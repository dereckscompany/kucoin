# tests/testthat/helper-constants.R
# Shared constants and constructor helpers for mocked-HTTP tests.
# `testthat` auto-sources every `helper-*.R` file in this directory
# before any test runs, so these are available everywhere without an
# explicit source().

# ---------------------------------------------------------------------------
# URL constants
# ---------------------------------------------------------------------------

# Live KuCoin REST endpoints. We pass these explicitly through the
# constructors so a test never accidentally hits the real network — the
# `httr2::local_mocked_responses()` setup short-circuits transport
# regardless of URL, but pinning the URL keeps test intent obvious.
BASE_SPOT <- "https://api.kucoin.com"
BASE_FUTURES <- "https://api-futures.kucoin.com"

# ---------------------------------------------------------------------------
# Dummy credentials
# ---------------------------------------------------------------------------

# Single shared set of dummy credentials. Never sent over the wire —
# tests mock the HTTP transport — but the request-builder still expects
# them to look syntactically valid (non-empty strings).
TEST_KEYS <- get_api_keys(
  api_key = "k",
  api_secret = "s",
  api_passphrase = "p"
)

# ---------------------------------------------------------------------------
# Default trading symbols
# ---------------------------------------------------------------------------

# Conventional defaults for fixture symbols. Most tests don't care which
# pair they exercise, only that the parser handles the response shape.
# Tests that DO care (futures-only endpoints, OCO-specific behaviour, …)
# pass an explicit symbol.
TEST_SYMBOL_SPOT <- "BTC-USDT"
TEST_SYMBOL_FUTURES <- "XBTUSDTM"

# ---------------------------------------------------------------------------
# R6 constructor helpers
# ---------------------------------------------------------------------------

# One helper per R6 class so tests read `new_oco()$cancel_all(...)`
# instead of repeating the 5-line constructor scaffold. Naming:
# spot wrappers keep their short name; futures wrappers carry an
# explicit `futures_` segment to avoid the two `new_account` /
# `new_trading` / `new_market` name collisions that existed before.

new_account <- function() {
  return(KucoinAccount$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_deposit <- function() {
  return(KucoinDeposit$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_lending <- function() {
  return(KucoinLending$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_margin <- function() {
  return(KucoinMarginTrading$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_margin_data <- function() {
  return(KucoinMarginData$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_market <- function() {
  return(KucoinMarketData$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_oco <- function() {
  return(KucoinOcoOrders$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_stop <- function() {
  return(KucoinStopOrders$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_sub <- function() {
  return(KucoinSubAccount$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_trading <- function() {
  return(KucoinTrading$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_transfer <- function() {
  return(KucoinTransfer$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_withdrawal <- function() {
  return(KucoinWithdrawal$new(keys = TEST_KEYS, base_url = BASE_SPOT))
}

new_futures_account <- function() {
  return(KucoinFuturesAccount$new(keys = TEST_KEYS, base_url = BASE_FUTURES))
}

new_futures_market <- function() {
  return(KucoinFuturesMarketData$new(keys = TEST_KEYS, base_url = BASE_FUTURES))
}

new_futures_trading <- function() {
  return(KucoinFuturesTrading$new(keys = TEST_KEYS, base_url = BASE_FUTURES))
}
