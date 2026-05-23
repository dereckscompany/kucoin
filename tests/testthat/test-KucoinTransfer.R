# tests/testthat/test-KucoinTransfer.R
# Tests for KucoinTransfer R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_transfer <- function() {
  KucoinTransfer$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinTransfer inherits from KucoinBase", {
  t <- new_transfer()
  expect_s3_class(t, "KucoinTransfer")
  expect_s3_class(t, "KucoinBase")
})

# -- add_transfer --

test_that("add_transfer returns data.table with order_id", {
  resp <- mock_kucoin_response(data = list(orderId = "6705f7248c6954000733ecac"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$add_transfer(
    clientOid = "64ccc0f164781800010d8c09",
    currency = "USDT",
    amount = "100",
    type = "INTERNAL",
    fromAccountType = "MAIN",
    toAccountType = "TRADE"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_id, "6705f7248c6954000733ecac")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("add_transfer validates clientOid", {
  expect_error(
    new_transfer()$add_transfer(
      clientOid = "",
      currency = "USDT",
      amount = "100",
      type = "INTERNAL",
      fromAccountType = "MAIN",
      toAccountType = "TRADE"
    ),
    "clientOid.*non-empty"
  )
})

test_that("add_transfer validates currency", {
  expect_error(
    new_transfer()$add_transfer(
      clientOid = "uuid-1",
      currency = "",
      amount = "100",
      type = "INTERNAL",
      fromAccountType = "MAIN",
      toAccountType = "TRADE"
    ),
    "currency.*non-empty"
  )
})

test_that("add_transfer validates amount", {
  expect_error(
    new_transfer()$add_transfer(
      clientOid = "uuid-1",
      currency = "USDT",
      amount = "",
      type = "INTERNAL",
      fromAccountType = "MAIN",
      toAccountType = "TRADE"
    ),
    "amount.*non-empty"
  )
})

test_that("add_transfer validates type", {
  expect_error(
    new_transfer()$add_transfer(
      clientOid = "uuid-1",
      currency = "USDT",
      amount = "100",
      type = "INVALID",
      fromAccountType = "MAIN",
      toAccountType = "TRADE"
    ),
    "type.*INTERNAL"
  )
})

test_that("add_transfer validates fromAccountType", {
  expect_error(
    new_transfer()$add_transfer(
      clientOid = "uuid-1",
      currency = "USDT",
      amount = "100",
      type = "INTERNAL",
      fromAccountType = "INVALID",
      toAccountType = "TRADE"
    ),
    "fromAccountType.*MAIN"
  )
})

test_that("add_transfer validates toAccountType", {
  expect_error(
    new_transfer()$add_transfer(
      clientOid = "uuid-1",
      currency = "USDT",
      amount = "100",
      type = "INTERNAL",
      fromAccountType = "MAIN",
      toAccountType = "INVALID"
    ),
    "toAccountType.*MAIN"
  )
})

test_that("add_transfer includes optional sub-account parameters", {
  resp <- mock_kucoin_response(data = list(orderId = "transfer-sub-001"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$add_transfer(
    clientOid = "uuid-2",
    currency = "BTC",
    amount = "0.01",
    type = "PARENT_TO_SUB",
    fromAccountType = "MAIN",
    toAccountType = "MAIN",
    toUserId = "sub-user-id-123"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_id, "transfer-sub-001")
})

# -- get_transferable --

test_that("get_transferable returns data.table with balance breakdown", {
  resp <- mock_kucoin_response(
    data = list(
      currency = "USDT",
      balance = "10.5",
      available = "10.5",
      holds = "0",
      transferable = "10.5"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$get_transferable(currency = "USDT", type = "MAIN")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$currency, "USDT")
  expect_equal(dt$balance, "10.5")
  expect_equal(dt$available, "10.5")
  expect_equal(dt$holds, "0")
  expect_equal(dt$transferable, "10.5")
  # Check column ordering
  expect_equal(names(dt)[1], "currency")
  # No list columns
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})

test_that("get_transferable validates currency", {
  expect_error(
    new_transfer()$get_transferable(currency = "", type = "MAIN"),
    "currency.*non-empty"
  )
})

test_that("get_transferable validates type", {
  expect_error(
    new_transfer()$get_transferable(currency = "USDT", type = "INVALID"),
    "type.*MAIN"
  )
})

test_that("get_transferable works with TRADE account type", {
  resp <- mock_kucoin_response(
    data = list(
      currency = "BTC",
      balance = "0.05",
      available = "0.03",
      holds = "0.02",
      transferable = "0.03"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_transfer()$get_transferable(currency = "BTC", type = "TRADE")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$currency, "BTC")
  expect_equal(dt$holds, "0.02")
})
