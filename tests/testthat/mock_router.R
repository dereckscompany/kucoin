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
  mock_eth_ticker_data,
  # Margin Trading
  mock_margin_order_response, mock_margin_borrow_response,
  mock_margin_repay_response, mock_borrow_history_data,
  mock_repay_history_data, mock_interest_history_data,
  mock_borrow_rate_data, mock_empty_response,
  # Margin Data
  mock_cross_margin_symbols_data, mock_isolated_margin_symbols_data,
  mock_margin_config_data, mock_collateral_ratio_data, mock_risk_limit_data,
  # Lending
  mock_loan_market_data, mock_loan_market_rate_data,
  mock_purchase_response, mock_purchase_orders_data,
  mock_redeem_response, mock_redeem_orders_data,
  # Futures Market Data
  mock_futures_contract_data, mock_futures_all_contracts_data,
  mock_futures_ticker_data, mock_futures_all_tickers_data,
  mock_futures_orderbook_data, mock_futures_trade_history_data,
  mock_futures_klines_data, mock_futures_mark_price_data,
  mock_futures_funding_rate_data, mock_futures_funding_history_data,
  mock_futures_server_time_data, mock_futures_service_status_data,
  # Futures Trading
  mock_futures_order_response, mock_futures_cancel_order_data,
  mock_futures_order_detail_data, mock_futures_order_list_data,
  mock_futures_fills_data, mock_futures_open_order_value_data,
  mock_futures_dcp_data,
  # Futures Account
  mock_futures_account_overview_data, mock_futures_position_data,
  mock_futures_positions_history_data, mock_futures_margin_mode_data,
  mock_futures_cross_leverage_data, mock_futures_max_open_size_data,
  mock_futures_max_withdraw_margin_data, mock_futures_margin_response,
  mock_futures_risk_limit_data, mock_futures_private_funding_data
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
  # Margin Trading (before generic patterns — order matters for substring matching)
  list(pattern = "hf/margin/order/test", fixture = function() mock_margin_order_response()),
  list(pattern = "hf/margin/order", fixture = function() mock_margin_order_response()),
  list(pattern = "margin/borrowRate", fixture = function() mock_borrow_rate_data()),
  list(pattern = "margin/borrow", fixture = function() mock_margin_borrow_response(), method = "POST"),
  list(pattern = "margin/borrow", fixture = function() mock_borrow_history_data()),
  list(pattern = "margin/repay", fixture = function() mock_margin_repay_response(), method = "POST"),
  list(pattern = "margin/repay", fixture = function() mock_repay_history_data()),
  list(pattern = "margin/interest", fixture = function() mock_interest_history_data()),
  list(pattern = "position/update-user-leverage", fixture = function() mock_empty_response()),
  # Margin Data (before generic "currencies" and "symbols")
  list(pattern = "margin/symbols", fixture = function() mock_cross_margin_symbols_data()),
  list(pattern = "isolated/symbols", fixture = function() mock_isolated_margin_symbols_data()),
  list(pattern = "margin/config", fixture = function() mock_margin_config_data()),
  list(pattern = "margin/collateralRatio", fixture = function() mock_collateral_ratio_data()),
  list(pattern = "margin/currencies", fixture = function() mock_risk_limit_data()),
  # Lending (specific patterns before generic "purchase"/"redeem")
  list(pattern = "project/marketInterestRate", fixture = function() mock_loan_market_rate_data()),
  list(pattern = "project/list", fixture = function() mock_loan_market_data()),
  list(pattern = "lend/purchase/update", fixture = function() mock_empty_response()),
  list(pattern = "purchase/orders", fixture = function() mock_purchase_orders_data()),
  list(pattern = "/api/v3/purchase", fixture = function() mock_purchase_response(), method = "POST"),
  list(pattern = "redeem/orders", fixture = function() mock_redeem_orders_data()),
  list(pattern = "/api/v3/redeem", fixture = function() mock_redeem_response(), method = "POST"),
  # Futures Market Data (before generic patterns)
  list(pattern = "contracts/risk-limit", fixture = function() mock_futures_risk_limit_data()),
  list(pattern = "contracts/active", fixture = function() mock_futures_all_contracts_data()),
  list(pattern = "contracts/", fixture = function() mock_futures_contract_data()),
  list(pattern = "api/v1/allTickers", fixture = function() mock_futures_all_tickers_data()),
  list(pattern = "api/v1/ticker", fixture = function() mock_futures_ticker_data()),
  list(pattern = "level2/depth", fixture = function() mock_futures_orderbook_data()),
  list(pattern = "level2/snapshot", fixture = function() mock_futures_orderbook_data()),
  list(pattern = "trade/history", fixture = function() mock_futures_trade_history_data()),
  list(pattern = "kline/query", fixture = function() mock_futures_klines_data()),
  list(pattern = "mark-price", fixture = function() mock_futures_mark_price_data()),
  list(pattern = "funding-rate", fixture = function() mock_futures_funding_rate_data()),
  list(pattern = "contract/funding-rates", fixture = function() mock_futures_funding_history_data()),
  list(pattern = "api/v1/timestamp", fixture = function() mock_futures_server_time_data()),
  list(pattern = "api/v1/status", fixture = function() mock_futures_service_status_data()),
  # Futures Trading
  list(pattern = "orders/dead-cancel-all/query", fixture = function() mock_futures_dcp_data()),
  list(pattern = "orders/dead-cancel-all", fixture = function() mock_futures_dcp_data(), method = "POST"),
  list(pattern = "orders/test", fixture = function() mock_futures_order_response(), method = "POST"),
  list(pattern = "orders/multi", fixture = function() list(mock_futures_order_response()), method = "POST"),
  list(pattern = "orders/byClientOid", fixture = function() mock_futures_order_detail_data()),
  list(pattern = "orders/client-order", fixture = function() mock_futures_cancel_order_data(), method = "DELETE"),
  list(pattern = "recentDoneOrders", fixture = function() list(mock_futures_order_detail_data())),
  list(pattern = "recentFills", fixture = function() mock_futures_fills_data()),
  list(pattern = "openOrderStatistics", fixture = function() mock_futures_open_order_value_data()),
  list(pattern = "stopOrders", fixture = function() mock_futures_cancel_order_data(), method = "DELETE"),
  # Futures Account
  list(pattern = "account-overview", fixture = function() mock_futures_account_overview_data()),
  list(pattern = "api/v2/position", fixture = function() mock_futures_position_data()),
  list(pattern = "history-positions", fixture = function() mock_futures_positions_history_data()),
  list(pattern = "api/v1/positions", fixture = function() mock_futures_position_data()),
  list(pattern = "marginMode", fixture = function() mock_futures_margin_mode_data()),
  list(pattern = "crossMarginLeverage", fixture = function() mock_futures_cross_leverage_data()),
  list(pattern = "maxOpenSize", fixture = function() mock_futures_max_open_size_data()),
  list(pattern = "maxWithdrawMargin", fixture = function() mock_futures_max_withdraw_margin_data()),
  list(pattern = "marginDepositIn", fixture = function() mock_futures_margin_response()),
  list(pattern = "marginWithdrawOut", fixture = function() mock_futures_margin_response()),
  list(pattern = "funding-history", fixture = function() mock_futures_private_funding_data()),
  # Generic market data (after margin-specific patterns)
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
