# Standalone helpers used by the public R Markdown examples.

clean_example_names <- function(names_vector) {
  cleaned <- tolower(trimws(names_vector))
  cleaned <- gsub("[^a-z0-9]+", "_", cleaned)
  cleaned <- gsub("^_+|_+$", "", cleaned)
  make.unique(cleaned, sep = "_")
}

read_example_xlsx <- function(path) {
  dataset <- readxl::read_excel(path)
  names(dataset) <- clean_example_names(names(dataset))
  dataset
}

format_example_number <- function(value) {
  ifelse(is.na(value), NA_character_, sprintf("%.2f", value))
}

summarize_continuous <- function(dataset, var_name, display_name = var_name) {
  values <- suppressWarnings(as.numeric(dataset[[var_name]]))
  analyzed <- values[is.finite(values)]
  probabilities <- c(
    P1 = 0.01,
    P5 = 0.05,
    P10 = 0.10,
    Q1 = 0.25,
    Q2 = 0.50,
    Q3 = 0.75,
    P90 = 0.90,
    P95 = 0.95,
    P99 = 0.99
  )
  percentiles <- if (length(analyzed) > 0L) {
    stats::setNames(
      unname(stats::quantile(analyzed, probabilities, na.rm = TRUE)),
      names(probabilities)
    )
  } else {
    stats::setNames(rep(NA_real_, length(probabilities)), names(probabilities))
  }

  mean_value <- if (length(analyzed) > 0L) mean(analyzed) else NA_real_
  sd_value <- if (length(analyzed) > 1L) stats::sd(analyzed) else NA_real_
  min_value <- if (length(analyzed) > 0L) min(analyzed) else NA_real_
  max_value <- if (length(analyzed) > 0L) max(analyzed) else NA_real_
  missing_count <- sum(is.na(values))
  total_count <- length(values)

  data.frame(
    Variable = display_name,
    Mean_SD = if (is.na(mean_value)) {
      NA_character_
    } else {
      sprintf("%.2f (%.2f)", mean_value, sd_value)
    },
    Median = format_example_number(percentiles[["Q2"]]),
    Min_Max = if (is.na(min_value)) {
      NA_character_
    } else {
      sprintf("%.2f - %.2f", min_value, max_value)
    },
    P1 = format_example_number(percentiles[["P1"]]),
    P5 = format_example_number(percentiles[["P5"]]),
    P10 = format_example_number(percentiles[["P10"]]),
    Q1 = format_example_number(percentiles[["Q1"]]),
    Q2 = format_example_number(percentiles[["Q2"]]),
    Q3 = format_example_number(percentiles[["Q3"]]),
    P90 = format_example_number(percentiles[["P90"]]),
    P95 = format_example_number(percentiles[["P95"]]),
    P99 = format_example_number(percentiles[["P99"]]),
    Missing = missing_count,
    N = total_count,
    NonMissing = total_count - missing_count,
    MissingPct = if (total_count > 0L) 100 * missing_count / total_count else NA_real_,
    NonFinite = sum(!is.na(values) & !is.finite(values)),
    Analyzed = length(analyzed),
    check.names = FALSE
  )
}

summarize_categorical <- function(
  dataset,
  var_name,
  display_name = var_name,
  include_missing = TRUE,
  sort_levels = "desc"
) {
  values <- as.character(dataset[[var_name]])

  if (include_missing) {
    values[is.na(values) | !nzchar(trimws(values))] <- "Missing"
  } else {
    values <- values[!is.na(values) & nzchar(trimws(values))]
  }

  counts <- table(values, useNA = "no")
  if (identical(sort_levels, "desc")) {
    counts <- sort(counts, decreasing = TRUE)
  }

  total_count <- sum(counts)
  formatted <- if (total_count > 0L) {
    sprintf("%d (%.1f%%)", as.integer(counts), 100 * counts / total_count)
  } else {
    character()
  }

  result <- data.frame(
    Variable = display_name,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  for (index in seq_along(counts)) {
    result[[names(counts)[index]]] <- formatted[index]
  }

  result[["Total"]] <- sprintf("%d (100.0%%)", total_count)
  result
}

load_variable_dictionary <- function(project_dir, dataset_name) {
  dictionary_path <- file.path(project_dir, "config", "variable_dictionary.csv")
  if (!file.exists(dictionary_path)) {
    stop("Variable dictionary not found: ", dictionary_path, call. = FALSE)
  }

  dictionary <- utils::read.csv(
    dictionary_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
  required_columns <- c(
    "dataset", "source_name", "canonical_name", "display_label", "domain",
    "storage_type", "analytic_type", "unit", "summary_method",
    "include_profile", "privacy_class", "display_order", "required",
    "allowed_values", "quality_rule"
  )
  missing_columns <- setdiff(required_columns, names(dictionary))
  if (length(missing_columns) > 0L) {
    stop(
      "Variable dictionary is missing columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  specification <- dictionary[
    toupper(dictionary$dataset) == toupper(dataset_name),
    required_columns,
    drop = FALSE
  ]
  specification$required <- tolower(specification$required) %in% c("true", "1", "yes")
  specification$display_order <- suppressWarnings(
    as.integer(specification$display_order)
  )
  specification <- specification[
    order(specification$display_order, specification$source_name),
    ,
    drop = FALSE
  ]
  rownames(specification) <- NULL

  if (nrow(specification) == 0L) {
    stop("No variable specification found for ", dataset_name, ".", call. = FALSE)
  }
  if (anyDuplicated(specification$source_name)) {
    stop("Duplicate source_name values found for ", dataset_name, ".", call. = FALSE)
  }
  if (anyDuplicated(specification$canonical_name)) {
    stop("Duplicate canonical_name values found for ", dataset_name, ".", call. = FALSE)
  }
  if (anyNA(specification$display_order) || anyDuplicated(specification$display_order)) {
    stop("display_order must be complete and unique for ", dataset_name, ".", call. = FALSE)
  }

  specification
}

validate_dataset_schema <- function(dataset, specification, dataset_name) {
  if (!is.data.frame(dataset)) {
    stop(dataset_name, " must be a data frame.", call. = FALSE)
  }

  missing_required <- setdiff(
    specification$source_name[specification$required],
    names(dataset)
  )
  unregistered <- setdiff(names(dataset), specification$source_name)

  if (length(missing_required) > 0L) {
    stop(
      dataset_name, " is missing required registered variables: ",
      paste(missing_required, collapse = ", "),
      call. = FALSE
    )
  }
  if (length(unregistered) > 0L) {
    stop(
      dataset_name, " contains unregistered variables: ",
      paste(unregistered, collapse = ", "),
      call. = FALSE
    )
  }

  binary_variables <- specification$source_name[
    specification$analytic_type == "binary_flag" &
      specification$source_name %in% names(dataset)
  ]
  invalid_binary <- vapply(binary_variables, function(variable) {
    values <- unique(as.character(dataset[[variable]]))
    values <- values[!is.na(values) & nzchar(trimws(values))]
    any(!values %in% c("0", "1"))
  }, FUN.VALUE = logical(1))
  if (any(invalid_binary)) {
    stop(
      dataset_name, " has non-binary values in: ",
      paste(binary_variables[invalid_binary], collapse = ", "),
      call. = FALSE
    )
  }

  invisible(data.frame(
    Registered = nrow(specification),
    Present = sum(specification$source_name %in% names(dataset)),
    Unregistered = length(unregistered),
    MissingRequired = length(missing_required),
    check.names = FALSE
  ))
}

variables_for <- function(specification, summary_method, include_profile = NULL) {
  selected <- specification$summary_method %in% summary_method
  if (!is.null(include_profile)) {
    selected <- selected & specification$include_profile %in% include_profile
  }
  specification$source_name[selected]
}

variable_label <- function(specification, variable, include_unit = TRUE) {
  row <- specification[specification$source_name == variable, , drop = FALSE]
  if (nrow(row) != 1L) return(variable)

  label <- row$display_label[[1L]]
  unit <- row$unit[[1L]]
  if (isTRUE(include_unit) && nzchar(unit) && !unit %in% c("none", "datetime")) {
    label <- paste0(label, " (", unit, ")")
  }
  label
}

summarize_datetime_coverage <- function(dataset, specification) {
  variables <- variables_for(specification, "datetime", "coverage")
  rows <- lapply(variables, function(variable) {
    values <- dataset[[variable]]
    parsed <- as.POSIXct(values, tz = "UTC")
    observed <- parsed[!is.na(parsed)]
    data.frame(
      Variable = variable_label(specification, variable, include_unit = FALSE),
      `Non-missing` = length(observed),
      Missing = sum(is.na(parsed)),
      Earliest = if (length(observed)) format(min(observed), "%Y-%m-%d %H:%M") else NA_character_,
      Latest = if (length(observed)) format(max(observed), "%Y-%m-%d %H:%M") else NA_character_,
      check.names = FALSE
    )
  })
  if (length(rows)) do.call(rbind, rows) else data.frame()
}

summarize_quality_status <- function(dataset, specification) {
  variables <- variables_for(specification, "quality", "quality")
  rows <- lapply(variables, function(variable) {
    values <- as.character(dataset[[variable]])
    values[is.na(values) | !nzchar(trimws(values))] <- "Missing"
    counts <- sort(table(values, useNA = "no"), decreasing = TRUE)
    total <- sum(counts)
    data.frame(
      Variable = variable_label(specification, variable, include_unit = FALSE),
      Status = names(counts),
      `Count n (%)` = sprintf(
        "%d (%.1f%%)",
        as.integer(counts),
        if (total > 0L) 100 * counts / total else NA_real_
      ),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  })
  if (length(rows)) do.call(rbind, rows) else data.frame()
}

nacrs_timing_checks <- function(dataset) {
  required <- c(
    "arrival_datetime", "disposition_decision_datetime", "discharge_datetime",
    "pre_disposition_los_min", "post_disposition_los_min", "los_min"
  )
  if (!all(required %in% names(dataset))) return(data.frame())

  arrival <- as.POSIXct(dataset$arrival_datetime, tz = "UTC")
  decision <- as.POSIXct(dataset$disposition_decision_datetime, tz = "UTC")
  discharge <- as.POSIXct(dataset$discharge_datetime, tz = "UTC")
  pre <- suppressWarnings(as.numeric(dataset$pre_disposition_los_min))
  post <- suppressWarnings(as.numeric(dataset$post_disposition_los_min))
  total <- suppressWarnings(as.numeric(dataset$los_min))
  tolerance <- 0.5

  check_result <- function(description, complete, failed) {
    evaluated <- sum(complete)
    violations <- sum(complete & failed)
    data.frame(
      Check = description,
      Evaluated = evaluated,
      Violations = violations,
      Status = if (violations == 0L) "Pass" else "Review",
      check.names = FALSE
    )
  }

  chronology_complete <- !is.na(arrival) & !is.na(decision) & !is.na(discharge)
  pre_complete <- !is.na(arrival) & !is.na(decision) & !is.na(pre)
  post_complete <- !is.na(decision) & !is.na(discharge) & !is.na(post)
  total_complete <- !is.na(pre) & !is.na(post) & !is.na(total)
  non_negative_complete <- !is.na(pre) & !is.na(post) & !is.na(total)

  rbind(
    check_result(
      "Arrival <= decision <= discharge",
      chronology_complete,
      arrival > decision | decision > discharge
    ),
    check_result(
      "Pre-disposition LOS matches timestamps",
      pre_complete,
      abs(as.numeric(difftime(decision, arrival, units = "mins")) - pre) > tolerance
    ),
    check_result(
      "Post-disposition LOS matches timestamps",
      post_complete,
      abs(as.numeric(difftime(discharge, decision, units = "mins")) - post) > tolerance
    ),
    check_result(
      "Pre + post LOS equals total LOS",
      total_complete,
      abs(pre + post - total) > tolerance
    ),
    check_result(
      "Timing durations are non-negative",
      non_negative_complete,
      pre < 0 | post < 0 | total < 0
    )
  )
}

summarize_categorical_long <- function(
  dataset,
  specification,
  variable,
  max_coded_levels = 20L
) {
  row <- specification[specification$source_name == variable, , drop = FALSE]
  values <- as.character(dataset[[variable]])
  values[is.na(values) | !nzchar(trimws(values))] <- "Missing"

  if (identical(row$analytic_type[[1L]], "binary_flag")) {
    values[values == "0"] <- "No"
    values[values == "1"] <- "Yes"
  }

  counts <- table(values, useNA = "no")
  analytic_type <- row$analytic_type[[1L]]

  if (identical(analytic_type, "ordinal_score") && nzchar(row$allowed_values[[1L]])) {
    specified_levels <- strsplit(row$allowed_values[[1L]], "|", fixed = TRUE)[[1L]]
    observed_levels <- names(counts)
    ordered_levels <- c(
      specified_levels[specified_levels %in% observed_levels],
      sort(setdiff(observed_levels, c(specified_levels, "Missing"))),
      if ("Missing" %in% observed_levels) "Missing" else character()
    )
    counts <- counts[ordered_levels]
  } else if (identical(analytic_type, "coded_category")) {
    missing_count <- if ("Missing" %in% names(counts)) counts[["Missing"]] else 0L
    nonmissing_counts <- sort(counts[names(counts) != "Missing"], decreasing = TRUE)
    if (length(nonmissing_counts) > max_coded_levels) {
      other_count <- sum(nonmissing_counts[-seq_len(max_coded_levels)])
      nonmissing_counts <- c(
        nonmissing_counts[seq_len(max_coded_levels)],
        Other = other_count
      )
    }
    counts <- nonmissing_counts
    if (missing_count > 0L) counts <- c(counts, Missing = missing_count)
  } else {
    missing_count <- if ("Missing" %in% names(counts)) counts[["Missing"]] else 0L
    counts <- sort(counts[names(counts) != "Missing"], decreasing = TRUE)
    if (missing_count > 0L) counts <- c(counts, Missing = missing_count)
  }

  total <- sum(counts)
  data.frame(
    Source = variable,
    Variable = variable_label(specification, variable, include_unit = FALSE),
    Category = names(counts),
    `Count n (%)` = sprintf(
      "%d (%.1f%%)",
      as.integer(counts),
      if (total > 0L) 100 * counts / total else NA_real_
    ),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

build_dataset_profile <- function(dataset, specification, dataset_name) {
  schema <- validate_dataset_schema(dataset, specification, dataset_name)
  continuous_variables <- variables_for(specification, "continuous", "main")
  timing_variables <- variables_for(specification, "continuous", "timing")
  categorical_variables <- variables_for(specification, "categorical", "main")

  summarize_continuous_set <- function(data, variables) {
    rows <- lapply(variables, function(variable) {
      summarize_continuous(
        data,
        variable,
        variable_label(specification, variable, include_unit = TRUE)
      )
    })
    if (length(rows)) do.call(rbind, rows) else data.frame()
  }

  continuous_summary <- summarize_continuous_set(dataset, continuous_variables)
  categorical_rows <- lapply(categorical_variables, function(variable) {
    summarize_categorical_long(dataset, specification, variable)
  })
  categorical_summary <- if (length(categorical_rows)) {
    do.call(rbind, categorical_rows)
  } else {
    data.frame()
  }

  timing_eligible <- rep(TRUE, nrow(dataset))
  if ("timing_quality_flag" %in% names(dataset)) {
    timing_status <- trimws(tolower(as.character(dataset$timing_quality_flag)))
    timing_eligible <- !is.na(timing_status) & timing_status == "pass"
  }
  timing_summary <- summarize_continuous_set(
    dataset[timing_eligible, , drop = FALSE],
    timing_variables
  )

  fiscal_year_variables <- variables_for(specification, "coverage", "coverage")
  fiscal_year_coverage <- lapply(fiscal_year_variables, function(variable) {
    values <- as.character(dataset[[variable]])
    values <- sort(unique(values[!is.na(values) & nzchar(trimws(values))]))
    data.frame(
      Variable = variable_label(specification, variable, include_unit = FALSE),
      Coverage = if (length(values)) paste(values, collapse = ", ") else "Missing",
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  })
  fiscal_year_coverage <- if (length(fiscal_year_coverage)) {
    do.call(rbind, fiscal_year_coverage)
  } else {
    data.frame()
  }

  list(
    specification = specification,
    schema = schema,
    continuous_variables = continuous_variables,
    timing_variables = timing_variables,
    categorical_variables = categorical_variables,
    continuous = continuous_summary,
    timing = timing_summary,
    categorical = categorical_summary,
    datetime_coverage = summarize_datetime_coverage(dataset, specification),
    fiscal_year_coverage = fiscal_year_coverage,
    quality = summarize_quality_status(dataset, specification),
    timing_checks = if (toupper(dataset_name) == "NACRS") {
      nacrs_timing_checks(dataset)
    } else {
      data.frame()
    },
    record_count = nrow(dataset),
    timing_eligible_count = sum(timing_eligible),
    timing_excluded_count = sum(!timing_eligible)
  )
}

render_standard_table <- function(data, caption, table_class = "summary-table") {
  if (nrow(data) == 0L) return(invisible(NULL))
  cat('<div class="table-scroll">')
  print(knitr::kable(
    data,
    format = "html",
    row.names = FALSE,
    escape = FALSE,
    table.attr = paste0('class="', table_class, '"'),
    caption = caption
  ))
  cat("</div>\n\n")
  invisible(NULL)
}

prepare_continuous_display <- function(summary) {
  if (nrow(summary) == 0L) return(summary)
  display <- summary[
    ,
    setdiff(names(summary), c("NonFinite", "Analyzed")),
    drop = FALSE
  ]
  names(display)[names(display) == "Mean_SD"] <- "Mean (SD)"
  names(display)[names(display) == "Min_Max"] <- "Min-Max"
  names(display)[names(display) == "NonMissing"] <- "Non-missing"
  names(display)[names(display) == "MissingPct"] <- "Missing %"
  display
}

render_categorical_cards <- function(summary, specification) {
  if (nrow(summary) == 0L) return(invisible(NULL))

  for (variable in unique(summary$Source)) {
    variable_summary <- summary[
      summary$Source == variable,
      c("Category", "Count n (%)"),
      drop = FALSE
    ]
    missing_row <- variable_summary$Category == "Missing"
    variable_summary$Category <- as.character(
      htmltools::htmlEscape(variable_summary$Category)
    )
    variable_summary[["Count n (%)"]] <- as.character(
      htmltools::htmlEscape(variable_summary[["Count n (%)"]])
    )
    variable_summary$Category[missing_row] <- paste0(
      '<span class="missing-category">Missing</span>',
      '<span class="missing-na-badge">NA</span>'
    )

    title <- variable_label(specification, variable, include_unit = FALSE)
    card_class <- if (nrow(variable_summary) > 20L) {
      "category-table-card long-table"
    } else {
      "category-table-card"
    }
    cat("#### ", title, "\n\n", sep = "")
    cat(
      '<div class="variable-code"><code>',
      htmltools::htmlEscape(variable),
      "</code></div>",
      sep = ""
    )
    cat('<div class="', card_class, '">', sep = "")
    print(knitr::kable(
      variable_summary,
      format = "html",
      escape = FALSE,
      row.names = FALSE,
      align = c("l", "r"),
      table.attr = 'class="summary-table categorical-summary-table"'
    ))
    cat("</div>\n\n")
  }
  invisible(NULL)
}

render_dataset_profile <- function(profile, dataset_name) {
  specification <- profile$specification
  cat(
    "The variable registry maps **", profile$schema$Present,
    " of ", profile$schema$Registered, "** registered ", dataset_name,
    " variables. The loaded data contain **", profile$record_count,
    "** records.\n\n",
    sep = ""
  )

  cat("## Coverage\n\n")
  if (nrow(profile$datetime_coverage) > 0L) {
    cat("Datetime ranges are displayed in UTC.\n\n")
    render_standard_table(
      profile$datetime_coverage,
      paste(dataset_name, "datetime coverage"),
      "summary-table"
    )
  }
  if (nrow(profile$fiscal_year_coverage) > 0L) {
    render_standard_table(
      profile$fiscal_year_coverage,
      paste(dataset_name, "reporting-period coverage"),
      "summary-table"
    )
  }

  cat("## Main measures\n\n")
  cat(
    "The registry selects **", length(profile$continuous_variables),
    "** continuous measures and **", length(profile$categorical_variables),
    "** categorical measures for the main profile.\n\n",
    sep = ""
  )
  if (nrow(profile$continuous) > 0L) {
    cat("### Continuous measures\n\n")
    render_standard_table(
      prepare_continuous_display(profile$continuous),
      paste("Selected", dataset_name, "continuous measures"),
      "summary-table continuous-summary-table"
    )
  }

  if (nrow(profile$timing) > 0L) {
    cat("### Timing measures\n\n")
    cat(
      "Timing summaries use **", profile$timing_eligible_count,
      "** quality-eligible records and exclude **",
      profile$timing_excluded_count,
      "** records. Excluded records remain visible in the Data quality section.\n\n",
      sep = ""
    )
    render_standard_table(
      prepare_continuous_display(profile$timing),
      paste("Quality-eligible", dataset_name, "timing measures"),
      "summary-table continuous-summary-table"
    )
  }

  if (nrow(profile$categorical) > 0L) {
    cat("### Categorical measures\n\n")
    cat(
      "Each variable is displayed separately. Coded variables show up to the ",
      "20 most frequent codes, followed by Other and Missing where applicable.\n\n",
      sep = ""
    )
    render_categorical_cards(profile$categorical, specification)
  }

  cat("## Data quality\n\n")
  if (nrow(profile$quality) > 0L) {
    render_standard_table(
      profile$quality,
      paste(dataset_name, "quality-status distribution"),
      "summary-table categorical-summary-table"
    )
  } else {
    cat("No public quality-status variables are registered for this data set.\n\n")
  }
  if (nrow(profile$timing_checks) > 0L) {
    render_standard_table(
      profile$timing_checks,
      paste(dataset_name, "timing consistency checks"),
      "summary-table"
    )
  }

  cat("### Variable handling\n\n")
  cat(
    "Identifiers and internal provenance fields are registered for schema ",
    "validation but are excluded from public summary tables. Missing values ",
    "remain distinct from valid zero values.\n\n",
    sep = ""
  )
  invisible(NULL)
}
