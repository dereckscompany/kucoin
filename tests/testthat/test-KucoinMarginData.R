# tests/testthat/test-KucoinMarginData.R
# Tests for KucoinMarginData R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_margin_data <- function() {
  return(KucoinMarginData$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("KucoinMarginData inherits from KucoinBase", {
  md <- new_margin_data()
  expect_s3_class(md, "KucoinMarginData")
  expect_s3_class(md, "KucoinBase")
})

# -- get_cross_margin_symbols --

test_that("get_cross_margin_symbols returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        symbol = "BTC-USDT",
        name = "BTC-USDT",
        enableTrading = TRUE,
        baseCurrency = "BTC",
        quoteCurrency = "USDT",
        baseIncrement = "0.00000001",
        quoteIncrement = "0.01",
        priceIncrement = "0.1"
      ),
      list(
        symbol = "ETH-USDT",
        name = "ETH-USDT",
        enableTrading = TRUE,
        baseCurrency = "ETH",
        quoteCurrency = "USDT",
        baseIncrement = "0.0000001",
        quoteIncrement = "0.01",
        priceIncrement = "0.01"
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_cross_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("enable_trading" %in% names(dt))
})

test_that("get_cross_margin_symbols returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_cross_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_isolated_margin_symbols --

test_that("get_isolated_margin_symbols returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        symbol = "BTC-USDT",
        symbolName = "BTC-USDT",
        baseCurrency = "BTC",
        quoteCurrency = "USDT",
        maxLeverage = 10,
        tradeEnable = TRUE
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_isolated_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("max_leverage" %in% names(dt))
})

# -- get_margin_config --

test_that("get_margin_config returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      maxLeverage = 10L,
      warningDebtRatio = "0.95",
      liqDebtRatio = "0.97",
      currencyList = list("BTC", "ETH", "USDT")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  config <- new_margin_data()$get_margin_config()
  expect_s3_class(config, "data.table")
  expect_equal(nrow(config), 3L)
  expect_equal(config$currency, c("BTC", "ETH", "USDT"))
  expect_true(all(config$max_leverage == 10L))
  expect_true(all(config$warning_debt_ratio == "0.95"))
})

# -- get_collateral_ratio --

test_that("get_collateral_ratio returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currencyList = list("BTC"),
        items = list(
          list(lowerLimit = "0", upperLimit = "10", collateralRatio = "1.0")
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  result <- new_margin_data()$get_collateral_ratio()
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1L)
  expect_equal(result$currency, "BTC")
  expect_equal(result$lower_limit, "0")
  expect_equal(result$upper_limit, "10")
  expect_equal(result$collateral_ratio, "1.0")
})

test_that("get_collateral_ratio flattens multi-currency multi-tier", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currencyList = list("BTC", "ETH"),
        items = list(
          list(lowerLimit = "0", upperLimit = "10", collateralRatio = "1.0"),
          list(lowerLimit = "10", upperLimit = "100", collateralRatio = "0.9")
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  result <- new_margin_data()$get_collateral_ratio()
  expect_s3_class(result, "data.table")
  # 2 currencies x 2 tiers = 4 rows
  expect_equal(nrow(result), 4L)
  expect_equal(sort(unique(result$currency)), c("BTC", "ETH"))
})

# -- get_risk_limit --

test_that("get_risk_limit returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currency = "BTC",
        borrowMaxAmount = "100",
        buyMaxAmount = "100",
        holdMaxAmount = "100",
        borrowEnabled = TRUE,
        precision = 8L
      ),
      list(
        currency = "USDT",
        borrowMaxAmount = "1000000",
        buyMaxAmount = "1000000",
        holdMaxAmount = "1000000",
        borrowEnabled = TRUE,
        precision = 2L
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_risk_limit(isIsolated = FALSE)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("currency" %in% names(dt))
  expect_true("borrow_max_amount" %in% names(dt))
})

test_that("get_risk_limit validates isIsolated", {
  expect_error(new_margin_data()$get_risk_limit(isIsolated = "no"), "logical")
})

test_that("get_risk_limit returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_risk_limit(isIsolated = FALSE)
  expect_equal(nrow(dt), 0L)
})

# -- Data-shape regression: no list columns, schema stability --
#
# Cross-package convention is "one entity = one row, no list columns". These
# tests pin the shape for each public method so a future change that would
# accidentally introduce a list column (e.g. via API drift surfacing a new
# nested object) fails loudly.

test_that("get_cross_margin_symbols produces no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      timestamp = 1772993986642,
      items = list(
        list(
          symbol = "BTC-USDT",
          name = "BTC-USDT",
          enableTrading = TRUE,
          market = "USDS",
          baseCurrency = "BTC",
          quoteCurrency = "USDT",
          baseIncrement = "0.00000001",
          baseMinSize = "0.00001",
          baseMaxSize = "10000000000",
          quoteIncrement = "0.000001",
          quoteMinSize = "0.1",
          quoteMaxSize = "99999999",
          priceIncrement = "0.1",
          feeCurrency = "USDT",
          priceLimitRate = "0.01",
          minFunds = "0.1"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_cross_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$symbol))
  expect_true(is.logical(dt$enable_trading))
  expect_true(all(c("base_currency", "quote_currency", "min_funds") %in% names(dt)))
})

test_that("get_isolated_margin_symbols produces no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        symbol = "BTC-USDT",
        symbolName = "BTC-USDT",
        baseCurrency = "BTC",
        quoteCurrency = "USDT",
        maxLeverage = 10L,
        flDebtRatio = "0.97",
        tradeEnable = TRUE,
        baseBorrowEnable = TRUE,
        quoteBorrowEnable = TRUE,
        baseTransferInEnable = TRUE,
        quoteTransferInEnable = TRUE
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_isolated_margin_symbols()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$symbol))
  expect_true(is.integer(dt$max_leverage))
  expect_true(is.logical(dt$trade_enable))
  expect_true(is.logical(dt$base_borrow_enable))
})

test_that("get_isolated_margin_symbols returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_isolated_margin_symbols()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_margin_config produces no list columns and integer max_leverage", {
  resp <- mock_kucoin_response(
    data = list(
      maxLeverage = 10L,
      warningDebtRatio = "0.95",
      liqDebtRatio = "0.97",
      currencyList = list("BTC", "ETH", "USDT")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  config <- new_margin_data()$get_margin_config()
  expect_equal(length(names(config)[vapply(config, is.list, logical(1))]), 0L)
  expect_true(is.character(config$currency))
  expect_true(is.integer(config$max_leverage))
  expect_true(is.character(config$warning_debt_ratio))
  expect_true(is.character(config$liq_debt_ratio))
  expect_equal(names(config)[1], "currency")
})

test_that("get_margin_config returns zero-row schema-stable table when currencyList is empty", {
  resp <- mock_kucoin_response(
    data = list(
      maxLeverage = 10L,
      warningDebtRatio = "0.95",
      liqDebtRatio = "0.97",
      currencyList = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  config <- new_margin_data()$get_margin_config()
  expect_s3_class(config, "data.table")
  expect_equal(nrow(config), 0L)
  expect_true(all(c("currency", "max_leverage", "warning_debt_ratio", "liq_debt_ratio") %in% names(config)))
  expect_equal(names(config)[1], "currency")
})

test_that("get_margin_config returns empty data.table for null data", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  config <- new_margin_data()$get_margin_config()
  expect_s3_class(config, "data.table")
  expect_equal(nrow(config), 0L)
})

test_that("get_collateral_ratio produces no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currencyList = list("BTC", "ETH"),
        items = list(
          list(lowerLimit = "0", upperLimit = "10", collateralRatio = "1.0")
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  result <- new_margin_data()$get_collateral_ratio()
  expect_equal(length(names(result)[vapply(result, is.list, logical(1))]), 0L)
  expect_true(is.character(result$currency))
  expect_true(is.character(result$lower_limit))
  expect_true(is.character(result$upper_limit))
  expect_true(is.character(result$collateral_ratio))
  expect_equal(nrow(result), 2L)
})

test_that("get_collateral_ratio returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_collateral_ratio()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_risk_limit produces no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currency = "BTC",
        borrowMaxAmount = "100",
        buyMaxAmount = "100",
        holdMaxAmount = "100",
        borrowCoefficient = "1",
        marginCoefficient = "1",
        precision = 8L,
        borrowMinAmount = "0.001",
        borrowMinUnit = "0.001",
        borrowEnabled = TRUE
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin_data()$get_risk_limit(isIsolated = FALSE)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$currency))
  expect_true(is.integer(dt$precision))
  expect_true(is.logical(dt$borrow_enabled))
})
