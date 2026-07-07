# KucoinWithdrawal: Withdrawal Management

KucoinWithdrawal: Withdrawal Management

KucoinWithdrawal: Withdrawal Management

## Details

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
[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
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

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_withdrawal()`

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
      --data-raw \
      '{"currency":"USDT","toAddress":"TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8","amount":"10","withdrawType":"ADDRESS",
      "chain":"trx"}'

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
      to_address,
      amount,
      withdraw_type,
      chain = NULL,
      memo = NULL,
      is_inner = NULL,
      remark = NULL,
      fee_deduct_type = NULL
    )

#### Arguments

- `currency`:

  (scalar\<character\>) currency code (e.g., `"BTC"`, `"USDT"`).

- `to_address`:

  (scalar\<character\>) withdrawal destination address, UID, email, or
  phone number.

- `amount`:

  (scalar\<character\>) withdrawal amount (must be positive, multiple of
  currency precision).

- `withdraw_type`:

  (scalar\<character\>) withdrawal type: `"ADDRESS"`, `"UID"`, `"MAIL"`,
  or `"PHONE"`.

- `chain`:

  (scalar\<character\> \| NULL) blockchain network identifier (e.g.,
  `"eth"`, `"trx"`, `"bsc"`). Required by the KuCoin API; the method
  raises if `NULL`.

- `memo`:

  (scalar\<character\> \| NULL) address memo/tag (required for some
  currencies like XRP, XLM).

- `is_inner`:

  (scalar\<logical\> \| NULL) if `TRUE`, this is an internal KuCoin
  transfer (no on-chain fee).

- `remark`:

  (scalar\<character\> \| NULL) optional remark for the withdrawal.

- `fee_deduct_type`:

  (scalar\<character\> \| NULL) fee deduction type: `"INTERNAL"` or
  `"EXTERNAL"`.

#### Returns

(data.table \| promise\<data.table\>) one row with column
`withdrawal_id` (character): the unique withdrawal identifier:

- withdrawal_id (character) the withdrawal id.

#### Examples

    \dontrun{
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
    }

------------------------------------------------------------------------

### Method `cancel_withdrawal()`

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

    KucoinWithdrawal$cancel_withdrawal(withdrawal_id)

#### Arguments

- `withdrawal_id`:

  (scalar\<character\>) the unique withdrawal ID to cancel.

#### Returns

(data.table \| promise\<data.table\>) one row, the cancelled withdrawal
ID echoed from the input (KuCoin returns `null` data on a successful
cancel):

- withdrawal_id (character) the cancelled withdrawal id.

#### Examples

    \dontrun{
    withdrawal <- KucoinWithdrawal$new()

    # Cancel a pending withdrawal
    result <- withdrawal$cancel_withdrawal("670deec84d64da0007d7c946")
    print(result$withdrawal_id)
    }

------------------------------------------------------------------------

### Method `get_withdrawal_quotas()`

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

KuCoin Get Withdrawal Quotas:
<https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-quotas>

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

  (scalar\<character\>) currency code (e.g., `"BTC"`, `"USDT"`).

- `chain`:

  (scalar\<character\> \| NULL) blockchain network identifier (e.g.,
  `"eth"`, `"trx"`). When NULL, returns quotas for the default chain.

#### Returns

(data.table \| promise\<data.table\>) one row with the withdrawal quota
details (currency, limit_btc_amount, used_btc_amount, quota_currency,
limit_quota_currency_amount, used_quota_currency_amount, remain_amount,
available_amount, withdraw_min_fee, inner_withdraw_min_fee,
withdraw_min_size, is_withdraw_enabled, precision, chain, reason,
locked_amount, ...):

- currency (character) the currency code.

- chain (character) the chain code.

- is_withdraw_enabled (logical \| NA) the is withdraw enabled.

- available_amount (numeric \| NA) the available amount.

- remain_amount (numeric \| NA) the remain amount.

- withdraw_min_fee (numeric \| NA) the withdraw min fee.

- inner_withdraw_min_fee (numeric \| NA) the inner withdraw min fee.

- withdraw_min_size (numeric \| NA) the withdraw min size.

- precision (integer \| NA) the decimal precision.

- limit_btc_amount (numeric \| NA) the limit btc amount.

- used_btc_amount (numeric \| NA) the used btc amount.

- locked_amount (numeric \| NA) the locked amount.

- quota_currency (character) the quota currency.

- limit_quota_currency_amount (numeric \| NA) the limit quota currency
  amount.

- used_quota_currency_amount (numeric \| NA) the used quota currency
  amount.

- reason (character \| NA) the reason withdrawals are disabled, when
  present.

#### Examples

    \dontrun{
    withdrawal <- KucoinWithdrawal$new()

    # Check BTC withdrawal quotas
    quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
    print(quotas[, .(currency, available_amount, withdraw_min_fee, is_withdraw_enabled)])

    # Check USDT quotas on TRC20
    usdt_quotas <- withdrawal$get_withdrawal_quotas(currency = "USDT", chain = "trx")
    print(usdt_quotas$withdraw_min_fee)
    }

------------------------------------------------------------------------

### Method `get_withdrawal_history()`

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

KuCoin Get Withdrawal History:
<https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-history>

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
      start_at = NULL,
      end_at = NULL,
      page_size = 50,
      max_pages = Inf
    )

#### Arguments

- `currency`:

  (scalar\<character\> \| NULL) currency code (e.g., `"BTC"`, `"USDT"`).
  If NULL, returns withdrawals for all currencies.

- `status`:

  (scalar\<character\> \| NULL) filter by withdrawal status. Accepted
  values: `"PROCESSING"`, `"REVIEW"`, `"WALLET_PROCESSING"`,
  `"SUCCESS"`, `"FAILURE"`. When NULL, returns withdrawals of all
  statuses.

- `start_at`:

  (scalar\<numeric\> \| NULL) start timestamp in milliseconds
  (inclusive).

- `end_at`:

  (scalar\<numeric\> \| NULL) end timestamp in milliseconds (inclusive).

- `page_size`:

  (scalar\<count in \[1, Inf\]\>) number of results per page (default
  50, max 500).

- `max_pages`:

  (scalar\<numeric in \[1, Inf\]\>) maximum number of pages to fetch
  (default `Inf` for all pages).

#### Returns

(data.table \| promise\<data.table\>) one row per withdrawal record
(currency, chain, status, address, memo, is_inner, amount, fee,
wallet_tx_id, created_at, updated_at, remark, arrears, ...), with
`created_at`/`updated_at` coerced to POSIXct, or an empty `data.table`
if no withdrawals match the filters.

#### Examples

    \dontrun{
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
    }

------------------------------------------------------------------------

### Method `get_withdrawal_by_id()`

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

KuCoin Get Withdrawal Detail:
<https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-by-id>

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

    KucoinWithdrawal$get_withdrawal_by_id(withdrawal_id)

#### Arguments

- `withdrawal_id`:

  (scalar\<character\>) the unique withdrawal ID.

#### Returns

(data.table \| promise\<data.table\>) one row with the full withdrawal
detail (id, currency, chain_id, chain_name, status, address, memo,
is_inner, amount, fee, wallet_tx_id, cancel_type, failure_reason,
failure_reason_msg, created_at, ...), with `created_at` coerced to
POSIXct:

- id (character) the record identifier.

- currency (character) the currency code.

- chain_id (character \| NA) the chain identifier.

- chain_name (character \| NA) the chain name.

- status (character) the status.

- address (character) the address.

- memo (character) the address memo/tag.

- is_inner (logical) the is inner.

- amount (numeric \| NA) the amount.

- fee (numeric \| NA) the fee.

- wallet_tx_id (character \| NA) the on-chain wallet transaction hash;
  NA for internal transfers.

- created_at (POSIXct) the created at (UTC).

- cancel_type (character) the cancel type.

- uid (integer) the user identifier.

- currency_name (character) the currency name.

- failure_reason (character \| NA) the failure reason.

- failure_reason_msg (character \| NA) the failure reason message, when
  the withdrawal failed.

- address_remark (character \| NA) the address remark.

- remark (character \| NA) an optional remark.

- taxes (numeric \| NA) the tax amount, when applicable.

- tax_description (character \| NA) the tax description, when
  applicable.

- tx_id (character \| NA) the transaction id, when present.

- return_status (character) the return status.

- return_amount (numeric \| NA) the returned amount, when the withdrawal
  was returned.

- return_currency (character) the return currency.

#### Examples

    \dontrun{
    withdrawal <- KucoinWithdrawal$new()

    # Get withdrawal details
    detail <- withdrawal$get_withdrawal_by_id("670deec84d64da0007d7c946")
    print(detail[, .(id, currency, status, amount, cancel_type)])

    # Check if a withdrawal can be cancelled
    if (detail$cancel_type == "CANCELABLE") {
      withdrawal$cancel_withdrawal(detail$id)
    }
    }

------------------------------------------------------------------------

### Method `clone()`

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
## Method `KucoinWithdrawal$add_withdrawal`
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
## Method `KucoinWithdrawal$cancel_withdrawal`
## ------------------------------------------------

if (FALSE) { # \dontrun{
withdrawal <- KucoinWithdrawal$new()

# Cancel a pending withdrawal
result <- withdrawal$cancel_withdrawal("670deec84d64da0007d7c946")
print(result$withdrawal_id)
} # }

## ------------------------------------------------
## Method `KucoinWithdrawal$get_withdrawal_quotas`
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
## Method `KucoinWithdrawal$get_withdrawal_history`
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
## Method `KucoinWithdrawal$get_withdrawal_by_id`
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
