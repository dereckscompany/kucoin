# File: R/impl_klines.R
# Shared klines fetching implementation used by both KucoinMarketData and
# kucoin_backfill_klines(). Handles time-range segmentation, per-segment
# HTTP requests, deduplication, and sorting.

# Timeframe Map for KuCoin Kline Intervals
#
# Maps human-readable timeframe strings to their duration in seconds.
# Used by kucoin_fetch_klines() for time-range segmentation.
kucoin_timeframe_map <- list(
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
  timeframe = "15min",
  from = NULL,
  to = NULL,
  .req_fn,
  is_async = FALSE
) {
  if (!timeframe %in% names(kucoin_timeframe_map)) {
    rlang::abort(paste0(
      "Invalid timeframe '",
      timeframe,
      "'. Valid: ",
      paste(names(kucoin_timeframe_map), collapse = ", ")
    ))
  }

  # When no time range specified, make a single request without startAt/endAt.
  # The KuCoin API returns up to 1500 most recent candles.
  if (is.null(from) && is.null(to)) {
    fetch_no_range <- function() {
      return(.req_fn(
        endpoint = "/api/v1/market/candles",
        method = "GET",
        query = list(type = timeframe, symbol = symbol),
        auth = FALSE,
        .parser = parse_klines
      ))
    }
    if (is_async) {
      return(fetch_no_range()$then(function(dt) {
        if (nrow(dt) > 0L) {
          data.table::setorder(dt, datetime)
        }
        return(dt[])
      }))
    }
    dt <- fetch_no_range()
    if (nrow(dt) > 0L) {
      data.table::setorder(dt, datetime)
    }
    return(dt[])
  }

  # Fill in whichever bound is missing
  if (is.null(to)) {
    to <- lubridate::now("UTC")
  }
  if (is.null(from)) {
    from <- lubridate::now("UTC") - lubridate::dhours(24)
  }

  timeframe_seconds <- kucoin_timeframe_map[[timeframe]]
  from_s <- as.integer(as.numeric(from))
  to_s <- as.integer(as.numeric(to))
  max_candles <- 1500L

  # Split into segments of up to 1500 candles each, with 1-candle overlap
  # to prevent gaps at segment boundaries. Dedup handles the overlap.
  segments <- list()
  seg_start <- from_s
  while (seg_start < to_s) {
    seg_end <- min(seg_start + max_candles * timeframe_seconds, to_s)
    segments[[length(segments) + 1L]] <- list(
      startAt = seg_start,
      endAt = seg_end
    )
    # Overlap by 1 candle only when there are more segments to come.
    # Without this guard, the last segment loops infinitely when
    # seg_end == to_s because seg_end - timeframe_seconds < to_s.
    if (seg_end >= to_s) {
      break
    }
    seg_start <- seg_end - timeframe_seconds
  }

  if (length(segments) == 0L) {
    return(data.table::data.table()[])
  }

  # Combiner: rbindlist, dedup by datetime, sort ascending
  combine_klines <- function(results_list) {
    dts <- Filter(function(x) nrow(x) > 0, results_list)
    if (length(dts) == 0L) {
      return(data.table::data.table()[])
    }
    dt <- data.table::rbindlist(dts)
    dt <- unique(dt, by = "datetime")
    data.table::setorder(dt, datetime)
    return(dt[])
  }

  # Fetch function for one segment
  fetch_segment <- function(seg) {
    return(.req_fn(
      endpoint = "/api/v1/market/candles",
      method = "GET",
      query = list(
        type = timeframe,
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
        return(acc_promise$then(function(acc) {
          return(fetch_segment(seg)$then(function(result) {
            return(c(acc, list(result)))
          }))
        }))
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

# Granularity Map for KuCoin Futures Kline Intervals
#
# Maps granularity integers (minutes) to their duration in seconds.
# Used by kucoin_fetch_futures_klines() for time-range segmentation.
kucoin_futures_granularity_map <- list(
  "1" = 60L,
  "5" = 300L,
  "15" = 900L,
  "30" = 1800L,
  "60" = 3600L,
  "120" = 7200L,
  "240" = 14400L,
  "480" = 28800L,
  "720" = 43200L,
  "1440" = 86400L,
  "10080" = 604800L
)

# Fetch Futures Klines from KuCoin
#
# Core implementation for fetching historical OHLCV candlestick data from
# KuCoin Futures REST API. Automatically segments the requested time range
# into chunks, fetches each segment, deduplicates, and sorts.
#
# KuCoin futures klines use millisecond timestamps and a different endpoint/
# query format than spot klines.
kucoin_fetch_futures_klines <- function(
  symbol,
  granularity,
  from,
  to,
  .req_fn,
  is_async = FALSE,
  max_candles = 200L,
  sleep = 0
) {
  gran_key <- as.character(granularity)
  if (!gran_key %in% names(kucoin_futures_granularity_map)) {
    rlang::abort(paste0(
      "Invalid granularity '",
      granularity,
      "'. Valid: ",
      paste(names(kucoin_futures_granularity_map), collapse = ", ")
    ))
  }

  granularity_seconds <- kucoin_futures_granularity_map[[gran_key]]
  from_ms <- as.numeric(from) * 1000
  to_ms <- as.numeric(to) * 1000

  # Split into segments of up to max_candles each, with 1-candle overlap
  segments <- list()
  seg_start <- from_ms
  while (seg_start < to_ms) {
    seg_end <- min(seg_start + max_candles * granularity_seconds * 1000, to_ms)
    segments[[length(segments) + 1L]] <- list(
      from = seg_start,
      to = seg_end
    )
    if (seg_end >= to_ms) {
      break
    }
    seg_start <- seg_end - granularity_seconds * 1000
  }

  if (length(segments) == 0L) {
    return(data.table::data.table()[])
  }

  # Combiner: rbindlist, dedup by datetime, sort ascending
  combine_klines <- function(results_list) {
    dts <- Filter(function(x) nrow(x) > 0, results_list)
    if (length(dts) == 0L) {
      return(data.table::data.table()[])
    }
    dt <- data.table::rbindlist(dts)
    dt <- unique(dt, by = "datetime")
    data.table::setorder(dt, datetime)
    return(dt[])
  }

  # Fetch function for one segment
  fetch_segment <- function(seg) {
    return(.req_fn(
      endpoint = "/api/v1/kline/query",
      method = "GET",
      query = list(
        symbol = symbol,
        granularity = granularity,
        from = seg$from,
        to = seg$to
      ),
      auth = FALSE,
      .parser = parse_futures_klines
    ))
  }

  # Async: sequential promise chain
  if (is_async) {
    seed <- promises::promise_resolve(list())
    chain <- Reduce(
      function(acc_promise, seg) {
        return(acc_promise$then(function(acc) {
          return(fetch_segment(seg)$then(function(result) {
            return(c(acc, list(result)))
          }))
        }))
      },
      segments,
      accumulate = FALSE,
      init = seed
    )
    return(chain$then(combine_klines))
  }

  # Sync: sequential with sleep between segments
  all_results <- vector("list", length(segments))
  for (i in seq_along(segments)) {
    all_results[[i]] <- fetch_segment(segments[[i]])
    if (i < length(segments) && sleep > 0) {
      Sys.sleep(sleep)
    }
  }
  return(combine_klines(all_results))
}
