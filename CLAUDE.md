# ATS LaTeX Resume: Working Notes

This repo is a public template that anyone can clone and use with their own resume. It has two jobs:

1. A clean, ATS-friendly LaTeX resume + cover letter template (placeholder content only).
2. A Claude Code skill, `.claude/skills/job-pipeline/SKILL.md`, that automates applying to a job: tailor the resume, build resume and cover letter PDFs, push them to GitHub, and log the job in the jobwyre tracker via MCP.

It is meant to be cloned by people from any field, each with their own resume structure and content. It contains no personal data and no job-finding rules.

## Updates

Users get updates by pulling from the upstream remote (`git pull`), so keep changes backward compatible with an already-configured clone: never overwrite or require edits to the user's `CLAUDE.md` Config block, their `sections/`, or their `cover_letter.tex`. Put new config as optional env vars with sensible defaults.

## Design decisions (do not undo without asking)

- **Adapt to the user's own structure.** The skill and scripts must work with whatever LaTeX files the user has. Nothing may hardcode section names, section order or a specific template. `RESUME_TEX` and `COVER_LETTER_TEX` env vars point the build scripts at the user's files.
- **Job discovery and fit-gating are out of scope.** The skill assumes the job was already found and judged worth applying to. Do not add language gates, role-fit gates or scoring.
- **jobwyre via MCP, not a REST script, and optional.** If the `jobwyre` MCP tools are not available in the session, the skill skips every jobwyre step and still builds and pushes both PDFs. When available, the tracker entry is created or updated with the `jobwyre` MCP tools (`list_jobs` first, then `update_job` or `create_job`). Resume and Cover Letter are attached as GitHub blob URLs on the work branch.
- **Work branch only** (default `edits`), never `main`. Push right after the cover letter commit.
- **Both PDFs per job**, built together. Page counts checked with `pdfinfo`.
- **No personal data** in this repo: no real name, contact details, employers, or tracker data. Content stays Lorem ipsum / placeholder.
- No em dashes or en dashes in generated text; hyphenated words and date ranges are fine.

## Layout

- `main.tex`, `sections/*.tex`: resume template (one file per section).
- `cover_letter.tex`: cover letter template, overwritten per job.
- `scripts/build.sh`: simple build to `output/Resume.pdf` (`make resume`).
- `scripts/build-pdf.sh`, `scripts/build-cover-letter.sh`: per-job builds into `output/resume/` and `output/cover-letters/` (`make job`, `make letter`). Filenames: `Resume_<Company>_<JobTitle>_<NAME_SLUG>.pdf`, `CoverLetter_<Company>_<JobTitle>_<NAME_SLUG>.pdf`.
- `README.md`: setup and usage for end users.

## When changing things

- Keep `SKILL.md`, `README.md` and the scripts consistent with each other (the scripts are also embedded in `SKILL.md`).
- After editing a script or template, run `make resume`, `make job company=Test title=Test` and `make letter company=Test title=Test` to confirm all PDFs still build, then delete the test PDFs from `output/`.
- Keep `.gitkeep` files in `output/resume/` and `output/cover-letters/`.

## Config (the end user fills this in after cloning)

```
GITHUB_USER      =
GITHUB_REPO      =
WORK_BRANCH      = edits
FULL_NAME        =
NAME_SLUG        =
RESUME_TEX       = main.tex
COVER_LETTER_TEX = cover_letter.tex
```
