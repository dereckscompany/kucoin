# tests/testthat/test-KucoinFuturesAccount.R
# Tests for KucoinFuturesAccount R6 class with mocked HTTP.

# -- Construction --

test_that("KucoinFuturesAccount inherits from KucoinBase", {
  a <- new_futures_account()
  expect_s3_class(a, "KucoinFuturesAccount")
  expect_s3_class(a, "KucoinBase")
})

# -- get_account_overview --

test_that("get_account_overview returns data.table with balance fields", {
  resp <- mock_kucoin_response(data = mock_futures_account_overview_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_account_overview()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("account_equity" %in% names(dt))
  expect_true("available_balance" %in% names(dt))
  expect_true("currency" %in% names(dt))
  expect_equal(dt$currency, "USDT")
})

test_that("get_account_overview passes currency query param", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_account_overview_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures_account()$get_account_overview(currency = "XBT")
  expect_true(grepl("currency=XBT", captured_url))
})

# -- get_position --

test_that("get_position returns data.table with timestamps", {
  # get_position returns a single position object (not an array)
  resp <- mock_kucoin_response(data = mock_futures_position_data()[[1]])
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_position("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
  expect_true("opening_timestamp" %in% names(dt))
  expect_s3_class(dt$opening_timestamp, "POSIXct")
  expect_true("current_timestamp" %in% names(dt))
  expect_s3_class(dt$current_timestamp, "POSIXct")
  expect_true("symbol" %in% names(dt))
})

# -- get_positions --

test_that("get_positions returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_position_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_positions()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
})

test_that("get_positions passes currency filter", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_position_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures_account()$get_positions(currency = "USDT")
  expect_true(grepl("currency=USDT", captured_url))
})

# -- get_positions_history --

test_that("get_positions_history returns data.table with timestamps", {
  resp <- mock_kucoin_response(data = mock_futures_positions_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_positions_history()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
  expect_true("open_time" %in% names(dt))
  expect_s3_class(dt$open_time, "POSIXct")
  expect_true("close_time" %in% names(dt))
  expect_s3_class(dt$close_time, "POSIXct")
})

# -- get_margin_mode --

test_that("get_margin_mode returns data.table with mode", {
  resp <- mock_kucoin_response(data = mock_futures_margin_mode_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_margin_mode("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("margin_mode" %in% names(dt))
  expect_equal(dt$margin_mode, "ISOLATED")
})

# -- set_margin_mode --

test_that("set_margin_mode sends POST", {
  captured_method <- NULL
  resp <- mock_kucoin_response(data = mock_futures_margin_mode_data())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  dt <- new_futures_account()$set_margin_mode("XBTUSDTM", "CROSS")
  expect_equal(captured_method, "POST")
  expect_s3_class(dt, "data.table")
})

# -- get_cross_margin_leverage --

test_that("get_cross_margin_leverage returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_cross_leverage_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_cross_margin_leverage("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("leverage" %in% names(dt))
})

# -- set_cross_margin_leverage --

test_that("set_cross_margin_leverage sends POST", {
  captured_method <- NULL
  resp <- mock_kucoin_response(data = mock_futures_cross_leverage_data())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  dt <- new_futures_account()$set_cross_margin_leverage("XBTUSDTM", 10)
  expect_equal(captured_method, "POST")
  expect_s3_class(dt, "data.table")
})

# -- get_max_open_size --

test_that("get_max_open_size returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_max_open_size_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_max_open_size("XBTUSDTM", price = "98000", leverage = 5)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("max_buy_open_size" %in% names(dt))
})

# -- get_max_withdraw_margin --

test_that("get_max_withdraw_margin returns data.table", {
  resp <- mock_kucoin_response(data = mock_futures_max_withdraw_margin_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_max_withdraw_margin("XBTUSDTM")
  expect_s3_class(dt, "data.table")
})

# -- add_isolated_margin --

test_that("add_isolated_margin sends POST", {
  captured_method <- NULL
  resp <- mock_kucoin_response(data = mock_futures_margin_response())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  dt <- new_futures_account()$add_isolated_margin("XBTUSDTM", margin = 10, bizNo = "biz-001")
  expect_equal(captured_method, "POST")
  expect_s3_class(dt, "data.table")
})

# -- remove_isolated_margin --

test_that("remove_isolated_margin sends POST", {
  captured_method <- NULL
  resp <- mock_kucoin_response(data = mock_futures_margin_response())
  httr2::local_mocked_responses(function(req) {
    captured_method <<- req$method
    return(resp)
  })

  dt <- new_futures_account()$remove_isolated_margin("XBTUSDTM", withdrawAmount = 5)
  expect_equal(captured_method, "POST")
  expect_s3_class(dt, "data.table")
})

# -- get_risk_limit --

test_that("get_risk_limit returns multi-row data.table", {
  resp <- mock_kucoin_response(data = mock_futures_risk_limit_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_risk_limit("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("level" %in% names(dt))
  expect_true("max_leverage" %in% names(dt))
})

test_that("get_risk_limit hits correct endpoint", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_risk_limit_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures_account()$get_risk_limit("XBTUSDTM")
  expect_true(grepl("contracts/risk-limit/XBTUSDTM", captured_url))
})

# -- get_funding_history --

test_that("get_funding_history returns data.table with time_point as POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_private_funding_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_funding_history("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
  expect_true("time_point" %in% names(dt))
  expect_s3_class(dt$time_point, "POSIXct")
  expect_true("symbol" %in% names(dt))
})

test_that("get_funding_history passes symbol in query", {
  captured_url <- NULL
  resp <- mock_kucoin_response(data = mock_futures_private_funding_data())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_futures_account()$get_funding_history("XBTUSDTM")
  expect_true(grepl("symbol=XBTUSDTM", captured_url))
})

# -- Data-shape convention: no list columns, one entity = one row -------------
#
# The cross-package convention is documented in
# `binance::vignette("data-shapes")`. For each method we sanity-check:
#   - The output is a `data.table`.
#   - No column is a list (i.e. no list cells / nested objects).
#   - Empty responses produce empty `data.table`s, not stub rows or errors.

# Helper: count list columns on a data.table.
n_list_cols <- function(dt) {
  return(length(names(dt)[vapply(dt, is.list, logical(1))]))
}

test_that("get_account_overview has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_account_overview_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_account_overview()
  expect_equal(n_list_cols(dt), 0L)
})

test_that("get_position has no list columns; timestamps are POSIXct", {
  resp <- mock_kucoin_response(data = mock_futures_position_data()[[1]])
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_position("XBTUSDTM")
  expect_equal(n_list_cols(dt), 0L)
  expect_s3_class(dt$opening_timestamp, "POSIXct")
  expect_s3_class(dt$current_timestamp, "POSIXct")
})

test_that("get_positions has no list columns; empty array yields empty dt", {
  resp <- mock_kucoin_response(data = mock_futures_position_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_positions()
  expect_equal(n_list_cols(dt), 0L)
  expect_s3_class(dt$opening_timestamp, "POSIXct")

  resp_empty <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp_empty)
  dt_empty <- new_futures_account()$get_positions()
  expect_s3_class(dt_empty, "data.table")
  expect_equal(nrow(dt_empty), 0L)
})

test_that("get_positions_history has no list columns; empty items yields empty dt", {
  resp <- mock_kucoin_response(data = mock_futures_positions_history_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_positions_history()
  expect_equal(n_list_cols(dt), 0L)
  expect_s3_class(dt$open_time, "POSIXct")
  expect_s3_class(dt$close_time, "POSIXct")

  resp_empty <- mock_kucoin_response(data = list(items = list()))
  httr2::local_mocked_responses(function(req) resp_empty)
  dt_empty <- new_futures_account()$get_positions_history()
  expect_s3_class(dt_empty, "data.table")
  expect_equal(nrow(dt_empty), 0L)
})

test_that("get_margin_mode has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_margin_mode_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_margin_mode("XBTUSDTM")
  expect_equal(n_list_cols(dt), 0L)
})

test_that("set_margin_mode has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_margin_mode_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$set_margin_mode("XBTUSDTM", "CROSS")
  expect_equal(n_list_cols(dt), 0L)
})

test_that("get_cross_margin_leverage has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_cross_leverage_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_cross_margin_leverage("XBTUSDTM")
  expect_equal(n_list_cols(dt), 0L)
})

test_that("set_cross_margin_leverage has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_cross_leverage_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$set_cross_margin_leverage("XBTUSDTM", 10)
  expect_equal(n_list_cols(dt), 0L)
})

test_that("get_max_open_size has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_max_open_size_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_max_open_size("XBTUSDTM", price = "98000", leverage = 5)
  expect_equal(n_list_cols(dt), 0L)
})

test_that("get_max_withdraw_margin returns named max_withdraw_margin column", {
  resp <- mock_kucoin_response(data = mock_futures_max_withdraw_margin_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_max_withdraw_margin("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(names(dt), "max_withdraw_margin")
  expect_type(dt$max_withdraw_margin, "character")
  expect_equal(dt$max_withdraw_margin, "15.00")
  expect_equal(n_list_cols(dt), 0L)
})

test_that("get_max_withdraw_margin handles empty response", {
  resp <- mock_kucoin_response(data = NULL)
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_max_withdraw_margin("XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("add_isolated_margin has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_margin_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$add_isolated_margin("XBTUSDTM", margin = 10, bizNo = "biz-001")
  expect_equal(n_list_cols(dt), 0L)
})

test_that("remove_isolated_margin has no list columns", {
  resp <- mock_kucoin_response(data = mock_futures_margin_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$remove_isolated_margin("XBTUSDTM", withdrawAmount = 5)
  expect_equal(n_list_cols(dt), 0L)
})

test_that("get_risk_limit has no list columns; empty array yields empty dt", {
  resp <- mock_kucoin_response(data = mock_futures_risk_limit_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_risk_limit("XBTUSDTM")
  expect_equal(n_list_cols(dt), 0L)

  resp_empty <- mock_kucoin_response(data = list())
  httr2::local_mocked_responses(function(req) resp_empty)
  dt_empty <- new_futures_account()$get_risk_limit("XBTUSDTM")
  expect_s3_class(dt_empty, "data.table")
  expect_equal(nrow(dt_empty), 0L)
})

test_that("get_funding_history has no list columns; empty dataList yields empty dt", {
  resp <- mock_kucoin_response(data = mock_futures_private_funding_data())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_futures_account()$get_funding_history("XBTUSDTM")
  expect_equal(n_list_cols(dt), 0L)
  expect_s3_class(dt$time_point, "POSIXct")

  resp_empty <- mock_kucoin_response(data = list(dataList = list(), hasMore = FALSE))
  httr2::local_mocked_responses(function(req) resp_empty)
  dt_empty <- new_futures_account()$get_funding_history("XBTUSDTM")
  expect_s3_class(dt_empty, "data.table")
  expect_equal(nrow(dt_empty), 0L)
})
