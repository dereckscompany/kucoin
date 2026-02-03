# tests/testthat/test-KucoinAccount.R
# Tests for KucoinAccount R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_account <- function() {
  KucoinAccount$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinAccount inherits from KucoinBase", {
  a <- new_account()
  expect_s3_class(a, "KucoinAccount")
  expect_s3_class(a, "KucoinBase")
})

# -- get_summary --

test_that("get_summary returns data.table with expected columns", {
  resp <- mock_kucoin_response(
    data = list(
      level = 1,
      subQuantity = 3,
      maxDefaultSubQuantity = 5,
      maxSubQuantity = 5,
      spotSubQuantity = 2,
      marginSubQuantity = 1,
      futuresSubQuantity = 0,
      optionSubQuantity = 0,
      maxSpotSubQuantity = 5,
      maxMarginSubQuantity = 5,
      maxFuturesSubQuantity = 5,
      maxOptionSubQuantity = 5
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_summary()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("level" %in% names(dt))
  expect_true("sub_quantity" %in% names(dt))
  expect_equal(dt$level, 1)
  expect_equal(dt$sub_quantity, 3)
})

# -- get_apikey_info --

test_that("get_apikey_info returns data.table with key details", {
  resp <- mock_kucoin_response(
    data = list(
      remark = "trading-bot",
      apiKey = "670c42f1a24b1b0001a5c7e0",
      apiVersion = 3,
      permission = "General,Spot",
      ipWhitelist = "198.51.100.42",
      createdAt = 1728905969000,
      uid = 123456789,
      isMaster = TRUE
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_apikey_info()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$api_key, "670c42f1a24b1b0001a5c7e0")
  expect_equal(dt$permission, "General,Spot")
  expect_true(dt$is_master)
})

# -- get_spot_account_type --

test_that("get_spot_account_type returns single named object as data.table", {
  resp <- mock_kucoin_response(data = list(type = "trade", isOpened = TRUE))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_account_type()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$type, "trade")
  expect_true(dt$is_opened)
})

test_that("get_spot_account_type returns array as multi-row data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(type = "trade", isOpened = TRUE),
      list(type = "margin", isOpened = FALSE)
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_account_type()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
})

test_that("get_spot_account_type handles empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_account_type()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_spot_accounts --

test_that("get_spot_accounts returns list of accounts", {
  resp <- mock_kucoin_response(
    data = list(
      list(id = "acc1", currency = "USDT", type = "trade", balance = "1250.75", available = "1200.50", holds = "50.25"),
      list(id = "acc2", currency = "BTC", type = "trade", balance = "0.05", available = "0.05", holds = "0")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_accounts()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("currency" %in% names(dt))
  expect_true("balance" %in% names(dt))
})

test_that("get_spot_accounts handles empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_accounts()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_spot_account_detail --

test_that("get_spot_account_detail returns single-row data.table", {
  resp <- mock_kucoin_response(
    data = list(
      currency = "USDT",
      balance = "1250.75",
      available = "1200.50",
      holds = "50.25"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_account_detail("5bd6e9286d99522a52e458de")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$currency, "USDT")
  expect_equal(dt$balance, "1250.75")
})

# -- get_cross_margin_account --

test_that("get_cross_margin_account extracts accounts sub-list", {
  resp <- mock_kucoin_response(
    data = list(
      totalAssetOfQuoteCurrency = "15234.67",
      totalLiabilityOfQuoteCurrency = "2500.00",
      debtRatio = "0.1641",
      status = "EFFECTIVE",
      accounts = list(
        list(
          currency = "USDT",
          totalBalance = "10000.00",
          availableBalance = "8500.00",
          holdBalance = "1500.00",
          liability = "2500.00",
          maxBorrowSize = "50000.00",
          borrowEnabled = TRUE,
          transferInEnabled = TRUE
        ),
        list(
          currency = "BTC",
          totalBalance = "0.15",
          availableBalance = "0.15",
          holdBalance = "0",
          liability = "0",
          maxBorrowSize = "2.5",
          borrowEnabled = TRUE,
          transferInEnabled = TRUE
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_cross_margin_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("currency" %in% names(dt))
  expect_true("total_balance" %in% names(dt))
  expect_true("borrow_enabled" %in% names(dt))
})

test_that("get_cross_margin_account handles empty accounts", {
  resp <- mock_kucoin_response(
    data = list(
      totalAssetOfQuoteCurrency = "0",
      accounts = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_cross_margin_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_isolated_margin_account --

test_that("get_isolated_margin_account extracts assets sub-list", {
  resp <- mock_kucoin_response(
    data = list(
      totalAssetOfQuoteCurrency = "5234.67",
      assets = list(
        list(symbol = "BTC-USDT", status = "EFFECTIVE", debtRatio = "0.19")
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_isolated_margin_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("symbol" %in% names(dt))
})

test_that("get_isolated_margin_account handles empty assets", {
  resp <- mock_kucoin_response(data = list(assets = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_isolated_margin_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_spot_ledger --

test_that("get_spot_ledger returns paginated data with datetime_created", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 50,
      totalNum = 1,
      totalPage = 1,
      items = list(
        list(
          id = "611a1e7c6a053300067a88de",
          currency = "USDT",
          amount = "125.50",
          fee = "0.1255",
          balance = "3750.25",
          accountType = "TRADE",
          bizType = "Exchange",
          direction = "in",
          createdAt = 1729176273859,
          context = "{}"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_ledger()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("datetime_created" %in% names(dt))
  expect_false("created_at" %in% names(dt))
  expect_s3_class(dt$datetime_created, "POSIXct")
  expect_equal(dt$currency, "USDT")
})

test_that("get_spot_ledger handles empty items", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 50,
      totalNum = 0,
      totalPage = 1,
      items = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_spot_ledger()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_hf_ledger --

test_that("get_hf_ledger returns ledger entries with datetime", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          id = "hf123",
          currency = "USDT",
          amount = "50.00",
          fee = "0.05",
          tax = "0",
          balance = "1000.00",
          accountType = "TRADE_HF",
          bizType = "TRADE_EXCHANGE",
          direction = "in",
          createdAt = 1729577515473,
          context = "{\"orderId\":\"abc\"}"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_hf_ledger(currency = "USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("datetime_created" %in% names(dt))
  expect_false("created_at" %in% names(dt))
  expect_equal(dt$biz_type, "TRADE_EXCHANGE")
})

test_that("get_hf_ledger handles empty response", {
  resp <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_hf_ledger()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_base_fee_rate --

test_that("get_base_fee_rate returns fee rates", {
  resp <- mock_kucoin_response(
    data = list(
      takerFeeRate = "0.001",
      makerFeeRate = "0.001"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_base_fee_rate()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$taker_fee_rate, "0.001")
  expect_equal(dt$maker_fee_rate, "0.001")
})

# -- get_fee_rate --

test_that("get_fee_rate returns per-symbol rates", {
  resp <- mock_kucoin_response(
    data = list(
      list(symbol = "BTC-USDT", takerFeeRate = "0.001", makerFeeRate = "0.001"),
      list(symbol = "ETH-USDT", takerFeeRate = "0.001", makerFeeRate = "0.001")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_fee_rate("BTC-USDT,ETH-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true("taker_fee_rate" %in% names(dt))
})

test_that("get_fee_rate validates symbols parameter", {
  expect_error(new_account()$get_fee_rate(""), "non-empty")
})
