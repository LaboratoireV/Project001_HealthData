# Shared helpers for rendering reports on macOS, Windows, and Linux.

find_project_dir <- function(start_dir) {
  current_dir <- normalizePath(
    start_dir,
    winslash = "/",
    mustWork = TRUE
  )

  repeat {
    r_projects <- list.files(
      current_dir,
      pattern = "\\.[Rr]proj$",
      full.names = TRUE
    )

    if (length(r_projects) > 0L || dir.exists(file.path(current_dir, ".git"))) {
      return(current_dir)
    }

    parent_dir <- dirname(current_dir)
    if (identical(parent_dir, current_dir)) {
      stop("Could not find the project root.", call. = FALSE)
    }

    current_dir <- parent_dir
  }
}

display_path <- function(path, project_dir) {
  normalized_path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  normalized_project <- normalizePath(
    project_dir,
    winslash = "/",
    mustWork = TRUE
  )
  project_prefix <- paste0(normalized_project, "/")

  if (identical(normalized_path, normalized_project)) {
    return(".")
  }

  if (startsWith(normalized_path, project_prefix)) {
    return(substring(normalized_path, nchar(project_prefix) + 1L))
  }

  basename(normalized_path)
}

sanitize_message <- function(message, project_dir) {
  normalized_project <- normalizePath(
    project_dir,
    winslash = "/",
    mustWork = TRUE
  )
  gsub(normalized_project, "<project>", message, fixed = TRUE)
}

is_absolute_path <- function(path) {
  grepl("^(?:/|[A-Za-z]:[/\\\\]|\\\\\\\\)", path)
}

resolve_project_path <- function(path, project_dir) {
  expanded_path <- path.expand(path)
  resolved_path <- if (is_absolute_path(expanded_path)) {
    expanded_path
  } else {
    file.path(project_dir, expanded_path)
  }

  normalizePath(resolved_path, winslash = "/", mustWork = FALSE)
}

find_input_path <- function(path, project_dir, script_dir) {
  expanded_path <- path.expand(path)

  candidates <- if (is_absolute_path(expanded_path)) {
    expanded_path
  } else {
    c(
      file.path(project_dir, expanded_path),
      file.path(script_dir, expanded_path)
    )
  }

  existing_candidates <- candidates[file.exists(candidates)]
  selected_path <- if (length(existing_candidates) > 0L) {
    existing_candidates[1L]
  } else {
    candidates[1L]
  }

  normalizePath(selected_path, winslash = "/", mustWork = FALSE)
}

find_pandoc_dir <- function() {
  if (rmarkdown::pandoc_available()) {
    return(invisible(TRUE))
  }

  executable_name <- if (.Platform$OS.type == "windows") {
    "pandoc.exe"
  } else {
    "pandoc"
  }

  path_pandoc <- Sys.which("pandoc")
  path_candidate <- if (nzchar(path_pandoc)) dirname(path_pandoc) else ""

  rstudio_tools <- "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools"
  machine <- unname(Sys.info()[["machine"]])
  mac_architectures <- unique(c(machine, "aarch64", "arm64", "x86_64"))

  program_files <- Sys.getenv("ProgramFiles", unset = "")
  program_files_x86 <- Sys.getenv("ProgramFiles(x86)", unset = "")
  local_app_data <- Sys.getenv("LOCALAPPDATA", unset = "")

  candidates <- unique(c(
    Sys.getenv("RSTUDIO_PANDOC", unset = ""),
    path_candidate,
    file.path(rstudio_tools, mac_architectures),
    rstudio_tools,
    file.path(program_files, "RStudio/resources/app/bin/quarto/bin/tools"),
    file.path(program_files, "RStudio/bin/pandoc"),
    file.path(program_files_x86, "RStudio/bin/pandoc"),
    file.path(local_app_data, "Programs/RStudio/resources/app/bin/quarto/bin/tools"),
    "/usr/lib/rstudio/resources/app/bin/quarto/bin/tools",
    "/usr/lib/rstudio/bin/pandoc",
    "/usr/local/lib/rstudio/bin/pandoc"
  ))
  candidates <- candidates[nzchar(candidates)]

  for (candidate in candidates) {
    pandoc_executable <- file.path(candidate, executable_name)

    if (file.exists(pandoc_executable)) {
      Sys.setenv(
        RSTUDIO_PANDOC = normalizePath(
          candidate,
          winslash = "/",
          mustWork = TRUE
        )
      )
      break
    }
  }

  if (!rmarkdown::pandoc_available()) {
    stop(
      paste(
        "Pandoc was not found.",
        "Install RStudio/Pandoc or set RSTUDIO_PANDOC to the directory",
        "that contains the Pandoc executable."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
