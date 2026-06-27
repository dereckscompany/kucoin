# File: R/KucoinTransfer.R
# R6 class for KuCoin internal transfer operations.

#' KucoinTransfer: Internal Transfer Management
#'
#' Provides methods for transferring funds between KuCoin accounts (main, trade,
#' margin, etc.) and between master and sub-accounts. Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Fund Movement**: Transfer funds between account types (e.g., main → trade) so that
#'   deposited funds can be used for HF spot trading.
#' - **Sub-Account Funding**: Move funds between master and sub-accounts.
#' - **Balance Queries**: Check how much of a currency is available for transfer from a specific account type.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase).
#' The API key must have **FlexTransfers** (universal transfer) permission for
#' `add_transfer()`. The `get_transferable()` method requires only **General** permission.
#'
#' ```r
#' # Synchronous usage
#' transfer <- KucoinTransfer$new()
#' balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
#'
#' # Asynchronous usage
#' transfer_async <- KucoinTransfer$new(async = TRUE)
#' coro::async(function() {
#'   balance <- await(transfer_async$get_transferable(currency = "USDT", type = "MAIN"))
#'   print(balance)
#' })()
#' ```
#'
#' ### Official Documentation
#' [KuCoin Transfer Endpoints](https://www.kucoin.com/docs-new/rest/account-info/transfer/flex-transfer)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_transfer | POST /api/v3/accounts/universal-transfer | POST |
#' | get_transferable | GET /api/v1/accounts/transferable | GET |
#'
#' @section Account Types:
#' KuCoin uses separate accounts for different purposes:
#' - `"MAIN"`: Funding account — deposits land here by default.
#' - `"TRADE"`: Spot trading account — required for HF orders.
#' - `"MARGIN"`: Cross-margin account.
#' - `"ISOLATED"`: Isolated-margin account (requires `fromAccountTag`/`toAccountTag` for symbol).
#' - `"CONTRACT"`: Futures account.
#'
#' @section Transfer Types:
#' - `"INTERNAL"`: Between your own accounts (e.g., MAIN → TRADE).
#' - `"PARENT_TO_SUB"`: From master to sub-account.
#' - `"SUB_TO_PARENT"`: From sub-account to master.
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' transfer <- KucoinTransfer$new()
#' balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
#' print(balance)
#'
#' # Asynchronous
#' transfer_async <- KucoinTransfer$new(async = TRUE)
#' main <- coro::async(function() {
#'   balance <- await(transfer_async$get_transferable(currency = "USDT", type = "MAIN"))
#'   print(balance)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinTransfer <- R6::R6Class(
  "KucoinTransfer",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Add Transfer (Universal)
    #'
    #' Transfers funds between account types within your own KuCoin account, or
    #' between master and sub-accounts. This is essential for trading bots because
    #' deposits land in the **main** account, but HF spot orders require funds in
    #' the **trade** account.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with required transfer parameters.
    #' 2. **Request**: Authenticated POST to the universal transfer endpoint.
    #' 3. **Parsing**: Returns `data.table` with the transfer order ID.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/accounts/universal-transfer`
    #'
    #' ### Official Documentation
    #' [KuCoin Flex Transfer](https://www.kucoin.com/docs-new/rest/account-info/transfer/flex-transfer)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Bot Startup**: Transfer deposited funds from MAIN to TRADE before placing orders.
    #' - **Profit Harvesting**: Move profits from TRADE to MAIN before withdrawing.
    #' - **Sub-Account Funding**: Distribute funds to sub-accounts running independent strategies.
    #' - **Idempotency**: Use `clientOid` (UUID) to prevent duplicate transfers on retry.
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/accounts/universal-transfer' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"clientOid":"64ccc0f164781800010d8c09","currency":"USDT","amount":"10","type":"INTERNAL","fromAccountType":"MAIN","toAccountType":"TRADE"}'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "6705f7248c6954000733ecac"
    #'   }
    #' }
    #' ```
    #'
    #' @param clientOid (scalar<character>) unique client order ID for
    #'   idempotency (max 128 bits, e.g., UUID).
    #' @param currency (scalar<character>) currency code (e.g., `"BTC"`,
    #'   `"USDT"`).
    #' @param amount (scalar<character>) transfer amount (positive, multiple of
    #'   currency precision).
    #' @param type (scalar<character>) transfer type: `"INTERNAL"`,
    #'   `"PARENT_TO_SUB"`, or `"SUB_TO_PARENT"`.
    #' @param fromAccountType (scalar<character>) source account type: `"MAIN"`,
    #'   `"TRADE"`, `"CONTRACT"`, `"MARGIN"`, `"ISOLATED"`, `"MARGIN_V2"`,
    #'   `"ISOLATED_V2"`.
    #' @param toAccountType (scalar<character>) destination account type (same
    #'   options as `fromAccountType`).
    #' @param fromUserId (scalar<character> | NULL) source user ID (required for
    #'   `"SUB_TO_PARENT"` transfers).
    #' @param fromAccountTag (scalar<character> | NULL) symbol for
    #'   ISOLATED/ISOLATED_V2 source accounts (e.g., `"BTC-USDT"`).
    #' @param toUserId (scalar<character> | NULL) destination user ID (required
    #'   for `"PARENT_TO_SUB"` transfers).
    #' @param toAccountTag (scalar<character> | NULL) symbol for
    #'   ISOLATED/ISOLATED_V2 destination accounts (e.g., `"BTC-USDT"`).
    #' @return (data.table | promise<data.table>) one row with column `order_id`
    #'   (character): the transfer order identifier.
    #'
    #' @examples
    #' \dontrun{
    #' transfer <- KucoinTransfer$new()
    #'
    #' # Move USDT from main to trade account for spot trading
    #' result <- transfer$add_transfer(
    #'   clientOid = "64ccc0f164781800010d8c09",
    #'   currency = "USDT",
    #'   amount = "100",
    #'   type = "INTERNAL",
    #'   fromAccountType = "MAIN",
    #'   toAccountType = "TRADE"
    #' )
    #' print(result$order_id)
    #'
    #' # Transfer BTC from master to sub-account
    #' result <- transfer$add_transfer(
    #'   clientOid = "unique-uuid-here",
    #'   currency = "BTC",
    #'   amount = "0.01",
    #'   type = "PARENT_TO_SUB",
    #'   fromAccountType = "MAIN",
    #'   toAccountType = "MAIN",
    #'   toUserId = "sub-user-id-here"
    #' )
    #' }
    add_transfer = function(
      clientOid,
      currency,
      amount,
      type,
      fromAccountType,
      toAccountType,
      fromUserId = NULL,
      fromAccountTag = NULL,
      toUserId = NULL,
      toAccountTag = NULL
    ) {
      assert_args_KucoinTransfer__add_transfer(
        clientOid,
        currency,
        amount,
        type,
        fromAccountType,
        toAccountType,
        fromUserId,
        fromAccountTag,
        toUserId,
        toAccountTag
      )
      if (!is.character(clientOid) || !nzchar(clientOid)) {
        rlang::abort("Parameter 'clientOid' must be a non-empty string.")
      }
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.character(amount) || !nzchar(amount)) {
        rlang::abort("Parameter 'amount' must be a non-empty string.")
      }
      valid_types <- c("INTERNAL", "PARENT_TO_SUB", "SUB_TO_PARENT")
      if (!is.character(type) || !(type %in% valid_types)) {
        rlang::abort(paste0(
          "Parameter 'type' must be one of: ",
          paste(valid_types, collapse = ", "),
          "."
        ))
      }
      valid_accounts <- c("MAIN", "TRADE", "CONTRACT", "MARGIN", "ISOLATED", "MARGIN_V2", "ISOLATED_V2")
      if (!is.character(fromAccountType) || !(fromAccountType %in% valid_accounts)) {
        rlang::abort(paste0(
          "Parameter 'fromAccountType' must be one of: ",
          paste(valid_accounts, collapse = ", "),
          "."
        ))
      }
      if (!is.character(toAccountType) || !(toAccountType %in% valid_accounts)) {
        rlang::abort(paste0(
          "Parameter 'toAccountType' must be one of: ",
          paste(valid_accounts, collapse = ", "),
          "."
        ))
      }

      body <- list(
        clientOid = clientOid,
        currency = currency,
        amount = amount,
        type = type,
        fromAccountType = fromAccountType,
        toAccountType = toAccountType
      )
      if (!is.null(fromUserId)) {
        body$fromUserId <- fromUserId
      }
      if (!is.null(fromAccountTag)) {
        body$fromAccountTag <- fromAccountTag
      }
      if (!is.null(toUserId)) {
        body$toUserId <- toUserId
      }
      if (!is.null(toAccountTag)) {
        body$toAccountTag <- toAccountTag
      }

      res <- private$.request(
        endpoint = "/api/v3/accounts/universal-transfer",
        method = "POST",
        body = body,
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinTransfer__add_transfer,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Transferable Balance
    #'
    #' Retrieves the amount of a currency that is available for transfer out of a
    #' specific account type. Use this before calling `add_transfer()` to verify
    #' sufficient funds are available.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `currency` and `type` (required) and optional `tag` query parameters.
    #' 2. **Parsing**: Returns a `data.table` with balance breakdown.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/accounts/transferable`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Transfer Quotas](https://www.kucoin.com/docs-new/rest/account-info/transfer/get-transfer-quotas)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Pre-Flight Check**: Verify `transferable` amount before initiating a transfer.
    #' - **Balance Awareness**: Monitor `holds` to understand how much is locked in open orders.
    #' - **Fund Routing**: Check transferable amounts across account types to optimise fund allocation.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/accounts/transferable?currency=USDT&type=MAIN' \
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
    #'     "balance": "10.5",
    #'     "available": "10.5",
    #'     "holds": "0",
    #'     "transferable": "10.5"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) currency code (e.g., `"BTC"`,
    #'   `"USDT"`).
    #' @param type (scalar<character>) account type: `"MAIN"`, `"TRADE"`,
    #'   `"MARGIN"`, `"ISOLATED"`, `"MARGIN_V2"`, `"ISOLATED_V2"`.
    #' @param tag (scalar<character> | NULL) trading pair symbol required for
    #'   `"ISOLATED"` account type (e.g., `"BTC-USDT"`).
    #' @return (data.table | promise<data.table>) one row with the balance
    #'   breakdown: `currency` (currency code), `balance` (total funds),
    #'   `available` (funds available to withdraw or trade), `holds` (funds
    #'   locked in open orders), and `transferable` (funds available for
    #'   transfer) -- all character.
    #'
    #' @examples
    #' \dontrun{
    #' transfer <- KucoinTransfer$new()
    #'
    #' # Check transferable USDT in main account
    #' balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
    #' print(balance[, .(currency, balance, transferable)])
    #'
    #' # Check transferable BTC in trade account
    #' trade_bal <- transfer$get_transferable(currency = "BTC", type = "TRADE")
    #' print(trade_bal$transferable)
    #' }
    get_transferable = function(currency, type, tag = NULL) {
      assert_args_KucoinTransfer__get_transferable(currency, type, tag)
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      valid_types <- c("MAIN", "TRADE", "MARGIN", "ISOLATED", "MARGIN_V2", "ISOLATED_V2")
      if (!is.character(type) || !(type %in% valid_types)) {
        rlang::abort(paste0(
          "Parameter 'type' must be one of: ",
          paste(valid_types, collapse = ", "),
          "."
        ))
      }

      res <- private$.request(
        endpoint = "/api/v1/accounts/transferable",
        query = list(currency = currency, type = type, tag = tag),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) == 0L) {
            return(dt[])
          }
          expected <- c("currency", "balance", "available", "holds", "transferable")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinTransfer__get_transferable,
        is_async = private$.is_async
      ))
    }
  )
)
