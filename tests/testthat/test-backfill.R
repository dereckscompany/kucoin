# tests/testthat/test-backfill.R
# Tests for kucoin_backfill_klines() with mocked HTTP.

# -- Input Validation --

test_that("backfill rejects NULL symbols", {
  expect_error(
    kucoin_backfill_klines(symbols = NULL, timeframes = "1day"),
    "non-empty"
  )
})

test_that("backfill rejects empty symbols", {
  expect_error(
    kucoin_backfill_klines(symbols = character(0), timeframes = "1day"),
    "non-empty"
  )
})

# -- Successful Backfill --

test_that("backfill writes CSV and returns file path", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Mock the HTTP layer: kucoin_fetch_klines calls .req_fn which eventually
  # calls httr2::req_perform. We mock that.
  kline_data <- mock_klines_data(n = 3, start_ts = 1729100000)
  resp <- mock_kucoin_response(data = kline_data)
  httr2::local_mocked_responses(function(req) resp)

  result <- kucoin_backfill_klines(
    symbols = "BTC-USDT",
    timeframes = "1day",
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  expect_equal(result, outfile)
  expect_true(file.exists(outfile))

  dt <- data.table::fread(outfile)
  expect_true(nrow(dt) > 0L)
  expect_true("symbol" %in% names(dt))
  expect_true("timeframe" %in% names(dt))
  expect_true("datetime" %in% names(dt))
  expect_equal(unique(dt$symbol), "BTC-USDT")
  expect_equal(unique(dt$timeframe), "1day")
})

# -- Resume Support --

test_that("backfill skips completed combos on resume", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Write a pre-existing CSV with data up to `to`
  existing <- data.table::data.table(
    datetime = "2024-10-17T00:00:00",
    open = 67000,
    high = 67100,
    low = 66900,
    close = 67050,
    volume = 100,
    turnover = 6700000,
    symbol = "BTC-USDT",
    timeframe = "1day"
  )
  data.table::fwrite(existing, outfile)

  captured_urls <- character()
  resp <- mock_kucoin_response(data = mock_klines_data(n = 1))
  httr2::local_mocked_responses(function(req) {
    captured_urls <<- c(captured_urls, req$url)
    return(resp)
  })

  kucoin_backfill_klines(
    symbols = "BTC-USDT",
    timeframes = "1day",
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  # Should have been skipped (already up to date), so no HTTP requests
  expect_equal(length(captured_urls), 0L)
})

# -- from Clamping --

test_that("backfill clamps -Inf from to 2017-01-01", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  resp <- mock_kucoin_response(data = mock_klines_data(n = 1))
  httr2::local_mocked_responses(function(req) resp)

  # Should not error with -Inf from
  result <- kucoin_backfill_klines(
    symbols = "BTC-USDT",
    timeframes = "1day",
    from = -Inf,
    to = lubridate::as_datetime("2017-01-02", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  expect_equal(result, outfile)
})

# -- Error Handling --

test_that("backfill attaches failures attribute on error", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Mock HTTP to return an error
  httr2::local_mocked_responses(function(req) {
    return(mock_http_error(status_code = 500L, body_text = "Internal Server Error"))
  })

  result <- suppressWarnings(kucoin_backfill_klines(
    symbols = "BTC-USDT",
    timeframes = "1day",
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  ))

  failures <- attr(result, "failures")
  expect_s3_class(failures, "data.table")
  expect_equal(nrow(failures), 1L)
  expect_equal(failures$symbol, "BTC-USDT")
  expect_equal(failures$timeframe, "1day")
})

# -- Multiple Symbols/Timeframes --

test_that("backfill handles multiple symbol-timeframe combos", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  resp <- mock_kucoin_response(data = mock_klines_data(n = 2))
  httr2::local_mocked_responses(function(req) resp)

  result <- kucoin_backfill_klines(
    symbols = c("BTC-USDT", "ETH-USDT"),
    timeframes = c("1day"),
    from = lubridate::as_datetime("2024-10-16", tz = "UTC"),
    to = lubridate::as_datetime("2024-10-17", tz = "UTC"),
    file = outfile,
    sleep = 0,
    verbose = FALSE
  )

  dt <- data.table::fread(outfile)
  expect_true(nrow(dt) > 0L)
  expect_true("BTC-USDT" %in% dt$symbol)
  expect_true("ETH-USDT" %in% dt$symbol)
})
