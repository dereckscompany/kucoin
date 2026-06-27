# KucoinTransfer: Internal Transfer Management

Provides methods for transferring funds between KuCoin accounts (main,
trade, margin, etc.) and between master and sub-accounts. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Fund Movement**: Transfer funds between account types (e.g., main →
  trade) so that deposited funds can be used for HF spot trading.

- **Sub-Account Funding**: Move funds between master and sub-accounts.

- **Balance Queries**: Check how much of a currency is available for
  transfer from a specific account type.

### Usage

All methods require authentication (valid API key, secret, passphrase).
The API key must have **FlexTransfers** (universal transfer) permission
for `add_transfer()`. The `get_transferable()` method requires only
**General** permission.

    # Synchronous usage
    transfer <- KucoinTransfer$new()
    balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")

    # Asynchronous usage
    transfer_async <- KucoinTransfer$new(async = TRUE)
    coro::async(function() {
      balance <- await(transfer_async$get_transferable(currency = "USDT", type = "MAIN"))
      print(balance)
    })()

### Official Documentation

[KuCoin Transfer
Endpoints](https://www.kucoin.com/docs-new/rest/account-info/transfer/flex-transfer)

### Endpoints Covered

|                  |                                          |      |
|------------------|------------------------------------------|------|
| Method           | Endpoint                                 | HTTP |
| add_transfer     | POST /api/v3/accounts/universal-transfer | POST |
| get_transferable | GET /api/v1/accounts/transferable        | GET  |

## Account Types

KuCoin uses separate accounts for different purposes:

- `"MAIN"`: Funding account — deposits land here by default.

- `"TRADE"`: Spot trading account — required for HF orders.

- `"MARGIN"`: Cross-margin account.

- `"ISOLATED"`: Isolated-margin account (requires
  `fromAccountTag`/`toAccountTag` for symbol).

- `"CONTRACT"`: Futures account.

## Transfer Types

- `"INTERNAL"`: Between your own accounts (e.g., MAIN → TRADE).

- `"PARENT_TO_SUB"`: From master to sub-account.

- `"SUB_TO_PARENT"`: From sub-account to master.

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinTransfer`

## Methods

### Public methods

- [`KucoinTransfer$add_transfer()`](#method-KucoinTransfer-add_transfer)

- [`KucoinTransfer$get_transferable()`](#method-KucoinTransfer-get_transferable)

- [`KucoinTransfer$clone()`](#method-KucoinTransfer-clone)

Inherited methods

- [`KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### `KucoinTransfer$add_transfer()`

Add Transfer (Universal)

Transfers funds between account types within your own KuCoin account, or
between master and sub-accounts. This is essential for trading bots
because deposits land in the **main** account, but HF spot orders
require funds in the **trade** account.

#### Workflow

1.  **Build Body**: Constructs JSON body with required transfer
    parameters.

2.  **Request**: Authenticated POST to the universal transfer endpoint.

3.  **Parsing**: Returns `data.table` with the transfer order ID.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/accounts/universal-transfer`

#### Official Documentation

[KuCoin Flex
Transfer](https://www.kucoin.com/docs-new/rest/account-info/transfer/flex-transfer)

Verified: 2026-05-23

#### Automated Trading Usage

- **Bot Startup**: Transfer deposited funds from MAIN to TRADE before
  placing orders.

- **Profit Harvesting**: Move profits from TRADE to MAIN before
  withdrawing.

- **Sub-Account Funding**: Distribute funds to sub-accounts running
  independent strategies.

- **Idempotency**: Use `clientOid` (UUID) to prevent duplicate transfers
  on retry.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/accounts/universal-transfer' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"clientOid":"64ccc0f164781800010d8c09","currency":"USDT","amount":"10","type":"INTERNAL","fromAccountType":"MAIN","toAccountType":"TRADE"}'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "6705f7248c6954000733ecac"
      }
    }

#### Usage

    KucoinTransfer$add_transfer(
      clientOid,
      currency,
      amount,
      type,
      fromAccountType,
      toAccountType,
      fromUserId = NULL,
      fromAccountTag = NULL,
      toUserId = NULL,
      toAccountTag = NULL
    )

#### Arguments

- `clientOid`:

  Character; unique client order ID for idempotency (max 128 bits, e.g.,
  UUID).

- `currency`:

  Character; currency code (e.g., `"BTC"`, `"USDT"`).

- `amount`:

  Character; transfer amount (positive, multiple of currency precision).

- `type`:

  Character; transfer type: `"INTERNAL"`, `"PARENT_TO_SUB"`, or
  `"SUB_TO_PARENT"`.

- `fromAccountType`:

  Character; source account type: `"MAIN"`, `"TRADE"`, `"CONTRACT"`,
  `"MARGIN"`, `"ISOLATED"`, `"MARGIN_V2"`, `"ISOLATED_V2"`.

- `toAccountType`:

  Character; destination account type (same options as
  `fromAccountType`).

- `fromUserId`:

  Character or NULL; source user ID (required for `"SUB_TO_PARENT"`
  transfers).

- `fromAccountTag`:

  Character or NULL; symbol for ISOLATED/ISOLATED_V2 source accounts
  (e.g., `"BTC-USDT"`).

- `toUserId`:

  Character or NULL; destination user ID (required for `"PARENT_TO_SUB"`
  transfers).

- `toAccountTag`:

  Character or NULL; symbol for ISOLATED/ISOLATED_V2 destination
  accounts (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `order_id` (character): The transfer order identifier.

#### Examples

    transfer <- KucoinTransfer$new()

    # Move USDT from main to trade account for spot trading
    result <- transfer$add_transfer(
      clientOid = "64ccc0f164781800010d8c09",
      currency = "USDT",
      amount = "100",
      type = "INTERNAL",
      fromAccountType = "MAIN",
      toAccountType = "TRADE"
    )
    print(result$order_id)

    # Transfer BTC from master to sub-account
    result <- transfer$add_transfer(
      clientOid = "unique-uuid-here",
      currency = "BTC",
      amount = "0.01",
      type = "PARENT_TO_SUB",
      fromAccountType = "MAIN",
      toAccountType = "MAIN",
      toUserId = "sub-user-id-here"
    )

------------------------------------------------------------------------

### `KucoinTransfer$get_transferable()`

Get Transferable Balance

Retrieves the amount of a currency that is available for transfer out of
a specific account type. Use this before calling `add_transfer()` to
verify sufficient funds are available.

#### Workflow

1.  **Request**: Authenticated GET with `currency` and `type` (required)
    and optional `tag` query parameters.

2.  **Parsing**: Returns a `data.table` with balance breakdown.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/accounts/transferable`

#### Official Documentation

[KuCoin Get Transfer
Quotas](https://www.kucoin.com/docs-new/rest/account-info/transfer/get-transfer-quotas)

Verified: 2026-05-23

#### Automated Trading Usage

- **Pre-Flight Check**: Verify `transferable` amount before initiating a
  transfer.

- **Balance Awareness**: Monitor `holds` to understand how much is
  locked in open orders.

- **Fund Routing**: Check transferable amounts across account types to
  optimise fund allocation.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/accounts/transferable?currency=USDT&type=MAIN' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currency": "USDT",
        "balance": "10.5",
        "available": "10.5",
        "holds": "0",
        "transferable": "10.5"
      }
    }

#### Usage

    KucoinTransfer$get_transferable(currency, type, tag = NULL)

#### Arguments

- `currency`:

  Character; currency code (e.g., `"BTC"`, `"USDT"`).

- `type`:

  Character; account type: `"MAIN"`, `"TRADE"`, `"MARGIN"`,
  `"ISOLATED"`, `"MARGIN_V2"`, `"ISOLATED_V2"`.

- `tag`:

  Character or NULL; trading pair symbol required for `"ISOLATED"`
  account type (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `currency` (character): Currency code.

- `balance` (character): Total funds in the account.

- `available` (character): Funds available to withdraw or trade.

- `holds` (character): Funds on hold (locked in open orders).

- `transferable` (character): Funds available for transfer.

#### Examples

    transfer <- KucoinTransfer$new()

    # Check transferable USDT in main account
    balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
    print(balance[, .(currency, balance, transferable)])

    # Check transferable BTC in trade account
    trade_bal <- transfer$get_transferable(currency = "BTC", type = "TRADE")
    print(trade_bal$transferable)

------------------------------------------------------------------------

### `KucoinTransfer$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinTransfer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
transfer <- KucoinTransfer$new()
balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
print(balance)

# Asynchronous
transfer_async <- KucoinTransfer$new(async = TRUE)
main <- coro::async(function() {
  balance <- await(transfer_async$get_transferable(currency = "USDT", type = "MAIN"))
  print(balance)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinTransfer$add_transfer()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
transfer <- KucoinTransfer$new()

# Move USDT from main to trade account for spot trading
result <- transfer$add_transfer(
  clientOid = "64ccc0f164781800010d8c09",
  currency = "USDT",
  amount = "100",
  type = "INTERNAL",
  fromAccountType = "MAIN",
  toAccountType = "TRADE"
)
print(result$order_id)

# Transfer BTC from master to sub-account
result <- transfer$add_transfer(
  clientOid = "unique-uuid-here",
  currency = "BTC",
  amount = "0.01",
  type = "PARENT_TO_SUB",
  fromAccountType = "MAIN",
  toAccountType = "MAIN",
  toUserId = "sub-user-id-here"
)
} # }

## ------------------------------------------------
## Method `KucoinTransfer$get_transferable()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
transfer <- KucoinTransfer$new()

# Check transferable USDT in main account
balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
print(balance[, .(currency, balance, transferable)])

# Check transferable BTC in trade account
trade_bal <- transfer$get_transferable(currency = "BTC", type = "TRADE")
print(trade_bal$transferable)
} # }
```
