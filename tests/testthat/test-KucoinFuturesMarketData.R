# tests/testthat/test-KucoinFuturesMarketData.R
# Tests for KucoinFuturesMarketData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api-futures.kucoin.com"

new_market <- function() {
  KucoinFuturesMarketData$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinFuturesMarketData inherits from KucoinBase", {
  m <- new_market()
  expect_s3_class(m, "KucoinFuturesMarketData")
  expect_s3_class(m, "KucoinBase")
  expect_false(m$is_async)
})

test_that("KucoinFuturesMarketData async mode sets is_async = TRUE", {
  m <- KucoinFuturesMarketData$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(m$is_async)
})

# -- get_contract --

test_that("get_contract returns single-row data.table", {
  resp <- mock_kucoin_response(data = mock_futures_contract_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_contract("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("symbol" %in% names(dt))
  expect_equal(dt$symbol, "XBTUSDTM")
  expect_true("max_leverage" %in% names(dt))
  expect_equal(dt$max_leverage, 125)
})

test_that("get_contract hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_contract_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  new_market()$get_contract("XBTUSDTM")
  expect_true(grepl("contracts/XBTUSDTM", captured_url))
})

# -- get_all_contracts --

test_that("get_all_contracts returns multi-row data.table", {
  resp <- mock_kucoin_response(data = mock_futures_all_contracts_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_all_contracts()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("XBTUSDTM" %in% dt$symbol)
  expect_true("ETHUSDTM" %in% dt$symbol)
})

# -- get_ticker --

test_that("get_ticker returns single-row data.table with ts as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_ticker_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_ticker("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("ts" %in% names(dt))
  expect_s3_class(dt$ts, "POSIXct")
  expect_true("symbol" %in% names(dt))
  expect_equal(dt$symbol, "XBTUSDTM")
})

# -- get_all_tickers --

test_that("get_all_tickers returns multi-row data.table", {
  resp <- mock_kucoin_response(data = mock_futures_all_tickers_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_all_tickers()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("ts" %in% names(dt))
  expect_s3_class(dt$ts, "POSIXct")
  expect_equal(sort(dt$symbol), c("ETHUSDTM", "XBTUSDTM"))
})

# -- get_part_orderbook --

test_that("get_part_orderbook returns data.table with bids and asks", {
  resp <- mock_kucoin_response(data = mock_futures_orderbook_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_part_orderbook("XBTUSDTM", size = 20)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("ts", "sequence", "side", "price", "size") %in% names(dt)))
  expect_s3_class(dt$ts, "POSIXct")
  expect_true("bid" %in% dt$side)
  expect_true("ask" %in% dt$side)
  # Prices should be numeric
  expect_true(is.numeric(dt$price))
  expect_true(is.numeric(dt$size))
})

test_that("get_part_orderbook validates size parameter", {
  expect_error(new_market()$get_part_orderbook("XBTUSDTM", size = 50))
})

# -- get_full_orderbook --

test_that("get_full_orderbook returns data.table with auth", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_orderbook_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  dt <- new_market()$get_full_orderbook("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_true(grepl("level2/snapshot", captured_url))
})

# -- get_trade_history --

test_that("get_trade_history returns data.table with ts as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_trade_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_trade_history("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("ts" %in% names(dt))
  expect_s3_class(dt$ts, "POSIXct")
  expect_true("side" %in% names(dt))
})

# -- get_klines --

test_that("get_klines returns data.table with OHLCV columns", {
  resp <- mock_kucoin_response(data = mock_futures_klines_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_klines("XBTUSDTM", granularity = 60)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expected_cols <- c("datetime", "open", "high", "low", "close", "volume", "turnover")
  expect_equal(names(dt), expected_cols)
  expect_s3_class(dt$datetime, "POSIXct")
  expect_true(is.numeric(dt$open))
  expect_true(is.numeric(dt$volume))
})

test_that("get_klines converts POSIXct from/to to milliseconds", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_klines_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  from_time <- as.POSIXct("2024-10-17 00:00:00", tz = "UTC")
  to_time <- as.POSIXct("2024-10-17 01:00:00", tz = "UTC")
  new_market()$get_klines("XBTUSDTM", granularity = 60, from = from_time, to = to_time)

  # Should contain millisecond timestamps in query
  expect_true(grepl("from=", captured_url))
  expect_true(grepl("to=", captured_url))
})

test_that("get_klines handles empty data", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_klines("XBTUSDTM", granularity = 60)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_mark_price --

test_that("get_mark_price returns single-row data.table with time_point as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_mark_price_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_mark_price("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("time_point" %in% names(dt))
  expect_s3_class(dt$time_point, "POSIXct")
  expect_true("value" %in% names(dt))
})

# -- get_funding_rate --

test_that("get_funding_rate returns single-row data.table with timestamps", {
  resp <- mock_kucoin_response(data = mock_futures_funding_rate_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_funding_rate("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("time_point" %in% names(dt))
  expect_s3_class(dt$time_point, "POSIXct")
  expect_true("funding_time" %in% names(dt))
  expect_s3_class(dt$funding_time, "POSIXct")
  expect_true("value" %in% names(dt))
})

# -- get_funding_history --

test_that("get_funding_history returns data.table with timepoint as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_funding_history_data())
  httr2::local_mocked_responses(function(req) resp)

  from_time <- as.POSIXct("2024-10-17 00:00:00", tz = "UTC")
  to_time <- as.POSIXct("2024-10-18 00:00:00", tz = "UTC")
  dt <- new_market()$get_funding_history("XBTUSDTM", from = from_time, to = to_time)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("timepoint" %in% names(dt))
  expect_s3_class(dt$timepoint, "POSIXct")
  expect_true("symbol" %in% names(dt))
})

# -- get_server_time --

test_that("get_server_time returns data.table with server_time as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_server_time_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_server_time()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("server_time" %in% names(dt))
  expect_s3_class(dt$server_time, "POSIXct")
})

# -- get_service_status --

test_that("get_service_status returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_service_status_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_service_status()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("status" %in% names(dt))
  expect_equal(dt$status, "open")
})
