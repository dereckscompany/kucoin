# tests/testthat/test-KucoinWithdrawal.R
# Tests for KucoinWithdrawal R6 class with mocked HTTP.

# -- Construction --

test_that("KucoinWithdrawal inherits from KucoinBase", {
  w <- new_withdrawal()
  expect_s3_class(w, "KucoinWithdrawal")
  expect_s3_class(w, "KucoinBase")
})

# -- add_withdrawal --

test_that("add_withdrawal returns data.table with withdrawal_id", {
  resp <- mock_kucoin_response(data = list(withdrawalId = "670deec84d64da0007d7c946"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$add_withdrawal(
    currency = "USDT",
    toAddress = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    amount = "10",
    withdrawType = "ADDRESS",
    chain = "trx"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$withdrawal_id, "670deec84d64da0007d7c946")
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("add_withdrawal validates currency", {
  expect_error(
    new_withdrawal()$add_withdrawal(
      currency = "",
      toAddress = "addr",
      amount = "10",
      withdrawType = "ADDRESS"
    ),
    "currency.*non-empty"
  )
})

test_that("add_withdrawal validates toAddress", {
  expect_error(
    new_withdrawal()$add_withdrawal(
      currency = "BTC",
      toAddress = "",
      amount = "10",
      withdrawType = "ADDRESS"
    ),
    "toAddress.*non-empty"
  )
})

test_that("add_withdrawal validates amount", {
  expect_error(
    new_withdrawal()$add_withdrawal(
      currency = "BTC",
      toAddress = "addr",
      amount = "",
      withdrawType = "ADDRESS"
    ),
    "amount.*non-empty"
  )
})

test_that("add_withdrawal validates withdrawType", {
  expect_error(
    new_withdrawal()$add_withdrawal(
      currency = "BTC",
      toAddress = "addr",
      amount = "10",
      withdrawType = "INVALID"
    ),
    "withdrawType.*ADDRESS"
  )
})

test_that("add_withdrawal includes optional parameters", {
  resp <- mock_kucoin_response(data = list(withdrawalId = "wd1"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$add_withdrawal(
    currency = "USDT",
    toAddress = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    amount = "10",
    withdrawType = "ADDRESS",
    chain = "trx",
    memo = "test-memo",
    isInner = TRUE,
    remark = "test-remark",
    feeDeductType = "INTERNAL"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(dt$withdrawal_id, "wd1")
})

# -- cancel_withdrawal --

test_that("cancel_withdrawal returns data.table with withdrawal_id", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$cancel_withdrawal("670deec84d64da0007d7c946")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$withdrawal_id, "670deec84d64da0007d7c946")
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("cancel_withdrawal validates withdrawalId", {
  expect_error(
    new_withdrawal()$cancel_withdrawal(""),
    "withdrawalId.*non-empty"
  )
})

# -- get_withdrawal_quotas --

test_that("get_withdrawal_quotas returns data.table with quota details", {
  resp <- mock_kucoin_response(
    data = list(
      currency = "BTC",
      limitBTCAmount = "15.79590095",
      usedBTCAmount = "0.00000000",
      quotaCurrency = "USDT",
      limitQuotaCurrencyAmount = "999999.00000000",
      usedQuotaCurrencyAmount = "0",
      remainAmount = "15.79590095",
      availableAmount = "0.5",
      withdrawMinFee = "0.0005",
      innerWithdrawMinFee = "0",
      withdrawMinSize = "0.001",
      isWithdrawEnabled = TRUE,
      precision = 8L,
      chain = "BTC",
      reason = NULL,
      lockedAmount = "0"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$get_withdrawal_quotas(currency = "BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$currency, "BTC")
  expect_equal(dt$is_withdraw_enabled, TRUE)
  expect_equal(dt$withdraw_min_fee, 0.0005)
  expect_equal(dt$precision, 8L)
  # Check column ordering starts with currency
  expect_equal(names(dt)[1], "currency")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_withdrawal_quotas validates currency", {
  expect_error(
    new_withdrawal()$get_withdrawal_quotas(currency = ""),
    "currency.*non-empty"
  )
})

# -- get_withdrawal_history --

test_that("get_withdrawal_history returns paginated data with created_at", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 50,
      totalNum = 1,
      totalPage = 1,
      items = list(
        list(
          currency = "USDT",
          chain = "",
          status = "SUCCESS",
          address = "a435*****@gmail.com",
          memo = "",
          isInner = TRUE,
          amount = "1.00000000",
          fee = "0.00000000",
          walletTxId = NULL,
          createdAt = 1728555875000,
          updatedAt = 1728555875000,
          remark = "",
          arrears = FALSE
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$get_withdrawal_history(currency = "USDT", status = "SUCCESS")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
  # updated_at now coerced to POSIXct
  expect_s3_class(dt$updated_at, "POSIXct")
  expect_equal(dt$currency, "USDT")
  expect_equal(dt$status, "SUCCESS")
  # Check column ordering
  expect_equal(names(dt)[1], "currency")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_withdrawal_history handles empty items", {
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

  dt <- new_withdrawal()$get_withdrawal_history(currency = "BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_withdrawal_history validates currency", {
  expect_error(
    new_withdrawal()$get_withdrawal_history(currency = ""),
    "currency.*non-empty"
  )
})

# -- get_withdrawal_by_id --

test_that("get_withdrawal_by_id returns detailed data.table with created_at", {
  resp <- mock_kucoin_response(
    data = list(
      id = "67e6515f7960ba0007b42025",
      uid = 165111215L,
      currency = "USDT",
      chainId = "trx",
      chainName = "TRC20",
      currencyName = "USDT",
      status = "SUCCESS",
      failureReason = "",
      failureReasonMsg = NULL,
      address = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
      memo = "",
      isInner = TRUE,
      amount = "3.00000000",
      fee = "0.00000000",
      walletTxId = NULL,
      addressRemark = "test",
      remark = "this is Remark",
      createdAt = 1743147359000,
      cancelType = "NON_CANCELABLE",
      taxes = NULL,
      taxDescription = NULL,
      txId = NULL,
      returnStatus = "NOT_RETURN",
      returnAmount = NULL,
      returnCurrency = "KCS"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_withdrawal()$get_withdrawal_by_id("67e6515f7960ba0007b42025")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
  expect_equal(dt$id, "67e6515f7960ba0007b42025")
  expect_equal(dt$currency, "USDT")
  expect_equal(dt$status, "SUCCESS")
  expect_equal(dt$cancel_type, "NON_CANCELABLE")
  # Check column ordering starts with id
  expect_equal(names(dt)[1], "id")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_withdrawal_by_id validates withdrawalId", {
  expect_error(
    new_withdrawal()$get_withdrawal_by_id(""),
    "withdrawalId.*non-empty"
  )
})
