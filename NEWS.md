# kucoin 4.0.0

## NEW FEATURES

* **Margin Trading — `KucoinMarginTrading` class** (9 endpoints): intent-based wrappers (`open_short`, `close_short`, `open_long`, `close_long`), `borrow`, `repay`, borrow/repay/interest history, borrow rate, leverage modification.
* **Margin Market Data — `KucoinMarginData` class** (5 endpoints): cross-margin symbols, isolated-margin symbols, margin config, collateral ratios, risk limits.
* **Lending — `KucoinLending` class** (7 endpoints): loan market data, market interest rates, purchase (lend), modify purchase, purchase/redeem orders, redeem.
* **KuCoin Futures API support** — three new R6 classes covering 44 endpoints:
    - `KucoinFuturesMarketData` (13 endpoints): contract details, tickers, orderbooks, trade history, klines, mark prices, funding rates, funding history, server time, service status.
    - `KucoinFuturesTrading` (17 endpoints): place/cancel/query futures orders (single, batch, test), stop orders, fills, open order value, Dead Connection Protection (DCP).
    - `KucoinFuturesAccount` (14 endpoints): account overview, positions, position history, margin mode, cross margin leverage, max open size, add/remove isolated margin, risk limits, funding history.
* **`get_futures_base_url()`**: New helper for the Futures API base URL (`https://api-futures.kucoin.com`), configurable via `KUCOIN_FUTURES_API_ENDPOINT` env var.
* **Futures-specific parsers**: `parse_futures_orderbook()` and `parse_futures_klines()` handle the different data formats (numeric values vs strings, nanosecond timestamps, OHLC column order).
* **Margin order validation**: `validate_margin_order_params()` helper for margin-specific order parameter checking with auto-generated `clientOid`.

## BREAKING CHANGES

* **Version bump 3.0.0 → 4.0.0**.
* **Timestamp columns no longer renamed**: All API timestamp fields now keep their original snake_case names instead of being renamed to `datetime_*` prefixed names. Timestamps are coerced to POSIXct in-place. No fields are dropped. Migration guide:
    - `datetime_created` → `created_at` (most classes)
    - `datetime_created` → `created_time` (`KucoinMarginTrading`)
    - `datetime_created` → `c_time` (`KucoinMarketData$get_announcements()`)
    - `datetime_updated` → `last_updated_at` (`KucoinTrading`)
    - `datetime_order` → `order_time` (`KucoinOcoOrders`)
    - `datetime_match` → `match_time` (`KucoinTrading$add_order_sync()`)
    - `datetime_applied` → `apply_time` (`KucoinLending`)
    - `datetime` → `time` (ticker, trade history, orderbook, 24hr stats)
* **Kline parameter renamed**: `freq` → `timeframe` in `kucoin_backfill_klines()` and related functions.
* **`KucoinMarketData$get_klines()` default window changed**: with `from = NULL`/`to = NULL` the method now returns the most recent candles for the requested timeframe rather than the previous "last 24 hours" window. Pass explicit `from`/`to` to restore deterministic ranges.
* **`KucoinDeposit$get_deposit_addresses()`**: `currency` is now a required argument (removed `NULL` default) to match KuCoin API requirement.

## BUG FIXES

* Fixed `KucoinMarginData$get_cross_margin_symbols()` parser to handle KuCoin's new `{timestamp, items}` response envelope. Previously returned garbled columns (`v1`, `v2`, ...) instead of proper data.
* Fixed `KucoinLending$get_loan_market()` — KuCoin now requires authentication for `/api/v3/project/list`. Removed erroneous `auth = FALSE`.
* Removed usage of `%||%` operator which was not defined or imported; replaced with explicit `if (is.null(...))` checks.
* Fixed `URLencode()` in request signing to coerce query values to character before encoding, preventing errors on numeric parameters.
* `KucoinMarginTrading$repay()` now coerces the response `timestamp` to `POSIXct` instead of leaving it as a raw millisecond `numeric`, matching the rest of the package's timestamp behaviour.
* `KucoinMarginData$get_margin_config()` now returns a schema-stable zero-row `data.table` when `currencyList` is empty or `data` is `NULL`, rather than indexing into an empty row.
* **Orderbook parsers gain a `level` depth column**. `parse_orderbook()` (spot) and `parse_futures_orderbook()` (futures) now emit a 1-indexed position column per side so the on-wire "best price first" ordering survives any later sort or filter (`level == 1` is best bid / best ask). Affects `KucoinMarketData$get_part_orderbook()`, `KucoinMarketData$get_full_orderbook()`, `KucoinFuturesMarketData$get_part_orderbook()`, and `KucoinFuturesMarketData$get_full_orderbook()`.
* **Cancel-parser NULL / empty-`cancelledOrderIds` guards** on every cancel method that returns `cancelled_order_id` long-format rows. Previously a NULL response or an empty `cancelledOrderIds` array could trigger row-replication errors; the parsers now short-circuit to a zero-row `data.table` with the documented schema. Affects `KucoinOcoOrders` (3 methods), `KucoinFuturesTrading` (3 methods).
* **`KucoinSubAccount` `account_type` semantic labels**. `get_detail_balance()` and `get_all_spot_balances()` previously emitted the raw response field names (`main_accounts`, `trade_accounts`, `margin_accounts`); these are now the stable semantic labels `"main"`, `"trade"`, `"margin"` so the documented filter idiom `balances[account_type == "trade"]` keeps working.
* `ms_to_datetime()` / `ns_to_datetime()` (and the alpaca equivalent `rfc3339_to_datetime`) no longer short-circuit on `all(is.na(x))` input. The short-circuit returned a length-1 `NA_POSIXct_` which `data.table::set()` would recycle into the existing column's storage type rather than replacing the column with POSIXct — so all-NA timestamp columns were silently typed as `character`/`numeric` instead of `POSIXct`. The helpers now always produce a length-matching POSIXct vector, even when every input value is missing.
* **`ms_to_datetime()` / `ns_to_datetime()` no longer emit spurious `"NAs introduced by coercion"` warnings** when given an all-`NA_character_` vector. The NA → NA path is the documented contract, not a problem worth a warning. Implemented by type-dispatching on the input and only feeding the non-NA entries to `as.numeric()` — not `suppressWarnings()`, which would hide genuine bad input (e.g. a malformed numeric string from a future API change). Pinned by a counter-regression test that asserts `ms_to_datetime("not-a-number")` still warns loudly.
* **`coerce_cols(dt, cols, fn)` deduplicates `cols`**. Previously passing the same column name twice — `coerce_cols(dt, c("time", "time"), ms_to_datetime)` — would feed the already-coerced POSIXct value back through `ms_to_datetime`, reinterpreting epoch-seconds as epoch-ms and silently producing wildly wrong values (year 56,000+). Now uses `for (col in unique(cols))`. Same fix applied to the binance and alpaca helpers.

## IMPROVEMENTS

* **One-entity-per-row, no-list-column convention across every R6 class.** Sweeping pass on all 16 classes to eliminate `data.table` list columns and standardise on one of five shape treatments (`;`-collapse for arrays of plain strings; long-format explode for arrays of objects, with a 1-indexed position column where order matters; wide-prefix flatten for fixed-schema nested objects; sibling-method re-route for collections that don't fit the row entity; JSON-string encode for dynamic-key or array-of-array objects). Matches the convention in the sibling `alpaca` and `binance` packages — see the new `vignette("data-shapes")`.
* **Consistent `data.table` returns**: All parsers now return `data.table` objects. Fixed four methods that previously returned other types:
    - `KucoinTrading$cancel_all_by_symbol()`: was `character`, now `data.table` with `result` column.
    - `KucoinMarketData$get_market_list()`: was `character` vector, now `data.table` with `market` column.
    - `KucoinMarginData$get_margin_config()`: was raw `list`, now long-format `data.table` with one row per supported `currency`, plus `max_leverage`, `warning_debt_ratio`, `liq_debt_ratio`.
    - `KucoinMarginData$get_collateral_ratio()`: was raw `list`, now flattened `data.table` with `currency`, `lower_limit`, `upper_limit`, `collateral_ratio` columns.
* **`KucoinMarketData$get_announcements()`**: `ann_type` is now a `;`-collapsed character column (Treatment A) instead of either a list column or a long-format row explosion. Recover with `strsplit(x, ";", fixed = TRUE)[[1]]`. The shared `collapse_string_array_fields()` helper emits a once-per-session warning if a value ever contains a literal `;` so silent corruption is unmissable.
* **Shared internal helpers** (`@noRd`, ported from the binance package to keep the three packages' parser surface aligned):
    - `collapse_string_array_fields(x, fields)` — NA-safe Treatment A `;`-collapse.
    - `coerce_cols(dt, cols, fn)` — applies a coercion function to a set of columns by reference, silently skipping columns that aren't on the table. Replaces the repeated `if (nrow(dt) > 0 && "X" %in% names(dt)) { dt[, X := fn(X)] }` boilerplate across every parser.
* Increased default request timeout from 10s to 30s.
* `@import data.table` added centrally via `R/imports.R` to simplify namespace management.
* Support both `KC-API-KEY` and `KUCOIN_API_KEY` environment variable naming conventions.

## DOCUMENTATION

* Corrected parameter docs based on live API testing:
    - `KucoinTrading$get_open_orders()`: `symbol` is **required** (not optional).
    - `KucoinDeposit$get_deposit_addresses()`: `currency` is **required** (not optional).
    - `KucoinLending$get_purchase_orders()` / `get_redeem_orders()`: `status` is **required** in the query list.
    - `KucoinLending$get_loan_market()`: now documented as authenticated.
* Corrected `wrap_list_fields` / `as_dt_row` documentation to accurately describe `length >= 1` wrapping behavior.
* Expanded `@return` blocks across `KucoinMarginData`, `KucoinMarginTrading`, and `KucoinLending`: every public method now spells out its columns and their R types, the per-method row entity, and how the empty case is shaped — matching the binance/alpaca data-shape vignette.
* Updated `kucoin_btc_usdt_4h_ohlcv` dataset documentation to reflect 18,351 rows through March 2026.
* Three new vignettes: "Margin Trading", "Futures Trading", and "Data shapes and the one-row-per-entity convention".
* README gains a **Design Philosophy** section explaining the snake_case / timestamp / shape-normalisation contract and pointing at `vignette("data-shapes")` for the full catalogue. Mirrors the section the sibling `alpaca` / `binance` READMEs already carry.
* Updated ROADMAP to v4.0.0 with Futures classes added to completed items.

## TESTS

* Added 140 live integration tests gated behind `KUCOIN_LIVE_TESTS=true`:
    - `test-live-integration-public.R`: 21 tests covering all public endpoints (no auth required).
    - `test-live-integration-private.R`: 35 tests covering authenticated read-only endpoints plus `add_order_test` dry-run.
* New mocked test suites: `test-KucoinMarginTrading.R`, `test-KucoinMarginData.R`, `test-KucoinLending.R`, `test-KucoinFuturesMarketData.R`, `test-KucoinFuturesTrading.R`, `test-KucoinFuturesAccount.R`, `test-bug-hunt.R`, `test-fetch-all.R`.
* All live tests use `Sys.sleep(0.5)` rate limiting between calls.
* Write tests use only the `/orders/test` dry-run endpoint — no real orders placed.
* Added data-shape regression tests on `KucoinMarginData`, `KucoinMarginTrading`, and `KucoinLending`: each public method asserts there are no list columns, the column types match the documented `@return` block, and the empty-response path yields a zero-row `data.table` rather than a stub row.

## DATA

* Refreshed bundled `kucoin_btc_usdt_4h_ohlcv` dataset (18,351 rows, Oct 2017 – Mar 2026).

## TOOLING

* **`scripts/LINT.sh`** — new script that runs `air format .` first (so reformatted code is what gets linted, and a passing run leaves the working tree clean) then `lintr::lint_package()` with the package loaded via `devtools::load_all()` so `object_usage_linter` honours `utils::globalVariables()` declarations for `data.table` NSE columns. Matches the binance package's lint script with the air format step folded in.
* **`.lintr` config repaired**. The previous file started with a leading `# .lintr` comment that made the DCF parser reject it (`Malformed config file`) — `lintr::lint_package()` had been failing silently. Now adopts the binance ruleset: line length 120, indentation 2, explicit `return()` style, and `object_name_linter` allowing `snake_case` / `SNAKE_CASE` / `CamelCase` / `camelCase` so R6 class names and KuCoin's camelCase API params (`clientOid`, `orderId`) are accepted.

## REFACTOR

* **Explicit `return()` everywhere.** Every closure now has an explicit `return(...)` instead of relying on R's implicit-last-expression. Touches 78 sites across the package (9 in `R/`, 69 across `tests/` and `vignettes/`). Side-effect-only closures get `return(invisible(NULL))`.
* **No `var <- if (...)` style.** Three sites refactored to declare the variable with its default value and conditionally reassign instead (POSIXct-vs-epoch-ms coercion in `KucoinFuturesMarketData$get_klines()`; ticker mock alternation in `vignettes/async-usage.Rmd`). Function-call named args (`f(x = if (...) a else b)`) are out of scope for the rule and were left alone.
* **`tests/testthat/helper-constants.R`** — shared test-setup file (auto-sourced by `testthat` before tests). Defines `BASE_SPOT` / `BASE_FUTURES`, `TEST_KEYS`, `TEST_SYMBOL_SPOT` / `TEST_SYMBOL_FUTURES`, and one `new_xxx()` constructor helper per R6 class. Strips ~130 lines of duplicated setup boilerplate from the 14 test files; collapses 22 inline `KucoinMarketData$new(...)` calls in `test-KucoinMarketData.R` to `new_market()`. Resolves three name collisions that the per-file scoping had been hiding (`new_account`, `new_market`, `new_trading` now have explicit `new_futures_*` siblings).

## LICENCE

* **`LICENSE` consolidated to a single full MIT file**. The package previously shipped both a 2-line DCF stub (`LICENSE`) and the full MIT text (`LICENSE.md`), to satisfy the CRAN `License: MIT + file LICENSE` template alongside GitHub's licensee detector. Those two requirements conflict in practice. `DESCRIPTION` now declares `License: MIT` (non-CRAN form), so R CMD check skips the DCF parse of the LICENSE file while GitHub still detects MIT. The previously bundled **Citation Clause has been dropped** — the package is now plain MIT, matching the sibling `alpaca` and `binance` packages. `LICENSE.md` was removed; `LICENSE` carries the full text.

# kucoin 3.0.0

## BREAKING CHANGES

* Complete rewrite of the package architecture. All implementation functions are now wrapped in R6 classes inheriting from `KucoinBase`.
* Removed all v2 standalone functions (`kucoin_get_ticker()`, `kucoin_place_order()`, etc.). Use the corresponding R6 class methods instead.
* API credentials are now managed via environment variables (`KC-API-KEY`, `KC-API-SECRET`, `KC-API-PASSPHRASE`) or passed directly to class constructors through `get_api_keys()`.

## NEW FEATURES

* **R6 class architecture**: Ten R6 classes covering 77 KuCoin Classic Spot REST API endpoints:
    - `KucoinMarketData` (16 endpoints): announcements, currencies, symbols, tickers, orderbooks, trade history, 24hr stats, klines, market list, server time, service status, fiat prices.
    - `KucoinTrading` (21 endpoints): place/cancel/query HF spot orders (single, batch, test), sync variants, modify order, fills, open/closed order lists, Dead Connection Protection (DCP).
    - `KucoinStopOrders` (7 endpoints): place/cancel/query stop orders with trigger price support.
    - `KucoinOcoOrders` (8 endpoints): place/cancel/query OCO (One-Cancels-Other) orders.
    - `KucoinAccount` (11 endpoints): account summary, API key info, spot/margin account balances, ledger history, HF ledger, base and actual fee rates.
    - `KucoinDeposit` (3 endpoints): create deposit addresses, query addresses and deposit history.
    - `KucoinWithdrawal` (5 endpoints): create/cancel withdrawals, query quotas, history, and details.
    - `KucoinTransfer` (2 endpoints): universal internal transfers, transferable balance queries.
    - `KucoinSubAccount` (4 endpoints): create sub-accounts, list summaries, query balances.
    - `KucoinBase`: abstract base class with shared auth, request, pagination, and timestamp logic.
* **Sync order endpoints**: `add_order_sync()`, `add_order_batch_sync()`, `cancel_order_by_id_sync()`, `cancel_order_by_client_oid_sync()` — place or cancel orders and receive fill results in a single round trip.
* **Order modification**: `modify_order()` — amend price or size of an existing HF order in place.
* **Dead Connection Protection (DCP)**: `set_dcp()` / `get_dcp()` — dead-man's switch that auto-cancels orders if the bot stops heartbeating.
* **Fee rate queries**: `get_base_fee_rate()` (account tier default) and `get_fee_rate()` (per-symbol actual rates after VIP/KCS discounts).
* **HF trading ledger**: `get_hf_ledger()` — fills, fees, and settlements from HF orders (7-day rolling window with lastId-based pagination).
* **Server time**: `get_server_time()` — fetch exchange clock for drift detection.
* **Service status**: `get_service_status()` — pre-flight check for exchange operational state.
* **Fiat prices**: `get_fiat_prices()` — real-time fiat currency prices for crypto assets.
* **Configurable timestamp source**: `time_source` parameter on all R6 class constructors. Set to `"server"` to use KuCoin server time for HMAC signing instead of the local clock, avoiding clock-drift issues on machines with inaccurate system time.
* **Async support**: All R6 classes support `async = TRUE` mode returning `promises` for non-blocking I/O via `httr2::req_perform_promise()`.
* **`kucoin_backfill_klines()`**: Bulk historical kline download with resume support, automatic time-range segmentation, and CSV output.
* **Bundled dataset**: `kucoin_btc_usdt_4h_ohlcv` — 20,000+ rows of real BTC-USDT 4-hour OHLCV data for examples and testing.
* **Automatic pagination**: `kucoin_paginate()` handles multi-page API responses transparently.
* **Timestamp handling**: `time_convert_from_kucoin()` and `time_convert_to_kucoin()` for millisecond/nanosecond epoch conversion.

## IMPROVEMENTS

* All API responses returned as `data.table` objects with snake_case column names.
* Datetime columns automatically converted to POSIXct.
* Input validation for order placement (type, side, symbol format, parameter combinations).
* Request signing uses HMAC-SHA256 with base64 encoding per KuCoin v2 API spec.
* Shared mock infrastructure (`tests/testthat/mockery.R` + `mock_router.R`) for tests, README, and vignettes.
* Standardised method naming convention across all R6 classes (see `ROADMAP.md` for rules):
    - `get_*` for queries, `add_*` for creation, `cancel_*` for cancellation, `modify_*` for amendments, `set_*` for configuration.
    - `_by_id` / `_by_client_oid` suffixes, `_sync` / `_batch` modifiers, snake_case throughout.
    - Renamed: `add_subaccount` -> `add_sub_account`, `get_list_summary` -> `get_sub_account_list`, `get_spot_v2` -> `get_all_spot_balances`.
    - Renamed in `KucoinStopOrders` and `KucoinOcoOrders`: `cancel_by_id` -> `cancel_order_by_id`, `cancel_by_client_oid` -> `cancel_order_by_client_oid`, `cancel_batch` -> `cancel_all`, `get_by_id` -> `get_order_by_id`, `get_by_client_oid` -> `get_order_by_client_oid`, `get_detail_by_id` -> `get_order_detail_by_id`.
    - Renamed: `get_subaccount` -> `get_sub_account`.

## DOCUMENTATION

* Full roxygen2 R6 method documentation for all public methods.
* Class-level docs include endpoint tables, example usage, and curl equivalents.
* Two vignettes: "Getting Started" (all 9 classes, synchronous) and "Async Usage" (promise-based patterns).
* README with evaluated code examples using invisible mocked HTTP.
* pkgdown site at <https://dereckscompany.github.io/kucoin/>.

## LICENCE

* MIT licence with an additional citation clause requiring attribution in academic publications, research outputs, and publicly distributed derivative works.
