# tests/testthat/test-KucoinMarginTrading.R
# Tests for KucoinMarginTrading R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_margin <- function() {
  KucoinMarginTrading$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinMarginTrading inherits from KucoinBase", {
  m <- new_margin()
  expect_s3_class(m, "KucoinMarginTrading")
  expect_s3_class(m, "KucoinBase")
})

# -- open_short --

test_that("open_short returns order_id and client_oid", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "margin-short-001",
      clientOid = "my-short",
      borrowSize = "0.001",
      loanApplyId = "loan-001"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$open_short(symbol = "BTC-USDT", size = 0.001)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(names(dt)[1:2], c("order_id", "client_oid"))
  expect_equal(dt$order_id, "margin-short-001")
  expect_equal(dt$borrow_size, "0.001")
})

test_that("open_short hits margin order endpoint with sell side and autoBorrow", {
  captured_url <- NULL
  captured_body <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "o1"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    captured_body <<- jsonlite::fromJSON(req$body$data)
    resp
  })

  new_margin()$open_short(symbol = "BTC-USDT", size = 0.001)
  expect_true(grepl("hf/margin/order", captured_url))
  expect_false(grepl("test", captured_url))
  expect_equal(captured_body$side, "sell")
  expect_true(captured_body$autoBorrow)
  expect_null(captured_body$autoRepay)
})

test_that("open_short sets client_oid to NA when missing", {
  resp <- mock_kucoin_response(data = list(orderId = "abc"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$open_short(symbol = "BTC-USDT", size = 0.001)
  expect_true(is.na(dt$client_oid))
})

# -- close_short --

test_that("close_short uses buy side and autoRepay", {
  captured_body <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "o2"))
  httr2::local_mocked_responses(function(req) {
    captured_body <<- jsonlite::fromJSON(req$body$data)
    resp
  })

  new_margin()$close_short(symbol = "BTC-USDT", size = 0.001)
  expect_equal(captured_body$side, "buy")
  expect_true(captured_body$autoRepay)
  expect_null(captured_body$autoBorrow)
})

# -- open_long --

test_that("open_long uses buy side and autoBorrow", {
  captured_body <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "o3"))
  httr2::local_mocked_responses(function(req) {
    captured_body <<- jsonlite::fromJSON(req$body$data)
    resp
  })

  new_margin()$open_long(symbol = "BTC-USDT", size = 0.001)
  expect_equal(captured_body$side, "buy")
  expect_true(captured_body$autoBorrow)
  expect_null(captured_body$autoRepay)
})

# -- close_long --

test_that("close_long uses sell side and autoRepay", {
  captured_body <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "o4"))
  httr2::local_mocked_responses(function(req) {
    captured_body <<- jsonlite::fromJSON(req$body$data)
    resp
  })

  new_margin()$close_long(symbol = "BTC-USDT", size = 0.001)
  expect_equal(captured_body$side, "sell")
  expect_true(captured_body$autoRepay)
  expect_null(captured_body$autoBorrow)
})

# -- dry_run --

test_that("dry_run hits test endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "test-o1"))
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  dt <- new_margin()$open_short(symbol = "BTC-USDT", size = 0.001, dry_run = TRUE)
  expect_true(grepl("order/test", captured_url))
  expect_equal(dt$order_id, "test-o1")
})

# -- isolated margin --

test_that("isIsolated flag is passed when TRUE", {
  captured_body <- NULL
  resp <- mock_kucoin_response(data = list(orderId = "iso-1"))
  httr2::local_mocked_responses(function(req) {
    captured_body <<- jsonlite::fromJSON(req$body$data)
    resp
  })

  new_margin()$open_short(symbol = "BTC-USDT", size = 0.001, isIsolated = TRUE)
  expect_true(captured_body$isIsolated)
})

# -- borrow --

test_that("borrow returns order_no and actual_size", {
  resp <- mock_kucoin_response(data = list(orderNo = "borrow-001", actualSize = "100"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$borrow(currency = "USDT", size = 100)
  expect_s3_class(dt, "data.table")
  expect_equal(dt$order_no, "borrow-001")
  expect_equal(dt$actual_size, "100")
})

test_that("borrow validates parameters", {
  expect_error(new_margin()$borrow(currency = "", size = 100), "non-empty")
  expect_error(new_margin()$borrow(currency = "USDT", size = -1), "positive")
  expect_error(
    new_margin()$borrow(currency = "BTC", size = 0.01, isIsolated = TRUE, symbol = "INVALID"),
    "valid ticker"
  )
})

# -- repay --

test_that("repay returns order_no and actual_size", {
  resp <- mock_kucoin_response(data = list(orderNo = "repay-001", actualSize = "100"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$repay(currency = "USDT", size = 100)
  expect_equal(dt$order_no, "repay-001")
})

test_that("repay validates parameters", {
  expect_error(new_margin()$repay(currency = "", size = 100), "non-empty")
  expect_error(new_margin()$repay(currency = "USDT", size = 0), "positive")
})

# -- get_borrow_history --

test_that("get_borrow_history returns data.table with created_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(orderNo = "b1", currency = "USDT", size = "100", createdTime = 1729655606816),
        list(orderNo = "b2", currency = "BTC", size = "0.01", createdTime = 1729655706816)
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_borrow_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("created_time" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
})

test_that("get_borrow_history returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_borrow_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_repay_history --

test_that("get_repay_history returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(orderNo = "r1", currency = "USDT", size = "100", createdTime = 1729655606816)
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_repay_history()
  expect_equal(nrow(dt), 1L)
  expect_true("created_time" %in% names(dt))
})

# -- get_interest_history --

test_that("get_interest_history returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(currency = "USDT", interest = "0.42", createdTime = 1729655606816)
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_history()
  expect_equal(nrow(dt), 1L)
  expect_true("created_time" %in% names(dt))
})

# -- get_borrow_rate --

test_that("get_borrow_rate returns data.table", {
  resp <- mock_kucoin_response(
    data = list(
      list(currency = "BTC", hourlyBorrowRate = "0.000012", annualizedBorrowRate = "0.1051"),
      list(currency = "USDT", hourlyBorrowRate = "0.000008", annualizedBorrowRate = "0.0701")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_borrow_rate()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("currency" %in% names(dt))
})

# -- modify_leverage --

test_that("modify_leverage sends correct leverage value", {
  captured_body <- NULL
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) {
    captured_body <<- jsonlite::fromJSON(req$body$data)
    resp
  })

  dt <- new_margin()$modify_leverage(leverage = 5)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$leverage, 5)
  expect_equal(dt$status, "success")
  expect_equal(captured_body$leverage, "5")
})

test_that("modify_leverage validates leverage", {
  expect_error(new_margin()$modify_leverage(leverage = -1), "positive")
  expect_error(new_margin()$modify_leverage(leverage = "abc"), "positive")
})

# -- Data-shape regression: no list columns, schema stability --
#
# Cross-package convention is "one entity = one row, no list columns".

test_that("open_short returns no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      orderId = "o1",
      clientOid = "c1",
      borrowSize = "0.001",
      loanApplyId = "loan-1"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$open_short(symbol = "BTC-USDT", size = 0.001)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$order_id))
  expect_true(is.character(dt$client_oid))
  expect_true(is.character(dt$borrow_size))
  expect_true(is.character(dt$loan_apply_id))
})

test_that("close_long returns no list columns", {
  resp <- mock_kucoin_response(data = list(orderId = "o4", clientOid = "c4"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$close_long(symbol = "BTC-USDT", size = 0.001)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$order_id))
  expect_true(is.character(dt$client_oid))
})

test_that("borrow returns no list columns", {
  resp <- mock_kucoin_response(data = list(orderNo = "b1", actualSize = "100"))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$borrow(currency = "USDT", size = 100)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$order_no))
  expect_true(is.character(dt$actual_size))
})

test_that("repay coerces timestamp to POSIXct with no list columns", {
  resp <- mock_kucoin_response(
    data = list(timestamp = 1729655606816, orderNo = "r1", actualSize = "100")
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$repay(currency = "USDT", size = 100)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_s3_class(dt$timestamp, "POSIXct")
  expect_true(is.character(dt$order_no))
  expect_true(is.character(dt$actual_size))
})

test_that("get_borrow_history schema: no list columns, POSIXct created_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          orderNo = "b1",
          symbol = "BTC-USDT",
          currency = "USDT",
          size = "100",
          actualSize = "100",
          status = "DONE",
          createdTime = 1729655606816
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_borrow_history()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_s3_class(dt$created_time, "POSIXct")
  expect_true(is.character(dt$order_no))
  expect_true(is.character(dt$currency))
})

test_that("get_repay_history schema: no list columns, POSIXct created_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          orderNo = "r1",
          symbol = "BTC-USDT",
          currency = "USDT",
          size = "100",
          actualSize = "100",
          status = "DONE",
          createdTime = 1729655606816
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_repay_history()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_s3_class(dt$created_time, "POSIXct")
})

test_that("get_interest_history schema: no list columns, POSIXct created_time", {
  resp <- mock_kucoin_response(
    data = list(
      items = list(
        list(
          currency = "USDT",
          dayRatio = "0.0001",
          interestAmount = "0.01",
          createdTime = 1729655606816
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_history()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_s3_class(dt$created_time, "POSIXct")
  expect_true(is.character(dt$currency))
})

test_that("get_borrow_rate schema: no list columns", {
  resp <- mock_kucoin_response(
    data = list(
      list(currency = "BTC", hourlyBorrowRate = "0.000004", annualizedBorrowRate = "0.035"),
      list(currency = "USDT", hourlyBorrowRate = "0.000006", annualizedBorrowRate = "0.0526")
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_borrow_rate()
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
  expect_true(is.character(dt$currency))
  expect_true(is.character(dt$hourly_borrow_rate))
  expect_true(is.character(dt$annualized_borrow_rate))
})

test_that("get_borrow_rate returns empty data.table for empty response", {
  resp <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_borrow_rate()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_interest_history returns empty data.table for empty items", {
  resp <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_interest_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("get_repay_history returns empty data.table for empty items", {
  resp <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$get_repay_history()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("modify_leverage returns no list columns", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_margin()$modify_leverage(leverage = 5)
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1))]), 0L)
})
