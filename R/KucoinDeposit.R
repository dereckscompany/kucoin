# File: R/KucoinDeposit.R
# R6 class for KuCoin deposit operations.

#' KucoinDeposit: Deposit Management
#'
#' Provides methods for managing deposit addresses and retrieving deposit
#' history on KuCoin. Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Address Creation**: Create new deposit addresses for any supported currency and chain.
#' - **Address Retrieval**: Query existing deposit addresses with optional chain filtering.
#' - **Deposit History**: Retrieve paginated deposit transaction records with status tracking,
#'   timestamps, and wallet transaction IDs for on-chain verification.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase).
#' Deposit operations are read/write for address creation and read-only for
#' history retrieval. Use `get_deposit_addresses()` to check if an address
#' already exists before calling `add_deposit_address()` to avoid creating
#' duplicates.
#'
#' ### Official Documentation
#' [KuCoin Deposit Endpoints](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_deposit_address | POST /api/v3/deposit-address/create | POST |
#' | get_deposit_addresses | GET /api/v3/deposit-addresses | GET |
#' | get_deposit_history | GET /api/v1/deposits | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' deposit <- KucoinDeposit$new()
#' addresses <- deposit$get_deposit_addresses(currency = "BTC")
#' print(addresses)
#'
#' # Asynchronous
#' deposit_async <- KucoinDeposit$new(async = TRUE)
#' main <- coro::async(function() {
#'   addrs <- await(deposit_async$get_deposit_addresses(currency = "ETH"))
#'   print(addrs)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinDeposit <- R6::R6Class(
  "KucoinDeposit",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Add Deposit Address
    #'
    #' Creates a new deposit address for a currency. Each currency/chain
    #' combination can have a limited number of addresses. If an address
    #' already exists for the given currency and chain, the API may return
    #' an error; use `get_deposit_addresses()` first to check.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with `currency` and optional `chain`, `to`, `amount` fields.
    #' 2. **Request**: Authenticated POST to the deposit address creation endpoint.
    #' 3. **Parsing**: Returns `data.table` with the newly created address, memo, and chain details.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/deposit-address/create`
    #'
    #' ### Official Documentation
    #' [KuCoin Add Deposit Address V3](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Multi-Chain Support**: Specify `chain` (e.g., `"ERC20"`, `"TRC20"`) to create addresses on the correct network for your deposit workflow.
    #' - **Address Pre-Provisioning**: Create deposit addresses at bot startup so they are ready when funds need to be received.
    #' - **Account Routing**: Use the `to` parameter to direct deposits to `"main"` or `"trade"` accounts for immediate trading use.
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/deposit-address/create' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"currency":"BTC","chain":"btc"}'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
    #'     "memo": "",
    #'     "chain": "btc",
    #'     "chainId": "btc",
    #'     "to": "main",
    #'     "currency": "BTC",
    #'     "contractAddress": ""
    #'   }
    #' }
    #' ```
    #'
    #' @param currency Character; currency code (e.g., `"BTC"`, `"ETH"`, `"USDT"`).
    #'   Must be a valid KuCoin-supported currency symbol.
    #' @param chain Character; blockchain network identifier (e.g., `"ERC20"`,
    #'   `"TRC20"`, `"btc"`). Required by the KuCoin API.
    #' @param to Character; target account type for the deposit. Accepted values
    #'   include `"main"` (funding account) and `"trade"` (trading account). Required by the KuCoin API.
    #' @param amount Character or NULL; deposit amount. Required for some invoice-based
    #'   deposit addresses (e.g., Lightning Network).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with one row and columns:
    #'   - `address` (character): The generated deposit address.
    #'   - `memo` (character): Memo/tag for the address (empty string if not applicable).
    #'   - `chain` (character): Blockchain network name.
    #'   - `chain_id` (character): Chain identifier.
    #'   - `to` (character): Target account type.
    #'   - `currency` (character): Currency code.
    #'   - `contract_address` (character): Token contract address (empty for native coins).
    #'
    #' @examples
    #' \dontrun{
    #' deposit <- KucoinDeposit$new()
    #'
    #' # Create a BTC deposit address on the default chain
    #' btc_addr <- deposit$add_deposit_address(currency = "BTC")
    #' print(btc_addr$address)
    #'
    #' # Create a USDT deposit address on TRC20 network
    #' usdt_addr <- deposit$add_deposit_address(
    #'   currency = "USDT",
    #'   chain = "TRC20",
    #'   to = "trade"
    #' )
    #' print(usdt_addr[, .(address, chain, to)])
    #' }
    add_deposit_address = function(currency, chain = NULL, to = NULL, amount = NULL) {
      if (is.null(chain)) {
        rlang::abort("Parameter 'chain' is required by the KuCoin API.")
      }
      if (is.null(to)) {
        rlang::abort("Parameter 'to' is required by the KuCoin API.")
      }
      body <- list(currency = currency)
      if (!is.null(chain)) {
        body$chain <- chain
      }
      if (!is.null(to)) {
        body$to <- to
      }
      if (!is.null(amount)) {
        body$amount <- amount
      }

      return(private$.request(
        endpoint = "/api/v3/deposit-address/create",
        method = "POST",
        body = body,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          data.table::setcolorder(
            dt,
            intersect(
              c("address", "memo", "chain", "chain_id", "to", "currency", "contract_address"),
              names(dt)
            )
          )
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Deposit Addresses
    #'
    #' Retrieves existing deposit addresses for a currency. Returns all
    #' addresses if no chain is specified, or a single address for the
    #' given chain. Useful for looking up addresses before creating new ones.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `currency` (required) and optional `amount`, `chain` query parameters.
    #' 2. **Parsing**: Normalises response into a `data.table` whether the API returns a single object or an array.
    #' 3. **Result**: Returns one row per deposit address with chain and memo details.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/deposit-addresses`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Deposit Addresses V3](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-address-v3/en)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Address Verification**: Query addresses before initiating external transfers to confirm the correct chain and memo.
    #' - **Multi-Chain Inventory**: Retrieve all addresses for a currency to manage deposits across networks (e.g., ERC20 vs TRC20 for USDT).
    #' - **Idempotent Setup**: Check if an address exists before calling `add_deposit_address()` to avoid duplicate creation errors.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/deposit-addresses?currency=BTC' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
    #'       "memo": "",
    #'       "chain": "btc",
    #'       "chainId": "btc",
    #'       "to": "main",
    #'       "currency": "BTC",
    #'       "contractAddress": ""
    #'     },
    #'     {
    #'       "address": "0x7a1f3d8b2c9e4f5a6b7c8d9e0f1a2b3c4d5e6f7a",
    #'       "memo": "",
    #'       "chain": "ERC20",
    #'       "chainId": "eth",
    #'       "to": "main",
    #'       "currency": "BTC",
    #'       "contractAddress": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param currency Character; currency code (e.g., `"BTC"`, `"ETH"`, `"USDT"`). **Required** by the API.
    #' @param amount Character or NULL; deposit amount. Some chains require an amount
    #'   to generate invoice-based addresses (e.g., Lightning Network).
    #' @param chain Character or NULL; blockchain network identifier (e.g., `"ERC20"`,
    #'   `"TRC20"`, `"btc"`). When NULL, returns addresses for all chains.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with one row per address and columns:
    #'   - `address` (character): The deposit address string.
    #'   - `memo` (character): Memo/tag for the address (empty string if not applicable).
    #'   - `chain` (character): Blockchain network name.
    #'   - `chain_id` (character): Chain identifier.
    #'   - `to` (character): Target account type.
    #'   - `currency` (character): Currency code.
    #'   - `contract_address` (character): Token contract address (empty for native coins).
    #'
    #'   Returns an empty `data.table` if no addresses exist for the currency.
    #'
    #' @examples
    #' \dontrun{
    #' deposit <- KucoinDeposit$new()
    #'
    #' # Get all BTC deposit addresses across all chains
    #' btc_addrs <- deposit$get_deposit_addresses(currency = "BTC")
    #' print(btc_addrs[, .(address, chain, to)])
    #'
    #' # Get USDT address for a specific chain
    #' usdt_erc20 <- deposit$get_deposit_addresses(
    #'   currency = "USDT",
    #'   chain = "ERC20"
    #' )
    #' print(usdt_erc20$address)
    #' }
    get_deposit_addresses = function(currency, amount = NULL, chain = NULL) {
      return(private$.request(
        endpoint = "/api/v3/deposit-addresses",
        query = list(currency = currency, amount = amount, chain = chain),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          # Single object (named list) vs array of objects
          if (is.list(data) && !is.null(names(data))) {
            dt <- as_dt_row(data)
          } else {
            dt <- data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)
          }
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          data.table::setcolorder(
            dt,
            intersect(
              c("address", "memo", "chain", "chain_id", "to", "currency", "contract_address"),
              names(dt)
            )
          )
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Deposit History
    #'
    #' Retrieves paginated deposit history with optional filtering by currency,
    #' status, and time range. Automatically coerces `created_at` timestamps
    #' to POSIXct for convenient analysis.
    #'
    #' ### Workflow
    #' 1. **Pagination**: Uses `private$.paginate()` to fetch all pages of deposit records up to `max_pages`.
    #' 2. **Flattening**: Combines all pages into a single `data.table` via `flatten_pages()`.
    #' 3. **Timestamp Conversion**: Coerces `created_at` (milliseconds) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/deposits`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Deposit History](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-history)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Deposit Monitoring**: Poll for `"SUCCESS"` status deposits to trigger trading logic when funds arrive.
    #' - **Reconciliation**: Match `wallet_tx_id` against on-chain transaction hashes for audit and verification.
    #' - **Time-Windowed Queries**: Use `startAt`/`endAt` timestamps to retrieve deposits within a specific period for daily reporting.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/deposits?currency=BTC&status=SUCCESS&currentPage=1&pageSize=50' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "currentPage": 1,
    #'     "pageSize": 50,
    #'     "totalNum": 2,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "currency": "BTC",
    #'         "chain": "btc",
    #'         "status": "SUCCESS",
    #'         "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
    #'         "memo": "",
    #'         "isInner": false,
    #'         "amount": "0.05000000",
    #'         "fee": "0.00000000",
    #'         "walletTxId": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2",
    #'         "createdAt": 1729577515473,
    #'         "updatedAt": 1729577815473,
    #'         "remark": ""
    #'       },
    #'       {
    #'         "currency": "BTC",
    #'         "chain": "btc",
    #'         "status": "SUCCESS",
    #'         "address": "bc1qxz47arp3kx8f0smu4j5dqylecgn3r7sft2wkgq",
    #'         "memo": "",
    #'         "isInner": true,
    #'         "amount": "0.10000000",
    #'         "fee": "0.00000000",
    #'         "walletTxId": "f0e1d2c3b4a5968778695a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d",
    #'         "createdAt": 1729491115473,
    #'         "updatedAt": 1729491415473,
    #'         "remark": ""
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param currency Character or NULL; filter by currency code (e.g., `"BTC"`, `"USDT"`).
    #'   When NULL, returns deposits for all currencies.
    #' @param status Character or NULL; filter by deposit status. Accepted values:
    #'   `"PROCESSING"`, `"WALLET_PROCESSING"`, `"SUCCESS"`, `"FAILURE"`.
    #'   When NULL, returns deposits of all statuses.
    #' @param startAt Integer or NULL; start timestamp in milliseconds (inclusive).
    #'   Used to filter deposits created on or after this time.
    #' @param endAt Integer or NULL; end timestamp in milliseconds (inclusive).
    #'   Used to filter deposits created on or before this time.
    #' @param page_size Integer; number of results per page (default 50, max 100).
    #' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with one row per deposit and columns:
    #'   - `currency` (character): Deposited currency code.
    #'   - `chain` (character): Blockchain network used for the deposit.
    #'   - `status` (character): Deposit status (`"PROCESSING"`, `"SUCCESS"`, `"FAILURE"`).
    #'   - `address` (character): Deposit address.
    #'   - `memo` (character): Memo/tag (empty string if not applicable).
    #'   - `is_inner` (logical): Whether this was an internal KuCoin transfer.
    #'   - `amount` (character): Deposit amount.
    #'   - `fee` (character): Deposit fee charged.
    #'   - `wallet_tx_id` (character): On-chain transaction hash.
    #'   - `created_at` (POSIXct): Creation datetime (coerced from epoch milliseconds).
    #'   - `updated_at` (POSIXct): Last update datetime (coerced from epoch milliseconds).
    #'   - `remark` (character): Optional remark.
    #'
    #'   Returns an empty `data.table` if no deposits match the filters.
    #'
    #' @examples
    #' \dontrun{
    #' deposit <- KucoinDeposit$new()
    #'
    #' # Get all successful BTC deposits
    #' btc_deposits <- deposit$get_deposit_history(
    #'   currency = "BTC",
    #'   status = "SUCCESS"
    #' )
    #' print(btc_deposits[, .(amount, status, created_at)])
    #'
    #' # Get deposits from the last 24 hours
    #' now_ms <- as.numeric(lubridate::now()) * 1000
    #' recent <- deposit$get_deposit_history(
    #'   startAt = as.integer(now_ms - 86400000),
    #'   endAt = as.integer(now_ms),
    #'   page_size = 100,
    #'   max_pages = 5
    #' )
    #' print(recent[, .(currency, amount, wallet_tx_id, created_at)])
    #' }
    get_deposit_history = function(
      currency = NULL,
      status = NULL,
      startAt = NULL,
      endAt = NULL,
      page_size = 50,
      max_pages = Inf
    ) {
      return(private$.paginate(
        endpoint = "/api/v1/deposits",
        query = list(
          currency = currency,
          status = status,
          startAt = startAt,
          endAt = endAt
        ),
        page_size = page_size,
        max_pages = max_pages,
        .parser = function(pages) {
          dt <- flatten_pages(pages)
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          coerce_cols(dt, c("created_at", "updated_at"), ms_to_datetime)
          data.table::setcolorder(
            dt,
            intersect(
              c(
                "currency",
                "chain",
                "status",
                "address",
                "memo",
                "is_inner",
                "amount",
                "fee",
                "wallet_tx_id",
                "created_at",
                "updated_at",
                "remark"
              ),
              names(dt)
            )
          )
          return(dt[])
        }
      ))
    }
  )
)
