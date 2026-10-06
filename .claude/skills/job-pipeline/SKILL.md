---
name: job-pipeline
description: Build a tailored resume PDF and cover letter PDF from LaTeX files for a specific job, push both to GitHub, and optionally log the job in the jobwyre tracker when the jobwyre MCP connector is available. Use when the user gives a job (link or pasted JD, already vetted by their own job-finding routine) and wants the application package built and tracked.
---

# Job Pipeline: LaTeX resume + cover letter, GitHub upload, optional jobwyre entry

Given a job that has already been found and judged worth applying to, produce the full application package:

1. Tailor the resume `.tex` files and compile a resume PDF.
2. Write and compile a cover letter PDF.
3. Commit and push both PDFs to the user's GitHub repo.
4. Optional: create or update the job in the jobwyre tracker (via the `jobwyre` MCP connector), with the Resume and Cover Letter attached as GitHub links. Skip this when the connector is not available (see "jobwyre is optional").

Job discovery and fit-gating are out of scope. Assume the job is already chosen.

**jobwyre is optional.** Check whether the `jobwyre` MCP tools (`list_jobs`, `create_job`, `update_job`) are available in this session. If they are, run every jobwyre step below. If they are not, or the user says they do not use jobwyre, skip all jobwyre steps (the duplicate check in section 2, section 7, and the jobwyre line in the final report) and do not ask the user to set it up. Everything else runs unchanged, and the build, commit and push steps never depend on jobwyre.

---

## 0. One-time setup (do this once per machine, skip if already done)

Fill in these values first and keep them in a `## Config` block at the top of the repo's `CLAUDE.md` so every session picks them up:

```
GITHUB_USER   = <github username>
GITHUB_REPO   = <repo name, e.g. ats-latex-resume>
WORK_BRANCH   = edits            # never commit straight to main
FULL_NAME     = <Firstname Lastname>
NAME_SLUG     = <FirstnameLastname>   # used in filenames, no spaces
```

Requirements:
- A LaTeX install with `pdflatex` (MacTeX / BasicTeX / TeX Live) and `pdfinfo` (`brew install poppler`).
- `git` authenticated to GitHub (`gh auth login` or SSH key), with the repo cloned locally.
- Optional: the `jobwyre` MCP connector (https://jobwyre.app) added to Claude and authorized (tools: `list_jobs`, `get_job`, `create_job`, `update_job`). Without it the pipeline still builds and pushes both PDFs.

### Use the user's structure, not a fixed template

This skill does not require any particular resume or cover letter layout. Before the first build in a repo, discover how the user's files are organized and record it in the `## Config` block of `CLAUDE.md`:

```
RESUME_TEX         = <entry file that compiles to the resume, e.g. main.tex, cv.tex, resume/resume.tex>
RESUME_TAILOR      = <the file(s)/section(s) that change per job, e.g. sections/summary.tex, or "the Summary block in cv.tex">
COVER_LETTER_TEX   = <your cover letter source, e.g. cover_letter.tex, letter.tex>   # or "none yet"
```

How to find them: list the repo, read the resume entry file, follow its `\input{}`/`\include{}` chain, and read the actual content. The tailorable parts are whatever plays the role of a summary/profile paragraph, a headline or title line, and a skills list. They might live in separate section files or inside one big `.tex`. Edit them where they are. Never restructure, rename, reformat or "clean up" the user's LaTeX, and never impose another template's section names or order.

If the user has no cover letter source yet, create one by copying their resume's own preamble (document class, fonts, margins, packages) and header style (name, contact line) so the letter matches their resume visually. Do not use a generic template.

Requirements for the build to work with the user's files:
- Everything compiles with plain `pdflatex`. If the user's files need `xelatex`/`lualatex`/`latexmk` (e.g. `fontspec`), change the compile command in the scripts to match; the rest of the flow is unchanged.
- Relative `\input{}` paths resolve from the repo root, so the scripts `cd` there before compiling. If the user's entry file lives in a subfolder and uses paths relative to it, set `RESUME_TEX` to that path and, if needed, edit the scripts to `cd` into that folder instead.

### `scripts/build-pdf.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage: bash scripts/build-pdf.sh "<Company>" "<Job Title>"
# Output: output/resume/Resume_<Company>_<JobTitle>_<NAME_SLUG>.pdf

NAME_SLUG="${NAME_SLUG:-FirstnameLastname}"   # edit this default to your own name
src="${RESUME_TEX:-main.tex}"                 # the user's resume entry file
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
company="$1"; title="$2"

# strip spaces/punctuation, keep the company's own casing
sanitize() { printf '%s' "$1" | tr -cd '[:alnum:]'; }
name="Resume_$(sanitize "$company")_$(sanitize "$title")_${NAME_SLUG}"
out="$repo_root/output/resume"
mkdir -p "$out"; cd "$repo_root"

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$out" -jobname="$name" "$src" >/dev/null
pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$out" -jobname="$name" "$src" >/dev/null
rm -f "$out/$name".{aux,log,out,fls,fdb_latexmk,synctex.gz}
echo "Created $out/$name.pdf"
```

### `scripts/build-cover-letter.sh`

Same as above, but compiles `${COVER_LETTER_TEX:-cover_letter.tex}`, names the file `CoverLetter_<Company>_<JobTitle>_<NAME_SLUG>.pdf`, and writes into `output/cover-letters/`.

---

## 1. Inputs for every job

Collect (ask the user only for what you cannot read from the JD):

| Field | Source |
|---|---|
| Company | Exactly as the company writes its own name (casing matters: `eRecht24`, not `Erecht24`). Check the employer's site if unsure. |
| Job title | The JD page's visible heading, never the URL slug. |
| Job link | The company's own listing URL (careers page or its ATS page). Not a LinkedIn/Indeed/StepStone URL. |
| City | From the JD. |
| Work type | `Hybrid`, `Remote` or `On-site`, from the JD. |
| Contact | Recruiter name/email/phone only if the JD lists one, else empty. Never invent. |
| Salary range | Only if the JD states it. Plain comma-separated digits, no currency symbol: `70,000-90,000`, `70k-90k`, or `80k`. Otherwise leave empty. |
| Source | Where the job was found, short: `LinkedIn`, `Indeed`, `Company's own careers page`, etc. |

If a JD link is behind a login wall and cannot be fetched, ask the user to paste the text. Do not guess content.

## 2. Pre-flight

1. `git checkout <WORK_BRANCH> && git pull`. Work only on this branch.
2. If jobwyre is available: call jobwyre `list_jobs` with `search` set to the company. If a matching company + role already exists with a status other than `To apply` (Applied, Interview, etc.), stop and ask the user before rebuilding anything. A repeated link is not an instruction to rebuild.
3. Read the JD fully. Note the stack, seniority language, domain terms, and any nice-to-haves that honestly match the user's background.

## 3. Tailor the resume

Read the user's resume source first (see "Use the user's structure"). Edit only the parts that change per job, in whatever files/sections they live:

- the summary/profile paragraph: rewrite for this JD. Open with the role, years of experience and the JD-relevant skills, then one concrete real achievement. Use JD keywords only where they are true of the user.
- the title/headline line under the user's name, if there is one: match it to the role applied for.
- the skills list: add a JD keyword only if it is a skill the user really has and it is not listed yet.

Leave everything else (experience, education, any permanent sections) as is. Keep the user's existing wording style, LaTeX commands and formatting; match the surrounding code rather than introducing new macros.

**Never fabricate** metrics, outcomes, tools or responsibilities. If the JD wants something the user does not have, leave it out. If something is unclear, ask.

## 4. Build the resume PDF

```
bash scripts/build-pdf.sh "<Company>" "<Job Title>"
pdfinfo output/resume/<file>.pdf | grep Pages
```

Check the page count with `pdfinfo` (install poppler if missing, do not substitute another method). The resume must not exceed the page limit the user wants (usually 2). If it runs long, trim the least relevant project bullets first, then older roles, never the main current role.

Commit: `generate resume for <Company> as <Job Title>`

## 5. Write and build the cover letter

Write the letter into the user's own cover letter source (`COVER_LETTER_TEX`), overwriting the per-job content while keeping the user's preamble, header and layout exactly as they are. Fill in the date, the recipient block (company name in its own capitalization), a subject line with the plain job title, salutation, body and closing, using whatever structure their template already has. If there is none, create one from the resume's preamble and header (see "Use the user's structure").

Content rules:
- Open with substance (what attracts the user to this role/company, or a concrete qualification). Never open with "I am writing to..." or "I am reaching out...".
- Cover: why this company/role specifically (something genuine from the JD), what value the user adds, which skills match the JD stack, and willingness to relocate if the job is in another city.
- First sentence must be crisp declarative prose, not a run-on or stitched JD phrases.
- No fabricated claims. One page maximum.

Build and verify:
```
bash scripts/build-cover-letter.sh "<Company>" "<Job Title>"
pdfinfo output/cover-letters/<file>.pdf | grep Pages    # must be 1
```

Commit: `generate cover letter for <Company> as <Job Title>`

## 6. Upload to GitHub

Push right after the cover letter commit, without waiting to be asked:

```
git push origin <WORK_BRANCH>
```

The GitHub links used for tracking are blob URLs on the work branch:

```
Resume:       https://github.com/<GITHUB_USER>/<GITHUB_REPO>/blob/<WORK_BRANCH>/output/resume/<resume-file>.pdf
Cover Letter: https://github.com/<GITHUB_USER>/<GITHUB_REPO>/blob/<WORK_BRANCH>/output/cover-letters/<cover-letter-file>.pdf
```

(If the repo is private, only the owner can open these, which is fine for a personal tracker.)

## 7. Add to jobwyre (only if available)

Skip this whole section if the jobwyre connector is not available. Otherwise use the `jobwyre` MCP tools, not any REST script.

1. `list_jobs` with `search` = company. Match on company + role. If found, `update_job` it in place. Otherwise `create_job`. Never create a duplicate.
2. Fields to pass:
   - `company`, `role`
   - `link`: company's own listing URL
   - `city`, `workType`
   - `contact` (empty if none)
   - `salaryRange`: only the JD-stated figure. If the JD gives none, leave it empty and put a one-line market-estimate note in `notes` instead.
   - `source`: the short discovery channel
   - `status`: `To apply` for new entries (do not overwrite the status of an existing entry)
   - `attachments`: array with a `"Resume"` entry and a `"Cover Letter"` entry, each `{label, url}` using the GitHub blob URLs above
3. `profileMatchScore` is optional. Only set it if the user wants it and tell them how you derived it.

Create the jobwyre entry as the last step, after the PDFs are built, committed and pushed, so the links resolve. When jobwyre is in use, a resume/cover letter and its jobwyre entry are one unit: never leave PDFs without an entry or an entry without PDFs.

## 8. Final report (keep it short)

Give the user: company, role, both PDF filenames, page counts, the two GitHub links, and, if jobwyre is used, the jobwyre entry status. Flag anything unusual (JD page vs. link mismatch, missing contact, a skill gap you left out). Do not paste the profile or letter text back unless asked.

## Hard rules

1. Never commit to `main`. Always the work branch.
2. Never fabricate experience, metrics or skills.
3. No em dashes or en dashes in any generated text, and no `--`/`-` used to join two clauses. Date ranges and hyphenated words are fine.
4. Company names keep their own capitalization everywhere (letters, PDFs, tracker).
5. Job link stored is the company's own listing, not an aggregator URL.
6. Page counts are checked with `pdfinfo`, every time.
7. Every job gets both a resume and a cover letter, built together.
8. Push to GitHub immediately after the commit.
9. When jobwyre is in use, check it for an existing entry before building, and update in place rather than duplicating.
