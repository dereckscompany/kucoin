# Synthetic KuCoin fixture builders, backed by the JSON fixtures on disk.
#
# The fixture DATA now lives in tests/testthat/fixtures/*.json (each a full
# `{ "code": "200000", "data": ... }` envelope), which is the single source of
# truth shared by the router (mock_router.R), the README, and the vignettes.
# This file is the thin compatibility layer the unit tests build on: each
# `mock_X_data()` parses its fixture and returns the bare `data` payload, and
# `mock_response()` re-wraps an arbitrary payload in the KuCoin envelope so a
# test can mutate the payload before serving it.
#
# This file is used in two ways:
# 1. As a box module via box::use() from the async vignette.
# 2. Via source() from helper-mock.R (testthat context).
# We use :: notation throughout so it works in both contexts.

# Load every fixture as a parsed list, keyed by basename (ticker.json ->
# "ticker"). This module is reached two ways: box::use() (the async vignette),
# where box::file() resolves the fixtures dir next to this file; and source()
# from helper-mock.R (testthat), where testthat::test_path() locates it. Pick
# whichever resolves to an existing directory.
.fixtures_dir <- local({
  box_dir <- tryCatch(box::file("fixtures"), error = function(e) NULL)
  if (!is.null(box_dir) && dir.exists(box_dir)) {
    return(box_dir)
  }
  return(file.path(testthat::test_path(), "fixtures"))
})
.fixtures <- connectcore::load_fixtures(.fixtures_dir, parse = TRUE)

# Return the bare `data` payload of a named fixture.
.data <- function(name) {
  fx <- .fixtures[[name]]
  if (is.null(fx)) {
    stop("Unknown fixture: ", name, call. = FALSE)
  }
  return(fx$data)
}

# ---------------------------------------------------------------------------
# Response builder
# ---------------------------------------------------------------------------

#' Build a fake httr2 response with KuCoin JSON envelope
#' @export
mock_response <- function(data, code = "200000", status_code = 200L) {
  body <- jsonlite::toJSON(
    list(code = code, data = data),
    auto_unbox = TRUE,
    null = "null"
  )
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

# ---------------------------------------------------------------------------
# Market Data fixtures
# ---------------------------------------------------------------------------

#' @export
mock_ticker_data <- function() {
  return(.data("ticker"))
}

#' @export
mock_24hr_stats_data <- function() {
  return(.data("stats_24hr"))
}

#' @export
mock_all_tickers_data <- function() {
  return(.data("all_tickers"))
}

#' @export
mock_trade_history_data <- function() {
  return(.data("trade_history"))
}

#' @export
mock_orderbook_data <- function() {
  return(.data("orderbook"))
}

#' Klines (candles). The on-disk fixture holds a fixed 3-candle sample; the
#' `n`/`start_ts` arguments are honoured by generating from the bundled
#' `kucoin_btc_usdt_4h_ohlcv` dataset, preserving the timestamps tests rely on.
#' @param n Number of candles to return.
#' @param start_ts Optional start timestamp (seconds); when set, candles are
#'   generated at 4h intervals from this timestamp.
#' @param offset Row offset into the bundled dataset (1-indexed). Default 17000.
#' @export
mock_klines_data <- function(n = 5, start_ts = NULL, offset = 17000) {
  if (is.null(start_ts) && n == 3L) {
    return(.data("klines"))
  }
  dt <- kucoin::kucoin_btc_usdt_4h_ohlcv[seq(offset, offset + n - 1)]
  return(lapply(seq_len(nrow(dt)), function(i) {
    row <- dt[i]
    ts <- start_ts
    if (is.null(ts)) {
      ts <- as.integer(row$datetime)
    } else {
      ts <- as.integer(start_ts + (i - 1) * 14400) # 4h intervals
    }
    return(c(
      as.character(ts),
      as.character(row$open),
      as.character(row$close),
      as.character(row$high),
      as.character(row$low),
      as.character(row$volume),
      as.character(row$turnover)
    ))
  }))
}

#' @export
mock_currency_data <- function() {
  return(.data("currency"))
}

#' @export
mock_symbol_data <- function() {
  return(.data("symbol"))
}

#' @export
mock_market_list_data <- function() {
  return(unlist(.data("market_list")))
}

#' @export
mock_announcements_page_data <- function() {
  return(.data("announcements_page"))
}

# ---------------------------------------------------------------------------
# Trading fixtures
# ---------------------------------------------------------------------------

#' @export
mock_order_response <- function() {
  return(.data("order_response"))
}

#' @export
mock_open_orders_data <- function() {
  return(.data("open_orders"))
}

#' @export
mock_cancel_order_data <- function() {
  return(.data("cancel_order"))
}

# ---------------------------------------------------------------------------
# Account fixtures
# ---------------------------------------------------------------------------

#' @export
mock_account_summary_data <- function() {
  return(.data("account_summary"))
}

#' @export
mock_spot_accounts_data <- function() {
  return(.data("spot_accounts"))
}

# ---------------------------------------------------------------------------
# Stop / OCO Order fixtures
# ---------------------------------------------------------------------------

#' @export
mock_stop_order_response <- function() {
  return(.data("stop_order_response"))
}

#' @export
mock_oco_order_response <- function() {
  return(.data("oco_order_response"))
}

# ---------------------------------------------------------------------------
# Deposit fixtures
# ---------------------------------------------------------------------------

#' @export
mock_deposit_addresses_data <- function() {
  return(.data("deposit_addresses"))
}

# ---------------------------------------------------------------------------
# Sub-Account fixtures
# ---------------------------------------------------------------------------

#' @export
mock_sub_accounts_page_data <- function() {
  return(.data("sub_accounts_page"))
}

#' @export
mock_sub_accounts_empty_page <- function() {
  return(.data("sub_accounts_empty_page"))
}

#' @export
mock_eth_ticker_data <- function() {
  return(.data("eth_ticker"))
}

# ---------------------------------------------------------------------------
# Margin Trading fixtures
# ---------------------------------------------------------------------------

#' @export
mock_margin_order_response <- function() {
  return(.data("margin_order_response"))
}

#' @export
mock_margin_borrow_response <- function() {
  return(.data("margin_borrow_response"))
}

#' @export
mock_margin_repay_response <- function() {
  return(.data("margin_repay_response"))
}

#' @export
mock_borrow_history_data <- function() {
  return(.data("borrow_history"))
}

#' @export
mock_repay_history_data <- function() {
  return(.data("repay_history"))
}

#' @export
mock_interest_history_data <- function() {
  return(.data("interest_history"))
}

#' @export
mock_borrow_rate_data <- function() {
  return(.data("borrow_rate"))
}

#' Empty response for endpoints that return invisible(NULL)
#' @export
mock_empty_response <- function() {
  return(.data("empty"))
}

# ---------------------------------------------------------------------------
# Margin Data fixtures
# ---------------------------------------------------------------------------

#' @export
mock_cross_margin_symbols_data <- function() {
  return(.data("cross_margin_symbols"))
}

#' @export
mock_isolated_margin_symbols_data <- function() {
  return(.data("isolated_margin_symbols"))
}

#' @export
mock_margin_config_data <- function() {
  return(.data("margin_config"))
}

#' @export
mock_collateral_ratio_data <- function() {
  return(.data("collateral_ratio"))
}

#' @export
mock_risk_limit_data <- function() {
  return(.data("risk_limit"))
}

# ---------------------------------------------------------------------------
# Lending fixtures
# ---------------------------------------------------------------------------

#' @export
mock_loan_market_data <- function() {
  return(.data("loan_market"))
}

#' @export
mock_loan_market_rate_data <- function() {
  return(.data("loan_market_rate"))
}

#' @export
mock_purchase_response <- function() {
  return(.data("purchase_response"))
}

#' @export
mock_purchase_orders_data <- function() {
  return(.data("purchase_orders"))
}

#' @export
mock_redeem_response <- function() {
  return(.data("redeem_response"))
}

#' @export
mock_redeem_orders_data <- function() {
  return(.data("redeem_orders"))
}

# ---------------------------------------------------------------------------
# Futures Market Data fixtures
# ---------------------------------------------------------------------------

#' @export
mock_futures_contract_data <- function() {
  return(.data("futures_contract"))
}

#' @export
mock_futures_all_contracts_data <- function() {
  return(.data("futures_all_contracts"))
}

#' @export
mock_futures_ticker_data <- function() {
  return(.data("futures_ticker"))
}

#' @export
mock_futures_all_tickers_data <- function() {
  return(.data("futures_all_tickers"))
}

#' @export
mock_futures_orderbook_data <- function() {
  return(.data("futures_orderbook"))
}

#' @export
mock_futures_trade_history_data <- function() {
  return(.data("futures_trade_history"))
}

#' @export
mock_futures_klines_data <- function() {
  return(.data("futures_klines"))
}

#' @export
mock_futures_mark_price_data <- function() {
  return(.data("futures_mark_price"))
}

#' @export
mock_futures_funding_rate_data <- function() {
  return(.data("futures_funding_rate"))
}

#' @export
mock_futures_funding_history_data <- function() {
  return(.data("futures_funding_history"))
}

#' @export
mock_futures_server_time_data <- function() {
  return(.data("futures_server_time"))
}

#' @export
mock_futures_service_status_data <- function() {
  return(.data("futures_service_status"))
}

# ---------------------------------------------------------------------------
# Futures Trading fixtures
# ---------------------------------------------------------------------------

#' @export
mock_futures_order_response <- function() {
  return(.data("futures_order_response"))
}

#' @export
mock_futures_cancel_order_data <- function() {
  return(.data("futures_cancel_order"))
}

#' @export
mock_futures_order_detail_data <- function() {
  return(.data("futures_order_detail"))
}

#' @export
mock_futures_order_list_data <- function() {
  return(.data("futures_order_list"))
}

#' @export
mock_futures_fills_data <- function() {
  return(.data("futures_fills"))
}

#' @export
mock_futures_open_order_value_data <- function() {
  return(.data("futures_open_order_value"))
}

#' @export
mock_futures_dcp_data <- function() {
  return(.data("futures_dcp"))
}

# ---------------------------------------------------------------------------
# Futures Account fixtures
# ---------------------------------------------------------------------------

#' @export
mock_futures_account_overview_data <- function() {
  return(.data("futures_account_overview"))
}

#' @export
mock_futures_position_data <- function() {
  return(.data("futures_position"))
}

#' @export
mock_futures_positions_history_data <- function() {
  return(.data("futures_positions_history"))
}

#' @export
mock_futures_margin_mode_data <- function() {
  return(.data("futures_margin_mode"))
}

#' @export
mock_futures_cross_leverage_data <- function() {
  return(.data("futures_cross_leverage"))
}

#' @export
mock_futures_max_open_size_data <- function() {
  return(.data("futures_max_open_size"))
}

#' @export
mock_futures_max_withdraw_margin_data <- function() {
  return(.data("futures_max_withdraw_margin"))
}

#' @export
mock_futures_margin_response <- function() {
  return(.data("futures_margin_response"))
}

#' @export
mock_futures_risk_limit_data <- function() {
  return(.data("futures_risk_limit"))
}

#' @export
mock_futures_private_funding_data <- function() {
  return(.data("futures_private_funding"))
}
