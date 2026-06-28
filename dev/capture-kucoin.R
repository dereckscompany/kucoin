#!/usr/bin/env Rscript
# File: dev/capture-kucoin.R
#
# READ-ONLY capture harness for the `kucoin` package.
#
# Purpose: hit the REAL KuCoin API (the user's own account + the public market
# data API) with GET-only read requests and dump each raw response body verbatim
# to local/raw-data/kucoin/<name>.json. Those captures are then compared by hand
# (or by a sibling validation script) against the SYNTHETIC fixtures committed in
# tests/testthat/fixtures/ to prove the fixtures faithfully mirror the live wire
# shapes, and to surface over-strict column contracts that the synthetic
# fixtures hide.
#
# SAFETY: this script drives ONLY the package's read methods (`get_*`), which
# issue HTTP GET requests against read endpoints. It never POSTs/PUTs/PATCHes/
# DELETEs, never places/cancels orders, never moves funds. Capture is performed
# by overriding each client's private `.perform` hook with a wrapper that writes
# the raw response body to disk before the normal parser runs -- so a captured
# file lands even if an over-strict contract later rejects the parsed value.
# Credentials are read from the package .Renviron via Sys.getenv() and are never
# printed. Raw bodies (which contain the user's real account data) are written
# ONLY under local/raw-data/kucoin/ which is git-ignored.
#
# Run from the package root:
#   Rscript dev/capture-kucoin.R

suppressWarnings(suppressMessages({
  library(httr2)
  library(jsonlite)
  library(devtools)
}))

if (file.exists(".Renviron")) {
  readRenviron(".Renviron")
}

api_key <- Sys.getenv("KUCOIN_API_KEY")
api_secret <- Sys.getenv("KUCOIN_API_SECRET")
api_passphrase <- Sys.getenv("KUCOIN_API_PASSPHRASE")
have_keys <- nzchar(api_key) && nzchar(api_secret) && nzchar(api_passphrase)

OUT_DIR <- file.path("local", "raw-data", "kucoin")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Defensive: refuse to write anywhere git would track. local/ is git-ignored.
if (Sys.which("git") != "") {
  probe <- file.path(OUT_DIR, "ignore-probe.json")
  ignored <- suppressWarnings(system2(
    "git", c("check-ignore", probe),
    stdout = TRUE, stderr = FALSE
  ))
  if (length(ignored) == 0L) {
    stop(
      "Refusing to write: ", OUT_DIR,
      " is NOT git-ignored. Aborting to avoid committing real account data."
    )
  }
}

cat("Output dir :", normalizePath(OUT_DIR), "\n")
cat("Have keys  :", have_keys, "\n\n")

suppressWarnings(suppressMessages(devtools::load_all(".", quiet = TRUE)))

keys <- get_api_keys()

# ---------------------------------------------------------------------------
# Capture machinery: a mutable "current name" + a perform wrapper that dumps the
# raw response body verbatim, then returns the response untouched so the normal
# parser still runs. Installed onto each client's private `.perform` field.
# ---------------------------------------------------------------------------
.state <- new.env(parent = emptyenv())
.state$name <- NULL
.state$rows <- list()

capturing_perform <- function(req) {
  resp <- httr2::req_perform(req)
  if (!is.null(.state$name)) {
    body <- tryCatch(httr2::resp_body_raw(resp), error = function(e) NULL)
    if (!is.null(body)) {
      writeBin(body, file.path(OUT_DIR, paste0(.state$name, ".json")))
    }
  }
  return(resp)
}

install_capture <- function(client) {
  client$.__enclos_env__$private$.perform <- capturing_perform
  return(invisible(client))
}

is_empty_data <- function(parsed) {
  if (is.null(parsed)) return(TRUE)
  d <- parsed$data
  if (is.null(d)) return(TRUE)
  if (length(d) == 0L) return(TRUE)
  if (is.list(d) && !is.null(d$items) && length(d$items) == 0L) return(TRUE)
  return(FALSE)
}

# One read call: set the capture name, run the method, classify the raw file.
cap <- function(name, expr) {
  .state$name <- name
  out_path <- file.path(OUT_DIR, paste0(name, ".json"))
  if (file.exists(out_path)) file.remove(out_path)
  res <- tryCatch(
    {
      force(expr)
      "ok"
    },
    error = function(e) conditionMessage(e)
  )
  .state$name <- NULL

  wrote <- file.exists(out_path)
  bytes <- if (wrote) file.info(out_path)$size else 0L
  parsed <- if (wrote) {
    tryCatch(jsonlite::fromJSON(out_path, simplifyVector = FALSE), error = function(e) NULL)
  } else {
    NULL
  }
  code <- if (!is.null(parsed) && !is.null(parsed$code)) as.character(parsed$code) else NA_character_
  empty <- is_empty_data(parsed)

  state <- if (!wrote) {
    "NO-WRITE"
  } else if (!is.na(code) && code != "200000") {
    paste0("APIERR(", code, ")")
  } else if (empty) {
    "EMPTY"
  } else {
    "POPULATED"
  }
  parse_state <- if (identical(res, "ok")) "parse-ok" else "PARSE-FAIL"
  cat(sprintf(
    "%-28s %-14s %-9s bytes=%-7s %s%s\n",
    name, state, parse_state, bytes,
    if (!identical(res, "ok")) substr(res, 1, 60) else "",
    ""
  ))
  .state$rows[[name]] <<- list(state = state, parse = parse_state, bytes = bytes)
  Sys.sleep(0.35)
  return(invisible(NULL))
}

now_ms <- function() floor(as.numeric(Sys.time()) * 1000)

# ---------------------------------------------------------------------------
# Public market data (spot)
# ---------------------------------------------------------------------------
cat("== Spot public market data ==\n")
market <- install_capture(KucoinMarketData$new(keys = keys))

cap("spot_server_time", market$get_server_time())
cap("spot_service_status", market$get_service_status())
cap("market_list", market$get_market_list())
cap("currencies_all", market$get_all_currencies())
cap("currency", market$get_currency("BTC"))
cap("symbol", market$get_symbol("BTC-USDT"))
cap("symbols_all", market$get_all_symbols())
cap("ticker", market$get_ticker("BTC-USDT"))
cap("eth_ticker", market$get_ticker("ETH-USDT"))
cap("all_tickers", market$get_all_tickers())
cap("stats_24hr", market$get_24hr_stats("BTC-USDT"))
cap("trade_history", market$get_trade_history("BTC-USDT"))
cap("orderbook_part", market$get_part_orderbook("BTC-USDT", size = 20))
cap("fiat_prices", market$get_fiat_prices())
cap("klines", market$get_klines(
  symbol = "BTC-USDT", timeframe = "1hour",
  from = Sys.time() - 86400, to = Sys.time()
))
cap("announcements_page", market$get_announcements(query = list(), page_size = 5, max_pages = 1))
cap("orderbook", market$get_full_orderbook("BTC-USDT"))

# ---------------------------------------------------------------------------
# Margin data (public + one authed risk-limit)
# ---------------------------------------------------------------------------
cat("\n== Margin data ==\n")
margin_data <- install_capture(KucoinMarginData$new(keys = keys))
cap("cross_margin_symbols", margin_data$get_cross_margin_symbols())
cap("isolated_margin_symbols", margin_data$get_isolated_margin_symbols())
cap("margin_config", margin_data$get_margin_config())
cap("collateral_ratio", margin_data$get_collateral_ratio())
cap("risk_limit", margin_data$get_risk_limit(isIsolated = FALSE))

# ---------------------------------------------------------------------------
# Lending (public rate + authed reads)
# ---------------------------------------------------------------------------
cat("\n== Lending ==\n")
lending <- install_capture(KucoinLending$new(keys = keys))
cap("loan_market_rate", lending$get_loan_market_rate("USDT"))
cap("loan_market", lending$get_loan_market())
cap("purchase_orders", lending$get_purchase_orders(query = list(currency = "USDT", status = "DONE")))
cap("redeem_orders", lending$get_redeem_orders(query = list(currency = "USDT", status = "DONE")))

# ---------------------------------------------------------------------------
# Account (authed reads)
# ---------------------------------------------------------------------------
if (have_keys) {
  cat("\n== Account (authed) ==\n")
  account <- install_capture(KucoinAccount$new(keys = keys))
  cap("account_summary", account$get_summary())
  cap("apikey_info", account$get_apikey_info())
  cap("spot_accounts", account$get_spot_accounts())
  cap("cross_margin_account", account$get_cross_margin_account())
  cap("isolated_margin_account", account$get_isolated_margin_account())
  cap("base_fee_rate", account$get_base_fee_rate())
  cap("fee_rate", account$get_fee_rate("BTC-USDT"))
  cap("spot_ledger", account$get_spot_ledger(max_pages = 1))
  cap("hf_ledger", account$get_hf_ledger())

  cat("\n== Trading (authed reads) ==\n")
  trading <- install_capture(KucoinTrading$new(keys = keys))
  cap("symbols_open_orders", trading$get_symbols_with_open_orders())
  cap("open_orders", trading$get_open_orders(symbol = "BTC-USDT"))
  cap("closed_orders", trading$get_closed_orders(symbol = "BTC-USDT"))
  cap("fills", trading$get_fills(symbol = "BTC-USDT"))
  cap("dcp", trading$get_dcp())

  cat("\n== Stop / OCO / Deposit / Withdrawal / Transfer / Sub ==\n")
  stop_orders <- install_capture(KucoinStopOrders$new(keys = keys))
  cap("stop_order_list", stop_orders$get_order_list())
  oco_orders <- install_capture(KucoinOcoOrders$new(keys = keys))
  cap("oco_order_list", oco_orders$get_order_list())
  deposit <- install_capture(KucoinDeposit$new(keys = keys))
  cap("deposit_addresses", deposit$get_deposit_addresses(currency = "BTC"))
  cap("deposit_history", deposit$get_deposit_history(max_pages = 1))
  withdrawal <- install_capture(KucoinWithdrawal$new(keys = keys))
  cap("withdrawal_quotas", withdrawal$get_withdrawal_quotas("BTC"))
  cap("withdrawal_history", withdrawal$get_withdrawal_history(page_size = 10, max_pages = 1))
  transfer <- install_capture(KucoinTransfer$new(keys = keys))
  cap("transferable", transfer$get_transferable(currency = "USDT", type = "MAIN"))
  sub_account <- install_capture(KucoinSubAccount$new(keys = keys))
  cap("sub_accounts_list", sub_account$get_sub_account_list(page_size = 10, max_pages = 1))
  cap("sub_spot_balances", sub_account$get_all_spot_balances(page_size = 10, max_pages = 1))

  cat("\n== Margin trading (authed reads) ==\n")
  margin_trading <- install_capture(KucoinMarginTrading$new(keys = keys))
  cap("borrow_history", margin_trading$get_borrow_history())
  cap("repay_history", margin_trading$get_repay_history())
  cap("interest_history", margin_trading$get_interest_history())
  cap("borrow_rate", margin_trading$get_borrow_rate())
}

# ---------------------------------------------------------------------------
# Futures public market data
# ---------------------------------------------------------------------------
cat("\n== Futures public market data ==\n")
futures_market <- install_capture(KucoinFuturesMarketData$new(keys = keys))
cap("futures_server_time", futures_market$get_server_time())
cap("futures_service_status", futures_market$get_service_status())
cap("futures_all_contracts", futures_market$get_all_contracts())
cap("futures_contract", futures_market$get_contract("XBTUSDTM"))
cap("futures_ticker", futures_market$get_ticker("XBTUSDTM"))
cap("futures_all_tickers", futures_market$get_all_tickers())
cap("futures_orderbook_part", futures_market$get_part_orderbook("XBTUSDTM", size = 20))
cap("futures_trade_history", futures_market$get_trade_history("XBTUSDTM"))
cap("futures_klines", futures_market$get_klines("XBTUSDTM", granularity = 60))
cap("futures_mark_price", futures_market$get_mark_price("XBTUSDTM"))
cap("futures_funding_rate", futures_market$get_funding_rate("XBTUSDTM"))
cap("futures_funding_history", futures_market$get_funding_history(
  "XBTUSDTM", from = now_ms() - 7 * 86400 * 1000, to = now_ms()
))
cap("futures_orderbook", futures_market$get_full_orderbook("XBTUSDTM"))

# ---------------------------------------------------------------------------
# Futures authed reads
# ---------------------------------------------------------------------------
if (have_keys) {
  cat("\n== Futures account (authed) ==\n")
  futures_account <- install_capture(KucoinFuturesAccount$new(keys = keys))
  cap("futures_account_overview", futures_account$get_account_overview("USDT"))
  cap("futures_position", futures_account$get_positions())
  cap("futures_positions_history", futures_account$get_positions_history())
  cap("futures_risk_limit", futures_account$get_risk_limit("XBTUSDTM"))
  cap("futures_margin_mode", futures_account$get_margin_mode("XBTUSDTM"))
  cap("futures_cross_leverage", futures_account$get_cross_margin_leverage("XBTUSDTM"))
  cap("futures_max_open_size", futures_account$get_max_open_size("XBTUSDTM", price = 40000, leverage = 10))
  cap("futures_max_withdraw_margin", futures_account$get_max_withdraw_margin("XBTUSDTM"))

  cat("\n== Futures trading (authed reads) ==\n")
  futures_trading <- install_capture(KucoinFuturesTrading$new(keys = keys))
  cap("futures_order_list", futures_trading$get_order_list())
  cap("futures_stop_orders", futures_trading$get_stop_orders())
  cap("futures_fills", futures_trading$get_recent_fills())
  cap("futures_open_order_value", futures_trading$get_open_order_value("XBTUSDTM"))
  cap("futures_dcp", futures_trading$get_dcp())
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
cat("\n== Summary ==\n")
rows <- .state$rows
states <- vapply(rows, function(r) r$state, character(1))
cat("POPULATED  :", sum(grepl("POPULATED", states)), "\n")
cat("EMPTY      :", sum(states == "EMPTY"), "\n")
cat("API errors :", sum(grepl("APIERR", states)), "\n")
cat("NO-WRITE   :", sum(states == "NO-WRITE"), "\n")
cat("PARSE-FAIL :", sum(vapply(rows, function(r) r$parse == "PARSE-FAIL", logical(1))), "\n")
cat("Total      :", length(states), "\n")
cat("\nCaptures written to", OUT_DIR, "\n")
