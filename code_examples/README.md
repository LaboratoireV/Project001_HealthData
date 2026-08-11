# Public R code examples

This directory contains a sanitized, GitHub-safe copy of the report code. It is intended to demonstrate an R Markdown workflow with synthetic health data.

The original source files and workbooks are not included. `Miss V`, `The V Lab`, `Dr. ABC`, and `ABC Department` are fictional public-facing labels. The examples use a fixed demonstration date, project-relative paths, and standalone helper functions. They do not reference private packages or machine-specific user paths.

## Contents

- `nacrs_summary_example.Rmd` — emergency/ambulatory data summary example.
- `dad_summary_example.Rmd` — inpatient data summary example.
- `example_helpers.R` — workbook import and summary-table helpers.
- `render_report.R` — render one example.
- `render_all_rmd.R` — render all examples.
- `render_utils.R` — portable project-path and Pandoc discovery helpers.
- `setup_dependencies.R` — install missing CRAN dependencies with `renv`.

## Synthetic data only

Never place real patient, client, or operational data in this directory. For local testing, add synthetic workbooks to `example_data/` using these names:

- `synthetic_nacrs.xlsx`
- `synthetic_dad.xlsx`

The first worksheet should contain the variables listed in the corresponding R Markdown file's `*_continuous` and `*_categorical` vectors. Files inside `example_data/` are ignored by Git and will not be uploaded.

## Run locally

From the repository root:

```sh
Rscript code_examples/setup_dependencies.R
Rscript code_examples/render_all_rmd.R
```

Generated HTML is written to `code_examples/output/`, which is also ignored by Git.

To render one report:

```sh
Rscript code_examples/render_report.R code_examples/nacrs_summary_example.Rmd
```
