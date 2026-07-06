# File: R/backfill.R
# Batch backfill of kline (OHLCV) data across multiple symbols and timeframes,
# with CSV-based resume support.

#' Backfill KuCoin Kline Data to CSV
#'
#' Downloads historical OHLCV candlestick data for one or more trading pairs and
#' timeframes, writing results incrementally to a CSV file. Supports resuming
#' from a partially completed backfill by reading the existing file and skipping
#' symbol-timeframe combinations that are already up to date.
#'
#' @param symbols (vector<character, 1..>) trading pair symbols (e.g.,
#'   `c("BTC-USDT", "ETH-USDT")`). Must not be NULL or empty.
#' @param timeframes (vector<character, 1..>) candle timeframes (e.g.,
#'   `c("1day", "1hour")`). Valid values are the names of the internal timeframe
#'   map: `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`,
#'   `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`,
#'   `"1month"`.
#' @param from (POSIXct | scalar<numeric>) start of the backfill window. Defaults
#'   to one year ago. Values before `"2017-01-01"` (or `-Inf`) are clamped to
#'   `"2017-01-01"` since KuCoin data does not exist before that date.
#' @param to (POSIXct | scalar<numeric>) end of the backfill window. Defaults to
#'   current time. `Inf` is replaced with current time.
#' @param file (scalar<character>) path to the output CSV file. Data is appended
#'   incrementally so progress is saved even if the process is interrupted.
#' @param base_url (scalar<character>) KuCoin API base URL.
#' @param sleep (scalar<numeric in [0, Inf[>) seconds to sleep between each
#'   symbol-timeframe combination to respect rate limits.
#' @param verbose (scalar<logical>) if `TRUE`, prints progress messages via
#'   [rlang::inform()].
#'
#' @return (scalar<character>) the file path (invisibly).
#'
#'   Per-combo failures are surfaced as warnings during the run (one
#'   [rlang::warn()] per failed `(symbol, timeframe)` pair, with the underlying
#'   error message). After the loop, if any combinations failed, a final summary
#'   warning lists the count and the affected pairs. No failure data is hidden on
#'   the return value.
#'
#' @importFrom httr2 req_perform
#' @importFrom lubridate as_datetime now
#' @importFrom rlang abort inform warn
#' @export
#' @noassert symbols, from, to
#'
#' @examples
#' \dontrun{
#' kucoin_backfill_klines(
#'   symbols = c("BTC-USDT", "ETH-USDT"),
#'   timeframes = c("1day", "1hour"),
#'   from = lubridate::as_datetime("2020-01-01"),
#'   file = "my_klines.csv"
#' )
#' }
kucoin_backfill_klines <- function(
  symbols,
  timeframes = "1day",
  from = lubridate::now("UTC") - lubridate::ddays(365),
  to = lubridate::now("UTC"),
  file = "kucoin_klines.csv",
  base_url = "https://api.kucoin.com",
  sleep = 0.3,
  verbose = TRUE
) {
  # `symbols` is validated below with a bespoke "non-empty" message (and is
  # `@noassert`d) so NULL / empty input raises that message rather than a
  # generated type error.
  assert_args_kucoin_backfill_klines(timeframes, file, base_url, sleep, verbose)
  # --- Input validation ---
  if (is.null(symbols) || length(symbols) == 0L) {
    rlang::abort("`symbols` must be a non-empty character vector of trading pairs.")
  }

  # Clamp from / to
  kucoin_epoch <- lubridate::as_datetime("2017-01-01", tz = "UTC")

  if (is.infinite(from) && from < 0) {
    from <- kucoin_epoch
  } else {
    from <- lubridate::as_datetime(from, tz = "UTC")
    if (from < kucoin_epoch) {
      from <- kucoin_epoch
    }
  }

  if (is.infinite(to) && to > 0) {
    to <- lubridate::now("UTC")
  } else {
    to <- lubridate::as_datetime(to, tz = "UTC")
  }

  # --- Resume support: read existing file ---
  resume <- NULL
  if (file.exists(file)) {
    existing <- tryCatch(
      data.table::fread(file, select = c("symbol", "timeframe", "datetime")),
      error = function(e) NULL
    )
    if (!is.null(existing) && nrow(existing) > 0L) {
      existing[, datetime := lubridate::as_datetime(datetime, tz = "UTC")]
      resume <- existing[, .(last_dt = max(datetime)), by = .(symbol, timeframe)]
    }
  }

  # --- Sync request function closure ---
  # Public klines endpoints are unauthenticated and bodiless, so route straight
  # through the connectcore funnel with body_format = "none".
  sync_req_fn <- function(endpoint, method = "GET", query = list(), auth = FALSE, .parser = identity, ...) {
    return(connectcore::build_request(
      base_url = base_url,
      endpoint = endpoint,
      method = method,
      query = query,
      body = NULL,
      keys = NULL,
      parse_envelope = parse_kucoin_response,
      body_format = "none",
      .perform = httr2::req_perform,
      .parser = .parser,
      is_async = FALSE
    ))
  }

  # --- Build combo grid ---
  combos <- expand.grid(
    symbol = symbols,
    timeframe = timeframes,
    stringsAsFactors = FALSE
  )
  total <- nrow(combos)

  failures <- list()
  file_exists <- file.exists(file)

  for (i in seq_len(total)) {
    sym <- combos$symbol[i]
    frq <- combos$timeframe[i]

    # Determine effective from for this combo
    combo_from <- from
    resumed_from <- NULL

    if (!is.null(resume)) {
      match_row <- resume[symbol == sym & timeframe == frq]
      if (nrow(match_row) > 0L) {
        last_dt <- match_row$last_dt[1L]
        if (last_dt >= to) {
          if (verbose) {
            rlang::inform(sprintf("[%d/%d] %s %s: skipped (already up to date)", i, total, sym, frq))
          }
          next
        }
        combo_from <- last_dt + 1 # Offset by 1 second to avoid re-fetching the last candle
        resumed_from <- last_dt
      }
    }

    dt <- tryCatch(
      {
        result <- kucoin_fetch_klines(
          symbol = sym,
          timeframe = frq,
          from = combo_from,
          to = to,
          .req_fn = sync_req_fn,
          is_async = FALSE
        )
        result
      },
      error = function(e) {
        failures[[length(failures) + 1L]] <<- data.table::data.table(
          symbol = sym,
          timeframe = frq,
          error = conditionMessage(e)
        )
        rlang::warn(sprintf("[%d/%d] %s %s: FAILED - %s", i, total, sym, frq, conditionMessage(e)))
        return(NULL)
      }
    )

    if (!is.null(dt) && nrow(dt) > 0L) {
      dt[, symbol := sym]
      dt[, timeframe := frq]

      if (!file_exists) {
        data.table::fwrite(dt, file, append = FALSE)
        file_exists <- TRUE
      } else {
        data.table::fwrite(dt, file, append = TRUE)
      }

      if (verbose) {
        msg <- sprintf("[%d/%d] %s %s: %d rows", i, total, sym, frq, nrow(dt))
        if (!is.null(resumed_from)) {
          msg <- paste0(msg, sprintf(" (resumed from %s)", format(resumed_from, "%Y-%m-%d")))
        }
        rlang::inform(msg)
      }
    } else if (is.null(dt)) {
      # Error already handled above
    } else {
      if (verbose) {
        rlang::inform(sprintf("[%d/%d] %s %s: 0 rows", i, total, sym, frq))
      }
    }

    if (i < total) {
      Sys.sleep(sleep)
    }
  }

  # --- Final summary warning if anything failed ---
  if (length(failures) > 0L) {
    failed_dt <- data.table::rbindlist(failures)
    pairs <- paste(
      sprintf("%s/%s", failed_dt$symbol, failed_dt$timeframe),
      collapse = ", "
    )
    rlang::warn(sprintf(
      "kucoin_backfill_klines: %d of %d (symbol, timeframe) combinations failed: %s",
      nrow(failed_dt),
      total,
      pairs
    ))
  }

  return(invisible(assert_return_kucoin_backfill_klines(file)))
}
