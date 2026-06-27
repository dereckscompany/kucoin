# KucoinWithdrawal: Withdrawal Management

Provides methods for creating, cancelling, and querying cryptocurrency
withdrawals on KuCoin. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Withdrawal Creation**: Initiate withdrawals to external addresses,
  KuCoin UIDs, email, or phone.

- **Withdrawal Cancellation**: Cancel pending withdrawals that are still
  in `PROCESSING` status.

- **Quota Queries**: Check withdrawal limits, minimum fees, and
  available balances per currency/chain.

- **History Retrieval**: Retrieve paginated withdrawal records with
  status tracking and timestamps.

- **Detail Lookup**: Get comprehensive details for a specific withdrawal
  by ID.

### Usage

All methods require authentication (valid API key, secret, passphrase).
The API key must have **Withdrawal** permission for `add_withdrawal()`
and `cancel_withdrawal()`. Query methods (`get_*`) require only
**General** permission.

    # Synchronous usage
    withdrawal <- KucoinWithdrawal$new()
    quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")

    # Asynchronous usage
    withdrawal_async <- KucoinWithdrawal$new(async = TRUE)
    coro::async(function() {
      quotas <- await(withdrawal_async$get_withdrawal_quotas(currency = "BTC"))
      print(quotas)
    })()

### Official Documentation

[KuCoin Withdrawal
Endpoints](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/withdraw-v3)

### Endpoints Covered

|                        |                                           |        |
|------------------------|-------------------------------------------|--------|
| Method                 | Endpoint                                  | HTTP   |
| add_withdrawal         | POST /api/v3/withdrawals                  | POST   |
| cancel_withdrawal      | DELETE /api/v1/withdrawals/{withdrawalId} | DELETE |
| get_withdrawal_quotas  | GET /api/v1/withdrawals/quotas            | GET    |
| get_withdrawal_history | GET /api/v1/withdrawals                   | GET    |
| get_withdrawal_by_id   | GET /api/v1/withdrawals/{withdrawalId}    | GET    |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinWithdrawal`

## Methods

### Public methods

- [`KucoinWithdrawal$add_withdrawal()`](#method-KucoinWithdrawal-add_withdrawal)

- [`KucoinWithdrawal$cancel_withdrawal()`](#method-KucoinWithdrawal-cancel_withdrawal)

- [`KucoinWithdrawal$get_withdrawal_quotas()`](#method-KucoinWithdrawal-get_withdrawal_quotas)

- [`KucoinWithdrawal$get_withdrawal_history()`](#method-KucoinWithdrawal-get_withdrawal_history)

- [`KucoinWithdrawal$get_withdrawal_by_id()`](#method-KucoinWithdrawal-get_withdrawal_by_id)

- [`KucoinWithdrawal$clone()`](#method-KucoinWithdrawal-clone)

Inherited methods

- [`KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### `KucoinWithdrawal$add_withdrawal()`

Add Withdrawal

Initiates a new withdrawal request. Supports withdrawals to external
blockchain addresses, KuCoin UIDs, email addresses, and phone numbers.
Only withdrawals in `PROCESSING` status can later be cancelled via
`cancel_withdrawal()`.

#### Workflow

1.  **Build Body**: Constructs JSON body with required and optional
    fields.

2.  **Request**: Authenticated POST to the withdrawal endpoint.

3.  **Parsing**: Returns `data.table` with the withdrawal ID.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/withdrawals`

#### Official Documentation

[KuCoin Withdraw
V3](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/withdraw-v3)

Verified: 2026-05-23

#### Automated Trading Usage

- **Profit Extraction**: Withdraw profits to a cold wallet at regular
  intervals.

- **Arbitrage Settlement**: Move funds off-exchange after capturing
  arbitrage spreads.

- **Internal Transfers**: Use `isInner = TRUE` for fee-free transfers
  between KuCoin accounts.

- **Multi-Chain Support**: Specify `chain` (e.g., `"trx"`, `"eth"`,
  `"bsc"`) to select the cheapest or fastest network.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/withdrawals' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"currency":"USDT","toAddress":"TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8","amount":"10","withdrawType":"ADDRESS","chain":"trx"}'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "withdrawalId": "670deec84d64da0007d7c946"
      }
    }

#### Usage

    KucoinWithdrawal$add_withdrawal(
      currency,
      toAddress,
      amount,
      withdrawType,
      chain = NULL,
      memo = NULL,
      isInner = NULL,
      remark = NULL,
      feeDeductType = NULL
    )

#### Arguments

- `currency`:

  Character; currency code (e.g., `"BTC"`, `"USDT"`).

- `toAddress`:

  Character; withdrawal destination address, UID, email, or phone
  number.

- `amount`:

  Character; withdrawal amount (must be positive, multiple of currency
  precision).

- `withdrawType`:

  Character; withdrawal type: `"ADDRESS"`, `"UID"`, `"MAIL"`, or
  `"PHONE"`.

- `chain`:

  Character; blockchain network identifier (e.g., `"eth"`, `"trx"`,
  `"bsc"`). Required by the KuCoin API.

- `memo`:

  Character or NULL; address memo/tag (required for some currencies like
  XRP, XLM).

- `isInner`:

  Logical or NULL; if `TRUE`, this is an internal KuCoin transfer (no
  on-chain fee).

- `remark`:

  Character or NULL; optional remark for the withdrawal.

- `feeDeductType`:

  Character or NULL; fee deduction type: `"INTERNAL"` or `"EXTERNAL"`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `withdrawal_id` (character): The unique withdrawal identifier.

#### Examples

    withdrawal <- KucoinWithdrawal$new()

    # Withdraw USDT via TRC20
    result <- withdrawal$add_withdrawal(
      currency = "USDT",
      toAddress = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
      amount = "10",
      withdrawType = "ADDRESS",
      chain = "trx"
    )
    print(result$withdrawal_id)

    # Internal KuCoin transfer by UID
    result <- withdrawal$add_withdrawal(
      currency = "BTC",
      toAddress = "12345678",
      amount = "0.01",
      withdrawType = "UID",
      isInner = TRUE
    )

------------------------------------------------------------------------

### `KucoinWithdrawal$cancel_withdrawal()`

Cancel Withdrawal

Cancels a pending withdrawal request. Only withdrawals with `PROCESSING`
status can be cancelled. Once a withdrawal has moved to
`WALLET_PROCESSING` or later, it cannot be reversed.

#### Workflow

1.  **Request**: Authenticated DELETE to the withdrawal-specific
    endpoint.

2.  **Response**: KuCoin returns `NULL` data on success.

3.  **Parsing**: Returns a `data.table` with the cancelled withdrawal
    ID.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/withdrawals/{withdrawalId}`

#### Official Documentation

[KuCoin Cancel
Withdrawal](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/cancel-withdrawal)

Verified: 2026-05-23

#### Automated Trading Usage

- **Error Recovery**: Cancel a withdrawal if the destination address was
  incorrect.

- **Strategy Change**: Cancel pending withdrawals if market conditions
  change and funds are needed for trading.

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/withdrawals/670deec84d64da0007d7c946' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": null
    }

#### Usage

    KucoinWithdrawal$cancel_withdrawal(withdrawalId)

#### Arguments

- `withdrawalId`:

  Character; the unique withdrawal ID to cancel.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `withdrawal_id` (character): The cancelled withdrawal ID (echoed from
  the input since KuCoin returns `null` data on a successful cancel).

#### Examples

    withdrawal <- KucoinWithdrawal$new()

    # Cancel a pending withdrawal
    result <- withdrawal$cancel_withdrawal("670deec84d64da0007d7c946")
    print(result$withdrawal_id)

------------------------------------------------------------------------

### `KucoinWithdrawal$get_withdrawal_quotas()`

Get Withdrawal Quotas

Retrieves withdrawal limits, minimum fees, and available balances for a
currency. Essential for pre-flight checks before initiating withdrawals
to ensure sufficient balance and valid amount parameters.

#### Workflow

1.  **Request**: Authenticated GET with `currency` (required) and
    optional `chain` query parameters.

2.  **Parsing**: Returns a `data.table` with quota details, limits, and
    fee information.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/withdrawals/quotas`

#### Official Documentation

[KuCoin Get Withdrawal
Quotas](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-quotas)

Verified: 2026-05-23

#### Automated Trading Usage

- **Pre-Flight Check**: Verify `is_withdraw_enabled` and
  `available_amount` before attempting a withdrawal.

- **Fee Estimation**: Use `withdraw_min_fee` and
  `inner_withdraw_min_fee` for cost calculations.

- **Amount Validation**: Check `withdraw_min_size` and `precision` to
  format withdrawal amounts correctly.

- **Limit Awareness**: Monitor `remain_amount` against
  `limit_btc_amount` to stay within daily limits.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/withdrawals/quotas?currency=BTC' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currency": "BTC",
        "limitBTCAmount": "15.79590095",
        "usedBTCAmount": "0.00000000",
        "quotaCurrency": "USDT",
        "limitQuotaCurrencyAmount": "999999.00000000",
        "usedQuotaCurrencyAmount": "0",
        "remainAmount": "15.79590095",
        "availableAmount": "0",
        "withdrawMinFee": "0.0005",
        "innerWithdrawMinFee": "0",
        "withdrawMinSize": "0.001",
        "isWithdrawEnabled": true,
        "precision": 8,
        "chain": "BTC",
        "reason": null,
        "lockedAmount": "0"
      }
    }

#### Usage

    KucoinWithdrawal$get_withdrawal_quotas(currency, chain = NULL)

#### Arguments

- `currency`:

  Character; currency code (e.g., `"BTC"`, `"USDT"`).

- `chain`:

  Character or NULL; blockchain network identifier (e.g., `"eth"`,
  `"trx"`). When NULL, returns quotas for the default chain.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `currency` (character): Currency code.

- `limit_btc_amount` (character): Daily withdrawal limit in BTC
  equivalent.

- `used_btc_amount` (character): BTC equivalent already withdrawn today.

- `quota_currency` (character): Quota currency (e.g., `"USDT"`).

- `limit_quota_currency_amount` (character): Daily limit in quota
  currency.

- `used_quota_currency_amount` (character): Amount used in quota
  currency.

- `remain_amount` (character): Remaining withdrawal quota in BTC
  equivalent.

- `available_amount` (character): Available balance for withdrawal.

- `withdraw_min_fee` (character): Minimum withdrawal fee.

- `inner_withdraw_min_fee` (character): Minimum fee for internal
  transfers.

- `withdraw_min_size` (character): Minimum withdrawal amount.

- `is_withdraw_enabled` (logical): Whether withdrawals are currently
  enabled.

- `precision` (integer): Decimal precision for amounts.

- `chain` (character): Blockchain network name.

- `reason` (character): Reason if withdrawals are disabled (or NA).

- `locked_amount` (character): Amount currently locked.

#### Examples

    withdrawal <- KucoinWithdrawal$new()

    # Check BTC withdrawal quotas
    quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
    print(quotas[, .(currency, available_amount, withdraw_min_fee, is_withdraw_enabled)])

    # Check USDT quotas on TRC20
    usdt_quotas <- withdrawal$get_withdrawal_quotas(currency = "USDT", chain = "trx")
    print(usdt_quotas$withdraw_min_fee)

------------------------------------------------------------------------

### `KucoinWithdrawal$get_withdrawal_history()`

Get Withdrawal History

Retrieves paginated withdrawal history with optional filtering by
currency, status, and time range. Automatically converts `created_at`
timestamps to POSIXct for convenient analysis.

#### Workflow

1.  **Pagination**: Uses `private$.paginate()` to fetch all pages of
    withdrawal records up to `max_pages`.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Timestamp Conversion**: Coerces `created_at` (milliseconds) to
    POSIXct in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/withdrawals`

#### Official Documentation

[KuCoin Get Withdrawal
History](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-history)

Verified: 2026-05-23

#### Automated Trading Usage

- **Withdrawal Monitoring**: Poll for `"SUCCESS"` status to confirm
  funds have left the exchange.

- **Reconciliation**: Match `wallet_tx_id` against on-chain transaction
  hashes for audit.

- **Time-Windowed Queries**: Use `startAt`/`endAt` timestamps to
  retrieve withdrawals within a specific period.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/withdrawals?currency=USDT&status=SUCCESS&currentPage=1&pageSize=50' \
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
            "chain": "",
            "status": "SUCCESS",
            "address": "a435*****@gmail.com",
            "memo": "",
            "isInner": true,
            "amount": "1.00000000",
            "fee": "0.00000000",
            "walletTxId": null,
            "createdAt": 1728555875000,
            "updatedAt": 1728555875000,
            "remark": "",
            "arrears": false
          }
        ]
      }
    }

#### Usage

    KucoinWithdrawal$get_withdrawal_history(
      currency = NULL,
      status = NULL,
      startAt = NULL,
      endAt = NULL,
      page_size = 50,
      max_pages = Inf
    )

#### Arguments

- `currency`:

  Character or NULL; currency code (e.g., `"BTC"`, `"USDT"`). If NULL,
  returns withdrawals for all currencies.

- `status`:

  Character or NULL; filter by withdrawal status. Accepted values:
  `"PROCESSING"`, `"REVIEW"`, `"WALLET_PROCESSING"`, `"SUCCESS"`,
  `"FAILURE"`. When NULL, returns withdrawals of all statuses.

- `startAt`:

  Integer or NULL; start timestamp in milliseconds (inclusive).

- `endAt`:

  Integer or NULL; end timestamp in milliseconds (inclusive).

- `page_size`:

  Integer; number of results per page (default 50, max 500).

- `max_pages`:

  Numeric; maximum number of pages to fetch (default `Inf` for all
  pages).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row per withdrawal and columns:

- `currency` (character): Withdrawn currency code.

- `chain` (character): Blockchain network used.

- `status` (character): Withdrawal status.

- `address` (character): Withdrawal destination address.

- `memo` (character): Memo/tag (empty string if not applicable).

- `is_inner` (logical): Whether this was an internal KuCoin transfer.

- `amount` (character): Withdrawal amount.

- `fee` (character): Withdrawal fee charged.

- `wallet_tx_id` (character): On-chain transaction hash.

- `created_at` (POSIXct): Creation datetime (coerced from epoch
  milliseconds).

- `updated_at` (POSIXct): Last update datetime (coerced from epoch
  milliseconds).

- `remark` (character): Optional remark.

- `arrears` (logical): Whether the withdrawal is in arrears.

Returns an empty `data.table` if no withdrawals match the filters.

#### Examples

    withdrawal <- KucoinWithdrawal$new()

    # Get all successful USDT withdrawals
    history <- withdrawal$get_withdrawal_history(
      currency = "USDT",
      status = "SUCCESS"
    )
    print(history[, .(amount, status, created_at)])

    # Get withdrawals from the last 24 hours
    now_ms <- as.integer(as.numeric(lubridate::now()) * 1000)
    recent <- withdrawal$get_withdrawal_history(
      currency = "BTC",
      startAt = now_ms - 86400000L,
      endAt = now_ms
    )

------------------------------------------------------------------------

### `KucoinWithdrawal$get_withdrawal_by_id()`

Get Withdrawal by ID

Retrieves comprehensive details for a specific withdrawal, including
chain information, failure reasons, cancel status, and return details.
Provides more information than the history endpoint.

#### Workflow

1.  **Request**: Authenticated GET to the withdrawal-specific endpoint.

2.  **Response**: KuCoin returns detailed withdrawal information.

3.  **Parsing**: Returns `data.table` with full withdrawal details.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/withdrawals/{withdrawalId}`

#### Official Documentation

[KuCoin Get Withdrawal
Detail](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-by-id)

Verified: 2026-05-23

#### Automated Trading Usage

- **Status Tracking**: Monitor withdrawal progress through `REVIEW` →
  `PROCESSING` → `WALLET_PROCESSING` → `SUCCESS`.

- **Failure Diagnosis**: Check `failure_reason` and `failure_reason_msg`
  to understand why a withdrawal failed.

- **Cancel Eligibility**: Use `cancel_type` (`"CANCELABLE"`,
  `"CANCELING"`, `"NON_CANCELABLE"`) to determine if a withdrawal can
  still be cancelled.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/withdrawals/670deec84d64da0007d7c946' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "67e6515f7960ba0007b42025",
        "currency": "USDT",
        "chainId": "trx",
        "chainName": "TRC20",
        "status": "SUCCESS",
        "address": "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
        "memo": "",
        "isInner": true,
        "amount": "3.00000000",
        "fee": "0.00000000",
        "walletTxId": null,
        "createdAt": 1743147359000,
        "cancelType": "NON_CANCELABLE"
      }
    }

#### Usage

    KucoinWithdrawal$get_withdrawal_by_id(withdrawalId)

#### Arguments

- `withdrawalId`:

  Character; the unique withdrawal ID.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `id` (character): Withdrawal ID.

- `currency` (character): Currency code.

- `chain_id` (character): Chain identifier (e.g., `"trx"`, `"eth"`).

- `chain_name` (character): Chain display name (e.g., `"TRC20"`,
  `"ERC20"`).

- `status` (character): Withdrawal status.

- `address` (character): Destination address.

- `memo` (character): Address memo/tag.

- `is_inner` (logical): Internal transfer flag.

- `amount` (character): Withdrawal amount.

- `fee` (character): Fee charged.

- `wallet_tx_id` (character): On-chain transaction hash (or NA).

- `cancel_type` (character): `"CANCELABLE"`, `"CANCELING"`, or
  `"NON_CANCELABLE"`.

- `failure_reason` (character): Failure reason code (or NA).

- `failure_reason_msg` (character): Human-readable failure message (or
  NA).

- `created_at` (POSIXct): Creation datetime (coerced from epoch
  milliseconds).

#### Examples

    withdrawal <- KucoinWithdrawal$new()

    # Get withdrawal details
    detail <- withdrawal$get_withdrawal_by_id("670deec84d64da0007d7c946")
    print(detail[, .(id, currency, status, amount, cancel_type)])

    # Check if a withdrawal can be cancelled
    if (detail$cancel_type == "CANCELABLE") {
      withdrawal$cancel_withdrawal(detail$id)
    }

------------------------------------------------------------------------

### `KucoinWithdrawal$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinWithdrawal$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
withdrawal <- KucoinWithdrawal$new()
quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
print(quotas)

# Asynchronous
withdrawal_async <- KucoinWithdrawal$new(async = TRUE)
main <- coro::async(function() {
  quotas <- await(withdrawal_async$get_withdrawal_quotas(currency = "BTC"))
  print(quotas)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinWithdrawal$add_withdrawal()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- KucoinWithdrawal$new()

# Withdraw USDT via TRC20
result <- withdrawal$add_withdrawal(
  currency = "USDT",
  toAddress = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
  amount = "10",
  withdrawType = "ADDRESS",
  chain = "trx"
)
print(result$withdrawal_id)

# Internal KuCoin transfer by UID
result <- withdrawal$add_withdrawal(
  currency = "BTC",
  toAddress = "12345678",
  amount = "0.01",
  withdrawType = "UID",
  isInner = TRUE
)
} # }

## ------------------------------------------------
## Method `KucoinWithdrawal$cancel_withdrawal()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- KucoinWithdrawal$new()

# Cancel a pending withdrawal
result <- withdrawal$cancel_withdrawal("670deec84d64da0007d7c946")
print(result$withdrawal_id)
} # }

## ------------------------------------------------
## Method `KucoinWithdrawal$get_withdrawal_quotas()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- KucoinWithdrawal$new()

# Check BTC withdrawal quotas
quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
print(quotas[, .(currency, available_amount, withdraw_min_fee, is_withdraw_enabled)])

# Check USDT quotas on TRC20
usdt_quotas <- withdrawal$get_withdrawal_quotas(currency = "USDT", chain = "trx")
print(usdt_quotas$withdraw_min_fee)
} # }

## ------------------------------------------------
## Method `KucoinWithdrawal$get_withdrawal_history()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- KucoinWithdrawal$new()

# Get all successful USDT withdrawals
history <- withdrawal$get_withdrawal_history(
  currency = "USDT",
  status = "SUCCESS"
)
print(history[, .(amount, status, created_at)])

# Get withdrawals from the last 24 hours
now_ms <- as.integer(as.numeric(lubridate::now()) * 1000)
recent <- withdrawal$get_withdrawal_history(
  currency = "BTC",
  startAt = now_ms - 86400000L,
  endAt = now_ms
)
} # }

## ------------------------------------------------
## Method `KucoinWithdrawal$get_withdrawal_by_id()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- KucoinWithdrawal$new()

# Get withdrawal details
detail <- withdrawal$get_withdrawal_by_id("670deec84d64da0007d7c946")
print(detail[, .(id, currency, status, amount, cancel_type)])

# Check if a withdrawal can be cancelled
if (detail$cancel_type == "CANCELABLE") {
  withdrawal$cancel_withdrawal(detail$id)
}
} # }
```
