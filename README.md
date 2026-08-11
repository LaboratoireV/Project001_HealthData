# Project 001: Synthetic Health Data Consulting Project

## Project overview

Project 001 is a **fictional health data consulting engagement** created to demonstrate a reproducible R and R Markdown reporting workflow. The project shows how a consultant might organize, summarize, and present descriptive analyses for emergency/ambulatory and inpatient health datasets.

This repository is a portfolio and training example. It does not represent a real consulting contract, health organization, patient population, or operational analysis.

## Project team and client

- **Project lead:** Miss V
- **Consulting organization:** The V Lab
- **Client:** Dr. ABC
- **Client organization:** ABC Department

All names and organizations above are fictional public-facing labels. They do not identify real people, clients, employers, or institutions.

## Synthetic data

The project uses two fictional health-data workbooks:

- **NACRS-style dataset:** 2,000 randomly generated records and 30 variables, representing an emergency/ambulatory care example.
- **DAD-style dataset:** 5,000 randomly generated records and 50 variables, representing an inpatient care example.

**All data are randomly generated and entirely synthetic.** They contain no real patient records, personal health information, client data, or operational information. Any resemblance to real people, organizations, facilities, events, or results is coincidental.

The data are intended only for software demonstration, education, and portfolio presentation. They must not be used for clinical, policy, financial, or operational decision-making.

## Public code examples

The GitHub-safe examples are available in [`code_examples/`](code_examples/README.md):

- `nacrs_summary_example.Rmd`
- `dad_summary_example.Rmd`
- standalone data-import and summary helpers
- portable single-report and batch-rendering scripts

The public examples use project-relative paths and do not contain private package references, machine-specific user paths, or real data.

## Run the examples locally

From the repository root:

```sh
Rscript code_examples/setup_dependencies.R
Rscript code_examples/render_all_rmd.R
```

For a full local demonstration, place only synthetic workbooks in `code_examples/example_data/` using the filenames documented in [`code_examples/README.md`](code_examples/README.md). Example workbooks and generated HTML outputs are ignored by Git.

## Repository privacy

The original working code, local datasets, and rendered internal reports remain local and are excluded from Git. Only the sanitized examples in `code_examples/` are intended for public display.
