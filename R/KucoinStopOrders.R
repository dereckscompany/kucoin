# File: R/KucoinStopOrders.R
# R6 class for KuCoin stop order management.

#' KucoinStopOrders: Stop Order Management
#'
#' Provides methods for managing stop orders on KuCoin Spot.
#' Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Stop Order Placement**: Place limit or market stop orders with configurable trigger prices,
#'   self-trade prevention, time-in-force policies, and iceberg/hidden order support.
#' - **Order Cancellation**: Cancel individual stop orders by KuCoin order ID, by client-assigned OID,
#'   or batch-cancel all stop orders matching filter criteria.
#' - **Order Queries**: Retrieve details for individual stop orders by order ID or client OID,
#'   and list all stop orders with pagination and filtering support.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase).
#' Stop orders remain dormant until the market price crosses the `stop_price` threshold.
#' Once triggered, a stop order becomes a regular limit or market order and is submitted
#' to the matching engine. Use stop orders for stop-loss, take-profit, and breakout strategies.
#'
#' ```r
#' # Synchronous usage
#' stop <- KucoinStopOrders$new()
#' orders <- stop$get_order_list(query = list(symbol = "BTC-USDT"))
#' print(orders)
#'
#' # Asynchronous usage
#' stop_async <- KucoinStopOrders$new(async = TRUE)
#' main <- coro::async(function() {
#'   orders <- await(stop_async$get_order_list(query = list(symbol = "BTC-USDT")))
#'   print(orders)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' ```
#'
#' ### Official Documentation
#' [KuCoin Spot Trading Stop Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-stop-order)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_order | POST /api/v1/stop-order | POST |
#' | cancel_order_by_id | DELETE /api/v1/stop-order/\{orderId\} | DELETE |
#' | cancel_order_by_client_oid | DELETE /api/v1/stop-order/cancelOrderByClientOid | DELETE |
#' | cancel_all | DELETE /api/v1/stop-order/cancel | DELETE |
#' | get_order_by_id | GET /api/v1/stop-order/\{orderId\} | GET |
#' | get_order_by_client_oid | GET /api/v1/stop-order/queryOrderByClientOid | GET |
#' | get_order_list | GET /api/v1/stop-order | GET |
#'
#' @section Stop Order Types:
#' **Limit Stop Orders** require `price`, `size`, and `stopPrice`. When the market
#' reaches the `stopPrice`, a limit order is placed at the specified `price`.
#' Optional parameters include `timeInForce`, `cancelAfter`, `postOnly`, `hidden`,
#' `iceberg`, and `visibleSize`.
#'
#' **Market Stop Orders** require `stopPrice` and either `size` (base currency quantity)
#' or `funds` (quote currency amount), but not both. `price` must NOT be specified.
#' When the market reaches the `stopPrice`, a market order executes immediately at
#' the best available price.
#'
#' **How stopPrice Triggers Work**:
#' - For a **buy** stop order, the stop triggers when the last traded price rises
#'   to or above `stopPrice`.
#' - For a **sell** stop order, the stop triggers when the last traded price falls
#'   to or below `stopPrice`.
#' - Once triggered, the stop order is converted to a regular order (limit or market)
#'   and submitted to the matching engine. Trigger checks are based on the last
#'   trade price for the symbol.
#'
#' @section Self-Trade Prevention (STP):
#' Use the `stp` parameter to control behaviour when your orders would match each other:
#' - `"CN"` (Cancel Newest): Cancel the incoming order.
#' - `"CO"` (Cancel Oldest): Cancel the resting order.
#' - `"CB"` (Cancel Both): Cancel both orders.
#' - `"DC"` (Decrement and Cancel): Reduce quantities.
#'
#' @section Time-In-Force Options:
#' - `"GTC"` (Good Till Cancelled): Remains until filled or cancelled. Default.
#' - `"GTT"` (Good Till Time): Cancels after `cancelAfter` seconds.
#' - `"IOC"` (Immediate Or Cancel): Fill immediately or cancel remainder.
#' - `"FOK"` (Fill Or Kill): Fill entirely or cancel completely.
#'
#' @examples
#' \dontrun{
#' # Synchronous
#' stop <- KucoinStopOrders$new()
#' orders <- stop$get_order_list(query = list(symbol = "BTC-USDT"))
#' print(orders)
#'
#' # Asynchronous
#' stop_async <- KucoinStopOrders$new(async = TRUE)
#' main <- coro::async(function() {
#'   orders <- await(stop_async$get_order_list(query = list(symbol = "BTC-USDT")))
#'   print(orders)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinStopOrders <- R6::R6Class(
  "KucoinStopOrders",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Place a Stop Order
    #'
    #' Places a stop order (limit or market) that triggers when the stop
    #' price is reached. For limit stop orders, both `price` and `size` are
    #' required. For market stop orders, either `size` or `funds` must be
    #' specified (but not both), and `price` must not be set.
    #'
    #' ### Workflow
    #' 1. **Validation**: Checks `type`, `side`, and `symbol` format; enforces
    #'    type-specific parameter constraints (e.g., `price` required for limit,
    #'    `funds`/`size` mutual exclusivity for market).
    #' 2. **Body Construction**: Assembles the request body with required and
    #'    optional parameters, converting numerics to character strings as needed.
    #' 3. **Request**: Authenticated POST to the stop order endpoint.
    #' 4. **Parsing**: Returns a `data.table` with the assigned `order_id` and `client_oid`.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v1/stop-order`
    #'
    #' ### Official Documentation
    #' [KuCoin Add Stop Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-stop-order)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Stop-Loss**: Place a sell stop order below your entry price to automatically exit a losing position.
    #' - **Breakout Entry**: Place a buy stop order above resistance to enter on a confirmed breakout.
    #' - **Risk Management**: Combine with `timeInForce = "GTT"` and `cancelAfter` to auto-expire stale stop orders.
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v1/stop-order' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"type":"limit","symbol":"BTC-USDT","side":"sell","stopPrice":"90000","price":"89500","size":"0.00001","tradeType":"TRADE"}'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "vs8hoo8q2ceshiue003b67c0",
    #'     "clientOid": null
    #'   }
    #' }
    #' ```
    #'
    #' @param type Character; order type, one of `"limit"` or `"market"`.
    #'   Determines which additional parameters are required.
    #' @param symbol Character; trading pair symbol (e.g., `"BTC-USDT"`).
    #'   Must match the `BASE-QUOTE` format validated by `verify_symbol()`.
    #' @param side Character; order side, one of `"buy"` or `"sell"`.
    #' @param stopPrice Character; the trigger price at which the stop order activates.
    #'   When the last traded price reaches this value, the order is placed.
    #' @param clientOid Character or NULL; optional client-assigned unique identifier
    #'   for the order (max 40 characters). Useful for tracking orders in automated systems.
    #' @param price Character or NULL; limit order price. Required for limit stop orders;
    #'   must NOT be set for market stop orders. Should align with the symbol's `priceIncrement`.
    #' @param size Character or NULL; order quantity in base currency.
    #'   Required for limit stop orders. For market stop orders, mutually exclusive with `funds`.
    #' @param funds Character or NULL; order amount in quote currency for market stop orders.
    #'   Mutually exclusive with `size`. Not applicable for limit stop orders.
    #' @param stp Character or NULL; self-trade prevention strategy.
    #'   One of `"DC"` (Decrement and Cancel), `"CO"` (Cancel Oldest),
    #'   `"CN"` (Cancel Newest), `"CB"` (Cancel Both).
    #' @param remark Character or NULL; order remarks or notes (max 20 ASCII characters).
    #' @param timeInForce Character or NULL; time-in-force policy for the triggered order.
    #'   One of `"GTC"` (Good Till Cancelled), `"GTT"` (Good Till Time),
    #'   `"IOC"` (Immediate Or Cancel), `"FOK"` (Fill Or Kill).
    #' @param cancelAfter Numeric or NULL; number of seconds after which to auto-cancel.
    #'   Only valid when `timeInForce = "GTT"`.
    #' @param postOnly Logical or NULL; if `TRUE`, the triggered order is rejected if it
    #'   would immediately match (guarantees maker fee).
    #' @param hidden Logical or NULL; if `TRUE`, the triggered order is hidden from the order book.
    #' @param iceberg Logical or NULL; if `TRUE`, only `visibleSize` of the order is displayed.
    #' @param visibleSize Character or NULL; the visible portion of an iceberg order.
    #'   Only applicable when `iceberg = TRUE`.
    #' @param tradeType Character; trade type, defaults to `"TRADE"` for spot trading.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned stop order identifier.
    #'   - `client_oid` (character or NA): Client-provided order identifier, if supplied.
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Limit stop-loss sell order
    #' order <- stop$add_order(
    #'   type = "limit", symbol = "BTC-USDT", side = "sell",
    #'   stopPrice = "90000", price = "89500", size = "0.00001"
    #' )
    #' print(order$order_id)
    #'
    #' # Market stop-loss sell order by size
    #' order <- stop$add_order(
    #'   type = "market", symbol = "BTC-USDT", side = "sell",
    #'   stopPrice = "90000", size = "0.00001"
    #' )
    #'
    #' # Market buy breakout order by funds
    #' order <- stop$add_order(
    #'   type = "market", symbol = "BTC-USDT", side = "buy",
    #'   stopPrice = "105000", funds = "100"
    #' )
    #' }
    add_order = function(
      type,
      symbol,
      side,
      stopPrice,
      clientOid = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL,
      tradeType = "TRADE"
    ) {
      type <- rlang::arg_match0(type, c("limit", "market"))
      side <- rlang::arg_match0(side, c("buy", "sell"))
      if (!verify_symbol(symbol)) {
        rlang::abort("Parameter 'symbol' must be a valid ticker.")
      }

      # Type-specific validation
      if (type == "limit") {
        if (is.null(price)) {
          rlang::abort("'price' is required for limit stop orders.")
        }
        if (is.null(size)) {
          rlang::abort("'size' is required for limit stop orders.")
        }
        if (!is.null(funds)) rlang::abort("'funds' is not applicable for limit orders.")
      } else {
        if (!is.null(price)) {
          rlang::abort("'price' is not applicable for market orders.")
        }
        if (is.null(size) && is.null(funds)) {
          rlang::abort("Either 'size' or 'funds' must be specified for market orders.")
        }
        if (!is.null(size) && !is.null(funds)) {
          rlang::abort("'size' and 'funds' are mutually exclusive for market orders.")
        }
      }

      body <- list(
        type = type,
        symbol = symbol,
        side = side,
        stopPrice = as.character(stopPrice),
        tradeType = tradeType
      )
      if (!is.null(clientOid)) {
        body$clientOid <- clientOid
      }
      if (!is.null(price)) {
        body$price <- as.character(price)
      }
      if (!is.null(size)) {
        body$size <- as.character(size)
      }
      if (!is.null(funds)) {
        body$funds <- as.character(funds)
      }
      if (!is.null(stp)) {
        body$stp <- rlang::arg_match0(stp, c("DC", "CO", "CN", "CB"))
      }
      if (!is.null(remark)) {
        body$remark <- remark
      }
      if (!is.null(timeInForce)) {
        body$timeInForce <- rlang::arg_match0(timeInForce, c("GTC", "GTT", "IOC", "FOK"))
      }
      if (!is.null(cancelAfter)) {
        body$cancelAfter <- as.integer(cancelAfter)
      }
      if (!is.null(postOnly)) {
        body$postOnly <- postOnly
      }
      if (!is.null(hidden)) {
        body$hidden <- hidden
      }
      if (!is.null(iceberg)) {
        body$iceberg <- iceberg
      }
      if (!is.null(visibleSize)) {
        body$visibleSize <- as.character(visibleSize)
      }

      return(private$.request(
        endpoint = "/api/v1/stop-order",
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
    #' Cancel Stop Order by Order ID
    #'
    #' Cancels a single pending stop order using its KuCoin-assigned order ID.
    #' Only stop orders that have not yet been triggered can be cancelled.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated DELETE with the order ID in the URL path.
    #' 2. **Parsing**: Returns a `data.table` with the cancelled order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v1/stop-order/{orderId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Cancel Stop Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-stop-order-by-orderld)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Dynamic Stop Adjustment**: Cancel and replace stop orders as price moves in your favour.
    #' - **Strategy Teardown**: Cancel individual stop orders when closing a position manually.
    #' - **Error Recovery**: Cancel stop orders that were placed with incorrect parameters.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE 'https://api.kucoin.com/api/v1/stop-order/vs8hoo8q2ceshiue003b67c0' \
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
    #'     "cancelledOrderIds": ["vs8hoo8q2ceshiue003b67c0"]
    #'   }
    #' }
    #' ```
    #'
    #' @param orderId Character; the KuCoin-assigned stop order ID to cancel.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with column:
    #'   - `cancelled_order_ids` (character): Vector of cancelled stop order IDs.
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Cancel a specific stop order
    #' result <- stop$cancel_order_by_id("vs8hoo8q2ceshiue003b67c0")
    #' print(result$cancelled_order_ids)
    #' }
    cancel_order_by_id = function(orderId) {
      return(private$.request(
        endpoint = paste0("/api/v1/stop-order/", orderId),
        method = "DELETE",
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Cancel Stop Order by Client OID
    #'
    #' Cancels a pending stop order using the client-assigned order ID and symbol.
    #' Both `clientOid` and `symbol` are required as query parameters.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated DELETE with `clientOid` and `symbol` as query parameters.
    #' 2. **Parsing**: Returns a `data.table` with the cancelled order ID.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v1/stop-order/cancelOrderByClientOid`
    #'
    #' ### Official Documentation
    #' [KuCoin Cancel Stop Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-stop-order-by-clientoid)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Client-Side Tracking**: Cancel orders using your own identifiers without storing KuCoin order IDs.
    #' - **Idempotent Cancellation**: Use deterministic client OIDs for reliable cancel-and-replace workflows.
    #' - **Multi-Symbol Bots**: Combine `clientOid` prefixes with symbol for organized order management.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE 'https://api.kucoin.com/api/v1/stop-order/cancelOrderByClientOid?clientOid=my-stop-001&symbol=BTC-USDT' \
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
    #'     "cancelledOrderId": "vs8hoo8q2ceshiue003b67c0",
    #'     "clientOid": "my-stop-001"
    #'   }
    #' }
    #' ```
    #'
    #' @param clientOid Character; the client-assigned order ID used when placing the stop order.
    #' @param symbol Character; trading pair symbol (e.g., `"BTC-USDT"`). Required to
    #'   disambiguate client OIDs across different trading pairs.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `cancelled_order_id` (character): The KuCoin order ID of the cancelled stop order.
    #'   - `client_oid` (character): The client-assigned order ID that was cancelled.
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Cancel by client OID
    #' result <- stop$cancel_order_by_client_oid("my-stop-001", symbol = "BTC-USDT")
    #' print(result$cancelled_order_id)
    #' }
    cancel_order_by_client_oid = function(clientOid, symbol) {
      return(private$.request(
        endpoint = "/api/v1/stop-order/cancelOrderByClientOid",
        method = "DELETE",
        query = list(clientOid = clientOid, symbol = symbol),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Cancel All Stop Orders
    #'
    #' Cancels all pending stop orders matching the given filters. Supports filtering
    #' by symbol, trade type, and specific order IDs. If no filters are provided,
    #' all pending stop orders are cancelled.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated DELETE with optional filter query parameters.
    #' 2. **Parsing**: Returns a `data.table` with all cancelled order IDs.
    #'
    #' ### API Endpoint
    #' `DELETE https://api.kucoin.com/api/v1/stop-order/cancel`
    #'
    #' ### Official Documentation
    #' [KuCoin Batch Cancel Stop Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-cancel-stop-orders)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Emergency Kill Switch**: Call with no filters to cancel all stop orders during extreme volatility.
    #' - **Symbol Cleanup**: Filter by `symbol` to cancel all stop orders for a specific trading pair.
    #' - **Selective Batch Cancel**: Pass `orderIds` to cancel a specific subset of stop orders.
    #'
    #' ### curl
    #' ```
    #' curl --location --request DELETE 'https://api.kucoin.com/api/v1/stop-order/cancel?symbol=BTC-USDT&tradeType=TRADE' \
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
    #'       "vs8hoo8q2ceshiue003b67c0",
    #'       "vs8hoo8q2ceshiue003b67c1",
    #'       "vs8hoo8q2ceshiue003b67c2"
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters:
    #'   - `symbol` (character): Trading pair to filter by (e.g., `"BTC-USDT"`).
    #'   - `tradeType` (character): Trade type, typically `"TRADE"` for spot.
    #'   - `orderIds` (character): Comma-separated list of specific stop order IDs to cancel.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with column:
    #'   - `cancelled_order_ids` (character): Vector of cancelled stop order IDs.
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Cancel all stop orders for BTC-USDT
    #' result <- stop$cancel_all(query = list(symbol = "BTC-USDT"))
    #' print(result$cancelled_order_ids)
    #'
    #' # Cancel all stop orders (no filter)
    #' result <- stop$cancel_all()
    #' print(result$cancelled_order_ids)
    #' }
    cancel_all = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v1/stop-order/cancel",
        method = "DELETE",
        query = query,
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Stop Order by Order ID
    #'
    #' Retrieves full details for a single stop order using its KuCoin-assigned
    #' order ID. Returns order parameters, status, trigger price, and timestamps.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with the order ID in the URL path.
    #' 2. **Parsing**: Returns a `data.table` with all order fields as columns.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/stop-order/{orderId}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Stop Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-stop-order-by-orderld)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Order Verification**: Confirm a stop order was placed with the correct parameters after submission.
    #' - **Status Monitoring**: Poll order status to detect when a stop order has been triggered.
    #' - **Audit Trail**: Retrieve full order details for logging and post-trade analysis.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/stop-order/vs8hoo8q2ceshiue003b67c0' \
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
    #'     "id": "vs8hoo8q2ceshiue003b67c0",
    #'     "symbol": "BTC-USDT",
    #'     "userId": "60d7b4c0f1baed0006a25f12",
    #'     "type": "limit",
    #'     "side": "sell",
    #'     "price": "89500",
    #'     "size": "0.00001",
    #'     "funds": null,
    #'     "stp": null,
    #'     "timeInForce": "GTC",
    #'     "cancelAfter": -1,
    #'     "postOnly": false,
    #'     "hidden": false,
    #'     "iceberg": false,
    #'     "visibleSize": null,
    #'     "channel": "API",
    #'     "clientOid": null,
    #'     "remark": null,
    #'     "tags": null,
    #'     "stopPrice": "90000",
    #'     "stop": "loss",
    #'     "stopTriggerTime": null,
    #'     "tradeType": "TRADE",
    #'     "createdAt": 1706789012000,
    #'     "orderTime": 1706789012345678900
    #'   }
    #' }
    #' ```
    #'
    #' @param orderId Character; the KuCoin-assigned stop order ID to retrieve.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with one row containing order details. Key columns include:
    #'   - `id` (character): Stop order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `type` (character): Order type (`"limit"` or `"market"`).
    #'   - `side` (character): Order side (`"buy"` or `"sell"`).
    #'   - `price` (character): Limit price (NULL for market orders).
    #'   - `size` (character): Order quantity in base currency.
    #'   - `stop_price` (character): Trigger price for the stop order.
    #'   - `stop` (character): Stop direction (`"loss"` or `"entry"`).
    #'   - `created_at` (POSIXct): Creation datetime (coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Get stop order details
    #' order <- stop$get_order_by_id("vs8hoo8q2ceshiue003b67c0")
    #' print(order$stop_price)
    #' print(order$side)
    #' }
    get_order_by_id = function(orderId) {
      return(private$.request(
        endpoint = paste0("/api/v1/stop-order/", orderId),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c("id", "symbol", "type", "side", "price", "size", "stop_price", "stop", "created_at"),
              names(dt)
            )
          )
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Stop Order by Client OID
    #'
    #' Retrieves stop order details using the client-assigned order ID and symbol.
    #' May return multiple results if the same `clientOid` was used across different orders.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `clientOid` and `symbol` as query parameters.
    #' 2. **Parsing**: If multiple orders match, returns a multi-row `data.table`;
    #'    otherwise returns a single-row `data.table`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/stop-order/queryOrderByClientOid`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Stop Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/get-stop-order-by-clientoid)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Client-Side Lookup**: Query stop orders using your own identifiers without persisting KuCoin IDs.
    #' - **Order Reconciliation**: Verify that a stop order with a given client OID exists and check its parameters.
    #' - **Deduplication Check**: Before placing a new stop order, check if one with the same client OID already exists.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/stop-order/queryOrderByClientOid?clientOid=my-stop-001&symbol=BTC-USDT' \
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
    #'       "id": "vs8hoo8q2ceshiue003b67c0",
    #'       "symbol": "BTC-USDT",
    #'       "userId": "60d7b4c0f1baed0006a25f12",
    #'       "type": "limit",
    #'       "side": "sell",
    #'       "price": "89500",
    #'       "size": "0.00001",
    #'       "funds": null,
    #'       "stp": null,
    #'       "timeInForce": "GTC",
    #'       "cancelAfter": -1,
    #'       "postOnly": false,
    #'       "hidden": false,
    #'       "iceberg": false,
    #'       "visibleSize": null,
    #'       "channel": "API",
    #'       "clientOid": "my-stop-001",
    #'       "remark": null,
    #'       "tags": null,
    #'       "stopPrice": "90000",
    #'       "stop": "loss",
    #'       "stopTriggerTime": null,
    #'       "tradeType": "TRADE",
    #'       "createdAt": 1706789012000,
    #'       "orderTime": 1706789012345678900
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param clientOid Character; the client-assigned order ID to search for.
    #' @param symbol Character; trading pair symbol (e.g., `"BTC-USDT"`). Required to
    #'   scope the search to a specific trading pair.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with one or more rows of order details. Key columns include:
    #'   - `id` (character): Stop order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `type` (character): Order type (`"limit"` or `"market"`).
    #'   - `side` (character): Order side (`"buy"` or `"sell"`).
    #'   - `price` (character): Limit price (NULL for market orders).
    #'   - `size` (character): Order quantity in base currency.
    #'   - `stop_price` (character): Trigger price for the stop order.
    #'   - `client_oid` (character): The client-assigned order ID.
    #'   - `created_at` (POSIXct): Creation datetime (coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Look up stop order by client OID
    #' order <- stop$get_order_by_client_oid("my-stop-001", symbol = "BTC-USDT")
    #' print(order$id)
    #' print(order$stop_price)
    #' }
    get_order_by_client_oid = function(clientOid, symbol) {
      return(private$.request(
        endpoint = "/api/v1/stop-order/queryOrderByClientOid",
        query = list(clientOid = clientOid, symbol = symbol),
        .parser = function(data) {
          if (is.list(data) && !is.null(data[[1]]) && is.list(data[[1]])) {
            dt <- data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)
          } else {
            dt <- as_dt_row(data)
          }
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c("id", "symbol", "type", "side", "price", "size", "stop_price", "client_oid", "created_at"),
              names(dt)
            )
          )
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Stop Order List
    #'
    #' Retrieves a paginated list of stop orders with optional filtering by symbol,
    #' side, type, and time range. Returns all matching stop orders as a `data.table`.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with optional query parameters for filtering and pagination.
    #' 2. **Parsing**: Extracts the `items` array from the paginated response and
    #'    binds rows into a `data.table`. Returns an empty `data.table` if no orders match.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/stop-order`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Stop Order List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-stop-orders-list)
    #'
    #' Verified: 2026-02-01
    #'
    #' ### Automated Trading Usage
    #' - **Portfolio Monitoring**: Periodically poll active stop orders to maintain an accurate view of pending triggers.
    #' - **Reconciliation**: Compare local order state with exchange state on bot startup or after reconnection.
    #' - **Reporting**: Retrieve historical stop orders filtered by time range for performance analysis.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/stop-order?symbol=BTC-USDT&side=sell&pageSize=50&currentPage=1' \
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
    #'         "id": "vs8hoo8q2ceshiue003b67c0",
    #'         "symbol": "BTC-USDT",
    #'         "userId": "60d7b4c0f1baed0006a25f12",
    #'         "type": "limit",
    #'         "side": "sell",
    #'         "price": "89500",
    #'         "size": "0.00001",
    #'         "funds": null,
    #'         "stp": null,
    #'         "timeInForce": "GTC",
    #'         "cancelAfter": -1,
    #'         "postOnly": false,
    #'         "hidden": false,
    #'         "iceberg": false,
    #'         "visibleSize": null,
    #'         "channel": "API",
    #'         "clientOid": null,
    #'         "remark": null,
    #'         "tags": null,
    #'         "stopPrice": "90000",
    #'         "stop": "loss",
    #'         "stopTriggerTime": null,
    #'         "tradeType": "TRADE",
    #'         "createdAt": 1706789012000,
    #'         "orderTime": 1706789012345678900
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter and pagination parameters:
    #'   - `symbol` (character): Trading pair to filter by (e.g., `"BTC-USDT"`).
    #'   - `side` (character): Order side filter, `"buy"` or `"sell"`.
    #'   - `type` (character): Order type filter, `"limit"` or `"market"`.
    #'   - `startAt` (numeric): Start time in milliseconds (UNIX epoch).
    #'   - `endAt` (numeric): End time in milliseconds (UNIX epoch).
    #'   - `currentPage` (integer): Page number for pagination (default 1).
    #'   - `pageSize` (integer): Number of results per page (default 50, max 100).
    #'   - `tradeType` (character): Trade type, typically `"TRADE"` for spot.
    #'   - `orderIds` (character): Comma-separated list of specific stop order IDs.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with zero or more rows. Returns an empty `data.table` if no
    #'   stop orders match the query. Key columns include:
    #'   - `id` (character): Stop order identifier.
    #'   - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`).
    #'   - `type` (character): Order type (`"limit"` or `"market"`).
    #'   - `side` (character): Order side (`"buy"` or `"sell"`).
    #'   - `price` (character): Limit price (NULL for market orders).
    #'   - `size` (character): Order quantity in base currency.
    #'   - `stop_price` (character): Trigger price for the stop order.
    #'   - `stop` (character): Stop direction (`"loss"` or `"entry"`).
    #'   - `time_in_force` (character): Time-in-force policy.
    #'   - `created_at` (POSIXct): Creation datetime (coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' stop <- KucoinStopOrders$new()
    #'
    #' # Get all BTC-USDT stop orders
    #' orders <- stop$get_order_list(query = list(symbol = "BTC-USDT"))
    #' print(orders)
    #'
    #' # Get sell stop orders with pagination
    #' orders <- stop$get_order_list(query = list(
    #'   symbol = "BTC-USDT", side = "sell",
    #'   currentPage = 1, pageSize = 20
    #' ))
    #' print(nrow(orders))
    #'
    #' # Get stop orders within a time range
    #' orders <- stop$get_order_list(query = list(
    #'   symbol = "ETH-USDT",
    #'   startAt = as.numeric(lubridate::now() - 86400) * 1000,
    #'   endAt = as.numeric(lubridate::now()) * 1000
    #' ))
    #' }
    get_order_list = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v1/stop-order",
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
          if ("created_at" %in% names(dt)) {
            dt[, created_at := ms_to_datetime(created_at)]
          }
          data.table::setcolorder(
            dt,
            intersect(
              c(
                "id",
                "symbol",
                "type",
                "side",
                "price",
                "size",
                "stop_price",
                "stop",
                "time_in_force",
                "created_at"
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
