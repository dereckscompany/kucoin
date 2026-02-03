# File: R/KucoinAccount.R
# R6 class for KuCoin account and funding operations.

#' KucoinAccount: Account and Funding Management
#'
#' Provides methods for querying account information, balances, and ledger
#' history on KuCoin. Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Account Summary**: Retrieve VIP level, sub-account count, and general account metadata.
#' - **API Key Inspection**: Query permissions, IP whitelist, and expiry for the active API key.
#' - **Spot Accounts**: List all spot/margin/trade accounts with balances, or inspect a single account by ID.
#' - **Margin Accounts**: Retrieve cross-margin and isolated-margin account details including liability and asset info.
#' - **Ledger History**: Paginated transaction history across spot and margin accounts with datetime conversion.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase set via
#' environment variables or passed to the constructor). The class supports both
#' synchronous and asynchronous (coro/promises) operation modes inherited from
#' [KucoinBase].
#'
#' ```r
#' # Synchronous usage
#' account <- KucoinAccount$new()
#' summary <- account$get_summary()
#' print(summary)
#'
#' # Asynchronous usage
#' account_async <- KucoinAccount$new(async = TRUE)
#' main <- coro::async(function() {
#'   summary <- await(account_async$get_summary())
#'   print(summary)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' ```
#'
#' ### Official Documentation
#' [KuCoin Account Funding](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_summary | GET /api/v2/user-info | GET |
#' | get_apikey_info | GET /api/v1/user/api-key | GET |
#' | get_spot_account_type | GET /api/v1/hf/accounts/opened | GET |
#' | get_spot_accounts | GET /api/v1/accounts | GET |
#' | get_spot_account_detail | GET /api/v1/accounts/\{accountId\} | GET |
#' | get_cross_margin_account | GET /api/v3/margin/accounts | GET |
#' | get_isolated_margin_account | GET /api/v3/isolated/accounts | GET |
#' | get_spot_ledger | GET /api/v1/accounts/ledgers | GET |
#' | get_hf_ledger | GET /api/v1/hf/accounts/ledgers | GET |
#' | get_base_fee_rate | GET /api/v1/base-fee | GET |
#' | get_fee_rate | GET /api/v1/trade-fees | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' account <- KucoinAccount$new()
#' summary <- account$get_summary()
#' print(summary)
#'
#' # Asynchronous
#' account_async <- KucoinAccount$new(async = TRUE)
#' main <- coro::async(function() {
#'   summary <- await(account_async$get_summary())
#'   print(summary)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom data.table data.table as.data.table rbindlist setcolorder
#' @export
KucoinAccount <- R6::R6Class(
  "KucoinAccount",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Get Account Summary
    #'
    #' Retrieves account summary information including VIP level, sub-account
    #' count, and general account metadata for the authenticated user.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the user-info endpoint.
    #' 2. **Parsing**: Converts the response into a single-row `data.table`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v2/user-info`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Account Summary](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **VIP Tier Monitoring**: Check `level` to confirm fee tier before placing large orders.
    #' - **Sub-Account Awareness**: Use `sub_quantity` to verify sub-account count for multi-strategy bots.
    #' - **Rate Limit Planning**: Higher VIP levels receive more generous rate limits; adjust request frequency accordingly.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v2/user-info' \
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
    #'     "level": 1,
    #'     "subQuantity": 3,
    #'     "maxDefaultSubQuantity": 5,
    #'     "maxSubQuantity": 5,
    #'     "spotSubQuantity": 2,
    #'     "marginSubQuantity": 1,
    #'     "futuresSubQuantity": 0,
    #'     "optionSubQuantity": 0,
    #'     "maxSpotSubQuantity": 5,
    #'     "maxMarginSubQuantity": 5,
    #'     "maxFuturesSubQuantity": 5,
    #'     "maxOptionSubQuantity": 5
    #'   }
    #' }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `level` (integer, VIP tier),
    #'   `sub_quantity` (integer, total sub-accounts), `max_default_sub_quantity` (integer),
    #'   `max_sub_quantity` (integer), `spot_sub_quantity` (integer), `margin_sub_quantity` (integer),
    #'   `futures_sub_quantity` (integer), `option_sub_quantity` (integer),
    #'   `max_spot_sub_quantity` (integer), `max_margin_sub_quantity` (integer),
    #'   `max_futures_sub_quantity` (integer), `max_option_sub_quantity` (integer).
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' summary <- account$get_summary()
    #' cat("VIP Level:", summary$level, "\\n")
    #' cat("Sub-accounts:", summary$sub_quantity, "/", summary$max_sub_quantity, "\\n")
    #' }
    get_summary = function() {
      return(private$.request(
        endpoint = "/api/v2/user-info",
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get API Key Info
    #'
    #' Retrieves detailed information about the currently authenticated API key,
    #' including its permissions, IP whitelist, creation date, and associated UID.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the api-key endpoint.
    #' 2. **Parsing**: Converts the response into a single-row `data.table`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/user/api-key`
    #'
    #' ### Official Documentation
    #' [KuCoin Get API Key Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Permission Verification**: Confirm the key has `Trade` permission before placing orders in a bot startup routine.
    #' - **IP Whitelist Check**: Validate that the bot's server IP is in `is_master`/`ip_whitelist` to avoid auth failures.
    #' - **Key Rotation Monitoring**: Use `created_at` to track key age and schedule rotation for security.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/user/api-key' \
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
    #'     "remark": "trading-bot",
    #'     "apiKey": "670c42f1a24b1b0001a5c7e0",
    #'     "apiVersion": 3,
    #'     "permission": "General,Spot",
    #'     "ipWhitelist": "198.51.100.42",
    #'     "createdAt": 1728905969000,
    #'     "uid": 123456789,
    #'     "isMaster": true
    #'   }
    #' }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `remark` (character, key label),
    #'   `api_key` (character, API key ID), `api_version` (integer, key version),
    #'   `permission` (character, comma-separated permissions e.g. `"General,Spot"`),
    #'   `ip_whitelist` (character, allowed IPs), `created_at` (numeric, epoch ms),
    #'   `uid` (numeric, user ID), `is_master` (logical, TRUE if master account key).
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' key_info <- account$get_apikey_info()
    #' cat("Permissions:", key_info$permission, "\\n")
    #' cat("IP Whitelist:", key_info$ip_whitelist, "\\n")
    #' cat("Is Master:", key_info$is_master, "\\n")
    #' }
    get_apikey_info = function() {
      return(private$.request(
        endpoint = "/api/v1/user/api-key",
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Spot Account Types
    #'
    #' Retrieves the account types that have been opened for HF (High-Frequency)
    #' spot trading. This indicates which account categories are active.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the HF accounts opened endpoint.
    #' 2. **Parsing**: If a named list is returned, converts to a single-row `data.table`.
    #'    If a list of entries is returned, row-binds into a multi-row `data.table`.
    #'    Returns an empty `data.table` if no accounts are opened.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Spot Account Type](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Pre-Trade Validation**: Confirm HF trading accounts are opened before submitting HF orders.
    #' - **Account Provisioning**: Detect missing account types at bot startup and alert the operator.
    #' - **Multi-Account Bots**: Verify that both `trade` and `margin` types are available for strategies that span both.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/hf/accounts/opened' \
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
    #'     "type": "trade",
    #'     "isOpened": true
    #'   }
    #' }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `type` (character, account type e.g. `"trade"`),
    #'   `is_opened` (logical, whether the account type is active). Returns an empty
    #'   `data.table` if no account types are found.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' types <- account$get_spot_account_type()
    #' print(types)
    #' # Check if trade account is opened
    #' if (nrow(types) > 0 && any(types$is_opened)) {
    #'   cat("HF trading account is active.\n")
    #' }
    #' }
    get_spot_account_type = function() {
      return(private$.request(
        endpoint = "/api/v1/hf/accounts/opened",
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table())
          }
          if (is.list(data) && !is.null(names(data))) {
            return(as_dt_row(data))
          }
          return(data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE))
        }
      ))
    },

    #' @description
    #' Get Spot Account List
    #'
    #' Retrieves all spot accounts for the authenticated user, optionally filtered
    #' by currency or account type. Each row represents a single account with its
    #' current balance, available funds, and holds.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with optional query filters.
    #' 2. **Parsing**: Row-binds the list of account objects into a `data.table`.
    #'    Returns an empty `data.table` if no accounts match the filter.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/accounts`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Spot Account List](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Balance Checks**: Query available funds before placing orders to avoid insufficient balance errors.
    #' - **Portfolio Snapshot**: Retrieve all account balances periodically for portfolio tracking and rebalancing.
    #' - **Filter by Type**: Use `query = list(type = "trade")` to get only trading account balances for order sizing.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/accounts?currency=USDT&type=trade' \
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
    #'       "id": "5bd6e9286d99522a52e458de",
    #'       "currency": "USDT",
    #'       "type": "trade",
    #'       "balance": "1250.75",
    #'       "available": "1200.50",
    #'       "holds": "50.25"
    #'     },
    #'     {
    #'       "id": "5bd6e9286d99522a52e458df",
    #'       "currency": "BTC",
    #'       "type": "trade",
    #'       "balance": "0.05123",
    #'       "available": "0.05123",
    #'       "holds": "0"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `currency` (character): Filter by currency code e.g. `"USDT"`, `"BTC"`.
    #'   - `type` (character): Filter by account type: `"main"`, `"trade"`, or `"margin"`.
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `id` (character, account ID),
    #'   `currency` (character, currency code), `type` (character, account type),
    #'   `balance` (character, total balance), `available` (character, available for trading),
    #'   `holds` (character, amount on hold in open orders). Returns an empty
    #'   `data.table` if no accounts match.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #'
    #' # Get all accounts
    #' all_accounts <- account$get_spot_accounts()
    #' print(all_accounts)
    #'
    #' # Get only USDT trade accounts
    #' usdt <- account$get_spot_accounts(query = list(currency = "USDT", type = "trade"))
    #' cat("USDT available:", usdt$available, "\\n")
    #' }
    get_spot_accounts = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v1/accounts",
        query = query,
        .parser = as_dt_list
      ))
    },

    #' @description
    #' Get Spot Account Detail
    #'
    #' Retrieves detailed information for a single specific account identified by
    #' its account ID. Returns currency, type, balance, available, and holds.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with the account ID appended to the path.
    #' 2. **Parsing**: Converts the response into a single-row `data.table`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Spot Account Detail](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Precise Balance Check**: Query a specific account by ID when you already know the account to avoid parsing lists.
    #' - **Post-Trade Verification**: After an order fills, query the relevant account to confirm balance changes.
    #' - **Hold Monitoring**: Check `holds` to understand how much capital is locked in open orders.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/accounts/5bd6e9286d99522a52e458de' \
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
    #'     "currency": "USDT",
    #'     "balance": "1250.75",
    #'     "available": "1200.50",
    #'     "holds": "50.25"
    #'   }
    #' }
    #' ```
    #'
    #' @param accountId Character; the unique account ID (e.g. `"5bd6e9286d99522a52e458de"`).
    #'   Obtain account IDs from `get_spot_accounts()`.
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `currency` (character, currency code),
    #'   `balance` (character, total balance), `available` (character, available for use),
    #'   `holds` (character, amount held in open orders).
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #'
    #' # First get all accounts to find the ID
    #' accounts <- account$get_spot_accounts(query = list(currency = "USDT", type = "trade"))
    #' account_id <- accounts$id[1]
    #'
    #' # Then query the specific account
    #' detail <- account$get_spot_account_detail(account_id)
    #' cat("Balance:", detail$balance, "Available:", detail$available, "\\n")
    #' }
    get_spot_account_detail = function(accountId) {
      return(private$.request(
        endpoint = paste0("/api/v1/accounts/", accountId),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Cross Margin Account
    #'
    #' Retrieves cross margin account information including balances, liabilities,
    #' and asset details for all currencies held in the cross margin account.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with optional query filters.
    #' 2. **Parsing**: Extracts the `accounts` sub-list from the response and
    #'    row-binds into a `data.table`. Returns empty `data.table` if no accounts found.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/accounts`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Cross Margin Account](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Margin Risk Monitoring**: Check `liability` and `totalAsset` to compute margin ratio and trigger de-risk actions.
    #' - **Borrowing Capacity**: Use `available_balance` to determine how much additional margin is available before placing leveraged orders.
    #' - **Cross-Margin Rebalancing**: Periodically query to detect imbalanced positions and repay liabilities automatically.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/margin/accounts?quoteCurrency=USDT&queryType=MARGIN' \
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
    #'     "totalAssetOfQuoteCurrency": "15234.67",
    #'     "totalLiabilityOfQuoteCurrency": "2500.00",
    #'     "debtRatio": "0.1641",
    #'     "status": "EFFECTIVE",
    #'     "accounts": [
    #'       {
    #'         "currency": "USDT",
    #'         "totalBalance": "10000.00",
    #'         "availableBalance": "8500.00",
    #'         "holdBalance": "1500.00",
    #'         "liability": "2500.00",
    #'         "maxBorrowSize": "50000.00",
    #'         "borrowEnabled": true,
    #'         "transferInEnabled": true
    #'       },
    #'       {
    #'         "currency": "BTC",
    #'         "totalBalance": "0.15",
    #'         "availableBalance": "0.15",
    #'         "holdBalance": "0",
    #'         "liability": "0",
    #'         "maxBorrowSize": "2.5",
    #'         "borrowEnabled": true,
    #'         "transferInEnabled": true
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `quoteCurrency` (character): Quote currency for valuation e.g. `"USDT"`, `"BTC"`.
    #'   - `queryType` (character): Query type e.g. `"MARGIN"`, `"MARGIN_V2"`.
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `currency` (character),
    #'   `total_balance` (character), `available_balance` (character), `hold_balance` (character),
    #'   `liability` (character), `max_borrow_size` (character), `borrow_enabled` (logical),
    #'   `transfer_in_enabled` (logical). Returns an empty `data.table` if no margin accounts exist.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' margin <- account$get_cross_margin_account(query = list(quoteCurrency = "USDT"))
    #' print(margin)
    #' # Check debt ratio
    #' cat("Liabilities:", margin[currency == "USDT", liability], "\\n")
    #' }
    get_cross_margin_account = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/margin/accounts",
        query = query,
        .parser = function(data) {
          accounts <- data$accounts %||% data
          if (is.null(accounts) || length(accounts) == 0) {
            return(data.table::data.table())
          }
          return(data.table::rbindlist(lapply(accounts, as_dt_row), fill = TRUE))
        }
      ))
    },

    #' @description
    #' Get Isolated Margin Account
    #'
    #' Retrieves isolated margin account information for specific trading pairs.
    #' Each isolated margin account is tied to a single symbol and has independent
    #' balances, liabilities, and risk parameters.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with optional query filters.
    #' 2. **Parsing**: Extracts the `assets` sub-list from the response and
    #'    row-binds into a `data.table`. Returns empty `data.table` if no assets found.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/isolated/accounts`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Isolated Margin Account](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Per-Pair Risk Management**: Monitor isolated margin ratios per symbol to trigger stop-loss or de-leverage actions independently.
    #' - **Position Sizing**: Use `available_balance` for the specific trading pair to size new margin orders correctly.
    #' - **Liquidation Prevention**: Compare `debt_ratio` against liquidation thresholds and add margin or reduce positions automatically.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/isolated/accounts?symbol=BTC-USDT&quoteCurrency=USDT&queryType=ISOLATED' \
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
    #'     "totalAssetOfQuoteCurrency": "5234.67",
    #'     "totalLiabilityOfQuoteCurrency": "1000.00",
    #'     "timestamp": 1729176273859,
    #'     "assets": [
    #'       {
    #'         "symbol": "BTC-USDT",
    #'         "status": "EFFECTIVE",
    #'         "debtRatio": "0.1912",
    #'         "baseAsset": {
    #'           "currency": "BTC",
    #'           "totalBalance": "0.1",
    #'           "holdBalance": "0",
    #'           "availableBalance": "0.1",
    #'           "liability": "0",
    #'           "interest": "0",
    #'           "borrowableAmount": "1.5"
    #'         },
    #'         "quoteAsset": {
    #'           "currency": "USDT",
    #'           "totalBalance": "5000.00",
    #'           "holdBalance": "500.00",
    #'           "availableBalance": "4500.00",
    #'           "liability": "1000.00",
    #'           "interest": "0.42",
    #'           "borrowableAmount": "25000.00"
    #'         }
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `symbol` (character): Trading pair e.g. `"BTC-USDT"`. Filter to a specific pair.
    #'   - `quoteCurrency` (character): Quote currency for valuation e.g. `"USDT"`.
    #'   - `queryType` (character): Query type e.g. `"ISOLATED"`, `"ISOLATED_V2"`.
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   Columns are flattened from the nested response and may include:
    #'   `symbol` (character), `status` (character), `debt_ratio` (character),
    #'   and nested `base_asset.*` and `quote_asset.*` fields (currency, total_balance, hold_balance,
    #'   available_balance, liability, interest, borrowable_amount). Returns an empty `data.table`
    #'   if no isolated margin accounts exist.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' isolated <- account$get_isolated_margin_account(
    #'   query = list(symbol = "BTC-USDT", quoteCurrency = "USDT")
    #' )
    #' print(isolated)
    #' }
    get_isolated_margin_account = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/isolated/accounts",
        query = query,
        .parser = function(data) {
          assets <- data$assets %||% data
          if (is.null(assets) || length(assets) == 0) {
            return(data.table::data.table())
          }
          return(data.table::rbindlist(lapply(assets, as_dt_row), fill = TRUE))
        }
      ))
    },

    #' @description
    #' Get Spot Account Ledger
    #'
    #' Retrieves paginated account ledger (transaction history) for spot and margin
    #' accounts. Each entry represents a balance change event such as a trade fill,
    #' deposit, withdrawal, transfer, or fee charge. Automatically converts the
    #' `created_at` millisecond timestamp to a `datetime_created` POSIXct column.
    #'
    #' ### Workflow
    #' 1. **Pagination**: Calls the internal `$.paginate()` method which fetches successive
    #'    pages until all results are retrieved or `max_pages` is reached.
    #' 2. **Flattening**: Combines all pages into a single `data.table` via `flatten_pages()`.
    #' 3. **Datetime Conversion**: If `created_at` is present, adds a `datetime_created`
    #'    column by converting epoch milliseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Account Ledger Spot/Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Trade Reconciliation**: Compare ledger entries against expected fills to verify order execution integrity.
    #' - **Fee Tracking**: Filter by `bizType = "Exchange"` to aggregate trading fees for cost analysis.
    #' - **Audit Trail**: Fetch full ledger history with `max_pages = Inf` for end-of-day accounting and compliance.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/accounts/ledgers?currency=USDT&direction=in&bizType=Exchange&pageSize=50&currentPage=1' \
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
    #'         "id": "611a1e7c6a053300067a88de",
    #'         "currency": "USDT",
    #'         "amount": "125.50",
    #'         "fee": "0.1255",
    #'         "balance": "3750.25",
    #'         "accountType": "TRADE",
    #'         "bizType": "Exchange",
    #'         "direction": "in",
    #'         "createdAt": 1729176273859,
    #'         "context": "{\"orderId\":\"670fd33bf9406e0007ab3945\",\"symbol\":\"BTC-USDT\"}"
    #'       },
    #'       {
    #'         "id": "611a1e7c6a053300067a88df",
    #'         "currency": "USDT",
    #'         "amount": "50.00",
    #'         "fee": "0",
    #'         "balance": "3624.75",
    #'         "accountType": "TRADE",
    #'         "bizType": "Transfer",
    #'         "direction": "out",
    #'         "createdAt": 1729170000000,
    #'         "context": "{\"description\":\"Transfer to main account\"}"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `currency` (character): Filter by currency code e.g. `"USDT"`, `"BTC"`.
    #'   - `direction` (character): Filter by direction: `"in"` or `"out"`.
    #'   - `bizType` (character): Business type filter e.g. `"Exchange"`, `"Deposit"`,
    #'     `"Withdrawal"`, `"Transfer"`, `"Trade_Exchange"`.
    #'   - `startAt` (numeric): Start time in milliseconds (epoch). Inclusive.
    #'   - `endAt` (numeric): End time in milliseconds (epoch). Inclusive.
    #' @param page_size Integer; number of results per page, between 10 and 500.
    #'   Default `50`.
    #' @param max_pages Numeric; maximum number of pages to fetch. Default `Inf`
    #'   (fetch all pages). Set to a finite number to limit API calls.
    #'
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `id` (character, ledger entry ID),
    #'   `currency` (character), `amount` (character, transaction amount),
    #'   `fee` (character, fee charged), `balance` (character, balance after transaction),
    #'   `account_type` (character, e.g. `"TRADE"`, `"MAIN"`),
    #'   `biz_type` (character, business type), `direction` (character, `"in"` or `"out"`),
    #'   `context` (character, JSON metadata),
    #'   `datetime_created` (POSIXct, converted from `created_at`).
    #'   Returns an empty `data.table` if no ledger entries match.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #'
    #' # Get recent USDT trade ledger entries
    #' ledger <- account$get_spot_ledger(
    #'   query = list(currency = "USDT", bizType = "Exchange"),
    #'   page_size = 100,
    #'   max_pages = 5
    #' )
    #' print(ledger)
    #'
    #' # Get all ledger entries for the last 24 hours
    #' now_ms <- as.numeric(lubridate::now()) * 1000
    #' ledger_24h <- account$get_spot_ledger(
    #'   query = list(startAt = now_ms - 86400000, endAt = now_ms)
    #' )
    #' print(ledger_24h[, .(currency, amount, direction, datetime_created)])
    #' }
    get_spot_ledger = function(query = list(), page_size = 50, max_pages = Inf) {
      return(private$.paginate(
        endpoint = "/api/v1/accounts/ledgers",
        query = query,
        page_size = page_size,
        max_pages = max_pages,
        .parser = function(pages) {
          dt <- flatten_pages(pages)
          if (nrow(dt) == 0) {
            return(dt)
          }
          if ("created_at" %in% names(dt)) {
            dt[, datetime_created := ms_to_datetime(created_at)]
            dt[, created_at := NULL]
          }
          return(dt)
        }
      ))
    },

    # ---- HF Ledger ----

    #' @description
    #' Get HF Trading Account Ledger
    #'
    #' Retrieves transfer records from high-frequency trading accounts.
    #' Results are sorted by creation timestamp in descending order.
    #' Data is limited to a rolling 7-day window.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/hf/accounts/ledgers`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Account Ledgers Trade_hf](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-tradehf)
    #'
    #' Verified: 2026-02-03
    #'
    #' ### Automated Trading Usage
    #' - **PnL Tracking**: Filter by `bizType = "TRADE_EXCHANGE"` to track trading gains/losses.
    #' - **Fee Reconciliation**: Use `fee` and `tax` fields for accurate fee accounting.
    #' - **Audit Trail**: Build trade-by-trade logs from the `context` JSON field.
    #'
    #' @param currency Character or NULL; filter by currency (supports up to 10 comma-separated).
    #' @param direction Character or NULL; `"in"` or `"out"`.
    #' @param bizType Character or NULL; transaction type: `"TRADE_EXCHANGE"`, `"TRANSFER"`,
    #'   `"SUB_TRANSFER"`, `"RETURNED_FEES"`, `"DEDUCTION_FEES"`, `"OTHER"`.
    #' @param lastId Character or NULL; pagination cursor for fetching previous batches.
    #' @param limit Integer or NULL; results per page (default 100, max 200).
    #' @param startAt Integer or NULL; start timestamp in milliseconds.
    #' @param endAt Integer or NULL; end timestamp in milliseconds.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   `id` (character), `currency` (character), `amount` (character),
    #'   `fee` (character), `tax` (character), `balance` (character),
    #'   `account_type` (character), `biz_type` (character),
    #'   `direction` (character), `context` (character),
    #'   `datetime_created` (POSIXct).
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' hf <- account$get_hf_ledger(currency = "USDT", bizType = "TRADE_EXCHANGE")
    #' print(hf[, .(currency, amount, fee, direction, datetime_created)])
    #' }
    get_hf_ledger = function(
      currency = NULL,
      direction = NULL,
      bizType = NULL,
      lastId = NULL,
      limit = NULL,
      startAt = NULL,
      endAt = NULL
    ) {
      return(private$.request(
        endpoint = "/api/v1/hf/accounts/ledgers",
        query = list(
          currency = currency,
          direction = direction,
          bizType = bizType,
          lastId = lastId,
          limit = limit,
          startAt = startAt,
          endAt = endAt
        ),
        .parser = function(data) {
          items <- data$items %||% data
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table())
          }
          dt <- data.table::rbindlist(
            lapply(items, as_dt_row),
            fill = TRUE
          )
          if ("created_at" %in% names(dt)) {
            dt[, datetime_created := ms_to_datetime(created_at)]
            dt[, created_at := NULL]
          }
          return(dt)
        }
      ))
    },

    # ---- Fee Rates ----

    #' @description
    #' Get Base Fee Rate
    #'
    #' Retrieves the base (tier default) taker and maker fee rates for
    #' spot/margin trading. This is the account's default rate before
    #' any per-symbol discounts.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/base-fee`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Basic Fee](https://www.kucoin.com/docs-new/rest/account-info/trade-fee/get-basic-fee-spot-margin)
    #'
    #' Verified: 2026-02-03
    #'
    #' ### Automated Trading Usage
    #' - **Tier Awareness**: Know your default fee tier for cost estimation.
    #' - **Fee Budgeting**: Use as baseline for worst-case fee calculations.
    #'
    #' @param currencyType Integer or NULL; `0` for crypto (default), `1` for fiat.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `taker_fee_rate` (character): Base taker fee rate.
    #'   - `maker_fee_rate` (character): Base maker fee rate.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' fees <- account$get_base_fee_rate()
    #' cat("Taker:", fees$taker_fee_rate, "Maker:", fees$maker_fee_rate, "\n")
    #' }
    get_base_fee_rate = function(currencyType = NULL) {
      return(private$.request(
        endpoint = "/api/v1/base-fee",
        query = list(currencyType = currencyType),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Actual Fee Rate
    #'
    #' Retrieves the actual (per-symbol) taker and maker fee rates after
    #' VIP/KCS discounts. Supports up to 10 trading pairs per request.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/trade-fees`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Actual Fee](https://www.kucoin.com/docs-new/rest/account-info/trade-fee/get-actual-fee-spot-margin)
    #'
    #' Verified: 2026-02-03
    #'
    #' ### Automated Trading Usage
    #' - **Precise PnL**: Use actual rates for accurate profit/loss calculations.
    #' - **Fee Optimization**: Compare rates across pairs to choose the cheapest execution venue.
    #' - **Batch Query**: Query up to 10 pairs at once to minimize API calls.
    #'
    #' @param symbols Character; comma-separated trading pairs (max 10),
    #'   e.g. `"BTC-USDT,ETH-USDT"`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `symbol` (character): Trading pair.
    #'   - `taker_fee_rate` (character): Actual taker fee rate.
    #'   - `maker_fee_rate` (character): Actual maker fee rate.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' fees <- account$get_fee_rate("BTC-USDT,ETH-USDT")
    #' print(fees[, .(symbol, taker_fee_rate, maker_fee_rate)])
    #' }
    get_fee_rate = function(symbols) {
      if (!is.character(symbols) || !nzchar(symbols)) {
        rlang::abort("Parameter 'symbols' must be a non-empty string of comma-separated pairs.")
      }

      return(private$.request(
        endpoint = "/api/v1/trade-fees",
        query = list(symbols = symbols),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table())
          }
          return(data.table::rbindlist(
            lapply(data, as_dt_row),
            fill = TRUE
          ))
        }
      ))
    }
  )
)
