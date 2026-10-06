#!/usr/bin/env bash
set -euo pipefail

# Compiles main.tex into main.pdf and copies it to output/Resume.pdf.
# Usage: bash scripts/build.sh [output-name]   (default: Resume)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:-Resume}"
cd "$repo_root"

pdflatex -interaction=nonstopmode -halt-on-error main.tex >/dev/null
pdflatex -interaction=nonstopmode -halt-on-error main.tex >/dev/null

mkdir -p output
cp main.pdf "output/${name}.pdf"
rm -f main.aux main.log main.out main.fls main.fdb_latexmk main.synctex.gz

echo "Built main.pdf and output/${name}.pdf ($(pdfinfo main.pdf 2>/dev/null | awk '/Pages/{print $2}') pages)"
