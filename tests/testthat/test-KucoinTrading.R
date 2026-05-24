# tests/testthat/test-KucoinTrading.R
# Tests for KucoinTrading R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_trading <- function() {
  return(KucoinTrading$new(keys = KEYS, base_url = BASE))
}

# -- Construction --

test_that("KucoinTrading inherits from KucoinBase", {
  t <- new_trading()
  expect_s3_class(t, "KucoinTrading")
  expect_s3_class(t, "KucoinBase")
})

# -- add_order --

test_that("add_order returns order_id and client_oid", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "670fd33bf9406e0007ab3945",
      clientOid = "5c52e11203aa677f33e493fb"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = "50000",
    size = "0.00001"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(names(dt)[1:2], c("order_id", "client_oid"))
  expect_equal(dt$order_id, "670fd33bf9406e0007ab3945")
})

test_that("add_order sets client_oid to NA when missing", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "abc123"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = "50000",
    size = "0.00001"
  )
  expect_true(is.na(dt$client_oid))
})

# -- add_order_test --

test_that("add_order_test hits test endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "test123", clientOid = "c1"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  dt <- new_trading()$add_order_test(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = "50000",
    size = "0.00001"
  )
  expect_true(grepl("orders/test", captured_url))
  expect_equal(dt$order_id, "test123")
})

# -- add_order_batch --

test_that("add_order_batch returns per-order results", {
  resp <- mock_kucoin_response(
    data = list(
      list(orderId = "o1", clientOid = "c1", success = TRUE),
      list(success = FALSE, failMsg = "Insufficient balance")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order_batch(list(
    list(type = "limit", symbol = "BTC-USDT", side = "buy", price = "50000", size = "0.00001"),
    list(type = "limit", symbol = "BTC-USDT", side = "buy", price = "100", size = "0.00001")
  ))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("success" %in% names(dt))
})

test_that("add_order_batch rejects empty or oversized lists", {
  expect_error(new_trading()$add_order_batch(list()), "1 to 20")
  expect_error(
    new_trading()$add_order_batch(as.list(seq_len(21))),
    "1 to 20"
  )
})

# -- cancel_order_by_id --

test_that("cancel_order_by_id returns cancelled order_id", {
  resp <- mock_kucoin_response(data = list(orderId = "671124f9365ccb00073debd4"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order_by_id("671124f9365ccb00073debd4", "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_id, "671124f9365ccb00073debd4")
})

test_that("cancel_order_by_id validates parameters", {
  expect_error(new_trading()$cancel_order_by_id("", "BTC-USDT"), "non-empty")
  expect_error(new_trading()$cancel_order_by_id("abc", "INVALID"), "valid ticker")
})

# -- cancel_order_by_client_oid --

test_that("cancel_order_by_client_oid returns cancelled client_oid", {
  resp <- mock_kucoin_response(data = list(clientOid = "myOid123"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order_by_client_oid("myOid123", "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$client_oid, "myOid123")
})

# -- cancel_partial_order --

test_that("cancel_partial_order returns data.table", {
  resp <- mock_kucoin_response(data = list(orderId = "abc", cancelSize = "0.001"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_partial_order("abc", "BTC-USDT", cancelSize = 0.001)
  expect_s3_class(dt, "data.table")
})

# -- cancel_all_by_symbol --

test_that("cancel_all_by_symbol returns data.table", {
  resp <- mock_kucoin_response(data = "success")
  httr2::local_mocked_responses(function(req) resp)

  result <- new_trading()$cancel_all_by_symbol("BTC-USDT")
  expect_s3_class(result, "data.table")
  expect_true("result" %in% names(result))
})

test_that("cancel_all_by_symbol validates symbol", {
  expect_error(new_trading()$cancel_all_by_symbol("INVALID"), "valid ticker")
})

# -- cancel_all --

test_that("cancel_all returns data.table with succeed/failed symbols", {
  resp <- mock_kucoin_response(
    data = list(
      succeedSymbols = list("BTC-USDT", "ETH-USDT"),
      failedSymbols = list("DOGE-USDT")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_all()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_equal(dt[status == "succeed", symbol], c("BTC-USDT", "ETH-USDT"))
  expect_equal(dt[status == "failed", symbol], "DOGE-USDT")
})

test_that("cancel_all returns empty data.table for legacy 'success' response", {
  resp <- mock_kucoin_response(data = "success")
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_all()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_order_by_id --

test_that("get_order_by_id converts timestamps and returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "671124f9365ccb00073debd4",
      symbol = "BTC-USDT",
      side = "buy",
      type = "limit",
      price = "67717.6",
      size = "0.00001",
      createdAt = 1729577515473,
      lastUpdatedAt = 1729577515500
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order_by_id("671124f9365ccb00073debd4", "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_true("created_at" %in% names(dt))
  expect_true("last_updated_at" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
  expect_false("datetime_created" %in% names(dt))
  expect_false("datetime_updated" %in% names(dt))
})

# -- get_order_by_client_oid --

test_that("get_order_by_client_oid converts timestamps to created_at", {
  resp <- mock_kucoin_response(
    data = list(
      clientOid = "myOid",
      symbol = "BTC-USDT",
      side = "sell",
      createdAt = 1729577515473
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order_by_client_oid("myOid", "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_true("created_at" %in% names(dt))
})

# -- get_fills --

test_that("get_fills returns fills with created_at", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          id = 19814995255305,
          orderId = "6717422bd51c29000775ea03",
          symbol = "BTC-USDT",
          side = "buy",
          liquidity = "taker",
          price = "67717.6",
          size = "0.00001",
          fee = "0.000677176",
          feeCurrency = "USDT",
          createdAt = 1729577515473
        )
      ),
      lastId = 19814995255305
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_fills("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
  expect_true("fee" %in% names(dt))
})

test_that("get_fills returns empty data.table when no items", {
  resp <- mock_kucoin_response(data = list(items = list(), lastId = 0))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_fills("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_symbols_with_open_orders --

test_that("get_symbols_with_open_orders returns symbols data.table", {
  resp <- mock_kucoin_response(data = list(symbols = list("BTC-USDT", "ETH-USDT")))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_symbols_with_open_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("BTC-USDT", "ETH-USDT") %in% dt$symbols))
})

test_that("get_symbols_with_open_orders handles empty", {
  resp <- mock_kucoin_response(data = list(symbols = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_symbols_with_open_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_open_orders --

test_that("get_open_orders returns order list with timestamps", {
  resp <- mock_kucoin_response(
    data = list(
      list(orderId = "o1", symbol = "BTC-USDT", side = "buy", price = "67000", createdAt = 1729577515473),
      list(orderId = "o2", symbol = "BTC-USDT", side = "sell", price = "68000", createdAt = 1729577516000)
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_open_orders("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("created_at" %in% names(dt))
})

test_that("get_open_orders handles empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_open_orders("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_closed_orders --

test_that("get_closed_orders returns orders with timestamps", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(orderId = "c1", symbol = "BTC-USDT", side = "buy", createdAt = 1729577515473),
        list(orderId = "c2", symbol = "BTC-USDT", side = "sell", createdAt = 1729577516000)
      ),
      lastId = 12345
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_closed_orders("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("created_at" %in% names(dt))
})

# -- add_order_sync --

test_that("add_order_sync returns fill result with status", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "sync123",
      clientOid = "c1",
      orderTime = 1729577515473,
      originSize = "0.00001",
      dealSize = "0.00001",
      remainSize = "0",
      canceledSize = "0",
      status = "done",
      matchTime = 1729577515500
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order_sync(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = "50000",
    size = "0.00001"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_id, "sync123")
  expect_equal(dt$status, "done")
  expect_true("deal_size" %in% names(dt))
  expect_true("match_time" %in% names(dt))
})

test_that("add_order_sync hits sync endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(
    data = list(
      orderId = "s1",
      status = "done",
      originSize = "0.00001",
      dealSize = "0",
      remainSize = "0.00001",
      canceledSize = "0"
    )
  )
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_trading()$add_order_sync(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = "50000",
    size = "0.00001"
  )
  expect_true(grepl("orders/sync", captured_url))
  expect_false(grepl("orders/sync/", captured_url))
})

# -- add_order_batch_sync --

test_that("add_order_batch_sync returns per-order results", {
  resp <- mock_kucoin_response(
    data = list(
      list(orderId = "o1", success = TRUE, status = "done", dealSize = "0.00001", remainSize = "0", canceledSize = "0"),
      list(success = FALSE, failMsg = "Insufficient balance")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order_batch_sync(list(
    list(type = "limit", symbol = "BTC-USDT", side = "buy", price = "50000", size = "0.00001"),
    list(type = "limit", symbol = "BTC-USDT", side = "buy", price = "100", size = "0.00001")
  ))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("success" %in% names(dt))
})

test_that("add_order_batch_sync rejects empty or oversized lists", {
  expect_error(new_trading()$add_order_batch_sync(list()), "1 to 20")
  expect_error(new_trading()$add_order_batch_sync(as.list(seq_len(21))), "1 to 20")
})

# -- cancel_order_by_id_sync --

test_that("cancel_order_by_id_sync returns final order state", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "671128ee365ccb0007534d45",
      originSize = "0.00001",
      dealSize = "0",
      remainSize = "0",
      canceledSize = "0.00001",
      status = "done"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order_by_id_sync("671128ee365ccb0007534d45", "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_id, "671128ee365ccb0007534d45")
  expect_equal(dt$status, "done")
  expect_true("canceled_size" %in% names(dt))
})

test_that("cancel_order_by_id_sync validates parameters", {
  expect_error(new_trading()$cancel_order_by_id_sync("", "BTC-USDT"), "non-empty")
  expect_error(new_trading()$cancel_order_by_id_sync("abc", "INVALID"), "valid ticker")
})

# -- cancel_order_by_client_oid_sync --

test_that("cancel_order_by_client_oid_sync returns final order state", {
  resp <- mock_kucoin_response(
    data = list(
      clientOid = "myOid123",
      originSize = "0.00001",
      dealSize = "0",
      remainSize = "0",
      canceledSize = "0.00001",
      status = "done"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order_by_client_oid_sync("myOid123", "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$client_oid, "myOid123")
  expect_equal(dt$status, "done")
})

test_that("cancel_order_by_client_oid_sync validates parameters", {
  expect_error(new_trading()$cancel_order_by_client_oid_sync("", "BTC-USDT"), "non-empty")
  expect_error(new_trading()$cancel_order_by_client_oid_sync("abc", "INVALID"), "valid ticker")
})

# -- modify_order --

test_that("modify_order returns new order id", {
  resp <- mock_kucoin_response(
    data = list(
      newOrderId = "replacement-order-id",
      clientOid = "original-client-oid"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$modify_order(
    symbol = "BTC-USDT",
    orderId = "671124f9365ccb00073debd4",
    newPrice = "51000"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(dt$new_order_id, "replacement-order-id")
  expect_equal(dt$client_oid, "original-client-oid")
})

test_that("modify_order validates required parameters", {
  expect_error(new_trading()$modify_order("INVALID"), "valid ticker")
  expect_error(new_trading()$modify_order("BTC-USDT"), "orderId.*clientOid")
  expect_error(new_trading()$modify_order("BTC-USDT", orderId = "abc"), "newPrice.*newSize")
})

# -- set_dcp --

test_that("set_dcp returns current and trigger times", {
  resp <- mock_kucoin_response(
    data = list(
      currentTime = 1729656588,
      triggerTime = 1729656593
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$set_dcp(timeout = 30, symbols = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_equal(dt$current_time, 1729656588)
  expect_equal(dt$trigger_time, 1729656593)
})

test_that("set_dcp validates timeout", {
  expect_error(new_trading()$set_dcp(timeout = 3), "between 5 and 86400")
  expect_error(new_trading()$set_dcp(timeout = 100000), "between 5 and 86400")
})

test_that("set_dcp allows -1 to disable", {
  resp <- mock_kucoin_response(data = list(currentTime = 1729656588, triggerTime = 0))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$set_dcp(timeout = -1)
  expect_s3_class(dt, "data.table")
})

# -- get_dcp --

test_that("get_dcp returns settings", {
  resp <- mock_kucoin_response(
    data = list(
      timeout = 5,
      symbols = "BTC-USDT,ETH-USDT",
      currentTime = 1729241305,
      triggerTime = 1729241308
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_dcp()
  expect_s3_class(dt, "data.table")
  expect_equal(dt$timeout, 5)
  expect_equal(dt$symbols, "BTC-USDT,ETH-USDT")
})

test_that("get_dcp handles empty response (unconfigured)", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_dcp()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
