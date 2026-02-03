# tests/testthat/test-KucoinMarketData.R
# Integration-style tests for KucoinMarketData R6 class with mocked HTTP.

# -- Construction --

test_that("KucoinMarketData inherits from KucoinBase", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")

  expect_s3_class(market, "KucoinMarketData")
  expect_s3_class(market, "KucoinBase")
  expect_false(market$is_async)
})

test_that("KucoinMarketData async mode sets is_async = TRUE", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com", async = TRUE)
  expect_true(market$is_async)
})

# -- get_ticker --

test_that("get_ticker returns data.table with correct columns and types", {
  resp <- mock_kucoin_response(data = mock_ticker_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_ticker("BTC-USDT")

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)

  # datetime should be first column and POSIXct
  expect_equal(names(dt)[1], "datetime")
  expect_s3_class(dt$datetime, "POSIXct")

  # Raw 'time' column should be removed
  expect_false("time" %in% names(dt))

  # Other fields should be present
  expect_true("price" %in% names(dt))
  expect_true("best_bid" %in% names(dt))
  expect_true("best_ask" %in% names(dt))
})

# -- get_all_tickers --

test_that("get_all_tickers returns multi-row data.table", {
  resp <- mock_kucoin_response(data = mock_all_tickers_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_all_tickers()

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")

  # Both symbols should be present
  expect_equal(sort(dt$symbol), c("BTC-USDT", "ETH-USDT"))
})

# -- get_trade_history --

test_that("get_trade_history returns correct columns and types", {
  resp <- mock_kucoin_response(data = mock_trade_history_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_trade_history("BTC-USDT")

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)

  expect_true("datetime" %in% names(dt))
  expect_true("sequence" %in% names(dt))
  expect_true("side" %in% names(dt))
  expect_true("price" %in% names(dt))
  expect_true("size" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")

  # Raw 'time' should be gone
  expect_false("time" %in% names(dt))

  # Side values should be buy/sell
  expect_true(all(dt$side %in% c("buy", "sell")))
})

# -- get_part_orderbook --

test_that("get_part_orderbook returns orderbook with correct structure", {
  resp <- mock_kucoin_response(data = mock_orderbook_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_part_orderbook("BTC-USDT", size = 20)

  expect_s3_class(dt, "data.table")
  expect_equal(names(dt), c("datetime", "sequence", "side", "price", "size"))
  expect_equal(nrow(dt), 6L)
  expect_s3_class(dt$datetime, "POSIXct")
  expect_type(dt$price, "double")
  expect_type(dt$size, "double")
})

test_that("get_part_orderbook uses correct endpoint for size 20 vs 100", {
  captured_urls <- character()
  resp <- mock_kucoin_response(data = mock_orderbook_data())

  httr2::local_mocked_responses(function(req) {
    captured_urls <<- c(captured_urls, req$url)
    return(resp)
  })

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")

  market$get_part_orderbook("BTC-USDT", size = 20)
  market$get_part_orderbook("BTC-USDT", size = 100)

  expect_true(grepl("level2_20", captured_urls[1]))
  expect_true(grepl("level2_100", captured_urls[2]))
})

# -- get_24hr_stats --

test_that("get_24hr_stats returns correct data.table", {
  resp <- mock_kucoin_response(data = mock_24hr_stats_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_24hr_stats("BTC-USDT")

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)

  # datetime and symbol should be first two columns
  expect_equal(names(dt)[1], "datetime")
  expect_equal(names(dt)[2], "symbol")

  expect_s3_class(dt$datetime, "POSIXct")
  expect_equal(dt$symbol, "BTC-USDT")
  expect_false("time" %in% names(dt))

  # Check some fields
  expect_true("change_rate" %in% names(dt))
  expect_true("vol" %in% names(dt))
})

# -- get_market_list --

test_that("get_market_list returns character vector", {
  resp <- mock_kucoin_response(data = mock_market_list_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  result <- market$get_market_list()

  expect_type(result, "character")
  expect_true("USDS" %in% result)
  expect_true("BTC" %in% result)
  expect_true(length(result) > 0)
})

# -- get_currency --

test_that("get_currency returns flattened currency + chain data", {
  resp <- mock_kucoin_response(data = mock_currency_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_currency("BTC")

  expect_s3_class(dt, "data.table")
  # BTC has 2 chains in mock data
  expect_equal(nrow(dt), 2L)

  # Top-level currency fields
  expect_true("currency" %in% names(dt))
  expect_true("full_name" %in% names(dt))

  # Chain-level fields
  expect_true("chain_name" %in% names(dt))
  expect_true("withdrawal_min_fee" %in% names(dt))
  expect_true("is_deposit_enabled" %in% names(dt))
})

# -- get_symbol --

test_that("get_symbol returns single-row data.table with snake_case names", {
  resp <- mock_kucoin_response(data = mock_symbol_data())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_symbol("BTC-USDT")

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "BTC-USDT")
  expect_true("base_currency" %in% names(dt))
  expect_true("quote_currency" %in% names(dt))
  expect_true("price_increment" %in% names(dt))
  expect_true("enable_trading" %in% names(dt))
})

# -- get_all_symbols --

test_that("get_all_symbols returns multi-row data.table", {
  symbols_data <- list(mock_symbol_data())
  # Add a second symbol
  eth_sym <- mock_symbol_data()
  eth_sym$symbol <- "ETH-USDT"
  eth_sym$name <- "ETH-USDT"
  eth_sym$baseCurrency <- "ETH"
  symbols_data[[2]] <- eth_sym

  resp <- mock_kucoin_response(data = symbols_data)
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_all_symbols()

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("BTC-USDT", "ETH-USDT") %in% dt$symbol))
})

# -- get_klines --

test_that("get_klines returns OHLCV data.table via kucoin_fetch_klines", {
  set.seed(42)
  klines <- mock_klines_data(n = 5, start_ts = 1729100000)
  resp <- mock_kucoin_response(data = klines)
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_klines(
    symbol = "BTC-USDT",
    freq = "15min",
    from = 1729100000,
    to = 1729110000
  )

  expect_s3_class(dt, "data.table")
  expect_equal(names(dt), c("datetime", "open", "high", "low", "close", "volume", "turnover"))
  expect_gt(nrow(dt), 0L)
})

# -- get_full_orderbook (authenticated) --

test_that("get_full_orderbook passes authentication headers", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = mock_orderbook_data())

  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret", api_passphrase = "test-pass")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_full_orderbook("BTC-USDT")

  expect_s3_class(dt, "data.table")
  expect_true("KC-API-KEY" %in% names(captured_req$headers))
  expect_equal(captured_req$headers[["KC-API-KEY"]], "test-key")
})

# -- get_server_time --

test_that("get_server_time returns server_time and datetime", {
  resp <- mock_kucoin_response(data = 1729100692873)
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_server_time()

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$server_time, 1729100692873)
  expect_s3_class(dt$datetime, "POSIXct")
})

# -- get_service_status --

test_that("get_service_status returns status and msg", {
  resp <- mock_kucoin_response(data = list(status = "open", msg = ""))
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_service_status()

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "open")
})

test_that("get_service_status detects maintenance", {
  resp <- mock_kucoin_response(data = list(status = "close", msg = "Scheduled maintenance"))
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_service_status()

  expect_equal(dt$status, "close")
  expect_equal(dt$msg, "Scheduled maintenance")
})

# -- get_fiat_prices --

test_that("get_fiat_prices returns currency-price table", {
  resp <- mock_kucoin_response(
    data = list(
      BTC = "67133.4165",
      ETH = "2607.6655",
      USDT = "1.0001"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_fiat_prices(base = "USD", currencies = "BTC,ETH,USDT")

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_equal(names(dt), c("currency", "price"))
  expect_true("BTC" %in% dt$currency)
  expect_equal(dt[currency == "BTC", price], "67133.4165")
})

test_that("get_fiat_prices handles empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  market <- KucoinMarketData$new(keys = keys, base_url = "https://api.kucoin.com")
  dt <- market$get_fiat_prices()

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
