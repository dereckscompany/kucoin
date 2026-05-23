# tests/testthat/test-KucoinStopOrders.R
# Tests for KucoinStopOrders R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_stop <- function() {
  KucoinStopOrders$new(keys = KEYS, base_url = BASE)
}

expect_no_list_cols <- function(dt) {
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L, info = paste("unexpected list columns:", paste(list_cols, collapse = ", ")))
}

# -- Construction --

test_that("KucoinStopOrders inherits from KucoinBase", {
  s <- new_stop()
  expect_s3_class(s, "KucoinStopOrders")
  expect_s3_class(s, "KucoinBase")
})

# -- add_order --

test_that("add_order limit returns order_id with client_oid column", {
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
  expect_true("client_oid" %in% names(dt))
  expect_equal(names(dt)[1], "order_id")
  expect_no_list_cols(dt)
})

test_that("add_order injects NA client_oid when API omits it", {
  resp <- mock_kucoin_response(data = list(orderId = "vs8hoo8q2ceshiue003b67c0"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$add_order(
    type = "limit",
    symbol = "BTC-USDT",
    side = "sell",
    stopPrice = "90000",
    price = "89500",
    size = "0.00001"
  )
  expect_true("client_oid" %in% names(dt))
  expect_true(is.na(dt$client_oid))
  expect_no_list_cols(dt)
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
  expect_no_list_cols(dt)
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
  expect_no_list_cols(dt)
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

test_that("cancel_order_by_id returns one row per cancelled id (Treatment B)", {
  resp <- mock_kucoin_response(data = list(cancelledOrderIds = list("vs8hoo8q2ceshiue003b67c0")))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_order_by_id("vs8hoo8q2ceshiue003b67c0")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("cancelled_order_id" %in% names(dt))
  expect_false("cancelled_order_ids" %in% names(dt))
  expect_equal(dt$cancelled_order_id, "vs8hoo8q2ceshiue003b67c0")
  expect_no_list_cols(dt)
})

test_that("cancel_order_by_id explodes multi-id payload to long format", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderIds = list("id1", "id2", "id3")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_order_by_id("id1")
  expect_equal(nrow(dt), 3L)
  expect_equal(dt$cancelled_order_id, c("id1", "id2", "id3"))
  expect_no_list_cols(dt)
})

test_that("cancel_order_by_id returns empty data.table on empty array", {
  resp <- mock_kucoin_response(data = list(cancelledOrderIds = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_order_by_id("xyz")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- cancel_order_by_client_oid --

test_that("cancel_order_by_client_oid returns single-row data.table", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderId = "vs8hoo8q2ceshiue003b67c0",
      clientOid = "my-stop-001"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_order_by_client_oid("my-stop-001", symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$client_oid, "my-stop-001")
  expect_equal(dt$cancelled_order_id, "vs8hoo8q2ceshiue003b67c0")
  expect_equal(names(dt)[1], "cancelled_order_id")
  expect_no_list_cols(dt)
})

# -- cancel_all --

test_that("cancel_all returns one row per cancelled id (Treatment B)", {
  resp <- mock_kucoin_response(
    data = list(
      cancelledOrderIds = list("id1", "id2", "id3")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_all(query = list(symbol = "BTC-USDT"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("cancelled_order_id" %in% names(dt))
  expect_false("cancelled_order_ids" %in% names(dt))
  expect_equal(dt$cancelled_order_id, c("id1", "id2", "id3"))
  expect_no_list_cols(dt)
})

test_that("cancel_all returns empty data.table when no matches", {
  resp <- mock_kucoin_response(data = list(cancelledOrderIds = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$cancel_all()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_order_by_id --

test_that("get_order_by_id returns data.table with created_at as POSIXct", {
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
  expect_no_list_cols(dt)
})

test_that("get_order_by_id converts order_time (ns) and stop_trigger_time (ms) to POSIXct", {
  resp <- mock_kucoin_response(
    data = list(
      id = "vs8hoo8q2ceshiue003b67c0",
      symbol = "BTC-USDT",
      type = "limit",
      side = "sell",
      stopPrice = "90000",
      createdAt = 1706789012000,
      orderTime = 1706789012345678900,
      stopTriggerTime = 1706789999000
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_by_id("vs8hoo8q2ceshiue003b67c0")
  expect_s3_class(dt$created_at, "POSIXct")
  expect_s3_class(dt$order_time, "POSIXct")
  expect_s3_class(dt$stop_trigger_time, "POSIXct")
  expect_no_list_cols(dt)
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
  expect_s3_class(dt$created_at, "POSIXct")
  expect_equal(dt$client_oid, "my-stop-001")
  expect_no_list_cols(dt)
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
  expect_s3_class(dt$created_at, "POSIXct")
  expect_no_list_cols(dt)
})

test_that("get_order_by_client_oid returns empty data.table on null payload", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_by_client_oid("missing", symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_order_list --

test_that("get_order_list returns orders with timestamp columns as POSIXct", {
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
          createdAt = 1706789012000,
          orderTime = 1706789012345678900
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
  expect_s3_class(dt$created_at, "POSIXct")
  expect_s3_class(dt$order_time, "POSIXct")
  expect_equal(names(dt)[1], "id")
  expect_no_list_cols(dt)
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

test_that("get_order_list produces one row per order across multi-item payload", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 50,
      totalNum = 2,
      totalPage = 1,
      items = list(
        list(
          id = "id-1",
          symbol = "BTC-USDT",
          type = "limit",
          side = "sell",
          stopPrice = "90000",
          createdAt = 1706789012000
        ),
        list(
          id = "id-2",
          symbol = "ETH-USDT",
          type = "market",
          side = "buy",
          stopPrice = "3000",
          createdAt = 1706789013000
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_stop()$get_order_list()
  expect_equal(nrow(dt), 2L)
  expect_equal(dt$id, c("id-1", "id-2"))
  expect_equal(dt$symbol, c("BTC-USDT", "ETH-USDT"))
  expect_no_list_cols(dt)
})
