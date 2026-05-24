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
  if (is.null(ms)) {
    return(lubridate::NA_POSIXct_)
  }
  # Don't short-circuit on `all(is.na(ms))` — returning the length-1
  # `NA_POSIXct_` from there would get recycled by `data.table::set()`
  # into the existing column's storage type rather than replacing the
  # column with a POSIXct one. Always return a vector matching input
  # length so columns documented as POSIXct actually land as POSIXct,
  # even when every upstream value is missing. Matches binance/alpaca.
  # `suppressWarnings()` silences the "NAs introduced by coercion"
  # message that `as.numeric()` emits when the input is character `NA`
  # — that NA → NA path is the documented contract, not a problem.
  return(lubridate::as_datetime(suppressWarnings(as.numeric(ms)) / 1000))
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
  if (is.null(ns)) {
    return(lubridate::NA_POSIXct_)
  }
  # Same all-NA shape contract as `ms_to_datetime`, and the same
  # `suppressWarnings()` rationale for character `NA` input.
  return(lubridate::as_datetime(suppressWarnings(as.numeric(ns)) / 1e9))
}

#' Collapse a Plain-String Array Field on a Single Record
#'
#' Walks the named list `x` and replaces any named field whose value is a
#' length >= 1 list of plain character strings (or atomic character vector)
#' with a single semicolon-separated character scalar. Used to apply
#' Treatment A (`;`-collapse for arrays of plain strings) so we get one row
#' per entity instead of a list column or an exploded long row count.
#'
#' Ported from the same-named helper in binance/alpaca. Separator is `;`
#' rather than `,` because semicolons are far less likely to appear inside
#' any of the joined values themselves. Recover with
#' `strsplit(x, ";", fixed = TRUE)[[1]]`.
#'
#' NA-safe: scalar `NA_character_` input is preserved as `NA_character_`;
#' mixed vectors like `c("real", NA)` filter NAs before joining (without
#' this, `paste(c("real", NA), collapse = ";")` would produce the literal
#' string `"real;NA"`); all-NA vectors round-trip to `NA_character_`.
#'
#' If any individual value contains a literal `;`, emits a once-per-session
#' warning so we catch silent corruption.
#'
#' @param x A named list representing a single API record.
#' @param fields Character vector; names of fields to collapse.
#' @return The same named list with the matching fields collapsed in place.
#'
#' @keywords internal
#' @noRd
collapse_string_array_fields <- function(x, fields) {
  for (nm in fields) {
    val <- x[[nm]]
    if (is.null(val) || length(val) == 0L) {
      x[[nm]] <- NA_character_
      next
    }
    if (is.list(val)) {
      val <- unlist(val, use.names = FALSE)
    }
    if (is.atomic(val) && length(val) >= 1L) {
      val_chr <- as.character(val)
      val_chr <- val_chr[!is.na(val_chr)]
      if (length(val_chr) == 0L) {
        x[[nm]] <- NA_character_
        next
      }
      if (any(grepl(";", val_chr, fixed = TRUE), na.rm = TRUE)) {
        rlang::warn(
          paste0(
            "Field `",
            nm,
            "` contains a literal `;` which collides with the ",
            "collapse separator. Joining anyway; downstream code that splits ",
            "on `;` will see corrupted values. Please report this so we can ",
            "switch the separator for this field."
          ),
          .frequency = "once",
          .frequency_id = paste0("collapse_sep_collision_", nm)
        )
      }
      x[[nm]] <- paste(val_chr, collapse = ";")
    }
  }
  return(x)
}

#' Apply a Function to Selected Columns of a data.table by Reference
#'
#' Walks `cols`; for each that exists in `dt`, replaces it in place with the
#' result of `fn(dt[[col]])`. Columns that are not in `dt` are silently
#' skipped — useful for endpoints whose payload sometimes omits optional
#' fields. A zero-row `dt` short-circuits.
#'
#' Replaces the repeated boilerplate of
#' `if (nrow(dt) > 0 && "X" %in% names(dt)) { dt[, X := fn(X)] }`
#' with `coerce_cols(dt, "X", fn)`. Modifies `dt` by reference via
#' `data.table::set()`. Same shape and contract as the same-named helper
#' in binance/alpaca.
#'
#' @param dt A [data.table::data.table].
#' @param cols Character; candidate column names to convert.
#' @param fn Function; takes a column vector, returns the coerced vector.
#' @return `dt`, modified by reference and returned invisibly.
#'
#' @keywords internal
#' @noRd
coerce_cols <- function(dt, cols, fn) {
  if (nrow(dt) == 0L) {
    return(invisible(dt))
  }
  # `unique()` prevents double-coercion when a caller passes the same
  # column name twice (e.g. `coerce_cols(dt, c("time", "time"),
  # ms_to_datetime)` would otherwise re-feed the already-converted
  # POSIXct vector back through `as.numeric / 1000 / as_datetime`, which
  # produces wildly wrong values silently).
  for (col in unique(cols)) {
    if (col %in% names(dt)) {
      data.table::set(dt, j = col, value = fn(dt[[col]]))
    }
  }
  return(invisible(dt))
}

#' Process Orderbook Data into a data.table
#'
#' Transforms the bids/asks arrays from a KuCoin orderbook response into a
#' tidy [data.table::data.table]. KuCoin returns best price first, so the
#' `level` column captures the 1-indexed depth from top-of-book (1 = best
#' bid / best ask); the position would otherwise be lost after any sort or
#' filter. Matches the cross-package long-format convention.
#'
#' @param data List; the parsed KuCoin orderbook response data containing
#'   `bids`, `asks`, `time`, and `sequence` fields.
#' @return A [data.table::data.table] with columns: `time`, `sequence`,
#'   `side`, `level`, `price`, `size`.
#'
#' @keywords internal
#' @noRd
parse_orderbook <- function(data) {
  parse_side <- function(entries, side_label) {
    if (is.null(entries) || length(entries) == 0) {
      return(data.table::data.table(
        side = character(),
        level = integer(),
        price = numeric(),
        size = numeric()
      )[])
    }
    # Each entry is a list of two strings: [price, quantity]. KuCoin
    # returns best price first, so the 1-indexed position is depth from
    # top-of-book (`level = 1` is the best bid / best ask). Matches the
    # cross-package long-format convention (alpaca / binance both add a
    # position-index column where the source order is meaningful).
    return(data.table::data.table(
      side = side_label,
      level = seq_along(entries),
      price = as.numeric(vapply(entries, `[[`, character(1), 1L)),
      size = as.numeric(vapply(entries, `[[`, character(1), 2L))
    )[])
  }

  bids_dt <- parse_side(data$bids, "bid")
  asks_dt <- parse_side(data$asks, "ask")
  result <- data.table::rbindlist(list(bids_dt, asks_dt))

  result[, time := ms_to_datetime(data$time)]
  result[, sequence := as.character(data$sequence)]
  data.table::setcolorder(result, c("time", "sequence", "side", "level", "price", "size"))

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
      return(data.table::rbindlist(
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
          return(data.table::as.data.table(cleaned))
        }),
        fill = TRUE
      ))
    }),
    fill = TRUE
  )
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt[])
}
