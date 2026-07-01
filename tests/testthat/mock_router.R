# Shared mock HTTP router for the kucoin README, vignettes, and tests.
#
# This is the THIN kucoin-specific layer over connectcore's shared mock harness
# (connectcore::mock_router / with_mock_api / local_mock_api / load_fixtures /
# mock_response). connectcore owns the response builder, the dispatch loop, and
# the scoped-activation helpers; this file only declares the route table -- URL
# pattern + HTTP method -> the fixture for that endpoint -- and loads the
# fixtures from disk.
#
# Each route's fixture is the JSON for that endpoint, loaded verbatim from
# tests/testthat/fixtures/*.json by connectcore::load_fixtures() (a named list
# keyed by file basename; each value is the raw JSON string). Every fixture
# carries the full KuCoin envelope `{ "code": "200000", "data": ... }`, so
# connectcore::mock_response() -- which serves a string body verbatim -- feeds
# the parsers and column contracts exactly what the live wire returns. The
# fixtures are synthetic but shape-faithful; the authenticated ones carry no
# real account identifiers or balances.
#
# httr2 exposes a native global mock hook: connectcore::with_mock_api(.mock_routes,
# { ... }) (or local_mock_api(.mock_routes)) installs the dispatcher as the
# httr2_mock option, intercepting every req_perform / req_perform_promise call,
# so docs render and tests run against canned, deterministic data with no
# network, no real credentials, and no funds.
#
# Usage (in a hidden knitr setup chunk or a test):
#   box::use(./tests/testthat/mock_router[.mock_routes])
#   connectcore::with_mock_api(.mock_routes, { ...code... })  # scoped to a block
#   connectcore::local_mock_api(.mock_routes)                 # scoped to a frame
#
# A back-compat `mock_router(req)` thunk is also exported for the few callers
# that set `options(httr2_mock = mock_router)` directly.

box::use(
  connectcore[load_fixtures, mock_response]
)

# Load every fixture as its raw JSON string, keyed by file basename
# (ticker.json -> "ticker"). Resolved relative to THIS module file so it works
# from the package root (README), vignettes/, and tests/testthat alike.
.fixtures <- load_fixtures(box::file("fixtures"))

# Sub-accounts pagination is STATEFUL: the client walks pages until it gets an
# empty `items` array. connectcore invokes a route's `fixture` thunk PER REQUEST,
# which is what makes this expressible as a stateful closure: the thunk returns
# page 1 on the first request and the empty page thereafter, so the paginator
# terminates. The counter lives in a module-level env (box bindings are locked,
# so it cannot be a rebound value); `.reset_pagination()` re-arms it before a
# fresh render or test scope.
.pagination <- new.env(parent = emptyenv())
.pagination$sub_accounts <- 0L

#' Reset the stateful sub-accounts paginator (page 1 on the next request).
#' @export
.reset_pagination <- function() {
  .pagination$sub_accounts <- 0L
  return(invisible(NULL))
}

.sub_accounts_fixture <- function() {
  .pagination$sub_accounts <- .pagination$sub_accounts + 1L
  if (.pagination$sub_accounts == 1L) {
    return(.fixtures$sub_accounts_page)
  }
  return(.fixtures$sub_accounts_empty_page)
}

# Two endpoints wrap a single object in a one-element array on the wire; the
# captured fixture stores the bare object, so re-wrap it here. mock_response
# JSON-encodes a list payload, so these stay R lists rather than strings.
.futures_order_response_list <- function() {
  return(list(code = "200000", data = list(jsonlite::fromJSON(.fixtures$futures_order_response)$data)))
}
.futures_order_detail_list <- function() {
  return(list(code = "200000", data = list(jsonlite::fromJSON(.fixtures$futures_order_detail)$data)))
}

#' Route table: URL pattern (+ optional method) -> fixture JSON string.
#'
#' Order matters -- more specific patterns first (e.g. "orderbook/level2" before
#' "orderbook/level1"). Hosts:
#'   Spot:    https://api.kucoin.com
#'   Futures: https://api-futures.kucoin.com
#' Each `fixture` is the raw JSON string for that endpoint (served verbatim by
#' connectcore::mock_response); the sub-accounts route is a stateful thunk.
#' @export
.mock_routes <- list(
  # Sub-accounts -- paginated: page 1 then the empty page (stateful). Placed
  # first so it wins before any generic "/accounts" pattern.
  list(pattern = "sub/user", fixture = .sub_accounts_fixture),
  list(pattern = "sub-accounts", fixture = .sub_accounts_fixture),

  # Market data
  list(pattern = "market/orderbook/level2", fixture = .fixtures$orderbook),
  list(pattern = "market/orderbook/level1", fixture = .fixtures$ticker),
  list(pattern = "market/allTickers", fixture = .fixtures$all_tickers),
  list(pattern = "market/stats", fixture = .fixtures$stats_24hr),
  list(pattern = "market/histories", fixture = .fixtures$trade_history),
  list(pattern = "market/candles", fixture = .fixtures$klines),

  # Margin Trading (before generic patterns -- order matters for substrings)
  list(pattern = "hf/margin/order/test", fixture = .fixtures$margin_order_response),
  list(pattern = "hf/margin/order", fixture = .fixtures$margin_order_response),
  list(pattern = "margin/borrowRate", fixture = .fixtures$borrow_rate),
  list(pattern = "margin/borrow", fixture = .fixtures$margin_borrow_response, method = "POST"),
  list(pattern = "margin/borrow", fixture = .fixtures$borrow_history),
  list(pattern = "margin/repay", fixture = .fixtures$margin_repay_response, method = "POST"),
  list(pattern = "margin/repay", fixture = .fixtures$repay_history),
  list(pattern = "margin/interest", fixture = .fixtures$interest_history),
  list(pattern = "position/update-user-leverage", fixture = .fixtures$empty),

  # Margin Data (before generic "currencies" and "symbols")
  list(pattern = "margin/symbols", fixture = .fixtures$cross_margin_symbols),
  list(pattern = "isolated/symbols", fixture = .fixtures$isolated_margin_symbols),
  list(pattern = "margin/config", fixture = .fixtures$margin_config),
  list(pattern = "margin/collateralRatio", fixture = .fixtures$collateral_ratio),
  list(pattern = "margin/currencies", fixture = .fixtures$risk_limit),

  # Lending (specific patterns before generic "purchase"/"redeem")
  list(pattern = "project/marketInterestRate", fixture = .fixtures$loan_market_rate),
  list(pattern = "project/list", fixture = .fixtures$loan_market),
  list(pattern = "lend/purchase/update", fixture = .fixtures$empty),
  list(pattern = "purchase/orders", fixture = .fixtures$purchase_orders),
  list(pattern = "/api/v3/purchase", fixture = .fixtures$purchase_response, method = "POST"),
  list(pattern = "redeem/orders", fixture = .fixtures$redeem_orders),
  list(pattern = "/api/v3/redeem", fixture = .fixtures$redeem_response, method = "POST"),

  # Futures Market Data (before generic patterns)
  list(pattern = "contracts/risk-limit", fixture = .fixtures$futures_risk_limit),
  list(pattern = "contracts/active", fixture = .fixtures$futures_all_contracts),
  list(pattern = "contracts/", fixture = .fixtures$futures_contract),
  list(pattern = "api/v1/allTickers", fixture = .fixtures$futures_all_tickers),
  list(pattern = "api/v1/ticker", fixture = .fixtures$futures_ticker),
  list(pattern = "level2/depth", fixture = .fixtures$futures_orderbook),
  list(pattern = "level2/snapshot", fixture = .fixtures$futures_orderbook),
  list(pattern = "trade/history", fixture = .fixtures$futures_trade_history),
  list(pattern = "kline/query", fixture = .fixtures$futures_klines),
  list(pattern = "mark-price", fixture = .fixtures$futures_mark_price),
  list(pattern = "funding-rate", fixture = .fixtures$futures_funding_rate),
  list(pattern = "contract/funding-rates", fixture = .fixtures$futures_funding_history),
  list(pattern = "api/v1/timestamp", fixture = .fixtures$futures_server_time),
  list(pattern = "api/v1/status", fixture = .fixtures$futures_service_status),

  # Futures Trading
  # Futures DCP migrated to the unified `/api/ua/v1/dcp/*` endpoint in v4.0.3
  # (the legacy `/api/v1/orders/dead-cancel-all*` paths return 404/403 since
  # KuCoin's 2026-05 reorganisation). The legacy patterns are kept second as a
  # fallback for any caller that hasn't migrated yet -- the first match wins.
  list(pattern = "ua/v1/dcp/query", fixture = .fixtures$futures_dcp),
  list(pattern = "ua/v1/dcp/set", fixture = .fixtures$futures_dcp_set, method = "POST"),
  list(pattern = "orders/dead-cancel-all/query", fixture = .fixtures$futures_dcp),
  list(pattern = "orders/dead-cancel-all", fixture = .fixtures$futures_dcp, method = "POST"),
  list(pattern = "orders/test", fixture = .fixtures$futures_order_response, method = "POST"),
  list(pattern = "orders/multi", fixture = .futures_order_response_list, method = "POST"),
  list(pattern = "orders/byClientOid", fixture = .fixtures$futures_order_detail),
  list(pattern = "orders/client-order", fixture = .fixtures$futures_cancel_order, method = "DELETE"),
  list(pattern = "recentDoneOrders", fixture = .futures_order_detail_list),
  list(pattern = "recentFills", fixture = .fixtures$futures_fills),
  list(pattern = "openOrderStatistics", fixture = .fixtures$futures_open_order_value),
  list(pattern = "stopOrders", fixture = .fixtures$futures_cancel_order, method = "DELETE"),

  # Futures Account
  list(pattern = "account-overview", fixture = .fixtures$futures_account_overview),
  list(pattern = "api/v2/position", fixture = .fixtures$futures_position),
  list(pattern = "history-positions", fixture = .fixtures$futures_positions_history),
  list(pattern = "api/v1/positions", fixture = .fixtures$futures_position),
  # Patterns track KuCoin's 2026-05 docs reorganisation: old paths
  # (`marginMode`, `crossMarginLeverage`, `maxOpenSize`, `marginDepositIn`,
  # `marginWithdrawOut`) were renamed to `getMarginMode` / `changeMarginMode`,
  # `getCrossUserLeverage` / `changeCrossUserLeverage`, `getMaxOpenSize`,
  # `deposit-margin`, and `withdrawMargin`. Routes below use the shortest
  # stable substring that survives both the GET and POST variants.
  list(pattern = "MarginMode", fixture = .fixtures$futures_margin_mode),
  list(pattern = "CrossUserLeverage", fixture = .fixtures$futures_cross_leverage),
  list(pattern = "MaxOpenSize", fixture = .fixtures$futures_max_open_size),
  list(pattern = "maxWithdrawMargin", fixture = .fixtures$futures_max_withdraw_margin),
  list(pattern = "deposit-margin", fixture = .fixtures$futures_margin_response),
  list(pattern = "withdrawMargin", fixture = .fixtures$futures_margin_response),
  list(pattern = "funding-history", fixture = .fixtures$futures_private_funding),

  # Generic market data (after margin-specific patterns)
  list(pattern = "currencies", fixture = .fixtures$currency),
  list(pattern = "symbols", fixture = .fixtures$symbol),

  # Trading (order matters: test before active before generic hf/orders)
  list(pattern = "hf/orders/test", fixture = .fixtures$order_response),
  list(pattern = "hf/orders/active", fixture = .fixtures$open_orders),
  list(pattern = "hf/orders", fixture = .fixtures$cancel_order, method = "DELETE"),

  # Stop & OCO orders
  list(pattern = "stop-order", fixture = .fixtures$stop_order_response),
  list(pattern = "oco/order", fixture = .fixtures$oco_order_response),

  # Account
  list(pattern = "user-info", fixture = .fixtures$account_summary),
  list(pattern = "/api/v1/accounts", fixture = .fixtures$spot_accounts),

  # Deposits
  list(pattern = "deposit-addresses", fixture = .fixtures$deposit_addresses)
)

#' Back-compat dispatcher: `options(httr2_mock = mock_router)`.
#'
#' Wraps `connectcore::mock_router(.mock_routes)` so the handful of callers that
#' set the option directly keep working. Re-arms the stateful paginator first so
#' a fresh render starts sub-accounts at page 1.
#' @param req An `httr2_request` object.
#' @return An `httr2_response` object.
#' @export
mock_router <- (function() {
  .reset_pagination()
  dispatch <- connectcore::mock_router(.mock_routes)
  return(function(req) {
    return(dispatch(req))
  })
})()
