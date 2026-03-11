# tests/testthat/test-KucoinStopOrders.R
# Tests for KucoinStopOrders R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_stop <- function() {
  KucoinStopOrders$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinStopOrders inherits from KucoinBase", {
  s <- new_stop()
  expect_s3_class(s, "KucoinStopOrders")
  expect_s3_class(s, "KucoinBase")
})

# -- add_order --

test_that("add_order limit returns order_id", {
  resp <- mock_kucoin_response(data = list(orderId = "vs8hoo8q2ceshiue003b67c0", clientOid = NA))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$add_order(
    type = "limit",
    symbol = "BTC-USDT",
    side = "sell",
    stopPrice = "90000",
    price = "89500",
    size = "0.00001"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_id, "vs8hoo8q2ceshiue003b67c0")
})

test_that("add_order market by size works", {
  resp <- mock_kucoin_response(data = list(orderId = "mkt1"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$add_order(
    type = "market",
    symbol = "BTC-USDT",
    side = "sell",
    stopPrice = "90000",
    size = "0.00001"
  )
  expect_equal(dt$order_id, "mkt1")
})

test_that("add_order market by funds works", {
  resp <- mock_kucoin_response(data = list(orderId = "mkt2"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$add_order(
    type = "market",
    symbol = "BTC-USDT",
    side = "buy",
    stopPrice = "105000",
    funds = "100"
  )
  expect_equal(dt$order_id, "mkt2")
})

test_that("add_order validates type-specific constraints", {
  # limit without price
  expect_error(
    new_stop()$add_order(
      type = "limit",
      symbol = "BTC-USDT",
      side = "buy",
      stopPrice = "90000",
      size = "0.1"
    ),
    "price.*required"
  )

  # limit without size
  expect_error(
    new_stop()$add_order(
      type = "limit",
      symbol = "BTC-USDT",
      side = "buy",
      stopPrice = "90000",
      price = "89500"
    ),
    "size.*required"
  )

  # market with price
  expect_error(
    new_stop()$add_order(
      type = "market",
      symbol = "BTC-USDT",
      side = "buy",
      stopPrice = "90000",
      price = "89500",
      size = "0.1"
    ),
    "price.*not applicable"
  )

  # market without size or funds
  expect_error(
    new_stop()$add_order(
      type = "market",
      symbol = "BTC-USDT",
      side = "buy",
      stopPrice = "90000"
    ),
    "size.*funds"
  )

  # market with both size and funds
  expect_error(
    new_stop()$add_order(
      type = "market",
      symbol = "BTC-USDT",
      side = "buy",
      stopPrice = "90000",
      size = "0.1",
      funds = "100"
    ),
    "mutually exclusive"
  )

  # invalid symbol
  expect_error(
    new_stop()$add_order(
      type = "limit",
      symbol = "INVALID",
      side = "buy",
      stopPrice = "90000",
      price = "89500",
      size = "0.1"
    ),
    "valid ticker"
  )
})

# -- cancel_order_by_id --

test_that("cancel_order_by_id returns data.table", {
  resp <- mock_kucoin_response(data = list(cancelledOrderIds = list("vs8hoo8q2ceshiue003b67c0")))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_order_by_id("vs8hoo8q2ceshiue003b67c0")
  expect_s3_class(dt, "data.table")
})

# -- cancel_order_by_client_oid --

test_that("cancel_order_by_client_oid returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderId = "vs8hoo8q2ceshiue003b67c0",
      clientOid = "my-stop-001"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_order_by_client_oid("my-stop-001", symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$client_oid, "my-stop-001")
})

# -- cancel_all --

test_that("cancel_all returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderIds = list("id1", "id2", "id3")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_all(query = list(symbol = "BTC-USDT"))
  expect_s3_class(dt, "data.table")
})

# -- get_order_by_id --

test_that("get_order_by_id returns data.table with created_at", {
  resp <- mock_kucoin_response(
    data = list(
      id = "vs8hoo8q2ceshiue003b67c0",
      symbol = "BTC-USDT",
      type = "limit",
      side = "sell",
      price = "89500",
      size = "0.00001",
      stopPrice = "90000",
      stop = "loss",
      createdAt = 1706789012000
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_by_id("vs8hoo8q2ceshiue003b67c0")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
  expect_equal(dt$symbol, "BTC-USDT")
})

# -- get_order_by_client_oid --

test_that("get_order_by_client_oid handles array response", {
  resp <- mock_kucoin_response(
    data = list(
      list(
        id = "vs8hoo8q2ceshiue003b67c0",
        symbol = "BTC-USDT",
        clientOid = "my-stop-001",
        createdAt = 1706789012000
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_by_client_oid("my-stop-001", symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_equal(dt$client_oid, "my-stop-001")
})

test_that("get_order_by_client_oid handles single object response", {
  resp <- mock_kucoin_response(
    data = list(
      id = "vs8hoo8q2ceshiue003b67c0",
      symbol = "BTC-USDT",
      clientOid = "my-stop-001",
      createdAt = 1706789012000
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_by_client_oid("my-stop-001", symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

# -- get_order_list --

test_that("get_order_list returns orders with created_at", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 50,
      totalNum = 1,
      totalPage = 1,
      items = list(
        list(
          id = "vs8hoo8q2ceshiue003b67c0",
          symbol = "BTC-USDT",
          type = "limit",
          side = "sell",
          price = "89500",
          stopPrice = "90000",
          createdAt = 1706789012000
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_list(query = list(symbol = "BTC-USDT"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
})

test_that("get_order_list handles empty items", {
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

  dt <- new_stop()$get_order_list()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
