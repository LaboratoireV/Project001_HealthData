# Render every public R Markdown example to code_examples/output/.
#
# Optional arguments:
#   Rscript code_examples/render_all_rmd.R [source-directory] [output-directory]

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
    script_path <- source_files[length(source_files)]
    return(dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE)))
  }

  command_args <- commandArgs(trailingOnly = FALSE)
  file_argument <- grep("^--file=", command_args, value = TRUE)

  if (length(file_argument) > 0L) {
    script_path <- sub("^--file=", "", file_argument[1L])
    return(dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE)))
  }

  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

script_dir <- get_script_dir()
source(file.path(script_dir, "render_utils.R"), local = TRUE)
project_dir <- find_project_dir(script_dir)

arguments <- commandArgs(trailingOnly = TRUE)
source_dir <- if (length(arguments) >= 1L) {
  resolve_project_path(arguments[1L], project_dir)
} else {
  script_dir
}
output_dir <- if (length(arguments) >= 2L) {
  resolve_project_path(arguments[2L], project_dir)
} else {
  file.path(script_dir, "output")
}

if (!dir.exists(source_dir)) {
  stop("Source directory not found: ", source_dir, call. = FALSE)
}

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

rmd_files <- list.files(
  path = source_dir,
  pattern = "\\.[Rr][Mm][Dd]$",
  full.names = TRUE,
  recursive = FALSE
)
rmd_files <- sort(normalizePath(rmd_files, winslash = "/", mustWork = TRUE))

if (length(rmd_files) == 0L) {
  stop(
    paste0(
      "No R Markdown source files were found in: ",
      display_path(source_dir, project_dir)
    ),
    call. = FALSE
  )
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

message("Source directory: ", display_path(source_dir, project_dir))
message("Output directory: ", display_path(output_dir, project_dir))
message("Found ", length(rmd_files), " R Markdown file(s).")

render_results <- lapply(seq_along(rmd_files), function(index) {
  input_file <- rmd_files[index]
  input_name <- basename(input_file)
  output_name <- paste0(tools::file_path_sans_ext(input_name), ".html")

  message(
    "\n[", index, "/", length(rmd_files), "] Rendering ", input_name, " ..."
  )

  tryCatch(
    {
      output_path <- rmarkdown::render(
        input = input_file,
        output_format = "html_document",
        output_file = output_name,
        output_dir = output_dir,
        knit_root_dir = project_dir,
        envir = new.env(parent = globalenv()),
        clean = TRUE,
        quiet = TRUE
      )

      data.frame(
        Input = input_name,
        Status = "SUCCESS",
        Output = display_path(output_path, project_dir),
        Error = "",
        check.names = FALSE
      )
    },
    error = function(error) {
      safe_error <- sanitize_message(conditionMessage(error), project_dir)
      message("FAILED: ", input_name, " — ", safe_error)

      data.frame(
        Input = input_name,
        Status = "FAILED",
        Output = "",
        Error = safe_error,
        check.names = FALSE
      )
    }
  )
})

render_results <- do.call(rbind, render_results)
rownames(render_results) <- NULL

message("\nRender summary:")
print(render_results, row.names = FALSE, right = FALSE)

failed_files <- render_results$Input[render_results$Status == "FAILED"]

if (length(failed_files) > 0L) {
  stop(
    length(failed_files),
    " file(s) failed to render: ",
    paste(failed_files, collapse = ", "),
    call. = FALSE
  )
}

message("\nAll R Markdown files rendered successfully.")
invisible(render_results)
