# tests/testthat/test-live-integration-private.R
# Live integration tests for authenticated endpoints.
# These hit the real KuCoin API — no mocking.
# Requires API keys set via environment variables.
# Requires env vars: KUCOIN_API_KEY, KUCOIN_API_SECRET, KUCOIN_API_PASSPHRASE
#
# Write tests only use the /orders/test endpoint (dry-run, no real execution).
#
# Run with:
#   KUCOIN_LIVE_TESTS=true Rscript -e 'devtools::test(filter = "live")'

skip_if_not(
  identical(Sys.getenv("KUCOIN_LIVE_TESTS"), "true"),
  "Live API tests skipped (set KUCOIN_LIVE_TESTS=true to run)"
)

.api_key <- Sys.getenv("KUCOIN_API_KEY", "")
.api_secret <- Sys.getenv("KUCOIN_API_SECRET", "")
.api_passphrase <- Sys.getenv("KUCOIN_API_PASSPHRASE", "")

skip_if(
  .api_key == "" || .api_secret == "" || .api_passphrase == "",
  "No API keys configured (set KUCOIN_API_KEY + KUCOIN_API_SECRET + KUCOIN_API_PASSPHRASE)"
)

.keys <- get_api_keys(
  api_key = .api_key,
  api_secret = .api_secret,
  api_passphrase = .api_passphrase
)

# Rate limit helper
throttle <- function() Sys.sleep(0.5)

# =============================================================================
# KucoinAccount — Read-only
# =============================================================================

account <- KucoinAccount$new(keys = .keys)

test_that("[LIVE] get_summary returns data.table with account info", {
  dt <- account$get_summary()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

test_that("[LIVE] get_apikey_info returns data.table", {
  dt <- account$get_apikey_info()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

test_that("[LIVE] get_spot_account_type returns logical", {
  result <- account$get_spot_account_type()
  expect_type(result, "logical")
  expect_length(result, 1L)
  throttle()
})

test_that("[LIVE] get_spot_accounts returns data.table", {
  dt <- account$get_spot_accounts()
  expect_s3_class(dt, "data.table")
  # May be empty if no balances, but should still be data.table
  if (nrow(dt) > 0) {
    expect_true(all(c("currency", "balance", "available") %in% names(dt)))
  }
  throttle()
})

test_that("[LIVE] get_cross_margin_account returns data.table", {
  dt <- account$get_cross_margin_account()
  expect_s3_class(dt, "data.table")
  # May be empty if margin not activated
  throttle()
})

test_that("[LIVE] get_isolated_margin_account returns data.table", {
  dt <- account$get_isolated_margin_account()
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_base_fee_rate returns data.table", {
  dt <- account$get_base_fee_rate()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("taker_fee_rate", "maker_fee_rate") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_fee_rate returns data.table for BTC-USDT", {
  dt <- account$get_fee_rate("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) >= 1L)
  expect_true(all(c("symbol", "taker_fee_rate", "maker_fee_rate") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_spot_ledger returns data.table", {
  dt <- account$get_spot_ledger(max_pages = 1)
  expect_s3_class(dt, "data.table")
  # May be empty on a fresh account
  if (nrow(dt) > 0) {
    expect_true("created_at" %in% names(dt))
  }
  throttle()
})

test_that("[LIVE] get_hf_ledger returns data.table", {
  dt <- account$get_hf_ledger()
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinTrading — Read-only getters
# =============================================================================

trading <- KucoinTrading$new(keys = .keys)

test_that("[LIVE] get_symbols_with_open_orders returns data.table", {
  dt <- trading$get_symbols_with_open_orders()
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_open_orders returns data.table", {
  dt <- trading$get_open_orders(symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_closed_orders returns data.table", {
  dt <- trading$get_closed_orders(symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_fills returns data.table", {
  dt <- trading$get_fills(symbol = "BTC-USDT")
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true(all(c("symbol", "side", "price", "size") %in% names(dt)))
  }
  throttle()
})

test_that("[LIVE] get_dcp returns data.table", {
  dt <- trading$get_dcp()
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinTrading — Write (test endpoint only, no real orders)
# =============================================================================

test_that("[LIVE] add_order_test validates a limit order without executing", {
  dt <- trading$add_order_test(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = 10000,
    size = 0.00001
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("order_id" %in% names(dt))
  throttle()
})

test_that("[LIVE] add_order_test validates a market order without executing", {
  dt <- trading$add_order_test(
    type = "market",
    symbol = "BTC-USDT",
    side = "buy",
    funds = 10
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

# =============================================================================
# KucoinStopOrders — Read-only
# =============================================================================

stop_orders <- KucoinStopOrders$new(keys = .keys)

test_that("[LIVE] stop_orders get_order_list returns data.table", {
  dt <- stop_orders$get_order_list()
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinOcoOrders — Read-only
# =============================================================================

oco_orders <- KucoinOcoOrders$new(keys = .keys)

test_that("[LIVE] oco_orders get_order_list returns data.table", {
  dt <- oco_orders$get_order_list()
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinDeposit — Read-only
# =============================================================================

deposit <- KucoinDeposit$new(keys = .keys)

test_that("[LIVE] get_deposit_addresses returns data.table for BTC", {
  dt <- deposit$get_deposit_addresses(currency = "BTC")
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("address" %in% names(dt))
  }
  throttle()
})

test_that("[LIVE] get_deposit_history returns data.table", {
  dt <- deposit$get_deposit_history(max_pages = 1)
  expect_s3_class(dt, "data.table")
  if (nrow(dt) > 0) {
    expect_true("created_at" %in% names(dt))
  }
  throttle()
})

# =============================================================================
# KucoinWithdrawal — Read-only
# =============================================================================

withdrawal <- KucoinWithdrawal$new(keys = .keys)

test_that("[LIVE] get_withdrawal_quotas returns data.table for BTC", {
  dt <- withdrawal$get_withdrawal_quotas("BTC")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("currency" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_withdrawal_history returns data.table", {
  dt <- withdrawal$get_withdrawal_history(page_size = 10, max_pages = 1)
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinTransfer — Read-only
# =============================================================================

transfer <- KucoinTransfer$new(keys = .keys)

test_that("[LIVE] get_transferable returns data.table", {
  dt <- transfer$get_transferable(currency = "USDT", type = "MAIN")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

# =============================================================================
# KucoinSubAccount — Read-only
# =============================================================================

sub_account <- KucoinSubAccount$new(keys = .keys)

test_that("[LIVE] get_sub_account_list returns data.table", {
  dt <- sub_account$get_sub_account_list(page_size = 10, max_pages = 1)
  expect_s3_class(dt, "data.table")
  # May be empty if no sub-accounts
  throttle()
})

test_that("[LIVE] get_all_spot_balances returns data.table", {
  dt <- sub_account$get_all_spot_balances(page_size = 10, max_pages = 1)
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinMarketData — Authenticated endpoint
# =============================================================================

market_auth <- KucoinMarketData$new(keys = .keys)

test_that("[LIVE] get_full_orderbook returns data.table for BTC-USDT", {
  dt <- market_auth$get_full_orderbook("BTC-USDT")
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true(all(c("side", "price", "size") %in% names(dt)))
  expect_true(all(dt$side %in% c("bid", "ask")))
  throttle()
})

# =============================================================================
# KucoinMarginData — Authenticated endpoint
# =============================================================================

margin_data_auth <- KucoinMarginData$new(keys = .keys)

test_that("[LIVE] get_risk_limit returns data.table for cross margin", {
  dt <- margin_data_auth$get_risk_limit(is_isolated = FALSE)
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("currency" %in% names(dt))
  throttle()
})

# =============================================================================
# KucoinMarginTrading — Read-only
# =============================================================================

margin_trading <- KucoinMarginTrading$new(keys = .keys)

test_that("[LIVE] get_borrow_history returns data.table", {
  dt <- margin_trading$get_borrow_history()
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_repay_history returns data.table", {
  dt <- margin_trading$get_repay_history()
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_interest_history returns data.table", {
  dt <- margin_trading$get_interest_history()
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_borrow_rate returns data.table", {
  dt <- margin_trading$get_borrow_rate()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  throttle()
})

# =============================================================================
# KucoinLending — Read-only (authenticated)
# =============================================================================

lending_auth <- KucoinLending$new(keys = .keys)

test_that("[LIVE] get_loan_market returns data.table", {
  dt <- lending_auth$get_loan_market()
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  expect_true("currency" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_purchase_orders returns data.table", {
  dt <- lending_auth$get_purchase_orders(query = list(currency = "USDT", status = "DONE"))
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] get_redeem_orders returns data.table", {
  dt <- lending_auth$get_redeem_orders(query = list(currency = "USDT", status = "DONE"))
  expect_s3_class(dt, "data.table")
  throttle()
})

# =============================================================================
# KucoinFuturesAccount — Authenticated read-only
# =============================================================================
#
# These cover the path-corrected GET methods in v4.0.2 (`get_margin_mode`,
# `get_cross_margin_leverage`, `get_max_open_size`, `get_max_withdraw_margin`).
# If KuCoin moves a futures endpoint again, these surface the 404 in CI
# rather than waiting for a user report.
#
# Each call wraps in `tryCatch()`: if the response indicates the account has
# no futures wallet (KuCoin error codes 200004 = position-not-found,
# 100001 = invalid-symbol-for-account-type, or HTTP 401 on no-futures-perm),
# the test SKIPs rather than fails. That way the suite stays usable for
# users without a funded futures sub-account.
#
# Write methods (`set_margin_mode`, `set_cross_margin_leverage`,
# `add_isolated_margin`, `remove_isolated_margin`) are deliberately NOT
# exercised — they require real positions / funds and the operational risk
# isn't worth catching the next docs reorganisation.

futures_account <- KucoinFuturesAccount$new(keys = .keys)

# Helper: if the API returns a futures-account-not-found / no-perm error,
# skip the test instead of failing. Distinguishes between "endpoint dead"
# (the regression we want to catch — should fail) and "account has no
# futures wallet" (user environment, should skip).
.skip_if_no_futures <- function(err) {
  msg <- conditionMessage(err)
  no_account_signals <- c(
    "200004", # position not found
    "400003", # KC-API-KEY not exists / wrong key type
    "411100", # user is frozen
    "100001", # invalid symbol
    "HTTP 401"
  )
  if (any(vapply(no_account_signals, function(s) grepl(s, msg, fixed = TRUE), logical(1)))) {
    testthat::skip(paste("No accessible futures account:", msg))
  }
  stop(err)
}

test_that("[LIVE] futures get_account_overview returns data.table for USDT", {
  dt <- tryCatch(
    futures_account$get_account_overview("USDT"),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

test_that("[LIVE] futures get_positions returns data.table", {
  dt <- tryCatch(
    futures_account$get_positions(),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_margin_mode returns data.table (path-corrected in 4.0.2)", {
  dt <- tryCatch(
    futures_account$get_margin_mode("XBTUSDTM"),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

test_that("[LIVE] futures get_cross_margin_leverage returns data.table (path-corrected in 4.0.2)", {
  dt <- tryCatch(
    futures_account$get_cross_margin_leverage("XBTUSDTM"),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  throttle()
})

test_that("[LIVE] futures get_max_open_size returns data.table (path-corrected in 4.0.2)", {
  dt <- tryCatch(
    futures_account$get_max_open_size("XBTUSDTM", price = 40000, leverage = 10),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_max_withdraw_margin returns data.table (path-corrected in 4.0.2)", {
  dt <- tryCatch(
    futures_account$get_max_withdraw_margin("XBTUSDTM"),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_risk_limit returns data.table for XBTUSDTM", {
  dt <- tryCatch(
    futures_account$get_risk_limit("XBTUSDTM"),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  expect_true(nrow(dt) > 0)
  throttle()
})

# =============================================================================
# KucoinFuturesMarketData — Authenticated read-only
# =============================================================================

futures_market_auth <- KucoinFuturesMarketData$new(keys = .keys)

test_that("[LIVE] futures get_full_orderbook returns data.table (path-corrected in 4.0.2)", {
  dt <- tryCatch(
    futures_market_auth$get_full_orderbook("XBTUSDTM"),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  expect_true(all(c("ts", "sequence", "side", "level", "price", "size") %in% names(dt)))
  expect_true(nrow(dt) > 0)
  throttle()
})

# =============================================================================
# KucoinFuturesTrading — Authenticated read-only
# =============================================================================

futures_trading <- KucoinFuturesTrading$new(keys = .keys)

test_that("[LIVE] futures get_order_list returns data.table", {
  dt <- tryCatch(
    futures_trading$get_order_list(),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_stop_orders returns data.table (path-refreshed in 4.0.2)", {
  dt <- tryCatch(
    futures_trading$get_stop_orders(),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures get_recent_fills returns data.table (path-refreshed in 4.0.2)", {
  dt <- tryCatch(
    futures_trading$get_recent_fills(),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

# Futures DCP migrated to the unified `/api/ua/v1/dcp/*` endpoint in
# v4.0.3 — the legacy `/api/v1/orders/dead-cancel-all*` paths returned
# 404/403 after KuCoin's 2026-05 reorganisation. These tests pin the
# new endpoint so the next time KuCoin moves DCP, CI catches it.

test_that("[LIVE] futures get_dcp returns data.table via unified endpoint", {
  dt <- tryCatch(
    futures_trading$get_dcp(),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] futures set_dcp -1 disables and returns data.table via unified endpoint", {
  # Use `timeout = -1` (disable) so this test has no real side effects:
  # it cannot accidentally leave a live dead-man's switch armed on the
  # account if a later test fails to clear it.
  dt <- tryCatch(
    futures_trading$set_dcp(timeout = -1),
    error = .skip_if_no_futures
  )
  expect_s3_class(dt, "data.table")
  throttle()
})
