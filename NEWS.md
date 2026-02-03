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
* pkgdown site at <https://dereckmezquita.github.io/kucoin/>.

## LICENCE

* MIT licence with an additional citation clause requiring attribution in academic publications, research outputs, and publicly distributed derivative works.
