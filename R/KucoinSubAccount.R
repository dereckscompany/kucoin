# File: R/KucoinSubAccount.R
# R6 class for KuCoin sub-account management.

#' KucoinSubAccount: Sub-Account Management
#'
#' Provides methods for managing sub-accounts under a KuCoin master account.
#' Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Sub-Account Creation**: Create new sub-accounts with configurable permissions (Spot, Futures, Margin).
#' - **Sub-Account Listing**: Retrieve paginated summaries of all sub-accounts under the master account.
#' - **Balance Queries**: Fetch detailed balance breakdowns per sub-account across main, trade, and margin wallets.
#' - **Batch Balance Overview**: Paginated retrieval of Spot balances for all sub-accounts simultaneously (V2 endpoint).
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase) from a **master account**.
#' Sub-account API keys cannot call these endpoints; only the master account that owns the
#' sub-accounts has permission. The class supports both synchronous and asynchronous (promise-based)
#' operation depending on the `async` flag passed to the constructor.
#'
#' ```r
#' # Synchronous usage
#' sub <- KucoinSubAccount$new()
#' summary <- sub$get_sub_account_list()
#'
#' # Asynchronous usage
#' sub_async <- KucoinSubAccount$new(async = TRUE)
#' coro::async(function() {
#'   summary <- await(sub_async$get_sub_account_list())
#'   print(summary)
#' })()
#' ```
#'
#' ### Official Documentation
#' [KuCoin Sub-Account Management](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_sub_account | POST /api/v2/sub/user/created | POST |
#' | get_sub_account_list | GET /api/v2/sub/user | GET |
#' | get_detail_balance | GET /api/v1/sub-accounts/\{subUserId\} | GET |
#' | get_all_spot_balances | GET /api/v2/sub-accounts | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' sub <- KucoinSubAccount$new()
#' summary <- sub$get_sub_account_list()
#' print(summary)
#'
#' # Asynchronous
#' sub_async <- KucoinSubAccount$new(async = TRUE)
#' main <- coro::async(function() {
#'   summary <- await(sub_async$get_sub_account_list())
#'   print(summary)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSubAccount <- R6::R6Class(
  "KucoinSubAccount",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Add Sub-Account
    #'
    #' Creates a new sub-account under the master account. The sub-account is
    #' assigned a unique UID and can be granted Spot, Futures, or Margin trading
    #' permissions. Only master accounts can call this endpoint.
    #'
    #' ### Workflow
    #' 1. **Validation**: `access` is matched against `"Spot"`, `"Futures"`, `"Margin"`.
    #' 2. **Request**: Authenticated POST with sub-account creation parameters in JSON body.
    #' 3. **Parsing**: Returns a single-row `data.table` with the newly created sub-account details.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v2/sub/user/created`
    #'
    #' ### Official Documentation
    #' [KuCoin Add Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Isolation**: Create dedicated sub-accounts per strategy to isolate funds and risk.
    #' - **Permission Control**: Grant only the needed permission (e.g., `"Spot"`) to limit exposure.
    #' - **Remarks**: Use `remarks` to tag sub-accounts by strategy name for easy identification.
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v2/sub/user/created' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"password":"MyPass123","subName":"mysubacct1","access":"Spot","remarks":"bot-alpha"}'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "uid": 169630809,
    #'     "subName": "mysubacct1",
    #'     "remarks": "bot-alpha",
    #'     "access": "Spot"
    #'   }
    #' }
    #' ```
    #'
    #' @param password Character; sub-account password (7-24 chars, must contain both letters and numbers, no special characters).
    #' @param subName Character; sub-account name (7-32 chars, must start with a letter, letters and numbers only, no spaces).
    #' @param access Character; permission type: `"Spot"`, `"Futures"`, or `"Margin"`. Validated via `rlang::arg_match0()`.
    #' @param remarks Character or NULL; optional descriptive remarks for the sub-account (1-24 chars). Default `NULL`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `uid` (integer): Unique user ID assigned to the new sub-account.
    #'   - `sub_name` (character): The sub-account login name.
    #'   - `remarks` (character): The remarks string (if provided).
    #'   - `access` (character): Permission granted (`"Spot"`, `"Futures"`, or `"Margin"`).
    #'
    #' @examples
    #' \dontrun{
    #' sub <- KucoinSubAccount$new()
    #'
    #' # Create a Spot sub-account
    #' result <- sub$add_sub_account(
    #'   password = "MyPass123",
    #'   subName = "botaccount1",
    #'   access = "Spot",
    #'   remarks = "alpha-strategy"
    #' )
    #' print(result$uid)
    #' print(result$sub_name)
    #'
    #' # Create a Futures sub-account without remarks
    #' result <- sub$add_sub_account(
    #'   password = "SecurePass99",
    #'   subName = "futuresbot1",
    #'   access = "Futures"
    #' )
    #' }
    add_sub_account = function(password, subName, access, remarks = NULL) {
      access <- rlang::arg_match0(access, c("Spot", "Futures", "Margin"))

      body <- list(
        password = password,
        subName = subName,
        access = access
      )
      if (!is.null(remarks)) {
        body$remarks <- remarks
      }

      return(private$.request(
        endpoint = "/api/v2/sub/user/created",
        method = "POST",
        body = body,
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Sub-Account List Summary
    #'
    #' Retrieves a paginated summary of all sub-accounts under the master account.
    #' Automatically handles pagination, fetching up to `max_pages` pages of results.
    #' The `created_at` column is coerced from epoch milliseconds to POSIXct.
    #'
    #' ### Workflow
    #' 1. **Pagination**: Calls the paginated endpoint, fetching `page_size` records per page up to `max_pages`.
    #' 2. **Flattening**: Combines all pages into a single `data.table` via `flatten_pages()`.
    #' 3. **Timestamp Conversion**: Coerces `created_at` (ms epoch) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v2/sub/user`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Sub-Account List Summary Info](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Inventory Check**: Periodically poll sub-account lists to verify all strategy sub-accounts are active.
    #' - **Audit Trail**: Use `created_at` to track when sub-accounts were provisioned.
    #' - **Filtering**: Post-filter the returned `data.table` by `access` type to find all Spot-enabled sub-accounts.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v2/sub/user?currentPage=1&pageSize=100' \
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
    #'     "pageSize": 100,
    #'     "totalNum": 2,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "userId": "641e7f09df0db80001f1e5ac",
    #'         "uid": 169630809,
    #'         "subName": "mysubacct1",
    #'         "status": 2,
    #'         "type": 0,
    #'         "access": "Spot",
    #'         "remarks": "bot-alpha",
    #'         "createdAt": 1679726345000
    #'       },
    #'       {
    #'         "userId": "641e8027df0db80001f1e6bb",
    #'         "uid": 169630810,
    #'         "subName": "futuresbot1",
    #'         "status": 2,
    #'         "type": 0,
    #'         "access": "Futures",
    #'         "remarks": null,
    #'         "createdAt": 1679726400000
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param page_size Integer; number of results per page, between 1 and 100. Default `100`.
    #' @param max_pages Numeric; maximum number of pages to retrieve. Use `Inf` (default) to fetch all available pages.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `user_id` (character): Internal user ID string.
    #'   - `uid` (integer): Numeric user ID for the sub-account.
    #'   - `sub_name` (character): Sub-account login name.
    #'   - `status` (integer): Account status code (2 = active).
    #'   - `type` (integer): Account type code.
    #'   - `access` (character): Permission type (`"Spot"`, `"Futures"`, `"Margin"`).
    #'   - `remarks` (character): Optional remarks string.
    #'   - `created_at` (POSIXct): Creation datetime (coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' sub <- KucoinSubAccount$new()
    #'
    #' # Fetch all sub-accounts
    #' all_subs <- sub$get_sub_account_list()
    #' print(all_subs)
    #'
    #' # Fetch only first page with 10 results
    #' first_page <- sub$get_sub_account_list(page_size = 10, max_pages = 1)
    #' print(first_page[, .(sub_name, access, created_at)])
    #'
    #' # Filter for Spot sub-accounts
    #' spot_subs <- all_subs[access == "Spot"]
    #' }
    get_sub_account_list = function(page_size = 100, max_pages = Inf) {
      return(private$.paginate(
        endpoint = "/api/v2/sub/user",
        page_size = page_size,
        max_pages = max_pages,
        .parser = function(pages) {
          dt <- flatten_pages(pages)
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Sub-Account Detail Balance
    #'
    #' Retrieves detailed balance information for a specific sub-account, broken
    #' down by account type (main, trade, margin). Each currency held in the
    #' sub-account is returned as a separate row with balance, available, and
    #' holds amounts.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the sub-account detail endpoint with the `subUserId` in the URL path.
    #' 2. **Iteration**: Loops over `mainAccounts`, `tradeAccounts`, and `marginAccounts` arrays in the response.
    #' 3. **Assembly**: Binds all account entries into a single `data.table` with `account_type`, `sub_user_id`, and `sub_name` columns appended.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Sub-Account Detail Balance](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Pre-Trade Check**: Query a sub-account's available balance before placing orders to avoid insufficient-funds errors.
    #' - **Risk Monitoring**: Periodically check `holds` across sub-accounts to track capital locked in open orders.
    #' - **Rebalancing**: Compare `available` balances across sub-accounts to decide on internal transfers.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/sub-accounts/169630809?includeBaseAmount=false' \
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
    #'     "subUserId": "169630809",
    #'     "subName": "mysubacct1",
    #'     "mainAccounts": [
    #'       {
    #'         "currency": "USDT",
    #'         "balance": "1500.00000000",
    #'         "available": "1200.00000000",
    #'         "holds": "300.00000000",
    #'         "baseCurrency": "USDT",
    #'         "baseCurrencyPrice": "1",
    #'         "baseAmount": "1500.00000000",
    #'         "tag": ""
    #'       },
    #'       {
    #'         "currency": "BTC",
    #'         "balance": "0.05000000",
    #'         "available": "0.05000000",
    #'         "holds": "0.00000000",
    #'         "baseCurrency": "USDT",
    #'         "baseCurrencyPrice": "96500",
    #'         "baseAmount": "4825.00000000",
    #'         "tag": ""
    #'       }
    #'     ],
    #'     "tradeAccounts": [
    #'       {
    #'         "currency": "USDT",
    #'         "balance": "500.00000000",
    #'         "available": "450.00000000",
    #'         "holds": "50.00000000",
    #'         "baseCurrency": "USDT",
    #'         "baseCurrencyPrice": "1",
    #'         "baseAmount": "500.00000000",
    #'         "tag": ""
    #'       }
    #'     ],
    #'     "marginAccounts": [
    #'       {
    #'         "currency": "ETH",
    #'         "balance": "2.50000000",
    #'         "available": "2.50000000",
    #'         "holds": "0.00000000",
    #'         "baseCurrency": "USDT",
    #'         "baseCurrencyPrice": "3200",
    #'         "baseAmount": "8000.00000000",
    #'         "tag": ""
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param subUserId Character; the sub-account user ID (numeric UID as a string, e.g., `"169630809"`).
    #' @param includeBaseAmount Logical; if `TRUE`, includes currencies with zero balances in the response. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `currency` (character): Currency code (e.g., `"USDT"`, `"BTC"`).
    #'   - `balance` (character): Total balance for that currency.
    #'   - `available` (character): Available (unfrozen) balance.
    #'   - `holds` (character): Amount held in open orders or pending withdrawals.
    #'   - `base_currency` (character): Base currency for value conversion.
    #'   - `base_currency_price` (character): Price of the currency in base currency terms.
    #'   - `base_amount` (character): Total value in base currency.
    #'   - `tag` (character): Currency tag (if applicable).
    #'   - `account_type` (character): One of `"main"`, `"trade"`, `"margin"`.
    #'   - `sub_user_id` (character): The sub-account user ID.
    #'   - `sub_name` (character): The sub-account name.
    #'
    #' @examples
    #' \dontrun{
    #' sub <- KucoinSubAccount$new()
    #'
    #' # Get balances for a specific sub-account
    #' balances <- sub$get_detail_balance(subUserId = "169630809")
    #' print(balances)
    #'
    #' # Include zero-balance currencies
    #' all_balances <- sub$get_detail_balance(
    #'   subUserId = "169630809",
    #'   includeBaseAmount = TRUE
    #' )
    #'
    #' # Filter for trade account balances only
    #' trade_bal <- balances[account_type == "trade"]
    #' print(trade_bal[, .(currency, available, holds)])
    #' }
    get_detail_balance = function(subUserId, includeBaseAmount = FALSE) {
      return(private$.request(
        endpoint = paste0("/api/v1/sub-accounts/", subUserId),
        query = list(includeBaseAmount = tolower(as.character(includeBaseAmount))),
        .parser = function(data) {
          rows <- list()
          sub_id <- as.character(data$subUserId)
          sub_name <- as.character(data$subName)

          # Dynamically detect account type arrays by checking for currency/balance fields
          for (field_name in names(data)) {
            accounts <- data[[field_name]]
            if (!is.list(accounts) || length(accounts) == 0L) {
              next
            }
            first <- accounts[[1]]
            if (!is.list(first) || !all(c("currency", "balance") %in% names(first))) {
              next
            }

            acct_dt <- data.table::rbindlist(
              lapply(accounts, as_dt_row),
              fill = TRUE
            )
            # Map raw response field names back to semantic labels
            # (`mainAccounts` -> `"main"`, `tradeAccounts` -> `"trade"`,
            # `marginAccounts` -> `"margin"`, future-proofed for any
            # other `<x>Accounts` shape). This keeps the documented
            # filter idiom `balances[account_type == "trade"]` working
            # across schema additions.
            acct_dt[, account_type := sub("_?accounts?$", "", to_snake_case(field_name))]
            acct_dt[, sub_user_id := sub_id]
            acct_dt[, sub_name := sub_name]
            rows[[length(rows) + 1L]] <- acct_dt
          }

          if (length(rows) == 0L) {
            return(data.table::data.table()[])
          }

          dt <- data.table::rbindlist(rows, fill = TRUE)
          expected <- c("sub_user_id", "sub_name", "account_type", "currency", "balance", "available", "holds")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Spot Sub-Account List (V2)
    #'
    #' Retrieves paginated Spot sub-account balance details for all sub-accounts
    #' at once via the V2 endpoint. Each sub-account's balances are broken down
    #' by account type (main, trade, margin) and combined into a single
    #' `data.table` with `sub_user_id` and `sub_name` identifiers.
    #'
    #' ### Workflow
    #' 1. **Pagination**: Fetches pages of sub-account balance data via the V2 endpoint, `page_size` records per page up to `max_pages`.
    #' 2. **Nested Iteration**: For each sub-account in each page, iterates over `mainAccounts`, `tradeAccounts`, and `marginAccounts`.
    #' 3. **Assembly**: Binds all entries into a single `data.table` with `account_type`, `sub_user_id`, and `sub_name` columns appended.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v2/sub-accounts`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Sub-Account List Spot Balance V2](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-spot-balance-v2)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Portfolio Dashboard**: Aggregate balances across all sub-accounts for a unified portfolio view.
    #' - **Threshold Alerts**: Check `available` balances across all sub-accounts and trigger alerts when below thresholds.
    #' - **Capital Allocation**: Compare balances across sub-accounts to identify idle capital for reallocation.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v2/sub-accounts?currentPage=1&pageSize=100' \
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
    #'     "pageSize": 100,
    #'     "totalNum": 2,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "subUserId": "169630809",
    #'         "subName": "mysubacct1",
    #'         "mainAccounts": [
    #'           {
    #'             "currency": "USDT",
    #'             "balance": "1500.00000000",
    #'             "available": "1200.00000000",
    #'             "holds": "300.00000000",
    #'             "baseCurrency": "USDT",
    #'             "baseCurrencyPrice": "1",
    #'             "baseAmount": "1500.00000000",
    #'             "tag": ""
    #'           }
    #'         ],
    #'         "tradeAccounts": [
    #'           {
    #'             "currency": "BTC",
    #'             "balance": "0.01000000",
    #'             "available": "0.01000000",
    #'             "holds": "0.00000000",
    #'             "baseCurrency": "USDT",
    #'             "baseCurrencyPrice": "96500",
    #'             "baseAmount": "965.00000000",
    #'             "tag": ""
    #'           }
    #'         ],
    #'         "marginAccounts": []
    #'       },
    #'       {
    #'         "subUserId": "169630810",
    #'         "subName": "futuresbot1",
    #'         "mainAccounts": [
    #'           {
    #'             "currency": "ETH",
    #'             "balance": "5.00000000",
    #'             "available": "5.00000000",
    #'             "holds": "0.00000000",
    #'             "baseCurrency": "USDT",
    #'             "baseCurrencyPrice": "3200",
    #'             "baseAmount": "16000.00000000",
    #'             "tag": ""
    #'           }
    #'         ],
    #'         "tradeAccounts": [],
    #'         "marginAccounts": []
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param page_size Integer; number of results per page, between 10 and 100. Default `100`.
    #' @param max_pages Numeric; maximum number of pages to retrieve. Use `Inf` (default) to fetch all available pages.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `sub_user_id` (character): The sub-account user ID.
    #'   - `sub_name` (character): The sub-account name.
    #'   - `account_type` (character): One of `"main"`, `"trade"`, `"margin"`.
    #'   - `currency` (character): Currency code (e.g., `"USDT"`, `"BTC"`, `"ETH"`).
    #'   - `balance` (character): Total balance for that currency.
    #'   - `available` (character): Available (unfrozen) balance.
    #'   - `holds` (character): Amount held in open orders or pending withdrawals.
    #'   - `base_currency` (character): Base currency for value conversion.
    #'   - `base_currency_price` (character): Price of the currency in base currency terms.
    #'   - `base_amount` (character): Total value in base currency.
    #'   - `tag` (character): Currency tag (if applicable).
    #'
    #' @examples
    #' \dontrun{
    #' sub <- KucoinSubAccount$new()
    #'
    #' # Fetch all sub-account Spot balances
    #' all_balances <- sub$get_all_spot_balances()
    #' print(all_balances)
    #'
    #' # Fetch first page only with 10 results per page
    #' first_page <- sub$get_all_spot_balances(page_size = 10, max_pages = 1)
    #'
    #' # Summarise total available USDT across all sub-accounts
    #' usdt <- all_balances[currency == "USDT"]
    #' total_avail <- sum(as.numeric(usdt$available))
    #' cat("Total available USDT:", total_avail, "\\n")
    #'
    #' # Group by sub-account
    #' all_balances[, .(n_currencies = .N), by = .(sub_name, account_type)]
    #' }
    get_all_spot_balances = function(page_size = 100, max_pages = Inf) {
      return(private$.paginate(
        endpoint = "/api/v2/sub-accounts",
        page_size = page_size,
        max_pages = max_pages,
        .parser = function(pages) {
          if (length(pages) == 0L) {
            return(data.table::data.table()[])
          }

          all_rows <- list()

          for (page in pages) {
            for (item in page) {
              sub_id <- as.character(item$subUserId)
              sub_name <- as.character(item$subName)

              # Dynamically detect account type arrays
              for (field_name in names(item)) {
                accounts <- item[[field_name]]
                if (!is.list(accounts) || length(accounts) == 0L) {
                  next
                }
                first <- accounts[[1]]
                if (!is.list(first) || !all(c("currency", "balance") %in% names(first))) {
                  next
                }

                acct_dt <- data.table::rbindlist(
                  lapply(accounts, as_dt_row),
                  fill = TRUE
                )
                # Map raw response field names back to semantic labels
                # (`mainAccounts` -> `"main"`, `tradeAccounts` -> `"trade"`,
                # `marginAccounts` -> `"margin"`, future-proofed for any
                # other `<x>Accounts` shape). This keeps the documented
                # filter idiom `balances[account_type == "trade"]` working
                # across schema additions.
                acct_dt[, account_type := sub("_?accounts?$", "", to_snake_case(field_name))]
                acct_dt[, sub_user_id := sub_id]
                acct_dt[, sub_name := sub_name]
                all_rows[[length(all_rows) + 1L]] <- acct_dt
              }
            }
          }

          if (length(all_rows) == 0L) {
            return(data.table::data.table()[])
          }

          dt <- data.table::rbindlist(all_rows, fill = TRUE)
          expected <- c("sub_user_id", "sub_name", "account_type", "currency", "balance", "available", "holds")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      ))
    }
  )
)
