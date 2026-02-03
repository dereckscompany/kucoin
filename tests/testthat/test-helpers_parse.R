# tests/testthat/test-helpers_parse.R
# Tests for response parsing and data.table construction helpers.

test_that("to_snake_case converts camelCase correctly", {
  expect_equal(to_snake_case("clientOid"), "client_oid")
  expect_equal(to_snake_case("isMarginEnabled"), "is_margin_enabled")
  expect_equal(to_snake_case("bestBidSize"), "best_bid_size")
  expect_equal(to_snake_case("changeRate"), "change_rate")
  expect_equal(to_snake_case("symbol"), "symbol")
  expect_equal(to_snake_case("annURL"), "ann_url")
})

test_that("to_snake_case handles vectors", {
  input <- c("baseCurrency", "quoteCurrency", "feeCurrency")
  expected <- c("base_currency", "quote_currency", "fee_currency")
  expect_equal(to_snake_case(input), expected)
})

test_that("as_dt_row converts named list to single-row data.table", {
  x <- list(symbol = "BTC-USDT", baseCurrency = "BTC", price = "67000.5")
  dt <- as_dt_row(x)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("base_currency" %in% names(dt))
  expect_equal(dt$symbol, "BTC-USDT")
  expect_equal(dt$base_currency, "BTC")
})

test_that("as_dt_row replaces NULLs with NA", {
  x <- list(symbol = "BTC-USDT", confirms = NULL, contractAddress = NULL)
  dt <- as_dt_row(x)
  expect_true(is.na(dt$confirms))
  expect_true(is.na(dt$contract_address))
})

test_that("as_dt_row returns empty data.table for NULL input", {
  expect_equal(nrow(as_dt_row(NULL)), 0L)
  expect_equal(nrow(as_dt_row(list())), 0L)
})

test_that("as_dt_list binds list of lists into data.table", {
  items <- list(
    list(symbol = "BTC-USDT", price = "67000"),
    list(symbol = "ETH-USDT", price = "2500")
  )
  dt <- as_dt_list(items)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_equal(dt$symbol, c("BTC-USDT", "ETH-USDT"))
})

test_that("as_dt_list returns empty data.table for NULL/empty", {
  expect_equal(nrow(as_dt_list(NULL)), 0L)
  expect_equal(nrow(as_dt_list(list())), 0L)
})

test_that("ms_to_datetime converts millisecond timestamps", {
  # 1729159459033 ms = 2024-10-17T10:04:19 UTC
  result <- ms_to_datetime(1729159459033)
  expect_s3_class(result, "POSIXct")
  expect_equal(as.numeric(result), 1729159459.033, tolerance = 0.001)
})

test_that("ms_to_datetime returns NA for NULL/NA input", {
  expect_true(is.na(ms_to_datetime(NULL)))
  expect_true(is.na(ms_to_datetime(NA)))
})

test_that("ns_to_datetime converts nanosecond timestamps", {
  # 1729159459033000000 ns = 1729159459.033 seconds
  result <- ns_to_datetime(1729159459033000000)
  expect_s3_class(result, "POSIXct")
  expect_equal(as.numeric(result), 1729159459.033, tolerance = 0.001)
})

test_that("ns_to_datetime returns NA for NULL/NA input", {
  expect_true(is.na(ns_to_datetime(NULL)))
  expect_true(is.na(ns_to_datetime(NA)))
})

test_that("parse_orderbook creates correct data.table from bid/ask arrays", {
  data <- mock_orderbook_data()
  dt <- parse_orderbook(data)

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 6L) # 3 bids + 3 asks
  expect_equal(names(dt), c("datetime", "sequence", "side", "price", "size"))

  # Check sides
  expect_equal(sum(dt$side == "bid"), 3L)
  expect_equal(sum(dt$side == "ask"), 3L)

  # Check types
  expect_s3_class(dt$datetime, "POSIXct")
  expect_type(dt$price, "double")
  expect_type(dt$size, "double")

  # Check values
  expect_equal(dt[side == "bid"][1]$price, 67232.8)
  expect_equal(dt[side == "ask"][1]$price, 67232.9)
})

test_that("parse_orderbook handles empty bids/asks", {
  data <- list(time = 1729159459033, sequence = "123", bids = list(), asks = list())
  dt <- parse_orderbook(data)
  expect_equal(nrow(dt), 0L)
})

test_that("parse_klines creates correct OHLCV data.table", {
  set.seed(42)
  data <- mock_klines_data(n = 3, start_ts = 1729100000)
  dt <- parse_klines(data)

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_equal(names(dt), c("datetime", "open", "high", "low", "close", "volume", "turnover"))

  # Check types
  expect_s3_class(dt$datetime, "POSIXct")
  expect_type(dt$open, "double")
  expect_type(dt$high, "double")
  expect_type(dt$low, "double")
  expect_type(dt$close, "double")
  expect_type(dt$volume, "double")
  expect_type(dt$turnover, "double")

  # Column order is OHLCV (open before high before low before close)
  col_positions <- match(c("open", "high", "low", "close"), names(dt))
  expect_true(all(diff(col_positions) > 0))
})

test_that("parse_klines reorders KuCoin close/high/low correctly", {
  # KuCoin returns: [ts, open, close, high, low, vol, turnover]
  # We want: datetime, open, high, low, close, vol, turnover
  data <- list(
    c("1729100000", "100", "103", "105", "98", "50", "5000")
  )
  dt <- parse_klines(data)
  expect_equal(dt$open, 100)
  expect_equal(dt$high, 105) # position 4 in KuCoin data
  expect_equal(dt$low, 98) # position 5 in KuCoin data
  expect_equal(dt$close, 103) # position 3 in KuCoin data
})

test_that("parse_klines returns empty data.table for NULL/empty", {
  expect_equal(nrow(parse_klines(NULL)), 0L)
  expect_equal(nrow(parse_klines(list())), 0L)
})

test_that("flatten_pages combines paginated results", {
  pages <- list(
    list(
      list(annId = 1L, annTitle = "First"),
      list(annId = 2L, annTitle = "Second")
    ),
    list(
      list(annId = 3L, annTitle = "Third")
    )
  )
  dt <- flatten_pages(pages)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("ann_id" %in% names(dt))
  expect_true("ann_title" %in% names(dt))
})

test_that("flatten_pages returns empty data.table for empty input", {
  expect_equal(nrow(flatten_pages(list())), 0L)
})
