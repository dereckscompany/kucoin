# File: R/helpers_parse.R
# Response parsing and data.table construction helpers.
#
# The generic JSON -> data.table toolkit (to_snake_case, as_dt_row, as_dt_list)
# is shared across connectors and lives in connectcore; it is imported in
# imports.R rather than duplicated here. KuCoin-specific parsers (orderbook,
# klines, paginated flatten) and the timestamp/coercion helpers whose behaviour
# the test-suite pins (ms/ns conversion shape contracts, coerce_cols dedup, the
# `;`-collapse warning id) stay here.

#' Convert a KuCoin Millisecond Timestamp to POSIXct
#'
#' @param ms (any | NULL) millisecond Unix timestamp(s); the raw JSON value,
#'   whose R type is unconstrained (numeric, character, or an all-NA logical).
#' @return (class<POSIXct>) a POSIXct vector in UTC (length matching `ms`), `NA`
#'   where `ms` is NULL/NA.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
ms_to_datetime <- function(ms) {
  assert_args_ms_to_datetime(ms)
  if (is.null(ms)) {
    return(assert_return_ms_to_datetime(lubridate::NA_POSIXct_))
  }
  # Don't short-circuit on `all(is.na(ms))` — returning the length-1
  # `NA_POSIXct_` from there would get recycled by `data.table::set()`
  # into the existing column's storage type rather than replacing the
  # column with a POSIXct one. Always return a vector matching input
  # length so columns documented as POSIXct actually land as POSIXct,
  # even when every upstream value is missing. Matches binance/alpaca.
  if (is.numeric(ms)) {
    return(assert_return_ms_to_datetime(lubridate::as_datetime(ms / 1000)))
  }
  # Character path. Only feed real (non-NA) values to `as.numeric()` so
  # the documented NA-in -> NA-out contract is silent, but a genuinely
  # malformed string (e.g. `"not-a-number"`) still triggers the usual
  # "NAs introduced by coercion" warning. `suppressWarnings()` here
  # would silence real bugs too.
  result <- rep(NA_real_, length(ms))
  not_na <- !is.na(ms)
  if (any(not_na)) {
    result[not_na] <- as.numeric(ms[not_na])
  }
  return(assert_return_ms_to_datetime(lubridate::as_datetime(result / 1000)))
}

#' Convert a KuCoin Nanosecond Timestamp to POSIXct
#'
#' @param ns (any | NULL) nanosecond Unix timestamp(s); the raw JSON value,
#'   whose R type is unconstrained (numeric, character, or an all-NA logical).
#' @return (class<POSIXct>) a POSIXct vector in UTC (length matching `ns`), `NA`
#'   where `ns` is NULL/NA.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
ns_to_datetime <- function(ns) {
  assert_args_ns_to_datetime(ns)
  if (is.null(ns)) {
    return(assert_return_ns_to_datetime(lubridate::NA_POSIXct_))
  }
  # Same all-NA shape contract as `ms_to_datetime`, and the same
  # only-feed-real-values-to-`as.numeric` strategy so the NA-in ->
  # NA-out contract is silent without hiding genuine bad input.
  if (is.numeric(ns)) {
    return(assert_return_ns_to_datetime(lubridate::as_datetime(ns / 1e9)))
  }
  result <- rep(NA_real_, length(ns))
  not_na <- !is.na(ns)
  if (any(not_na)) {
    result[not_na] <- as.numeric(ns[not_na])
  }
  return(assert_return_ns_to_datetime(lubridate::as_datetime(result / 1e9)))
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
#' @param x (list) a named list representing a single API record.
#' @param fields (vector<character, 0..>) names of fields to collapse.
#' @return (list) the same named list with the matching fields collapsed in
#'   place.
#'
#' @keywords internal
#' @noRd
collapse_string_array_fields <- function(x, fields) {
  assert_args_collapse_string_array_fields(x, fields)
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
  return(assert_return_collapse_string_array_fields(x))
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
#' @param dt (class<data.table>) the table to modify.
#' @param cols (vector<character, 0..>) candidate column names to convert.
#' @param fn (function) takes a column vector, returns the coerced vector.
#' @return (class<data.table>) `dt`, modified by reference and returned
#'   invisibly.
#'
#' @keywords internal
#' @noRd
coerce_cols <- function(dt, cols, fn) {
  assert_args_coerce_cols(dt, cols, fn)
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
  return(invisible(assert_return_coerce_cols(dt)))
}

#' Coerce KuCoin Number-as-String Columns to Numeric
#'
#' KuCoin transports numeric quantities (prices, sizes, amounts, fees, rates,
#' balances, ...) as JSON strings to avoid float rounding in transit. This
#' coerces every such column that is present to `numeric`, so the client
#' receives a usable number rather than a verbatim string. The set was derived
#' from a live sweep of the API: a column qualifies only where every real value
#' it returns is numeric-coercible and it is not an identifier. Identifiers,
#' symbols, currencies, statuses, enums and flags are left as-is; timestamps are
#' handled separately. Applied centrally between parse and contract validation
#' (see [KucoinBase]'s request funnel), so it runs once per endpoint over
#' whichever of these columns that endpoint returns. Order *input* prices/sizes
#' are unaffected — they are validated as strings before the request is sent.
#'
#' @param x (any) a parser result; coerced only when it is a `data.table`.
#' @return (any) `x`, with its numeric-quantity columns coerced to numeric.
#'
#' @keywords internal
#' @noRd
#' @noassert
coerce_numeric_quantities <- function(x) {
  if (!data.table::is.data.table(x)) {
    return(x)
  }
  quantities <- c(
    "amount",
    "annualized_borrow_rate",
    "auto_renew_max_debt_ratio",
    "available",
    "available_amount",
    "average_price",
    "balance",
    "base_amount",
    "base_asset_available",
    "base_asset_hold",
    "base_asset_liability",
    "base_asset_liability_interest",
    "base_asset_liability_principal",
    "base_asset_max_borrow_size",
    "base_asset_total",
    "base_borrow_coefficient",
    "base_borrow_min_amount",
    "base_borrow_min_unit",
    "base_currency_price",
    "base_increment",
    "base_margin_coefficient",
    "base_max_borrow_amount",
    "base_max_buy_amount",
    "base_max_hold_amount",
    "base_max_size",
    "base_min_size",
    "best_ask",
    "best_ask_price",
    "best_ask_size",
    "best_bid",
    "best_bid_price",
    "best_bid_size",
    "borrow_coefficient",
    "borrow_max_amount",
    "borrow_min_amount",
    "borrow_min_unit",
    "buy",
    "buy_max_amount",
    "callauction_price_ceiling",
    "callauction_price_floor",
    "change_price",
    "change_rate",
    "collateral_ratio",
    "debt_ratio",
    "deposit_min_size",
    "fee",
    "fl_debt_ratio",
    "high",
    "hold",
    "hold_max_amount",
    "holds",
    "hourly_borrow_rate",
    "increment",
    "inner_withdraw_min_fee",
    "interest_increment",
    "last",
    "last_size",
    "liability",
    "liability_interest",
    "liability_principal",
    "limit_btc_amount",
    "limit_quota_currency_amount",
    "liq_debt_ratio",
    "locked_amount",
    "low",
    "lower_limit",
    "maker_coefficient",
    "maker_fee_coefficient",
    "maker_fee_rate",
    "margin_coefficient",
    "market_interest_rate",
    "max_borrow_size",
    "max_deposit",
    "max_interest_rate",
    "max_purchase_size",
    "min_funds",
    "min_interest_rate",
    "min_purchase_size",
    "open",
    "open_interest",
    "price",
    "price_change",
    "price_change_percent",
    "price_increment",
    "price_limit_rate",
    "quote_asset_available",
    "quote_asset_hold",
    "quote_asset_liability",
    "quote_asset_liability_interest",
    "quote_asset_liability_principal",
    "quote_asset_max_borrow_size",
    "quote_asset_total",
    "quote_borrow_coefficient",
    "quote_borrow_min_amount",
    "quote_borrow_min_unit",
    "quote_increment",
    "quote_margin_coefficient",
    "quote_max_borrow_amount",
    "quote_max_buy_amount",
    "quote_max_hold_amount",
    "quote_max_size",
    "quote_min_size",
    "remain_amount",
    "sell",
    "size",
    "taker_coefficient",
    "taker_fee_coefficient",
    "taker_fee_rate",
    "total",
    "total_asset_of_quote_currency",
    "total_liability_of_quote_currency",
    "transferable",
    "upper_limit",
    "used_btc_amount",
    "used_quota_currency_amount",
    "vol",
    "vol_value",
    "warning_debt_ratio",
    "withdraw_fee_rate",
    "withdraw_max_fee",
    "withdraw_min_fee",
    "withdraw_min_size",
    "withdrawal_min_fee",
    "withdrawal_min_size"
  )
  coerce_cols(x, quantities, as.numeric)
  return(x[])
}

#' Process Orderbook Data into a data.table
#'
#' Transforms the bids/asks arrays from a KuCoin orderbook response into a
#' tidy [data.table::data.table]. KuCoin returns best price first, so the
#' `level` column captures the 1-indexed depth from top-of-book (1 = best
#' bid / best ask); the position would otherwise be lost after any sort or
#' filter. Matches the cross-package long-format convention.
#'
#' @param data (list) the parsed KuCoin orderbook response data containing
#'   `bids`, `asks`, `time`, and `sequence` fields.
#' @return (Orderbook) one row per price level per side, best price first.
#'
#' @keywords internal
#' @noRd
parse_orderbook <- function(data) {
  assert_args_parse_orderbook(data)
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

  return(assert_return_parse_orderbook(result[]))
}

# The fixed-shape kline parsers' empty branches return this fully-typed zero-row
# table (columns and types EXACTLY matching the `Klines` shape and the non-empty
# branch) so a method's column contract still holds on an empty result. The
# `datetime` column is built with `lubridate::as_datetime()` on a zero-length
# vector so class and tz match the populated case. Mirrors its shape; not
# asserted.

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_klines <- function() {
  return(data.table::data.table(
    datetime = lubridate::as_datetime(numeric(0)),
    open = numeric(0),
    high = numeric(0),
    low = numeric(0),
    close = numeric(0),
    volume = numeric(0),
    turnover = numeric(0)
  ))
}

#' Parse Raw KuCoin Kline Data into a data.table
#'
#' Converts the array-of-arrays response from KuCoin's klines endpoint into
#' a typed [data.table::data.table] with standard OHLCV columns.
#' Each candle is returned as `[timestamp, open, close, high, low, volume, turnover]`.
#'
#' @param data (list | NULL) the raw kline response from KuCoin (a list of
#'   7-element character vectors), or NULL.
#' @return (Klines) one row per candle. Empty if `data` is NULL or empty.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
parse_klines <- function(data) {
  assert_args_parse_klines(data)
  if (is.null(data) || length(data) == 0) {
    return(assert_return_parse_klines(empty_dt_klines()))
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
  return(assert_return_parse_klines(dt[]))
}

#' Flatten Paginated Results into a data.table
#'
#' Takes the accumulator list from [kucoin_paginate()] and row-binds all items
#' into a single [data.table::data.table] with snake_case column names.
#'
#' @param pages (list) each element is one page's items from the API.
#' @return (class<data.table>) the row-bound table; empty if `pages` is empty.
#'
#' @keywords internal
#' @noRd
flatten_pages <- function(pages) {
  assert_args_flatten_pages(pages)
  if (length(pages) == 0) {
    return(assert_return_flatten_pages(data.table::data.table()[]))
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
  return(assert_return_flatten_pages(dt[]))
}
