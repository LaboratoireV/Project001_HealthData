# Render one R Markdown report using project-root paths.
#
# Usage:
#   Rscript code_examples/render_report.R code_examples/report.Rmd

get_script_dir <- function() {
  source_files <- vapply(
    sys.frames(),
    function(frame) {
      if (is.null(frame$ofile)) NA_character_ else as.character(frame$ofile)[1L]
    },
    FUN.VALUE = character(1)
  )
  source_files <- source_files[!is.na(source_files) & nzchar(source_files)]

  if (length(source_files) > 0L) {
    return(dirname(normalizePath(
      source_files[length(source_files)],
      winslash = "/",
      mustWork = TRUE
    )))
  }

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

required_packages <- c("rmarkdown", "knitr", "htmltools", "readxl", "shiny")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]

if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    ". Run `Rscript code_examples/setup_dependencies.R` first.",
    call. = FALSE
  )
}

find_pandoc_dir()

arguments <- commandArgs(trailingOnly = TRUE)

if (length(arguments) == 0L) {
  rmd_candidates <- list.files(
    script_dir,
    pattern = "\\.[Rr][Mm][Dd]$",
    full.names = TRUE
  )

  if (length(rmd_candidates) != 1L) {
    stop(
      paste0(
        "Specify the report source file. Usage:\n",
        "  Rscript code_examples/render_report.R ",
        "code_examples/report.Rmd\n\n",
        "No unique .Rmd source is currently available in: ",
        script_dir
      ),
      call. = FALSE
    )
  }

  input_path <- normalizePath(
    rmd_candidates[1L],
    winslash = "/",
    mustWork = TRUE
  )
} else {
  input_path <- find_input_path(
    arguments[1L],
    project_dir = project_dir,
    script_dir = script_dir
  )
}

if (!file.exists(input_path)) {
  stop(
    "R Markdown source file not found: ",
    basename(input_path),
    call. = FALSE
  )
}

default_output_name <- paste0(
  tools::file_path_sans_ext(basename(input_path)),
  ".html"
)
output_path <- if (length(arguments) >= 2L) {
  resolve_project_path(arguments[2L], project_dir)
} else {
  file.path(script_dir, "output", default_output_name)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)

message("Rendering: ", display_path(input_path, project_dir))
message("Output: ", display_path(output_path, project_dir))

rmarkdown::render(
  input = input_path,
  output_format = "html_document",
  output_file = basename(output_path),
  output_dir = dirname(output_path),
  knit_root_dir = project_dir,
  envir = new.env(parent = globalenv()),
  clean = TRUE,
  quiet = TRUE
)
