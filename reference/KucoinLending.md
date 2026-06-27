# KucoinLending: Margin Lending Operations

Provides methods for lending assets on the KuCoin margin lending market,
managing purchase (lend) orders, and redeeming lent assets. Inherits
from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Loan Market Data**: Query available lending currencies and
  historical interest rates.

- **Purchase (Lend)**: Lend assets to the margin pool to earn interest.

- **Modify**: Update interest rate on existing lending orders.

- **Redeem**: Withdraw lent assets from the lending pool.

- **Order Queries**: Retrieve purchase and redemption order history.

### Usage

All methods except `get_loan_market_rate()` require authentication with
Margin permission.

### Official Documentation

[KuCoin Lending
Market](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-loan-market)

### Endpoints Covered

|                      |                                        |      |
|----------------------|----------------------------------------|------|
| Method               | Endpoint                               | HTTP |
| get_loan_market      | GET /api/v3/project/list               | GET  |
| get_loan_market_rate | GET /api/v3/project/marketInterestRate | GET  |
| purchase             | POST /api/v3/purchase                  | POST |
| modify_purchase      | POST /api/v3/lend/purchase/update      | POST |
| get_purchase_orders  | GET /api/v3/purchase/orders            | GET  |
| redeem               | POST /api/v3/redeem                    | POST |
| get_redeem_orders    | GET /api/v3/redeem/orders              | GET  |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinLending`

## Methods

### Public methods

- [`KucoinLending$get_loan_market()`](#method-KucoinLending-get_loan_market)

- [`KucoinLending$get_loan_market_rate()`](#method-KucoinLending-get_loan_market_rate)

- [`KucoinLending$purchase()`](#method-KucoinLending-purchase)

- [`KucoinLending$modify_purchase()`](#method-KucoinLending-modify_purchase)

- [`KucoinLending$get_purchase_orders()`](#method-KucoinLending-get_purchase_orders)

- [`KucoinLending$redeem()`](#method-KucoinLending-redeem)

- [`KucoinLending$get_redeem_orders()`](#method-KucoinLending-get_redeem_orders)

- [`KucoinLending$clone()`](#method-KucoinLending-clone)

Inherited methods

- [`KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### `KucoinLending$get_loan_market()`

Get Loan Market Information

Retrieves information about available lending currencies, including
minimum/maximum purchase sizes and current market interest rates.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/project/list`

#### Official Documentation

[KuCoin Get Currency
Information](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-loan-market)

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/project/list?currency=USDT' \
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
          "currency": "USDT",
          "purchaseEnable": true,
          "redeemEnable": true,
          "increment": "0.01",
          "minPurchaseSize": "10",
          "maxPurchaseSize": "1000000",
          "interestIncrement": "0.0001",
          "minInterestRate": "0.004",
          "marketInterestRate": "0.05",
          "maxInterestRate": "0.1",
          "autoPurchaseEnable": true
        }
      ]
    }

#### Usage

    KucoinLending$get_loan_market(query = list())

#### Arguments

- `query`:

  Named list; optional filter. Supported keys:

  - `currency` (character): Filter by currency (e.g., `"USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per lending currency** and columns:

- `currency` (character): Currency code (e.g. `"USDT"`).

- `purchase_enable` (logical): Whether new purchases are accepted.

- `redeem_enable` (logical): Whether redemptions are accepted.

- `increment` (character): Smallest purchase-size step.

- `min_purchase_size` (character): Minimum purchase amount.

- `max_purchase_size` (character): Maximum purchase amount.

- `interest_increment` (character): Smallest interest-rate step.

- `min_interest_rate` (character): Minimum permitted interest rate.

- `market_interest_rate` (character): Current market rate.

- `max_interest_rate` (character): Maximum permitted interest rate.

- `auto_purchase_enable` (logical): Whether auto-purchase is available.

Empty response yields an empty `data.table`.

#### Examples

    lending <- KucoinLending$new()
    market <- lending$get_loan_market(query = list(currency = "USDT"))
    print(market)

------------------------------------------------------------------------

### `KucoinLending$get_loan_market_rate()`

Get Loan Market Interest Rate History

Retrieves the market interest rate history for a currency over the past
7 days.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/project/marketInterestRate`

#### Official Documentation

[KuCoin Get Market Interest
Rate](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-loan-market-interest-rate)

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/project/marketInterestRate?currency=USDT' \
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
          "time": "202603070000",
          "marketInterestRate": "0.05"
        }
      ]
    }

#### Usage

    KucoinLending$get_loan_market_rate(currency)

#### Arguments

- `currency`:

  Character; the currency to query (e.g., `"USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per observation** and columns:

- `time` (character): Timestamp string (YYYYMMDDHHmm format).

- `market_interest_rate` (character): Market interest rate at that time.

Empty response yields an empty `data.table`.

#### Examples

    lending <- KucoinLending$new()
    rates <- lending$get_loan_market_rate(currency = "USDT")
    print(rates)

------------------------------------------------------------------------

### `KucoinLending$purchase()`

Purchase (Lend) Assets

Lends a specified amount of currency to the margin lending pool at a
given interest rate to earn passive income.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/purchase`

#### Official Documentation

[KuCoin
Purchase](https://www.kucoin.com/docs-new/rest/margin-trading/credit/purchase)

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/purchase' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"currency":"USDT","size":"1000","interestRate":"0.05"}'

#### JSON Request

    {
      "currency": "USDT",
      "size": "1000",
      "interestRate": "0.05"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderNo": "abc123"
      }
    }

#### Usage

    KucoinLending$purchase(currency, size, interestRate)

#### Arguments

- `currency`:

  Character; the currency to lend (e.g., `"USDT"`).

- `size`:

  Numeric; the amount to lend.

- `interestRate`:

  Numeric; the interest rate (e.g., `0.05` for 5%).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with column:

- `order_no` (character): Lending order number.

#### Examples

    lending <- KucoinLending$new()
    order <- lending$purchase(currency = "USDT", size = 1000, interestRate = 0.05)
    print(order$order_no)

------------------------------------------------------------------------

### `KucoinLending$modify_purchase()`

Modify Purchase Interest Rate

Updates the interest rate on an existing lending order. Rate changes
take effect at the start of the next hour.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/lend/purchase/update`

#### Official Documentation

[KuCoin Modify
Purchase](https://www.kucoin.com/docs-new/rest/margin-trading/credit/modify-purchase)

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/lend/purchase/update' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"currency":"USDT","purchaseOrderNo":"abc123","interestRate":"0.06"}'

#### JSON Request

    {
      "currency": "USDT",
      "purchaseOrderNo": "abc123",
      "interestRate": "0.06"
    }

#### JSON Response

    {
      "code": "200000",
      "data": null
    }

#### Usage

    KucoinLending$modify_purchase(currency, purchaseOrderNo, interestRate)

#### Arguments

- `currency`:

  Character; the currency of the lending order.

- `purchaseOrderNo`:

  Character; the order number to modify.

- `interestRate`:

  Numeric; the new interest rate.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`), single row
with columns:

- `currency` (character): The lending currency.

- `purchase_order_no` (character): The modified order number.

- `interest_rate` (numeric): The new interest rate.

- `status` (character): `"success"`.

#### Examples

    lending <- KucoinLending$new()
    lending$modify_purchase(
      currency = "USDT",
      purchaseOrderNo = "abc123",
      interestRate = 0.06
    )

------------------------------------------------------------------------

### `KucoinLending$get_purchase_orders()`

Get Purchase Orders

Retrieves lending purchase order history with optional filters.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/purchase/orders`

#### Official Documentation

[KuCoin Get Purchase
Orders](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-purchase-orders)

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/purchase/orders?currency=USDT&status=DONE&currentPage=1&pageSize=50' \
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
        "pageSize": 50,
        "totalNum": 1,
        "totalPage": 1,
        "items": [
          {
            "currency": "USDT",
            "purchaseOrderNo": "abc123",
            "purchaseSize": "1000",
            "matchSize": "800",
            "interestRate": "0.05",
            "incomeSize": "3.42",
            "applyTime": 1729655606816,
            "status": "DONE"
          }
        ]
      }
    }

#### Usage

    KucoinLending$get_purchase_orders(query = list())

#### Arguments

- `query`:

  Named list; filters. Supported keys:

  - `status` (character): **Required.** Order status (e.g., `"DONE"`,
    `"PENDING"`).

  - `currency` (character): Currency filter (e.g., `"USDT"`).

  - `purchaseOrderNo` (character): Specific order number.

  - `currentPage` (integer): Page number.

  - `pageSize` (integer): Items per page.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per purchase order** and columns:

- `currency` (character): Lent currency.

- `purchase_order_no` (character): Purchase order number.

- `purchase_size` (character): Amount lent.

- `match_size` (character): Amount that has been matched.

- `interest_rate` (character): Rate of the lending order.

- `income_size` (character): Accrued income so far.

- `apply_time` (POSIXct): Order creation time (millisecond epoch
  coerced).

- `status` (character): Order status (e.g. `"DONE"`).

Empty response yields an empty `data.table`.

#### Examples

    lending <- KucoinLending$new()
    orders <- lending$get_purchase_orders(query = list(currency = "USDT", status = "DONE"))
    print(orders)

------------------------------------------------------------------------

### `KucoinLending$redeem()`

Redeem Lent Assets

Redeems (withdraws) lent assets from the lending pool. The redemption is
processed against a specific purchase order.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/redeem`

#### Official Documentation

[KuCoin
Redeem](https://www.kucoin.com/docs-new/rest/margin-trading/credit/redeem)

Verified: 2026-05-23

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/redeem' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"currency":"USDT","size":"500","purchaseOrderNo":"abc123"}'

#### JSON Request

    {
      "currency": "USDT",
      "size": "500",
      "purchaseOrderNo": "abc123"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderNo": "abc123"
      }
    }

#### Usage

    KucoinLending$redeem(currency, size, purchaseOrderNo)

#### Arguments

- `currency`:

  Character; the currency to redeem (e.g., `"USDT"`).

- `size`:

  Numeric; the amount to redeem.

- `purchaseOrderNo`:

  Character; the purchase order to redeem from.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with column:

- `order_no` (character): Redemption order number.

#### Examples

    lending <- KucoinLending$new()
    result <- lending$redeem(
      currency = "USDT", size = 500, purchaseOrderNo = "abc123"
    )
    print(result$order_no)

------------------------------------------------------------------------

### `KucoinLending$get_redeem_orders()`

Get Redeem Orders

Retrieves redemption order history with optional filters.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/redeem/orders`

#### Official Documentation

[KuCoin Get Redeem
Orders](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-redeem-orders)

Verified: 2026-05-23

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/redeem/orders?currency=USDT&status=DONE&currentPage=1&pageSize=50' \
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
        "pageSize": 50,
        "totalNum": 1,
        "totalPage": 1,
        "items": [
          {
            "currency": "USDT",
            "purchaseOrderNo": "abc123",
            "redeemOrderNo": "def456",
            "redeemSize": "500",
            "receiptSize": "500",
            "applyTime": 1729655606816,
            "status": "DONE"
          }
        ]
      }
    }

#### Usage

    KucoinLending$get_redeem_orders(query = list())

#### Arguments

- `query`:

  Named list; filters. Supported keys:

  - `status` (character): **Required.** Order status (e.g., `"DONE"`,
    `"PENDING"`).

  - `currency` (character): Currency filter (e.g., `"USDT"`).

  - `redeemOrderNo` (character): Specific redemption order number.

  - `currentPage` (integer): Page number.

  - `pageSize` (integer): Items per page.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with **one row per redemption order** and columns:

- `currency` (character): Redeemed currency.

- `purchase_order_no` (character): Source purchase order.

- `redeem_order_no` (character): Redemption order number.

- `redeem_size` (character): Requested redeem amount.

- `receipt_size` (character): Amount actually received.

- `apply_time` (POSIXct): Order creation time (millisecond epoch
  coerced).

- `status` (character): Order status (e.g. `"DONE"`).

Empty response yields an empty `data.table`.

#### Examples

    lending <- KucoinLending$new()
    orders <- lending$get_redeem_orders(query = list(currency = "USDT", status = "DONE"))
    print(orders)

------------------------------------------------------------------------

### `KucoinLending$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinLending$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
lending <- KucoinLending$new()

# Check available lending currencies
market <- lending$get_loan_market()
print(market)

# Lend USDT at a specified interest rate
order <- lending$purchase(currency = "USDT", size = 1000, interestRate = 0.05)
print(order)

# Redeem lent USDT
result <- lending$redeem(currency = "USDT", size = 1000,
                         purchaseOrderNo = order$order_no)
} # }


## ------------------------------------------------
## Method `KucoinLending$get_loan_market()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
market <- lending$get_loan_market(query = list(currency = "USDT"))
print(market)
} # }

## ------------------------------------------------
## Method `KucoinLending$get_loan_market_rate()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
rates <- lending$get_loan_market_rate(currency = "USDT")
print(rates)
} # }

## ------------------------------------------------
## Method `KucoinLending$purchase()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
order <- lending$purchase(currency = "USDT", size = 1000, interestRate = 0.05)
print(order$order_no)
} # }

## ------------------------------------------------
## Method `KucoinLending$modify_purchase()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
lending$modify_purchase(
  currency = "USDT",
  purchaseOrderNo = "abc123",
  interestRate = 0.06
)
} # }

## ------------------------------------------------
## Method `KucoinLending$get_purchase_orders()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
orders <- lending$get_purchase_orders(query = list(currency = "USDT", status = "DONE"))
print(orders)
} # }

## ------------------------------------------------
## Method `KucoinLending$redeem()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
result <- lending$redeem(
  currency = "USDT", size = 500, purchaseOrderNo = "abc123"
)
print(result$order_no)
} # }

## ------------------------------------------------
## Method `KucoinLending$get_redeem_orders()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
lending <- KucoinLending$new()
orders <- lending$get_redeem_orders(query = list(currency = "USDT", status = "DONE"))
print(orders)
} # }
```
