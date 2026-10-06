#!/usr/bin/env bash
set -euo pipefail

# Builds a per-job cover letter PDF from cover_letter.tex.
# Usage: bash scripts/build-cover-letter.sh "<Company>" "<Job Title>"
# Output: output/cover-letters/CoverLetter_<Company>_<JobTitle>_<NAME_SLUG>.pdf
# Set NAME_SLUG in your environment (or edit the default below), e.g. JaneDoe.

NAME_SLUG="${NAME_SLUG:-FirstnameLastname}"
# Source file to compile. Point this at your own file if it is not named cover_letter.tex
# (e.g. RESUME_TEX=cv.tex or COVER_LETTER_TEX=letter/main.tex).
src="${COVER_LETTER_TEX:-cover_letter.tex}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"<Company>\" \"<Job Title>\"" >&2
  exit 1
fi

# Strip spaces/punctuation, keep the company's own casing.
sanitize() { printf '%s' "$1" | tr -cd '[:alnum:]'; }

name="CoverLetter_$(sanitize "$1")_$(sanitize "$2")_${NAME_SLUG}"
out="$repo_root/output/cover-letters"
mkdir -p "$out"
cd "$repo_root"

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$out" -jobname="$name" "$src" >/dev/null
pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$out" -jobname="$name" "$src" >/dev/null
rm -f "$out/$name".{aux,log,out,fls,fdb_latexmk,synctex.gz}

echo "Created $out/$name.pdf ($(pdfinfo "$out/$name.pdf" 2>/dev/null | awk '/Pages/{print $2}') pages)"
