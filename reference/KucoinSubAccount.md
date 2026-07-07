# KucoinSubAccount: Sub-Account Management

KucoinSubAccount: Sub-Account Management

KucoinSubAccount: Sub-Account Management

## Details

Provides methods for managing sub-accounts under a KuCoin master
account. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Sub-Account Creation**: Create new sub-accounts with configurable
  permissions (Spot, Futures, Margin).

- **Sub-Account Listing**: Retrieve paginated summaries of all
  sub-accounts under the master account.

- **Balance Queries**: Fetch detailed balance breakdowns per sub-account
  across main, trade, and margin wallets.

- **Batch Balance Overview**: Paginated retrieval of Spot balances for
  all sub-accounts simultaneously (V2 endpoint).

### Usage

All methods require authentication (valid API key, secret, passphrase)
from a **master account**. Sub-account API keys cannot call these
endpoints; only the master account that owns the sub-accounts has
permission. The class supports both synchronous and asynchronous
(promise-based) operation depending on the `async` flag passed to the
constructor.

    # Synchronous usage
    sub <- KucoinSubAccount$new()
    summary <- sub$get_sub_account_list()

    # Asynchronous usage
    sub_async <- KucoinSubAccount$new(async = TRUE)
    coro::async(function() {
      summary <- await(sub_async$get_sub_account_list())
      print(summary)
    })()

### Official Documentation

[KuCoin Sub-Account
Management](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)

### Endpoints Covered

|                       |                                      |      |
|-----------------------|--------------------------------------|------|
| Method                | Endpoint                             | HTTP |
| add_sub_account       | POST /api/v2/sub/user/created        | POST |
| get_sub_account_list  | GET /api/v2/sub/user                 | GET  |
| get_detail_balance    | GET /api/v1/sub-accounts/{subUserId} | GET  |
| get_all_spot_balances | GET /api/v2/sub-accounts             | GET  |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinSubAccount`

## Methods

### Public methods

- [`KucoinSubAccount$add_sub_account()`](#method-KucoinSubAccount-add_sub_account)

- [`KucoinSubAccount$get_sub_account_list()`](#method-KucoinSubAccount-get_sub_account_list)

- [`KucoinSubAccount$get_detail_balance()`](#method-KucoinSubAccount-get_detail_balance)

- [`KucoinSubAccount$get_all_spot_balances()`](#method-KucoinSubAccount-get_all_spot_balances)

- [`KucoinSubAccount$clone()`](#method-KucoinSubAccount-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_sub_account()`

Add Sub-Account

Creates a new sub-account under the master account. The sub-account is
assigned a unique UID and can be granted Spot, Futures, or Margin
trading permissions. Only master accounts can call this endpoint.

#### Workflow

1.  **Validation**: `access` is matched against `"Spot"`, `"Futures"`,
    `"Margin"`.

2.  **Request**: Authenticated POST with sub-account creation parameters
    in JSON body.

3.  **Parsing**: Returns a single-row `data.table` with the newly
    created sub-account details.

#### API Endpoint

`POST https://api.kucoin.com/api/v2/sub/user/created`

#### Official Documentation

[KuCoin Add
Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)

Verified: 2026-05-23

#### Automated Trading Usage

- **Isolation**: Create dedicated sub-accounts per strategy to isolate
  funds and risk.

- **Permission Control**: Grant only the needed permission (e.g.,
  `"Spot"`) to limit exposure.

- **Remarks**: Use `remarks` to tag sub-accounts by strategy name for
  easy identification.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v2/sub/user/created' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"password":"MyPass123","subName":"mysubacct1","access":"Spot","remarks":"bot-alpha"}'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "uid": 169630809,
        "subName": "mysubacct1",
        "remarks": "bot-alpha",
        "access": "Spot"
      }
    }

#### Usage

    KucoinSubAccount$add_sub_account(password, sub_name, access, remarks = NULL)

#### Arguments

- `password`:

  (scalar\<character\>) sub-account password (7-24 chars, must contain
  both letters and numbers, no special characters).

- `sub_name`:

  (scalar\<character\>) sub-account name (7-32 chars, must start with a
  letter, letters and numbers only, no spaces).

- `access`:

  (scalar\<character\>) permission type: `"Spot"`, `"Futures"`, or
  `"Margin"`. Validated via
  [`rlang::arg_match0()`](https://rlang.r-lib.org/reference/arg_match.html).

- `remarks`:

  (scalar\<character\> \| NULL) optional descriptive remarks for the
  sub-account (1-24 chars).

#### Returns

(data.table \| promise\<data.table\>) one row with the newly created
sub-account details: the unique user ID `uid`, the login name
`sub_name`, the `remarks` string, and the granted permission `access`:

- uid (integer) the user identifier.

- sub_name (character) the sub name.

- remarks (character \| NA) an optional remark.

- access (character) the access.

#### Examples

    \dontrun{
    sub <- KucoinSubAccount$new()

    # Create a Spot sub-account
    result <- sub$add_sub_account(
      password = "MyPass123",
      subName = "botaccount1",
      access = "Spot",
      remarks = "alpha-strategy"
    )
    print(result$uid)
    print(result$sub_name)

    # Create a Futures sub-account without remarks
    result <- sub$add_sub_account(
      password = "SecurePass99",
      subName = "futuresbot1",
      access = "Futures"
    )
    }

------------------------------------------------------------------------

### Method `get_sub_account_list()`

Get Sub-Account List Summary

Retrieves a paginated summary of all sub-accounts under the master
account. Automatically handles pagination, fetching up to `max_pages`
pages of results. The `created_at` column is coerced from epoch
milliseconds to POSIXct.

#### Workflow

1.  **Pagination**: Calls the paginated endpoint, fetching `page_size`
    records per page up to `max_pages`.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Timestamp Conversion**: Coerces `created_at` (ms epoch) to POSIXct
    in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v2/sub/user`

#### Official Documentation

KuCoin Get Sub-Account List Summary Info:
<https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info>

Verified: 2026-05-23

#### Automated Trading Usage

- **Inventory Check**: Periodically poll sub-account lists to verify all
  strategy sub-accounts are active.

- **Audit Trail**: Use `created_at` to track when sub-accounts were
  provisioned.

- **Filtering**: Post-filter the returned `data.table` by `access` type
  to find all Spot-enabled sub-accounts.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v2/sub/user?currentPage=1&pageSize=100' \
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
        "pageSize": 100,
        "totalNum": 2,
        "totalPage": 1,
        "items": [
          {
            "userId": "641e7f09df0db80001f1e5ac",
            "uid": 169630809,
            "subName": "mysubacct1",
            "status": 2,
            "type": 0,
            "access": "Spot",
            "remarks": "bot-alpha",
            "createdAt": 1679726345000
          },
          {
            "userId": "641e8027df0db80001f1e6bb",
            "uid": 169630810,
            "subName": "futuresbot1",
            "status": 2,
            "type": 0,
            "access": "Futures",
            "remarks": null,
            "createdAt": 1679726400000
          }
        ]
      }
    }

#### Usage

    KucoinSubAccount$get_sub_account_list(page_size = 100, max_pages = Inf)

#### Arguments

- `page_size`:

  (scalar\<count in \[1, Inf\]\>) number of results per page, between 1
  and 100.

- `max_pages`:

  (scalar\<numeric in \[1, Inf\]\>) maximum number of pages to retrieve.
  Use `Inf` (default) to fetch all available pages.

#### Returns

(data.table \| promise\<data.table\>) one row per sub-account with its
internal `user_id`, numeric `uid`, login `sub_name`, `status` and `type`
codes, `access` permission, `remarks`, and `created_at` creation
datetime (coerced from epoch milliseconds).

#### Examples

    \dontrun{
    sub <- KucoinSubAccount$new()

    # Fetch all sub-accounts
    all_subs <- sub$get_sub_account_list()
    print(all_subs)

    # Fetch only first page with 10 results
    first_page <- sub$get_sub_account_list(page_size = 10, max_pages = 1)
    print(first_page[, .(sub_name, access, created_at)])

    # Filter for Spot sub-accounts
    spot_subs <- all_subs[access == "Spot"]
    }

------------------------------------------------------------------------

### Method `get_detail_balance()`

Get Sub-Account Detail Balance

Retrieves detailed balance information for a specific sub-account,
broken down by account type (main, trade, margin). Each currency held in
the sub-account is returned as a separate row with balance, available,
and holds amounts.

#### Workflow

1.  **Request**: Authenticated GET to the sub-account detail endpoint
    with the `subUserId` in the URL path.

2.  **Iteration**: Loops over `mainAccounts`, `tradeAccounts`, and
    `marginAccounts` arrays in the response.

3.  **Assembly**: Binds all account entries into a single `data.table`
    with `account_type`, `sub_user_id`, and `sub_name` columns appended.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}`

#### Official Documentation

KuCoin Get Sub-Account Detail Balance:
<https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance>

Verified: 2026-05-23

#### Automated Trading Usage

- **Pre-Trade Check**: Query a sub-account's available balance before
  placing orders to avoid insufficient-funds errors.

- **Risk Monitoring**: Periodically check `holds` across sub-accounts to
  track capital locked in open orders.

- **Rebalancing**: Compare `available` balances across sub-accounts to
  decide on internal transfers.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/sub-accounts/169630809?includeBaseAmount=false' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "subUserId": "169630809",
        "subName": "mysubacct1",
        "mainAccounts": [
          {
            "currency": "USDT",
            "balance": "1500.00000000",
            "available": "1200.00000000",
            "holds": "300.00000000",
            "baseCurrency": "USDT",
            "baseCurrencyPrice": "1",
            "baseAmount": "1500.00000000",
            "tag": ""
          },
          {
            "currency": "BTC",
            "balance": "0.05000000",
            "available": "0.05000000",
            "holds": "0.00000000",
            "baseCurrency": "USDT",
            "baseCurrencyPrice": "96500",
            "baseAmount": "4825.00000000",
            "tag": ""
          }
        ],
        "tradeAccounts": [
          {
            "currency": "USDT",
            "balance": "500.00000000",
            "available": "450.00000000",
            "holds": "50.00000000",
            "baseCurrency": "USDT",
            "baseCurrencyPrice": "1",
            "baseAmount": "500.00000000",
            "tag": ""
          }
        ],
        "marginAccounts": [
          {
            "currency": "ETH",
            "balance": "2.50000000",
            "available": "2.50000000",
            "holds": "0.00000000",
            "baseCurrency": "USDT",
            "baseCurrencyPrice": "3200",
            "baseAmount": "8000.00000000",
            "tag": ""
          }
        ]
      }
    }

#### Usage

    KucoinSubAccount$get_detail_balance(sub_user_id, include_base_amount = FALSE)

#### Arguments

- `sub_user_id`:

  (scalar\<character\>) the sub-account user ID (numeric UID as a
  string, e.g., `"169630809"`).

- `include_base_amount`:

  (scalar\<logical\>) if `TRUE`, includes currencies with zero balances
  in the response.

#### Returns

(data.table \| promise\<data.table\>) one row per currency and account
type holding the `currency`, `balance`, `available`, and `holds`
amounts, the `base_currency`, `base_currency_price` and `base_amount`
value conversion, the currency `tag`, the `account_type` (`"main"`,
`"trade"`, or `"margin"`), and the `sub_user_id` and `sub_name`
identifiers.

#### Examples

    \dontrun{
    sub <- KucoinSubAccount$new()

    # Get balances for a specific sub-account
    balances <- sub$get_detail_balance(subUserId = "169630809")
    print(balances)

    # Include zero-balance currencies
    all_balances <- sub$get_detail_balance(
      subUserId = "169630809",
      includeBaseAmount = TRUE
    )

    # Filter for trade account balances only
    trade_bal <- balances[account_type == "trade"]
    print(trade_bal[, .(currency, available, holds)])
    }

------------------------------------------------------------------------

### Method `get_all_spot_balances()`

Get Spot Sub-Account List (V2)

Retrieves paginated Spot sub-account balance details for all
sub-accounts at once via the V2 endpoint. Each sub-account's balances
are broken down by account type (main, trade, margin) and combined into
a single `data.table` with `sub_user_id` and `sub_name` identifiers.

#### Workflow

1.  **Pagination**: Fetches pages of sub-account balance data via the V2
    endpoint, `page_size` records per page up to `max_pages`.

2.  **Nested Iteration**: For each sub-account in each page, iterates
    over `mainAccounts`, `tradeAccounts`, and `marginAccounts`.

3.  **Assembly**: Binds all entries into a single `data.table` with
    `account_type`, `sub_user_id`, and `sub_name` columns appended.

#### API Endpoint

`GET https://api.kucoin.com/api/v2/sub-accounts`

#### Official Documentation

KuCoin Get Sub-Account List Spot Balance V2:
<https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-spot-balance-v2>

Verified: 2026-05-23

#### Automated Trading Usage

- **Portfolio Dashboard**: Aggregate balances across all sub-accounts
  for a unified portfolio view.

- **Threshold Alerts**: Check `available` balances across all
  sub-accounts and trigger alerts when below thresholds.

- **Capital Allocation**: Compare balances across sub-accounts to
  identify idle capital for reallocation.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v2/sub-accounts?currentPage=1&pageSize=100' \
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
        "pageSize": 100,
        "totalNum": 2,
        "totalPage": 1,
        "items": [
          {
            "subUserId": "169630809",
            "subName": "mysubacct1",
            "mainAccounts": [
              {
                "currency": "USDT",
                "balance": "1500.00000000",
                "available": "1200.00000000",
                "holds": "300.00000000",
                "baseCurrency": "USDT",
                "baseCurrencyPrice": "1",
                "baseAmount": "1500.00000000",
                "tag": ""
              }
            ],
            "tradeAccounts": [
              {
                "currency": "BTC",
                "balance": "0.01000000",
                "available": "0.01000000",
                "holds": "0.00000000",
                "baseCurrency": "USDT",
                "baseCurrencyPrice": "96500",
                "baseAmount": "965.00000000",
                "tag": ""
              }
            ],
            "marginAccounts": []
          },
          {
            "subUserId": "169630810",
            "subName": "futuresbot1",
            "mainAccounts": [
              {
                "currency": "ETH",
                "balance": "5.00000000",
                "available": "5.00000000",
                "holds": "0.00000000",
                "baseCurrency": "USDT",
                "baseCurrencyPrice": "3200",
                "baseAmount": "16000.00000000",
                "tag": ""
              }
            ],
            "tradeAccounts": [],
            "marginAccounts": []
          }
        ]
      }
    }

#### Usage

    KucoinSubAccount$get_all_spot_balances(page_size = 100, max_pages = Inf)

#### Arguments

- `page_size`:

  (scalar\<count in \[1, Inf\]\>) number of results per page, between 10
  and 100.

- `max_pages`:

  (scalar\<numeric in \[1, Inf\]\>) maximum number of pages to retrieve.
  Use `Inf` (default) to fetch all available pages.

#### Returns

(data.table \| promise\<data.table\>) one row per currency, account type
and sub-account holding the `sub_user_id` and `sub_name` identifiers,
the `account_type` (`"main"`, `"trade"`, or `"margin"`), the `currency`,
`balance`, `available` and `holds` amounts, and the `base_currency`,
`base_currency_price`, `base_amount` and `tag` value-conversion fields.

#### Examples

    \dontrun{
    sub <- KucoinSubAccount$new()

    # Fetch all sub-account Spot balances
    all_balances <- sub$get_all_spot_balances()
    print(all_balances)

    # Fetch first page only with 10 results per page
    first_page <- sub$get_all_spot_balances(page_size = 10, max_pages = 1)

    # Summarise total available USDT across all sub-accounts
    usdt <- all_balances[currency == "USDT"]
    total_avail <- sum(as.numeric(usdt$available))
    cat("Total available USDT:", total_avail, "\\n")

    # Group by sub-account
    all_balances[, .(n_currencies = .N), by = .(sub_name, account_type)]
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinSubAccount$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
sub <- KucoinSubAccount$new()
summary <- sub$get_sub_account_list()
print(summary)

# Asynchronous
sub_async <- KucoinSubAccount$new(async = TRUE)
main <- coro::async(function() {
  summary <- await(sub_async$get_sub_account_list())
  print(summary)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinSubAccount$add_sub_account`
## ------------------------------------------------

if (FALSE) { # \dontrun{
sub <- KucoinSubAccount$new()

# Create a Spot sub-account
result <- sub$add_sub_account(
  password = "MyPass123",
  subName = "botaccount1",
  access = "Spot",
  remarks = "alpha-strategy"
)
print(result$uid)
print(result$sub_name)

# Create a Futures sub-account without remarks
result <- sub$add_sub_account(
  password = "SecurePass99",
  subName = "futuresbot1",
  access = "Futures"
)
} # }

## ------------------------------------------------
## Method `KucoinSubAccount$get_sub_account_list`
## ------------------------------------------------

if (FALSE) { # \dontrun{
sub <- KucoinSubAccount$new()

# Fetch all sub-accounts
all_subs <- sub$get_sub_account_list()
print(all_subs)

# Fetch only first page with 10 results
first_page <- sub$get_sub_account_list(page_size = 10, max_pages = 1)
print(first_page[, .(sub_name, access, created_at)])

# Filter for Spot sub-accounts
spot_subs <- all_subs[access == "Spot"]
} # }

## ------------------------------------------------
## Method `KucoinSubAccount$get_detail_balance`
## ------------------------------------------------

if (FALSE) { # \dontrun{
sub <- KucoinSubAccount$new()

# Get balances for a specific sub-account
balances <- sub$get_detail_balance(subUserId = "169630809")
print(balances)

# Include zero-balance currencies
all_balances <- sub$get_detail_balance(
  subUserId = "169630809",
  includeBaseAmount = TRUE
)

# Filter for trade account balances only
trade_bal <- balances[account_type == "trade"]
print(trade_bal[, .(currency, available, holds)])
} # }

## ------------------------------------------------
## Method `KucoinSubAccount$get_all_spot_balances`
## ------------------------------------------------

if (FALSE) { # \dontrun{
sub <- KucoinSubAccount$new()

# Fetch all sub-account Spot balances
all_balances <- sub$get_all_spot_balances()
print(all_balances)

# Fetch first page only with 10 results per page
first_page <- sub$get_all_spot_balances(page_size = 10, max_pages = 1)

# Summarise total available USDT across all sub-accounts
usdt <- all_balances[currency == "USDT"]
total_avail <- sum(as.numeric(usdt$available))
cat("Total available USDT:", total_avail, "\\n")

# Group by sub-account
all_balances[, .(n_currencies = .N), by = .(sub_name, account_type)]
} # }
```
