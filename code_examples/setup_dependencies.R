# Install the CRAN packages needed by the public code examples.
# Run from the repository root:
#   Rscript code_examples/setup_dependencies.R

get_script_dir <- function() {
  command_args <- commandArgs(trailingOnly = FALSE)
  file_argument <- grep("^--file=", command_args, value = TRUE)

  if (length(file_argument) > 0L) {
    return(dirname(normalizePath(
      sub("^--file=", "", file_argument[1L]),
      winslash = "/",
      mustWork = TRUE
    )))
  }

  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

script_dir <- get_script_dir()
source(file.path(script_dir, "render_utils.R"), local = TRUE)
project_dir <- find_project_dir(script_dir)

if (!requireNamespace("renv", quietly = TRUE)) {
  stop(
    paste(
      "The renv package is not available.",
      "Open the repository's .Rproj file or install renv first."
    ),
    call. = FALSE
  )
}

renv::load(project = project_dir)

cran_packages <- c("rmarkdown", "knitr", "htmltools", "readxl", "shiny")
missing_packages <- cran_packages[
  !vapply(cran_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]

if (length(missing_packages) > 0L) {
  message("Installing the missing CRAN dependencies ...")
  renv::install(missing_packages, project = project_dir)
} else {
  message("All public-example dependencies are already installed.")
}
