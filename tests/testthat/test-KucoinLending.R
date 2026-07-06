# tests/testthat/test-KucoinLending.R
# Tests for KucoinLending R6 class with mocked HTTP.

# -- Construction --

test_that("KucoinLending inherits from KucoinBase", {
  l <- new_lending()
  expect_s3_class(l, "KucoinLending")
  expect_s3_class(l, "KucoinBase")
})

# -- get_loan_market --

test_that("get_loan_market returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currency = "USDT",
        purchaseEnable = TRUE,
        redeemEnable = TRUE,
        increment = "0.01",
        minPurchaseSize = "10",
        maxPurchaseSize = "1000000"
      ),
      list(
        currency = "BTC",
        purchaseEnable = TRUE,
        redeemEnable = TRUE,
        increment = "0.0001",
        minPurchaseSize = "0.001",
        maxPurchaseSize = "100"
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_loan_market()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("currency" %in% names(dt))
  expect_true("purchase_enable" %in% names(dt))
})

test_that("get_loan_market returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_loan_market()
  expect_equal(nrow(dt), 0L)
})

# -- get_loan_market_rate --

test_that("get_loan_market_rate returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(time = "202603070000", marketInterestRate = "0.05"),
      list(time = "202603080000", marketInterestRate = "0.048")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_loan_market_rate(currency = "USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("market_interest_rate" %in% names(dt))
})

test_that("get_loan_market_rate validates currency", {
  expect_error(new_lending()$get_loan_market_rate(currency = ""), "non-empty")
})

# -- purchase --

test_that("purchase returns order_no", {
  resp <- mock_kucoin_response(data = list(orderNo = "purchase-001"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$purchase(currency = "USDT", size = 1000, interest_rate = 0.05)
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_no, "purchase-001")
})

test_that("purchase validates parameters", {
  expect_error(new_lending()$purchase(currency = "", size = 100, interest_rate = 0.05), "non-empty")
  expect_error(new_lending()$purchase(currency = "USDT", size = -1, interest_rate = 0.05), "positive")
  expect_error(new_lending()$purchase(currency = "USDT", size = 100, interest_rate = 0), "positive")
})

# -- modify_purchase --

test_that("modify_purchase returns confirmation data.table on success", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$modify_purchase(
    currency = "USDT",
    purchase_order_no = "abc123",
    interest_rate = 0.06
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$currency, "USDT")
  expect_equal(dt$purchase_order_no, "abc123")
  expect_equal(dt$interest_rate, 0.06)
  expect_equal(dt$status, "success")
})

test_that("modify_purchase validates parameters", {
  expect_error(new_lending()$modify_purchase(currency = "", purchase_order_no = "a", interest_rate = 0.05), "non-empty")
  expect_error(
    new_lending()$modify_purchase(currency = "USDT", purchase_order_no = "", interest_rate = 0.05),
    "non-empty"
  )
  expect_error(
    new_lending()$modify_purchase(currency = "USDT", purchase_order_no = "a", interest_rate = -1),
    "positive"
  )
})

# -- get_purchase_orders --

test_that("get_purchase_orders returns data.table with apply_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          currency = "USDT",
          purchaseOrderNo = "p1",
          purchaseSize = "1000",
          matchSize = "800",
          interestRate = "0.05",
          incomeSize = "3.42",
          applyTime = 1729655606816,
          status = "DONE"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_purchase_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("apply_time" %in% names(dt))
  expect_false("datetime_applied" %in% names(dt))
  expect_equal(names(dt)[1], "currency")
})

test_that("get_purchase_orders returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_purchase_orders()
  expect_equal(nrow(dt), 0L)
})

# -- redeem --

test_that("redeem returns order_no", {
  resp <- mock_kucoin_response(data = list(orderNo = "redeem-001"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$redeem(currency = "USDT", size = 500, purchase_order_no = "abc123")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_no, "redeem-001")
})

test_that("redeem validates parameters", {
  expect_error(new_lending()$redeem(currency = "", size = 100, purchase_order_no = "a"), "non-empty")
  expect_error(new_lending()$redeem(currency = "USDT", size = 0, purchase_order_no = "a"), "positive")
  expect_error(new_lending()$redeem(currency = "USDT", size = 100, purchase_order_no = ""), "non-empty")
})

# -- get_redeem_orders --

test_that("get_redeem_orders returns data.table with apply_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          currency = "USDT",
          purchaseOrderNo = "p1",
          redeemOrderNo = "r1",
          redeemSize = "500",
          receiptSize = "500",
          applyTime = 1729655606816,
          status = "DONE"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_redeem_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("apply_time" %in% names(dt))
  expect_false("datetime_applied" %in% names(dt))
  expect_equal(names(dt)[1], "currency")
})

test_that("get_redeem_orders returns empty data.table for empty items", {
  resp <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_redeem_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- Data-shape regression: no list columns, schema stability --
#
# Cross-package convention is "one entity = one row, no list columns".

test_that("get_loan_market produces no list columns and correct types", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        currency = "USDT",
        purchaseEnable = TRUE,
        redeemEnable = TRUE,
        increment = "0.01",
        minPurchaseSize = "10",
        maxPurchaseSize = "1000000",
        interestIncrement = "0.0001",
        minInterestRate = "0.004",
        marketInterestRate = "0.05",
        maxInterestRate = "0.1",
        autoPurchaseEnable = TRUE
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_loan_market()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$currency))
  expect_true(is.logical(dt$purchase_enable))
  expect_true(is.logical(dt$redeem_enable))
  expect_true(is.numeric(dt$increment))
  expect_true(is.logical(dt$auto_purchase_enable))
})

test_that("get_loan_market_rate produces no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      list(time = "202603070000", marketInterestRate = "0.05"),
      list(time = "202603080000", marketInterestRate = "0.048")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_loan_market_rate(currency = "USDT")
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$time))
  expect_true(is.numeric(dt$market_interest_rate))
})

test_that("get_loan_market_rate returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_loan_market_rate(currency = "USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("purchase returns no list columns", {
  resp <- mock_kucoin_response(data = list(orderNo = "p-1"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$purchase(currency = "USDT", size = 1000, interest_rate = 0.05)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$order_no))
})

test_that("redeem returns no list columns", {
  resp <- mock_kucoin_response(data = list(orderNo = "r-1"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$redeem(currency = "USDT", size = 500, purchase_order_no = "abc123")
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$order_no))
})

test_that("modify_purchase returns no list columns", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$modify_purchase(
    currency = "USDT",
    purchase_order_no = "abc",
    interest_rate = 0.06
  )
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_purchase_orders schema: no list columns, POSIXct apply_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          currency = "USDT",
          purchaseOrderNo = "p1",
          purchaseSize = "1000",
          matchSize = "800",
          interestRate = "0.05",
          incomeSize = "3.42",
          applyTime = 1729655606816,
          status = "DONE"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_purchase_orders()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_s3_class(dt$apply_time, "POSIXct")
  expect_true(is.character(dt$currency))
  expect_true(is.character(dt$purchase_order_no))
})

test_that("get_redeem_orders schema: no list columns, POSIXct apply_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          currency = "USDT",
          purchaseOrderNo = "p1",
          redeemOrderNo = "r1",
          redeemSize = "500",
          receiptSize = "500",
          applyTime = 1729655606816,
          status = "DONE"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_lending()$get_redeem_orders()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_s3_class(dt$apply_time, "POSIXct")
  expect_true(is.character(dt$currency))
  expect_true(is.character(dt$redeem_order_no))
})
