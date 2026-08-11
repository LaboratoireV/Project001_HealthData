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
