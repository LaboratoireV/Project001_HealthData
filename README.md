# Project 001: Synthetic Health Data Consulting

Project 001 generates **synthetic Alberta NACRS and DAD records** so two linked questions can be studied without real patients. It is a fictional consulting demonstration from The V Lab, not a real contract, hospital, or patient population.

The local folder `V_Project_001` and the GitHub repository `Project001_HealthData` are this project. The [Alberta Health Data Atlas](#supporting-reference-alberta-health-data-atlas) is only the reference used to design those synthetic files. It is not a second project.

## Research questions

The synthetic files imitate two Alberta sources:

- **NACRS** — National Ambulatory Care Reporting System. Here it is the emergency department visit: 30,000 records and 34 variables.
- **DAD** — Discharge Abstract Database. Here it is the inpatient stay: 60,000 records and 51 variables, including the derived length of stay. Question 2 uses the subset linked from a hospitalized NACRS visit.

Two questions, in order:

1. **Hospitalization, yes or no.** Among emergency visits, do CTAS and the time before the disposition decision affect whether the patient is hospitalized? CTAS is the Canadian Triage and Acuity Scale (`ctas_level`, levels 1–5, level 1 most urgent). The primary stay measure is pre-disposition stay in minutes (`pre_disposition_los_min`). Total emergency stay (`los_min`) includes time after that decision, so it is an appendix comparison, not the primary exposure. The outcome is hospitalization (`admitted_flag`: 1 = yes, 0 = no).
2. **Inpatient length of stay, in days.** Among hospitalized visits that can be linked to a DAD record, do CTAS and total NACRS stay minutes (`los_min`) affect DAD length of stay in days (`los_days`)? `acute_los_days` is the same stay after alternate-level-of-care days are removed, and it is a sensitivity outcome, not the primary one.

[A00](Project_001_Memo_A00.html) builds the derived research variables. [A01](Project_001_Memo_A01.html) and [A02](Project_001_Memo_A02.html) describe each synthetic file. [A03](Project_001_Memo_A03.html) estimates question 1. [A04](Project_001_Memo_A04.html) links hospitalized visits to DAD abstracts and compares linked with unlinked visits. [A05](Project_001_Memo_A05.html) estimates question 2 on the linked subset. [A06](Project_001_Memo_A06.html) summarizes the design, methods, findings, and limitations. The working R Markdown and analytic files stay in local `code/` and `data/`, which are excluded from Git, so the published HTML cannot be regenerated from the GitHub copy alone.

| If you want to… | Start here |
| --- | --- |
| Read the research | [A06](Project_001_Memo_A06.html) is the summary. [A03](Project_001_Memo_A03.html) is hospitalization. [A04](Project_001_Memo_A04.html) is linkage. [A05](Project_001_Memo_A05.html) is inpatient stay |
| See how the files were built | [A00](Project_001_Memo_A00.html) builds the research variables. [A01](Project_001_Memo_A01.html) and [A02](Project_001_Memo_A02.html) describe the files |
| Browse the published site | [Project 001 site](https://laboratoirev.github.io/Project001_HealthData/) |
| Run the public R examples | [`code_examples/`](code_examples/README.md). These examples do not rerun A00–A06 |
| See the reference used to design the synthetic data | [Atlas overview](ahs-datasets/README.md) or the [interactive atlas](https://alberta-health-data-atlas.tigerdogai.chatgpt.site) |

## What's in this repository

| Path | Role in Project 001 |
| --- | --- |
| [`index.html`](index.html) | Public project page |
| [`Project_001_Memo_A00.html`](Project_001_Memo_A00.html) | Builds derived research variables from the source files |
| [`Project_001_Memo_A01.html`](Project_001_Memo_A01.html) | Emergency/ambulatory summary (the A01 deliverable) |
| [`Project_001_Memo_A02.html`](Project_001_Memo_A02.html) | Inpatient summary (the A02 deliverable) |
| [`Project_001_Memo_A03.html`](Project_001_Memo_A03.html) | Logistic model of hospitalization on pre-disposition stay and CTAS. Total stay and other covariates are in the appendix |
| [`Project_001_Memo_A04.html`](Project_001_Memo_A04.html) | Links hospitalized emergency visits to DAD abstracts by personal health number and a six-hour window, then compares linked and unlinked visits |
| [`Project_001_Memo_A05.html`](Project_001_Memo_A05.html) | Linear model of inpatient stay in days on emergency stay and CTAS, using the A04 linked visits. Acute stay is a sensitivity analysis |
| [`Project_001_Memo_A06.html`](Project_001_Memo_A06.html) | Summary of the study design, data, methods, findings, and limitations |
| [`code_examples/`](code_examples/README.md) | Sanitized reporting workflow. Example workbooks are not committed |
| [`config/variable_dictionary.csv`](config/variable_dictionary.csv) | Shared NACRS and DAD variable definitions used by the reports |
| [`ahs-datasets/`](ahs-datasets/README.md) | Supporting reference for designing the synthetic data. The interactive app is hosted separately |
| `code/`, `data/` | Original working code and local datasets. Local only; excluded from Git |

Official data-dictionary workbooks and any real working datasets are not copied into this repository.

## Project team and client

- **Project lead:** Miss V
- **Consulting organization:** The V Lab
- **Client:** Dr. ABC
- **Client organization:** ABC Department

All names and organizations above are fictional public-facing labels. They do not identify real people, clients, employers, or institutions.

## Published reports

- **[Memo A00](Project_001_Memo_A00.html)** — constructs the derived research variables and records their definitions
- **[Memo A01](Project_001_Memo_A01.html)** — descriptive summary of the analytic NACRS file written by Memo A00
- **[Memo A02](Project_001_Memo_A02.html)** — descriptive summary of the analytic DAD file written by Memo A00
- **[Memo A03](Project_001_Memo_A03.html)** — logistic regression of hospitalization on pre-disposition stay and CTAS. Total emergency stay and the other covariates are in the appendix
- **[Memo A04](Project_001_Memo_A04.html)** — links hospitalized NACRS visits to DAD abstracts by personal health number, then a six-hour admission window, and compares linked with unlinked visits
- **[Memo A05](Project_001_Memo_A05.html)** — linear regression of inpatient length of stay in days on emergency stay and CTAS, in the linked cohort, with an acute-stay sensitivity analysis
- **[Memo A06](Project_001_Memo_A06.html)** — summary of the study design, data, statistical methods, key findings, and limitations

## Synthetic data

**All data are randomly generated and entirely synthetic.** They contain no real patient records, personal health information, client data, or operational information. Any resemblance to real people, organizations, facilities, events, or results is coincidental.

The Alberta Health Data Atlas supplies the structural reference for those records: what one row represents, which field families exist, and how sources can be linked. It does not supply patient-level values, and it is not the generator that writes the workbooks.

The data are for software demonstration, education, and portfolio presentation only. They must not be used for clinical, policy, financial, or operational decision-making.

## Supporting reference: Alberta Health Data Atlas

The atlas is an independent Chinese–English guide to nine Alberta administrative health datasets and clinical information systems. In this repository it is supporting material for Project 001. It explains record grain, field families, linkage, cohort design, access, and responsible interpretation, so the NACRS-style and DAD-style examples can stay realistic without using real records.

- [Overview in this repository](ahs-datasets/README.md)
- [Interactive bilingual atlas](https://alberta-health-data-atlas.tigerdogai.chatgpt.site)

It contains original educational commentary and links to official public sources. It contains no patient-level data and does not copy the official UCalgary workbooks into this repository. It is not an official Alberta Health Services, University of Calgary, Government of Alberta, or CIHI publication.

## Public code examples

The GitHub-safe examples are in [`code_examples/`](code_examples/README.md):

- `nacrs_summary_example.Rmd` and `dad_summary_example.Rmd`
- standalone data-import, schema-validation, and summary helpers
- the shared variable dictionary in `config/variable_dictionary.csv`
- portable single-report and batch-rendering scripts

The public examples use project-relative paths and do not contain private package references, machine-specific user paths, or real data. The reports stop if a required variable is missing, an unregistered variable appears, or a binary flag contains values other than `0`, `1`, and missing.

### Run the examples locally

From the repository root:

```sh
Rscript code_examples/setup_dependencies.R
Rscript code_examples/render_all_rmd.R
```

For a full local demonstration, place only synthetic workbooks in `code_examples/example_data/` as `synthetic_nacrs.xlsx` and `synthetic_dad.xlsx`. Filenames and worksheet rules are documented in [`code_examples/README.md`](code_examples/README.md). Example workbooks and generated HTML outputs are ignored by Git.

## Repository privacy

The original Project 001 working code and local datasets remain local and are excluded from Git (`code/`, `data/`). The published HTML for Memos A00–A06 is the rendered output of those local files. Cloning the repository does not include the R Markdown or the analytic data, so those memos cannot be regenerated from GitHub. The public examples in `code_examples/` read raw synthetic workbooks and do not rebuild derived variables such as `los_min`, `admitted_flag`, `pre_disposition_los_min`, or `los_days`.

On this machine, `renv` autoload hangs unless R is started without a site or user profile and with the project library set explicitly. From the repository root, one memo is rendered with:

```sh
R_PROFILE_USER=/dev/null R_LIBS="renv/library/macos/R-4.6/aarch64-apple-darwin23" \
  Rscript --vanilla code/render_report.R code/Project_001_Memo_A00.Rmd
```

Replace the memo name to render another report. The HTML is written to the repository root. That library path is specific to this macOS R 4.6 install.

The atlas integration is limited to a public overview and preview image. Its dependency folders, build caches, hosting metadata, and third-party workbooks are not copied here. The interactive reference remains on its existing deployment.
