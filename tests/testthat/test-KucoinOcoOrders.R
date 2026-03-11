# tests/testthat/test-KucoinOcoOrders.R
# Tests for KucoinOcoOrders R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_oco <- function() {
  KucoinOcoOrders$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinOcoOrders inherits from KucoinBase", {
  o <- new_oco()
  expect_s3_class(o, "KucoinOcoOrders")
  expect_s3_class(o, "KucoinBase")
})

# -- add_order --

test_that("add_order returns order_id", {
  resp <- mock_kucoin_response(data = list(orderId = "674c40d38b4b2f00073deef3"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$add_order(
    symbol = "BTC-USDT",
    side = "sell",
    price = "110000",
    size = "0.0001",
    stopPrice = "90000",
    limitPrice = "89500"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_id, "674c40d38b4b2f00073deef3")
  expect_equal(names(dt)[1], "order_id")
})

test_that("add_order validates symbol", {
  expect_error(
    new_oco()$add_order(
      symbol = "INVALID",
      side = "sell",
      price = "110000",
      size = "0.0001",
      stopPrice = "90000",
      limitPrice = "89500"
    ),
    "valid ticker"
  )
})

# -- cancel_order_by_id --

test_that("cancel_order_by_id returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderIds = list("674c40d38b4b2f00073deef3", "674c40d38b4b2f00073deef4")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$cancel_order_by_id("674c40d38b4b2f00073deef3")
  expect_s3_class(dt, "data.table")
})

# -- cancel_order_by_client_oid --

test_that("cancel_order_by_client_oid returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderIds = list("674c40d38b4b2f00073deef3", "674c40d38b4b2f00073deef4")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$cancel_order_by_client_oid("my-bot-oco-001")
  expect_s3_class(dt, "data.table")
})

# -- cancel_all --

test_that("cancel_all returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderIds = list("id1", "id2", "id3", "id4")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$cancel_all(query = list(symbol = "BTC-USDT"))
  expect_s3_class(dt, "data.table")
})

# -- get_order_by_id --

test_that("get_order_by_id returns data.table with order_time and column reorder", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "674c40d38b4b2f00073deef3",
      symbol = "BTC-USDT",
      clientOid = "my-bot-oco-001",
      orderTime = 1729176273859,
      status = "NEW"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_order_by_id("674c40d38b4b2f00073deef3")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("order_time" %in% names(dt))
  expect_false("datetime_order" %in% names(dt))
  expect_s3_class(dt$order_time, "POSIXct")
  expect_equal(dt$status, "NEW")
  # Check column ordering
  expect_equal(names(dt)[1], "order_id")
})

# -- get_order_by_client_oid --

test_that("get_order_by_client_oid returns data.table with order_time", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "674c40d38b4b2f00073deef3",
      symbol = "BTC-USDT",
      clientOid = "my-bot-oco-001",
      orderTime = 1729176273859,
      status = "NEW"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_order_by_client_oid("my-bot-oco-001")
  expect_s3_class(dt, "data.table")
  expect_true("order_time" %in% names(dt))
  expect_equal(dt$order_id, "674c40d38b4b2f00073deef3")
})

# -- get_order_detail_by_id --

test_that("get_order_detail_by_id returns data.table with orders list-column", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "674c40d38b4b2f00073deef3",
      symbol = "BTC-USDT",
      clientOid = "my-bot-oco-001",
      orderTime = 1729176273859,
      status = "NEW",
      orders = list(
        list(
          id = "674c40d38b4b2f00073deef4",
          symbol = "BTC-USDT",
          side = "sell",
          price = "110000",
          size = "0.0001",
          status = "NEW"
        ),
        list(
          id = "674c40d38b4b2f00073deef5",
          symbol = "BTC-USDT",
          side = "sell",
          price = "89500",
          stopPrice = "90000",
          size = "0.0001",
          status = "NEW"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_order_detail_by_id("674c40d38b4b2f00073deef3")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("order_time" %in% names(dt))
  expect_true("orders" %in% names(dt))
  expect_equal(dt$status, "NEW")
})

# -- get_order_list --

test_that("get_order_list returns orders with order_time and column reorder", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 20,
      totalNum = 2,
      totalPage = 1,
      items = list(
        list(
          orderId = "674c40d38b4b2f00073deef3",
          symbol = "BTC-USDT",
          clientOid = "oco-001",
          orderTime = 1729176273859,
          status = "NEW"
        ),
        list(
          orderId = "674c40d38b4b2f00073deef6",
          symbol = "ETH-USDT",
          clientOid = "oco-002",
          orderTime = 1729176274000,
          status = "TRIGGERED"
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_order_list()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("order_time" %in% names(dt))
  expect_false("datetime_order" %in% names(dt))
  expect_equal(names(dt)[1], "order_id")
})

test_that("get_order_list handles empty items", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 20,
      totalNum = 0,
      totalPage = 1,
      items = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_oco()$get_order_list()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
