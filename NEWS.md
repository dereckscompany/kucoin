# kucoin 4.3.1

## `kucoin_paginate()` walks pages iteratively in sync mode (closes #15)

`kucoin_paginate()` expressed its page walk as self-recursion: each page's synchronous continuation called the fetch closure for the next page, so on a deep walk (thousands of pages, e.g. a long account history) the nested `fetch_page -> then_or_now -> continuation -> fetch_page` frames grew the call stack and eventually aborted with a node-stack overflow (R has no tail-call optimisation). The sync path is now an iterative `while`-loop that accumulates pages in constant stack depth, so a several-thousand-page walk completes. Results are bit-identical: the same page ordering, the same `page < total && page < max_pages` stop condition, and the same `max_pages` / `page_size` closed-interval contracts. The async path keeps its promise-based recursion, which is safe because `promises::then()` schedules each continuation as a fresh event-loop task, so the call stack unwinds between pages. A regression test walks 3000 pages through the mock router and confirms the sync path survives where the recursive code overflowed.

# kucoin 4.3.0

## snake_case argument convergence (clean break) + connectcore alignment

This release renames every camelCase R argument to snake_case, so the whole public surface reads in one style and matches the rest of the connector fleet. The KuCoin API's own camelCase field names live on only as wire payload keys built inside each method: you now pass `client_order_id`, `time_in_force`, `order_id` and so on, and the method translates each back to `clientOid` / `timeInForce` / `orderId` at the call site. This is a clean break with no deprecation shims, hence the minor-version bump.

* **snake_case everywhere.** All ~40 camelCase method arguments become snake_case (`clientOid` -> `client_order_id`, `orderId` -> `order_id`, `timeInForce` -> `time_in_force`, `isIsolated` -> `is_isolated`, `stopPrice` -> `stop_price`, `newPrice` / `newSize` -> `new_price` / `new_size`, `marginMode` -> `margin_mode`, and the rest); the venue's camelCase survives only as accepted values and wire payload keys. The blessed `.lintr` drops its camelCase allowance and now enforces pure snake_case.
* **`ms_to_datetime()` centralised in connectcore.** kucoin's length-preserving, NA-in-NA-out millisecond-to-POSIXct helper was the fleet donor and now lives in `connectcore (>= 0.3.0)`; the local copy is deleted and the function is imported, so every wrapper shares one implementation. The nanosecond variant stays local because connectcore does not centralise it.
* **Backfill no longer smuggles failures on an attribute.** `kucoin_backfill_klines()` previously attached a `"failures"` attribute to its returned file path, breaking the one-method-one-value rule; per-combo failures are now surfaced as warnings during the run, with a final summary warning listing the failed count and affected `(symbol, timeframe)` pairs, and the return value is just the file path.
* **lubridate for all date/time.** The remaining base `as.POSIXct()` / `Sys.time()` calls in code and examples are replaced with `lubridate::as_datetime()` / `lubridate::now("UTC")`.
* **Docs, tests, vignettes.** Documentation is regenerated with roxygen 7.3.3; `test-empty-tables.R` is renamed `test-empty-constructors.R` and proves every `empty_dt_*` constructor is a zero-row, non-zero-column, list-column-free, contract-passing table; the README and vignettes execute against the tests/testthat mock router with the new snake_case arguments and print real synthetic-fixture output.

# kucoin 4.2.3

## data.table return shapes documented with typed column bullets

The `@return` of every public method that yields a fixed-shape `data.table` now lists each column as a typed nested bullet, following the roxyassert convention: bare element types (`character`, `integer`, `numeric`, `logical`, `POSIXct`) with ` | NA` appended wherever a column can legitimately be missing in a real response. Documenting the columns regenerates `assert_has_columns` plus the per-column type asserts, so the parsed shape is now enforced at the public boundary — for the synchronous value and for the resolved value of a promise alike — rather than relying on the old loose `assert_data_table` check. Methods whose tables are genuinely variable-shape are deliberately left as the generic `(data.table | promise<data.table>)`: those that return a zero-column empty `data.table` on an empty response, the heterogeneous futures position tables whose numeric fields arrive sometimes as numbers and sometimes as strings, and the wide futures-contract metadata tables. This matches the package's existing flattener convention and keeps the empty-response and variable-payload paths working untouched.

# kucoin 4.2.2

## Live-capture fixture hardening + bugs the synthetic fixtures hid

This release validates every committed fixture against a read-only capture of the REAL KuCoin API (spot + futures, public + private GET) and fixes the divergences that synthetic, shape-only fixtures could not surface. A new `dev/capture-kucoin.R` drives the package's own read methods through a raw-response interceptor and dumps each verbatim body to the git-ignored `local/raw-data/kucoin/`; `dev/validate-fixtures.R` diffs each fixture's record keys against its capture. All enrichment uses synthetic values — no real account id, balance, or order id is committed.

* **Futures `GET /api/v1/status` returns a `text/plain` Content-Type.** KuCoin sends a valid JSON body for the futures service-status endpoint but labels it `text/plain`, so `httr2::resp_body_json()`'s default content-type guard aborted before parsing and `KucoinFuturesMarketData$get_service_status()` failed against the live API. The synthetic mock (served as `application/json`) hid this. `parse_kucoin_response()` now parses with `check_type = FALSE`.

* **Futures contract `sourceExchanges` produced a forbidden list column.** The live `GET /api/v1/contracts/active` and `/api/v1/contracts/{symbol}` payloads carry a `sourceExchanges` JSON array (the mark-price source venues) that the generic flattener turned into a list column, violating the package's no-list-column invariant on real data. The old array-free fixtures hid it. `KucoinFuturesMarketData$get_contract()` / `$get_all_contracts()` now collapse `sourceExchanges` to a `;`-separated scalar via `collapse_string_array_fields()`, matching the cross-package Treatment-A convention.

* **`get_open_order_value()` field rename `Qty` → `Size`.** The live `GET /api/v1/openOrderStatistics` response returns `openOrderBuySize` / `openOrderSellSize`; the fixture, mock helper, and unit assertion still used the retired `openOrderBuyQty` / `openOrderSellQty` names. The fixture, the `@return` / example docs, and the test now use `open_order_buy_size` / `open_order_sell_size`.

* **`get_funding_rate()` fictional `predictedValue` replaced with the real fields.** The live `GET /api/v1/funding-rate/{symbol}/current` response carries `dailyInterestRate`, `fundingRateCap`, `fundingRateFloor`, and `period` and does NOT return `predictedValue`; the fixture and docs invented a `predictedValue` field. Both now reflect the real payload.

* **`get_max_open_size()` rejected a numeric `price`.** The futures max-open-size endpoint typed its `price` `@param` as `scalar<character>`, so the natural numeric call `get_max_open_size("XBTUSDTM", price = 40000, leverage = 10)` aborted at the input contract — surfaced only by the private read-only live test against the real API (the synthetic unit test happened to pass a string). `price` is now `scalar<numeric in ]0, Inf[>` (httr2 serialises it for the query just like the adjacent numeric `leverage`), and the unit tests pass a numeric price too.

* **Empty kline ranges returned a column-less table.** `combine_klines()` and the zero-width-range early returns in `kucoin_fetch_klines()` (spot and futures) returned a bare `data.table()` for a window with no candles, but `get_klines()`'s `@return` requires the seven OHLCV columns (`assert_has_columns`), so an empty range aborted instead of returning empty. All four sites now return the existing typed `empty_dt_klines()` zero-row schema (the same fix class as binance and hyperliquid).

* **Fixtures enriched to the real superset (synthetic values).** Added the real-but-missing fields: `futures_account_overview` (`availableMargin`, `riskRatio`, `maxWithdrawAmount`); `futures_contract` / `futures_all_contracts` (the full real field set — `displaySymbol`, `marketMaxOrderQty`, `fundingRateCap`/`Floor`, `crossRiskLimit`, `marketType`, `sourceExchanges`, and ~30 more); `futures_trade_history` (`contractId`); `symbol` (the `callauction*` stage fields and `tradingStartTime`, present-but-null); `isolated_margin_symbols` (`autoRenewMaxDebtRatio`, `baseBorrowCoefficient`, `quoteBorrowCoefficient`); `risk_limit` (`timestamp`); `sub_accounts_page` (`tradeTypes`, `openedTradeTypes`); `deposit_addresses` (`remark`); and spot `trade_history` (`tradeId`).

## Type contract corrections (coinbase gold-standard remediation)

* **Epoch-millisecond and page-size parameters retyped off `integer`.** `assert_scalar_integer()` rejects a plain R double (an unsuffixed numeric literal such as `1729176273859` or `100` is a double, not an integer), so every `startAt` / `endAt` / `limit` / `currencyType` argument typed `scalar<integer>` was rejecting legitimate caller input at the contract boundary. Millisecond timestamp windows (`startAt` / `endAt`) — which exceed `2^31` — are now `scalar<numeric>`; the small bounded page-size / currency-type flags (`limit`, `currencyType`) are now `scalar<count>`, which validates by value and accepts a whole double. Affects `KucoinAccount`, `KucoinDeposit`, `KucoinTrading`, `KucoinWithdrawal`.

* **`max_pages` accepts its own `Inf` default again.** The pagination cap was typed half-open `scalar<numeric in [1, Inf[>`, whose generated `assert_between(..., upper_inclusive = FALSE)` rejected `max_pages = Inf` — the parameter's documented default. Retyped to the closed `scalar<numeric in [1, Inf]>` (matching the sibling connectors), so the unbounded default validates.

* **Typed per-column `@return` shapes for the fixed-schema one-row / single-column methods.** `KucoinTrading$cancel_all_by_symbol()` / `$cancel_all()` / `$get_symbols_with_open_orders()`, `KucoinMarketData$get_market_list()` / `$get_server_time()`, `KucoinLending$modify_purchase()`, `KucoinMarginTrading$modify_leverage()`, and `KucoinWithdrawal$cancel_withdrawal()` documented their result as a bare `(data.table)`; each now carries `- name (type)` column bullets, so the contract roclet emits a real `assert_has_columns()` plus per-column type check at the boundary. Payload-dependent returns (the generic flatteners, the dry-run-variable margin order acknowledgements, the optional-`symbol` futures order book) deliberately stay generic per the cross-package convention.

* **`DESCRIPTION` version constraints moved into `Imports` / `Suggests`.** `connectcore (>= 0.1.0)` and `roxyassert (>= 0.9.1)` now carry their minimum-version constraints in the dependency fields; the `Remotes` field is source-only (the `@v…` refs were stripped) as the other tracked packages do.

* **Documentation hygiene.** `NEWS.md` bullets are now one continuous line each (the renderer wraps); the over-long roxygen prose, `### Official Documentation` links (split into a title line plus a bare-URL autolink), and `curl` examples were wrapped so the package lints clean at 120 columns with no `.lintr` exclusion.

# kucoin 4.2.0

## Type contracts (roxyassert)

* **Adopted `roxyassert` for runtime type contracts across the whole package.** Every `@param`/`@return` is now written in the `roxyassert` grammar (zero prose type annotations remain), and the `roxyassert::contract_roclet` generates `assert_args_*()` / `assert_return_*()` helpers into `R/contracts-generated.R` at `document()` time — so each function's documented contract and its runtime validation come from a single source. Every public R6 table method validates its arguments at entry and validates the parsed result (synchronous value or the resolved value of a promise alike) at the boundary via `connectcore::then_or_now(res, assert_return_*, is_async = private$.is_async)`. `assert` is now an import; `uuid` and `roxyassert` are added (the margin client-order-id auto-generator now uses `uuid::UUIDgenerate()` instead of a hand-rolled hex string).

* **Reusable `@type` shapes for the fixed-schema returns.** `R/types_kucoin.R` defines `Klines` (the spot and futures OHLCV candles) and `Orderbook` (the spot level-2 book in long format); the kline and spot-order-book parsers return the fully-typed table and a typed zero-row empty on no data. Every other endpoint returns a payload-dependent schema (built by the generic `as_dt_row`/`as_dt_list`/`flatten_pages` flatteners or a bespoke inline parser), so those returns stay the generic `(data.table | promise<data.table>)` — including the futures order book, whose `symbol` column is optional. No contracts are exported (`kucoin` is a leaf connector): the shapes expand inline into each method's generated `assert_return_*` and nothing downstream validates against them. The public API and the wire bytes are unchanged.

# kucoin 4.1.1

## REFACTOR

* **Adopted `connectcore`'s `body_format = "raw"` funnel; the connector now owns no transport.** With `connectcore` v0.1.0 a pre-serialised body can be sent byte-verbatim (no NULL-pruning, no pretty-printing, no re-encoding) and the `.sign()` seam runs after the body is set, so a body-signing venue reads the exact bytes off the request. KuCoin now serialises its body once to compact JSON, routes it through the inherited funnel via `body_format = "raw"`, and signs those exact bytes — making the hand-rolled `kucoin_build_request()` redundant. It has been **removed**; `KucoinBase$.request()` is a thin override of `connectcore::build_request()` and `kucoin_paginate()` routes each page through the same funnel. The wire bytes — and the `KC-API-*` HMAC computed over them — are byte-identical to 4.1.0 (verified end-to-end: identical compact body, identical prehash, identical signature). The public API is otherwise unchanged.

# kucoin 4.1.0

## REFACTOR

* **Migrated the transport layer onto `connectcore`, the shared connector base.** `KucoinBase` now inherits [`connectcore::RestClient`](https://github.com/dereckscompany/connectcore) instead of carrying its own copy of the credential-storage / sync-async / server-time / active-binding plumbing. KuCoin plugs into the base through the two documented seams — `.sign()` (the header-based HMAC scheme: `KC-API-KEY` / `KC-API-SIGN` / `KC-API-TIMESTAMP` / `KC-API-PASSPHRASE` / `KC-API-KEY-VERSION`, signing the timestamp + method + URL-encoded path + raw body) and `.parse_envelope()` (KuCoin's `code` / `data` envelope). The public API is unchanged: every `Kucoin*` class, method, and the exported `kucoin_build_request()` / `kucoin_paginate()` helpers keep their exact signatures and behaviour.
* **The generic transport helpers now come from `connectcore` instead of being duplicated here.** The package-private `then_or_now()` and `fetch_server_time_ms()`, plus the generic JSON→data.table toolkit (`to_snake_case()`, `as_dt_row()`, `as_dt_list()`), are imported from `connectcore` (their KuCoin copies were byte-for-byte equivalents). KuCoin-specific parsers (`parse_orderbook()`, `parse_klines()`, `flatten_pages()`, the futures kline parser) and the helpers whose precise behaviour the test-suite pins (`ms_to_datetime()` / `ns_to_datetime()` shape contracts, `coerce_cols()` dedup, the `;`-collapse warning id) stay in the package.
* **Why KuCoin keeps its own request funnel.** Unlike most venues, KuCoin signs the *exact compact JSON request body* and must transmit that same byte sequence on the wire, so `kucoin_build_request()` continues to send the body via `req_body_raw()` (the signed string verbatim) rather than `connectcore`'s default funnel, which pretty-prints the body and would invalidate the signature. `kucoin_build_request()` / `kucoin_paginate()` gained optional `sign` / `parse_envelope` parameters (defaulting to KuCoin's own) so the seams drive the funnel; existing callers are unaffected.

## DEPENDENCIES

* Added `connectcore` to `Imports` (pinned to `dereckscompany/connectcore@v0.0.1` via `Remotes` and `renv.lock`).

# kucoin 4.0.3

## BUG FIXES

* **`KucoinFuturesTrading$set_dcp()` / `$get_dcp()` migrated to KuCoin's new unified DCP endpoint.** The legacy futures-specific paths (`POST /api/v1/orders/dead-cancel-all` and `GET /api/v1/orders/dead-cancel-all/query` on `api-futures.kucoin.com`) were retired by KuCoin around 2026-05 — the docs page was withdrawn, the GET path returned HTTP 404 and the POST returned 403 even on accounts with the relevant permission. KuCoin replaced both with a unified Universal-Trading-Account endpoint on the spot host: `POST /api/ua/v1/dcp/set` and `GET /api/ua/v1/dcp/query`, both taking a `tradeType` parameter that accepts `SPOT`, `MARGIN`, or `FUTURES`. We now hardcode `tradeType = "FUTURES"` and override the base URL to the spot host inside both methods, so the public method API stays unchanged — existing `futures_trading$set_dcp(timeout, symbol)` and `$get_dcp(symbol)` calls keep working. Spot DCP (`KucoinTrading$set_dcp()` / `$get_dcp()`) is untouched — it still works against the `/api/v1/hf/orders/dead-cancel-all*` paths on the spot host.

## REFACTOR

* **`KucoinBase$.request()` (private) gains an optional `base_url` parameter** that overrides the instance's configured host for a single call. Used so the migrated futures DCP methods can target the spot host while every other `KucoinFuturesTrading` method keeps using the futures host. No behaviour change for any existing call site — `base_url = NULL` (the default) preserves the previous behaviour exactly.

## TESTS

* **Live integration coverage for the Futures REST surface.** New `[LIVE]` test blocks in `tests/testthat/test-live-integration-public.R` (7 tests against `KucoinFuturesMarketData` public endpoints) and `test-live-integration-private.R` (13 tests covering authenticated `KucoinFuturesAccount`, `KucoinFuturesMarketData$get_full_orderbook`, read-only `KucoinFuturesTrading` queries, and the migrated DCP methods). Pins the 5 path-corrected GET endpoints from v4.0.2 (`get_margin_mode`, `get_cross_margin_leverage`, `get_max_open_size`, `get_max_withdraw_margin`, `get_full_orderbook`) plus the migrated DCP endpoints so the next time KuCoin moves a futures endpoint, CI surfaces the 404 instead of waiting for a user report. The DCP `set_dcp` test deliberately uses `timeout = -1` (disable) so it has no real side effects.
* Write methods (`set_margin_mode`, `set_cross_margin_leverage`, `add_isolated_margin`, `remove_isolated_margin`) are intentionally not exercised — they require real positions / funds.
* Authenticated futures tests wrap each call in `tryCatch()` and skip with a clear reason if KuCoin returns a no-futures-account / no-permission error, so the suite stays usable for contributors without a funded futures sub-account. Endpoints that genuinely 404 still fail loudly (which is the regression we want to catch).

# kucoin 4.0.2

## DOCUMENTATION

* **All 144 `Verified: YYYY-MM-DD` markers in the R6 roxygen blocks bumped to `2026-05-23`.** Every marker was walked individually against the live KuCoin docs — endpoint paths, HTTP methods, and "page exists" all confirmed per endpoint, not sampled. 119 matched the source as-is; the other 25 surfaced the docs URL / endpoint-path drift documented below.
* **Refreshed 25 stale `### Official Documentation` URLs after KuCoin reorganised the docs-new site.** 17 had returned HTTP 404 because the futures section moved (e.g. `/futures-trading/account/get-account-overview` → `/account-info/account-funding/get-account-futures`; `/futures-trading/orders/cancel-order-by-orderid` → `/futures-trading/orders/cancel-order-by-orderld` — note the typo on KuCoin's side); 7 pointed at pages that now document a different REST endpoint than the source code calls; 1 (`KucoinMarketData$get_symbol`) pointed at the all-symbols list page instead of the single-symbol detail page. All replacement URLs verified by HTTP GET. The futures Dead Connection Protection (DCP) docs were withdrawn from KuCoin entirely, so `KucoinFuturesTrading$set_dcp()` / `$get_dcp()` now reference the equivalent spot-trading DCP page with an inline note (see BUG FIXES below for the related endpoint observation).

## BUG FIXES

* **9 KuCoin Futures REST endpoint paths corrected after the 2026-05 docs reorganisation moved them.** The old paths now return HTTP 404; the new paths were confirmed live (read endpoints fully exercised; write endpoints poked with no-op or invalid payloads to confirm the path is recognised by KuCoin and only the business validation fails). Methods affected:
    - `KucoinFuturesAccount$get_margin_mode()`: `GET /api/v1/marginMode` → `GET /api/v2/position/getMarginMode`.
    - `KucoinFuturesAccount$set_margin_mode()`: `POST /api/v1/marginMode` → `POST /api/v2/position/changeMarginMode`.
    - `KucoinFuturesAccount$get_cross_margin_leverage()`: `GET /api/v1/crossMarginLeverage` → `GET /api/v2/getCrossUserLeverage`.
    - `KucoinFuturesAccount$set_cross_margin_leverage()`: `POST /api/v1/crossMarginLeverage` → `POST /api/v2/changeCrossUserLeverage`.
    - `KucoinFuturesAccount$get_max_open_size()`: `GET /api/v1/maxOpenSize` → `GET /api/v2/getMaxOpenSize`.
    - `KucoinFuturesAccount$get_max_withdraw_margin()`: `GET /api/v1/maxWithdrawMargin` → `GET /api/v1/margin/maxWithdrawMargin`.
    - `KucoinFuturesAccount$add_isolated_margin()`: `POST /api/v1/marginDepositIn` → `POST /api/v1/position/margin/deposit-margin`.
    - `KucoinFuturesAccount$remove_isolated_margin()`: `POST /api/v1/marginWithdrawOut` → `POST /api/v1/margin/withdrawMargin`.
    - `KucoinFuturesMarketData$get_full_orderbook()`: `GET /api/v2/level2/snapshot` → `GET /api/v1/level2/snapshot`.
* **Futures DCP appears to have been removed by KuCoin without an announcement.** `KucoinFuturesTrading$set_dcp()` (POST `/api/v1/orders/dead-cancel-all`) is still accepted by the Futures REST API (returns HTTP 403 on accounts without the relevant permission, so the route is alive), but `$get_dcp()` (GET `/api/v1/orders/dead-cancel-all/query`) now consistently returns HTTP 404 and the dedicated docs pages have been withdrawn. Methods left in place but flagged in roxygen; callers relying on futures DCP should treat `$get_dcp()` as broken until KuCoin clarifies.

# kucoin 4.0.1

## BUG FIXES

* **`ms_to_datetime()` / `ns_to_datetime()` no longer emit spurious `"NAs introduced by coercion"` warnings** when given an all-`NA_character_` vector. The NA → NA path is the documented contract, not a problem worth a warning. Implemented by type-dispatching on the input and only feeding the non-NA entries to `as.numeric()` — not `suppressWarnings()`, which would hide genuine bad input (e.g. a malformed numeric string from a future API change). Pinned by a counter-regression test that asserts `ms_to_datetime("not-a-number")` still warns loudly.
* **`coerce_cols(dt, cols, fn)` deduplicates `cols`**. Previously passing the same column name twice — `coerce_cols(dt, c("time", "time"), ms_to_datetime)` — would feed the already-coerced POSIXct value back through `ms_to_datetime`, reinterpreting epoch-seconds as epoch-ms and silently producing wildly wrong values (year 56,000+). Now uses `for (col in unique(cols))`. Same fix applied to the binance and alpaca helpers.

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
