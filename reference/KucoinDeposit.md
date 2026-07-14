# KucoinDeposit: Deposit Management

KucoinDeposit: Deposit Management

KucoinDeposit: Deposit Management

## Details

Provides methods for managing deposit addresses and retrieving deposit
history on KuCoin. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Address Creation**: Create new deposit addresses for any supported
  currency and chain.

- **Address Retrieval**: Query existing deposit addresses with optional
  chain filtering.

- **Deposit History**: Retrieve paginated deposit transaction records
  with status tracking, timestamps, and wallet transaction IDs for
  on-chain verification.

### Usage

All methods require authentication (valid API key, secret, passphrase).
Deposit operations are read/write for address creation and read-only for
history retrieval. Use `get_deposit_addresses()` to check if an address
already exists before calling `add_deposit_address()` to avoid creating
duplicates.

### Official Documentation

[KuCoin Deposit
Endpoints](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)

### Endpoints Covered

|                       |                                     |      |
|-----------------------|-------------------------------------|------|
| Method                | Endpoint                            | HTTP |
| add_deposit_address   | POST /api/v3/deposit-address/create | POST |
| get_deposit_addresses | GET /api/v3/deposit-addresses       | GET  |
| get_deposit_history   | GET /api/v1/deposits                | GET  |

## Super classes

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\>
[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinDeposit`

## Methods

### Public methods

- [`KucoinDeposit$add_deposit_address()`](#method-KucoinDeposit-add_deposit_address)

- [`KucoinDeposit$get_deposit_addresses()`](#method-KucoinDeposit-get_deposit_addresses)

- [`KucoinDeposit$get_deposit_history()`](#method-KucoinDeposit-get_deposit_history)

- [`KucoinDeposit$clone()`](#method-KucoinDeposit-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_deposit_address()`

Add Deposit Address

Creates a new deposit address for a currency. Each currency/chain
combination can have a limited number of addresses. If an address
already exists for the given currency and chain, the API may return an
error; use `get_deposit_addresses()` first to check.

#### Workflow

1.  **Build Body**: Constructs JSON body with `currency` and optional
    `chain`, `to`, `amount` fields.

2.  **Request**: Authenticated POST to the deposit address creation
    endpoint.

3.  **Parsing**: Returns `data.table` with the newly created address,
    memo, and chain details.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/deposit-address/create`

#### Official Documentation

[KuCoin Add Deposit Address
V3](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)

Verified: 2026-05-23

#### Automated Trading Usage

- **Multi-Chain Support**: Specify `chain` (e.g., `"ERC20"`, `"TRC20"`)
  to create addresses on the correct network for your deposit workflow.

- **Address Pre-Provisioning**: Create deposit addresses at bot startup
  so they are ready when funds need to be received.

- **Account Routing**: Use the `to` parameter to direct deposits to
  `"main"` or `"trade"` accounts for immediate trading use.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/deposit-address/create' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"currency":"BTC","chain":"btc"}'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
        "memo": "",
        "chain": "btc",
        "chainId": "btc",
        "to": "main",
        "currency": "BTC",
        "contractAddress": ""
      }
    }

#### Usage

    KucoinDeposit$add_deposit_address(
      currency,
      chain = NULL,
      to = NULL,
      amount = NULL
    )

#### Arguments

- `currency`:

  (scalar\<character\>) currency code (e.g., `"BTC"`, `"ETH"`,
  `"USDT"`). Must be a valid KuCoin-supported currency symbol.

- `chain`:

  (scalar\<character\> \| NULL) blockchain network identifier (e.g.,
  `"ERC20"`, `"TRC20"`, `"btc"`). Required by the KuCoin API.

- `to`:

  (scalar\<character\> \| NULL) target account type for the deposit.
  Accepted values include `"main"` (funding account) and `"trade"`
  (trading account). Required by the KuCoin API.

- `amount`:

  (scalar\<character\> \| NULL) deposit amount. Required for some
  invoice-based deposit addresses (e.g., Lightning Network).

#### Returns

(data.table \| promise\<data.table\>) one row describing the newly
created deposit address: the generated address, its memo/tag (empty
string if not applicable), the blockchain network name, the chain
identifier, the target account type, the currency code, and the token
contract address (empty for native coins) – all character:

- address (character) the address.

- memo (character) the address memo/tag.

- chain (character) the chain code.

- chain_id (character \| NA) the chain identifier.

- to (character) the destination.

- currency (character) the currency code.

- contract_address (character \| NA) the token contract address.

#### Examples

    \dontrun{
    deposit <- KucoinDeposit$new()

    # Create a BTC deposit address on the default chain
    btc_addr <- deposit$add_deposit_address(currency = "BTC")
    print(btc_addr$address)

    # Create a USDT deposit address on TRC20 network
    usdt_addr <- deposit$add_deposit_address(
      currency = "USDT",
      chain = "TRC20",
      to = "trade"
    )
    print(usdt_addr[, .(address, chain, to)])
    }

------------------------------------------------------------------------

### Method `get_deposit_addresses()`

Get Deposit Addresses

Retrieves existing deposit addresses for a currency. Returns all
addresses if no chain is specified, or a single address for the given
chain. Useful for looking up addresses before creating new ones.

#### Workflow

1.  **Request**: Authenticated GET with `currency` (required) and
    optional `amount`, `chain` query parameters.

2.  **Parsing**: Normalises response into a `data.table` whether the API
    returns a single object or an array.

3.  **Result**: Returns one row per deposit address with chain and memo
    details.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/deposit-addresses`

#### Official Documentation

KuCoin Get Deposit Addresses V3:
<https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-address-v3/en>

Verified: 2026-05-23

#### Automated Trading Usage

- **Address Verification**: Query addresses before initiating external
  transfers to confirm the correct chain and memo.

- **Multi-Chain Inventory**: Retrieve all addresses for a currency to
  manage deposits across networks (e.g., ERC20 vs TRC20 for USDT).

- **Idempotent Setup**: Check if an address exists before calling
  `add_deposit_address()` to avoid duplicate creation errors.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/deposit-addresses?currency=BTC' \
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
          "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
          "memo": "",
          "chain": "btc",
          "chainId": "btc",
          "to": "main",
          "currency": "BTC",
          "contractAddress": ""
        },
        {
          "address": "0x7a1f3d8b2c9e4f5a6b7c8d9e0f1a2b3c4d5e6f7a",
          "memo": "",
          "chain": "ERC20",
          "chainId": "eth",
          "to": "main",
          "currency": "BTC",
          "contractAddress": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
        }
      ]
    }

#### Usage

    KucoinDeposit$get_deposit_addresses(currency, amount = NULL, chain = NULL)

#### Arguments

- `currency`:

  (scalar\<character\>) currency code (e.g., `"BTC"`, `"ETH"`,
  `"USDT"`). **Required** by the API.

- `amount`:

  (scalar\<character\> \| NULL) deposit amount. Some chains require an
  amount to generate invoice-based addresses (e.g., Lightning Network).

- `chain`:

  (scalar\<character\> \| NULL) blockchain network identifier (e.g.,
  `"ERC20"`, `"TRC20"`, `"btc"`). When NULL, returns addresses for all
  chains.

#### Returns

(data.table \| promise\<data.table\>) one row per deposit address, each
giving the deposit address string, its memo/tag (empty string if not
applicable), the blockchain network name, the chain identifier, the
target account type, the currency code, and the token contract address
(empty for native coins) – all character. Returns an empty data.table if
no addresses exist for the currency.

#### Examples

    \dontrun{
    deposit <- KucoinDeposit$new()

    # Get all BTC deposit addresses across all chains
    btc_addrs <- deposit$get_deposit_addresses(currency = "BTC")
    print(btc_addrs[, .(address, chain, to)])

    # Get USDT address for a specific chain
    usdt_erc20 <- deposit$get_deposit_addresses(
      currency = "USDT",
      chain = "ERC20"
    )
    print(usdt_erc20$address)
    }

------------------------------------------------------------------------

### Method `get_deposit_history()`

Get Deposit History

Retrieves paginated deposit history with optional filtering by currency,
status, and time range. Automatically coerces `created_at` timestamps to
POSIXct for convenient analysis.

#### Workflow

1.  **Pagination**: Uses `private$.paginate()` to fetch all pages of
    deposit records up to `max_pages`.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Timestamp Conversion**: Coerces `created_at` (milliseconds) to
    POSIXct in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/deposits`

#### Official Documentation

[KuCoin Get Deposit
History](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-history)

Verified: 2026-05-23

#### Automated Trading Usage

- **Deposit Monitoring**: Poll for `"SUCCESS"` status deposits to
  trigger trading logic when funds arrive.

- **Reconciliation**: Match `wallet_tx_id` against on-chain transaction
  hashes for audit and verification.

- **Time-Windowed Queries**: Use `startAt`/`endAt` timestamps to
  retrieve deposits within a specific period for daily reporting.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/deposits?currency=BTC&status=SUCCESS&currentPage=1&pageSize=50' \
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
            "currency": "BTC",
            "chain": "btc",
            "status": "SUCCESS",
            "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
            "memo": "",
            "isInner": false,
            "amount": "0.05000000",
            "fee": "0.00000000",
            "walletTxId": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2",
            "createdAt": 1729577515473,
            "updatedAt": 1729577815473,
            "remark": ""
          },
          {
            "currency": "BTC",
            "chain": "btc",
            "status": "SUCCESS",
            "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
            "memo": "",
            "isInner": true,
            "amount": "0.10000000",
            "fee": "0.00000000",
            "walletTxId": "f0e1d2c3b4a5968778695a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d",
            "createdAt": 1729491115473,
            "updatedAt": 1729491415473,
            "remark": ""
          }
        ]
      }
    }

#### Usage

    KucoinDeposit$get_deposit_history(
      currency = NULL,
      status = NULL,
      start_at = NULL,
      end_at = NULL,
      page_size = 50,
      max_pages = Inf
    )

#### Arguments

- `currency`:

  (scalar\<character\> \| NULL) filter by currency code (e.g., `"BTC"`,
  `"USDT"`). When NULL, returns deposits for all currencies.

- `status`:

  (scalar\<character\> \| NULL) filter by deposit status. Accepted
  values: `"PROCESSING"`, `"WALLET_PROCESSING"`, `"SUCCESS"`,
  `"FAILURE"`. When NULL, returns deposits of all statuses.

- `start_at`:

  (scalar\<numeric\> \| NULL) start timestamp in milliseconds
  (inclusive). Used to filter deposits created on or after this time.

- `end_at`:

  (scalar\<numeric\> \| NULL) end timestamp in milliseconds (inclusive).
  Used to filter deposits created on or before this time.

- `page_size`:

  (scalar\<count in \[1, Inf\]\>) number of results per page (default
  50, max 100).

- `max_pages`:

  (scalar\<numeric in \[1, Inf\]\>) maximum number of pages to fetch
  (default `Inf` for all pages).

#### Returns

(data.table \| promise\<data.table\>) one row per deposit, each giving
the deposited currency code, the blockchain network used, the deposit
status (`"PROCESSING"`, `"SUCCESS"`, `"FAILURE"`), the deposit address,
the memo/tag (empty string if not applicable), whether the deposit was
an internal KuCoin transfer (logical), the deposit amount, the fee
charged, the on-chain transaction hash, the creation and last update
datetimes (POSIXct, coerced from epoch milliseconds), and an optional
remark. Returns an empty data.table if no deposits match the filters.

#### Examples

    \dontrun{
    deposit <- KucoinDeposit$new()

    # Get all successful BTC deposits
    btc_deposits <- deposit$get_deposit_history(
      currency = "BTC",
      status = "SUCCESS"
    )
    print(btc_deposits[, .(amount, status, created_at)])

    # Get deposits from the last 24 hours
    now_ms <- as.numeric(lubridate::now()) * 1000
    recent <- deposit$get_deposit_history(
      startAt = as.integer(now_ms - 86400000),
      endAt = as.integer(now_ms),
      page_size = 100,
      max_pages = 5
    )
    print(recent[, .(currency, amount, wallet_tx_id, created_at)])
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinDeposit$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
deposit <- KucoinDeposit$new()
addresses <- deposit$get_deposit_addresses(currency = "BTC")
print(addresses)

# Asynchronous
deposit_async <- KucoinDeposit$new(async = TRUE)
main <- coro::async(function() {
  addrs <- await(deposit_async$get_deposit_addresses(currency = "ETH"))
  print(addrs)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinDeposit$add_deposit_address`
## ------------------------------------------------

if (FALSE) { # \dontrun{
deposit <- KucoinDeposit$new()

# Create a BTC deposit address on the default chain
btc_addr <- deposit$add_deposit_address(currency = "BTC")
print(btc_addr$address)

# Create a USDT deposit address on TRC20 network
usdt_addr <- deposit$add_deposit_address(
  currency = "USDT",
  chain = "TRC20",
  to = "trade"
)
print(usdt_addr[, .(address, chain, to)])
} # }

## ------------------------------------------------
## Method `KucoinDeposit$get_deposit_addresses`
## ------------------------------------------------

if (FALSE) { # \dontrun{
deposit <- KucoinDeposit$new()

# Get all BTC deposit addresses across all chains
btc_addrs <- deposit$get_deposit_addresses(currency = "BTC")
print(btc_addrs[, .(address, chain, to)])

# Get USDT address for a specific chain
usdt_erc20 <- deposit$get_deposit_addresses(
  currency = "USDT",
  chain = "ERC20"
)
print(usdt_erc20$address)
} # }

## ------------------------------------------------
## Method `KucoinDeposit$get_deposit_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
deposit <- KucoinDeposit$new()

# Get all successful BTC deposits
btc_deposits <- deposit$get_deposit_history(
  currency = "BTC",
  status = "SUCCESS"
)
print(btc_deposits[, .(amount, status, created_at)])

# Get deposits from the last 24 hours
now_ms <- as.numeric(lubridate::now()) * 1000
recent <- deposit$get_deposit_history(
  startAt = as.integer(now_ms - 86400000),
  endAt = as.integer(now_ms),
  page_size = 100,
  max_pages = 5
)
print(recent[, .(currency, amount, wallet_tx_id, created_at)])
} # }
```
