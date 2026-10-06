SHELL := /bin/bash

.PHONY: help resume job letter clean

help:
	@echo "  make resume              Build main.pdf and output/Resume.pdf"
	@echo "  make resume name=Jane    Same, but output/Jane.pdf"
	@echo "  make job company=Acme title=\"Frontend Dev\"      Per-job resume PDF in output/resume/"
	@echo "  make letter company=Acme title=\"Frontend Dev\"   Per-job cover letter PDF in output/cover-letters/"
	@echo "  make clean               Remove build byproducts"

resume:
	bash scripts/build.sh $(name)

job:
	bash scripts/build-pdf.sh "$(company)" "$(title)"

letter:
	bash scripts/build-cover-letter.sh "$(company)" "$(title)"

clean:
	rm -f main.aux main.log main.out main.fls main.fdb_latexmk main.synctex.gz
