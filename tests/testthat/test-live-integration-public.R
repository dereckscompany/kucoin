# tests/testthat/test-live-integration-public.R
# Live integration tests for public (no auth) endpoints.
# These hit the real KuCoin API — no mocking.
#
# Run with:
#   KUCOIN_LIVE_TESTS=true Rscript -e 'devtools::test(filter = "live")'

skip_if_not(
  identical(Sys.getenv("KUCOIN_LIVE_TESTS"), "true"),
  "Live API tests skipped (set KUCOIN_LIVE_TESTS=true to run)"
)

# Rate limit helper — be polite to KuCoin
throttle <- function() Sys.sleep(0.5)

# All public endpoints use no auth; construct once
market <- KucoinMarketData$new()
margin_data <- KucoinMarginData$new()
lending <- KucoinLending$new()

# =============================================================================
# KucoinMarketData — Public Endpoints
# =============================================================================

test_that("[LIVE] get_server_time returns data.table with valid datetime", {
  dt <- market$get_server_time()
  expect_s3_class(dt, "data.table")
  expect_true("datetime" %in% names(dt))
  expect_s3_class(dt$datetime, "POSIXct")
  # Server time should be within 60 seconds of our local time
  diff_secs <- abs(as.numeric(difftime(dt$datetime, Sys.time(), units = "secs")))
  expect_true(diff_secs < 60, info = paste("Clock drift:", diff_secs, "seconds"))
  throttle()
})

test_that("[LIVE] get_service_status returns data.table", {
  dt <- market$get_service_status()
  expect_s3_class(dt, "data.table")
  expect_true("status" %in% names(dt))
  expect_true(nrow(dt) == 1L)
  throttle()
})

test_that("[LIVE] get_market_list returns data.table of markets", {
  dt <- market$get_market_list()
  expect_s3_class(dt, "data.table")
  expect_true("market" %in% names(dt))
  expect_true(nrow(dt) > 0)
  # BTC and USDS markets should always exist
  expect_true("BTC" %in% dt$market)
  expect_true("USDS" %in% dt$market)
  throttle()
})

test_that("[LIVE] get_all_currencies returns data.table with expected columns", {
  dt <- market$get_all_currencies()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 100, info = "Expected 100+ currencies")
  expect_true(all(c("currency", "full_name") %in% names(dt)))
  # BTC should be present
  expect_true("BTC" %in% dt$currency)
  throttle()
})

test_that("[LIVE] get_currency returns data.table for BTC", {
  dt <- market$get_currency("BTC")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
  expect_true("currency" %in% names(dt))
  expect_true(all(dt$currency == "BTC"))
  throttle()
})

test_that("[LIVE] get_symbol returns data.table for BTC-USDT", {
  dt <- market$get_symbol("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("symbol" %in% names(dt))
  expect_equal(dt$symbol, "BTC-USDT")
  throttle()
})

test_that("[LIVE] get_all_symbols returns data.table with many pairs", {
  dt <- market$get_all_symbols()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 100, info = "Expected 100+ trading pairs")
  expect_true("symbol" %in% names(dt))
  expect_true("BTC-USDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] get_all_symbols with market filter returns subset", {
  dt <- market$get_all_symbols(market = "BTC")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  throttle()
})

test_that("[LIVE] get_ticker returns data.table for BTC-USDT", {
  dt <- market$get_ticker("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("price", "size", "best_bid", "best_ask") %in% names(dt)))
  # Price should be a reasonable number (> $1000)
  expect_true(as.numeric(dt$price) > 1000)
  throttle()
})

test_that("[LIVE] get_all_tickers returns data.table with many tickers", {
  dt <- market$get_all_tickers()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 100, info = "Expected 100+ tickers")
  expect_true(all(c("symbol", "last") %in% names(dt)))
  expect_true("BTC-USDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] get_24hr_stats returns data.table for BTC-USDT", {
  dt <- market$get_24hr_stats("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("symbol", "high", "low", "vol") %in% names(dt)))
  expect_equal(dt$symbol, "BTC-USDT")
  throttle()
})

test_that("[LIVE] get_trade_history returns data.table for BTC-USDT", {
  dt <- market$get_trade_history("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("price", "size", "side") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_part_orderbook returns data.table for BTC-USDT", {
  dt <- market$get_part_orderbook("BTC-USDT", size = 20)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("price", "size", "side") %in% names(dt)))
  expect_true(all(dt$side %in% c("bid", "ask")))
  throttle()
})

test_that("[LIVE] get_fiat_prices returns data.table", {
  dt <- market$get_fiat_prices()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("currency" %in% names(dt))
  expect_true("BTC" %in% dt$currency)
  throttle()
})

test_that("[LIVE] get_klines returns data.table with OHLCV data", {
  dt <- market$get_klines(
    symbol = "BTC-USDT",
    timeframe = "1hour",
    from = Sys.time() - 86400,
    to = Sys.time()
  )
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("datetime", "open", "high", "low", "close", "volume") %in% names(dt)))
  expect_s3_class(dt$datetime, "POSIXct")
  # OHLCV should be numeric
  expect_type(dt$open, "double")
  expect_type(dt$close, "double")
  throttle()
})

test_that("[LIVE] get_announcements returns data.table", {
  dt <- market$get_announcements(page_size = 5, max_pages = 1)
  expect_s3_class(dt, "data.table")
  # Might be empty if no recent announcements, but should still be data.table
  if (nrow(dt) > 0) {
    expect_true("ann_title" %in% names(dt) || "title" %in% names(dt) || ncol(dt) > 0)
  }
  throttle()
})

# =============================================================================
# KucoinMarginData — Public Endpoints
# =============================================================================

test_that("[LIVE] get_cross_margin_symbols returns data.table", {
  dt <- margin_data$get_cross_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("symbol", "base_currency", "quote_currency") %in% names(dt)))
  expect_true("BTC-USDT" %in% dt$symbol)
  throttle()
})

test_that("[LIVE] get_isolated_margin_symbols returns data.table", {
  dt <- margin_data$get_isolated_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("symbol" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_margin_config returns data.table with config", {
  dt <- margin_data$get_margin_config()
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0L)
  expect_true("currency" %in% names(dt))
  expect_true("max_leverage" %in% names(dt))
  expect_true(all(dt$max_leverage > 0))
  expect_true(all(nchar(dt$currency) > 0))
  throttle()
})

test_that("[LIVE] get_collateral_ratio returns data.table", {
  dt <- margin_data$get_collateral_ratio()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("currency", "lower_limit", "upper_limit", "collateral_ratio") %in% names(dt)))
  # BTC should be present
  expect_true("BTC" %in% dt$currency)
  throttle()
})

# =============================================================================
# KucoinLending — Public Endpoints
# =============================================================================

test_that("[LIVE] get_loan_market_rate returns data.table for USDT", {
  dt <- lending$get_loan_market_rate("USDT")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  throttle()
})
