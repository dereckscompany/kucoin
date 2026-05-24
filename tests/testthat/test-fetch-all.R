# ===========================================================================
# Tests for fetch_all klines segmentation — KuCoin Futures
# KuCoin Spot already auto-segments via kucoin_fetch_klines(), so only
# futures needs the new fetch_all parameter.
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: generate N mock futures kline arrays
# KuCoin futures klines are arrays: [time_ms, open, high, low, close, volume, turnover]
# ---------------------------------------------------------------------------
make_mock_futures_klines <- function(n, start_ms = 1704067200000, interval_ms = 3600000) {
  return(lapply(seq_len(n), function(i) {
    ts <- start_ms + (i - 1) * interval_ms
    return(list(ts, 42000, 42100, 41900, 42050, 100, 4200000))
  }))
}

# ---------------------------------------------------------------------------
# KuCoin Futures: get_klines with fetch_all = TRUE
# ---------------------------------------------------------------------------
test_that("KucoinFuturesMarketData$get_klines with fetch_all segments large ranges", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )
  BASE <- "https://api-futures.kucoin.com"
  fm <- KucoinFuturesMarketData$new(keys = keys, base_url = BASE)

  # Granularity 60 = 60 min candles. Mock returns max 200 per call.
  # 2880 hours (Jan-May) needs multiple calls.
  call_count <- 0L
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    parsed <- httr2::url_parse(req$url)
    from_ms <- as.numeric(parsed$query$from)
    to_ms <- as.numeric(parsed$query$to)
    interval_ms <- 60 * 60 * 1000 # 60 min in ms
    n <- min(200L, floor((to_ms - from_ms) / interval_ms))
    n <- max(n, 1L)
    return(mock_kucoin_response(data = make_mock_futures_klines(n, start_ms = from_ms, interval_ms = interval_ms)))
  })

  dt <- fm$get_klines(
    symbol = "XBTUSDTM",
    granularity = 60,
    from = as.POSIXct("2024-01-01", tz = "UTC"),
    to = as.POSIXct("2024-05-01", tz = "UTC"),
    fetch_all = TRUE,
    sleep = 0
  )

  expect_s3_class(dt, "data.table")
  expect_true(call_count >= 2L, info = paste("Expected >= 2 API calls for large futures range, got", call_count))
  expect_true(nrow(dt) > 200L, info = paste("Expected > 200 rows, got", nrow(dt)))
})

test_that("KucoinFuturesMarketData$get_klines with fetch_all deduplicates and sorts", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )
  BASE <- "https://api-futures.kucoin.com"
  fm <- KucoinFuturesMarketData$new(keys = keys, base_url = BASE)

  # Return 200 klines per call to guarantee overlaps between segments
  call_count <- 0L
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    parsed <- httr2::url_parse(req$url)
    from_ms <- as.numeric(parsed$query$from)
    return(mock_kucoin_response(data = make_mock_futures_klines(200, start_ms = from_ms, interval_ms = 3600000)))
  })

  dt <- fm$get_klines(
    symbol = "XBTUSDTM",
    granularity = 60,
    from = as.POSIXct("2024-01-01", tz = "UTC"),
    to = as.POSIXct("2024-02-15", tz = "UTC"),
    fetch_all = TRUE,
    sleep = 0
  )

  expect_s3_class(dt, "data.table")
  # Must have made multiple calls
  expect_true(call_count >= 2L, info = paste("Expected >= 2 API calls, got", call_count))
  # No duplicate timestamps after dedup
  expect_equal(nrow(dt), length(unique(dt$datetime)), info = "Segmented results should be deduplicated by datetime")
  # Sorted ascending
  expect_true(all(diff(as.numeric(dt$datetime)) >= 0), info = "Results should be sorted ascending by datetime")
})

test_that("KucoinFuturesMarketData$get_klines without fetch_all makes single API call", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )
  BASE <- "https://api-futures.kucoin.com"
  fm <- KucoinFuturesMarketData$new(keys = keys, base_url = BASE)

  call_count <- 0L
  resp <- mock_kucoin_response(data = make_mock_futures_klines(200))
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    return(resp)
  })

  # Large range but fetch_all = FALSE (default): should still make 1 call
  dt <- fm$get_klines(
    symbol = "XBTUSDTM",
    granularity = 60,
    from = as.POSIXct("2024-01-01", tz = "UTC"),
    to = as.POSIXct("2024-05-01", tz = "UTC")
  )

  expect_equal(call_count, 1L, info = "Default mode should make exactly 1 API call")
  expect_equal(nrow(dt), 200L, info = "Without fetch_all, should return only what the single call returns")
})

# ---------------------------------------------------------------------------
# Async mode: test kucoin_fetch_futures_klines directly with is_async = TRUE
# (httr2::local_mocked_responses does not intercept req_perform_promise,
#  so we test the impl function directly with a .req_fn that returns promises)
# ---------------------------------------------------------------------------
test_that("kucoin_fetch_futures_klines works in async mode", {
  skip_if_not_installed("promises")
  skip_if_not_installed("later")

  call_count <- 0L
  mock_req_fn <- function(endpoint, method, query, auth, .parser) {
    call_count <<- call_count + 1L
    from_ms <- as.numeric(query$from)
    to_ms <- as.numeric(query$to)
    interval_ms <- 60 * 60 * 1000
    n <- min(200L, floor((to_ms - from_ms) / interval_ms))
    n <- max(n, 1L)
    klines <- make_mock_futures_klines(n, start_ms = from_ms, interval_ms = interval_ms)
    return(promises::promise_resolve(.parser(klines)))
  }

  # Use a range that needs ~3 segments (600 hours / 200 per segment)
  result_promise <- kucoin:::kucoin_fetch_futures_klines(
    symbol = "XBTUSDTM",
    granularity = 60,
    from = as.POSIXct("2024-01-01", tz = "UTC"),
    to = as.POSIXct("2024-01-26", tz = "UTC"),
    .req_fn = mock_req_fn,
    is_async = TRUE,
    max_candles = 200L,
    sleep = 0
  )

  expect_true(promises::is.promise(result_promise), info = "Async futures fetch_klines should return a promise")

  resolved <- NULL
  error_msg <- NULL
  promises::then(
    result_promise,
    onFulfilled = function(val) {
      resolved <<- val
      return(invisible(NULL))
    },
    onRejected = function(err) {
      error_msg <<- conditionMessage(err)
      return(invisible(NULL))
    }
  )
  for (i in 1:20) {
    later::run_now(timeoutSecs = 0.5)
  }

  expect_null(error_msg, info = paste("Promise rejected with:", error_msg))
  expect_false(is.null(resolved), info = "Promise should have resolved")
  if (!is.null(resolved)) {
    expect_s3_class(resolved, "data.table")
    expect_true(nrow(resolved) > 200L, info = paste("Async futures should return > 200 rows, got", nrow(resolved)))
    expect_true(call_count >= 2L, info = paste("Async futures should make >= 2 calls, got", call_count))
  }
})
