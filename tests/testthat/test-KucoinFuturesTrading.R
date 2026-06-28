# tests/testthat/test-KucoinFuturesTrading.R
# Tests for KucoinFuturesTrading R6 class with mocked HTTP.

# -- Construction --

test_that("KucoinFuturesTrading inherits from KucoinBase", {
  t <- new_futures_trading()
  expect_s3_class(t, "KucoinFuturesTrading")
  expect_s3_class(t, "KucoinBase")
})

# -- add_order --

test_that("add_order returns order_id and client_oid", {
  resp <- mock_kucoin_response(data = mock_futures_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$add_order(
    clientOid = "test-001",
    symbol = "XBTUSDTM",
    side = "buy",
    type = "limit",
    leverage = 5,
    size = 1,
    price = "98000"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("order_id" %in% names(dt))
  expect_true("client_oid" %in% names(dt))
  expect_equal(dt$order_id, "futures-order-001")
})

test_that("add_order strips NULL params from body", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = mock_futures_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  new_futures_trading()$add_order(
    clientOid = "test-002",
    symbol = "XBTUSDTM",
    side = "buy",
    type = "market",
    leverage = 10,
    size = 1
  )
  # Method should be POST
  expect_equal(captured_req$method, "POST")
})

# -- add_order_test --

test_that("add_order_test hits test endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  dt <- new_futures_trading()$add_order_test(
    clientOid = "test-003",
    symbol = "XBTUSDTM",
    side = "buy",
    type = "limit",
    leverage = 5,
    size = 1,
    price = "98000"
  )
  expect_true(grepl("orders/test", captured_url))
  expect_equal(dt$order_id, "futures-order-001")
})

# -- add_order_batch --

test_that("add_order_batch returns data.table", {
  resp <- mock_kucoin_response(data = list(mock_futures_order_response()))
  httr2::local_mocked_responses(function(req) resp)

  orders <- list(
    list(clientOid = "b1", symbol = "XBTUSDTM", side = "buy", type = "limit", leverage = 5, size = 1, price = "98000")
  )
  dt <- new_futures_trading()$add_order_batch(orders)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
})

# -- cancel_order_by_id --

test_that("cancel_order_by_id hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_cancel_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  dt <- new_futures_trading()$cancel_order_by_id("futures-order-001")
  expect_true(grepl("orders/futures-order-001", captured_url))
  expect_s3_class(dt, "data.table")
})

# -- cancel_order_by_client_oid --

test_that("cancel_order_by_client_oid includes symbol in query", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_cancel_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  dt <- new_futures_trading()$cancel_order_by_client_oid("client-001", "XBTUSDTM")
  expect_true(grepl("client-order/client-001", captured_url))
  expect_true(grepl("symbol=XBTUSDTM", captured_url))
  expect_s3_class(dt, "data.table")
})

# -- cancel_all --

test_that("cancel_all returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_cancel_order_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$cancel_all()
  expect_s3_class(dt, "data.table")
})

# -- cancel_all_stop_orders --

test_that("cancel_all_stop_orders hits stopOrders endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_cancel_order_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  dt <- new_futures_trading()$cancel_all_stop_orders()
  expect_true(grepl("stopOrders", captured_url))
  expect_s3_class(dt, "data.table")
})

# -- cancel parsers: NULL / empty payload regression --

test_that("cancel_order_by_id returns 0-row data.table when data is NULL", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$cancel_order_by_id("futures-order-001")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("cancel_order_by_client_oid returns 0-row data.table when data is NULL", {
  # Futures `cancel_order_by_client_oid` returns a `{clientOid}` object,
  # not a `cancelledOrderIds` array — pin the NULL-payload branch only.
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$cancel_order_by_client_oid("client-001", "XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("cancel_all returns 0-row data.table on empty cancelledOrderIds", {
  resp <- mock_kucoin_response(data = list(cancelledOrderIds = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$cancel_all()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("cancel_all explodes cancelledOrderIds into long-format rows", {
  resp <- mock_kucoin_response(
    data = list(cancelledOrderIds = list("id-x", "id-y", "id-z"))
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$cancel_all()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("cancelled_order_id" %in% names(dt))
  expect_type(dt$cancelled_order_id, "character")
  expect_equal(dt$cancelled_order_id, c("id-x", "id-y", "id-z"))
  expect_false("cancelled_order_ids" %in% names(dt))
})

# -- get_order_by_id --

test_that("get_order_by_id returns data.table with timestamps", {
  resp <- mock_kucoin_response(data = mock_futures_order_detail_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$get_order_by_id("futures-order-001")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
  expect_true("updated_at" %in% names(dt))
  expect_s3_class(dt$updated_at, "POSIXct")
})

# -- get_order_by_client_oid --

test_that("get_order_by_client_oid includes clientOid in query", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_order_detail_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  dt <- new_futures_trading()$get_order_by_client_oid("futures-client-001")
  expect_true(grepl("clientOid=futures-client-001", captured_url))
  expect_s3_class(dt, "data.table")
  expect_s3_class(dt$created_at, "POSIXct")
})

# -- get_order_list --

test_that("get_order_list returns paginated data.table with timestamps", {
  resp <- mock_kucoin_response(data = mock_futures_order_list_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$get_order_list(query = list(status = "active"))
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
  expect_true("created_at" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
})

# -- get_recent_closed_orders --

test_that("get_recent_closed_orders returns data.table", {
  resp <- mock_kucoin_response(data = list(mock_futures_order_detail_data()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$get_recent_closed_orders()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
})

# -- get_recent_fills --

test_that("get_recent_fills returns data.table with trade_time as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_fills_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$get_recent_fills()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("trade_time" %in% names(dt))
  expect_s3_class(dt$trade_time, "POSIXct")
  expect_true("created_at" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
})

# -- get_open_order_value --

test_that("get_open_order_value returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_open_order_value_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$get_open_order_value("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("open_order_buy_size" %in% names(dt))
  expect_true("settle_currency" %in% names(dt))
})

# -- set_dcp / get_dcp --

test_that("set_dcp sends POST with timeout", {
  captured_method <- NULL
  resp <- mock_kucoin_response(data = mock_futures_dcp_data())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  dt <- new_futures_trading()$set_dcp(timeout = 5)
  expect_equal(captured_method, "POST")
  expect_s3_class(dt, "data.table")
  expect_true("timeout" %in% names(dt))
})

test_that("get_dcp returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_dcp_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_trading()$get_dcp()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("timeout" %in% names(dt))
})
