# KucoinAccount: Account and Funding Management

KucoinAccount: Account and Funding Management

KucoinAccount: Account and Funding Management

## Details

Provides methods for querying account information, balances, and ledger
history on KuCoin. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Account Summary**: Retrieve VIP level, sub-account count, and
  general account metadata.

- **API Key Inspection**: Query permissions, IP whitelist, and expiry
  for the active API key.

- **Spot Accounts**: List all spot/margin/trade accounts with balances,
  or inspect a single account by ID.

- **Margin Accounts**: Retrieve cross-margin and isolated-margin account
  details including liability and asset info.

- **Ledger History**: Paginated transaction history across spot and
  margin accounts with datetime conversion.

### Usage

All methods require authentication (valid API key, secret, passphrase
set via environment variables or passed to the constructor). The class
supports both synchronous and asynchronous (coro/promises) operation
modes inherited from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

    # Synchronous usage
    account <- KucoinAccount$new()
    summary <- account$get_summary()
    print(summary)

    # Asynchronous usage
    account_async <- KucoinAccount$new(async = TRUE)
    main <- coro::async(function() {
      summary <- await(account_async$get_summary())
      print(summary)
    })
    main()
    while (!later::loop_empty()) later::run_now()

### Official Documentation

[KuCoin Account
Funding](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)

### Endpoints Covered

|                             |                                  |      |
|-----------------------------|----------------------------------|------|
| Method                      | Endpoint                         | HTTP |
| get_summary                 | GET /api/v2/user-info            | GET  |
| get_apikey_info             | GET /api/v1/user/api-key         | GET  |
| get_spot_account_type       | GET /api/v1/hf/accounts/opened   | GET  |
| get_spot_accounts           | GET /api/v1/accounts             | GET  |
| get_spot_account_detail     | GET /api/v1/accounts/{accountId} | GET  |
| get_cross_margin_account    | GET /api/v3/margin/accounts      | GET  |
| get_isolated_margin_account | GET /api/v3/isolated/accounts    | GET  |
| get_spot_ledger             | GET /api/v1/accounts/ledgers     | GET  |
| get_hf_ledger               | GET /api/v1/hf/accounts/ledgers  | GET  |
| get_base_fee_rate           | GET /api/v1/base-fee             | GET  |
| get_fee_rate                | GET /api/v1/trade-fees           | GET  |

## Super class

[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinAccount`

## Methods

### Public methods

- [`KucoinAccount$get_summary()`](#method-KucoinAccount-get_summary)

- [`KucoinAccount$get_apikey_info()`](#method-KucoinAccount-get_apikey_info)

- [`KucoinAccount$get_spot_account_type()`](#method-KucoinAccount-get_spot_account_type)

- [`KucoinAccount$get_spot_accounts()`](#method-KucoinAccount-get_spot_accounts)

- [`KucoinAccount$get_spot_account_detail()`](#method-KucoinAccount-get_spot_account_detail)

- [`KucoinAccount$get_cross_margin_account()`](#method-KucoinAccount-get_cross_margin_account)

- [`KucoinAccount$get_isolated_margin_account()`](#method-KucoinAccount-get_isolated_margin_account)

- [`KucoinAccount$get_spot_ledger()`](#method-KucoinAccount-get_spot_ledger)

- [`KucoinAccount$get_hf_ledger()`](#method-KucoinAccount-get_hf_ledger)

- [`KucoinAccount$get_base_fee_rate()`](#method-KucoinAccount-get_base_fee_rate)

- [`KucoinAccount$get_fee_rate()`](#method-KucoinAccount-get_fee_rate)

- [`KucoinAccount$clone()`](#method-KucoinAccount-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_summary()`

Get Account Summary

Retrieves account summary information including VIP level, sub-account
count, and general account metadata for the authenticated user.

#### Workflow

1.  **Request**: Authenticated GET to the user-info endpoint.

2.  **Parsing**: Converts the response into a single-row `data.table`.

#### API Endpoint

`GET https://api.kucoin.com/api/v2/user-info`

#### Official Documentation

[KuCoin Get Account
Summary](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)

Verified: 2026-02-01

#### Automated Trading Usage

- **VIP Tier Monitoring**: Check `level` to confirm fee tier before
  placing large orders.

- **Sub-Account Awareness**: Use `sub_quantity` to verify sub-account
  count for multi-strategy bots.

- **Rate Limit Planning**: Higher VIP levels receive more generous rate
  limits; adjust request frequency accordingly.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v2/user-info' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "level": 1,
        "subQuantity": 3,
        "maxDefaultSubQuantity": 5,
        "maxSubQuantity": 5,
        "spotSubQuantity": 2,
        "marginSubQuantity": 1,
        "futuresSubQuantity": 0,
        "optionSubQuantity": 0,
        "maxSpotSubQuantity": 5,
        "maxMarginSubQuantity": 5,
        "maxFuturesSubQuantity": 5,
        "maxOptionSubQuantity": 5
      }
    }

#### Usage

    KucoinAccount$get_summary()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `level` (integer): VIP tier.

- `sub_quantity` (integer): Total sub-accounts.

- `max_default_sub_quantity` (integer): Max default sub-accounts.

- `max_sub_quantity` (integer): Max sub-accounts.

- `spot_sub_quantity` (integer): Spot sub-accounts.

- `margin_sub_quantity` (integer): Margin sub-accounts.

- `futures_sub_quantity` (integer): Futures sub-accounts.

- `option_sub_quantity` (integer): Option sub-accounts.

- `max_spot_sub_quantity` (integer): Max spot sub-accounts.

- `max_margin_sub_quantity` (integer): Max margin sub-accounts.

- `max_futures_sub_quantity` (integer): Max futures sub-accounts.

- `max_option_sub_quantity` (integer): Max option sub-accounts.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    summary <- account$get_summary()
    cat("VIP Level:", summary$level, "\\n")
    cat("Sub-accounts:", summary$sub_quantity, "/", summary$max_sub_quantity, "\\n")
    }

------------------------------------------------------------------------

### Method `get_apikey_info()`

Get API Key Info

Retrieves detailed information about the currently authenticated API
key, including its permissions, IP whitelist, creation date, and
associated UID.

#### Workflow

1.  **Request**: Authenticated GET to the api-key endpoint.

2.  **Parsing**: Converts the response into a single-row `data.table`.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/user/api-key`

#### Official Documentation

[KuCoin Get API Key
Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)

Verified: 2026-02-01

#### Automated Trading Usage

- **Permission Verification**: Confirm the key has `Trade` permission
  before placing orders in a bot startup routine.

- **IP Whitelist Check**: Validate that the bot's server IP is in
  `is_master`/`ip_whitelist` to avoid auth failures.

- **Key Rotation Monitoring**: Use `created_at` to track key age and
  schedule rotation for security.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/user/api-key' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "remark": "trading-bot",
        "apiKey": "670c42f1a24b1b0001a5c7e0",
        "apiVersion": 3,
        "permission": "General,Spot",
        "ipWhitelist": "198.51.100.42",
        "createdAt": 1728905969000,
        "uid": 123456789,
        "isMaster": true
      }
    }

#### Usage

    KucoinAccount$get_apikey_info()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row and columns:

- `remark` (character): Key label.

- `api_key` (character): API key ID.

- `api_version` (integer): Key version.

- `permission` (character): Comma-separated permissions e.g.
  `"General,Spot"` (already a single string from KuCoin, not a JSON
  array; recover the vector with
  `strsplit(dt$permission[1], ",", fixed = TRUE)[[1]]`).

- `ip_whitelist` (character): Allowed IPs (comma-separated string).

- `created_at` (POSIXct): Key creation datetime (coerced from epoch
  milliseconds).

- `uid` (numeric): User ID.

- `is_master` (logical): TRUE if master account key.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    key_info <- account$get_apikey_info()
    cat("Permissions:", key_info$permission, "\\n")
    cat("IP Whitelist:", key_info$ip_whitelist, "\\n")
    cat("Is Master:", key_info$is_master, "\\n")
    }

------------------------------------------------------------------------

### Method `get_spot_account_type()`

Get Spot Account Types

Retrieves the account types that have been opened for HF
(High-Frequency) spot trading. This indicates which account categories
are active.

#### Workflow

1.  **Request**: Authenticated GET to the HF accounts opened endpoint.

2.  **Parsing**: If a named list is returned, converts to a single-row
    `data.table`. If a list of entries is returned, row-binds into a
    multi-row `data.table`. Returns an empty `data.table` if no accounts
    are opened.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/accounts/opened`

#### Official Documentation

[KuCoin Get Spot Account
Type](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot)

Verified: 2026-02-01

#### Automated Trading Usage

- **Pre-Trade Validation**: Confirm HF trading accounts are opened
  before submitting HF orders.

- **Account Provisioning**: Detect missing account types at bot startup
  and alert the operator.

- **Multi-Account Bots**: Verify that both `trade` and `margin` types
  are available for strategies that span both.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/hf/accounts/opened' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": false
    }

#### Usage

    KucoinAccount$get_spot_account_type()

#### Returns

Logical scalar: `TRUE` if the user is a spot high-frequency user (use
`trade_hf` for transfers/queries), `FALSE` for low-frequency (use
`trade`). This is a compatibility interface for users who enabled HF
trading before 2024.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    is_hf <- account$get_spot_account_type()
    if (is_hf) {
      cat("HF trading account is active.\n")
    }
    }

------------------------------------------------------------------------

### Method `get_spot_accounts()`

Get Spot Account List

Retrieves all spot accounts for the authenticated user, optionally
filtered by currency or account type. Each row represents a single
account with its current balance, available funds, and holds.

#### Workflow

1.  **Request**: Authenticated GET with optional query filters.

2.  **Parsing**: Row-binds the list of account objects into a
    `data.table`. Returns an empty `data.table` if no accounts match the
    filter.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/accounts`

#### Official Documentation

[KuCoin Get Spot Account
List](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot)

Verified: 2026-02-01

#### Automated Trading Usage

- **Balance Checks**: Query available funds before placing orders to
  avoid insufficient balance errors.

- **Portfolio Snapshot**: Retrieve all account balances periodically for
  portfolio tracking and rebalancing.

- **Filter by Type**: Use `query = list(type = "trade")` to get only
  trading account balances for order sizing.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/accounts?currency=USDT&type=trade' \
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
          "id": "5bd6e9286d99522a52e458de",
          "currency": "USDT",
          "type": "trade",
          "balance": "1250.75",
          "available": "1200.50",
          "holds": "50.25"
        },
        {
          "id": "5bd6e9286d99522a52e458df",
          "currency": "BTC",
          "type": "trade",
          "balance": "0.05123",
          "available": "0.05123",
          "holds": "0"
        }
      ]
    }

#### Usage

    KucoinAccount$get_spot_accounts(query = list())

#### Arguments

- `query`:

  Named list; optional filter parameters. Supported keys:

  - `currency` (character): Filter by currency code e.g. `"USDT"`,
    `"BTC"`.

  - `type` (character): Filter by account type: `"main"`, `"trade"`, or
    `"margin"`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `id` (character): Account ID.

- `currency` (character): Currency code.

- `type` (character): Account type.

- `balance` (character): Total balance.

- `available` (character): Available for trading.

- `holds` (character): Amount on hold in open orders.

  Returns an empty `data.table` if no accounts match.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()

    # Get all accounts
    all_accounts <- account$get_spot_accounts()
    print(all_accounts)

    # Get only USDT trade accounts
    usdt <- account$get_spot_accounts(query = list(currency = "USDT", type = "trade"))
    cat("USDT available:", usdt$available, "\\n")
    }

------------------------------------------------------------------------

### Method `get_spot_account_detail()`

Get Spot Account Detail

Retrieves detailed information for a single specific account identified
by its account ID. Returns currency, type, balance, available, and
holds.

#### Workflow

1.  **Request**: Authenticated GET with the account ID appended to the
    path.

2.  **Parsing**: Converts the response into a single-row `data.table`.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/accounts/{accountId}`

#### Official Documentation

[KuCoin Get Spot Account
Detail](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot)

Verified: 2026-02-01

#### Automated Trading Usage

- **Precise Balance Check**: Query a specific account by ID when you
  already know the account to avoid parsing lists.

- **Post-Trade Verification**: After an order fills, query the relevant
  account to confirm balance changes.

- **Hold Monitoring**: Check `holds` to understand how much capital is
  locked in open orders.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/accounts/5bd6e9286d99522a52e458de' \
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
        "balance": "1250.75",
        "available": "1200.50",
        "holds": "50.25"
      }
    }

#### Usage

    KucoinAccount$get_spot_account_detail(accountId)

#### Arguments

- `accountId`:

  Character; the unique account ID (e.g. `"5bd6e9286d99522a52e458de"`).
  Obtain account IDs from `get_spot_accounts()`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `currency` (character): Currency code.

- `balance` (character): Total balance.

- `available` (character): Available for use.

- `holds` (character): Amount held in open orders.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()

    # First get all accounts to find the ID
    accounts <- account$get_spot_accounts(query = list(currency = "USDT", type = "trade"))
    account_id <- accounts$id[1]

    # Then query the specific account
    detail <- account$get_spot_account_detail(account_id)
    cat("Balance:", detail$balance, "Available:", detail$available, "\\n")
    }

------------------------------------------------------------------------

### Method `get_cross_margin_account()`

Get Cross Margin Account

Retrieves cross margin account information including balances,
liabilities, and asset details for all currencies held in the cross
margin account.

#### Workflow

1.  **Request**: Authenticated GET with optional query filters.

2.  **Parsing**: Extracts the `accounts` sub-list from the response and
    row-binds into a `data.table`. Returns empty `data.table` if no
    accounts found.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/margin/accounts`

#### Official Documentation

[KuCoin Get Cross Margin
Account](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin)

Verified: 2026-02-01

#### Automated Trading Usage

- **Margin Risk Monitoring**: Check `liability` and `totalAsset` to
  compute margin ratio and trigger de-risk actions.

- **Borrowing Capacity**: Use `available_balance` to determine how much
  additional margin is available before placing leveraged orders.

- **Cross-Margin Rebalancing**: Periodically query to detect imbalanced
  positions and repay liabilities automatically.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v3/margin/accounts?quoteCurrency=USDT&queryType=MARGIN' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "totalAssetOfQuoteCurrency": "15234.67",
        "totalLiabilityOfQuoteCurrency": "2500.00",
        "debtRatio": "0.1641",
        "status": "EFFECTIVE",
        "accounts": [
          {
            "currency": "USDT",
            "total": "10000.00",
            "available": "8500.00",
            "hold": "1500.00",
            "liability": "2500.00",
            "liabilityPrincipal": "2400.00",
            "liabilityInterest": "100.00",
            "maxBorrowSize": "50000.00",
            "borrowEnabled": true,
            "transferInEnabled": true
          },
          {
            "currency": "BTC",
            "total": "0.15",
            "available": "0.15",
            "hold": "0",
            "liability": "0",
            "liabilityPrincipal": "0",
            "liabilityInterest": "0",
            "maxBorrowSize": "2.5",
            "borrowEnabled": true,
            "transferInEnabled": true
          }
        ]
      }
    }

#### Usage

    KucoinAccount$get_cross_margin_account(query = list())

#### Arguments

- `query`:

  Named list; optional filter parameters. Supported keys:

  - `quoteCurrency` (character): Quote currency for valuation e.g.
    `"USDT"`, `"BTC"`.

  - `queryType` (character): Query type e.g. `"MARGIN"`, `"MARGIN_V2"`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row per currency (Treatment B). The
account-level summary fields (`total_asset_of_quote_currency`,
`total_liability_of_quote_currency`, `debt_ratio`, `status`) are
replicated on every row so the caller never needs a sibling method.
Columns (subset; the exact set depends on the KuCoin payload):

- `currency` (character): Currency code (e.g. `"USDT"`, `"BTC"`).

- `total` (character): Total balance.

- `available` (character): Available balance.

- `hold` (character): Amount on hold.

- `liability` (character): Total liability.

- `liability_principal` (character): Liability principal.

- `liability_interest` (character): Liability interest.

- `max_borrow_size` (character): Maximum borrowable amount.

- `borrow_enabled` (logical): Whether borrowing is enabled.

- `transfer_in_enabled` (logical): Whether transfer-in is enabled.

- `total_asset_of_quote_currency` (character): Account-level total asset
  (repeated).

- `total_liability_of_quote_currency` (character): Account-level total
  liability (repeated).

- `debt_ratio` (character): Account-level debt ratio (repeated).

- `status` (character): Account-level status (repeated).

Returns an empty `data.table` if no margin accounts exist.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    margin <- account$get_cross_margin_account(query = list(quoteCurrency = "USDT"))
    print(margin)
    # Check debt ratio
    cat("Liabilities:", margin[currency == "USDT", liability], "\\n")
    }

------------------------------------------------------------------------

### Method `get_isolated_margin_account()`

Get Isolated Margin Account

Retrieves isolated margin account information for specific trading
pairs. Each isolated margin account is tied to a single symbol and has
independent balances, liabilities, and risk parameters.

#### Workflow

1.  **Request**: Authenticated GET with optional query filters.

2.  **Parsing**: Extracts the `assets` sub-list from the response and
    row-binds into a `data.table`. Returns empty `data.table` if no
    assets found.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/isolated/accounts`

#### Official Documentation

[KuCoin Get Isolated Margin
Account](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin)

Verified: 2026-02-01

#### Automated Trading Usage

- **Per-Pair Risk Management**: Monitor isolated margin ratios per
  symbol to trigger stop-loss or de-leverage actions independently.

- **Position Sizing**: Use `available_balance` for the specific trading
  pair to size new margin orders correctly.

- **Liquidation Prevention**: Compare `debt_ratio` against liquidation
  thresholds and add margin or reduce positions automatically.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v3/isolated/accounts?symbol=BTC-USDT&quoteCurrency=USDT&queryType=ISOLATED' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "totalAssetOfQuoteCurrency": "5234.67",
        "totalLiabilityOfQuoteCurrency": "1000.00",
        "timestamp": 1729176273859,
        "assets": [
          {
            "symbol": "BTC-USDT",
            "status": "EFFECTIVE",
            "debtRatio": "0.1912",
            "baseAsset": {
              "currency": "BTC",
              "borrowEnabled": true,
              "transferInEnabled": true,
              "liability": "0",
              "liabilityPrincipal": "0",
              "liabilityInterest": "0",
              "total": "0.1",
              "available": "0.1",
              "hold": "0",
              "maxBorrowSize": "1.5"
            },
            "quoteAsset": {
              "currency": "USDT",
              "borrowEnabled": true,
              "transferInEnabled": true,
              "liability": "1000.00",
              "liabilityPrincipal": "950.00",
              "liabilityInterest": "50.00",
              "total": "5000.00",
              "available": "4500.00",
              "hold": "500.00",
              "maxBorrowSize": "25000.00"
            }
          }
        ]
      }
    }

#### Usage

    KucoinAccount$get_isolated_margin_account(query = list())

#### Arguments

- `query`:

  Named list; optional filter parameters. Supported keys:

  - `symbol` (character): Trading pair e.g. `"BTC-USDT"`. Filter to a
    specific pair.

  - `quoteCurrency` (character): Quote currency for valuation e.g.
    `"USDT"`.

  - `queryType` (character): Query type e.g. `"ISOLATED"`,
    `"ISOLATED_V2"`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with one row per isolated-margin pair (Treatment B) and
the nested `baseAsset` / `quoteAsset` objects flattened wide-prefix
(Treatment C). The account-level fields `total_asset_of_quote_currency`,
`total_liability_of_quote_currency`, and `timestamp` are replicated on
every row. Columns:

- `symbol` (character): Isolated pair symbol (e.g. `"BTC-USDT"`).

- `status` (character): Account status (e.g. `"EFFECTIVE"`).

- `debt_ratio` (character): Liability-to-asset ratio.

- `base_asset_currency` (character): Base asset code.

- `base_asset_borrow_enabled` (logical): Whether borrowing the base
  asset is allowed.

- `base_asset_transfer_in_enabled` (logical): Whether transferring the
  base asset in is allowed.

- `base_asset_liability` (character): Total base-asset liability.

- `base_asset_liability_principal` (character): Base-asset liability
  principal.

- `base_asset_liability_interest` (character): Base-asset liability
  interest.

- `base_asset_total` (character): Base-asset total balance.

- `base_asset_available` (character): Base-asset available balance.

- `base_asset_hold` (character): Base-asset amount on hold.

- `base_asset_max_borrow_size` (character): Base-asset maximum
  borrowable.

- `quote_asset_currency` (character): Quote asset code.

- `quote_asset_borrow_enabled` (logical): Whether borrowing the quote
  asset is allowed.

- `quote_asset_transfer_in_enabled` (logical): Whether transferring the
  quote asset in is allowed.

- `quote_asset_liability` (character): Total quote-asset liability.

- `quote_asset_liability_principal` (character): Quote-asset liability
  principal.

- `quote_asset_liability_interest` (character): Quote-asset liability
  interest.

- `quote_asset_total` (character): Quote-asset total balance.

- `quote_asset_available` (character): Quote-asset available balance.

- `quote_asset_hold` (character): Quote-asset amount on hold.

- `quote_asset_max_borrow_size` (character): Quote-asset maximum
  borrowable.

- `total_asset_of_quote_currency` (character): Account-level total asset
  (repeated).

- `total_liability_of_quote_currency` (character): Account-level total
  liability (repeated).

- `timestamp` (POSIXct): Snapshot timestamp (repeated).

Returns an empty `data.table` if no isolated-margin pairs exist.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    isolated <- account$get_isolated_margin_account(
      query = list(symbol = "BTC-USDT", quoteCurrency = "USDT")
    )
    print(isolated)
    }

------------------------------------------------------------------------

### Method `get_spot_ledger()`

Get Spot Account Ledger

Retrieves paginated account ledger (transaction history) for spot and
margin accounts. Each entry represents a balance change event such as a
trade fill, deposit, withdrawal, transfer, or fee charge. Automatically
coerces the `created_at` millisecond timestamp to POSIXct.

#### Workflow

1.  **Pagination**: Calls the internal `$.paginate()` method which
    fetches successive pages until all results are retrieved or
    `max_pages` is reached.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Datetime Conversion**: If `created_at` is present, coerces it to
    POSIXct in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/accounts/ledgers`

#### Official Documentation

[KuCoin Get Account Ledger
Spot/Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin)

Verified: 2026-02-01

#### Automated Trading Usage

- **Trade Reconciliation**: Compare ledger entries against expected
  fills to verify order execution integrity.

- **Fee Tracking**: Filter by `bizType = "Exchange"` to aggregate
  trading fees for cost analysis.

- **Audit Trail**: Fetch full ledger history with `max_pages = Inf` for
  end-of-day accounting and compliance.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v1/accounts/ledgers?currency=USDT&direction=in&bizType=Exchange&pageSize=50&currentPage=1' \
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
        "totalNum": 2,
        "totalPage": 1,
        "items": [
          {
            "id": "611a1e7c6a053300067a88de",
            "currency": "USDT",
            "amount": "125.50",
            "fee": "0.1255",
            "balance": "3750.25",
            "accountType": "TRADE",
            "bizType": "Exchange",
            "direction": "in",
            "createdAt": 1729176273859,
            "context": "{\"orderId\":\"670fd33bf9406e0007ab3945\",\"symbol\":\"BTC-USDT\"}"
          },
          {
            "id": "611a1e7c6a053300067a88df",
            "currency": "USDT",
            "amount": "50.00",
            "fee": "0",
            "balance": "3624.75",
            "accountType": "TRADE",
            "bizType": "Transfer",
            "direction": "out",
            "createdAt": 1729170000000,
            "context": "{\"description\":\"Transfer to main account\"}"
          }
        ]
      }
    }

#### Usage

    KucoinAccount$get_spot_ledger(query = list(), page_size = 50, max_pages = Inf)

#### Arguments

- `query`:

  Named list; optional filter parameters. Supported keys:

  - `currency` (character): Filter by currency code e.g. `"USDT"`,
    `"BTC"`.

  - `direction` (character): Filter by direction: `"in"` or `"out"`.

  - `bizType` (character): Business type filter e.g. `"Exchange"`,
    `"Deposit"`, `"Withdrawal"`, `"Transfer"`, `"Trade_Exchange"`.

  - `startAt` (numeric): Start time in milliseconds (epoch). Inclusive.

  - `endAt` (numeric): End time in milliseconds (epoch). Inclusive.

- `page_size`:

  Integer; number of results per page, between 10 and 500. Default `50`.

- `max_pages`:

  Numeric; maximum number of pages to fetch. Default `Inf` (fetch all
  pages). Set to a finite number to limit API calls.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `id` (character): Ledger entry ID.

- `currency` (character): Currency code.

- `amount` (character): Transaction amount.

- `fee` (character): Fee charged.

- `balance` (character): Balance after transaction.

- `account_type` (character): Account type e.g. `"TRADE"`, `"MAIN"`.

- `biz_type` (character): Business type.

- `direction` (character): `"in"` or `"out"`.

- `context` (character): JSON metadata.

- `created_at` (POSIXct): Coerced from epoch milliseconds.

  Returns an empty `data.table` if no ledger entries match.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()

    # Get recent USDT trade ledger entries
    ledger <- account$get_spot_ledger(
      query = list(currency = "USDT", bizType = "Exchange"),
      page_size = 100,
      max_pages = 5
    )
    print(ledger)

    # Get all ledger entries for the last 24 hours
    now_ms <- as.numeric(lubridate::now()) * 1000
    ledger_24h <- account$get_spot_ledger(
      query = list(startAt = now_ms - 86400000, endAt = now_ms)
    )
    print(ledger_24h[, .(currency, amount, direction, created_at)])
    }

------------------------------------------------------------------------

### Method `get_hf_ledger()`

Get HF Trading Account Ledger

Retrieves transfer records from high-frequency trading accounts. Results
are sorted by creation timestamp in descending order. Data is limited to
a rolling 7-day window.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/accounts/ledgers`

#### Official Documentation

[KuCoin Get Account Ledgers
Trade_hf](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-tradehf)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/accounts/ledgers?currency=USDT&bizType=TRADE_EXCHANGE&limit=100' \
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
          "id": "611a1e7c6a053300067a99ab",
          "currency": "USDT",
          "amount": "50.25",
          "fee": "0.0503",
          "tax": "0",
          "balance": "5230.75",
          "accountType": "TRADE_HF",
          "bizType": "TRADE_EXCHANGE",
          "direction": "in",
          "createdAt": 1729176273859,
          "context": "{\"orderId\":\"670fd33bf9406e0007ab3945\",\"symbol\":\"BTC-USDT\"}"
        },
        {
          "id": "611a1e7c6a053300067a99ac",
          "currency": "USDT",
          "amount": "100.00",
          "fee": "0.1000",
          "tax": "0",
          "balance": "5180.50",
          "accountType": "TRADE_HF",
          "bizType": "TRADE_EXCHANGE",
          "direction": "out",
          "createdAt": 1729170000000,
          "context": "{\"orderId\":\"670fd22af9406e0007ab3901\",\"symbol\":\"ETH-USDT\"}"
        }
      ]
    }

#### Automated Trading Usage

- **PnL Tracking**: Filter by `bizType = "TRADE_EXCHANGE"` to track
  trading gains/losses.

- **Fee Reconciliation**: Use `fee` and `tax` fields for accurate fee
  accounting.

- **Audit Trail**: Build trade-by-trade logs from the `context` JSON
  field.

#### Usage

    KucoinAccount$get_hf_ledger(
      currency = NULL,
      direction = NULL,
      bizType = NULL,
      lastId = NULL,
      limit = NULL,
      startAt = NULL,
      endAt = NULL
    )

#### Arguments

- `currency`:

  Character or NULL; filter by currency (supports up to 10
  comma-separated).

- `direction`:

  Character or NULL; `"in"` or `"out"`.

- `bizType`:

  Character or NULL; transaction type: `"TRADE_EXCHANGE"`, `"TRANSFER"`,
  `"SUB_TRANSFER"`, `"RETURNED_FEES"`, `"DEDUCTION_FEES"`, `"OTHER"`.

- `lastId`:

  Character or NULL; pagination cursor for fetching previous batches.

- `limit`:

  Integer or NULL; results per page (default 100, max 200).

- `startAt`:

  Integer or NULL; start timestamp in milliseconds.

- `endAt`:

  Integer or NULL; end timestamp in milliseconds.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `id` (character): Ledger entry ID.

- `currency` (character): Currency code.

- `amount` (character): Transaction amount.

- `fee` (character): Fee charged.

- `tax` (character): Tax amount.

- `balance` (character): Balance after transaction.

- `account_type` (character): Account type.

- `biz_type` (character): Business type.

- `direction` (character): `"in"` or `"out"`.

- `context` (character): JSON metadata.

- `created_at` (POSIXct): Coerced from epoch milliseconds.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    hf <- account$get_hf_ledger(currency = "USDT", bizType = "TRADE_EXCHANGE")
    print(hf[, .(currency, amount, fee, direction, created_at)])
    }

------------------------------------------------------------------------

### Method `get_base_fee_rate()`

Get Base Fee Rate

Retrieves the base (tier default) taker and maker fee rates for
spot/margin trading. This is the account's default rate before any
per-symbol discounts.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/base-fee`

#### Official Documentation

[KuCoin Get Basic
Fee](https://www.kucoin.com/docs-new/rest/account-info/trade-fee/get-basic-fee-spot-margin)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/base-fee?currencyType=0' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "takerFeeRate": "0.001",
        "makerFeeRate": "0.001"
      }
    }

#### Automated Trading Usage

- **Tier Awareness**: Know your default fee tier for cost estimation.

- **Fee Budgeting**: Use as baseline for worst-case fee calculations.

#### Usage

    KucoinAccount$get_base_fee_rate(currencyType = NULL)

#### Arguments

- `currencyType`:

  Integer or NULL; `0` for crypto (default), `1` for fiat.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `taker_fee_rate` (character): Base taker fee rate.

- `maker_fee_rate` (character): Base maker fee rate.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    fees <- account$get_base_fee_rate()
    cat("Taker:", fees$taker_fee_rate, "Maker:", fees$maker_fee_rate, "\n")
    }

------------------------------------------------------------------------

### Method `get_fee_rate()`

Get Actual Fee Rate

Retrieves the actual (per-symbol) taker and maker fee rates after
VIP/KCS discounts. Supports up to 10 trading pairs per request.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/trade-fees`

#### Official Documentation

[KuCoin Get Actual
Fee](https://www.kucoin.com/docs-new/rest/account-info/trade-fee/get-actual-fee-spot-margin)

Verified: 2026-03-10

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/trade-fees?symbols=BTC-USDT,ETH-USDT' \
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
          "takerFeeRate": "0.001",
          "makerFeeRate": "0.001"
        },
        {
          "symbol": "ETH-USDT",
          "takerFeeRate": "0.001",
          "makerFeeRate": "0.001"
        }
      ]
    }

#### Automated Trading Usage

- **Precise PnL**: Use actual rates for accurate profit/loss
  calculations.

- **Fee Optimization**: Compare rates across pairs to choose the
  cheapest execution venue.

- **Batch Query**: Query up to 10 pairs at once to minimize API calls.

#### Usage

    KucoinAccount$get_fee_rate(symbols)

#### Arguments

- `symbols`:

  Character; comma-separated trading pairs (max 10), e.g.
  `"BTC-USDT,ETH-USDT"`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `symbol` (character): Trading pair.

- `taker_fee_rate` (character): Actual taker fee rate.

- `maker_fee_rate` (character): Actual maker fee rate.

#### Examples

    \dontrun{
    account <- KucoinAccount$new()
    fees <- account$get_fee_rate("BTC-USDT,ETH-USDT")
    print(fees[, .(symbol, taker_fee_rate, maker_fee_rate)])
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinAccount$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
account <- KucoinAccount$new()
summary <- account$get_summary()
print(summary)

# Asynchronous
account_async <- KucoinAccount$new(async = TRUE)
main <- coro::async(function() {
  summary <- await(account_async$get_summary())
  print(summary)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinAccount$get_summary`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
summary <- account$get_summary()
cat("VIP Level:", summary$level, "\\n")
cat("Sub-accounts:", summary$sub_quantity, "/", summary$max_sub_quantity, "\\n")
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_apikey_info`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
key_info <- account$get_apikey_info()
cat("Permissions:", key_info$permission, "\\n")
cat("IP Whitelist:", key_info$ip_whitelist, "\\n")
cat("Is Master:", key_info$is_master, "\\n")
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_spot_account_type`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
is_hf <- account$get_spot_account_type()
if (is_hf) {
  cat("HF trading account is active.\n")
}
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_spot_accounts`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()

# Get all accounts
all_accounts <- account$get_spot_accounts()
print(all_accounts)

# Get only USDT trade accounts
usdt <- account$get_spot_accounts(query = list(currency = "USDT", type = "trade"))
cat("USDT available:", usdt$available, "\\n")
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_spot_account_detail`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()

# First get all accounts to find the ID
accounts <- account$get_spot_accounts(query = list(currency = "USDT", type = "trade"))
account_id <- accounts$id[1]

# Then query the specific account
detail <- account$get_spot_account_detail(account_id)
cat("Balance:", detail$balance, "Available:", detail$available, "\\n")
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_cross_margin_account`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
margin <- account$get_cross_margin_account(query = list(quoteCurrency = "USDT"))
print(margin)
# Check debt ratio
cat("Liabilities:", margin[currency == "USDT", liability], "\\n")
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_isolated_margin_account`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
isolated <- account$get_isolated_margin_account(
  query = list(symbol = "BTC-USDT", quoteCurrency = "USDT")
)
print(isolated)
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_spot_ledger`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()

# Get recent USDT trade ledger entries
ledger <- account$get_spot_ledger(
  query = list(currency = "USDT", bizType = "Exchange"),
  page_size = 100,
  max_pages = 5
)
print(ledger)

# Get all ledger entries for the last 24 hours
now_ms <- as.numeric(lubridate::now()) * 1000
ledger_24h <- account$get_spot_ledger(
  query = list(startAt = now_ms - 86400000, endAt = now_ms)
)
print(ledger_24h[, .(currency, amount, direction, created_at)])
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_hf_ledger`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
hf <- account$get_hf_ledger(currency = "USDT", bizType = "TRADE_EXCHANGE")
print(hf[, .(currency, amount, fee, direction, created_at)])
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_base_fee_rate`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
fees <- account$get_base_fee_rate()
cat("Taker:", fees$taker_fee_rate, "Maker:", fees$maker_fee_rate, "\n")
} # }

## ------------------------------------------------
## Method `KucoinAccount$get_fee_rate`
## ------------------------------------------------

if (FALSE) { # \dontrun{
account <- KucoinAccount$new()
fees <- account$get_fee_rate("BTC-USDT,ETH-USDT")
print(fees[, .(symbol, taker_fee_rate, maker_fee_rate)])
} # }
```
