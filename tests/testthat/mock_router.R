# Shared mock HTTP router for README and vignettes.
#
# Dispatches httr2 requests to fixture data based on URL pattern matching.
# Fixtures come from mockery.R; this file only handles routing logic.
#
# Usage (in a hidden knitr setup chunk):
#   box::use(./tests/testthat/mock_router[mock_router])
#   options(httr2_mock = mock_router)

# This file is used in two ways:
# 1. As a box module via box::use() from README.Rmd and vignettes
# 2. Could be source()'d in testthat context if needed
# We use :: notation for httr2/jsonlite and source() for mockery.R
# so it works in both contexts.

# Load all fixtures from mockery.R (sibling file)
box::use(./mockery[
  mock_response,
  mock_ticker_data, mock_24hr_stats_data, mock_all_tickers_data,
  mock_trade_history_data, mock_orderbook_data, mock_klines_data,
  mock_currency_data, mock_symbol_data,
  mock_order_response, mock_open_orders_data, mock_cancel_order_data,
  mock_account_summary_data, mock_spot_accounts_data,
  mock_stop_order_response, mock_oco_order_response,
  mock_deposit_addresses_data,
  mock_sub_accounts_page_data, mock_sub_accounts_empty_page,
  mock_eth_ticker_data
])

#' Route table: URL pattern -> fixture thunk
#' Order matters — more specific patterns first (e.g. "orderbook/level2"
#' before "orderbook/level1").
#' @keywords internal
.mock_routes <- list(
  # Market data
  list(pattern = "market/orderbook/level2", fixture = function() mock_orderbook_data()),
  list(pattern = "market/orderbook/level1", fixture = function() mock_ticker_data()),
  list(pattern = "market/allTickers", fixture = function() mock_all_tickers_data()),
  list(pattern = "market/stats", fixture = function() mock_24hr_stats_data()),
  list(pattern = "market/histories", fixture = function() mock_trade_history_data()),
  list(pattern = "market/candles", fixture = function() mock_klines_data(n = 3)),
  list(pattern = "currencies", fixture = function() mock_currency_data()),
  list(pattern = "symbols", fixture = function() mock_symbol_data()),
  # Trading (order matters: test before active before generic hf/orders)
  list(pattern = "hf/orders/test", fixture = function() mock_order_response()),
  list(pattern = "hf/orders/active", fixture = function() mock_open_orders_data()),
  list(pattern = "hf/orders", fixture = function() mock_cancel_order_data(), method = "DELETE"),
  # Stop & OCO orders
  list(pattern = "stop-order", fixture = function() mock_stop_order_response()),
  list(pattern = "oco/order", fixture = function() mock_oco_order_response()),
  # Account
  list(pattern = "user-info", fixture = function() mock_account_summary_data()),
  list(pattern = "/api/v1/accounts", fixture = function() mock_spot_accounts_data()),
  # Deposits
  list(pattern = "deposit-addresses", fixture = function() mock_deposit_addresses_data())
)

#' Internal counter for paginated endpoints
#' @keywords internal
.mock_page_counter <- new.env(parent = emptyenv())
.mock_page_counter$sub_accounts <- 0L

#' Mock HTTP router for README and vignettes
#'
#' Dispatches `httr2` requests to fixture data based on URL pattern matching.
#' Set via `options(httr2_mock = mock_router)` in a hidden knitr setup chunk.
#'
#' @param req An `httr2_request` object.
#' @return An `httr2_response` object.
#' @export
mock_router <- function(req) {
  url <- req$url
  method <- req$method

  # Sub-accounts — paginated: first call returns data, second returns empty
  if (grepl("sub/user", url) || grepl("sub-accounts", url)) {
    .mock_page_counter$sub_accounts <- .mock_page_counter$sub_accounts + 1L
    if (.mock_page_counter$sub_accounts == 1L) {
      return(mock_response(mock_sub_accounts_page_data()))
    }
    return(mock_response(mock_sub_accounts_empty_page()))
  }

  # Route table lookup
  for (route in .mock_routes) {
    if (grepl(route$pattern, url, fixed = TRUE)) {
      if (!is.null(route$method) && method != route$method) {
        next
      }
      return(mock_response(route$fixture()))
    }
  }

  stop("Unmocked request: ", url)
}
