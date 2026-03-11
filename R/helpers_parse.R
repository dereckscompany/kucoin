# File: R/helpers_parse.R
# Response parsing and data.table construction helpers.

#' Convert camelCase Names to snake_case
#'
#' Converts column names from KuCoin's camelCase convention to R's
#' snake_case convention. Handles consecutive uppercase letters (e.g.,
#' `"clientOid"` -> `"client_oid"`, `"isMarginEnabled"` -> `"is_margin_enabled"`).
#'
#' @param names Character vector; names to convert.
#' @return Character vector; converted snake_case names.
#'
#' @keywords internal
#' @noRd
to_snake_case <- function(names) {
  # Insert underscore before uppercase letters that follow lowercase/digit

  out <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", names)
  # Insert underscore between consecutive uppercase and following lowercase
  out <- gsub("([A-Z])([A-Z][a-z])", "\\1_\\2", out)
  out <- tolower(out)
  return(out)
}

#' Convert a List or Named List to a data.table Row
#'
#' Converts a flat named list (typically from a KuCoin API JSON response)
#' into a single-row [data.table::data.table]. NULL values become NA.
#' Column names are converted to snake_case.
#'
#' @param x A named list.
#' @return A single-row [data.table::data.table] with snake_case column names.
#'
#' @keywords internal
#' @noRd
as_dt_row <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(data.table::data.table()[])
  }
  x <- lapply(x, function(val) {
    if (is.null(val)) {
      return(NA)
    }
    if (is.list(val) && length(val) == 0) {
      return(NA)
    }
    # NOTE: lists with length >= 1 (e.g. annType = list("a", "b")) must be wrapped
    # in list() so data.table stores them as a single list-column entry instead
    # of recycling rows.
    if (is.list(val) && length(val) >= 1) {
      return(list(val))
    }
    return(val)
  })
  dt <- data.table::as.data.table(x)
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt[])
}

#' Convert a List of Lists to a data.table
#'
#' Takes a list where each element is a named list (e.g., from a JSON array)
#' and row-binds them into a [data.table::data.table] with snake_case columns.
#'
#' @param items A list of named lists, or NULL.
#' @return A [data.table::data.table]. Returns an empty data.table if `items` is NULL or empty.
#'
#' @keywords internal
#' @noRd
as_dt_list <- function(items) {
  if (is.null(items) || length(items) == 0) {
    return(data.table::data.table()[])
  }
  dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
  return(dt[])
}

#' Convert a KuCoin Millisecond Timestamp to POSIXct
#'
#' @param ms Numeric; millisecond Unix timestamp.
#' @return POSIXct in UTC, or NA if `ms` is NULL/NA.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
ms_to_datetime <- function(ms) {
  if (is.null(ms) || all(is.na(ms))) {
    return(lubridate::NA_POSIXct_)
  }
  return(lubridate::as_datetime(as.numeric(ms) / 1000))
}

#' Convert a KuCoin Nanosecond Timestamp to POSIXct
#'
#' @param ns Numeric; nanosecond Unix timestamp.
#' @return POSIXct in UTC, or NA if `ns` is NULL/NA.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
ns_to_datetime <- function(ns) {
  if (is.null(ns) || all(is.na(ns))) {
    return(lubridate::NA_POSIXct_)
  }
  return(lubridate::as_datetime(as.numeric(ns) / 1e9))
}

#' Process Orderbook Data into a data.table
#'
#' Transforms the bids/asks arrays from a KuCoin orderbook response into a
#' tidy [data.table::data.table] with `side`, `price`, and `size` columns.
#'
#' @param data List; the parsed KuCoin orderbook response data containing
#'   `bids`, `asks`, `time`, and `sequence` fields.
#' @return A [data.table::data.table] with columns: `time`, `sequence`,
#'   `side`, `price`, `size`.
#'
#' @keywords internal
#' @noRd
parse_orderbook <- function(data) {
  parse_side <- function(entries, side_label) {
    if (is.null(entries) || length(entries) == 0) {
      return(data.table::data.table(
        side = character(),
        price = numeric(),
        size = numeric()
      )[])
    }
    # Each entry is a list of two strings: [price, quantity].
    return(data.table::data.table(
      side = side_label,
      price = as.numeric(vapply(entries, `[[`, character(1), 1L)),
      size = as.numeric(vapply(entries, `[[`, character(1), 2L))
    )[])
  }

  bids_dt <- parse_side(data$bids, "bid")
  asks_dt <- parse_side(data$asks, "ask")
  result <- data.table::rbindlist(list(bids_dt, asks_dt))

  result[, time := ms_to_datetime(data$time)]
  result[, sequence := as.character(data$sequence)]
  data.table::setcolorder(result, c("time", "sequence", "side", "price", "size"))

  return(result[])
}

#' Parse Raw KuCoin Kline Data into a data.table
#'
#' Converts the array-of-arrays response from KuCoin's klines endpoint into
#' a typed [data.table::data.table] with standard OHLCV columns.
#' Each candle is returned as `[timestamp, open, close, high, low, volume, turnover]`.
#'
#' @param data List of character vectors; the raw kline response from KuCoin.
#' @return A [data.table::data.table] with columns: `datetime`, `open`, `high`,
#'   `low`, `close`, `volume`, `turnover`. Returns empty data.table if input is
#'   NULL or empty.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
parse_klines <- function(data) {
  if (is.null(data) || length(data) == 0) {
    return(data.table::data.table()[])
  }
  # KuCoin returns: [timestamp, open, close, high, low, volume, turnover]
  # We reorder to standard OHLCV: datetime, open, high, low, close, volume, turnover
  # Each candle is a list of 7 character strings.
  dt <- data.table::data.table(
    datetime = lubridate::as_datetime(as.numeric(vapply(data, `[[`, character(1), 1L))),
    open = as.numeric(vapply(data, `[[`, character(1), 2L)),
    high = as.numeric(vapply(data, `[[`, character(1), 4L)),
    low = as.numeric(vapply(data, `[[`, character(1), 5L)),
    close = as.numeric(vapply(data, `[[`, character(1), 3L)),
    volume = as.numeric(vapply(data, `[[`, character(1), 6L)),
    turnover = as.numeric(vapply(data, `[[`, character(1), 7L))
  )
  return(dt[])
}

#' Flatten Paginated Results into a data.table
#'
#' Takes the accumulator list from [kucoin_paginate()] and row-binds all items
#' into a single [data.table::data.table] with snake_case column names.
#'
#' @param pages List of lists; each element is one page's items from the API.
#' @return A [data.table::data.table].
#'
#' @keywords internal
#' @noRd
flatten_pages <- function(pages) {
  if (length(pages) == 0) {
    return(data.table::data.table()[])
  }

  dt <- data.table::rbindlist(
    lapply(pages, function(page) {
      data.table::rbindlist(
        lapply(page, function(item) {
          cleaned <- lapply(item, function(v) {
            if (is.null(v)) {
              return(NA)
            }
            if (is.list(v) && length(v) == 0) {
              return(NA)
            }
            if (is.list(v) && length(v) >= 1) {
              return(list(v))
            }
            return(v)
          })
          data.table::as.data.table(cleaned)
        }),
        fill = TRUE
      )
    }),
    fill = TRUE
  )
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt[])
}
