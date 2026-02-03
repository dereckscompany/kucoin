# tests/testthat/test-impl_klines.R
# Tests for the shared klines fetching implementation.

# -- kucoin_freq_map --

test_that("kucoin_freq_map contains all expected frequencies", {
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
  expect_equal(sort(names(kucoin_freq_map)), sort(expected))
})

test_that("kucoin_freq_map values are correct durations in seconds", {
  expect_equal(kucoin_freq_map[["1min"]], 60L)
  expect_equal(kucoin_freq_map[["15min"]], 900L)
  expect_equal(kucoin_freq_map[["1hour"]], 3600L)
  expect_equal(kucoin_freq_map[["1day"]], 86400L)
  expect_equal(kucoin_freq_map[["1week"]], 604800L)
})

# -- kucoin_fetch_klines validation --

test_that("kucoin_fetch_klines rejects invalid frequency", {
  fake_fn <- function(...) stop("Should not be called")
  expect_error(
    kucoin_fetch_klines(
      symbol = "BTC-USDT",
      freq = "2min",
      from = 1729100000,
      to = 1729200000,
      .req_fn = fake_fn
    ),
    "Invalid frequency.*2min"
  )
})

test_that("kucoin_fetch_klines returns empty data.table for zero-width range", {
  fake_fn <- function(...) stop("Should not be called")
  result <- kucoin_fetch_klines(
    symbol = "BTC-USDT",
    freq = "15min",
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
    freq = "15min",
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
    freq = "15min",
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
    freq = "15min",
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
    freq = "15min",
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
    freq = "1day",
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
    freq = "1day",
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
    freq = "15min",
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
    freq = "15min",
    from = from_ts,
    to = to_ts,
    .req_fn = fake_req_fn
  )

  expect_equal(call_count, 2L)

  # Second segment's startAt should be first segment's endAt minus freq_seconds (900)
  seg1_end <- captured_queries[[1]]$endAt
  seg2_start <- captured_queries[[2]]$startAt
  expect_equal(seg2_start, seg1_end - 900)
})
