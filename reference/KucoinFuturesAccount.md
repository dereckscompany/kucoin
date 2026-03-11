# KucoinFuturesAccount: Futures Account and Position Management

KucoinFuturesAccount: Futures Account and Position Management

KucoinFuturesAccount: Futures Account and Position Management

## Details

Provides methods for querying futures account details, managing
positions, configuring margin mode and leverage, and tracking funding
fee history. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Official Documentation

[KuCoin Futures
Positions](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-details)

### Endpoints Covered

|                           |                                           |      |
|---------------------------|-------------------------------------------|------|
| Method                    | Endpoint                                  | HTTP |
| get_account_overview      | GET /api/v1/account-overview              | GET  |
| get_position              | GET /api/v2/position                      | GET  |
| get_positions             | GET /api/v1/positions                     | GET  |
| get_positions_history     | GET /api/v1/history-positions             | GET  |
| get_margin_mode           | GET /api/v1/marginMode                    | GET  |
| set_margin_mode           | POST /api/v1/marginMode                   | POST |
| get_cross_margin_leverage | GET /api/v1/crossMarginLeverage           | GET  |
| set_cross_margin_leverage | POST /api/v1/crossMarginLeverage          | POST |
| get_max_open_size         | GET /api/v1/maxOpenSize                   | GET  |
| get_max_withdraw_margin   | GET /api/v1/maxWithdrawMargin             | GET  |
| add_isolated_margin       | POST /api/v1/marginDepositIn              | POST |
| remove_isolated_margin    | POST /api/v1/marginWithdrawOut            | POST |
| get_risk_limit            | GET /api/v1/contracts/risk-limit/{symbol} | GET  |
| get_funding_history       | GET /api/v1/funding-history               | GET  |

## Super class

[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinFuturesAccount`

## Methods

### Public methods

- [`KucoinFuturesAccount$new()`](#method-KucoinFuturesAccount-new)

- [`KucoinFuturesAccount$get_account_overview()`](#method-KucoinFuturesAccount-get_account_overview)

- [`KucoinFuturesAccount$get_position()`](#method-KucoinFuturesAccount-get_position)

- [`KucoinFuturesAccount$get_positions()`](#method-KucoinFuturesAccount-get_positions)

- [`KucoinFuturesAccount$get_positions_history()`](#method-KucoinFuturesAccount-get_positions_history)

- [`KucoinFuturesAccount$get_margin_mode()`](#method-KucoinFuturesAccount-get_margin_mode)

- [`KucoinFuturesAccount$set_margin_mode()`](#method-KucoinFuturesAccount-set_margin_mode)

- [`KucoinFuturesAccount$get_cross_margin_leverage()`](#method-KucoinFuturesAccount-get_cross_margin_leverage)

- [`KucoinFuturesAccount$set_cross_margin_leverage()`](#method-KucoinFuturesAccount-set_cross_margin_leverage)

- [`KucoinFuturesAccount$get_max_open_size()`](#method-KucoinFuturesAccount-get_max_open_size)

- [`KucoinFuturesAccount$get_max_withdraw_margin()`](#method-KucoinFuturesAccount-get_max_withdraw_margin)

- [`KucoinFuturesAccount$add_isolated_margin()`](#method-KucoinFuturesAccount-add_isolated_margin)

- [`KucoinFuturesAccount$remove_isolated_margin()`](#method-KucoinFuturesAccount-remove_isolated_margin)

- [`KucoinFuturesAccount$get_risk_limit()`](#method-KucoinFuturesAccount-get_risk_limit)

- [`KucoinFuturesAccount$get_funding_history()`](#method-KucoinFuturesAccount-get_funding_history)

- [`KucoinFuturesAccount$clone()`](#method-KucoinFuturesAccount-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new KucoinFuturesAccount instance.

#### Usage

    KucoinFuturesAccount$new(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    )

#### Arguments

- `keys`:

  List; API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md).

- `base_url`:

  Character; Futures API base URL. Defaults to
  [`get_futures_base_url()`](https://dereckscompany.github.io/kucoin/reference/get_futures_base_url.md).

- `async`:

  Logical; if TRUE, methods return promises.

- `time_source`:

  Character; `"local"` or `"server"`.

#### Returns

Invisible self.

------------------------------------------------------------------------

### Method `get_account_overview()`

Get Account Overview

Retrieves the futures account overview, including balance, equity,
margin, and P&L.

#### Workflow

1.  **Request**: Authenticated GET with `currency` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with account balance
    details.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/account-overview`

#### Official Documentation

[KuCoin Get Futures Account
Overview](https://www.kucoin.com/docs-new/rest/futures-trading/account/get-account-overview)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/account-overview?currency=USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "accountEquity": 99.8999305281,
        "unrealisedPNL": 0,
        "marginBalance": 99.8999305281,
        "positionMargin": 0,
        "orderMargin": 0,
        "frozenFunds": 0,
        "availableBalance": 99.8999305281,
        "currency": "USDT"
      }
    }

#### Usage

    KucoinFuturesAccount$get_account_overview(currency = "USDT")

#### Arguments

- `currency`:

  Character; settlement currency (e.g., `"USDT"`). Default `"USDT"`.

#### Returns

A single-row `data.table` with columns:

- `account_equity` (numeric): Total account equity.

- `unrealised_pnl` (numeric): Unrealised profit and loss.

- `margin_balance` (numeric): Margin balance (equity + unrealised PNL).

- `position_margin` (numeric): Margin held by open positions.

- `order_margin` (numeric): Margin held by open orders.

- `frozen_funds` (numeric): Frozen funds.

- `available_balance` (numeric): Available balance for trading.

- `currency` (character): Settlement currency code.

------------------------------------------------------------------------

### Method `get_position()`

Get Position Details

Retrieves position details for a specific symbol.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with position
    details.

3.  **Timestamp Conversion**: Coerces `opening_timestamp` and
    `current_timestamp` from milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v2/position`

#### Official Documentation

[KuCoin Get Position
Details](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-details)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v2/position?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "615ba79f27adbe000854c352",
        "symbol": "XBTUSDTM",
        "autoDeposit": false,
        "realLeverage": 2.05,
        "crossMode": false,
        "delevPercentage": 0.66,
        "currentQty": 1,
        "currentCost": "40.008",
        "currentComm": "0.0240048",
        "unrealisedCost": "40.008",
        "realisedGrossCost": "0.0",
        "realisedCost": "0.0240048",
        "isOpen": true,
        "markPrice": 40014.93,
        "markValue": "40.01493",
        "posCost": "40.008",
        "posInit": "20.004",
        "posComm": "0.02400588",
        "posMargin": "20.02800588",
        "unrealisedPnl": 0.00693,
        "unrealisedPnlPcnt": 0.0002,
        "avgEntryPrice": "40008.0",
        "liquidationPrice": "20332.0",
        "bankruptPrice": "20012.0",
        "settleCurrency": "USDT",
        "marginMode": "ISOLATED",
        "openingTimestamp": 1729176273859,
        "currentTimestamp": 1729176573859
      }
    }

#### Usage

    KucoinFuturesAccount$get_position(symbol)

#### Arguments

- `symbol`:

  Character; futures symbol (e.g., `"XBTUSDTM"`).

#### Returns

A `data.table` with columns:

- `id` (character): Position identifier.

- `symbol` (character): Contract symbol.

- `real_leverage` (numeric): Effective leverage.

- `cross_mode` (logical): Whether cross margin mode is active.

- `current_qty` (integer): Current position size in contracts.

- `current_cost` (character): Cost of the current position.

- `is_open` (logical): Whether the position is open.

- `mark_price` (numeric): Current mark price.

- `mark_value` (character): Mark value of the position.

- `pos_margin` (character): Position margin.

- `unrealised_pnl` (numeric): Unrealised profit and loss.

- `avg_entry_price` (character): Average entry price.

- `liquidation_price` (character): Estimated liquidation price.

- `margin_mode` (character): `"ISOLATED"` or `"CROSS"`.

- `opening_timestamp` (POSIXct): Position opened time (coerced from
  milliseconds).

- `current_timestamp` (POSIXct): Current server time (coerced from
  milliseconds).

------------------------------------------------------------------------

### Method `get_positions()`

Get All Positions

Retrieves all open positions.

#### Workflow

1.  **Request**: Authenticated GET with optional `currency` query
    parameter.

2.  **Parsing**: Returns a multi-row `data.table` with one row per open
    position.

3.  **Timestamp Conversion**: Coerces `opening_timestamp` and
    `current_timestamp` from milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/positions`

#### Official Documentation

[KuCoin Get Position
List](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-list)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/positions?currency=USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "id": "615ba79f27adbe000854c352",
          "symbol": "XBTUSDTM",
          "realLeverage": 2.05,
          "crossMode": false,
          "currentQty": 1,
          "currentCost": "40.008",
          "isOpen": true,
          "markPrice": 40014.93,
          "markValue": "40.01493",
          "posMargin": "20.02800588",
          "unrealisedPnl": 0.00693,
          "avgEntryPrice": "40008.0",
          "liquidationPrice": "20332.0",
          "marginMode": "ISOLATED",
          "openingTimestamp": 1729176273859,
          "currentTimestamp": 1729176573859
        },
        {
          "id": "615ba7a027adbe000854c358",
          "symbol": "ETHUSDTM",
          "realLeverage": 5.12,
          "crossMode": true,
          "currentQty": 10,
          "currentCost": "200.50",
          "isOpen": true,
          "markPrice": 2210.45,
          "markValue": "221.045",
          "posMargin": "44.209",
          "unrealisedPnl": 0.545,
          "avgEntryPrice": "2005.0",
          "liquidationPrice": "1650.0",
          "marginMode": "CROSS",
          "openingTimestamp": 1729176273859,
          "currentTimestamp": 1729176573859
        }
      ]
    }

#### Usage

    KucoinFuturesAccount$get_positions(currency = NULL)

#### Arguments

- `currency`:

  Character or NULL; filter by settlement currency.

#### Returns

A `data.table`; same columns as `get_position()`.

------------------------------------------------------------------------

### Method `get_positions_history()`

Get Position History

Retrieves historical position records.

#### Workflow

1.  **Request**: Authenticated GET with optional query parameters for
    filtering and pagination.

2.  **Parsing**: Extracts `items` from paginated response into a
    `data.table`.

3.  **Timestamp Conversion**: Coerces `open_time` and `close_time` from
    milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/history-positions`

#### Official Documentation

[KuCoin Get Position
History](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-positions-history)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/history-positions?symbol=XBTUSDTM&limit=20' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currentPage": 1,
        "pageSize": 20,
        "totalNum": 1,
        "totalPage": 1,
        "items": [
          {
            "closeId": "615ba79f27adbe000854c360",
            "positionId": "615ba79f27adbe000854c352",
            "uid": 123456789,
            "userId": "5e1234567890abcdef123456",
            "symbol": "XBTUSDTM",
            "settleCurrency": "USDT",
            "leverage": "10",
            "type": "Close",
            "pnl": "2.345",
            "realisedGrossCost": "2.5",
            "withdrawPnl": "0",
            "tradeFee": "0.155",
            "fundingFee": "0.012",
            "openTime": 1729176273859,
            "closeTime": 1729262673859,
            "openPrice": "40008.0",
            "closePrice": "40250.0",
            "marginMode": "ISOLATED"
          }
        ]
      }
    }

#### Usage

    KucoinFuturesAccount$get_positions_history(query = list())

#### Arguments

- `query`:

  Named list; query parameters. Optional: `symbol`, `from`, `to`,
  `limit`, `pageId`.

#### Returns

A `data.table` with columns:

- `symbol` (character): Contract symbol.

- `settle_currency` (character): Settlement currency.

- `realised_gross_pnl` (character): Gross realised PNL.

- `realised_pnl` (character): Net realised PNL (after fees).

- `leverage` (integer): Leverage used.

- `type` (character): Close type (e.g., `"Close"`).

- `open_time` (POSIXct): Position opened time (coerced from
  milliseconds).

- `close_time` (POSIXct): Position closed time (coerced from
  milliseconds).

------------------------------------------------------------------------

### Method `get_margin_mode()`

Get Margin Mode

Retrieves the current margin mode for a symbol.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with the current
    margin mode.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/marginMode`

#### Official Documentation

[KuCoin Get Margin
Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-margin-mode)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/marginMode?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbol": "XBTUSDTM",
        "marginMode": "ISOLATED"
      }
    }

#### Usage

    KucoinFuturesAccount$get_margin_mode(symbol)

#### Arguments

- `symbol`:

  Character; futures symbol.

#### Returns

A single-row `data.table` with columns:

- `symbol` (character): Contract symbol.

- `margin_mode` (character): `"ISOLATED"` or `"CROSS"`.

------------------------------------------------------------------------

### Method `set_margin_mode()`

Set Margin Mode

Switches the margin mode for a symbol between ISOLATED and CROSS.

#### Workflow

1.  **Build Body**: Constructs JSON body with `symbol` and `marginMode`.

2.  **Request**: Authenticated POST to the margin mode endpoint.

3.  **Parsing**: Returns a single-row `data.table` confirming the
    updated mode.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/marginMode`

#### Official Documentation

[KuCoin Modify Margin
Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/modify-margin-mode)

Verified: 2026-03-10

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/marginMode' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"symbol":"XBTUSDTM","marginMode":"CROSS"}'

#### JSON Request

    {
      "symbol": "XBTUSDTM",
      "marginMode": "CROSS"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbol": "XBTUSDTM",
        "marginMode": "CROSS"
      }
    }

#### Usage

    KucoinFuturesAccount$set_margin_mode(symbol, marginMode)

#### Arguments

- `symbol`:

  Character; futures symbol.

- `marginMode`:

  Character; `"ISOLATED"` or `"CROSS"`.

#### Returns

A single-row `data.table` with columns:

- `symbol` (character): Contract symbol.

- `margin_mode` (character): Updated margin mode.

------------------------------------------------------------------------

### Method `get_cross_margin_leverage()`

Get Cross Margin Leverage

Retrieves the current cross margin leverage for a symbol.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with the current
    leverage setting.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/crossMarginLeverage`

#### Official Documentation

[KuCoin Get Cross Margin
Leverage](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-cross-margin-leverage)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/crossMarginLeverage?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbol": "XBTUSDTM",
        "leverage": "5"
      }
    }

#### Usage

    KucoinFuturesAccount$get_cross_margin_leverage(symbol)

#### Arguments

- `symbol`:

  Character; futures symbol.

#### Returns

A single-row `data.table` with columns:

- `symbol` (character): Contract symbol.

- `leverage` (character): Current leverage multiplier.

------------------------------------------------------------------------

### Method `set_cross_margin_leverage()`

Set Cross Margin Leverage

Modifies the cross margin leverage for a symbol.

#### Workflow

1.  **Build Body**: Constructs JSON body with `symbol` and `leverage`.

2.  **Request**: Authenticated POST to the cross margin leverage
    endpoint.

3.  **Parsing**: Returns a single-row `data.table` confirming the
    updated leverage.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/crossMarginLeverage`

#### Official Documentation

[KuCoin Modify Cross Margin
Leverage](https://www.kucoin.com/docs-new/rest/futures-trading/positions/modify-cross-margin-leverage)

Verified: 2026-03-10

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/crossMarginLeverage' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"symbol":"XBTUSDTM","leverage":"10"}'

#### JSON Request

    {
      "symbol": "XBTUSDTM",
      "leverage": "10"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbol": "XBTUSDTM",
        "leverage": "10"
      }
    }

#### Usage

    KucoinFuturesAccount$set_cross_margin_leverage(symbol, leverage)

#### Arguments

- `symbol`:

  Character; futures symbol.

- `leverage`:

  Integer; leverage multiplier.

#### Returns

A single-row `data.table` with columns:

- `symbol` (character): Contract symbol.

- `leverage` (character): Updated leverage multiplier.

------------------------------------------------------------------------

### Method `get_max_open_size()`

Get Maximum Open Size

Retrieves the maximum number of contracts that can be opened.

#### Workflow

1.  **Request**: Authenticated GET with `symbol`, `price`, and
    `leverage` query parameters.

2.  **Parsing**: Returns a single-row `data.table` with maximum buy and
    sell open sizes.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/maxOpenSize`

#### Official Documentation

[KuCoin Get Max Open
Size](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-maximum-open-position-size)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/maxOpenSize?symbol=XBTUSDTM&price=40000&leverage=10' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbol": "XBTUSDTM",
        "maxBuyOpenSize": 100,
        "maxSellOpenSize": 100
      }
    }

#### Usage

    KucoinFuturesAccount$get_max_open_size(symbol, price, leverage)

#### Arguments

- `symbol`:

  Character; futures symbol.

- `price`:

  Character; order price.

- `leverage`:

  Integer; leverage multiplier.

#### Returns

A single-row `data.table` with columns:

- `symbol` (character): Contract symbol.

- `max_buy_open_size` (integer): Maximum buy contracts.

- `max_sell_open_size` (integer): Maximum sell contracts.

------------------------------------------------------------------------

### Method `get_max_withdraw_margin()`

Get Maximum Withdrawable Margin

Retrieves the maximum margin that can be withdrawn from an isolated
position.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with the maximum
    withdrawable margin.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/maxWithdrawMargin`

#### Official Documentation

[KuCoin Get Max Withdraw
Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-max-withdraw-margin)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/maxWithdrawMargin?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": "21.1234"
    }

#### Usage

    KucoinFuturesAccount$get_max_withdraw_margin(symbol)

#### Arguments

- `symbol`:

  Character; futures symbol.

#### Returns

A single-row `data.table` with the maximum withdrawable margin amount.

------------------------------------------------------------------------

### Method `add_isolated_margin()`

Add Isolated Margin

Deposits additional margin into an isolated margin position.

#### Workflow

1.  **Build Body**: Constructs JSON body with `symbol`, `margin`, and
    `bizNo`.

2.  **Request**: Authenticated POST to the margin deposit endpoint.

3.  **Parsing**: Returns a single-row `data.table` confirming the
    deposit.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/marginDepositIn`

#### Official Documentation

[KuCoin Add Isolated
Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/add-isolated-margin)

Verified: 2026-03-10

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/marginDepositIn' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"symbol":"XBTUSDTM","margin":5,"bizNo":"abc123-unique-id"}'

#### JSON Request

    {
      "symbol": "XBTUSDTM",
      "margin": 5,
      "bizNo": "abc123-unique-id"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "615ba79f27adbe000854c370",
        "symbol": "XBTUSDTM",
        "margin": "5",
        "marginType": "ADD"
      }
    }

#### Usage

    KucoinFuturesAccount$add_isolated_margin(symbol, margin, bizNo)

#### Arguments

- `symbol`:

  Character; futures symbol.

- `margin`:

  Numeric; amount of margin to add.

- `bizNo`:

  Character; unique business ID for idempotency.

#### Returns

A single-row `data.table` with columns:

- `id` (character): Margin operation ID.

- `symbol` (character): Contract symbol.

- `margin` (character): Amount deposited.

- `margin_type` (character): Operation type (e.g., `"ADD"`).

------------------------------------------------------------------------

### Method `remove_isolated_margin()`

Remove Isolated Margin

Withdraws excess margin from an isolated margin position.

#### Workflow

1.  **Build Body**: Constructs JSON body with `symbol` and
    `withdrawAmount`.

2.  **Request**: Authenticated POST to the margin withdrawal endpoint.

3.  **Parsing**: Returns a single-row `data.table` confirming the
    withdrawal.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/marginWithdrawOut`

#### Official Documentation

[KuCoin Remove Isolated
Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/remove-isolated-margin)

Verified: 2026-03-10

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/marginWithdrawOut' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"symbol":"XBTUSDTM","withdrawAmount":3}'

#### JSON Request

    {
      "symbol": "XBTUSDTM",
      "withdrawAmount": 3
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "615ba79f27adbe000854c375",
        "symbol": "XBTUSDTM",
        "margin": "3",
        "marginType": "WITHDRAW"
      }
    }

#### Usage

    KucoinFuturesAccount$remove_isolated_margin(symbol, withdrawAmount)

#### Arguments

- `symbol`:

  Character; futures symbol.

- `withdrawAmount`:

  Numeric; amount of margin to withdraw.

#### Returns

A single-row `data.table` with columns:

- `id` (character): Margin operation ID.

- `symbol` (character): Contract symbol.

- `margin` (character): Amount withdrawn.

- `margin_type` (character): Operation type.

------------------------------------------------------------------------

### Method `get_risk_limit()`

Get Risk Limit Level

Retrieves risk limit tiers for a futures contract.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` embedded in the URL
    path.

2.  **Parsing**: Returns a multi-row `data.table` with one row per risk
    limit tier.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/contracts/risk-limit/{symbol}`

#### Official Documentation

[KuCoin Get Risk Limit
Level](https://www.kucoin.com/docs-new/rest/futures-trading/risk-limit/get-futures-risk-limit-level)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/contracts/risk-limit/XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "symbol": "XBTUSDTM",
          "level": 1,
          "maxRiskLimit": 500000,
          "minRiskLimit": 0,
          "maxLeverage": 125,
          "initialMargin": 0.008,
          "maintainMargin": 0.004
        },
        {
          "symbol": "XBTUSDTM",
          "level": 2,
          "maxRiskLimit": 1000000,
          "minRiskLimit": 500000,
          "maxLeverage": 100,
          "initialMargin": 0.01,
          "maintainMargin": 0.005
        },
        {
          "symbol": "XBTUSDTM",
          "level": 3,
          "maxRiskLimit": 2000000,
          "minRiskLimit": 1000000,
          "maxLeverage": 75,
          "initialMargin": 0.0133,
          "maintainMargin": 0.007
        }
      ]
    }

#### Usage

    KucoinFuturesAccount$get_risk_limit(symbol)

#### Arguments

- `symbol`:

  Character; futures symbol.

#### Returns

A `data.table` with columns:

- `symbol` (character): Contract symbol.

- `level` (integer): Risk limit tier level.

- `max_risk_limit` (integer): Maximum position value for this tier.

- `min_risk_limit` (integer): Minimum position value for this tier.

- `max_leverage` (integer): Maximum leverage at this tier.

- `initial_margin` (numeric): Initial margin rate.

- `maintain_margin` (numeric): Maintenance margin rate.

------------------------------------------------------------------------

### Method `get_funding_history()`

Get Private Funding Fee History

Retrieves your personal funding fee settlement records.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` (required) and optional
    pagination/filtering query parameters.

2.  **Parsing**: Extracts `dataList` from response into a `data.table`.

3.  **Timestamp Conversion**: Coerces `time_point` from milliseconds to
    POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/funding-history`

#### Official Documentation

[KuCoin Get Private Funding
History](https://www.kucoin.com/docs-new/rest/futures-trading/funding-fees/get-private-funding-history)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/funding-history?symbol=XBTUSDTM&maxCount=100' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "dataList": [
          {
            "id": 1742547891234,
            "symbol": "XBTUSDTM",
            "timePoint": 1729176000000,
            "fundingRate": 0.0001,
            "markPrice": 40125.56,
            "positionQty": 10,
            "positionCost": "400.12556",
            "funding": "-0.04001256",
            "settleCurrency": "USDT"
          },
          {
            "id": 1742547891235,
            "symbol": "XBTUSDTM",
            "timePoint": 1729147200000,
            "fundingRate": -0.00005,
            "markPrice": 39987.12,
            "positionQty": 10,
            "positionCost": "399.8712",
            "funding": "0.01999356",
            "settleCurrency": "USDT"
          }
        ],
        "hasMore": false
      }
    }

#### Usage

    KucoinFuturesAccount$get_funding_history(symbol, query = list())

#### Arguments

- `symbol`:

  Character; futures symbol.

- `query`:

  Named list; additional query parameters. Optional: `startAt`, `endAt`,
  `reverse`, `offset`, `forward`, `maxCount`.

#### Returns

A `data.table` with columns:

- `id` (integer): Record identifier.

- `symbol` (character): Contract symbol.

- `time_point` (POSIXct): Funding settlement time (coerced from
  milliseconds).

- `funding_rate` (numeric): Funding rate applied.

- `mark_price` (numeric): Mark price at settlement.

- `position_qty` (integer): Position size at settlement.

- `position_cost` (character): Position cost at settlement.

- `funding` (character): Funding fee amount (negative = paid, positive =
  received).

- `settle_currency` (character): Settlement currency.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinFuturesAccount$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
futures_account <- KucoinFuturesAccount$new()

# Get account overview
overview <- futures_account$get_account_overview(currency = "USDT")

# Get open positions
positions <- futures_account$get_positions()

# Get position for a specific symbol
pos <- futures_account$get_position("XBTUSDTM")
} # }
```
