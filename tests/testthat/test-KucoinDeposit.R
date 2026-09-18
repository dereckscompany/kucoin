# tests/testthat/test-KucoinDeposit.R
# Tests for KucoinDeposit R6 class with mocked HTTP.

# -- Construction --

test_that("KucoinDeposit inherits from KucoinBase", {
  d <- new_deposit()
  expect_s3_class(d, "KucoinDeposit")
  expect_s3_class(d, "KucoinBase")
})

# -- add_deposit_address --

test_that("add_deposit_address returns data.table with column reorder", {
  resp <- mock_kucoin_response(
    data = list(
      address = "bc1q00000000000000000000000000000000000000",
      memo = "",
      chain = "btc",
      chainId = "btc",
      to = "main",
      currency = "BTC",
      contractAddress = ""
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$add_deposit_address(currency = "BTC", chain = "btc", to = "main")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$address, "bc1q00000000000000000000000000000000000000")
  expect_equal(dt$currency, "BTC")
  # Check column ordering starts with address
  expect_equal(names(dt)[1], "address")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

# -- get_deposit_addresses --

test_that("get_deposit_addresses returns array as multi-row data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        address = "addr1",
        memo = "",
        chain = "btc",
        chainId = "btc",
        to = "main",
        currency = "BTC",
        contractAddress = ""
      ),
      list(
        address = "addr2",
        memo = "",
        chain = "ERC20",
        chainId = "eth",
        to = "main",
        currency = "BTC",
        contractAddress = "0x0000000000000000000000000000000000000001"
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_addresses(currency = "BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_equal(names(dt)[1], "address")
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_deposit_addresses handles single object response", {
  resp <- mock_kucoin_response(
    data = list(
      address = "addr1",
      memo = "",
      chain = "btc",
      chainId = "btc",
      to = "main",
      currency = "BTC",
      contractAddress = ""
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_addresses(currency = "BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_deposit_addresses handles empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_addresses(currency = "BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_deposit_history --

test_that("get_deposit_history returns paginated data with created_at and column reorder", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 50,
      totalNum = 1,
      totalPage = 1,
      items = list(
        list(
          currency = "BTC",
          chain = "btc",
          status = "SUCCESS",
          address = "bc1q00000000000000000000000000000000000000",
          memo = "",
          isInner = FALSE,
          amount = "0.05000000",
          fee = "0.00000000",
          walletTxId = "a1b2c3d4e5f6",
          createdAt = 1767571500000,
          updatedAt = 1767571800000,
          remark = ""
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_deposit()$get_deposit_history(currency = "BTC", status = "SUCCESS")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
  # updated_at now coerced to POSIXct as well
  expect_s3_class(dt$updated_at, "POSIXct")
  expect_equal(dt$currency, "BTC")
  expect_equal(dt$status, "SUCCESS")
  # Check column ordering
  expect_equal(names(dt)[1], "currency")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_deposit_history handles empty items", {
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

  dt <- new_deposit()$get_deposit_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
