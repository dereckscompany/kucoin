# KucoinMarginData: Margin Market Information

KucoinMarginData: Margin Market Information

KucoinMarginData: Margin Market Information

## Details

Provides methods for querying margin-specific market data including
supported symbols, configuration, risk limits, and collateral ratios.
Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Cross Margin Symbols**: Query symbols available for cross margin
  trading.

- **Isolated Margin Symbols**: Query symbols available for isolated
  margin trading.

- **Margin Config**: Retrieve global margin configuration (max leverage,
  liquidation ratios).

- **Collateral Ratios**: Query collateral ratio tiers by currency.

- **Risk Limits**: Query borrow/hold limits per currency or symbol.

### Usage

Most methods are public (no auth required). `get_risk_limit()` requires
authentication with General permission.

### Official Documentation

[KuCoin Margin
Info](https://www.kucoin.com/docs-new/rest/margin-trading/risk-limit/get-margin-risk-limit)

### Endpoints Covered

|                             |                                    |      |
|-----------------------------|------------------------------------|------|
| Method                      | Endpoint                           | HTTP |
| get_cross_margin_symbols    | GET /api/v3/margin/symbols         | GET  |
| get_isolated_margin_symbols | GET /api/v1/isolated/symbols       | GET  |
| get_margin_config           | GET /api/v1/margin/config          | GET  |
| get_collateral_ratio        | GET /api/v3/margin/collateralRatio | GET  |
| get_risk_limit              | GET /api/v3/margin/currencies      | GET  |

## Super class

[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinMarginData`

## Methods

### Public methods

- [`KucoinMarginData$get_cross_margin_symbols()`](#method-KucoinMarginData-get_cross_margin_symbols)

- [`KucoinMarginData$get_isolated_margin_symbols()`](#method-KucoinMarginData-get_isolated_margin_symbols)

- [`KucoinMarginData$get_margin_config()`](#method-KucoinMarginData-get_margin_config)

- [`KucoinMarginData$get_collateral_ratio()`](#method-KucoinMarginData-get_collateral_ratio)

- [`KucoinMarginData$get_risk_limit()`](#method-KucoinMarginData-get_risk_limit)

- [`KucoinMarginData$clone()`](#method-KucoinMarginData-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_cross_margin_symbols()`

Get Cross Margin Symbols

Retrieves symbols (trading pairs) available for cross margin trading,
including increment sizes, min/max order sizes, and fee information.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/margin/symbols`

#### Official Documentation

[KuCoin Get Cross Margin
Symbols](https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-symbols-cross-margin)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/margin/symbols?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "timestamp": 1772993986642,
        "items": [
          {
            "symbol": "BTC-USDT",
            "name": "BTC-USDT",
            "enableTrading": true,
            "market": "USDS",
            "baseCurrency": "BTC",
            "quoteCurrency": "USDT",
            "baseIncrement": "0.00000001",
            "baseMinSize": "0.00001",
            "baseMaxSize": "10000000000",
            "quoteIncrement": "0.000001",
            "quoteMinSize": "0.1",
            "quoteMaxSize": "99999999",
            "priceIncrement": "0.1",
            "feeCurrency": "USDT",
            "priceLimitRate": "0.01",
            "minFunds": "0.1"
          }
        ]
      }
    }

#### Usage

    KucoinMarginData$get_cross_margin_symbols(query = list())

#### Arguments

- `query`:

  Named list; optional. Supported keys:

  - `symbol` (character): Filter by specific symbol (e.g.,
    `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per cross-margin symbol** and the
following columns (subset shown — KuCoin may add fields):

- `symbol` (character): Trading pair identifier (e.g. `"BTC-USDT"`).

- `name` (character): Display name.

- `enable_trading` (logical): Whether trading is enabled.

- `market` (character): Market category (e.g. `"USDS"`).

- `base_currency` (character): Base asset code.

- `quote_currency` (character): Quote asset code.

- `base_increment` (character): Minimum base-quantity step.

- `base_min_size` (character): Minimum order base quantity.

- `base_max_size` (character): Maximum order base quantity.

- `quote_increment` (character): Minimum quote-quantity step.

- `quote_min_size` (character): Minimum order quote quantity.

- `quote_max_size` (character): Maximum order quote quantity.

- `price_increment` (character): Minimum price step.

- `fee_currency` (character): Currency charged for trading fees.

- `price_limit_rate` (character): Maximum allowed price deviation.

- `min_funds` (character): Minimum order notional.

Empty response yields an empty `data.table`.

#### Examples

    \dontrun{
    margin_data <- KucoinMarginData$new()
    symbols <- margin_data$get_cross_margin_symbols(query = list(symbol = "BTC-USDT"))
    print(symbols)
    }

------------------------------------------------------------------------

### Method `get_isolated_margin_symbols()`

Get Isolated Margin Symbols

Retrieves symbols available for isolated margin trading, including
leverage limits, debt ratios, and borrowing parameters per pair.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/isolated/symbols`

#### Official Documentation

[KuCoin Get Isolated Margin
Symbols](https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-symbols-isolated-margin)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/isolated/symbols' \
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
          "symbol": "BTC-USDT",
          "symbolName": "BTC-USDT",
          "baseCurrency": "BTC",
          "quoteCurrency": "USDT",
          "maxLeverage": 10,
          "flDebtRatio": "0.97",
          "tradeEnable": true,
          "baseBorrowEnable": true,
          "quoteBorrowEnable": true,
          "baseTransferInEnable": true,
          "quoteTransferInEnable": true
        }
      ]
    }

#### Usage

    KucoinMarginData$get_isolated_margin_symbols()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per isolated-margin pair** and columns:

- `symbol` (character): Trading pair identifier.

- `symbol_name` (character): Display name.

- `base_currency` (character): Base asset code.

- `quote_currency` (character): Quote asset code.

- `max_leverage` (integer): Maximum leverage available.

- `fl_debt_ratio` (character): Forced-liquidation debt ratio.

- `trade_enable` (logical): Whether trading is enabled.

- `base_borrow_enable` (logical): Base-currency borrow allowed.

- `quote_borrow_enable` (logical): Quote-currency borrow allowed.

- `base_transfer_in_enable` (logical): Base-currency transfer-in
  allowed.

- `quote_transfer_in_enable` (logical): Quote-currency transfer-in
  allowed.

Empty response yields an empty `data.table`.

#### Examples

    \dontrun{
    margin_data <- KucoinMarginData$new()
    symbols <- margin_data$get_isolated_margin_symbols()
    print(symbols[trade_enable == TRUE])
    }

------------------------------------------------------------------------

### Method `get_margin_config()`

Get Margin Configuration

Retrieves global margin configuration including maximum leverage,
warning debt ratio, liquidation debt ratio, and list of supported
currencies.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/margin/config`

#### Official Documentation

[KuCoin Get Margin
Config](https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-margin-config)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/margin/config' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "maxLeverage": 10,
        "warningDebtRatio": "0.95",
        "liqDebtRatio": "0.97",
        "currencyList": ["BTC", "ETH", "USDT"]
      }
    }

#### Usage

    KucoinMarginData$get_margin_config()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per supported currency** (the
`currencyList` array is exploded so each currency gets its own row with
the config-level fields replicated). Columns:

- `currency` (character): Supported margin currency (e.g. `"BTC"`).

- `max_leverage` (integer): Maximum leverage.

- `warning_debt_ratio` (character): Warning debt ratio.

- `liq_debt_ratio` (character): Liquidation debt ratio.

Empty `currencyList` yields a zero-row `data.table` with this schema.

#### Examples

    \dontrun{
    margin_data <- KucoinMarginData$new()
    config <- margin_data$get_margin_config()
    cat("Max leverage:", config$max_leverage[1], "\n")
    cat("Supported currencies:", paste(config$currency, collapse = ", "), "\n")
    }

------------------------------------------------------------------------

### Method `get_collateral_ratio()`

Get Collateral Ratios

Retrieves collateral ratio tiers for margin currencies. Each currency
has multiple tiers based on collateral amount ranges.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/margin/collateralRatio`

#### Official Documentation

[KuCoin Get Collateral
Ratio](https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-margin-collateral-ratio)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/margin/collateralRatio?currencyList=BTC,ETH' \
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
          "currencyList": ["BTC"],
          "items": [
            {
              "lowerLimit": "0",
              "upperLimit": "10",
              "collateralRatio": "1.0"
            }
          ]
        }
      ]
    }

#### Usage

    KucoinMarginData$get_collateral_ratio(query = list())

#### Arguments

- `query`:

  Named list; optional. Supported keys:

  - `currencyList` (character): Comma-separated currencies (e.g.,
    `"BTC,ETH"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per (currency, tier) pair**. The nested
`currencyList`/`items` arrays are cross-joined to a flat long table.
Columns:

- `currency` (character): Currency code.

- `lower_limit` (character): Lower bound of the collateral range.

- `upper_limit` (character): Upper bound of the collateral range.

- `collateral_ratio` (character): Ratio applied in that range.

Empty response yields a zero-row `data.table` with this schema.

#### Examples

    \dontrun{
    margin_data <- KucoinMarginData$new()
    ratios <- margin_data$get_collateral_ratio(query = list(currencyList = "BTC,ETH"))
    print(ratios)
    # Filter high-ratio tiers
    ratios[as.numeric(collateral_ratio) >= 0.9]
    }

------------------------------------------------------------------------

### Method `get_risk_limit()`

Get Margin Risk Limit

Retrieves borrow and hold limits for margin currencies. Supports both
cross and isolated margin. This endpoint requires authentication.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/margin/currencies`

#### Official Documentation

[KuCoin Get Risk
Limit](https://www.kucoin.com/docs-new/rest/margin-trading/risk-limit/get-margin-risk-limit)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/margin/currencies?isIsolated=false&currency=BTC' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response (cross margin)

    {
      "code": "200000",
      "data": [
        {
          "currency": "BTC",
          "borrowMaxAmount": "100",
          "buyMaxAmount": "100",
          "holdMaxAmount": "100",
          "borrowCoefficient": "1",
          "marginCoefficient": "1",
          "precision": 8,
          "borrowMinAmount": "0.001",
          "borrowMinUnit": "0.001",
          "borrowEnabled": true
        }
      ]
    }

#### Usage

    KucoinMarginData$get_risk_limit(isIsolated, query = list())

#### Arguments

- `isIsolated`:

  Logical; `TRUE` for isolated margin limits, `FALSE` for cross margin.

- `query`:

  Named list; optional additional filters. Supported keys:

  - `currency` (character): Currency filter (cross margin).

  - `symbol` (character): Symbol filter (isolated margin only).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per currency** (cross) or **one row per
(symbol, currency) pair** (isolated). Common columns:

- `currency` (character): Currency code.

- `borrow_max_amount` (character): Maximum borrowable amount.

- `buy_max_amount` (character): Maximum buyable amount.

- `hold_max_amount` (character): Maximum hold amount.

- `borrow_coefficient` (character): Coefficient applied to borrows.

- `margin_coefficient` (character): Coefficient applied to margin.

- `precision` (integer): Decimal precision.

- `borrow_min_amount` (character): Minimum borrowable amount.

- `borrow_min_unit` (character): Minimum borrow step.

- `borrow_enabled` (logical): Whether borrowing is currently enabled.

For isolated margin an extra `symbol` (character) column is present.
Empty response yields an empty `data.table`.

#### Examples

    \dontrun{
    margin_data <- KucoinMarginData$new()

    # Cross margin risk limits
    limits <- margin_data$get_risk_limit(isIsolated = FALSE)
    print(limits)

    # Isolated margin risk limits for BTC-USDT
    limits <- margin_data$get_risk_limit(
      isIsolated = TRUE,
      query = list(symbol = "BTC-USDT")
    )
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinMarginData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
margin_data <- KucoinMarginData$new()

# Check available cross margin trading pairs
symbols <- margin_data$get_cross_margin_symbols()
print(symbols)

# Get margin configuration
config <- margin_data$get_margin_config()
print(config)
} # }


## ------------------------------------------------
## Method `KucoinMarginData$get_cross_margin_symbols`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin_data <- KucoinMarginData$new()
symbols <- margin_data$get_cross_margin_symbols(query = list(symbol = "BTC-USDT"))
print(symbols)
} # }

## ------------------------------------------------
## Method `KucoinMarginData$get_isolated_margin_symbols`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin_data <- KucoinMarginData$new()
symbols <- margin_data$get_isolated_margin_symbols()
print(symbols[trade_enable == TRUE])
} # }

## ------------------------------------------------
## Method `KucoinMarginData$get_margin_config`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin_data <- KucoinMarginData$new()
config <- margin_data$get_margin_config()
cat("Max leverage:", config$max_leverage[1], "\n")
cat("Supported currencies:", paste(config$currency, collapse = ", "), "\n")
} # }

## ------------------------------------------------
## Method `KucoinMarginData$get_collateral_ratio`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin_data <- KucoinMarginData$new()
ratios <- margin_data$get_collateral_ratio(query = list(currencyList = "BTC,ETH"))
print(ratios)
# Filter high-ratio tiers
ratios[as.numeric(collateral_ratio) >= 0.9]
} # }

## ------------------------------------------------
## Method `KucoinMarginData$get_risk_limit`
## ------------------------------------------------

if (FALSE) { # \dontrun{
margin_data <- KucoinMarginData$new()

# Cross margin risk limits
limits <- margin_data$get_risk_limit(isIsolated = FALSE)
print(limits)

# Isolated margin risk limits for BTC-USDT
limits <- margin_data$get_risk_limit(
  isIsolated = TRUE,
  query = list(symbol = "BTC-USDT")
)
} # }
```
