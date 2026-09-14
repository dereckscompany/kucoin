# Precision regression: every numeric field KuCoin reports as a decimal
# STRING must survive parsing at full double precision, and every field that
# is deliberately left alone (an identifier such as the ticker's `sequence`)
# must be returned byte-identical -- never silently swept into the numeric
# coercion. No round(), signif(), sprintf("%.Nf"), format(nsmall = ), or other
# narrowing cast may ever sit between the venue's own decimal string and what
# this package returns.
#
# Why this test exists: on 2026-09-13 the fleet found every Hyperliquid candle
# in the data lake had been stored to four decimal places for months -- a coin
# priced below a cent (e.g. "0.000212") lost almost all of its information,
# and a strategy that ranks coins by calmness ranked them wrongly as a direct
# result. The cause traced to a re-serialisation default in the data scraper
# (since fixed), NOT to the venue connectors: this package's own parse path
# was proven correct at every step. KuCoin is unusual among the fleet's
# connectors in doing this coercion in TWO places: `parse_klines()`
# (R/helpers_parse.R) casts the kline OHLCV fields inline with a plain
# `as.numeric()`, while every OTHER endpoint (including `get_ticker()`, whose
# own parser leaves the response untouched) is swept by a single shared
# `coerce_numeric_quantities()` -- applied centrally by `KucoinBase$.request()`
# to every parser's output -- which converts a fixed whitelist of ~150
# price/size/rate/balance column names via `coerce_cols(x, quantities,
# as.numeric)`, explicitly leaving identifiers, symbols, statuses and enums
# untouched. Both are plain `as.numeric()`, with no rounding anywhere. This
# test pins that fact for KuCoin so the layer that is currently correct STAYS
# correct: if anyone later adds a round()/signif()/sprintf("%.4f")/
# format(nsmall = ) or a narrowing cast to either coercion path, it fails
# immediately.
#
# Drives the real public client methods (get_klines / get_ticker) through the
# shared connectcore mock harness (a URL-pattern route table +
# local_mock_api()), the same way mock_router.R wires the README and
# vignettes, with a synthetic fixture authored as raw JSON text (never built
# from an R list + jsonlite::toJSON()) so the exact wire digits/strings below
# are what the parser actually sees -- never a private helper reimplemented
# here. `new_market()`, `TEST_KEYS`, and `BASE_SPOT` come from
# tests/testthat/helper-constants.R, already auto-loaded for every test file.
# Uses expect_identical() throughout, never expect_equal()'s tolerance,
# because tolerance is exactly what would hide this defect.

# ---- fixture: decimal strings with many significant digits ------------------

# A value just under 2^53 (the largest integer a double represents exactly),
# used as a character-typed identifier (the ticker's `sequence`) to prove an
# identifier column is never accidentally swept into the numeric coercion.
.precision_big_id <- "9007199254740991"

.precision_strings <- list(
  a = "0.00023456789",
  b = "12345.678901234",
  c = "0.000000123456",
  d = "1e-10"
)

# The klines endpoint returns positional string arrays
# [timestamp, open, close, high, low, volume, turnover] -- authored as literal
# text so the exact wire digits below are what the parser actually sees.
.precision_klines_json <- sprintf(
  paste0(
    '{"code":"200000","data":[["1700000000","%s","%s","%s","%s","%s","%s"]]}'
  ),
  .precision_strings$a,
  .precision_strings$d,
  .precision_strings$b,
  .precision_strings$c,
  .precision_strings$b,
  .precision_strings$a
)

# The level1 ticker sends every quantity as a quoted decimal string and the
# identifier `sequence` as a quoted (large) integer string.
.precision_ticker_json <- sprintf(
  paste0(
    '{"code":"200000","data":{"sequence":"%s","price":"%s","size":"%s",',
    '"bestBid":"%s","bestBidSize":"%s","bestAsk":"%s","bestAskSize":"%s",',
    '"time":1700000000000}}'
  ),
  .precision_big_id,
  .precision_strings$a,
  .precision_strings$b,
  .precision_strings$c,
  .precision_strings$d,
  .precision_strings$a,
  .precision_strings$b
)

# A tiny URL-pattern route table covering exactly the two endpoints this test
# drives, built the same way the shared mock_router.R does, but with a
# synthetic high-precision fixture instead of the captured/synthetic
# real-shaped fixtures.
precision_routes <- function() {
  return(list(
    list(pattern = "market/orderbook/level1", fixture = .precision_ticker_json),
    list(pattern = "market/candles", fixture = .precision_klines_json)
  ))
}

# A shared digit-level check: sprintf("%.17g", .) prints enough significant
# digits to uniquely round-trip an IEEE-754 double, so if the parser silently
# narrowed the value (round()/signif()/a %.Nf format), the 17-digit rendering
# of the parsed value would diverge from the 17-digit rendering of the
# fixture's own as.numeric() value.
expect_full_precision <- function(actual, fixture_string) {
  expected <- as.numeric(fixture_string)
  expect_identical(actual, expected)
  return(expect_identical(sprintf("%.17g", actual), sprintf("%.17g", expected)))
}

# ---- candle/kline path: get_klines -------------------------------------------

test_that("get_klines preserves full OHLCV precision through the real parse path", {
  connectcore::local_mock_api(precision_routes())
  dt <- new_market()$get_klines("BTC-USDT", timeframe = "1hour")

  expect_identical(nrow(dt), 1L)
  expect_full_precision(dt$open, .precision_strings$a)
  expect_full_precision(dt$close, .precision_strings$d)
  expect_full_precision(dt$high, .precision_strings$b)
  expect_full_precision(dt$low, .precision_strings$c)
  expect_full_precision(dt$volume, .precision_strings$b)
  expect_full_precision(dt$turnover, .precision_strings$a)
})

# ---- ticker/market-data snapshot path: get_ticker ----------------------------

test_that("get_ticker preserves full price precision and leaves the identifier untouched", {
  connectcore::local_mock_api(precision_routes())
  dt <- new_market()$get_ticker("BTC-USDT")

  expect_identical(nrow(dt), 1L)
  expect_full_precision(dt$price, .precision_strings$a)
  expect_full_precision(dt$size, .precision_strings$b)
  expect_full_precision(dt$best_bid, .precision_strings$c)
  expect_full_precision(dt$best_bid_size, .precision_strings$d)
  expect_full_precision(dt$best_ask, .precision_strings$a)
  expect_full_precision(dt$best_ask_size, .precision_strings$b)
  # `sequence` is an identifier, explicitly excluded from
  # coerce_numeric_quantities()'s whitelist, and must stay exactly as KuCoin
  # sent it: character, byte-identical, never swept up by the shared
  # coercion.
  expect_type(dt$sequence, "character")
  expect_identical(dt$sequence, .precision_big_id)
})
