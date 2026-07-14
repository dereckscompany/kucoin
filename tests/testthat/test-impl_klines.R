# tests/testthat/test-impl_klines.R
# Tests for the shared klines fetching implementation.

# -- kucoin_timeframe_map --

test_that("kucoin_timeframe_map contains all expected timeframes", {
  expected <- c(
    "1min",
    "3min",
    "5min",
    "15min",
    "30min",
    "1hour",
    "2hour",
    "4hour",
    "6hour",
    "8hour",
    "12hour",
    "1day",
    "1week",
    "1month"
  )
  expect_equal(sort(names(kucoin_timeframe_map)), sort(expected))
})

test_that("kucoin_timeframe_map values are correct durations in seconds", {
  expect_equal(kucoin_timeframe_map[["1min"]], 60L)
  expect_equal(kucoin_timeframe_map[["15min"]], 900L)
  expect_equal(kucoin_timeframe_map[["1hour"]], 3600L)
  expect_equal(kucoin_timeframe_map[["1day"]], 86400L)
  expect_equal(kucoin_timeframe_map[["1week"]], 604800L)
})

# -- kucoin_fetch_klines validation --

test_that("kucoin_fetch_klines rejects invalid timeframe", {
  fake_fn <- function(...) stop("Should not be called")
  expect_error(
    kucoin_fetch_klines(
      symbol = "BTC-USDT",
      timeframe = "2min",
      from = 1729100000,
      to = 1729200000,
      .req_fn = fake_fn
    ),
    "Invalid timeframe.*2min"
  )
})

test_that("kucoin_fetch_klines returns empty data.table for zero-width range", {
  fake_fn <- function(...) stop("Should not be called")
  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = 1729100000,
    to = 1729100000,
    .req_fn = fake_fn
  )
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})

# -- kucoin_fetch_klines with mock .req_fn --

test_that("kucoin_fetch_klines fetches single segment correctly", {
  call_count <- 0L
  captured_queries <- list()

  # 10 candles at 15min = 9000 seconds, well within 1500-candle limit
  from_ts <- 1729100000
  to_ts <- from_ts + 9000

  set.seed(42)
  mock_data <- mock_klines_data(n = 10, start_ts = from_ts)

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    return(.parser(mock_data))
  }

  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 1L)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 10L)
  expect_equal(names(result), c("datetime", "open", "high", "low", "close", "volume", "turnover"))

  # Verify query params
  q <- captured_queries[[1]]
  expect_equal(q$symbol, "BTC-USDT")
  expect_equal(q$type, "15min")
  expect_equal(q$startAt, from_ts)
})

test_that("kucoin_fetch_klines segments large time ranges", {
  call_count <- 0L

  # 1500 candles * 900s = 1,350,000s per segment
  # Request 3000 candles worth = should be 2-3 segments (with overlap)
  from_ts <- 1729100000
  to_ts <- from_ts + 3000 * 900 # 2,700,000s

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    # Return a small set each time
    set.seed(call_count)
    return(.parser(mock_klines_data(n = 3, start_ts = query$startAt)))
  }

  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  # Should have made multiple requests

  expect_gt(call_count, 1L)
  expect_s3_class(result, "data.table")
})

test_that("kucoin_fetch_klines deduplicates by datetime", {
  from_ts <- 1729100000
  to_ts <- from_ts + 1800 # 2 candles worth at 15min

  # Return overlapping data
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    data <- list(
      c(as.character(from_ts), "100", "101", "102", "99", "50", "5000"),
      c(as.character(from_ts + 900), "101", "102", "103", "100", "60", "6060")
    )
    return(.parser(data))
  }

  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  # Should be deduplicated
  expect_equal(nrow(result), length(unique(result$datetime)))
})

test_that("kucoin_fetch_klines sorts by datetime ascending", {
  from_ts <- 1729100000
  to_ts <- from_ts + 5400 # 6 candles at 15min

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    # Return in reverse order
    data <- list(
      c(as.character(from_ts + 3600), "103", "104", "105", "102", "70", "7210"),
      c(as.character(from_ts + 1800), "102", "103", "104", "101", "60", "6120"),
      c(as.character(from_ts), "100", "101", "102", "99", "50", "5000")
    )
    return(.parser(data))
  }

  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  # Datetimes should be in ascending order
  timestamps <- as.numeric(result$datetime)
  expect_true(all(diff(timestamps) >= 0))
})

test_that("kucoin_fetch_klines uses correct endpoint", {
  captured_endpoint <- NULL

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    captured_endpoint <<- endpoint
    return(.parser(list()))
  }

  kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "1day",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_equal(captured_endpoint, "/api/v1/market/candles")
})

test_that("kucoin_fetch_klines sets auth = FALSE", {
  captured_auth <- NULL

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    captured_auth <<- auth
    return(.parser(list()))
  }

  kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "1day",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_false(captured_auth)
})

test_that("kucoin_fetch_klines handles empty API responses", {
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    return(.parser(list()))
  }

  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = 1729100000,
    to = 1729200000,
    .req_fn = fake_req_fn
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})

# -- Segment overlap --

test_that("kucoin_fetch_klines segments overlap by 1 candle", {
  captured_queries <- list()
  call_count <- 0L

  # Force 2 segments: 1500 candles * 900s = 1,350,000s per segment
  from_ts <- 1000000
  to_ts <- from_ts + 1500 * 900 + 900 # just over 1 segment

  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    return(.parser(list()))
  }

  kucoin_fetch_klines(
    symbol = "BTC-USDT",
    timeframe = "15min",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 2L)

  # Second segment's startAt should be first segment's endAt minus timeframe_seconds (900)
  seg1_end <- captured_queries[[1]]$endAt
  seg2_start <- captured_queries[[2]]$startAt
  expect_equal(seg2_start, seg1_end - 900)
})

# -- int32 overflow regression (issue #40) --

# For week/month intervals the segment-window width alone
# (max_candles * timeframe_seconds) exceeds .Machine$integer.max, so the old
# int32 arithmetic produced `NA` on the first loop iteration and threw
# "missing value where TRUE/FALSE needed". These tests drive the exact 2020-era
# epochs from the bug report and assert the segmentation is overflow-free with
# finite, correct boundaries.

test_that("kucoin_fetch_klines: 1week segment math is overflow-free at 2020+ epochs (issue #40)", {
  from_dt <- lubridate::as_datetime("2020-01-01", tz = "UTC")
  to_dt <- lubridate::as_datetime("2021-01-01", tz = "UTC")
  from_s <- as.numeric(from_dt)
  to_s <- as.numeric(to_dt)

  captured_queries <- list()
  call_count <- 0L
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    return(.parser(list()))
  }

  expect_no_warning(
    kucoin_fetch_klines(
      symbol = "BTC-USDT",
      timeframe = "1week",
      from = from_dt,
      to = to_dt,
      .req_fn = fake_req_fn
    )
  )

  # A full year of weekly candles fits inside one 1500-week segment
  expect_equal(call_count, 1L)
  q <- captured_queries[[1]]
  expect_false(is.na(q$startAt))
  expect_false(is.na(q$endAt))
  expect_equal(q$startAt, from_s)
  expect_equal(q$endAt, to_s)
})

test_that("kucoin_fetch_klines: 1month segment math is overflow-free at 2020+ epochs (issue #40)", {
  from_dt <- lubridate::as_datetime("2020-01-01", tz = "UTC")
  to_dt <- lubridate::as_datetime("2022-01-01", tz = "UTC")
  from_s <- as.numeric(from_dt)
  to_s <- as.numeric(to_dt)

  captured_queries <- list()
  call_count <- 0L
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    return(.parser(list()))
  }

  # 1month's width alone (1500 * 2592000 = 3.888e9) overflows int32 even before
  # adding the epoch second, so this is the strictest regression of the two.
  expect_no_warning(
    kucoin_fetch_klines(
      symbol = "BTC-USDT",
      timeframe = "1month",
      from = from_dt,
      to = to_dt,
      .req_fn = fake_req_fn
    )
  )

  expect_equal(call_count, 1L)
  q <- captured_queries[[1]]
  expect_false(is.na(q$startAt))
  expect_false(is.na(q$endAt))
  expect_equal(q$startAt, from_s)
  expect_equal(q$endAt, to_s)
})

test_that("kucoin_fetch_klines: 1week multi-segment boundaries are correct past int32 (issue #40)", {
  tf_s <- 604800 # 1week in seconds
  from_dt <- lubridate::as_datetime("2020-01-01", tz = "UTC")
  from_s <- as.numeric(from_dt)
  # Window just over one 1500-week segment to force a second segment. The first
  # segment's endAt (from_s + 1500 * 604800 = 2.485e9) lands past
  # .Machine$integer.max, which is exactly where the old code overflowed.
  to_s <- from_s + 1500 * tf_s + tf_s
  to_dt <- lubridate::as_datetime(to_s, tz = "UTC")

  captured_queries <- list()
  call_count <- 0L
  fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
    call_count <<- call_count + 1L
    captured_queries[[call_count]] <<- query
    return(.parser(list()))
  }

  expect_no_warning(
    kucoin_fetch_klines(
      symbol = "BTC-USDT",
      timeframe = "1week",
      from = from_dt,
      to = to_dt,
      .req_fn = fake_req_fn
    )
  )

  expect_equal(call_count, 2L)
  seg1_end <- captured_queries[[1]]$endAt
  seg2_start <- captured_queries[[2]]$startAt
  expect_false(is.na(seg1_end))
  expect_gt(seg1_end, .Machine$integer.max)
  expect_equal(seg1_end, from_s + 1500 * tf_s)
  expect_equal(seg2_start, seg1_end - tf_s) # 1-candle overlap
})

test_that("kucoin_fetch_klines: sub-week intervals (1hour/4hour/1day) unchanged at 2020+ epochs (issue #40)", {
  from_dt <- lubridate::as_datetime("2020-01-01", tz = "UTC")
  from_s <- as.numeric(from_dt)
  to_dt <- from_dt + lubridate::ddays(50) # small window: single segment for all
  to_s <- as.numeric(to_dt)

  for (tf in c("1hour", "4hour", "1day")) {
    captured_queries <- list()
    call_count <- 0L
    fake_req_fn <- function(endpoint, method, query, auth, .parser, ...) {
      call_count <<- call_count + 1L
      captured_queries[[call_count]] <<- query
      return(.parser(list()))
    }

    expect_no_warning(
      kucoin_fetch_klines(
        symbol = "BTC-USDT",
        timeframe = tf,
        from = from_dt,
        to = to_dt,
        .req_fn = fake_req_fn
      )
    )

    expect_equal(call_count, 1L, info = tf)
    q <- captured_queries[[1]]
    expect_equal(q$startAt, from_s, info = tf)
    expect_equal(q$endAt, to_s, info = tf)
  }
})
