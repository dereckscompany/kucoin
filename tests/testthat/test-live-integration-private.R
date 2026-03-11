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
  dt <- margin_data_auth$get_risk_limit(isIsolated = FALSE)
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
