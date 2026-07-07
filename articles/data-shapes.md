# Package Tour and Data-Shape Conventions

This vignette is the **one-stop tour** of the `kucoin` package. It
catalogues every public method by class, explains the shape of what each
one returns, and then documents the underlying data-shape policy in
detail.

If you’ve never used the package, read top to bottom. If you’ve used it
and just want to know how a specific endpoint comes back, jump to the
catalogue table for its class and then to the relevant treatment
section.

The same conventions are shared with the sister `alpaca` and `binance`
packages, so that switching between exchanges does not mean switching
mental models of how the data looks.

------------------------------------------------------------------------

## What’s in the package

Fifteen R6 classes cover the spot, futures, margin, lending,
sub-account, and funding surfaces of the KuCoin REST API. Every class
supports both **synchronous** and **asynchronous (promise-based)**
operation via `httr2`. All share a common abstract base (`KucoinBase`)
that handles authentication, signing, retries, and pagination.

| Class | What it covers |
|----|----|
| `KucoinMarketData` | Spot public market data — announcements, currencies, symbols, tickers, trades, orderbook, klines, server time |
| `KucoinFuturesMarketData` | Futures public market data — contracts, tickers, orderbook, trades, klines, mark price, funding rate |
| `KucoinTrading` | Spot HF order management — add, cancel, modify, query orders + fills + DCP heartbeat |
| `KucoinStopOrders` | Spot stop-loss / take-profit conditional orders |
| `KucoinOcoOrders` | Spot OCO (one-cancels-the-other) orders with sub-leg explode |
| `KucoinFuturesTrading` | Futures order management — orders, fills, stop orders, DCP |
| `KucoinAccount` | Spot account info, balances, cross/isolated margin overviews, ledgers, fee rates |
| `KucoinDeposit` | Deposit address creation, list, history |
| `KucoinWithdrawal` | Withdrawal submission, cancellation, quotas, history |
| `KucoinTransfer` | Universal asset transfers between wallets + transferable balance |
| `KucoinSubAccount` | Sub-account list, detail balances, aggregated spot balances |
| `KucoinFuturesAccount` | Futures account overview, positions, position history, margin mode, leverage, isolated margin top-up |
| `KucoinMarginData` | Cross- and isolated-margin reference data — symbols, config, collateral ratios, risk limits |
| `KucoinMarginTrading` | Margin trading — open/close long/short, borrow/repay, interest, leverage |
| `KucoinLending` | Lending pool — market, rates, purchase, modify, redeem |

Standalone (not on a class):

| Helper | What it does |
|----|----|
| [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md), [`get_base_url()`](https://dereckscompany.github.io/kucoin/reference/get_base_url.md), [`get_futures_base_url()`](https://dereckscompany.github.io/kucoin/reference/get_futures_base_url.md) | Read API credentials and base URLs from environment variables |
| [`kucoin_paginate()`](https://dereckscompany.github.io/kucoin/reference/kucoin_paginate.md) | Generic page-walker for paginated endpoints (routes through [`connectcore::build_request()`](https://rdrr.io/pkg/connectcore/man/build_request.html)) |
| [`kucoin_backfill_klines()`](https://dereckscompany.github.io/kucoin/reference/kucoin_backfill_klines.md) | Bulk historical klines download for many symbols × timeframes with CSV resume |
| [`verify_symbol()`](https://dereckscompany.github.io/kucoin/reference/verify_symbol.md) | Sanity-check a symbol against the cached symbol list before placing an order |
| [`time_convert_to_kucoin()`](https://dereckscompany.github.io/kucoin/reference/time_convert_to_kucoin.md), [`time_convert_from_kucoin()`](https://dereckscompany.github.io/kucoin/reference/time_convert_from_kucoin.md) | Millisecond / nanosecond timestamps ↔︎ `POSIXct` |

------------------------------------------------------------------------

## Setup

Set credentials in `.Renviron`:

``` bash
KUCOIN_API_KEY=your-api-key
KUCOIN_API_SECRET=your-api-secret
KUCOIN_API_PASSPHRASE=your-api-passphrase
KUCOIN_API_ENDPOINT=https://api.kucoin.com                   # spot / margin / lending
KUCOIN_FUTURES_API_ENDPOINT=https://api-futures.kucoin.com   # futures
```

Then in R:

``` r

library(kucoin)
keys           <- get_api_keys()
market         <- KucoinMarketData$new()                       # public, no keys needed
futures_market <- KucoinFuturesMarketData$new()                # public, no keys needed
trading        <- KucoinTrading$new(keys = keys)
stops          <- KucoinStopOrders$new(keys = keys)
oco            <- KucoinOcoOrders$new(keys = keys)
futures        <- KucoinFuturesTrading$new(keys = keys)
account        <- KucoinAccount$new(keys = keys)
deposit        <- KucoinDeposit$new(keys = keys)
withdrawal     <- KucoinWithdrawal$new(keys = keys)
transfer       <- KucoinTransfer$new(keys = keys)
sub            <- KucoinSubAccount$new(keys = keys)
futures_acct   <- KucoinFuturesAccount$new(keys = keys)
margin_data    <- KucoinMarginData$new(keys = keys)
margin         <- KucoinMarginTrading$new(keys = keys)
lending        <- KucoinLending$new(keys = keys)
```

------------------------------------------------------------------------

## `KucoinMarketData` — spot public market data

| Method | Endpoint | Shape |
|----|----|----|
| `get_announcements(query, page_size, max_pages)` | `GET /api/v3/announcements` | one row per announcement; `;`-collapsed `ann_type` (Treatment A) |
| `get_currency(currency, chain)` | `GET /api/v3/currencies/{currency}` | one row per chain; currency-level fields replicated (Treatment B) |
| `get_all_currencies()` | `GET /api/v3/currencies` | one row per (currency, chain) combination |
| `get_symbol(symbol)` | `GET /api/v2/symbols/{symbol}` | single row |
| `get_all_symbols(market)` | `GET /api/v2/symbols` | one row per symbol |
| `get_ticker(symbol)` | `GET /api/v1/market/orderbook/level1` | single row |
| `get_all_tickers()` | `GET /api/v1/market/allTickers` | one row per symbol; shared `time` repeated on every row |
| `get_trade_history(symbol)` | `GET /api/v1/market/histories` | one row per trade |
| `get_part_orderbook(symbol, size)` | `GET /api/v1/market/orderbook/level2_{20|100}` | one row per (side, level); `side ∈ {"bid","ask"}`, `level` 1-indexed |
| `get_full_orderbook(symbol)` | `GET /api/v3/market/orderbook/level2` | one row per (side, level); auth required |
| `get_24hr_stats(symbol)` | `GET /api/v1/market/stats` | single row |
| `get_market_list()` | `GET /api/v1/markets` | one row per market segment |
| `get_klines(symbol, timeframe, from, to)` | `GET /api/v1/market/candles` | one row per kline; auto-segments to honour the 1500-row cap |
| `get_server_time()` | `GET /api/v1/timestamp` | single row (`server_time`, `datetime`) |
| `get_service_status()` | `GET /api/v1/status` | single row |
| `get_fiat_prices(base, currencies)` | `GET /api/v1/prices` | one row per currency |

``` r

# Top 5 highest-priced asks in the book
depth <- market$get_part_orderbook("BTC-USDT", size = 20)
depth[side == "ask"][order(-price)][1:5]
```

------------------------------------------------------------------------

## `KucoinFuturesMarketData` — futures public market data

| Method | Endpoint | Shape |
|----|----|----|
| `get_contract(symbol)` | `GET /api/v1/contracts/{symbol}` | single row |
| `get_all_contracts()` | `GET /api/v1/contracts/active` | one row per active contract |
| `get_ticker(symbol)` | `GET /api/v1/ticker` | single row |
| `get_all_tickers()` | `GET /api/v1/allTickers` | one row per contract |
| `get_part_orderbook(symbol, size)` | `GET /api/v1/level2/depth{20|100}` | one row per (side, level); `level` 1-indexed |
| `get_full_orderbook(symbol)` | `GET /api/v2/level2/snapshot` | one row per (side, level); auth required |
| `get_trade_history(symbol)` | `GET /api/v1/trade/history` | one row per trade |
| `get_klines(symbol, granularity, from, to, fetch_all)` | `GET /api/v1/kline/query` | one row per kline; auto-segments when `fetch_all = TRUE` |
| `get_mark_price(symbol)` | `GET /api/v1/mark-price/{symbol}/current` | single row |
| `get_funding_rate(symbol)` | `GET /api/v1/funding-rate/{symbol}/current` | single row |
| `get_funding_history(symbol, from, to)` | `GET /api/v1/contract/funding-rates` | one row per funding settlement |
| `get_server_time()` | `GET /api/v1/timestamp` | single row |
| `get_service_status()` | `GET /api/v1/status` | single row |

------------------------------------------------------------------------

## `KucoinTrading` — spot HF order management

| Method | Endpoint | Shape |
|----|----|----|
| `add_order(type, symbol, side, ...)` | `POST /api/v1/hf/orders` | single row (`order_id`, `client_oid`) |
| `add_order_test(...)` | `POST /api/v1/hf/orders/test` | single row |
| `add_order_batch(order_list)` | `POST /api/v1/hf/orders/multi` | one row per order result (`success`, `fail_msg`) |
| `cancel_order_by_id(orderId, symbol)` | `DELETE /api/v1/hf/orders/{orderId}` | single row |
| `cancel_order_by_client_oid(clientOid, symbol)` | `DELETE /api/v1/hf/orders/client-order/{clientOid}` | single row |
| `cancel_partial_order(orderId, symbol, cancelSize)` | `DELETE /api/v1/hf/orders/cancel/{orderId}` | single row |
| `cancel_all_by_symbol(symbol)` | `DELETE /api/v1/hf/orders` | single row (`result`) |
| `cancel_all()` | `DELETE /api/v1/hf/orders/cancelAll` | one row per (symbol, status); empty `data.table` if none open |
| `get_order_by_id(orderId, symbol)` | `GET /api/v1/hf/orders/{orderId}` | single row |
| `get_order_by_client_oid(clientOid, symbol)` | `GET /api/v1/hf/orders/client-order/{clientOid}` | single row |
| `get_fills(symbol, ...)` | `GET /api/v1/hf/fills` | one row per fill |
| `get_symbols_with_open_orders()` | `GET /api/v1/hf/orders/active/symbols` | one row per symbol |
| `get_open_orders(symbol)` | `GET /api/v1/hf/orders/active` | one row per open order |
| `get_closed_orders(symbol, ...)` | `GET /api/v1/hf/orders/done` | one row per closed order |
| `add_order_sync(...)` | `POST /api/v1/hf/orders/sync` | single row including fill summary |
| `add_order_batch_sync(order_list)` | `POST /api/v1/hf/orders/multi/sync` | one row per order with fill summary |
| `cancel_order_by_id_sync(orderId, symbol)` | `DELETE /api/v1/hf/orders/sync/{orderId}` | single row |
| `cancel_order_by_client_oid_sync(clientOid, symbol)` | `DELETE /api/v1/hf/orders/sync/client-order/{clientOid}` | single row |
| `modify_order(symbol, orderId, clientOid, newPrice, newSize)` | `POST /api/v1/hf/orders/alter` | single row (`new_order_id`) |
| `set_dcp(timeout, symbols)` | `POST /api/v1/hf/orders/dead-cancel-all` | single row |
| `get_dcp()` | `GET /api/v1/hf/orders/dead-cancel-all/query` | single row; empty if unset |

``` r

# All BTC-USDT orders that filled at > 50k
orders <- trading$get_closed_orders(symbol = "BTC-USDT")
orders[as.numeric(deal_funds) > 50000]
```

------------------------------------------------------------------------

## `KucoinStopOrders` — spot stop-loss / take-profit orders

| Method | Endpoint | Shape |
|----|----|----|
| `add_order(type, symbol, side, stopPrice, ...)` | `POST /api/v1/stop-order` | single row |
| `cancel_order_by_id(orderId)` | `DELETE /api/v1/stop-order/{orderId}` | one row per cancelled order; empty if none matched |
| `cancel_order_by_client_oid(clientOid, symbol)` | `DELETE /api/v1/stop-order/cancelOrderByClientOid` | single row (`cancelled_order_id`, `client_oid`) |
| `cancel_all(query)` | `DELETE /api/v1/stop-order/cancel` | one row per cancelled order; empty if none matched |
| `get_order_by_id(orderId)` | `GET /api/v1/stop-order/{orderId}` | single row |
| `get_order_by_client_oid(clientOid, symbol)` | `GET /api/v1/stop-order/queryOrderByClientOid` | single row |
| `get_order_list(query)` | `GET /api/v1/stop-order` | one row per pending stop order |

------------------------------------------------------------------------

## `KucoinOcoOrders` — spot OCO (one-cancels-the-other) orders

OCO orders are inherently nested (one parent contains two legs — a limit
and a stop-limit). The package keeps the parent on its own methods; the
`get_order_detail_by_id` endpoint expands the `orders` array to one row
per leg with parent fields replicated, using a `sub_order_*` prefix.

| Method | Endpoint | Shape |
|----|----|----|
| `add_order(symbol, side, price, size, stopPrice, limitPrice, ...)` | `POST /api/v3/oco/order` | single row (`order_id`, `client_oid`) |
| `cancel_order_by_id(orderId)` | `DELETE /api/v3/oco/order/{orderId}` | one row per cancelled leg |
| `cancel_order_by_client_oid(clientOid)` | `DELETE /api/v3/oco/client-order/{clientOid}` | one row per cancelled leg |
| `cancel_all(query)` | `DELETE /api/v3/oco/orders` | one row per cancelled leg |
| `get_order_by_id(orderId)` | `GET /api/v3/oco/order/{orderId}` | single row (parent summary only) |
| `get_order_by_client_oid(clientOid)` | `GET /api/v3/oco/client-order/{clientOid}` | single row |
| `get_order_detail_by_id(orderId)` | `GET /api/v3/oco/order/details/{orderId}` | one row per sub-order with `sub_order_*` columns + replicated parent (Treatment B) |
| `get_order_list(query)` | `GET /api/v3/oco/orders` | one row per OCO order |

------------------------------------------------------------------------

## `KucoinFuturesTrading` — futures order management

| Method | Endpoint | Shape |
|----|----|----|
| `add_order(clientOid, symbol, side, type, leverage, size, ...)` | `POST /api/v1/orders` | single row |
| `add_order_test(...)` | `POST /api/v1/orders/test` | single row |
| `add_order_batch(orders)` | `POST /api/v1/orders/multi` | one row per order result |
| `cancel_order_by_id(orderId)` | `DELETE /api/v1/orders/{orderId}` | one row per cancelled order; empty if none matched |
| `cancel_order_by_client_oid(clientOid, symbol)` | `DELETE /api/v1/orders/client-order/{clientOid}` | one row per cancelled order |
| `cancel_all(symbol)` | `DELETE /api/v1/orders` | one row per cancelled order; empty if none matched |
| `cancel_all_stop_orders(symbol)` | `DELETE /api/v1/stopOrders` | one row per cancelled stop order; empty if none matched |
| `get_order_by_id(orderId)` | `GET /api/v1/orders/{orderId}` | single row |
| `get_order_by_client_oid(clientOid)` | `GET /api/v1/orders/byClientOid` | single row |
| `get_order_list(query)` | `GET /api/v1/orders` | one row per order; auto-paginated |
| `get_recent_closed_orders(symbol)` | `GET /api/v1/recentDoneOrders` | one row per recently closed order |
| `get_stop_orders(query)` | `GET /api/v1/stopOrders` | one row per untriggered stop order; auto-paginated |
| `get_fills(query)` | `GET /api/v1/fills` | one row per fill; auto-paginated |
| `get_recent_fills(symbol)` | `GET /api/v1/recentFills` | one row per recent fill |
| `get_open_order_value(symbol)` | `GET /api/v1/openOrderStatistics` | single row |
| `set_dcp(timeout, symbol)` | `POST /api/v1/orders/dead-cancel-all` | single row |
| `get_dcp(symbol)` | `GET /api/v1/orders/dead-cancel-all/query` | single row |

------------------------------------------------------------------------

## `KucoinAccount` — spot, cross- and isolated-margin account

| Method | Endpoint | Shape |
|----|----|----|
| `get_summary()` | `GET /api/v2/user-info` | single row |
| `get_apikey_info()` | `GET /api/v1/user/api-key` | single row; `permission` is a comma-joined character |
| `get_spot_account_type()` | `GET /api/v1/hf/accounts/opened` | logical scalar (compatibility flag) |
| `get_spot_accounts(query)` | `GET /api/v1/accounts` | one row per account |
| `get_spot_account_detail(accountId)` | `GET /api/v1/accounts/{accountId}` | single row |
| `get_cross_margin_account(query)` | `GET /api/v3/margin/accounts` | one row per currency; account-level summary replicated (Treatment B with replicated parent) |
| `get_isolated_margin_account(query)` | `GET /api/v3/isolated/accounts` | one row per pair; nested `baseAsset`/`quoteAsset` flattened wide-prefix (Treatment B + C) |
| `get_spot_ledger(query, page_size, max_pages)` | `GET /api/v1/accounts/ledgers` | one row per ledger entry; auto-paginated |
| `get_hf_ledger(...)` | `GET /api/v1/hf/accounts/ledgers` | one row per HF ledger entry |
| `get_base_fee_rate(currencyType)` | `GET /api/v1/base-fee` | single row |
| `get_fee_rate(symbols)` | `GET /api/v1/trade-fees` | one row per symbol (max 10 per call) |

------------------------------------------------------------------------

## `KucoinDeposit`

| Method | Endpoint | Shape |
|----|----|----|
| `add_deposit_address(currency, chain, to, amount)` | `POST /api/v3/deposit-address/create` | single row |
| `get_deposit_addresses(currency, amount, chain)` | `GET /api/v3/deposit-addresses` | one row per address (single object or array, both normalised) |
| `get_deposit_history(currency, status, ...)` | `GET /api/v1/deposits` | one row per deposit; auto-paginated |

------------------------------------------------------------------------

## `KucoinWithdrawal`

| Method | Endpoint | Shape |
|----|----|----|
| `add_withdrawal(currency, toAddress, amount, withdrawType, chain, ...)` | `POST /api/v3/withdrawals` | single row |
| `cancel_withdrawal(withdrawalId)` | `DELETE /api/v1/withdrawals/{withdrawalId}` | single row (`withdrawal_id` echoed; KuCoin returns null) |
| `get_withdrawal_quotas(currency, chain)` | `GET /api/v1/withdrawals/quotas` | single row |
| `get_withdrawal_history(currency, status, ...)` | `GET /api/v1/withdrawals` | one row per withdrawal; auto-paginated |
| `get_withdrawal_by_id(withdrawalId)` | `GET /api/v1/withdrawals/{withdrawalId}` | single row with cancel-eligibility / failure-reason columns |

------------------------------------------------------------------------

## `KucoinTransfer`

Universal asset transfers across spot, trade, margin, isolated,
contract, and sub-account wallets.

| Method | Endpoint | Shape |
|----|----|----|
| `add_transfer(clientOid, currency, amount, type, fromAccountType, toAccountType, ...)` | `POST /api/v3/accounts/universal-transfer` | single row |
| `get_transferable(currency, type, tag)` | `GET /api/v1/accounts/transferable` | single row |

------------------------------------------------------------------------

## `KucoinSubAccount`

| Method | Endpoint | Shape |
|----|----|----|
| `add_sub_account(password, subName, access, remarks)` | `POST /api/v2/sub/user/created` | single row |
| `get_sub_account_list(page_size, max_pages)` | `GET /api/v2/sub/user` | one row per sub-account; auto-paginated |
| `get_detail_balance(subUserId, includeBaseAmount)` | `GET /api/v1/sub-accounts/{subUserId}` | one row per (wallet bucket, asset) for one sub-account; `account_type ∈ {"main","trade","margin"}` |
| `get_all_spot_balances(page_size, max_pages)` | `GET /api/v2/sub-accounts` | one row per (sub-account, wallet bucket, asset); auto-paginated |

------------------------------------------------------------------------

## `KucoinFuturesAccount` — futures account, positions, isolated-margin top-up

| Method | Endpoint | Shape |
|----|----|----|
| `get_account_overview(currency)` | `GET /api/v1/account-overview` | single row |
| `get_position(symbol)` | `GET /api/v2/position` | single row |
| `get_positions(currency)` | `GET /api/v1/positions` | one row per open position |
| `get_positions_history(query)` | `GET /api/v1/history-positions` | one row per closed-position record |
| `get_margin_mode(symbol)` | `GET /api/v1/marginMode` | single row |
| `set_margin_mode(symbol, marginMode)` | `POST /api/v1/marginMode` | single row |
| `get_cross_margin_leverage(symbol)` | `GET /api/v1/crossMarginLeverage` | single row |
| `set_cross_margin_leverage(symbol, leverage)` | `POST /api/v1/crossMarginLeverage` | single row |
| `get_max_open_size(symbol, price, leverage)` | `GET /api/v1/maxOpenSize` | single row |
| `get_max_withdraw_margin(symbol)` | `GET /api/v1/maxWithdrawMargin` | single row (`max_withdraw_margin` — scalar wrapped) |
| `add_isolated_margin(symbol, margin, bizNo)` | `POST /api/v1/marginDepositIn` | single row |
| `remove_isolated_margin(symbol, withdrawAmount)` | `POST /api/v1/marginWithdrawOut` | single row |
| `get_risk_limit(symbol)` | `GET /api/v1/contracts/risk-limit/{symbol}` | one row per risk-limit tier |
| `get_funding_history(symbol, query)` | `GET /api/v1/funding-history` | one row per funding settlement |

------------------------------------------------------------------------

## `KucoinMarginData` — cross- and isolated-margin reference data

| Method | Endpoint | Shape |
|----|----|----|
| `get_cross_margin_symbols(query)` | `GET /api/v3/margin/symbols` | one row per cross-margin pair |
| `get_isolated_margin_symbols()` | `GET /api/v1/isolated/symbols` | one row per isolated-margin pair |
| `get_margin_config()` | `GET /api/v1/margin/config` | one row per supported currency; config-level fields replicated (Treatment B) |
| `get_collateral_ratio(query)` | `GET /api/v3/margin/collateralRatio` | one row per (currency, tier); cross-joins `currencyList` × `items` |
| `get_risk_limit(isIsolated, query)` | `GET /api/v3/margin/currencies` | one row per currency (cross) or (symbol, currency) (isolated) |

------------------------------------------------------------------------

## `KucoinMarginTrading` — leveraged spot trading and borrowing

The four trade-direction methods (`open_short`, `close_short`,
`open_long`, `close_long`) all route through a single
`POST /api/v3/hf/margin/order` endpoint with the appropriate `side` /
`autoBorrow` / `autoRepay` flags.

| Method | Endpoint | Shape |
|----|----|----|
| `open_short(symbol, size, ...)` | `POST /api/v3/hf/margin/order` | single row (`order_id`, `client_oid`, `borrow_size`, `loan_apply_id`) |
| `close_short(symbol, size, ...)` | `POST /api/v3/hf/margin/order` | single row |
| `open_long(symbol, size, ...)` | `POST /api/v3/hf/margin/order` | single row |
| `close_long(symbol, size, ...)` | `POST /api/v3/hf/margin/order` | single row |
| `borrow(currency, size, ...)` | `POST /api/v3/margin/borrow` | single row (`order_no`, `actual_size`) |
| `repay(currency, size)` | `POST /api/v3/margin/repay` | single row |
| `get_borrow_history(query)` | `GET /api/v3/margin/borrow` | one row per borrow record |
| `get_repay_history(query)` | `GET /api/v3/margin/repay` | one row per repay record |
| `get_interest_history(query)` | `GET /api/v3/margin/interest` | one row per interest accrual |
| `get_borrow_rate(query)` | `GET /api/v3/margin/borrowRate` | one row per currency |
| `modify_leverage(leverage)` | `POST /api/v3/position/update-user-leverage` | single row (`leverage`, `status`) |

------------------------------------------------------------------------

## `KucoinLending` — lending pool (earn yield from margin borrowers)

| Method | Endpoint | Shape |
|----|----|----|
| `get_loan_market(query)` | `GET /api/v3/project/list` | one row per loan-market entry |
| `get_loan_market_rate(currency)` | `GET /api/v3/project/marketInterestRate` | one row per observation (7-day window) |
| `purchase(currency, size, interestRate)` | `POST /api/v3/purchase` | single row (`order_no`) |
| `modify_purchase(currency, purchaseOrderNo, interestRate)` | `POST /api/v3/lend/purchase/update` | single row |
| `get_purchase_orders(query)` | `GET /api/v3/purchase/orders` | one row per purchase order |
| `redeem(currency, size, purchaseOrderNo)` | `POST /api/v3/redeem` | single row (`order_no`) |
| `get_redeem_orders(query)` | `GET /api/v3/redeem/orders` | one row per redemption order |

------------------------------------------------------------------------

## Standalone helpers

### Credentials and base URLs

``` r

keys     <- get_api_keys()              # reads .Renviron
spot_url <- get_base_url()              # api.kucoin.com
fut_url  <- get_futures_base_url()      # api-futures.kucoin.com
```

### Low-level HTTP

Every request flows through
[`connectcore::build_request()`](https://rdrr.io/pkg/connectcore/man/build_request.html)
(the shared transport funnel) via `KucoinBase$.request()`, which
pre-serialises the body to compact JSON and sends it byte-verbatim so
the HMAC-SHA256 signature matches on the wire.
[`kucoin_paginate()`](https://dereckscompany.github.io/kucoin/reference/kucoin_paginate.md)
walks the `currentPage` / `pageSize` envelope on paginated endpoints
through that same funnel. You should rarely call
[`kucoin_paginate()`](https://dereckscompany.github.io/kucoin/reference/kucoin_paginate.md)
directly — every method goes through it — but it is exported so you can
wrap any not-yet-bound paginated endpoint without re-implementing the
signing.

### Bulk klines download

``` r

# Backfill 1-hour bars for many symbols, with CSV resume so an aborted
# run doesn't restart from scratch.
kucoin_backfill_klines(
  symbols    = c("BTC-USDT", "ETH-USDT"),
  timeframes = c("1day", "1hour"),
  from       = lubridate::as_datetime("2024-01-01"),
  to         = lubridate::as_datetime("2024-02-01"),
  file       = "data/klines.csv"
)
```

### Time conversions

KuCoin’s APIs use a mix of millisecond and nanosecond UNIX timestamps.
The two helpers handle both:

``` r

time_convert_to_kucoin(as.POSIXct("2024-01-01", tz = "UTC"), unit = "ms")
#> [1] 1704067200000
time_convert_from_kucoin(1704067200000, unit = "ms")
#> [1] "2024-01-01 UTC"
time_convert_from_kucoin(1704067200000000000, unit = "ns")
#> [1] "2024-01-01 UTC"
```

### Symbol verification

``` r

verify_symbol("BTC-USDT")   # TRUE
verify_symbol("ETH-USDT")   # TRUE
verify_symbol("FOOBAR")     # FALSE, with informative message
```

------------------------------------------------------------------------

## Data-shape conventions

Every `kucoin` method that returns nested API data follows one rule:

> **Identify the entity for the endpoint, and return one row per
> entity.**

A trade gets a row. An order gets a row. An asset balance gets a row. A
candle gets a row. Anything nested under the entity becomes a flat
column on the same row or an additional row on a different axis —
**never a list column** — and **no data is dropped**; fields that don’t
fit a per-entity row are surfaced via a sibling method or inlined onto
the existing rows.

The same rule applies in the sister `alpaca` and `binance` packages, so
that switching between exchanges does not mean switching mental models
of how the data looks.

There are five shape treatments. A handful of endpoints use two
treatments together when their nesting has two layers.

### Treatment A — `;` collapse for arrays of plain strings

When a field is an array of short, plain string values (codes, tags,
permissions, announcement types) and the user mostly filters by them or
displays the whole list, collapse with `;` into a single character
column. Filter with `grepl`, recover the original vector with
`strsplit(x, ";", fixed = TRUE)[[1]]`.

The package ships a shared helper
`collapse_string_array_fields(x, fields)` that does this (NA-safe; emits
a once-per-session warning if any value contains a literal `;`).

``` r

ann <- market$get_announcements(page_size = 50, max_pages = 1)

ann$ann_type[1]
#> "latest-announcements;new-listings"

# Filter
ann[grepl("new-listings", ann_type)]

# Recover the vector
strsplit(ann$ann_type[1], ";", fixed = TRUE)[[1]]
#> "latest-announcements" "new-listings"
```

Where this is used: `get_announcements()` for `ann_type`,
`get_apikey_info()`’s `permission` (KuCoin already returns it as a
comma-joined string, so the recovery idiom is `strsplit(..., ",")[[1]]`
rather than `";"`).

The separator is `;` rather than `,` because semicolons are far less
likely to appear inside any of the joined values themselves. If KuCoin
ever ships a value that contains `;`, the parser emits a
once-per-session warning so we catch it immediately rather than silently
corrupting data.

### Treatment B — Long format for arrays of objects

When the array elements are themselves records (each has multiple
fields), explode to one row per element with the parent fields
replicated. Add a 1-indexed position column where order matters.

``` r

# `KucoinSubAccount::get_detail_balance()` returns one row per
# (sub-account × wallet bucket × asset). The sub-account-level fields
# (`sub_user_id`, `sub_name`, `account_type`) are replicated on each
# row.
bal <- sub$get_detail_balance(sub_user_id)
bal[account_type == "trade", .(currency, balance, available, holds)]
```

``` r

# `KucoinOcoOrders::get_order_detail_by_id()` explodes the `orders`
# array into `sub_order_*` columns — one row per child leg, parent
# fields replicated.
detail <- oco$get_order_detail_by_id(order_id)
detail[, .(order_id, sub_order_id, sub_order_side, sub_order_price)]
```

``` r

# `KucoinAccount::get_cross_margin_account()` returns one row per
# currency in the cross-margin wallet, with account-level summary
# fields (`total_asset_of_quote_currency`, `debt_ratio`, `status`)
# replicated on every row. No sibling method needed for the parent
# scalars — they are small enough to inline.
ca <- account$get_cross_margin_account(query = list(quoteCurrency = "USDT"))
ca[currency == "USDT", .(currency, total, liability, debt_ratio)]
```

Where this is used: `KucoinSubAccount::get_detail_balance()` and
`get_all_spot_balances()` (sub-account × wallet × asset),
`KucoinOcoOrders::get_order_detail_by_id()` (`sub_order_*` legs),
`KucoinMarketData::get_currency()` / `get_all_currencies()` (chains per
currency), `KucoinMarginData::get_margin_config()` (currency list),
`KucoinMarginData::get_collateral_ratio()` (`currencyList` × `items`
cross-join), `KucoinAccount::get_cross_margin_account()` /
`get_isolated_margin_account()` (per-currency / per-pair detail with
parent fields replicated), orderbook `bids` / `asks`.

**Empty arrays**: KuCoin’s Treatment B parsers don’t know every possible
child field up-front (some sub-orders carry `stopPrice`, others don’t),
so they don’t synthesise an `NA`-filled `<noun>_*` schema when the array
is empty. `KucoinOcoOrders::get_order_detail_by_id()` with no sub-orders
returns just the parent columns; cancel parsers with an empty
`cancelledOrderIds` return a zero-row table. Defensive callers should
check `<noun>_*` columns with `"sub_order_id" %in% names(dt)` rather
than assuming they’re always present.

### Treatment C — Wide prefix for fixed-schema nested objects

When the field is a single nested object with a known fixed key set,
flatten it to `parent_child` columns.

``` r

# `KucoinAccount::get_isolated_margin_account()` flattens the nested
# `baseAsset` / `quoteAsset` per-pair objects into wide columns.
iso <- account$get_isolated_margin_account()
iso[, .(symbol,
        base_asset_currency,  base_asset_borrow_enabled,
        quote_asset_currency, quote_asset_borrow_enabled)]
```

Where this is used: `KucoinAccount::get_isolated_margin_account()` for
`baseAsset` / `quoteAsset`. The same endpoint also uses Treatment B (one
row per pair) + replicated parent summary fields, so it ends up doing
all three treatments at once — see the column list in
[`?KucoinAccount`](https://dereckscompany.github.io/kucoin/reference/KucoinAccount.md)
for the full schema.

### Treatment D — Re-route to a sibling method

When a response bundles a collection that doesn’t fit the per-entity row
of the calling endpoint — typically heterogeneous siblings (e.g. an
account-level summary bundled with per-asset rows) — the parser keeps
only the rows for the entity the method names, and the rest is exposed
via a dedicated sibling method. Every method still returns one
`data.table`; no data is lost.

KuCoin uses this less frequently than `binance` because the KuCoin REST
API tends to namespace different entities to different endpoints
already. Where KuCoin does bundle, the parsers usually prefer Treatment
B with replicated parent fields (see `get_cross_margin_account()` above)
rather than Treatment D, because the parent scalars are small and the
caller doesn’t need a second round trip.

The clearest re-route on KuCoin is the public market data pair where the
in-class methods complement each other rather than splitting a single
response: `KucoinMarketData::get_part_orderbook()` and
`get_full_orderbook()` hit different endpoints, but
`get_full_orderbook()` requires authentication. Choose the one that
matches your auth state; the shape is identical.

### Treatment E — JSON string for dynamic-key or array-of-array objects

When a nested object has dynamic keys (different products have different
key sets) or is an array of arrays where the inner grouping carries
semantic meaning, neither `;`-collapse nor wide-prefix preserves the
structure. Serialise the whole field as a JSON string; recover with
[`jsonlite::fromJSON`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

``` r

# `KucoinAccount::get_spot_ledger()` and `get_hf_ledger()` preserve the
# raw `context` field as a JSON string because its keys depend on
# the `bizType` of the entry (Exchange entries carry `orderId` +
# `symbol`; Transfer entries carry `description`; etc.).
ledger <- account$get_spot_ledger(query = list(currency = "USDT", biz_type = "Exchange"))
ledger$context[1]
#> '{"orderId":"670fd33bf9406e0007ab3945","symbol":"BTC-USDT"}'

# Recover the structure
jsonlite::fromJSON(ledger$context[1])
#> $orderId
#> [1] "670fd33bf9406e0007ab3945"
#> $symbol
#> [1] "BTC-USDT"
```

Where this is used: `KucoinAccount::get_spot_ledger()` and
`get_hf_ledger()` for the `context` field. Other endpoints (e.g.
`get_collateral_ratio()`) avoid Treatment E by cross-joining the nested
arrays in the parser instead.

------------------------------------------------------------------------

## Two cross-cutting rules

These apply to every shape treatment:

1.  **Empty / null array → `NA_character_`** (no list cells). An order
    with no fills returns `fill_id = NA`, not `fill_id = list()`.
2.  **Empty response → empty `data.table`** (no synthetic stub rows).
    `KucoinTrading::cancel_all()` with no open orders returns a zero-row
    table, not a 1-row `(symbol, status = "cancelled")` fabrication. The
    absence of an error is the success signal.

------------------------------------------------------------------------

## What was *not* done

A few intentional non-goals, shared with the sister `alpaca` and
`binance` packages:

- **No automatic numeric coercion of “string-numeric” fields.** KuCoin
  returns prices, quantities, balances, fees, and interest rates as
  fixed-precision strings. The package preserves them as character so
  the user controls precision. Cast with
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) at the point of
  use.
- **`clientOid` is round-tripped verbatim.** Whatever string you pass
  goes back to you unchanged. No normalisation, no re-encoding —
  bring-your-own UUIDs.
- **No automatic local-time conversion.** Millisecond timestamps come
  back as UTC `POSIXct`; nanosecond timestamps (trades, order placement
  times) also UTC `POSIXct`. Convert with
  `format(x, tz = "America/New_York")` or similar at display time.
- **`context` ledger field stays JSON.** Dynamic keys per business type
  defeat any flatten strategy; the user calls
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  only when they need the metadata.
- **No client-side rate-limiting.** The package surfaces KuCoin’s
  rate-limit error codes but does not back off on its own — that is the
  caller’s job.
- **No reconnect / retry on transient network errors.** The single call
  is what you asked for; configure retries through
  [`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)’s
  `max_tries` (the shared transport funnel) if you want them.

------------------------------------------------------------------------

## Why this matters across exchanges

The `alpaca`, `binance`, and `kucoin` packages all follow the same shape
rule. That means once you’ve learned `data.table` idioms for one of
them, the same idioms work on the others — pivot a portfolio’s balances
across multiple wallets and exchanges with a straight `rbindlist` plus
an exchange / wallet column, no per-source shape massage.

``` r

# Combine spot + futures + cross-margin balances into one ledger
ledger <- data.table::rbindlist(
  list(
    account$get_spot_accounts()[, wallet := "spot"],
    futures_acct$get_account_overview("USDT")[, wallet := "futures"],
    account$get_cross_margin_account()[, wallet := "margin"]
  ),
  use.names = TRUE,
  fill = TRUE
)
ledger[as.numeric(available) > 0]
```

The same idiom works for orders:

``` r

# Top 5 highest-priced asks in the book
depth[side == "ask"][order(-price)][1:5]

# All BTC-USDT orders that filled at > 50k
orders <- trading$get_closed_orders(symbol = "BTC-USDT")
orders[as.numeric(deal_funds) > 50000]
```

…without escape hatches into `lapply` over hidden lists.

------------------------------------------------------------------------

## See also

- [`vignette("getting-started", package = "kucoin")`](https://dereckscompany.github.io/kucoin/articles/getting-started.md)
  — the package tour.
- [`vignette("async-usage", package = "kucoin")`](https://dereckscompany.github.io/kucoin/articles/async-usage.md)
  — using the same methods with `async = TRUE`.
- [`vignette("futures-trading", package = "kucoin")`](https://dereckscompany.github.io/kucoin/articles/futures-trading.md)
  and
  [`vignette("margin-trading", package = "kucoin")`](https://dereckscompany.github.io/kucoin/articles/margin-trading.md)
  — surface-specific walkthroughs.
- The sister `alpaca` and `binance` packages — same convention applied
  to different exchanges. `binance`’s
  [`vignette("data-shapes")`](https://dereckscompany.github.io/kucoin/articles/data-shapes.md)
  has the same Package Tour layout for its 13 R6 classes.
