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
    #' KuCoin Get Account Summary:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **VIP Tier Monitoring**: Check `level` to confirm fee tier before placing large orders.
    #' - **Sub-Account Awareness**: Use `sub_quantity` to verify sub-account count for multi-strategy bots.
    #' - **Rate Limit Planning**: Higher VIP levels receive more generous rate limits; adjust request frequency
    #'   accordingly.
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
    #' @return (data.table | promise<data.table>) one row giving the VIP tier
    #'   level and the sub-account counts (total, spot, margin, futures, option)
    #'   alongside their respective maxima:
    #' - level (integer) the tier level.
    #' - sub_quantity (integer) the sub quantity.
    #' - max_default_sub_quantity (integer) the max default sub quantity.
    #' - max_sub_quantity (integer) the max sub quantity.
    #' - spot_sub_quantity (integer) the spot sub quantity.
    #' - margin_sub_quantity (integer) the margin sub quantity.
    #' - futures_sub_quantity (integer) the futures sub quantity.
    #' - option_sub_quantity (integer) the option sub quantity.
    #' - max_spot_sub_quantity (integer) the max spot sub quantity.
    #' - max_margin_sub_quantity (integer) the max margin sub quantity.
    #' - max_futures_sub_quantity (integer) the max futures sub quantity.
    #' - max_option_sub_quantity (integer) the max option sub quantity.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' summary <- account$get_summary()
    #' cat("VIP Level:", summary$level, "\\n")
    #' cat("Sub-accounts:", summary$sub_quantity, "/", summary$max_sub_quantity, "\\n")
    #' }
    get_summary = function() {
      res <- private$.request(
        endpoint = "/api/v2/user-info",
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_summary,
        is_async = private$.is_async
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
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Permission Verification**: Confirm the key has `Trade` permission before placing orders in a bot startup
    #'   routine.
    #' - **IP Whitelist Check**: Validate that the bot's server IP is in `is_master`/`ip_whitelist` to avoid auth
    #'   failures.
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
    #' @return (data.table | promise<data.table>) one row describing the active
    #'   API key: its label, key ID, version, comma-separated permissions and IP
    #'   whitelist, creation datetime (POSIXct, coerced from epoch milliseconds),
    #'   user ID, and whether it belongs to the master account:
    #' - remark (character) an optional remark.
    #' - api_key (character) the api key.
    #' - api_version (integer) the api version.
    #' - permission (character) the permission.
    #' - ip_whitelist (character) the ip whitelist.
    #' - created_at (POSIXct) the created at (UTC).
    #' - uid (integer) the user identifier.
    #' - is_master (logical) the is master.
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
      res <- private$.request(
        endpoint = "/api/v1/user/api-key",
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "created_at", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_apikey_info,
        is_async = private$.is_async
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
    #' KuCoin Get Spot Account Type:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Pre-Trade Validation**: Confirm HF trading accounts are opened before submitting HF orders.
    #' - **Account Provisioning**: Detect missing account types at bot startup and alert the operator.
    #' - **Multi-Account Bots**: Verify that both `trade` and `margin` types are available for strategies that span
    #'   both.
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
    #'   "data": false
    #' }
    #' ```
    #'
    #' @return (scalar<logical> | promise<scalar<logical>>) TRUE if the user is a
    #'   spot HF user (use `trade_hf` for transfers/queries), FALSE for
    #'   low-frequency (use `trade`). This is a compatibility interface for users
    #'   who enabled HF trading before 2024.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' is_hf <- account$get_spot_account_type()
    #' if (is_hf) {
    #'   cat("HF trading account is active.\n")
    #' }
    #' }
    get_spot_account_type = function() {
      res <- private$.request(
        endpoint = "/api/v1/hf/accounts/opened",
        .parser = function(data) {
          return(isTRUE(data))
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_spot_account_type,
        is_async = private$.is_async
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
    #' KuCoin Get Spot Account List:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot>
    #'
    #' Verified: 2026-05-23
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
    #' @param query (list) optional filter parameters. Supported keys:
    #'   `currency` (filter by currency code e.g. `"USDT"`, `"BTC"`) and `type`
    #'   (filter by account type: `"main"`, `"trade"`, or `"margin"`).
    #'
    #' @return (data.table | promise<data.table>) one row per spot account, each
    #'   giving the account ID, currency code, account type, total balance, the
    #'   amount available for trading, and the amount on hold in open orders.
    #'   Returns an empty data.table if no accounts match.
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
      assert_args_KucoinAccount__get_spot_accounts(query)
      res <- private$.request(
        endpoint = "/api/v1/accounts",
        query = query,
        .parser = as_dt_list
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_spot_accounts,
        is_async = private$.is_async
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
    #' KuCoin Get Spot Account Detail:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Precise Balance Check**: Query a specific account by ID when you already know the account to avoid parsing
    #'   lists.
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
    #' @param accountId (scalar<character>) the unique account ID (e.g.
    #'   `"5bd6e9286d99522a52e458de"`). Obtain account IDs from
    #'   `get_spot_accounts()`.
    #'
    #' @return (data.table | promise<data.table>) one row giving the currency
    #'   code, total balance, the amount available for use, and the amount held
    #'   in open orders for the requested account:
    #' - currency (character) the currency code.
    #' - balance (character) the total balance.
    #' - available (character) the amount available.
    #' - holds (character) the amount on hold.
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
      assert_args_KucoinAccount__get_spot_account_detail(accountId)
      assert::assert_nonempty_strings(accountId)
      res <- private$.request(
        endpoint = paste0("/api/v1/accounts/", accountId),
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_spot_account_detail,
        is_async = private$.is_async
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
    #' KuCoin Get Cross Margin Account:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Margin Risk Monitoring**: Check `liability` and `totalAsset` to compute margin ratio and trigger de-risk
    #'   actions.
    #' - **Borrowing Capacity**: Use `available_balance` to determine how much additional margin is available before
    #'   placing leveraged orders.
    #' - **Cross-Margin Rebalancing**: Periodically query to detect imbalanced positions and repay liabilities
    #'   automatically.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/accounts?quoteCurrency=USDT&queryType=MARGIN' \
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
    #'         "total": "10000.00",
    #'         "available": "8500.00",
    #'         "hold": "1500.00",
    #'         "liability": "2500.00",
    #'         "liabilityPrincipal": "2400.00",
    #'         "liabilityInterest": "100.00",
    #'         "maxBorrowSize": "50000.00",
    #'         "borrowEnabled": true,
    #'         "transferInEnabled": true
    #'       },
    #'       {
    #'         "currency": "BTC",
    #'         "total": "0.15",
    #'         "available": "0.15",
    #'         "hold": "0",
    #'         "liability": "0",
    #'         "liabilityPrincipal": "0",
    #'         "liabilityInterest": "0",
    #'         "maxBorrowSize": "2.5",
    #'         "borrowEnabled": true,
    #'         "transferInEnabled": true
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query (list) optional filter parameters. Supported keys:
    #'   `quoteCurrency` (quote currency for valuation e.g. `"USDT"`, `"BTC"`) and
    #'   `queryType` (query type e.g. `"MARGIN"`, `"MARGIN_V2"`).
    #'
    #' @return (data.table | promise<data.table>) one row per currency in the
    #'   cross-margin account, each giving the currency code, total/available/hold
    #'   balances, total liability with its principal and interest, the maximum
    #'   borrowable size, and the borrow- and transfer-in-enabled flags; the
    #'   account-level total asset, total liability, debt ratio, and status are
    #'   replicated on every row. Returns an empty data.table if no margin
    #'   accounts exist.
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
      assert_args_KucoinAccount__get_cross_margin_account(query)
      res <- private$.request(
        endpoint = "/api/v3/margin/accounts",
        query = query,
        .parser = function(data) {
          accounts <- NULL
          if (!is.null(data$accounts)) {
            accounts <- data$accounts
          }
          if (is.null(accounts) || length(accounts) == 0L) {
            return(data.table::data.table()[])
          }

          child_dt <- as_dt_list(accounts)
          if (nrow(child_dt) == 0L) {
            return(data.table::data.table()[])
          }

          # Account-level summary fields replicated on each per-currency row
          # (Treatment B with replicated parent). The spec prefers replication
          # over Treatment D here because the parent fields are small scalars
          # and the caller would otherwise need to refetch the same endpoint.
          parent <- data
          parent$accounts <- NULL
          parent_dt <- as_dt_row(parent)
          if (nrow(parent_dt) > 0L) {
            parent_dt <- parent_dt[rep(1L, nrow(child_dt))]
            dt <- cbind(child_dt, parent_dt)
          } else {
            dt <- child_dt
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_cross_margin_account,
        is_async = private$.is_async
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
    #' KuCoin Get Isolated Margin Account:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Per-Pair Risk Management**: Monitor isolated margin ratios per symbol to trigger stop-loss or de-leverage
    #'   actions independently.
    #' - **Position Sizing**: Use `available_balance` for the specific trading pair to size new margin orders correctly.
    #' - **Liquidation Prevention**: Compare `debt_ratio` against liquidation thresholds and add margin or reduce
    #'   positions automatically.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/isolated/accounts?symbol=BTC-USDT&quoteCurrency=USDT&queryType=ISOLATED' \
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
    #'           "borrowEnabled": true,
    #'           "transferInEnabled": true,
    #'           "liability": "0",
    #'           "liabilityPrincipal": "0",
    #'           "liabilityInterest": "0",
    #'           "total": "0.1",
    #'           "available": "0.1",
    #'           "hold": "0",
    #'           "maxBorrowSize": "1.5"
    #'         },
    #'         "quoteAsset": {
    #'           "currency": "USDT",
    #'           "borrowEnabled": true,
    #'           "transferInEnabled": true,
    #'           "liability": "1000.00",
    #'           "liabilityPrincipal": "950.00",
    #'           "liabilityInterest": "50.00",
    #'           "total": "5000.00",
    #'           "available": "4500.00",
    #'           "hold": "500.00",
    #'           "maxBorrowSize": "25000.00"
    #'         }
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query (list) optional filter parameters. Supported keys: `symbol`
    #'   (trading pair e.g. `"BTC-USDT"`, to filter to a specific pair),
    #'   `quoteCurrency` (quote currency for valuation e.g. `"USDT"`), and
    #'   `queryType` (query type e.g. `"ISOLATED"`, `"ISOLATED_V2"`).
    #'
    #' @return (data.table | promise<data.table>) one row per isolated-margin
    #'   pair, each giving the pair symbol, account status, and debt ratio, with
    #'   the nested base-asset and quote-asset objects flattened to wide-prefix
    #'   columns (currency, borrow- and transfer-in-enabled flags, liability with
    #'   principal and interest, total/available/hold balances, and maximum
    #'   borrowable size); the account-level total asset, total liability, and
    #'   snapshot timestamp (POSIXct, coerced from epoch milliseconds) are
    #'   replicated on every row. Returns an empty data.table if no
    #'   isolated-margin pairs exist.
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
      assert_args_KucoinAccount__get_isolated_margin_account(query)
      res <- private$.request(
        endpoint = "/api/v3/isolated/accounts",
        query = query,
        .parser = function(data) {
          assets <- NULL
          if (!is.null(data$assets)) {
            assets <- data$assets
          }
          if (is.null(assets) || length(assets) == 0L) {
            return(data.table::data.table()[])
          }

          # Flatten each asset: nested baseAsset/quoteAsset objects -> wide-prefix
          # (Treatment C). The result is a single flat record per pair so the
          # outer `as_dt_list` doesn't have to deal with list columns.
          flat_assets <- lapply(assets, function(a) {
            for (nested in c("baseAsset", "quoteAsset")) {
              obj <- a[[nested]]
              prefix <- to_snake_case(nested)
              if (!is.null(obj) && is.list(obj) && length(obj) > 0L) {
                for (nm in names(obj)) {
                  a[[paste0(prefix, "_", nm)]] <- obj[[nm]]
                }
              }
              a[[nested]] <- NULL
            }
            return(a)
          })

          child_dt <- as_dt_list(flat_assets)
          if (nrow(child_dt) == 0L) {
            return(data.table::data.table()[])
          }

          # Account-level summary fields replicated on each row (Treatment B
          # with replicated parent). Caller doesn't need a sibling method —
          # the parent summary is small enough to inline.
          parent <- data
          parent$assets <- NULL
          parent_dt <- as_dt_row(parent)
          if (nrow(parent_dt) > 0L) {
            coerce_cols(parent_dt, "timestamp", ms_to_datetime)
            parent_dt <- parent_dt[rep(1L, nrow(child_dt))]
            dt <- cbind(child_dt, parent_dt)
          } else {
            dt <- child_dt
          }

          expected <- c(
            "symbol",
            "status",
            "debt_ratio",
            "base_asset_currency",
            "base_asset_borrow_enabled",
            "base_asset_transfer_in_enabled",
            "base_asset_liability",
            "base_asset_liability_principal",
            "base_asset_liability_interest",
            "base_asset_total",
            "base_asset_available",
            "base_asset_hold",
            "base_asset_max_borrow_size",
            "quote_asset_currency",
            "quote_asset_borrow_enabled",
            "quote_asset_transfer_in_enabled",
            "quote_asset_liability",
            "quote_asset_liability_principal",
            "quote_asset_liability_interest",
            "quote_asset_total",
            "quote_asset_available",
            "quote_asset_hold",
            "quote_asset_max_borrow_size",
            "total_asset_of_quote_currency",
            "total_liability_of_quote_currency",
            "timestamp"
          )
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_isolated_margin_account,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Spot Account Ledger
    #'
    #' Retrieves paginated account ledger (transaction history) for spot and margin
    #' accounts. Each entry represents a balance change event such as a trade fill,
    #' deposit, withdrawal, transfer, or fee charge. Automatically coerces the
    #' `created_at` millisecond timestamp to POSIXct.
    #'
    #' ### Workflow
    #' 1. **Pagination**: Calls the internal `$.paginate()` method which fetches successive
    #'    pages until all results are retrieved or `max_pages` is reached.
    #' 2. **Flattening**: Combines all pages into a single `data.table` via `flatten_pages()`.
    #' 3. **Datetime Conversion**: If `created_at` is present, coerces it to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
    #'
    #' ### Official Documentation
    #' KuCoin Get Account Ledger Spot/Margin:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Trade Reconciliation**: Compare ledger entries against expected fills to verify order execution integrity.
    #' - **Fee Tracking**: Filter by `bizType = "Exchange"` to aggregate trading fees for cost analysis.
    #' - **Audit Trail**: Fetch full ledger history with `max_pages = Inf` for end-of-day accounting and compliance.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/accounts/ledgers?currency=USDT&direction=in&bizType=Exchange' \
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
    #' @param query (list) optional filter parameters. Supported keys: `currency`
    #'   (filter by currency code e.g. `"USDT"`, `"BTC"`), `direction` (filter by
    #'   direction: `"in"` or `"out"`), `bizType` (business type filter e.g.
    #'   `"Exchange"`, `"Deposit"`, `"Withdrawal"`, `"Transfer"`,
    #'   `"Trade_Exchange"`), `startAt` (start time in milliseconds epoch,
    #'   inclusive), and `endAt` (end time in milliseconds epoch, inclusive).
    #' @param page_size (scalar<count in [1, Inf[>) number of results per page,
    #'   between 10 and 500 (default 50).
    #' @param max_pages (scalar<numeric in [1, Inf]>) maximum number of pages to
    #'   fetch (default `Inf` for all pages). Set to a finite number to limit API
    #'   calls.
    #'
    #' @return (data.table | promise<data.table>) one row per ledger entry, each
    #'   giving the entry ID, currency code, transaction amount, fee charged,
    #'   balance after the transaction, account type (`"TRADE"`, `"MAIN"`),
    #'   business type, direction (`"in"` or `"out"`), the JSON context metadata,
    #'   and the creation datetime (POSIXct, coerced from epoch milliseconds).
    #'   Returns an empty data.table if no ledger entries match.
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
    #' print(ledger_24h[, .(currency, amount, direction, created_at)])
    #' }
    get_spot_ledger = function(query = list(), page_size = 50, max_pages = Inf) {
      assert_args_KucoinAccount__get_spot_ledger(query, page_size, max_pages)
      res <- private$.paginate(
        endpoint = "/api/v1/accounts/ledgers",
        query = query,
        page_size = page_size,
        max_pages = max_pages,
        .parser = function(pages) {
          dt <- flatten_pages(pages)
          if (nrow(dt) == 0) {
            return(dt[])
          }
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c(
                "id",
                "currency",
                "amount",
                "fee",
                "balance",
                "account_type",
                "biz_type",
                "direction",
                "context",
                "created_at"
              ),
              names(dt)
            )
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_spot_ledger,
        is_async = private$.is_async
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
    #' KuCoin Get Account Ledgers Trade_hf:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-tradehf>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/hf/accounts/ledgers?currency=USDT&bizType=TRADE_EXCHANGE&limit=100' \
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
    #'       "id": "611a1e7c6a053300067a99ab",
    #'       "currency": "USDT",
    #'       "amount": "50.25",
    #'       "fee": "0.0503",
    #'       "tax": "0",
    #'       "balance": "5230.75",
    #'       "accountType": "TRADE_HF",
    #'       "bizType": "TRADE_EXCHANGE",
    #'       "direction": "in",
    #'       "createdAt": 1729176273859,
    #'       "context": "{\"orderId\":\"670fd33bf9406e0007ab3945\",\"symbol\":\"BTC-USDT\"}"
    #'     },
    #'     {
    #'       "id": "611a1e7c6a053300067a99ac",
    #'       "currency": "USDT",
    #'       "amount": "100.00",
    #'       "fee": "0.1000",
    #'       "tax": "0",
    #'       "balance": "5180.50",
    #'       "accountType": "TRADE_HF",
    #'       "bizType": "TRADE_EXCHANGE",
    #'       "direction": "out",
    #'       "createdAt": 1729170000000,
    #'       "context": "{\"orderId\":\"670fd22af9406e0007ab3901\",\"symbol\":\"ETH-USDT\"}"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **PnL Tracking**: Filter by `bizType = "TRADE_EXCHANGE"` to track trading gains/losses.
    #' - **Fee Reconciliation**: Use `fee` and `tax` fields for accurate fee accounting.
    #' - **Audit Trail**: Build trade-by-trade logs from the `context` JSON field.
    #'
    #' @param currency (scalar<character> | NULL) filter by currency (supports up
    #'   to 10 comma-separated).
    #' @param direction (scalar<character> | NULL) `"in"` or `"out"`.
    #' @param bizType (scalar<character> | NULL) transaction type:
    #'   `"TRADE_EXCHANGE"`, `"TRANSFER"`, `"SUB_TRANSFER"`, `"RETURNED_FEES"`,
    #'   `"DEDUCTION_FEES"`, `"OTHER"`.
    #' @param lastId (scalar<character> | NULL) pagination cursor for fetching
    #'   previous batches.
    #' @param limit (scalar<count> | NULL) results per page (default 100, max
    #'   200).
    #' @param startAt (scalar<numeric> | NULL) start timestamp in milliseconds.
    #' @param endAt (scalar<numeric> | NULL) end timestamp in milliseconds.
    #' @return (data.table | promise<data.table>) one row per ledger entry, each
    #'   giving the entry ID, currency code, transaction amount, fee charged, tax
    #'   amount, balance after the transaction, account type, business type,
    #'   direction (`"in"` or `"out"`), the JSON context metadata, and the
    #'   creation datetime (POSIXct, coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' hf <- account$get_hf_ledger(currency = "USDT", bizType = "TRADE_EXCHANGE")
    #' print(hf[, .(currency, amount, fee, direction, created_at)])
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
      assert_args_KucoinAccount__get_hf_ledger(
        currency,
        direction,
        bizType,
        lastId,
        limit,
        startAt,
        endAt
      )
      res <- private$.request(
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
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(
            lapply(items, as_dt_row),
            fill = TRUE
          )
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c(
                "id",
                "currency",
                "amount",
                "fee",
                "tax",
                "balance",
                "account_type",
                "biz_type",
                "direction",
                "context",
                "created_at"
              ),
              names(dt)
            )
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_hf_ledger,
        is_async = private$.is_async
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
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/base-fee?currencyType=0' \
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
    #'     "takerFeeRate": "0.001",
    #'     "makerFeeRate": "0.001"
    #'   }
    #' }
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **Tier Awareness**: Know your default fee tier for cost estimation.
    #' - **Fee Budgeting**: Use as baseline for worst-case fee calculations.
    #'
    #' @param currencyType (scalar<count> | NULL) `0` for crypto (default), `1`
    #'   for fiat.
    #' @return (data.table | promise<data.table>) one row giving the base taker
    #'   fee rate and the base maker fee rate:
    #' - taker_fee_rate (character) the taker fee rate.
    #' - maker_fee_rate (character) the maker fee rate.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' fees <- account$get_base_fee_rate()
    #' cat("Taker:", fees$taker_fee_rate, "Maker:", fees$maker_fee_rate, "\n")
    #' }
    get_base_fee_rate = function(currencyType = NULL) {
      assert_args_KucoinAccount__get_base_fee_rate(currencyType)
      res <- private$.request(
        endpoint = "/api/v1/base-fee",
        query = list(currencyType = currencyType),
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_base_fee_rate,
        is_async = private$.is_async
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
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/trade-fees?symbols=BTC-USDT,ETH-USDT' \
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
    #'       "symbol": "BTC-USDT",
    #'       "takerFeeRate": "0.001",
    #'       "makerFeeRate": "0.001"
    #'     },
    #'     {
    #'       "symbol": "ETH-USDT",
    #'       "takerFeeRate": "0.001",
    #'       "makerFeeRate": "0.001"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **Precise PnL**: Use actual rates for accurate profit/loss calculations.
    #' - **Fee Optimization**: Compare rates across pairs to choose the cheapest execution venue.
    #' - **Batch Query**: Query up to 10 pairs at once to minimize API calls.
    #'
    #' @param symbols (scalar<character>) comma-separated trading pairs (max 10),
    #'   e.g. `"BTC-USDT,ETH-USDT"`.
    #' @return (data.table | promise<data.table>) one row per trading pair, each
    #'   giving the pair symbol, the actual taker fee rate, and the actual maker
    #'   fee rate:
    #' - symbol (character) the trading pair symbol.
    #' - taker_fee_rate (character) the taker fee rate.
    #' - maker_fee_rate (character) the maker fee rate.
    #'
    #' @examples
    #' \dontrun{
    #' account <- KucoinAccount$new()
    #' fees <- account$get_fee_rate("BTC-USDT,ETH-USDT")
    #' print(fees[, .(symbol, taker_fee_rate, maker_fee_rate)])
    #' }
    get_fee_rate = function(symbols) {
      assert_args_KucoinAccount__get_fee_rate(symbols)
      if (!is.character(symbols) || !nzchar(symbols)) {
        rlang::abort("Parameter 'symbols' must be a non-empty string of comma-separated pairs.")
      }

      res <- private$.request(
        endpoint = "/api/v1/trade-fees",
        query = list(symbols = symbols),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(
            lapply(data, as_dt_row),
            fill = TRUE
          )
          data.table::setcolorder(dt, intersect(c("symbol", "taker_fee_rate", "maker_fee_rate"), names(dt)))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinAccount__get_fee_rate,
        is_async = private$.is_async
      ))
    }
  )
)
