# File: R/KucoinOcoOrders.R
# R6 class for KuCoin OCO (One-Cancels-Other) order management.

#' KucoinOcoOrders: OCO Order Management
#'
#' Provides methods for managing OCO (One-Cancels-Other) orders on KuCoin Spot.
#' Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Order Placement**: Place OCO orders combining a limit order with a stop-limit order,
#'   where triggering one automatically cancels the other.
#' - **Order Cancellation**: Cancel OCO orders by order ID, client OID, or in batch.
#' - **Order Queries**: Retrieve OCO order summaries, detailed sub-order breakdowns,
#'   and paginated order lists with filtering.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase).
#' OCO orders are useful for setting simultaneous take-profit and stop-loss levels
#' on a position. When one side fills, the other is automatically cancelled.
#'
#' ```r
#' oco <- KucoinOcoOrders$new()
#'
#' # Place an OCO order: limit sell at 110k, stop-limit sell at 90k
#' order <- oco$add_order(
#'   symbol = "BTC-USDT", side = "sell",
#'   price = "110000", size = "0.0001",
#'   stopPrice = "90000", limitPrice = "89500"
#' )
#'
#' # List all OCO orders
#' orders <- oco$get_order_list()
#' ```
#'
#' ### Official Documentation
#' [KuCoin Spot OCO Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-oco-order)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_order | POST /api/v3/oco/order | POST |
#' | cancel_order_by_id | DELETE /api/v3/oco/order/\{orderId\} | DELETE |
#' | cancel_order_by_client_oid | DELETE /api/v3/oco/client-order/\{clientOid\} | DELETE |
#' | cancel_all | DELETE /api/v3/oco/orders | DELETE |
#' | get_order_by_id | GET /api/v3/oco/order/\{orderId\} | GET |
#' | get_order_by_client_oid | GET /api/v3/oco/client-order/\{clientOid\} | GET |
#' | get_order_detail_by_id | GET /api/v3/oco/order/details/\{orderId\} | GET |
#' | get_order_list | GET /api/v3/oco/orders | GET |
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' oco <- KucoinOcoOrders$new()
#' orders <- oco$get_order_list()
#' print(orders)
#'
#' # Asynchronous
#' oco_async <- KucoinOcoOrders$new(async = TRUE)
#' main <- coro::async(function() {
#'   orders <- await(oco_async$get_order_list())
#'   print(orders)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinOcoOrders <- R6::R6Class(
  "KucoinOcoOrders",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Place an OCO Order
    #'
    #' Places a new OCO (One-Cancels-Other) order on KuCoin Spot. An OCO order
    #' combines a limit order with a stop-limit order. When one side triggers or
    #' fills, the other side is automatically cancelled.
    #'
    #' ### Workflow
    #' 1. **Validation**: Verifies `symbol` format and matches `side` against allowed values.
    #' 2. **Body Construction**: Builds the request body with price, size, stop, and limit parameters.
    #' 3. **Request**: Authenticated POST to the OCO order endpoint.
    #' 4. **Parsing**: Returns `data.table` with the assigned `order_id`.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/oco/order`
    #'
    #' ### Official Documentation
    #' [KuCoin Add OCO Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-oco-order)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Take-Profit + Stop-Loss**: Place a sell OCO with `price` as take-profit and `stopPrice`/`limitPrice` as stop-loss to protect positions automatically.
    #' - **Bracket Entry**: Use a buy OCO to enter a position at a limit price while also setting a stop-entry above resistance.
    #' - **Client OID Tracking**: Set `clientOid` to a unique strategy identifier for programmatic order tracking and reconciliation.
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/oco/order' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"symbol":"BTC-USDT","side":"sell","price":"110000","size":"0.0001","stopPrice":"90000","limitPrice":"89500","tradeType":"TRADE"}'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "674c40d38b4b2f00073deef3"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair (e.g., `"BTC-USDT"`). Must match the
    #'   `BASE-QUOTE` format validated by `verify_symbol()`.
    #' @param side Character; order side, one of `"buy"` or `"sell"`.
    #' @param price Character; limit order price for the take-profit leg.
    #'   Must align with the symbol's `priceIncrement`.
    #' @param size Character; order quantity in base currency (e.g., `"0.0001"` BTC).
    #'   Must align with the symbol's `baseIncrement`.
    #' @param stopPrice Character; trigger price for the stop-limit leg. When the
    #'   market reaches this price, the stop-limit order is activated.
    #' @param limitPrice Character; limit price for the stop-limit leg after the
    #'   stop is triggered. This is the price at which the stop-limit order is placed.
    #' @param clientOid Character or NULL; unique client-assigned order identifier
    #'   (max 40 characters). Useful for idempotent order placement and tracking.
    #' @param remark Character or NULL; order remarks or notes (max 20 characters).
    #' @param tradeType Character; trade type, defaults to `"TRADE"` for spot trading.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned OCO order identifier.
    #'   - `client_oid` (character): Client-provided order identifier (NA if not supplied).
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Sell OCO: take-profit at 110k, stop-loss at 90k
    #' order <- oco$add_order(
    #'   symbol = "BTC-USDT", side = "sell",
    #'   price = "110000", size = "0.0001",
    #'   stopPrice = "90000", limitPrice = "89500"
    #' )
    #' print(order$order_id)
    #'
    #' # Buy OCO with client OID for tracking
    #' order <- oco$add_order(
    #'   symbol = "ETH-USDT", side = "buy",
    #'   price = "3000", size = "0.01",
    #'   stopPrice = "3500", limitPrice = "3550",
    #'   clientOid = "my-bot-oco-001"
    #' )
    #' }
    add_order = function(
      symbol,
      side,
      price,
      size,
      stopPrice,
      limitPrice,
      clientOid = NULL,
      remark = NULL,
      tradeType = "TRADE"
    ) {
      if (!verify_symbol(symbol)) {
        rlang::abort("Parameter 'symbol' must be a valid ticker.")
      }
      side <- rlang::arg_match0(side, c("buy", "sell"))

      body <- list(
        symbol = symbol,
        side = side,
        price = as.character(price),
        size = as.character(size),
        stopPrice = as.character(stopPrice),
        limitPrice = as.character(limitPrice),
        tradeType = tradeType
      )
      if (!is.null(clientOid)) {
        body$clientOid <- clientOid
      }
      if (!is.null(remark)) {
        body$remark <- remark
      }

      return(private$.request(
        endpoint = "/api/v3/oco/order",
        method = "POST",
        body = body,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (is.null(dt$client_oid)) {
            dt[, client_oid := NA_character_]
          }
          data.table::setcolorder(dt, intersect(c("order_id", "client_oid"), names(dt)))
          return(dt[])
        }
      ))
    },

    #' @description
    #' Cancel OCO Order by Order ID
    #'
    #' Cancels an active OCO order using its KuCoin-assigned order ID. Both the
    #' limit and stop-limit legs of the OCO order are cancelled.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated DELETE to the order-specific endpoint.
    #' 2. **Cancellation**: KuCoin cancels both legs of the OCO order.
    #' 3. **Parsing**: Returns `data.table` with the cancelled order IDs.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v3/oco/order/{orderId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Cancel OCO Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-orderld)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Position Exit**: Cancel an OCO order when manually closing a position or switching strategies.
    #' - **Order Replacement**: Cancel the existing OCO and place a new one with updated price levels.
    #' - **Error Recovery**: Cancel orphaned OCO orders detected during periodic order audits.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/order/674c40d38b4b2f00073deef3' \
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
    #'     "cancelledOrderIds": [
    #'       "674c40d38b4b2f00073deef3",
    #'       "674c40d38b4b2f00073deef4",
    #'       "674c40d38b4b2f00073deef5"
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param orderId Character; the KuCoin-assigned OCO order ID to cancel
    #'   (e.g., `"674c40d38b4b2f00073deef3"`).
    #' @return `data.table` (or `promise<data.table>` if constructed with
    #'   `async = TRUE`) with one row per cancelled order, and column:
    #'   - `cancelled_order_id` (character): Cancelled order ID (the parent
    #'     OCO and each of its sub-orders appear as separate rows). Empty
    #'     `data.table` if nothing matched.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Cancel a specific OCO order
    #' result <- oco$cancel_order_by_id("674c40d38b4b2f00073deef3")
    #' print(result$cancelled_order_id)
    #' }
    cancel_order_by_id = function(orderId) {
      return(private$.request(
        endpoint = paste0("/api/v3/oco/order/", orderId),
        method = "DELETE",
        .parser = function(data) {
          ids <- NULL
          if (!is.null(data)) {
            ids <- data$cancelledOrderIds
            data$cancelledOrderIds <- NULL
          }
          if (is.null(ids) || length(ids) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_row(data)
          id_vals <- as.character(unlist(ids, use.names = FALSE))
          if (nrow(dt) == 0L) {
            dt <- data.table::data.table(cancelled_order_id = id_vals)
          } else {
            dt <- dt[rep(1L, length(id_vals))]
            dt[, cancelled_order_id := id_vals]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Cancel OCO Order by Client OID
    #'
    #' Cancels an active OCO order using the client-assigned order ID (`clientOid`).
    #' Both the limit and stop-limit legs of the OCO order are cancelled.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated DELETE to the client-order endpoint.
    #' 2. **Lookup**: KuCoin resolves the `clientOid` to the internal OCO order.
    #' 3. **Cancellation**: Both legs of the OCO order are cancelled.
    #' 4. **Parsing**: Returns `data.table` with cancelled order IDs.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v3/oco/client-order/{clientOid}`
    #'
    #' ### Official Documentation
    #' [KuCoin Cancel OCO Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-clientoid)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Strategy-Based Cancellation**: Cancel OCO orders by your own strategy IDs without needing to store KuCoin order IDs.
    #' - **Idempotent Operations**: Use deterministic `clientOid` values so re-running cancellation logic is safe.
    #' - **Multi-Bot Coordination**: Each bot uses a unique `clientOid` prefix to manage its own OCO orders independently.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/client-order/my-bot-oco-001' \
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
    #'     "cancelledOrderIds": [
    #'       "674c40d38b4b2f00073deef3",
    #'       "674c40d38b4b2f00073deef4",
    #'       "674c40d38b4b2f00073deef5"
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param clientOid Character; the client-assigned order ID used when placing
    #'   the OCO order (e.g., `"my-bot-oco-001"`).
    #' @return `data.table` (or `promise<data.table>` if constructed with
    #'   `async = TRUE`) with one row per cancelled order, and column:
    #'   - `cancelled_order_id` (character): Cancelled order ID (the parent
    #'     OCO and each of its sub-orders appear as separate rows). Empty
    #'     `data.table` if nothing matched.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Cancel by client-assigned ID
    #' result <- oco$cancel_order_by_client_oid("my-bot-oco-001")
    #' print(result$cancelled_order_id)
    #' }
    cancel_order_by_client_oid = function(clientOid) {
      return(private$.request(
        endpoint = paste0("/api/v3/oco/client-order/", clientOid),
        method = "DELETE",
        .parser = function(data) {
          ids <- NULL
          if (!is.null(data)) {
            ids <- data$cancelledOrderIds
            data$cancelledOrderIds <- NULL
          }
          if (is.null(ids) || length(ids) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_row(data)
          id_vals <- as.character(unlist(ids, use.names = FALSE))
          if (nrow(dt) == 0L) {
            dt <- data.table::data.table(cancelled_order_id = id_vals)
          } else {
            dt <- dt[rep(1L, length(id_vals))]
            dt[, cancelled_order_id := id_vals]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Cancel All OCO Orders
    #'
    #' Cancels all active OCO orders matching the given filters. Can filter by
    #' `symbol` or specify individual `orderIds`. If no filters are provided,
    #' all active OCO orders are cancelled.
    #'
    #' ### Workflow
    #' 1. **Filter Construction**: Builds query parameters from the provided filter list.
    #' 2. **Request**: Authenticated DELETE to the batch cancellation endpoint.
    #' 3. **Cancellation**: KuCoin cancels all matching OCO orders.
    #' 4. **Parsing**: Returns `data.table` with cancelled order IDs.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v3/oco/orders`
    #'
    #' ### Official Documentation
    #' [KuCoin Batch Cancel OCO Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-cancel-oco-order)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Emergency Kill Switch**: Call with no filters to cancel all OCO orders during market anomalies or system errors.
    #' - **Symbol Cleanup**: Pass `symbol` to cancel all OCO orders for a specific pair when exiting a position entirely.
    #' - **Selective Batch Cancel**: Pass specific `orderIds` to cancel a subset of OCO orders during strategy rebalancing.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/orders?symbol=BTC-USDT' \
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
    #'     "cancelledOrderIds": [
    #'       "674c40d38b4b2f00073deef3",
    #'       "674c40d38b4b2f00073deef4",
    #'       "674c40d38b4b2f00073deef5",
    #'       "674c40d38b4b2f00073deef6"
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; filter parameters for batch cancellation:
    #'   - `symbol` (character): Optional. Trading pair to filter by (e.g., `"BTC-USDT"`).
    #'   - `orderIds` (character): Optional. Comma-separated order IDs to cancel specifically.
    #'   If empty, all active OCO orders are cancelled.
    #' @return `data.table` (or `promise<data.table>` if constructed with
    #'   `async = TRUE`) with one row per cancelled order, and column:
    #'   - `cancelled_order_id` (character): Cancelled order ID. Empty
    #'     `data.table` if no active OCO orders matched the filter.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Cancel all OCO orders for BTC-USDT
    #' result <- oco$cancel_all(query = list(symbol = "BTC-USDT"))
    #' print(result$cancelled_order_id)
    #'
    #' # Cancel all OCO orders (no filter)
    #' result <- oco$cancel_all()
    #' }
    cancel_all = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/oco/orders",
        method = "DELETE",
        query = query,
        .parser = function(data) {
          ids <- NULL
          if (!is.null(data)) {
            ids <- data$cancelledOrderIds
            data$cancelledOrderIds <- NULL
          }
          if (is.null(ids) || length(ids) == 0) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_row(data)
          id_vals <- as.character(unlist(ids, use.names = FALSE))
          if (nrow(dt) == 0L) {
            dt <- data.table::data.table(cancelled_order_id = id_vals)
          } else {
            dt <- dt[rep(1L, length(id_vals))]
            dt[, cancelled_order_id := id_vals]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get OCO Order by Order ID
    #'
    #' Retrieves summary information for a specific OCO order using its
    #' KuCoin-assigned order ID. Returns the OCO order metadata without
    #' detailed sub-order information (use `get_order_detail_by_id()` for that).
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the order-specific endpoint.
    #' 2. **Response**: KuCoin returns the OCO order summary.
    #' 3. **Parsing**: Returns `data.table` with order metadata.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/oco/order/{orderId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get OCO Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-orderld)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Status Polling**: Periodically check OCO order status to determine if either leg has triggered.
    #' - **Audit Logging**: Retrieve order metadata for trade journal and performance tracking.
    #' - **Conditional Logic**: Check the `status` field to decide whether to place replacement orders.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/oco/order/674c40d38b4b2f00073deef3' \
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
    #'     "orderId": "674c40d38b4b2f00073deef3",
    #'     "symbol": "BTC-USDT",
    #'     "clientOid": "my-bot-oco-001",
    #'     "orderTime": 1729176273859,
    #'     "status": "NEW"
    #'   }
    #' }
    #' ```
    #'
    #' @param orderId Character; the KuCoin-assigned OCO order ID
    #'   (e.g., `"674c40d38b4b2f00073deef3"`).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): OCO order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `client_oid` (character): Client-assigned order identifier.
    #'   - `order_time` (POSIXct): Order creation datetime (coerced from epoch milliseconds).
    #'   - `status` (character): Order status (e.g., `"NEW"`, `"DONE"`, `"TRIGGERED"`).
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Get OCO order summary
    #' order <- oco$get_order_by_id("674c40d38b4b2f00073deef3")
    #' print(order$status)
    #' print(order$symbol)
    #' }
    get_order_by_id = function(orderId) {
      return(private$.request(
        endpoint = paste0("/api/v3/oco/order/", orderId),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if ("order_time" %in% names(dt)) {
            dt[, order_time := ms_to_datetime(order_time)]
          }
          expected <- c("order_id", "symbol", "client_oid", "order_time", "status")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get OCO Order by Client OID
    #'
    #' Retrieves summary information for a specific OCO order using the
    #' client-assigned order ID (`clientOid`). Useful when you track orders
    #' by your own identifiers rather than KuCoin-assigned IDs.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the client-order endpoint.
    #' 2. **Lookup**: KuCoin resolves the `clientOid` to the internal OCO order.
    #' 3. **Parsing**: Returns `data.table` with order metadata.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/oco/client-order/{clientOid}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get OCO Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-clientoid)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Strategy Reconciliation**: Look up OCO orders using your strategy-generated IDs for post-trade analysis.
    #' - **Duplicate Detection**: Check if an OCO order with a given `clientOid` already exists before placing a new one.
    #' - **Bot State Recovery**: On restart, recover OCO order state using stored `clientOid` values.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/oco/client-order/my-bot-oco-001' \
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
    #'     "orderId": "674c40d38b4b2f00073deef3",
    #'     "symbol": "BTC-USDT",
    #'     "clientOid": "my-bot-oco-001",
    #'     "orderTime": 1729176273859,
    #'     "status": "NEW"
    #'   }
    #' }
    #' ```
    #'
    #' @param clientOid Character; the client-assigned order ID used when placing
    #'   the OCO order (e.g., `"my-bot-oco-001"`).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned OCO order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `client_oid` (character): Client-assigned order identifier.
    #'   - `order_time` (POSIXct): Order creation datetime (coerced from epoch milliseconds).
    #'   - `status` (character): Order status (e.g., `"NEW"`, `"DONE"`, `"TRIGGERED"`).
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Retrieve by client OID
    #' order <- oco$get_order_by_client_oid("my-bot-oco-001")
    #' print(order$order_id)
    #' print(order$status)
    #' }
    get_order_by_client_oid = function(clientOid) {
      return(private$.request(
        endpoint = paste0("/api/v3/oco/client-order/", clientOid),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if ("order_time" %in% names(dt)) {
            dt[, order_time := ms_to_datetime(order_time)]
          }
          expected <- c("order_id", "symbol", "client_oid", "order_time", "status")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get OCO Order Details by Order ID
    #'
    #' Retrieves detailed information for a specific OCO order, including the
    #' individual sub-orders (limit leg and stop-limit leg) and their respective
    #' statuses. This provides more information than `get_order_by_id()`.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the order details endpoint.
    #' 2. **Response**: KuCoin returns the OCO order with full sub-order breakdown.
    #' 3. **Parsing**: Returns `data.table` with detailed order information.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/oco/order/details/{orderId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get OCO Order Detail By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-detail-by-orderld)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Fill Analysis**: Inspect sub-order details to determine which leg filled and at what price.
    #' - **Partial Fill Detection**: Check individual sub-order fill quantities for partial execution scenarios.
    #' - **Trade Journaling**: Extract complete execution details for performance attribution and reporting.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/oco/order/details/674c40d38b4b2f00073deef3' \
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
    #'     "orderId": "674c40d38b4b2f00073deef3",
    #'     "symbol": "BTC-USDT",
    #'     "clientOid": "my-bot-oco-001",
    #'     "orderTime": 1729176273859,
    #'     "status": "NEW",
    #'     "orders": [
    #'       {
    #'         "id": "674c40d38b4b2f00073deef4",
    #'         "symbol": "BTC-USDT",
    #'         "side": "sell",
    #'         "price": "110000",
    #'         "size": "0.0001",
    #'         "status": "NEW"
    #'       },
    #'       {
    #'         "id": "674c40d38b4b2f00073deef5",
    #'         "symbol": "BTC-USDT",
    #'         "side": "sell",
    #'         "price": "89500",
    #'         "stopPrice": "90000",
    #'         "size": "0.0001",
    #'         "status": "NEW"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param orderId Character; the KuCoin-assigned OCO order ID
    #'   (e.g., `"674c40d38b4b2f00073deef3"`).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): OCO order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `client_oid` (character): Client-assigned order identifier.
    #'   - `order_time` (POSIXct): Order creation datetime (coerced from epoch milliseconds).
    #'   - `status` (character): Overall OCO order status.
    #'
    #'   The nested `orders` array (one entry per sub-order — typically the
    #'   limit leg + the stop-limit leg) is exploded to long format: the
    #'   parent OCO row is replicated once per sub-order, and each sub-order's
    #'   fields are added with a `sub_order_` prefix. Typical sub-order columns:
    #'   - `sub_order_id` (character)
    #'   - `sub_order_symbol` (character)
    #'   - `sub_order_side` (character)
    #'   - `sub_order_price` (character)
    #'   - `sub_order_size` (character)
    #'   - `sub_order_status` (character)
    #'   - `sub_order_stop_price` (character; only present on the stop leg)
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Get full OCO order details with sub-orders
    #' details <- oco$get_order_detail_by_id("674c40d38b4b2f00073deef3")
    #' print(details$status)
    #' print(details$orders)
    #' }
    get_order_detail_by_id = function(orderId) {
      return(private$.request(
        endpoint = paste0("/api/v3/oco/order/details/", orderId),
        .parser = function(data) {
          orders <- data$orders
          data$orders <- NULL
          dt <- as_dt_row(data)
          if ("order_time" %in% names(dt)) {
            dt[, order_time := ms_to_datetime(order_time)]
          }
          # Expand orders to long format: one row per sub-order
          if (!is.null(orders) && length(orders) > 0) {
            orders_dt <- as_dt_list(orders)
            order_names <- names(orders_dt)
            new_names <- paste0("sub_order_", order_names)
            data.table::setnames(orders_dt, order_names, new_names)
            dt <- dt[rep(1L, nrow(orders_dt))]
            dt <- cbind(dt, orders_dt)
          }
          expected <- c("order_id", "symbol", "client_oid", "order_time", "status")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get OCO Order List
    #'
    #' Retrieves a paginated list of OCO orders with optional filtering by symbol,
    #' time range, and pagination parameters. Returns all OCO orders matching the
    #' specified criteria.
    #'
    #' ### Workflow
    #' 1. **Filter Construction**: Builds query parameters from the provided filter list.
    #' 2. **Request**: Authenticated GET to the order list endpoint.
    #' 3. **Pagination**: KuCoin returns a paginated response with `items` array.
    #' 4. **Parsing**: Binds all items into a single `data.table` using `rbindlist()`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/oco/orders`
    #'
    #' ### Official Documentation
    #' [KuCoin Get OCO Order List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-list)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Portfolio Overview**: List all active OCO orders to display current take-profit/stop-loss levels across positions.
    #' - **Stale Order Detection**: Filter by `startAt`/`endAt` to find OCO orders that have been open too long and may need adjustment.
    #' - **Pagination Loop**: Use `currentPage` and `pageSize` to iterate through large result sets in batch processing.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/oco/orders?symbol=BTC-USDT&pageSize=20&currentPage=1' \
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
    #'     "pageSize": 20,
    #'     "totalNum": 2,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "orderId": "674c40d38b4b2f00073deef3",
    #'         "symbol": "BTC-USDT",
    #'         "clientOid": "my-bot-oco-001",
    #'         "orderTime": 1729176273859,
    #'         "status": "NEW"
    #'       },
    #'       {
    #'         "orderId": "674c40d38b4b2f00073deef6",
    #'         "symbol": "ETH-USDT",
    #'         "clientOid": "my-bot-oco-002",
    #'         "orderTime": 1729176274000,
    #'         "status": "TRIGGERED"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; filter and pagination parameters:
    #'   - `symbol` (character): Optional. Trading pair to filter by (e.g., `"BTC-USDT"`).
    #'   - `startAt` (numeric): Optional. Start time in milliseconds (inclusive).
    #'   - `endAt` (numeric): Optional. End time in milliseconds (inclusive).
    #'   - `pageSize` (integer): Optional. Number of results per page (default 20, max 100).
    #'   - `currentPage` (integer): Optional. Page number to retrieve (default 1).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns (one row per OCO order):
    #'   - `order_id` (character): OCO order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `client_oid` (character): Client-assigned order identifier.
    #'   - `order_time` (POSIXct): Order creation datetime (coerced from epoch milliseconds).
    #'   - `status` (character): Order status (e.g., `"NEW"`, `"DONE"`, `"TRIGGERED"`).
    #'   Returns an empty `data.table` if no orders match.
    #'
    #' @examples
    #' \dontrun{
    #' oco <- KucoinOcoOrders$new()
    #'
    #' # Get all OCO orders
    #' orders <- oco$get_order_list()
    #' print(orders)
    #'
    #' # Filter by symbol with pagination
    #' orders <- oco$get_order_list(query = list(
    #'   symbol = "BTC-USDT",
    #'   pageSize = 50,
    #'   currentPage = 1
    #' ))
    #' print(orders)
    #'
    #' # Filter by time range
    #' orders <- oco$get_order_list(query = list(
    #'   startAt = as.numeric(lubridate::now() - 86400) * 1000,
    #'   endAt = as.numeric(lubridate::now()) * 1000
    #' ))
    #' }
    get_order_list = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/oco/orders",
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
          if ("order_time" %in% names(dt)) {
            dt[, order_time := ms_to_datetime(order_time)]
          }
          expected <- c("order_id", "symbol", "client_oid", "order_time", "status")
          data.table::setcolorder(dt, intersect(expected, names(dt)))
          return(dt[])
        }
      ))
    }
  )
)
