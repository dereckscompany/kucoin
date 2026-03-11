# Package index

## API Client Classes

R6 classes for interacting with KuCoin REST API

- [`KucoinBase`](https://dereckmezquita.github.io/kucoin/reference/KucoinBase.md)
  : KucoinBase: Abstract Base Class for KuCoin API Clients
- [`KucoinMarketData`](https://dereckmezquita.github.io/kucoin/reference/KucoinMarketData.md)
  : KucoinMarketData: Spot Market Data Retrieval
- [`KucoinTrading`](https://dereckmezquita.github.io/kucoin/reference/KucoinTrading.md)
  : KucoinTrading: Spot Order Management
- [`KucoinStopOrders`](https://dereckmezquita.github.io/kucoin/reference/KucoinStopOrders.md)
  : KucoinStopOrders: Stop Order Management
- [`KucoinOcoOrders`](https://dereckmezquita.github.io/kucoin/reference/KucoinOcoOrders.md)
  : KucoinOcoOrders: OCO Order Management
- [`KucoinAccount`](https://dereckmezquita.github.io/kucoin/reference/KucoinAccount.md)
  : KucoinAccount: Account and Funding Management
- [`KucoinDeposit`](https://dereckmezquita.github.io/kucoin/reference/KucoinDeposit.md)
  : KucoinDeposit: Deposit Management
- [`KucoinTransfer`](https://dereckmezquita.github.io/kucoin/reference/KucoinTransfer.md)
  : KucoinTransfer: Internal Transfer Management
- [`KucoinWithdrawal`](https://dereckmezquita.github.io/kucoin/reference/KucoinWithdrawal.md)
  : KucoinWithdrawal: Withdrawal Management
- [`KucoinSubAccount`](https://dereckmezquita.github.io/kucoin/reference/KucoinSubAccount.md)
  : KucoinSubAccount: Sub-Account Management
- [`KucoinMarginTrading`](https://dereckmezquita.github.io/kucoin/reference/KucoinMarginTrading.md)
  : KucoinMarginTrading: Margin Order and Debit Management
- [`KucoinMarginData`](https://dereckmezquita.github.io/kucoin/reference/KucoinMarginData.md)
  : KucoinMarginData: Margin Market Information
- [`KucoinLending`](https://dereckmezquita.github.io/kucoin/reference/KucoinLending.md)
  : KucoinLending: Margin Lending Operations
- [`KucoinFuturesMarketData`](https://dereckmezquita.github.io/kucoin/reference/KucoinFuturesMarketData.md)
  : KucoinFuturesMarketData: Futures Market Data Retrieval
- [`KucoinFuturesTrading`](https://dereckmezquita.github.io/kucoin/reference/KucoinFuturesTrading.md)
  : KucoinFuturesTrading: Futures Order Management
- [`KucoinFuturesAccount`](https://dereckmezquita.github.io/kucoin/reference/KucoinFuturesAccount.md)
  : KucoinFuturesAccount: Futures Account and Position Management

## Configuration

API credential and endpoint helpers

- [`get_api_keys()`](https://dereckmezquita.github.io/kucoin/reference/get_api_keys.md)
  : Retrieve KuCoin API Credentials
- [`get_base_url()`](https://dereckmezquita.github.io/kucoin/reference/get_base_url.md)
  : Retrieve KuCoin API Base URL
- [`get_futures_base_url()`](https://dereckmezquita.github.io/kucoin/reference/get_futures_base_url.md)
  : Retrieve KuCoin Futures API Base URL
- [`get_sub_account()`](https://dereckmezquita.github.io/kucoin/reference/get_sub_account.md)
  : Retrieve KuCoin Sub-Account Configuration

## Low-Level Request Helpers

Functions for building and executing KuCoin API requests

- [`kucoin_build_request()`](https://dereckmezquita.github.io/kucoin/reference/kucoin_build_request.md)
  : Build and Execute a KuCoin API Request
- [`kucoin_paginate()`](https://dereckmezquita.github.io/kucoin/reference/kucoin_paginate.md)
  : Paginate a KuCoin API Endpoint

## Backfill and Data

Bulk data download and included datasets

- [`kucoin_backfill_klines()`](https://dereckmezquita.github.io/kucoin/reference/kucoin_backfill_klines.md)
  : Backfill KuCoin Kline Data to CSV
- [`kucoin_btc_usdt_4h_ohlcv`](https://dereckmezquita.github.io/kucoin/reference/kucoin_btc_usdt_4h_ohlcv.md)
  : BTC-USDT 4-Hour OHLCV Data from KuCoin

## Utilities

Time conversion and validation helpers

- [`time_convert_from_kucoin()`](https://dereckmezquita.github.io/kucoin/reference/time_convert_from_kucoin.md)
  : Convert KuCoin Timestamp to POSIXct
- [`time_convert_to_kucoin()`](https://dereckmezquita.github.io/kucoin/reference/time_convert_to_kucoin.md)
  : Convert POSIXct to KuCoin Timestamp
- [`verify_symbol()`](https://dereckmezquita.github.io/kucoin/reference/verify_symbol.md)
  : Verify Ticker Symbol Format
