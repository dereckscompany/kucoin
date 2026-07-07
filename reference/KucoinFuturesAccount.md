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

|                           |                                             |      |
|---------------------------|---------------------------------------------|------|
| Method                    | Endpoint                                    | HTTP |
| get_account_overview      | GET /api/v1/account-overview                | GET  |
| get_position              | GET /api/v2/position                        | GET  |
| get_positions             | GET /api/v1/positions                       | GET  |
| get_positions_history     | GET /api/v1/history-positions               | GET  |
| get_margin_mode           | GET /api/v2/position/getMarginMode          | GET  |
| set_margin_mode           | POST /api/v2/position/changeMarginMode      | POST |
| get_cross_margin_leverage | GET /api/v2/getCrossUserLeverage            | GET  |
| set_cross_margin_leverage | POST /api/v2/changeCrossUserLeverage        | POST |
| get_max_open_size         | GET /api/v2/getMaxOpenSize                  | GET  |
| get_max_withdraw_margin   | GET /api/v1/margin/maxWithdrawMargin        | GET  |
| add_isolated_margin       | POST /api/v1/position/margin/deposit-margin | POST |
| remove_isolated_margin    | POST /api/v1/margin/withdrawMargin          | POST |
| get_risk_limit            | GET /api/v1/contracts/risk-limit/{symbol}   | GET  |
| get_funding_history       | GET /api/v1/funding-history                 | GET  |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
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

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) Futures API base URL. Defaults to
  [`get_futures_base_url()`](https://dereckscompany.github.io/kucoin/reference/get_futures_base_url.md).

- `async`:

  (scalar\<logical\>) if TRUE, methods return promises.

- `time_source`:

  (scalar\<character\>) `"local"` or `"server"`.

#### Returns

(class\<KucoinFuturesAccount\>) invisibly, the new instance.

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

KuCoin Get Account - Futures:
<https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-futures>

Verified: 2026-05-23

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

  (scalar\<character\>) settlement currency (e.g., `"USDT"`). Default
  `"USDT"`.

#### Returns

(data.table \| promise\<data.table\>) one row giving the futures account
overview: total account equity, unrealised profit and loss, margin
balance, position and order margin, frozen funds, available balance, and
the settlement currency code:

- account_equity (numeric \| NA) the account equity.

- unrealised_pnl (numeric \| NA) the unrealised pnl.

- margin_balance (numeric \| NA) the margin balance.

- available_balance (numeric \| NA) the available balance.

- available_margin (numeric \| NA) the available margin.

- currency (character) the currency code.

- risk_ratio (numeric \| NA) the risk ratio.

- max_withdraw_amount (numeric \| NA) the max withdraw amount.

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

KuCoin Get Position Details:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-details>

Verified: 2026-05-23

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

  (scalar\<character\>) futures symbol (e.g., `"XBTUSDTM"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the position
details: identifier, contract symbol, auto-deposit flag, effective
leverage, cross-mode flag, auto-deleveraging percentage, current
position size, current and unrealised/realised costs and commissions,
open flag, mark price and value, position cost/init/commission/margin,
unrealised PnL and its percentage, average entry, liquidation and
bankruptcy prices, settlement currency, margin mode, position side, and
the opening and current datetimes (POSIXct, coerced from epoch
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

Verified: 2026-05-23

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

  (scalar\<character\> \| NULL) filter by settlement currency.

#### Returns

(data.table \| promise\<data.table\>) one row per open position,
carrying the same columns as `get_position()`; an empty `data.table`
when there are no open positions.

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

KuCoin Get Position History:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-positions-history>

Verified: 2026-05-23

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

  (list) query parameters. Optional keys: symbol, from, to, limit,
  pageId.

#### Returns

(data.table \| promise\<data.table\>) one row per closed position
record, each giving the close-event and position identifiers, numeric
and string user IDs, contract symbol, settlement currency, leverage,
close type, realised PnL, gross realised cost, withdrawn PnL, trade and
funding fees, average open and close prices, margin mode, and the
opening and closing datetimes (POSIXct, coerced from epoch
milliseconds); an empty `data.table` when no history records match.

------------------------------------------------------------------------

### Method `get_margin_mode()`

Get Margin Mode

Retrieves the current margin mode for a symbol.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with the current
    margin mode.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v2/position/getMarginMode`

#### Official Documentation

[KuCoin Get Margin
Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-margin-mode)

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v2/position/getMarginMode?symbol=XBTUSDTM' \
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

  (scalar\<character\>) futures symbol.

#### Returns

(data.table \| promise\<data.table\>) one row giving the contract symbol
and its current margin mode (`"ISOLATED"` or `"CROSS"`):

- symbol (character) the trading pair symbol.

- margin_mode (character) the margin mode.

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

`POST https://api-futures.kucoin.com/api/v2/position/changeMarginMode`

#### Official Documentation

[KuCoin Switch Margin
Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/switch-margin-mode)

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v2/position/changeMarginMode' \
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

    KucoinFuturesAccount$set_margin_mode(symbol, margin_mode)

#### Arguments

- `symbol`:

  (scalar\<character\>) futures symbol.

- `margin_mode`:

  (scalar\<character\>) `"ISOLATED"` or `"CROSS"`.

#### Returns

(data.table \| promise\<data.table\>) one row giving the contract symbol
and its updated margin mode:

- symbol (character) the trading pair symbol.

- margin_mode (character) the margin mode.

------------------------------------------------------------------------

### Method `get_cross_margin_leverage()`

Get Cross Margin Leverage

Retrieves the current cross margin leverage for a symbol.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` query parameter.

2.  **Parsing**: Returns a single-row `data.table` with the current
    leverage setting.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v2/getCrossUserLeverage`

#### Official Documentation

KuCoin Get Cross Margin Leverage:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-cross-margin-leverage>

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v2/getCrossUserLeverage?symbol=XBTUSDTM' \
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

  (scalar\<character\>) futures symbol.

#### Returns

(data.table \| promise\<data.table\>) one row giving the contract symbol
and its current cross-margin leverage multiplier:

- symbol (character) the trading pair symbol.

- leverage (character \| NA) the leverage.

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

`POST https://api-futures.kucoin.com/api/v2/changeCrossUserLeverage`

#### Official Documentation

KuCoin Modify Cross Margin Leverage:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/modify-cross-margin-leverage>

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v2/changeCrossUserLeverage' \
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

  (scalar\<character\>) futures symbol.

- `leverage`:

  (scalar\<count in \[1, Inf\[\>) leverage multiplier.

#### Returns

(data.table \| promise\<data.table\>) one row giving the contract symbol
and its updated cross-margin leverage multiplier:

- symbol (character) the trading pair symbol.

- leverage (character \| NA) the leverage.

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

`GET https://api-futures.kucoin.com/api/v2/getMaxOpenSize`

#### Official Documentation

[KuCoin Get Max Open
Size](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-max-open-size)

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v2/getMaxOpenSize?symbol=XBTUSDTM&price=40000&leverage=10' \
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

  (scalar\<character\>) futures symbol.

- `price`:

  (scalar\<numeric in \]0, Inf\[\>) order price.

- `leverage`:

  (scalar\<count in \[1, Inf\[\>) leverage multiplier.

#### Returns

(data.table \| promise\<data.table\>) one row giving the contract symbol
and the maximum number of contracts that can be opened on the buy and
sell sides:

- symbol (character) the trading pair symbol.

- max_buy_open_size (integer \| NA) the max buy open size.

- max_sell_open_size (integer \| NA) the max sell open size.

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

`GET https://api-futures.kucoin.com/api/v1/margin/maxWithdrawMargin`

#### Official Documentation

KuCoin Get Max Withdraw Margin:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-max-withdraw-margin>

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/margin/maxWithdrawMargin?symbol=XBTUSDTM' \
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

  (scalar\<character\>) futures symbol.

#### Returns

(data.table \| promise\<data.table\>) one row giving the maximum amount
of isolated margin that can be withdrawn from the position, returned by
KuCoin as a fixed-precision string so the caller controls numeric
coercion.

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

`POST https://api-futures.kucoin.com/api/v1/position/margin/deposit-margin`

#### Official Documentation

[KuCoin Add Isolated
Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/add-isolated-margin)

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/position/margin/deposit-margin' \
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

    KucoinFuturesAccount$add_isolated_margin(symbol, margin, biz_no)

#### Arguments

- `symbol`:

  (scalar\<character\>) futures symbol.

- `margin`:

  (scalar\<numeric\>) amount of margin to add.

- `biz_no`:

  (scalar\<character\>) unique business ID for idempotency.

#### Returns

(data.table \| promise\<data.table\>) one row giving the margin
operation ID, contract symbol, amount deposited, and operation type
(e.g., `"ADD"`):

- id (character) the record identifier.

- symbol (character) the trading pair symbol.

- margin (numeric \| NA) the margin amount.

- margin_type (character) the margin type.

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

`POST https://api-futures.kucoin.com/api/v1/margin/withdrawMargin`

#### Official Documentation

KuCoin Remove Isolated Margin:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/remove-isolated-margin>

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/margin/withdrawMargin' \
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

    KucoinFuturesAccount$remove_isolated_margin(symbol, withdraw_amount)

#### Arguments

- `symbol`:

  (scalar\<character\>) futures symbol.

- `withdraw_amount`:

  (scalar\<numeric\>) amount of margin to withdraw.

#### Returns

(data.table \| promise\<data.table\>) one row giving the margin
operation ID, contract symbol, amount withdrawn, and operation type:

- id (character) the record identifier.

- symbol (character) the trading pair symbol.

- margin (numeric \| NA) the margin amount.

- margin_type (character) the margin type.

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

KuCoin Get Isolated Margin Risk Limit:
<https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-isolated-margin-risk-limit>

Verified: 2026-05-23

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

  (scalar\<character\>) futures symbol.

#### Returns

(data.table \| promise\<data.table\>) one row per risk-limit tier, each
giving the contract symbol, tier level, maximum and minimum position
values for the tier, maximum leverage, and the initial and maintenance
margin rates; an empty `data.table` when KuCoin returns no tiers.

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

KuCoin Get Private Funding History:
<https://www.kucoin.com/docs-new/rest/futures-trading/funding-fees/get-private-funding-history>

Verified: 2026-05-23

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

  (scalar\<character\>) futures symbol.

- `query`:

  (list) additional query parameters. Optional keys: startAt, endAt,
  reverse, offset, forward, maxCount.

#### Returns

(data.table \| promise\<data.table\>) one row per funding settlement,
each giving the record identifier, contract symbol, the funding
settlement datetime (POSIXct, coerced from epoch milliseconds), funding
rate applied, mark price at settlement, position size and cost at
settlement, the funding fee amount (negative = paid, positive =
received), and the settlement currency; an empty `data.table` when no
records are returned.

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
