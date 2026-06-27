# File: R/KucoinWithdrawal.R
# R6 class for KuCoin withdrawal operations.

#' KucoinWithdrawal: Withdrawal Management
#'
#' Provides methods for creating, cancelling, and querying cryptocurrency
#' withdrawals on KuCoin. Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Withdrawal Creation**: Initiate withdrawals to external addresses, KuCoin UIDs, email, or phone.
#' - **Withdrawal Cancellation**: Cancel pending withdrawals that are still in `PROCESSING` status.
#' - **Quota Queries**: Check withdrawal limits, minimum fees, and available balances per currency/chain.
#' - **History Retrieval**: Retrieve paginated withdrawal records with status tracking and timestamps.
#' - **Detail Lookup**: Get comprehensive details for a specific withdrawal by ID.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase).
#' The API key must have **Withdrawal** permission for `add_withdrawal()` and
#' `cancel_withdrawal()`. Query methods (`get_*`) require only **General** permission.
#'
#' ```r
#' # Synchronous usage
#' withdrawal <- KucoinWithdrawal$new()
#' quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
#'
#' # Asynchronous usage
#' withdrawal_async <- KucoinWithdrawal$new(async = TRUE)
#' coro::async(function() {
#'   quotas <- await(withdrawal_async$get_withdrawal_quotas(currency = "BTC"))
#'   print(quotas)
#' })()
#' ```
#'
#' ### Official Documentation
#' [KuCoin Withdrawal Endpoints](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/withdraw-v3)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_withdrawal | POST /api/v3/withdrawals | POST |
#' | cancel_withdrawal | DELETE /api/v1/withdrawals/\{withdrawalId\} | DELETE |
#' | get_withdrawal_quotas | GET /api/v1/withdrawals/quotas | GET |
#' | get_withdrawal_history | GET /api/v1/withdrawals | GET |
#' | get_withdrawal_by_id | GET /api/v1/withdrawals/\{withdrawalId\} | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' withdrawal <- KucoinWithdrawal$new()
#' quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
#' print(quotas)
#'
#' # Asynchronous
#' withdrawal_async <- KucoinWithdrawal$new(async = TRUE)
#' main <- coro::async(function() {
#'   quotas <- await(withdrawal_async$get_withdrawal_quotas(currency = "BTC"))
#'   print(quotas)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinWithdrawal <- R6::R6Class(
  "KucoinWithdrawal",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Add Withdrawal
    #'
    #' Initiates a new withdrawal request. Supports withdrawals to external
    #' blockchain addresses, KuCoin UIDs, email addresses, and phone numbers.
    #' Only withdrawals in `PROCESSING` status can later be cancelled via
    #' `cancel_withdrawal()`.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with required and optional fields.
    #' 2. **Request**: Authenticated POST to the withdrawal endpoint.
    #' 3. **Parsing**: Returns `data.table` with the withdrawal ID.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/withdrawals`
    #'
    #' ### Official Documentation
    #' [KuCoin Withdraw V3](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/withdraw-v3)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Profit Extraction**: Withdraw profits to a cold wallet at regular intervals.
    #' - **Arbitrage Settlement**: Move funds off-exchange after capturing arbitrage spreads.
    #' - **Internal Transfers**: Use `isInner = TRUE` for fee-free transfers between KuCoin accounts.
    #' - **Multi-Chain Support**: Specify `chain` (e.g., `"trx"`, `"eth"`, `"bsc"`) to select the cheapest or fastest
    #'   network.
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/withdrawals' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw \
    #'   '{"currency":"USDT","toAddress":"TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8","amount":"10","withdrawType":"ADDRESS",
    #'   "chain":"trx"}'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "withdrawalId": "670deec84d64da0007d7c946"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) currency code (e.g., `"BTC"`,
    #'   `"USDT"`).
    #' @param toAddress (scalar<character>) withdrawal destination address, UID,
    #'   email, or phone number.
    #' @param amount (scalar<character>) withdrawal amount (must be positive,
    #'   multiple of currency precision).
    #' @param withdrawType (scalar<character>) withdrawal type: `"ADDRESS"`,
    #'   `"UID"`, `"MAIL"`, or `"PHONE"`.
    #' @param chain (scalar<character> | NULL) blockchain network identifier
    #'   (e.g., `"eth"`, `"trx"`, `"bsc"`). Required by the KuCoin API; the method
    #'   raises if `NULL`.
    #' @param memo (scalar<character> | NULL) address memo/tag (required for some
    #'   currencies like XRP, XLM).
    #' @param isInner (scalar<logical> | NULL) if `TRUE`, this is an internal
    #'   KuCoin transfer (no on-chain fee).
    #' @param remark (scalar<character> | NULL) optional remark for the
    #'   withdrawal.
    #' @param feeDeductType (scalar<character> | NULL) fee deduction type:
    #'   `"INTERNAL"` or `"EXTERNAL"`.
    #' @return (data.table | promise<data.table>) one row with column
    #'   `withdrawal_id` (character): the unique withdrawal identifier.
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- KucoinWithdrawal$new()
    #'
    #' # Withdraw USDT via TRC20
    #' result <- withdrawal$add_withdrawal(
    #'   currency = "USDT",
    #'   toAddress = "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    #'   amount = "10",
    #'   withdrawType = "ADDRESS",
    #'   chain = "trx"
    #' )
    #' print(result$withdrawal_id)
    #'
    #' # Internal KuCoin transfer by UID
    #' result <- withdrawal$add_withdrawal(
    #'   currency = "BTC",
    #'   toAddress = "12345678",
    #'   amount = "0.01",
    #'   withdrawType = "UID",
    #'   isInner = TRUE
    #' )
    #' }
    add_withdrawal = function(
      currency,
      toAddress,
      amount,
      withdrawType,
      chain = NULL,
      memo = NULL,
      isInner = NULL,
      remark = NULL,
      feeDeductType = NULL
    ) {
      assert_args_KucoinWithdrawal__add_withdrawal(
        currency,
        toAddress,
        amount,
        withdrawType,
        chain,
        memo,
        isInner,
        remark,
        feeDeductType
      )
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.character(toAddress) || !nzchar(toAddress)) {
        rlang::abort("Parameter 'toAddress' must be a non-empty string.")
      }
      if (!is.character(amount) || !nzchar(amount)) {
        rlang::abort("Parameter 'amount' must be a non-empty string.")
      }
      valid_types <- c("ADDRESS", "UID", "MAIL", "PHONE")
      if (!is.character(withdrawType) || !(withdrawType %in% valid_types)) {
        rlang::abort(paste0(
          "Parameter 'withdrawType' must be one of: ",
          paste(valid_types, collapse = ", "),
          "."
        ))
      }

      if (is.null(chain)) {
        rlang::abort("Parameter 'chain' is required by the KuCoin API.")
      }

      body <- list(
        currency = currency,
        toAddress = toAddress,
        amount = amount,
        withdrawType = withdrawType
      )
      if (!is.null(chain)) {
        body$chain <- chain
      }
      if (!is.null(memo)) {
        body$memo <- memo
      }
      if (!is.null(isInner)) {
        body$isInner <- isInner
      }
      if (!is.null(remark)) {
        body$remark <- remark
      }
      if (!is.null(feeDeductType)) {
        body$feeDeductType <- feeDeductType
      }

      res <- private$.request(
        endpoint = "/api/v3/withdrawals",
        method = "POST",
        body = body,
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinWithdrawal__add_withdrawal,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Cancel Withdrawal
    #'
    #' Cancels a pending withdrawal request. Only withdrawals with `PROCESSING`
    #' status can be cancelled. Once a withdrawal has moved to `WALLET_PROCESSING`
    #' or later, it cannot be reversed.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated DELETE to the withdrawal-specific endpoint.
    #' 2. **Response**: KuCoin returns `NULL` data on success.
    #' 3. **Parsing**: Returns a `data.table` with the cancelled withdrawal ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v1/withdrawals/{withdrawalId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Cancel Withdrawal](https://www.kucoin.com/docs-new/rest/account-info/withdrawals/cancel-withdrawal)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Error Recovery**: Cancel a withdrawal if the destination address was incorrect.
    #' - **Strategy Change**: Cancel pending withdrawals if market conditions change and funds are needed for trading.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE \
    #'   'https://api.kucoin.com/api/v1/withdrawals/670deec84d64da0007d7c946' \
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
    #'   "data": null
    #' }
    #' ```
    #'
    #' @param withdrawalId (scalar<character>) the unique withdrawal ID to
    #'   cancel.
    #' @return (data.table | promise<data.table>) one row, the cancelled
    #'   withdrawal ID echoed from the input (KuCoin returns `null` data on a
    #'   successful cancel):
    #' - withdrawal_id (character) the cancelled withdrawal ID.
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- KucoinWithdrawal$new()
    #'
    #' # Cancel a pending withdrawal
    #' result <- withdrawal$cancel_withdrawal("670deec84d64da0007d7c946")
    #' print(result$withdrawal_id)
    #' }
    cancel_withdrawal = function(withdrawalId) {
      assert_args_KucoinWithdrawal__cancel_withdrawal(withdrawalId)
      if (!is.character(withdrawalId) || !nzchar(withdrawalId)) {
        rlang::abort("Parameter 'withdrawalId' must be a non-empty string.")
      }

      res <- private$.request(
        endpoint = paste0("/api/v1/withdrawals/", withdrawalId),
        method = "DELETE",
        .parser = function(data) {
          return(data.table::data.table(withdrawal_id = withdrawalId)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinWithdrawal__cancel_withdrawal,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Withdrawal Quotas
    #'
    #' Retrieves withdrawal limits, minimum fees, and available balances for a
    #' currency. Essential for pre-flight checks before initiating withdrawals
    #' to ensure sufficient balance and valid amount parameters.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `currency` (required) and optional `chain` query parameters.
    #' 2. **Parsing**: Returns a `data.table` with quota details, limits, and fee information.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/withdrawals/quotas`
    #'
    #' ### Official Documentation
    #' KuCoin Get Withdrawal Quotas:
    #' <https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-quotas>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Pre-Flight Check**: Verify `is_withdraw_enabled` and `available_amount` before attempting a withdrawal.
    #' - **Fee Estimation**: Use `withdraw_min_fee` and `inner_withdraw_min_fee` for cost calculations.
    #' - **Amount Validation**: Check `withdraw_min_size` and `precision` to format withdrawal amounts correctly.
    #' - **Limit Awareness**: Monitor `remain_amount` against `limit_btc_amount` to stay within daily limits.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/withdrawals/quotas?currency=BTC' \
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
    #'     "currency": "BTC",
    #'     "limitBTCAmount": "15.79590095",
    #'     "usedBTCAmount": "0.00000000",
    #'     "quotaCurrency": "USDT",
    #'     "limitQuotaCurrencyAmount": "999999.00000000",
    #'     "usedQuotaCurrencyAmount": "0",
    #'     "remainAmount": "15.79590095",
    #'     "availableAmount": "0",
    #'     "withdrawMinFee": "0.0005",
    #'     "innerWithdrawMinFee": "0",
    #'     "withdrawMinSize": "0.001",
    #'     "isWithdrawEnabled": true,
    #'     "precision": 8,
    #'     "chain": "BTC",
    #'     "reason": null,
    #'     "lockedAmount": "0"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) currency code (e.g., `"BTC"`,
    #'   `"USDT"`).
    #' @param chain (scalar<character> | NULL) blockchain network identifier
    #'   (e.g., `"eth"`, `"trx"`). When NULL, returns quotas for the default
    #'   chain.
    #' @return (data.table | promise<data.table>) one row with the withdrawal
    #'   quota details (currency, limit_btc_amount, used_btc_amount,
    #'   quota_currency, limit_quota_currency_amount, used_quota_currency_amount,
    #'   remain_amount, available_amount, withdraw_min_fee, inner_withdraw_min_fee,
    #'   withdraw_min_size, is_withdraw_enabled, precision, chain, reason,
    #'   locked_amount, ...).
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- KucoinWithdrawal$new()
    #'
    #' # Check BTC withdrawal quotas
    #' quotas <- withdrawal$get_withdrawal_quotas(currency = "BTC")
    #' print(quotas[, .(currency, available_amount, withdraw_min_fee, is_withdraw_enabled)])
    #'
    #' # Check USDT quotas on TRC20
    #' usdt_quotas <- withdrawal$get_withdrawal_quotas(currency = "USDT", chain = "trx")
    #' print(usdt_quotas$withdraw_min_fee)
    #' }
    get_withdrawal_quotas = function(currency, chain = NULL) {
      assert_args_KucoinWithdrawal__get_withdrawal_quotas(currency, chain)
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }

      res <- private$.request(
        endpoint = "/api/v1/withdrawals/quotas",
        query = list(currency = currency, chain = chain),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          expected <- c(
            "currency",
            "chain",
            "is_withdraw_enabled",
            "available_amount",
            "remain_amount",
            "withdraw_min_fee",
            "inner_withdraw_min_fee",
            "withdraw_min_size",
            "precision",
            "limit_btc_amount",
            "used_btc_amount",
            "locked_amount"
          )
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinWithdrawal__get_withdrawal_quotas,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Withdrawal History
    #'
    #' Retrieves paginated withdrawal history with optional filtering by currency,
    #' status, and time range. Automatically converts `created_at` timestamps
    #' to POSIXct for convenient analysis.
    #'
    #' ### Workflow
    #' 1. **Pagination**: Uses `private$.paginate()` to fetch all pages of withdrawal records up to `max_pages`.
    #' 2. **Flattening**: Combines all pages into a single `data.table` via `flatten_pages()`.
    #' 3. **Timestamp Conversion**: Coerces `created_at` (milliseconds) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/withdrawals`
    #'
    #' ### Official Documentation
    #' KuCoin Get Withdrawal History:
    #' <https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-history>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Withdrawal Monitoring**: Poll for `"SUCCESS"` status to confirm funds have left the exchange.
    #' - **Reconciliation**: Match `wallet_tx_id` against on-chain transaction hashes for audit.
    #' - **Time-Windowed Queries**: Use `startAt`/`endAt` timestamps to retrieve withdrawals within a specific period.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/withdrawals?currency=USDT&status=SUCCESS&currentPage=1&pageSize=50' \
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
    #'     "totalNum": 1,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "currency": "USDT",
    #'         "chain": "",
    #'         "status": "SUCCESS",
    #'         "address": "a435*****@gmail.com",
    #'         "memo": "",
    #'         "isInner": true,
    #'         "amount": "1.00000000",
    #'         "fee": "0.00000000",
    #'         "walletTxId": null,
    #'         "createdAt": 1728555875000,
    #'         "updatedAt": 1728555875000,
    #'         "remark": "",
    #'         "arrears": false
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character> | NULL) currency code (e.g., `"BTC"`,
    #'   `"USDT"`). If NULL, returns withdrawals for all currencies.
    #' @param status (scalar<character> | NULL) filter by withdrawal status.
    #'   Accepted values: `"PROCESSING"`, `"REVIEW"`, `"WALLET_PROCESSING"`,
    #'   `"SUCCESS"`, `"FAILURE"`. When NULL, returns withdrawals of all statuses.
    #' @param startAt (scalar<numeric> | NULL) start timestamp in milliseconds
    #'   (inclusive).
    #' @param endAt (scalar<numeric> | NULL) end timestamp in milliseconds
    #'   (inclusive).
    #' @param page_size (scalar<count in [1, Inf[>) number of results per page
    #'   (default 50, max 500).
    #' @param max_pages (scalar<numeric in [1, Inf]>) maximum number of pages to
    #'   fetch (default `Inf` for all pages).
    #' @return (data.table | promise<data.table>) one row per withdrawal record
    #'   (currency, chain, status, address, memo, is_inner, amount, fee,
    #'   wallet_tx_id, created_at, updated_at, remark, arrears, ...), with
    #'   `created_at`/`updated_at` coerced to POSIXct, or an empty `data.table`
    #'   if no withdrawals match the filters.
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- KucoinWithdrawal$new()
    #'
    #' # Get all successful USDT withdrawals
    #' history <- withdrawal$get_withdrawal_history(
    #'   currency = "USDT",
    #'   status = "SUCCESS"
    #' )
    #' print(history[, .(amount, status, created_at)])
    #'
    #' # Get withdrawals from the last 24 hours
    #' now_ms <- as.integer(as.numeric(lubridate::now()) * 1000)
    #' recent <- withdrawal$get_withdrawal_history(
    #'   currency = "BTC",
    #'   startAt = now_ms - 86400000L,
    #'   endAt = now_ms
    #' )
    #' }
    get_withdrawal_history = function(
      currency = NULL,
      status = NULL,
      startAt = NULL,
      endAt = NULL,
      page_size = 50,
      max_pages = Inf
    ) {
      assert_args_KucoinWithdrawal__get_withdrawal_history(
        currency,
        status,
        startAt,
        endAt,
        page_size,
        max_pages
      )
      if (!is.null(currency) && (!is.character(currency) || !nzchar(currency))) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }

      res <- private$.paginate(
        endpoint = "/api/v1/withdrawals",
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
                "remark",
                "arrears"
              ),
              names(dt)
            )
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinWithdrawal__get_withdrawal_history,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Withdrawal by ID
    #'
    #' Retrieves comprehensive details for a specific withdrawal, including
    #' chain information, failure reasons, cancel status, and return details.
    #' Provides more information than the history endpoint.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the withdrawal-specific endpoint.
    #' 2. **Response**: KuCoin returns detailed withdrawal information.
    #' 3. **Parsing**: Returns `data.table` with full withdrawal details.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/withdrawals/{withdrawalId}`
    #'
    #' ### Official Documentation
    #' KuCoin Get Withdrawal Detail:
    #' <https://www.kucoin.com/docs-new/rest/account-info/withdrawals/get-withdrawal-by-id>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Status Tracking**: Monitor withdrawal progress through `REVIEW` → `PROCESSING` → `WALLET_PROCESSING` →
    #'   `SUCCESS`.
    #' - **Failure Diagnosis**: Check `failure_reason` and `failure_reason_msg` to understand why a withdrawal failed.
    #' - **Cancel Eligibility**: Use `cancel_type` (`"CANCELABLE"`, `"CANCELING"`, `"NON_CANCELABLE"`) to determine if a
    #'   withdrawal can still be cancelled.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/withdrawals/670deec84d64da0007d7c946' \
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
    #'     "id": "67e6515f7960ba0007b42025",
    #'     "currency": "USDT",
    #'     "chainId": "trx",
    #'     "chainName": "TRC20",
    #'     "status": "SUCCESS",
    #'     "address": "TKFRQXSDcY4kd3QLzw7uK16GmLrjJggwX8",
    #'     "memo": "",
    #'     "isInner": true,
    #'     "amount": "3.00000000",
    #'     "fee": "0.00000000",
    #'     "walletTxId": null,
    #'     "createdAt": 1743147359000,
    #'     "cancelType": "NON_CANCELABLE"
    #'   }
    #' }
    #' ```
    #'
    #' @param withdrawalId (scalar<character>) the unique withdrawal ID.
    #' @return (data.table | promise<data.table>) one row with the full
    #'   withdrawal detail (id, currency, chain_id, chain_name, status, address,
    #'   memo, is_inner, amount, fee, wallet_tx_id, cancel_type, failure_reason,
    #'   failure_reason_msg, created_at, ...), with `created_at` coerced to
    #'   POSIXct.
    #'
    #' @examples
    #' \dontrun{
    #' withdrawal <- KucoinWithdrawal$new()
    #'
    #' # Get withdrawal details
    #' detail <- withdrawal$get_withdrawal_by_id("670deec84d64da0007d7c946")
    #' print(detail[, .(id, currency, status, amount, cancel_type)])
    #'
    #' # Check if a withdrawal can be cancelled
    #' if (detail$cancel_type == "CANCELABLE") {
    #'   withdrawal$cancel_withdrawal(detail$id)
    #' }
    #' }
    get_withdrawal_by_id = function(withdrawalId) {
      assert_args_KucoinWithdrawal__get_withdrawal_by_id(withdrawalId)
      if (!is.character(withdrawalId) || !nzchar(withdrawalId)) {
        rlang::abort("Parameter 'withdrawalId' must be a non-empty string.")
      }

      res <- private$.request(
        endpoint = paste0("/api/v1/withdrawals/", withdrawalId),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          expected <- c(
            "id",
            "currency",
            "chain_id",
            "chain_name",
            "status",
            "address",
            "memo",
            "is_inner",
            "amount",
            "fee",
            "wallet_tx_id",
            "created_at",
            "cancel_type"
          )
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinWithdrawal__get_withdrawal_by_id,
        is_async = private$.is_async
      ))
    }
  )
)
