# ATS LaTeX Resume

An ATS-friendly LaTeX resume and matching cover letter template. The resume is one to two pages and split into one file per section, so you can reorder, remove or edit sections easily. Per-job build scripts produce a named resume PDF and cover letter PDF for each application, and an optional Claude Code skill automates applying: it tailors the resume, writes the cover letter, pushes both PDFs to GitHub, and tracks the job in [jobwyre](https://jobwyre.app).

The build scripts are standalone: they need only LaTeX and `make`, no jobwyre, GitHub or Claude account. Based on [sb2nov/resume](https://github.com/sb2nov/resume) by Jake Gutierrez (MIT).

## Structure

```
Makefile, scripts/         # build commands (build.sh, build-pdf.sh, build-cover-letter.sh)
.claude/skills/job-pipeline/ # Claude Code skill for the automated pipeline
output/resume/, output/cover-letters/  # per-job PDFs
cover_letter.tex           # cover letter template, overwritten per job
main.tex                   # preamble, custom commands, section order
sections/intro.tex         # name, title, contact links
sections/profile.tex       # short summary paragraph
sections/experience.tex
sections/education.tex
sections/technical_skills.tex
sections/projects.tex
sections/leadership.tex    # optional: awards, volunteering
sections/languages.tex
sections/interests.tex
```

All content is Lorem ipsum placeholder text. Replace it with your own.

## Build

Start from a fresh machine. Do steps 1 to 3 once, then build as often as you like.

### 1. Get the files

```bash
git clone https://github.com/sikandarrali/ats-latex-resume.git
cd ats-latex-resume
```

No git? Click **Code > Download ZIP** on the GitHub page, unzip it, and open a terminal in that folder.

### 2. Install the tools

Install commands can be run from any folder. Only the build commands in step 4 must be run from inside the `ats-latex-resume` folder (`cd ats-latex-resume`). You need three things: `pdflatex` (with a few LaTeX packages), `make` and `bash` (to run the build commands), and optionally `pdfinfo` (so the build prints the page count). Pick your system.

#### macOS

1. Download **MiKTeX** for macOS from <https://miktex.org/download>, open the downloaded file, and drag **MiKTeX Console** into Applications. Open it and follow the first-run setup (it may ask for your password).
2. In MiKTeX Console go to **Settings > General** and set "Install missing packages on-the-fly" to **Yes**. MiKTeX then downloads packages like `titlesec`, `fullpage` and `marvosym` by itself the first time a build needs them, so there are no package commands to run.
3. **Quit your terminal or VS Code completely (Cmd+Q) and reopen it.** Until you do, `pdflatex` is "command not found".
4. Check with `pdflatex --version`. The first build is slow because it downloads packages. If a window asks to install a package, allow it.

You also need `make`: run `xcode-select --install` if `make --version` says it is missing. Optional, for the page count in the build output: install [Homebrew](https://brew.sh), then `brew install poppler`.

<details>
<summary>Prefer the command line? Install MacTeX with Homebrew instead</summary>

```bash
brew install --cask mactex-no-gui    # ~4 GB, includes every package, nothing else to install
```

Then quit and reopen your terminal or VS Code. If `pdflatex` is still not found, run `echo 'export PATH="/Library/TeX/texbin:$PATH"' >> ~/.zshrc` and open a new terminal. Do not install it alongside MiKTeX.

</details>

#### Linux

```bash
# Debian / Ubuntu / Mint
sudo apt update
sudo apt install texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra make poppler-utils git

# Fedora
sudo dnf install texlive-scheme-medium make poppler-utils git

# Arch / Manjaro
sudo pacman -S texlive texlive-latexextra texlive-fontsextra make poppler git
```

If a build says `File 'xyz.sty' not found`, install it: on Fedora `sudo dnf install 'tex(xyz.sty)'`, on Debian/Ubuntu `sudo apt install texlive-full` (large, installs everything), on Arch `sudo pacman -S texlive-most`.

#### Windows

Open PowerShell and run:

```powershell
winget install --id MiKTeX.MiKTeX -e
winget install --id Git.Git -e
```

Then:

1. Open **MiKTeX Console > Settings** and set "Install missing packages on-the-fly" to **Yes**. MiKTeX then downloads packages such as `fullpage`, `titlesec` and `marvosym` the first time a build needs them.
2. Close and reopen the terminal so `pdflatex` is on your `PATH`.
3. Use **Git Bash** (installed with Git) for every command below. It provides `bash`, which the build scripts need. Windows has no `make` by default, so instead of `make resume` run `bash scripts/build.sh`. The per-job builds work the same way, see "Per-job builds".

Prefer Linux tools? Install WSL with `wsl --install` (in an admin PowerShell, then reboot), open Ubuntu, and follow the Linux steps above.

#### No install: Overleaf

Upload the folder (as a zip) to [Overleaf](https://www.overleaf.com), set `main.tex` as the main file, and click Recompile. The per-job build scripts and the Claude skill do not work there.

### 3. Check it works

```bash
pdflatex --version
make --version      # macOS/Linux; on Windows use `bash --version` in Git Bash
pdfinfo -v          # optional
```

### 4. Build

> [!IMPORTANT]
> Run every build command from inside your project directory (the `ats-latex-resume` folder, or whatever you named your copy). Running them from your home folder or anywhere else fails.

```bash
cd ats-latex-resume      # run all commands below in your project directory
make resume              # builds main.pdf and output/Resume.pdf
make resume name=Jane    # output/Jane.pdf instead
make clean               # remove build byproducts
```

Or directly: `pdflatex main.tex` (run it twice). On Windows without `make`: `bash scripts/build.sh`.

### Per-job builds (resume + cover letter)

No jobwyre or Claude needed. These are plain shell scripts that build the PDFs locally.

```bash
# run these in your project directory (cd ats-latex-resume)
export NAME_SLUG=JaneDoe   # used in filenames
make job company=Acme title="Frontend Developer"      # output/resume/Resume_Acme_FrontendDeveloper_JaneDoe.pdf
make letter company=Acme title="Frontend Developer"   # output/cover-letters/CoverLetter_Acme_FrontendDeveloper_JaneDoe.pdf
```

On Windows without `make`, use Git Bash and call the scripts directly: `NAME_SLUG=JaneDoe bash scripts/build-pdf.sh "Acme" "Frontend Developer"` and `NAME_SLUG=JaneDoe bash scripts/build-cover-letter.sh "Acme" "Frontend Developer"`.

Edit `cover_letter.tex` per job before running `make letter`. If your files are named differently, point the scripts at them:

```bash
RESUME_TEX=cv.tex COVER_LETTER_TEX=letter.tex NAME_SLUG=JaneDoe make job company=Acme title="Frontend Developer"
```

## Automated job pipeline (Claude Code, optional)

Everything above works without this section. Skip it if you only want the PDF builds. jobwyre is optional inside the pipeline too: without the connector, the skill still tailors, builds and pushes both PDFs, and skips tracking.

The repo ships a Claude Code skill, `.claude/skills/job-pipeline/SKILL.md`. Given a job link or pasted job description, it:

1. checks the [jobwyre](https://jobwyre.app) tracker (if connected) so a job is never built twice,
2. tailors your resume (summary, title line, skills) without touching the rest,
3. builds the resume and cover letter PDFs and checks their page counts,
4. commits and pushes both PDFs to your GitHub repo,
5. creates or updates the job in jobwyre (if connected) with the Resume and Cover Letter GitHub links attached.

It works with your own LaTeX structure, not only this template.

### Setup

1. Install a TeX distribution (above), `pdfinfo` (poppler), [Claude Code](https://claude.com/claude-code), and `git` signed in to GitHub (`gh auth login` or an SSH key).
2. Put the repo in your own GitHub account:
   ```bash
   git remote set-url origin https://github.com/<you>/<repo>.git   # or: git init && git remote add origin ...
   git checkout -b edits        # the skill only commits to this branch, never main
   ```
3. Replace the placeholder content with your real resume and cover letter, and check that `make resume` builds.
4. Create a `CLAUDE.md` in the repo root with your config (the skill reads it every session):
   ```
   ## Config
   GITHUB_USER  = <your github username>
   GITHUB_REPO  = <repo name>
   WORK_BRANCH  = edits
   FULL_NAME    = Jane Doe
   NAME_SLUG    = JaneDoe
   RESUME_TEX   = main.tex
   COVER_LETTER_TEX = cover_letter.tex
   ```
5. Optional: add the [jobwyre](https://jobwyre.app) MCP connector in Claude and authorize it. Skip this if you don't use jobwyre.

### Use

Open the repo folder in Claude Code and say, for example: "Build the application for https://company.com/jobs/123". Claude does the rest and reports the PDF names, page counts, GitHub links and jobwyre status (when connected). Output PDFs live in `output/resume/` and `output/cover-letters/`.

## Customising

- **Remove a section:** delete its `\input{...}` line in `main.tex`.
- **Reorder sections:** reorder the `\input{...}` lines.
- **Change the font:** uncomment one of the options under `FONT OPTIONS` in `main.tex`.
- **Margins:** adjust the `\addtolength` lines in `main.tex`.

## License

MIT, see [LICENSE](LICENSE).
