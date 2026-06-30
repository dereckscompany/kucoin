# File: R/KucoinLending.R
# R6 class for KuCoin margin lending (credit) operations.

#' KucoinLending: Margin Lending Operations
#'
#' Provides methods for lending assets on the KuCoin margin lending market,
#' managing purchase (lend) orders, and redeeming lent assets. Inherits from
#' [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Loan Market Data**: Query available lending currencies and historical interest rates.
#' - **Purchase (Lend)**: Lend assets to the margin pool to earn interest.
#' - **Modify**: Update interest rate on existing lending orders.
#' - **Redeem**: Withdraw lent assets from the lending pool.
#' - **Order Queries**: Retrieve purchase and redemption order history.
#'
#' ### Usage
#' All methods except `get_loan_market_rate()`
#' require authentication with Margin permission.
#'
#' ### Official Documentation
#' [KuCoin Lending Market](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-loan-market)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_loan_market | GET /api/v3/project/list | GET |
#' | get_loan_market_rate | GET /api/v3/project/marketInterestRate | GET |
#' | purchase | POST /api/v3/purchase | POST |
#' | modify_purchase | POST /api/v3/lend/purchase/update | POST |
#' | get_purchase_orders | GET /api/v3/purchase/orders | GET |
#' | redeem | POST /api/v3/redeem | POST |
#' | get_redeem_orders | GET /api/v3/redeem/orders | GET |
#'
#' @examples
#' \dontrun{
#' lending <- KucoinLending$new()
#'
#' # Check available lending currencies
#' market <- lending$get_loan_market()
#' print(market)
#'
#' # Lend USDT at a specified interest rate
#' order <- lending$purchase(currency = "USDT", size = 1000, interestRate = 0.05)
#' print(order)
#'
#' # Redeem lent USDT
#' result <- lending$redeem(currency = "USDT", size = 1000,
#'                          purchaseOrderNo = order$order_no)
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinLending <- R6::R6Class(
  "KucoinLending",
  inherit = KucoinBase,
  public = list(
    # ---- Market Data ----

    #' @description
    #' Get Loan Market Information
    #'
    #' Retrieves information about available lending currencies, including
    #' minimum/maximum purchase sizes and current market interest rates.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/project/list`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Currency Information](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-loan-market)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/project/list?currency=USDT' \
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
    #'       "currency": "USDT",
    #'       "purchaseEnable": true,
    #'       "redeemEnable": true,
    #'       "increment": "0.01",
    #'       "minPurchaseSize": "10",
    #'       "maxPurchaseSize": "1000000",
    #'       "interestIncrement": "0.0001",
    #'       "minInterestRate": "0.004",
    #'       "marketInterestRate": "0.05",
    #'       "maxInterestRate": "0.1",
    #'       "autoPurchaseEnable": true
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param query (list) optional filter; supported key `currency`
    #'   (scalar<character>) filters by currency (e.g., `"USDT"`).
    #' @return (data.table | promise<data.table>) one row per lending currency
    #'   with currency code, purchase/redeem enablement flags, size increments and
    #'   bounds, and the minimum, market, and maximum interest rates; an empty
    #'   response yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' market <- lending$get_loan_market(query = list(currency = "USDT"))
    #' print(market)
    #' }
    get_loan_market = function(query = list()) {
      assert_args_KucoinLending__get_loan_market(query)
      res <- private$.request(
        endpoint = "/api/v3/project/list",
        query = query,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__get_loan_market,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Loan Market Interest Rate History
    #'
    #' Retrieves the market interest rate history for a currency over the
    #' past 7 days.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/project/marketInterestRate`
    #'
    #' ### Official Documentation
    #' KuCoin Get Market Interest Rate:
    #' <https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-loan-market-interest-rate>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/project/marketInterestRate?currency=USDT' \
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
    #'       "time": "202603070000",
    #'       "marketInterestRate": "0.05"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) the currency to query (e.g., `"USDT"`).
    #' @return (data.table | promise<data.table>) one row per observation with the
    #'   timestamp string (YYYYMMDDHHmm format) and the market interest rate at that
    #'   time; an empty response yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' rates <- lending$get_loan_market_rate(currency = "USDT")
    #' print(rates)
    #' }
    get_loan_market_rate = function(currency) {
      assert_args_KucoinLending__get_loan_market_rate(currency)
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }

      res <- private$.request(
        endpoint = "/api/v3/project/marketInterestRate",
        query = list(currency = currency),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__get_loan_market_rate,
        is_async = private$.is_async
      ))
    },

    # ---- Lending Operations ----

    #' @description
    #' Purchase (Lend) Assets
    #'
    #' Lends a specified amount of currency to the margin lending pool at a
    #' given interest rate to earn passive income.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/purchase`
    #'
    #' ### Official Documentation
    #' [KuCoin Purchase](https://www.kucoin.com/docs-new/rest/margin-trading/credit/purchase)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/purchase' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"currency":"USDT","size":"1000","interestRate":"0.05"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "currency": "USDT",
    #'   "size": "1000",
    #'   "interestRate": "0.05"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderNo": "abc123"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) the currency to lend (e.g., `"USDT"`).
    #' @param size (scalar<numeric>) the amount to lend.
    #' @param interestRate (scalar<numeric>) the interest rate (e.g., `0.05` for
    #'   5%).
    #' @return (data.table | promise<data.table>) one row with the lending order
    #'   number:
    #' - order_no (character) the order number.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' order <- lending$purchase(currency = "USDT", size = 1000, interestRate = 0.05)
    #' print(order$order_no)
    #' }
    purchase = function(currency, size, interestRate) {
      assert_args_KucoinLending__purchase(currency, size, interestRate)
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.numeric(size) || size <= 0) {
        rlang::abort("Parameter 'size' must be a positive number.")
      }
      if (!is.numeric(interestRate) || interestRate <= 0) {
        rlang::abort("Parameter 'interestRate' must be a positive number.")
      }

      body <- list(
        currency = currency,
        size = as.character(size),
        interestRate = as.character(interestRate)
      )

      res <- private$.request(
        endpoint = "/api/v3/purchase",
        method = "POST",
        body = body,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(empty_dt_order_no())
          }
          return(as_dt_row(data))
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__purchase,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Modify Purchase Interest Rate
    #'
    #' Updates the interest rate on an existing lending order. Rate changes
    #' take effect at the start of the next hour.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/lend/purchase/update`
    #'
    #' ### Official Documentation
    #' [KuCoin Modify Purchase](https://www.kucoin.com/docs-new/rest/margin-trading/credit/modify-purchase)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/lend/purchase/update' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"currency":"USDT","purchaseOrderNo":"abc123","interestRate":"0.06"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "currency": "USDT",
    #'   "purchaseOrderNo": "abc123",
    #'   "interestRate": "0.06"
    #' }
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
    #' @param currency (scalar<character>) the currency of the lending order.
    #' @param purchaseOrderNo (scalar<character>) the order number to modify.
    #' @param interestRate (scalar<numeric>) the new interest rate.
    #' @return (data.table | promise<data.table>) one row echoing the request:
    #' - currency (character) the lending currency.
    #' - purchase_order_no (character) the modified order number.
    #' - interest_rate (numeric | NA) the new interest rate.
    #' - status (character) the local outcome marker, always `"success"`:
    #' - currency (character) the currency code.
    #' - purchase_order_no (character) the purchase order no.
    #' - interest_rate (numeric | NA) the interest rate.
    #' - status (character) the status.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' lending$modify_purchase(
    #'   currency = "USDT",
    #'   purchaseOrderNo = "abc123",
    #'   interestRate = 0.06
    #' )
    #' }
    modify_purchase = function(currency, purchaseOrderNo, interestRate) {
      assert_args_KucoinLending__modify_purchase(currency, purchaseOrderNo, interestRate)
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.character(purchaseOrderNo) || !nzchar(purchaseOrderNo)) {
        rlang::abort("Parameter 'purchaseOrderNo' must be a non-empty string.")
      }
      if (!is.numeric(interestRate) || interestRate <= 0) {
        rlang::abort("Parameter 'interestRate' must be a positive number.")
      }

      body <- list(
        currency = currency,
        purchaseOrderNo = purchaseOrderNo,
        interestRate = as.character(interestRate)
      )

      res <- private$.request(
        endpoint = "/api/v3/lend/purchase/update",
        method = "POST",
        body = body,
        .parser = function(data) {
          return(data.table::data.table(
            currency = currency,
            purchase_order_no = purchaseOrderNo,
            interest_rate = interestRate,
            status = "success"
          )[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__modify_purchase,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Purchase Orders
    #'
    #' Retrieves lending purchase order history with optional filters.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/purchase/orders`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Purchase Orders](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-purchase-orders)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/purchase/orders?currency=USDT&status=DONE&currentPage=1&pageSize=50' \
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
    #'         "purchaseOrderNo": "abc123",
    #'         "purchaseSize": "1000",
    #'         "matchSize": "800",
    #'         "interestRate": "0.05",
    #'         "incomeSize": "3.42",
    #'         "applyTime": 1729655606816,
    #'         "status": "DONE"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query (list) filters; supported keys `status` (required, e.g.
    #'   `"DONE"`, `"PENDING"`), `currency`, `purchaseOrderNo`, `currentPage`, and
    #'   `pageSize`.
    #' @return (data.table | promise<data.table>) one row per purchase order with
    #'   the currency, purchase order number, amount lent, matched amount, interest
    #'   rate, accrued income, order creation time, and status; an empty response
    #'   yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' orders <- lending$get_purchase_orders(query = list(currency = "USDT", status = "DONE"))
    #' print(orders)
    #' }
    get_purchase_orders = function(query = list()) {
      assert_args_KucoinLending__get_purchase_orders(query)
      res <- private$.request(
        endpoint = "/api/v3/purchase/orders",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
          if ("apply_time" %in% names(dt)) {
            dt[, apply_time := ms_to_datetime(apply_time)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c(
                "currency",
                "purchase_order_no",
                "purchase_size",
                "match_size",
                "interest_rate",
                "income_size",
                "apply_time",
                "status"
              ),
              names(dt)
            )
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__get_purchase_orders,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Redeem Lent Assets
    #'
    #' Redeems (withdraws) lent assets from the lending pool. The redemption
    #' is processed against a specific purchase order.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/redeem`
    #'
    #' ### Official Documentation
    #' [KuCoin Redeem](https://www.kucoin.com/docs-new/rest/margin-trading/credit/redeem)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/redeem' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"currency":"USDT","size":"500","purchaseOrderNo":"abc123"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "currency": "USDT",
    #'   "size": "500",
    #'   "purchaseOrderNo": "abc123"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderNo": "abc123"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) the currency to redeem (e.g., `"USDT"`).
    #' @param size (scalar<numeric>) the amount to redeem.
    #' @param purchaseOrderNo (scalar<character>) the purchase order to redeem
    #'   from.
    #' @return (data.table | promise<data.table>) one row with the redemption order
    #'   number:
    #' - order_no (character) the order number.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' result <- lending$redeem(
    #'   currency = "USDT", size = 500, purchaseOrderNo = "abc123"
    #' )
    #' print(result$order_no)
    #' }
    redeem = function(currency, size, purchaseOrderNo) {
      assert_args_KucoinLending__redeem(currency, size, purchaseOrderNo)
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.numeric(size) || size <= 0) {
        rlang::abort("Parameter 'size' must be a positive number.")
      }
      if (!is.character(purchaseOrderNo) || !nzchar(purchaseOrderNo)) {
        rlang::abort("Parameter 'purchaseOrderNo' must be a non-empty string.")
      }

      body <- list(
        currency = currency,
        size = as.character(size),
        purchaseOrderNo = purchaseOrderNo
      )

      res <- private$.request(
        endpoint = "/api/v3/redeem",
        method = "POST",
        body = body,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(empty_dt_order_no())
          }
          return(as_dt_row(data))
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__redeem,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Redeem Orders
    #'
    #' Retrieves redemption order history with optional filters.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/redeem/orders`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Redeem Orders](https://www.kucoin.com/docs-new/rest/margin-trading/credit/get-redeem-orders)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/redeem/orders?currency=USDT&status=DONE&currentPage=1&pageSize=50' \
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
    #'         "purchaseOrderNo": "abc123",
    #'         "redeemOrderNo": "def456",
    #'         "redeemSize": "500",
    #'         "receiptSize": "500",
    #'         "applyTime": 1729655606816,
    #'         "status": "DONE"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query (list) filters; supported keys `status` (required, e.g.
    #'   `"DONE"`, `"PENDING"`), `currency`, `redeemOrderNo`, `currentPage`, and
    #'   `pageSize`.
    #' @return (data.table | promise<data.table>) one row per redemption order with
    #'   the currency, source purchase order, redemption order number, requested
    #'   redeem amount, amount actually received, order creation time, and status;
    #'   an empty response yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' lending <- KucoinLending$new()
    #' orders <- lending$get_redeem_orders(query = list(currency = "USDT", status = "DONE"))
    #' print(orders)
    #' }
    get_redeem_orders = function(query = list()) {
      assert_args_KucoinLending__get_redeem_orders(query)
      res <- private$.request(
        endpoint = "/api/v3/redeem/orders",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
          if ("apply_time" %in% names(dt)) {
            dt[, apply_time := ms_to_datetime(apply_time)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c(
                "currency",
                "purchase_order_no",
                "redeem_order_no",
                "redeem_size",
                "receipt_size",
                "apply_time",
                "status"
              ),
              names(dt)
            )
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinLending__get_redeem_orders,
        is_async = private$.is_async
      ))
    }
  )
)
