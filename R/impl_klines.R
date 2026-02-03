# File: R/impl_klines.R
# Shared klines fetching implementation used by both KucoinMarketData and
# kucoin_backfill_klines(). Handles time-range segmentation, per-segment
# HTTP requests, deduplication, and sorting.

# Frequency Map for KuCoin Kline Intervals
#
# Maps human-readable frequency strings to their duration in seconds.
# Used by kucoin_fetch_klines() for time-range segmentation.
kucoin_freq_map <- list(
  "1min" = 60L,
  "3min" = 180L,
  "5min" = 300L,
  "15min" = 900L,
  "30min" = 1800L,
  "1hour" = 3600L,
  "2hour" = 7200L,
  "4hour" = 14400L,
  "6hour" = 21600L,
  "8hour" = 28800L,
  "12hour" = 43200L,
  "1day" = 86400L,
  "1week" = 604800L,
  "1month" = 2592000L
)

# Fetch Klines from KuCoin
#
# Core implementation for fetching historical OHLCV candlestick data from
# KuCoin's REST API. Automatically segments the requested time range into
# chunks of up to 1500 candles (the per-request limit), fetches each segment
# via the supplied .req_fn, deduplicates, and sorts.
#
# This function is used internally by KucoinMarketData$get_klines() and
# by kucoin_backfill_klines(). It does not depend on any R6 class instance.
kucoin_fetch_klines <- function(
  symbol,
  freq = "15min",
  from = lubridate::now("UTC") - lubridate::dhours(24),
  to = lubridate::now("UTC"),
  .req_fn,
  is_async = FALSE
) {
  if (!freq %in% names(kucoin_freq_map)) {
    rlang::abort(paste0(
      "Invalid frequency '",
      freq,
      "'. Valid: ",
      paste(names(kucoin_freq_map), collapse = ", ")
    ))
  }

  freq_seconds <- kucoin_freq_map[[freq]]
  from_s <- as.integer(as.numeric(from))
  to_s <- as.integer(as.numeric(to))
  max_candles <- 1500L

  # Split into segments of up to 1500 candles each, with 1-candle overlap
  # to prevent gaps at segment boundaries. Dedup handles the overlap.
  segments <- list()
  seg_start <- from_s
  while (seg_start < to_s) {
    seg_end <- min(seg_start + max_candles * freq_seconds, to_s)
    segments[[length(segments) + 1L]] <- list(
      startAt = seg_start,
      endAt = seg_end
    )
    # Overlap by 1 candle only when there are more segments to come.
    # Without this guard, the last segment loops infinitely when
    # seg_end == to_s because seg_end - freq_seconds < to_s.
    if (seg_end >= to_s) {
      break
    }
    seg_start <- seg_end - freq_seconds
  }

  if (length(segments) == 0L) {
    return(data.table::data.table())
  }

  # Combiner: rbindlist, dedup by datetime, sort ascending
  combine_klines <- function(results_list) {
    dts <- Filter(function(x) nrow(x) > 0, results_list)
    if (length(dts) == 0L) {
      return(data.table::data.table())
    }
    dt <- data.table::rbindlist(dts)
    dt <- unique(dt, by = "datetime")
    data.table::setorder(dt, datetime)
    return(dt)
  }

  # Fetch function for one segment
  fetch_segment <- function(seg) {
    return(.req_fn(
      endpoint = "/api/v1/market/candles",
      method = "GET",
      query = list(
        type = freq,
        symbol = symbol,
        startAt = seg$startAt,
        endAt = seg$endAt
      ),
      auth = FALSE,
      .parser = parse_klines
    ))
  }

  # Async: sequential promise chain (one segment at a time to respect rate limits)
  if (is_async) {
    seed <- promises::promise_resolve(list())
    chain <- Reduce(
      function(acc_promise, seg) {
        acc_promise$then(function(acc) {
          fetch_segment(seg)$then(function(result) {
            c(acc, list(result))
          })
        })
      },
      segments,
      accumulate = FALSE,
      init = seed
    )
    return(chain$then(combine_klines))
  }

  # Sync: sequential
  all_results <- lapply(segments, fetch_segment)
  return(combine_klines(all_results))
}
