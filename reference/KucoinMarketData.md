# KucoinMarketData: Spot Market Data Retrieval

KucoinMarketData: Spot Market Data Retrieval

KucoinMarketData: Spot Market Data Retrieval

## Details

Provides methods for retrieving market data from KuCoin's Spot trading
API, including announcements, klines, currencies, symbols, tickers,
orderbooks, trade history, and 24-hour statistics.

Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Announcements**: Fetch paginated KuCoin platform announcements
  filtered by type, language, and date range.

- **Currencies**: Retrieve metadata for individual or all listed
  currencies, including chain-specific deposit/withdrawal details.

- **Symbols**: Retrieve trading pair metadata including precision, size
  limits, fee rates, and trading status.

- **Tickers**: Access real-time Level 1 best bid/ask data for individual
  symbols or all pairs.

- **Order Books**: Get partial (20/100 levels) or full depth order book
  snapshots.

- **Trade History**: Retrieve the most recent 100 trades for any symbol.

- **24hr Statistics**: Get rolling 24-hour market statistics (OHLCV,
  change rate, fees).

- **Market List**: Discover all available market segments (e.g., USDS,
  DeFi, Meme).

- **Klines**: Fetch historical candlestick data with automatic
  time-range segmentation to bypass the 1500-candle-per-request limit.

### Usage

Most methods are public endpoints requiring no authentication. The one
exception is `get_full_orderbook()` which requires valid API
credentials.

### Official Documentation

[KuCoin Spot Market
Data](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)

### Endpoints Covered

|                    |                                             |      |
|--------------------|---------------------------------------------|------|
| Method             | Endpoint                                    | Auth |
| get_announcements  | GET /api/v3/announcements                   | No   |
| get_currency       | GET /api/v3/currencies/{currency}           | No   |
| get_all_currencies | GET /api/v3/currencies                      | No   |
| get_symbol         | GET /api/v2/symbols/{symbol}                | No   |
| get_all_symbols    | GET /api/v2/symbols                         | No   |
| get_ticker         | GET /api/v1/market/orderbook/level1         | No   |
| get_all_tickers    | GET /api/v1/market/allTickers               | No   |
| get_trade_history  | GET /api/v1/market/histories                | No   |
| get_part_orderbook | GET /api/v1/market/orderbook/level2\_{size} | No   |
| get_full_orderbook | GET /api/v3/market/orderbook/level2         | Yes  |
| get_24hr_stats     | GET /api/v1/market/stats                    | No   |
| get_market_list    | GET /api/v1/markets                         | No   |
| get_klines         | GET /api/v1/market/candles                  | No   |
| get_server_time    | GET /api/v1/timestamp                       | No   |
| get_service_status | GET /api/v1/status                          | No   |
| get_fiat_prices    | GET /api/v1/prices                          | No   |

## Super class

[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinMarketData`

## Methods

### Public methods

- [`KucoinMarketData$get_announcements()`](#method-KucoinMarketData-get_announcements)

- [`KucoinMarketData$get_currency()`](#method-KucoinMarketData-get_currency)

- [`KucoinMarketData$get_all_currencies()`](#method-KucoinMarketData-get_all_currencies)

- [`KucoinMarketData$get_symbol()`](#method-KucoinMarketData-get_symbol)

- [`KucoinMarketData$get_all_symbols()`](#method-KucoinMarketData-get_all_symbols)

- [`KucoinMarketData$get_ticker()`](#method-KucoinMarketData-get_ticker)

- [`KucoinMarketData$get_all_tickers()`](#method-KucoinMarketData-get_all_tickers)

- [`KucoinMarketData$get_trade_history()`](#method-KucoinMarketData-get_trade_history)

- [`KucoinMarketData$get_part_orderbook()`](#method-KucoinMarketData-get_part_orderbook)

- [`KucoinMarketData$get_full_orderbook()`](#method-KucoinMarketData-get_full_orderbook)

- [`KucoinMarketData$get_24hr_stats()`](#method-KucoinMarketData-get_24hr_stats)

- [`KucoinMarketData$get_market_list()`](#method-KucoinMarketData-get_market_list)

- [`KucoinMarketData$get_klines()`](#method-KucoinMarketData-get_klines)

- [`KucoinMarketData$get_server_time()`](#method-KucoinMarketData-get_server_time)

- [`KucoinMarketData$get_service_status()`](#method-KucoinMarketData-get_service_status)

- [`KucoinMarketData$get_fiat_prices()`](#method-KucoinMarketData-get_fiat_prices)

- [`KucoinMarketData$clone()`](#method-KucoinMarketData-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_announcements()`

Get Announcements

Retrieves paginated market announcements from KuCoin. Announcements
include new listings, delistings, maintenance notices, and other
platform updates.

#### Workflow

1.  **Request**: Sends paginated GET request with optional filters.

2.  **Pagination**: Automatically fetches multiple pages via
    `.paginate()`.

3.  **Parsing**: Flattens paginated results into a single `data.table`.

4.  **Timestamp Conversion**: Coerces `c_time` (ms) to POSIXct in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/announcements`

#### Official Documentation

[KuCoin Get
Announcements](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)

Verified: 2026-03-10

#### Automated Trading Usage

- **New Listing Detection**: Monitor for new token listings to automate
  early trading strategies.

- **Maintenance Alerts**: Detect scheduled maintenance windows to pause
  trading bots.

- **Delisting Warnings**: Identify tokens being delisted to trigger
  position exit logic.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/announcements?currentPage=1&pageSize=50&annType=latest-announcements&lang=en_US'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "totalNum": 195,
        "totalPage": 13,
        "currentPage": 1,
        "pageSize": 15,
        "items": [
          {
            "annId": 129045,
            "annTitle": "KuCoin Will List Token XYZ",
            "annType": ["latest-announcements"],
            "annDesc": "Description of announcement...",
            "cTime": 1729594043000,
            "language": "en_US",
            "annUrl": "https://www.kucoin.com/announcement/..."
          }
        ]
      }
    }

#### Usage

    KucoinMarketData$get_announcements(
      query = list(),
      page_size = 50,
      max_pages = Inf
    )

#### Arguments

- `query`:

  Named list; filter parameters:

  - `annType` (character): Announcement type filter (e.g.,
    `"latest-announcements"`, `"activities"`, `"new-listings"`,
    `"product-updates"`).

  - `lang` (character): Language code (e.g., `"en_US"`, `"zh_CN"`).

  - `startTime` (integer): Start timestamp in milliseconds.

  - `endTime` (integer): End timestamp in milliseconds.

- `page_size`:

  Integer; results per page (default 50, max 100).

- `max_pages`:

  Numeric; max pages to fetch (default `Inf` for all).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `ann_id` (integer): Announcement identifier.

- `ann_title` (character): Announcement title.

- `ann_type` (list): Category tags as character vector.

- `ann_desc` (character): Short description text.

- `c_time` (POSIXct): Creation datetime (coerced from epoch
  milliseconds).

- `language` (character): Language code.

- `ann_url` (character): Full URL to the announcement page.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()

    # Get latest announcements
    anns <- market$get_announcements()
    print(anns[, .(ann_id, ann_title, c_time)])

    # Filter by type and language
    listings <- market$get_announcements(
      query = list(annType = "new-listings", lang = "en_US"),
      page_size = 20,
      max_pages = 3
    )
    }

------------------------------------------------------------------------

### Method `get_currency()`

Get Currency Details

Retrieves metadata for a specific currency, including per-chain deposit
and withdrawal details (fees, minimums, confirmations, contract
addresses).

#### Workflow

1.  **Request**: GET with currency code in URL path, optional chain
    filter.

2.  **Parsing**: Extracts top-level currency fields and nested `chains`
    array.

3.  **Flattening**: Combines currency metadata with chain details via
    `cbind`.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/currencies/{currency}`

#### Official Documentation

[KuCoin Get
Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)

Verified: 2026-03-10

#### Automated Trading Usage

- **Deposit Monitoring**: Check `is_deposit_enabled` and
  `deposit_min_size` before initiating deposits.

- **Withdrawal Validation**: Verify `is_withdraw_enabled`,
  `withdrawal_min_size`, `withdrawal_min_fee`, and `withdraw_precision`
  before submitting withdrawals.

- **Chain Selection**: Compare fees and confirmation times across chains
  to optimise transfers.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/currencies/BTC'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currency": "BTC",
        "name": "BTC",
        "fullName": "Bitcoin",
        "precision": 8,
        "confirms": null,
        "contractAddress": null,
        "isMarginEnabled": true,
        "isDebitEnabled": true,
        "chains": [
          {
            "chainName": "BTC",
            "withdrawalMinSize": "0.001",
            "depositMinSize": "0.0002",
            "withdrawFeeRate": "0",
            "withdrawalMinFee": "0.0005",
            "isWithdrawEnabled": true,
            "isDepositEnabled": true,
            "confirms": 3,
            "preConfirms": 1,
            "contractAddress": "",
            "withdrawPrecision": 8,
            "maxWithdraw": null,
            "maxDeposit": null,
            "needTag": false,
            "chainId": "btc"
          }
        ]
      }
    }

#### Usage

    KucoinMarketData$get_currency(currency, chain = NULL)

#### Arguments

- `currency`:

  Character; currency code (e.g., `"BTC"`, `"ETH"`, `"USDT"`).

- `chain`:

  Character or NULL; specific chain to filter (e.g., `"ERC20"`,
  `"TRC20"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with currency metadata and chain details:

- `currency` (character): Currency code.

- `name` (character): Short name.

- `full_name` (character): Full currency name.

- `precision` (integer): Decimal precision.

- `is_margin_enabled` (logical): Whether margin trading is supported.

- `is_debit_enabled` (logical): Whether debit is supported.

- `chain_name` (character): Blockchain network name.

- `withdrawal_min_size` (character): Minimum withdrawal amount.

- `deposit_min_size` (character): Minimum deposit amount.

- `withdrawal_min_fee` (character): Minimum withdrawal fee.

- `is_withdraw_enabled` (logical): Whether withdrawals are active.

- `is_deposit_enabled` (logical): Whether deposits are active.

- `confirms` (integer): Confirmations required.

- `pre_confirms` (integer): Pre-confirmations for early credit.

- `contract_address` (character): Token contract address.

- `withdraw_precision` (integer): Withdrawal decimal precision.

- `need_tag` (logical): Whether a memo/tag is required.

- `chain_id` (character): Chain identifier.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    btc <- market$get_currency("BTC")
    print(btc[, .(chain_name, withdrawal_min_fee, is_deposit_enabled, confirms)])

    # Specific chain
    usdt_erc20 <- market$get_currency("USDT", chain = "ERC20")
    }

------------------------------------------------------------------------

### Method `get_all_currencies()`

Get All Currencies

Retrieves metadata for all listed currencies, including chain-specific
deposit/withdrawal details. Useful for building currency reference
tables.

#### Workflow

1.  **Request**: GET for all currencies (no parameters).

2.  **Parsing**: Iterates over each currency, extracting chain details.

3.  **Flattening**: Combines per-currency metadata with chain arrays
    into rows.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/currencies`

#### Official Documentation

[KuCoin Get All
Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)

Verified: 2026-03-10

#### Automated Trading Usage

- **Universe Construction**: Build a reference table of all supported
  assets.

- **Chain Discovery**: Determine which blockchains are available for
  each asset.

- **Fee Comparison**: Compare withdrawal fees across all assets for
  arbitrage costing.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v3/currencies'

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "currency": "BTC",
          "name": "BTC",
          "fullName": "Bitcoin",
          "precision": 8,
          "confirms": null,
          "contractAddress": null,
          "isMarginEnabled": true,
          "isDebitEnabled": true,
          "chains": [
            {
              "chainName": "BTC",
              "withdrawalMinSize": "0.001",
              "depositMinSize": "0.0002",
              "withdrawalMinFee": "0.0005",
              "isWithdrawEnabled": true,
              "isDepositEnabled": true,
              "confirms": 3,
              "preConfirms": 1,
              "contractAddress": "",
              "withdrawPrecision": 8,
              "needTag": false,
              "chainId": "btc"
            }
          ]
        }
      ]
    }

#### Usage

    KucoinMarketData$get_all_currencies()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with currency metadata and chain details. Same columns
as `get_currency()`, one row per currency-chain combination.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    all_currencies <- market$get_all_currencies()
    # Find all ERC20 tokens
    erc20 <- all_currencies[chain_name == "ERC20"]
    print(erc20[, .(currency, withdrawal_min_fee, is_deposit_enabled)])
    }

------------------------------------------------------------------------

### Method `get_symbol()`

Get Symbol Details

Retrieves trading pair metadata for a specific symbol, including
precision increments, size limits, fee rates, and trading status.

#### Workflow

1.  **Request**: GET with symbol in URL path.

2.  **Parsing**: Returns single-row `data.table` with all symbol fields.

#### API Endpoint

`GET https://api.kucoin.com/api/v2/symbols/{symbol}`

#### Official Documentation

[KuCoin Get
Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)

Verified: 2026-03-10

#### Automated Trading Usage

- **Order Validation**: Read `price_increment`, `base_increment`,
  `base_min_size`, and `quote_min_size` to validate order parameters
  before submission.

- **Trading Status**: Check `enable_trading` before attempting to place
  orders.

- **Fee Calculation**: Use `maker_fee_coefficient` and
  `taker_fee_coefficient` for accurate P&L estimation.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v2/symbols/BTC-USDT'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbol": "BTC-USDT",
        "name": "BTC-USDT",
        "baseCurrency": "BTC",
        "quoteCurrency": "USDT",
        "feeCurrency": "USDT",
        "market": "USDS",
        "baseMinSize": "0.00001",
        "quoteMinSize": "0.1",
        "baseMaxSize": "10000000000",
        "quoteMaxSize": "99999999",
        "baseIncrement": "0.00000001",
        "quoteIncrement": "0.000001",
        "priceIncrement": "0.1",
        "priceLimitRate": "0.1",
        "minFunds": "0.1",
        "isMarginEnabled": true,
        "enableTrading": true,
        "feeCategory": 1,
        "makerFeeCoefficient": "1.00",
        "takerFeeCoefficient": "1.00",
        "st": false
      }
    }

#### Usage

    KucoinMarketData$get_symbol(symbol)

#### Arguments

- `symbol`:

  Character; trading symbol (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with symbol metadata:

- `symbol` (character): Trading pair identifier.

- `base_currency` (character): Base asset code.

- `quote_currency` (character): Quote asset code.

- `fee_currency` (character): Currency used for fees.

- `market` (character): Market segment.

- `base_min_size` (character): Minimum base order size.

- `quote_min_size` (character): Minimum quote order size.

- `base_max_size` (character): Maximum base order size.

- `base_increment` (character): Base size precision increment.

- `quote_increment` (character): Quote size precision increment.

- `price_increment` (character): Price tick size.

- `price_limit_rate` (character): Max price deviation rate.

- `min_funds` (character): Minimum order value in quote currency.

- `is_margin_enabled` (logical): Whether margin is available.

- `enable_trading` (logical): Whether trading is active.

- `maker_fee_coefficient` (character): Maker fee multiplier.

- `taker_fee_coefficient` (character): Taker fee multiplier.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    btc <- market$get_symbol("BTC-USDT")
    print(btc[, .(price_increment, base_increment, base_min_size, enable_trading)])
    }

------------------------------------------------------------------------

### Method `get_all_symbols()`

Get All Symbols

Retrieves metadata for all trading pairs, optionally filtered by market
segment. Returns the same fields as `get_symbol()` for every pair.

#### Workflow

1.  **Request**: GET with optional `market` query parameter.

2.  **Parsing**: Converts array of symbol objects to `data.table` rows.

#### API Endpoint

`GET https://api.kucoin.com/api/v2/symbols`

#### Official Documentation

[KuCoin Get All
Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)

Verified: 2026-03-10

#### Automated Trading Usage

- **Universe Filtering**: Filter by `market`, `enable_trading`,
  `is_margin_enabled` to build your trading universe.

- **Precision Lookup**: Cache the result and look up `price_increment` /
  `base_increment` before placing orders.

- **New Pair Detection**: Compare against a cached version to detect
  newly listed pairs.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v2/symbols?market=USDS'

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "symbol": "BTC-USDT",
          "name": "BTC-USDT",
          "baseCurrency": "BTC",
          "quoteCurrency": "USDT",
          "feeCurrency": "USDT",
          "market": "USDS",
          "baseMinSize": "0.00001",
          "quoteMinSize": "0.1",
          "baseMaxSize": "10000000000",
          "quoteMaxSize": "99999999",
          "baseIncrement": "0.00000001",
          "quoteIncrement": "0.000001",
          "priceIncrement": "0.1",
          "priceLimitRate": "0.1",
          "minFunds": "0.1",
          "isMarginEnabled": true,
          "enableTrading": true,
          "feeCategory": 1,
          "makerFeeCoefficient": "1.00",
          "takerFeeCoefficient": "1.00",
          "st": false
        },
        {
          "symbol": "ETH-USDT",
          "name": "ETH-USDT",
          "baseCurrency": "ETH",
          "quoteCurrency": "USDT",
          "feeCurrency": "USDT",
          "market": "USDS",
          "baseMinSize": "0.0001",
          "quoteMinSize": "0.1",
          "baseMaxSize": "10000000000",
          "quoteMaxSize": "99999999",
          "baseIncrement": "0.0000001",
          "quoteIncrement": "0.000001",
          "priceIncrement": "0.01",
          "priceLimitRate": "0.1",
          "minFunds": "0.1",
          "isMarginEnabled": true,
          "enableTrading": true,
          "feeCategory": 1,
          "makerFeeCoefficient": "1.00",
          "takerFeeCoefficient": "1.00",
          "st": false
        }
      ]
    }

\[ "symbol": "BTC-USDT", "name": "BTC-USDT", "baseCurrency": "BTC",
"quoteCurrency": "USDT", "feeCurrency": "USDT", "market": "USDS",
"baseMinSize": "0.00001", "quoteMinSize": "0.1", "baseMaxSize":
"10000000000", "quoteMaxSize": "99999999", "baseIncrement":
"0.00000001", "quoteIncrement": "0.000001", "priceIncrement": "0.1",
"priceLimitRate": "0.1", "minFunds": "0.1", "isMarginEnabled": true,
"enableTrading": true, "feeCategory": 1, "makerFeeCoefficient": "1.00",
"takerFeeCoefficient": "1.00", "st": false , "symbol": "ETH-USDT",
"name": "ETH-USDT", "baseCurrency": "ETH", "quoteCurrency": "USDT",
"feeCurrency": "USDT", "market": "USDS", "baseMinSize": "0.0001",
"quoteMinSize": "0.1", "baseMaxSize": "10000000000", "quoteMaxSize":
"99999999", "baseIncrement": "0.0000001", "quoteIncrement": "0.000001",
"priceIncrement": "0.01", "priceLimitRate": "0.1", "minFunds": "0.1",
"isMarginEnabled": true, "enableTrading": true, "feeCategory": 1,
"makerFeeCoefficient": "1.00", "takerFeeCoefficient": "1.00", "st":
false \]:
R:%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22symbol%22:%20%22BTC-USDT%22,%0A%20%20%20%20%20%20%22name%22:%20%22BTC-USDT%22,%0A%20%20%20%20%20%20%22baseCurrency%22:%20%22BTC%22,%0A%20%20%20%20%20%20%22quoteCurrency%22:%20%22USDT%22,%0A%20%20%20%20%20%20%22feeCurrency%22:%20%22USDT%22,%0A%20%20%20%20%20%20%22market%22:%20%22USDS%22,%0A%20%20%20%20%20%20%22baseMinSize%22:%20%220.00001%22,%0A%20%20%20%20%20%20%22quoteMinSize%22:%20%220.1%22,%0A%20%20%20%20%20%20%22baseMaxSize%22:%20%2210000000000%22,%0A%20%20%20%20%20%20%22quoteMaxSize%22:%20%2299999999%22,%0A%20%20%20%20%20%20%22baseIncrement%22:%20%220.00000001%22,%0A%20%20%20%20%20%20%22quoteIncrement%22:%20%220.000001%22,%0A%20%20%20%20%20%20%22priceIncrement%22:%20%220.1%22,%0A%20%20%20%20%20%20%22priceLimitRate%22:%20%220.1%22,%0A%20%20%20%20%20%20%22minFunds%22:%20%220.1%22,%0A%20%20%20%20%20%20%22isMarginEnabled%22:%20true,%0A%20%20%20%20%20%20%22enableTrading%22:%20true,%0A%20%20%20%20%20%20%22feeCategory%22:%201,%0A%20%20%20%20%20%20%22makerFeeCoefficient%22:%20%221.00%22,%0A%20%20%20%20%20%20%22takerFeeCoefficient%22:%20%221.00%22,%0A%20%20%20%20%20%20%22st%22:%20false%0A%20%20%20%20%7D,%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22symbol%22:%20%22ETH-USDT%22,%0A%20%20%20%20%20%20%22name%22:%20%22ETH-USDT%22,%0A%20%20%20%20%20%20%22baseCurrency%22:%20%22ETH%22,%0A%20%20%20%20%20%20%22quoteCurrency%22:%20%22USDT%22,%0A%20%20%20%20%20%20%22feeCurrency%22:%20%22USDT%22,%0A%20%20%20%20%20%20%22market%22:%20%22USDS%22,%0A%20%20%20%20%20%20%22baseMinSize%22:%20%220.0001%22,%0A%20%20%20%20%20%20%22quoteMinSize%22:%20%220.1%22,%0A%20%20%20%20%20%20%22baseMaxSize%22:%20%2210000000000%22,%0A%20%20%20%20%20%20%22quoteMaxSize%22:%20%2299999999%22,%0A%20%20%20%20%20%20%22baseIncrement%22:%20%220.0000001%22,%0A%20%20%20%20%20%20%22quoteIncrement%22:%20%220.000001%22,%0A%20%20%20%20%20%20%22priceIncrement%22:%20%220.01%22,%0A%20%20%20%20%20%20%22priceLimitRate%22:%20%220.1%22,%0A%20%20%20%20%20%20%22minFunds%22:%20%220.1%22,%0A%20%20%20%20%20%20%22isMarginEnabled%22:%20true,%0A%20%20%20%20%20%20%22enableTrading%22:%20true,%0A%20%20%20%20%20%20%22feeCategory%22:%201,%0A%20%20%20%20%20%20%22makerFeeCoefficient%22:%20%221.00%22,%0A%20%20%20%20%20%20%22takerFeeCoefficient%22:%20%221.00%22,%0A%20%20%20%20%20%20%22st%22:%20false%0A%20%20%20%20%7D%0A%20%20

#### Usage

    KucoinMarketData$get_all_symbols(market = NULL)

#### Arguments

- `market`:

  Character or NULL; market segment filter (e.g., `"USDS"`, `"BTC"`,
  `"KCS"`, `"DeFi"`). Use `get_market_list()` for available values.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with symbol metadata for all pairs. Same columns as
`get_symbol()`.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    all_symbols <- market$get_all_symbols()
    # Filter to active USDT pairs
    usdt_pairs <- all_symbols[quote_currency == "USDT" & enable_trading == TRUE]
    print(usdt_pairs[, .(symbol, base_min_size, price_increment)])
    }

------------------------------------------------------------------------

### Method `get_ticker()`

Get Ticker (Level 1 Market Data)

Retrieves real-time Level 1 ticker data for a symbol: the best bid/ask
prices, sizes, and the most recent trade price and size.

#### Workflow

1.  **Request**: GET with `symbol` query parameter.

2.  **Parsing**: Single-row `data.table` with ticker fields.

3.  **Timestamp Conversion**: Coerces `time` (ms) to POSIXct in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/market/orderbook/level1`

#### Official Documentation

[KuCoin Get
Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)

Verified: 2026-03-10

#### Automated Trading Usage

- **Spread Monitoring**: Calculate `best_ask - best_bid` for
  spread-based strategies.

- **Price Feeds**: Use as a lightweight price feed for mid-price
  calculation.

- **Execution Timing**: Monitor `sequence` to detect order book changes.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/market/orderbook/level1?symbol=BTC-USDT'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "time": 1729172965609,
        "sequence": "14609309753",
        "price": "67269",
        "size": "0.000025",
        "bestBid": "67267.5",
        "bestBidSize": "0.000025",
        "bestAsk": "67267.6",
        "bestAskSize": "1.24808993"
      }
    }

#### Usage

    KucoinMarketData$get_ticker(symbol)

#### Arguments

- `symbol`:

  Character; trading symbol (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `time` (POSIXct): Server datetime (coerced from epoch milliseconds).

- `sequence` (character): Order book sequence number.

- `price` (character): Last trade price.

- `size` (character): Last trade size.

- `best_bid` (character): Best bid price.

- `best_bid_size` (character): Size at best bid.

- `best_ask` (character): Best ask price.

- `best_ask_size` (character): Size at best ask.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    ticker <- market$get_ticker("BTC-USDT")
    spread <- as.numeric(ticker$best_ask) - as.numeric(ticker$best_bid)
    print(paste("Spread:", spread))
    }

------------------------------------------------------------------------

### Method `get_all_tickers()`

Get All Tickers

Retrieves ticker data for all trading pairs in a single request.
Snapshots are captured every 2 seconds on the server side.

#### Workflow

1.  **Request**: GET with no parameters (public, rate limit weight 15).

2.  **Parsing**: Extracts global `time` and array of `ticker` objects.

3.  **Flattening**: Converts ticker array to `data.table`, adds `time`.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/market/allTickers`

#### Official Documentation

[KuCoin Get All
Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)

Verified: 2026-03-10

#### Automated Trading Usage

- **Market Screening**: Scan all pairs for volume, change rate, or
  spread anomalies.

- **Pair Selection**: Rank pairs by `vol_value` to focus on liquid
  markets.

- **Cross-Pair Analysis**: Detect arbitrage opportunities across related
  pairs.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/market/allTickers'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "time": 1729173207043,
        "ticker": [
          {
            "symbol": "BTC-USDT",
            "symbolName": "BTC-USDT",
            "buy": "67192.5",
            "bestBidSize": "0.000025",
            "sell": "67192.6",
            "bestAskSize": "1.24949204",
            "changeRate": "-0.0014",
            "changePrice": "-98.5",
            "high": "68321.4",
            "low": "66683.3",
            "vol": "1836.03034612",
            "volValue": "124068431.06726933",
            "last": "67193",
            "averagePrice": "67281.21437289",
            "takerFeeRate": "0.001",
            "makerFeeRate": "0.001",
            "takerCoefficient": "1",
            "makerCoefficient": "1"
          }
        ]
      }
    }

#### Usage

    KucoinMarketData$get_all_tickers()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `symbol` (character): Trading pair.

- `symbol_name` (character): Display name.

- `buy` (character): Best bid price.

- `best_bid_size` (character): Size at best bid.

- `sell` (character): Best ask price.

- `best_ask_size` (character): Size at best ask.

- `change_rate` (character): 24h price change rate.

- `change_price` (character): 24h price change amount.

- `high` (character): 24h high price.

- `low` (character): 24h low price.

- `vol` (character): 24h volume in base currency.

- `vol_value` (character): 24h volume in quote currency.

- `last` (character): Last trade price.

- `average_price` (character): 24h average price.

- `taker_fee_rate` (character): Taker fee rate.

- `maker_fee_rate` (character): Maker fee rate.

- `time` (POSIXct): Snapshot datetime (coerced from epoch milliseconds).

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    all_tickers <- market$get_all_tickers()
    # Top 10 by 24h volume
    all_tickers[, vol_value := as.numeric(vol_value)]
    top10 <- all_tickers[order(-vol_value)][1:10]
    print(top10[, .(symbol, vol_value, change_rate)])
    }

------------------------------------------------------------------------

### Method `get_trade_history()`

Get Trade History

Retrieves the most recent 100 trades for a symbol. Each trade includes
the price, size, side (buy/sell), and nanosecond-precision timestamp.

#### Workflow

1.  **Request**: GET with `symbol` query parameter.

2.  **Parsing**: Converts array of trade objects to `data.table`.

3.  **Timestamp Conversion**: Coerces `time` (nanoseconds) to POSIXct
    in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/market/histories`

#### Official Documentation

[KuCoin Get Trade
History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)

Verified: 2026-03-10

#### Automated Trading Usage

- **Volume Analysis**: Aggregate recent trade sizes to estimate
  real-time volume flow.

- **Trade Direction**: Analyse buy/sell ratio for order flow imbalance
  signals.

- **Execution Benchmarking**: Compare your fills against recent market
  trades.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/market/histories?symbol=BTC-USDT'

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "sequence": "10976028003549185",
          "price": "67122",
          "size": "0.000025",
          "side": "buy",
          "time": 1729177117877000000
        }
      ]
    }

#### Usage

    KucoinMarketData$get_trade_history(symbol)

#### Arguments

- `symbol`:

  Character; trading symbol (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `sequence` (character): Trade sequence number.

- `price` (character): Trade price.

- `size` (character): Trade quantity.

- `side` (character): Trade direction (`"buy"` or `"sell"`).

- `time` (POSIXct): Trade datetime (coerced from nanosecond timestamp).

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    trades <- market$get_trade_history("BTC-USDT")
    # Buy/sell ratio
    buys <- trades[side == "buy", sum(as.numeric(size))]
    sells <- trades[side == "sell", sum(as.numeric(size))]
    print(paste("Buy/Sell ratio:", round(buys / sells, 3)))
    }

------------------------------------------------------------------------

### Method `get_part_orderbook()`

Get Partial Orderbook

Retrieves a partial order book snapshot with either 20 or 100 levels of
depth on each side (bids and asks). Public endpoint, no authentication
required.

#### Workflow

1.  **Validation**: Ensures `size` is 20 or 100.

2.  **Request**: GET with size embedded in endpoint path.

3.  **Parsing**: Calls `parse_orderbook()` to convert nested bid/ask
    arrays into a long-format `data.table` with `side`, `price`, and
    `size` columns.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/market/orderbook/level2_{20|100}`

#### Official Documentation

[KuCoin Get Part
Orderbook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-part-orderbook)

Verified: 2026-03-10

#### Automated Trading Usage

- **Depth Analysis**: Assess liquidity at various price levels for
  slippage estimation.

- **Support/Resistance**: Identify large resting orders as potential
  support/resistance.

- **Market Making**: Use top-of-book levels for dynamic spread
  calculation.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/market/orderbook/level2_20?symbol=BTC-USDT'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "time": 1729176273859,
        "sequence": "14610502970",
        "bids": [["66976.4", "0.69109872"], ["66976.3", "0.14377"]],
        "asks": [["66976.5", "0.05408199"], ["66976.8", "0.0005"]]
      }
    }

#### Usage

    KucoinMarketData$get_part_orderbook(symbol, size = 20)

#### Arguments

- `symbol`:

  Character; trading symbol (e.g., `"BTC-USDT"`).

- `size`:

  Integer; depth levels: `20` or `100` (default `20`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) in long format with columns:

- `time` (POSIXct): Server timestamp (coerced from epoch milliseconds).

- `sequence` (character): Order book sequence number.

- `side` (character): `"bid"` or `"ask"`.

- `price` (numeric): Price level.

- `size` (numeric): Size at that price.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    ob <- market$get_part_orderbook("BTC-USDT", size = 20)
    bids <- ob[side == "bid"]
    asks <- ob[side == "ask"]
    print(paste("Best bid:", bids$price[1], "Best ask:", asks$price[1]))
    }

------------------------------------------------------------------------

### Method `get_full_orderbook()`

Get Full Orderbook

Retrieves the complete order book for a symbol with all price levels.
**Requires authentication** (API key with Spot trading permissions).

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Calls `parse_orderbook()` for long-format conversion.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/market/orderbook/level2`

#### Official Documentation

[KuCoin Get Full
Orderbook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-full-orderbook)

Verified: 2026-03-10

#### Automated Trading Usage

- **Full Depth Analysis**: Build complete order book profiles for
  advanced strategies.

- **Liquidity Assessment**: Sum volume across all levels for total
  market depth.

- **VWAP Calculation**: Compute volume-weighted average price for large
  order execution.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/market/orderbook/level2?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "time": 1729176273859,
        "sequence": "14610502970",
        "bids": [["66976.4", "0.69109872"], ["66976.3", "0.14377"]],
        "asks": [["66976.5", "0.05408199"], ["66976.8", "0.0005"]]
      }
    }

#### Usage

    KucoinMarketData$get_full_orderbook(symbol)

#### Arguments

- `symbol`:

  Character; trading symbol (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) in long format with columns:

- `time` (POSIXct): Server timestamp (coerced from epoch milliseconds).

- `sequence` (character): Order book sequence number.

- `side` (character): `"bid"` or `"ask"`.

- `price` (numeric): Price level.

- `size` (numeric): Size at that price.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    full_ob <- market$get_full_orderbook("BTC-USDT")
    # Total bid depth
    total_bid_volume <- full_ob[side == "bid", sum(size)]
    print(paste("Total bid depth:", total_bid_volume, "BTC"))
    }

------------------------------------------------------------------------

### Method `get_24hr_stats()`

Get 24-Hour Statistics

Retrieves rolling 24-hour market statistics for a symbol, including
OHLCV data, change rate, average price, and fee rates.

#### Workflow

1.  **Request**: GET with `symbol` query parameter.

2.  **Parsing**: Single-row `data.table` with all statistics fields.

3.  **Timestamp Conversion**: Coerces `time` (ms) to POSIXct in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/market/stats`

#### Official Documentation

[KuCoin Get 24hr
Stats](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-24hr-stats)

Verified: 2026-03-10

#### Automated Trading Usage

- **Volatility Assessment**: Use `high - low` range or `change_rate` for
  volatility signals.

- **Volume Confirmation**: Verify `vol_value` exceeds minimum thresholds
  for strategy activation.

- **Fee-Adjusted Returns**: Use `taker_fee_rate`/`maker_fee_rate` for
  precise P&L calculation.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/market/stats?symbol=BTC-USDT'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "time": 1729175612158,
        "symbol": "BTC-USDT",
        "buy": "66982.4",
        "sell": "66982.5",
        "changeRate": "-0.0114",
        "changePrice": "-778.1",
        "high": "68107.7",
        "low": "66683.3",
        "vol": "1738.02898182",
        "volValue": "117321982.415978333",
        "last": "66981.5",
        "averagePrice": "67281.21437289",
        "takerFeeRate": "0.001",
        "makerFeeRate": "0.001",
        "takerCoefficient": "1",
        "makerCoefficient": "1"
      }
    }

#### Usage

    KucoinMarketData$get_24hr_stats(symbol)

#### Arguments

- `symbol`:

  Character; trading symbol (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `time` (POSIXct): Server datetime (coerced from epoch milliseconds).

- `symbol` (character): Trading pair.

- `buy` (character): Best bid price.

- `sell` (character): Best ask price.

- `change_rate` (character): 24h price change rate (decimal, e.g.,
  `"-0.0114"`).

- `change_price` (character): 24h price change amount.

- `high` (character): 24h high price.

- `low` (character): 24h low price.

- `vol` (character): 24h volume in base currency.

- `vol_value` (character): 24h volume in quote currency.

- `last` (character): Last trade price.

- `average_price` (character): 24h average price.

- `taker_fee_rate` (character): Taker fee rate.

- `maker_fee_rate` (character): Maker fee rate.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    stats <- market$get_24hr_stats("BTC-USDT")
    range <- as.numeric(stats$high) - as.numeric(stats$low)
    print(paste("24h range:", range, "USDT"))
    }

------------------------------------------------------------------------

### Method `get_market_list()`

Get Market List

Retrieves the list of all available market segments on KuCoin. Market
segments group trading pairs by theme (e.g., DeFi, Meme, Layer 1).

#### Workflow

1.  **Request**: GET with no parameters.

2.  **Parsing**: Returns character vector of market identifiers.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/markets`

#### Official Documentation

[KuCoin Get Market
List](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-market-list)

Verified: 2026-03-10

#### Automated Trading Usage

- **Market Discovery**: Enumerate available segments for the `market`
  filter in `get_all_symbols()`.

- **Sector Rotation**: Monitor segment-level volume for sector rotation
  strategies.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/markets'

#### JSON Response

    {
      "code": "200000",
      "data": ["USDS", "TON", "AI", "DePIN", "PoW", "BRC-20", "ETF",
               "KCS", "Meme", "Solana", "FIAT", "DeFi", "Polkadot",
               "BTC", "ALTS", "Layer 1"]
    }

#### Usage

    KucoinMarketData$get_market_list()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with column `market` containing segment identifiers.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    markets <- market$get_market_list()
    print(markets)
    # Use to filter symbols by market
    defi_symbols <- market$get_all_symbols(market = "DeFi")
    }

------------------------------------------------------------------------

### Method `get_klines()`

Get Klines (Candlestick Data)

Retrieves historical OHLCV candlestick data for a symbol. Automatically
segments requests to handle KuCoin's 1500-candle-per-request limit,
fetching and combining as many segments as needed to cover the requested
time range.

#### Workflow

1.  **Validation**: Validates timeframe string against allowed
    intervals.

2.  **Segmentation**: Splits the `[from, to]` range into chunks of up to
    1500 candles.

3.  **Fetching**: Requests each segment sequentially (sync) or in
    parallel (async).

4.  **Parsing**: Each segment's array-of-arrays response is converted to
    a typed `data.table`.

5.  **Deduplication**: Removes duplicate candles at segment boundaries.

6.  **Sorting**: Returns rows ordered by `datetime` ascending.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/market/candles`

#### Official Documentation

[KuCoin Get
Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)

Verified: 2026-03-10

#### Automated Trading Usage

- **Backtesting**: Fetch large historical ranges for strategy
  backtesting.

- **Technical Indicators**: Feed OHLCV data into indicator calculations
  (SMA, RSI, MACD).

- **Real-Time Candles**: Poll with short `[from, to]` windows for live
  candle updates.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/market/candles?symbol=BTC-USDT&type=1hour&startAt=1750389927&endAt=1750393527'

#### JSON Response

Each candle is an array:
`[timestamp, open, close, high, low, volume, turnover]`

    {
      "code": "200000",
      "data": [
        ["1566789720", "10411.5", "10401.9", "10411.5", "10396.3", "29.11357276", "302889.301529914"],
        ["1566789660", "10416", "10411.5", "10422.3", "10411.5", "15.61781842", "162703.708997029"]
      ]
    }

#### Usage

    KucoinMarketData$get_klines(
      symbol,
      timeframe = "15min",
      from = lubridate::now() - lubridate::dhours(24),
      to = lubridate::now()
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

- `timeframe`:

  Character; candle interval. One of: `"1min"`, `"3min"`, `"5min"`,
  `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`,
  `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`. Default
  `"15min"`.

- `from`:

  POSIXct; start time (default 24 hours ago).

- `to`:

  POSIXct; end time (default now).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `datetime` (POSIXct): Candle open datetime.

- `open` (numeric): Opening price.

- `high` (numeric): Highest price.

- `low` (numeric): Lowest price.

- `close` (numeric): Closing price.

- `volume` (numeric): Volume in base currency.

- `turnover` (numeric): Turnover in quote currency.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()

    # Last 24 hours of 15-minute candles
    klines <- market$get_klines("BTC-USDT")
    print(head(klines))

    # 7 days of hourly candles
    klines_7d <- market$get_klines(
      symbol = "ETH-USDT",
      timeframe = "1hour",
      from = lubridate::now() - lubridate::days(7),
      to = lubridate::now()
    )
    print(paste("Fetched", nrow(klines_7d), "candles"))
    }

------------------------------------------------------------------------

### Method `get_server_time()`

Get Server Time

Retrieves the current server timestamp from KuCoin in milliseconds.
Useful for detecting clock drift and ensuring HMAC signatures are valid.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/timestamp`

#### Official Documentation

[KuCoin Get Server
Time](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-server-time)

Verified: 2026-03-10

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/timestamp'

#### JSON Response

    {
      "code": "200000",
      "data": 1729176273859
    }

#### Automated Trading Usage

- **Clock Drift Detection**: Compare server time against local clock to
  detect drift.

- **Auth Debugging**: KuCoin tolerates +/-5s; verify your timestamps are
  in range.

- **Heartbeat**: Lightweight endpoint suitable for connectivity health
  checks.

#### Usage

    KucoinMarketData$get_server_time()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `server_time` (numeric): Server timestamp in milliseconds.

- `datetime` (POSIXct): Converted server datetime.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    st <- market$get_server_time()
    drift <- as.numeric(lubridate::now()) * 1000 - st$server_time
    cat("Clock drift:", round(drift), "ms\n")
    }

------------------------------------------------------------------------

### Method `get_service_status()`

Get Service Status

Retrieves the current operational status of the KuCoin platform. Bots
should check this before placing orders to avoid silent failures during
maintenance windows.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/status`

#### Official Documentation

[KuCoin Get Service
Status](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-service-status)

Verified: 2026-03-10

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/status'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "status": "open",
        "msg": ""
      }
    }

#### Automated Trading Usage

- **Pre-Flight Check**: Verify `status == "open"` before placing orders.

- **Maintenance Detection**: Detect `"close"` status to pause bot
  activity.

- **Cancel-Only Mode**: Detect `"cancelonly"` to only run cancellation
  logic.

#### Usage

    KucoinMarketData$get_service_status()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `status` (character): `"open"`, `"close"`, or `"cancelonly"`.

- `msg` (character): Optional remark/message.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    status <- market$get_service_status()
    if (status$status != "open") {
      cat("Exchange not operational:", status$msg, "\n")
    }
    }

------------------------------------------------------------------------

### Method `get_fiat_prices()`

Get Fiat Prices

Retrieves current fiat-equivalent prices for cryptocurrencies. Useful
for portfolio valuation and P&L reporting in fiat terms.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/prices`

#### Official Documentation

[KuCoin Get Fiat
Price](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-fiat-price)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/prices?base=USD&currencies=BTC,ETH,USDT'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "BTC": "67269.15",
        "ETH": "2485.73",
        "USDT": "1.0002"
      }
    }

#### Automated Trading Usage

- **Portfolio Valuation**: Convert all holdings to USD/EUR for dashboard
  reporting.

- **Position Sizing**: Size positions in native fiat currency terms.

- **PnL Reporting**: Calculate profit/loss in fiat for accounting.

#### Usage

    KucoinMarketData$get_fiat_prices(base = NULL, currencies = NULL)

#### Arguments

- `base`:

  Character or NULL; fiat currency ticker (e.g., `"USD"`, `"EUR"`).
  Default `"USD"`.

- `currencies`:

  Character or NULL; comma-separated crypto tickers to convert (e.g.,
  `"BTC,ETH,USDT"`). If NULL, returns all available.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `currency` (character): Cryptocurrency ticker.

- `price` (character): Fiat price as string.

#### Examples

    \dontrun{
    market <- KucoinMarketData$new()
    prices <- market$get_fiat_prices(base = "USD", currencies = "BTC,ETH,USDT")
    print(prices)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinMarketData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous usage
market <- KucoinMarketData$new()
ticker <- market$get_ticker("BTC-USDT")
print(ticker)

# Asynchronous usage
market_async <- KucoinMarketData$new(async = TRUE)
main <- coro::async(function() {
  ticker <- await(market_async$get_ticker("BTC-USDT"))
  print(ticker)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinMarketData$get_announcements`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()

# Get latest announcements
anns <- market$get_announcements()
print(anns[, .(ann_id, ann_title, c_time)])

# Filter by type and language
listings <- market$get_announcements(
  query = list(annType = "new-listings", lang = "en_US"),
  page_size = 20,
  max_pages = 3
)
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_currency`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
btc <- market$get_currency("BTC")
print(btc[, .(chain_name, withdrawal_min_fee, is_deposit_enabled, confirms)])

# Specific chain
usdt_erc20 <- market$get_currency("USDT", chain = "ERC20")
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_all_currencies`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
all_currencies <- market$get_all_currencies()
# Find all ERC20 tokens
erc20 <- all_currencies[chain_name == "ERC20"]
print(erc20[, .(currency, withdrawal_min_fee, is_deposit_enabled)])
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_symbol`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
btc <- market$get_symbol("BTC-USDT")
print(btc[, .(price_increment, base_increment, base_min_size, enable_trading)])
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_all_symbols`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
all_symbols <- market$get_all_symbols()
# Filter to active USDT pairs
usdt_pairs <- all_symbols[quote_currency == "USDT" & enable_trading == TRUE]
print(usdt_pairs[, .(symbol, base_min_size, price_increment)])
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_ticker`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
ticker <- market$get_ticker("BTC-USDT")
spread <- as.numeric(ticker$best_ask) - as.numeric(ticker$best_bid)
print(paste("Spread:", spread))
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_all_tickers`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
all_tickers <- market$get_all_tickers()
# Top 10 by 24h volume
all_tickers[, vol_value := as.numeric(vol_value)]
top10 <- all_tickers[order(-vol_value)][1:10]
print(top10[, .(symbol, vol_value, change_rate)])
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_trade_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
trades <- market$get_trade_history("BTC-USDT")
# Buy/sell ratio
buys <- trades[side == "buy", sum(as.numeric(size))]
sells <- trades[side == "sell", sum(as.numeric(size))]
print(paste("Buy/Sell ratio:", round(buys / sells, 3)))
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_part_orderbook`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
ob <- market$get_part_orderbook("BTC-USDT", size = 20)
bids <- ob[side == "bid"]
asks <- ob[side == "ask"]
print(paste("Best bid:", bids$price[1], "Best ask:", asks$price[1]))
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_full_orderbook`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
full_ob <- market$get_full_orderbook("BTC-USDT")
# Total bid depth
total_bid_volume <- full_ob[side == "bid", sum(size)]
print(paste("Total bid depth:", total_bid_volume, "BTC"))
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_24hr_stats`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
stats <- market$get_24hr_stats("BTC-USDT")
range <- as.numeric(stats$high) - as.numeric(stats$low)
print(paste("24h range:", range, "USDT"))
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_market_list`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
markets <- market$get_market_list()
print(markets)
# Use to filter symbols by market
defi_symbols <- market$get_all_symbols(market = "DeFi")
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_klines`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()

# Last 24 hours of 15-minute candles
klines <- market$get_klines("BTC-USDT")
print(head(klines))

# 7 days of hourly candles
klines_7d <- market$get_klines(
  symbol = "ETH-USDT",
  timeframe = "1hour",
  from = lubridate::now() - lubridate::days(7),
  to = lubridate::now()
)
print(paste("Fetched", nrow(klines_7d), "candles"))
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_server_time`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
st <- market$get_server_time()
drift <- as.numeric(lubridate::now()) * 1000 - st$server_time
cat("Clock drift:", round(drift), "ms\n")
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_service_status`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
status <- market$get_service_status()
if (status$status != "open") {
  cat("Exchange not operational:", status$msg, "\n")
}
} # }

## ------------------------------------------------
## Method `KucoinMarketData$get_fiat_prices`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- KucoinMarketData$new()
prices <- market$get_fiat_prices(base = "USD", currencies = "BTC,ETH,USDT")
print(prices)
} # }
```
