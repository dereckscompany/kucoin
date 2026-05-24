# KucoinTrading: Spot Order Management

KucoinTrading: Spot Order Management

KucoinTrading: Spot Order Management

## Details

Provides methods for placing, cancelling, and querying spot orders on
KuCoin. All order operations use the HF (High-Frequency) trading
endpoints. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Order Placement**: Place single or batch limit/market orders with
  full parameter control.

- **Order Testing**: Validate order parameters without execution via the
  test endpoint.

- **Order Cancellation**: Cancel by order ID, client OID, partially, by
  symbol, or all at once.

- **Order Queries**: Retrieve order details, open orders, closed orders,
  fills, and symbols with activity.

### Usage

All methods require authentication (valid API key, secret, passphrase).
The `KucoinTrading` class consolidates functionality previously split
across `KucoinSpotAddOrder`, `KucoinSpotCancelOrder`, and
`KucoinSpotGetOrder`.

### Official Documentation

[KuCoin Spot Trading
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-order)

### Endpoints Covered

|  |  |  |
|----|----|----|
| Method | Endpoint | HTTP |
| add_order | POST /api/v1/hf/orders | POST |
| add_order_test | POST /api/v1/hf/orders/test | POST |
| add_order_batch | POST /api/v1/hf/orders/multi | POST |
| cancel_order_by_id | DELETE /api/v1/hf/orders/{orderId} | DELETE |
| cancel_order_by_client_oid | DELETE /api/v1/hf/orders/client-order/{clientOid} | DELETE |
| cancel_partial_order | DELETE /api/v1/hf/orders/cancel/{orderId} | DELETE |
| cancel_all_by_symbol | DELETE /api/v1/hf/orders | DELETE |
| cancel_all | DELETE /api/v1/hf/orders/cancelAll | DELETE |
| get_order_by_id | GET /api/v1/hf/orders/{orderId} | GET |
| get_order_by_client_oid | GET /api/v1/hf/orders/client-order/{clientOid} | GET |
| get_fills | GET /api/v1/hf/fills | GET |
| get_symbols_with_open_orders | GET /api/v1/hf/orders/active/symbols | GET |
| get_open_orders | GET /api/v1/hf/orders/active | GET |
| get_closed_orders | GET /api/v1/hf/orders/done | GET |
| add_order_sync | POST /api/v1/hf/orders/sync | POST |
| add_order_batch_sync | POST /api/v1/hf/orders/multi/sync | POST |
| cancel_order_by_id_sync | DELETE /api/v1/hf/orders/sync/{orderId} | DELETE |
| cancel_order_by_client_oid_sync | DELETE /api/v1/hf/orders/sync/client-order/{clientOid} | DELETE |
| modify_order | POST /api/v1/hf/orders/alter | POST |
| set_dcp | POST /api/v1/hf/orders/dead-cancel-all | POST |
| get_dcp | GET /api/v1/hf/orders/dead-cancel-all/query | GET |

## Order Types and Parameters

**Limit Orders** require `price` and `size`. Optional: `timeInForce`,
`cancelAfter`, `postOnly`, `hidden`, `iceberg`, `visibleSize`.

**Market Orders** require either `size` (base currency qty) or `funds`
(quote currency qty), but not both. `price` must NOT be specified.

## Self-Trade Prevention (STP)

Use the `stp` parameter to control behaviour when your orders would
match each other:

- `"CN"` (Cancel Newest): Cancel the incoming order.

- `"CO"` (Cancel Oldest): Cancel the resting order.

- `"CB"` (Cancel Both): Cancel both orders.

- `"DC"` (Decrement and Cancel): Reduce quantities.

## Time-In-Force Options

- `"GTC"` (Good Till Cancelled): Remains until filled or cancelled.
  Default.

- `"GTT"` (Good Till Time): Cancels after `cancelAfter` seconds.

- `"IOC"` (Immediate Or Cancel): Fill immediately or cancel remainder.

- `"FOK"` (Fill Or Kill): Fill entirely or cancel completely.

## Super class

[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinTrading`

## Methods

### Public methods

- [`KucoinTrading$add_order()`](#method-KucoinTrading-add_order)

- [`KucoinTrading$add_order_test()`](#method-KucoinTrading-add_order_test)

- [`KucoinTrading$add_order_batch()`](#method-KucoinTrading-add_order_batch)

- [`KucoinTrading$cancel_order_by_id()`](#method-KucoinTrading-cancel_order_by_id)

- [`KucoinTrading$cancel_order_by_client_oid()`](#method-KucoinTrading-cancel_order_by_client_oid)

- [`KucoinTrading$cancel_partial_order()`](#method-KucoinTrading-cancel_partial_order)

- [`KucoinTrading$cancel_all_by_symbol()`](#method-KucoinTrading-cancel_all_by_symbol)

- [`KucoinTrading$cancel_all()`](#method-KucoinTrading-cancel_all)

- [`KucoinTrading$get_order_by_id()`](#method-KucoinTrading-get_order_by_id)

- [`KucoinTrading$get_order_by_client_oid()`](#method-KucoinTrading-get_order_by_client_oid)

- [`KucoinTrading$get_fills()`](#method-KucoinTrading-get_fills)

- [`KucoinTrading$get_symbols_with_open_orders()`](#method-KucoinTrading-get_symbols_with_open_orders)

- [`KucoinTrading$get_open_orders()`](#method-KucoinTrading-get_open_orders)

- [`KucoinTrading$get_closed_orders()`](#method-KucoinTrading-get_closed_orders)

- [`KucoinTrading$add_order_sync()`](#method-KucoinTrading-add_order_sync)

- [`KucoinTrading$add_order_batch_sync()`](#method-KucoinTrading-add_order_batch_sync)

- [`KucoinTrading$cancel_order_by_id_sync()`](#method-KucoinTrading-cancel_order_by_id_sync)

- [`KucoinTrading$cancel_order_by_client_oid_sync()`](#method-KucoinTrading-cancel_order_by_client_oid_sync)

- [`KucoinTrading$modify_order()`](#method-KucoinTrading-modify_order)

- [`KucoinTrading$set_dcp()`](#method-KucoinTrading-set_dcp)

- [`KucoinTrading$get_dcp()`](#method-KucoinTrading-get_dcp)

- [`KucoinTrading$clone()`](#method-KucoinTrading-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_order()`

Place an Order

Places a new limit or market order on KuCoin Spot via the HF endpoint.
Parameters are validated by `validate_order_params()` before submission.

#### Workflow

1.  **Validation**: Calls `validate_order_params()` for type-specific
    checks.

2.  **Request**: Authenticated POST with order body.

3.  **Parsing**: Returns `data.table` with `order_id` and `client_oid`.

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders`

#### Official Documentation

[KuCoin Add
Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-order)

Verified: 2026-02-01

#### Automated Trading Usage

- **Limit Orders**: Set `price` and `size` for precise entry/exit
  points.

- **Market Orders**: Use `size` for base-amount or `funds` for
  quote-amount execution.

- **Post-Only**: Set `postOnly = TRUE` to guarantee maker fees (order
  rejected if it would match).

- **Iceberg Orders**: Set `iceberg = TRUE` with `visibleSize` to hide
  large order quantities.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"type":"limit","symbol":"BTC-USDT","side":"buy","price":"50000","size":"0.00001"}'

#### JSON Request

    {
      "type": "limit",
      "symbol": "BTC-USDT",
      "side": "buy",
      "price": "50000",
      "size": "0.00001",
      "clientOid": "5c52e11203aa677f33e493fb",
      "timeInForce": "GTC"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "670fd33bf9406e0007ab3945",
        "clientOid": "5c52e11203aa677f33e493fb"
      }
    }

#### Usage

    KucoinTrading$add_order(
      type,
      symbol,
      side,
      clientOid = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      tags = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL
    )

#### Arguments

- `type`:

  Character; `"limit"` or `"market"`.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

- `side`:

  Character; `"buy"` or `"sell"`.

- `clientOid`:

  Character or NULL; unique client order ID (max 40 chars).

- `price`:

  Numeric or NULL; price for limit orders. Must align with
  `priceIncrement`. Required for limit orders; must NOT be set for
  market orders.

- `size`:

  Numeric or NULL; quantity in base currency. Must align with
  `baseIncrement`. Required for limit orders; optional for market orders
  (mutually exclusive with `funds`).

- `funds`:

  Numeric or NULL; amount in quote currency for market orders. Mutually
  exclusive with `size`. Not applicable for limit orders.

- `stp`:

  Character or NULL; self-trade prevention: `"CN"`, `"CO"`, `"CB"`,
  `"DC"`.

- `tags`:

  Character or NULL; order tag (max 20 ASCII chars).

- `remark`:

  Character or NULL; remarks (max 20 ASCII chars).

- `timeInForce`:

  Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.

- `cancelAfter`:

  Numeric or NULL; auto-cancel seconds (requires `timeInForce = "GTT"`).

- `postOnly`:

  Logical or NULL; if TRUE, order rejected if it would match
  immediately.

- `hidden`:

  Logical or NULL; if TRUE, order hidden from order book.

- `iceberg`:

  Logical or NULL; if TRUE, only `visibleSize` is shown.

- `visibleSize`:

  Numeric or NULL; visible quantity for iceberg orders.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `order_id` (character): KuCoin-assigned order identifier.

- `client_oid` (character): Client-provided order identifier.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()

    # Limit buy order
    order <- trading$add_order(
      type = "limit", symbol = "BTC-USDT", side = "buy",
      price = 50000, size = 0.00001
    )
    print(order$order_id)

    # Market sell order by size
    order <- trading$add_order(
      type = "market", symbol = "BTC-USDT", side = "sell",
      size = 0.00001
    )
    }

------------------------------------------------------------------------

### Method `add_order_test()`

Test Order Placement

Simulates placing an order without execution. Validates all parameters
and authentication exactly as `add_order()`, but no order is actually
created.

#### Workflow

Same as `add_order()` but hits the test endpoint.

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders/test`

#### Official Documentation

[KuCoin Add Order
Test](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-order-test)

Verified: 2026-02-01

#### Automated Trading Usage

- **Parameter Validation**: Verify order parameters are correct before
  live submission.

- **Auth Testing**: Confirm API credentials work for order placement.

- **Integration Testing**: Test your trading pipeline end-to-end without
  risk.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders/test' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"type":"limit","symbol":"BTC-USDT","side":"buy","price":"50000","size":"0.00001"}'

#### JSON Request

    {
      "type": "limit",
      "symbol": "BTC-USDT",
      "side": "buy",
      "price": "50000",
      "size": "0.00001",
      "clientOid": "5c52e11203aa677f33e493fb",
      "timeInForce": "GTC"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "670fd33bf9406e0007ab3945",
        "clientOid": "5c52e11203aa677f33e493fb"
      }
    }

#### Usage

    KucoinTrading$add_order_test(
      type,
      symbol,
      side,
      clientOid = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      tags = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL
    )

#### Arguments

- `type`:

  Character; `"limit"` or `"market"`.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

- `side`:

  Character; `"buy"` or `"sell"`.

- `clientOid`:

  Character or NULL; unique client order ID (max 40 chars).

- `price`:

  Numeric or NULL; price for limit orders.

- `size`:

  Numeric or NULL; quantity in base currency.

- `funds`:

  Numeric or NULL; amount in quote currency for market orders.

- `stp`:

  Character or NULL; self-trade prevention: `"CN"`, `"CO"`, `"CB"`,
  `"DC"`.

- `tags`:

  Character or NULL; order tag (max 20 ASCII chars).

- `remark`:

  Character or NULL; remarks (max 20 ASCII chars).

- `timeInForce`:

  Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.

- `cancelAfter`:

  Numeric or NULL; auto-cancel seconds (requires `timeInForce = "GTT"`).

- `postOnly`:

  Logical or NULL; if TRUE, order rejected if it would match
  immediately.

- `hidden`:

  Logical or NULL; if TRUE, order hidden from order book.

- `iceberg`:

  Logical or NULL; if TRUE, only `visibleSize` is shown.

- `visibleSize`:

  Numeric or NULL; visible quantity for iceberg orders.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with simulated `order_id` and `client_oid`.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    test <- trading$add_order_test(
      type = "limit", symbol = "BTC-USDT", side = "buy",
      price = 50000, size = 0.00001
    )
    print(test)
    }

------------------------------------------------------------------------

### Method `add_order_batch()`

Place Batch Orders

Places up to 20 orders in a single request. Each order is validated
independently. Failed orders return `success = FALSE` with a `fail_msg`.

#### Workflow

1.  **Validation**: Each order in the list is validated via
    `validate_batch_order()`.

2.  **Request**: Authenticated POST with `orderList` body.

3.  **Parsing**: Returns per-order results with success/failure status.

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders/multi`

#### Official Documentation

[KuCoin Batch Add
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-add-orders)

Verified: 2026-02-01

#### Automated Trading Usage

- **Portfolio Rebalancing**: Submit multiple orders across pairs
  simultaneously.

- **Grid Trading**: Place a grid of limit orders at different price
  levels.

- **Error Handling**: Check `success` column to identify and retry
  failed orders.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders/multi' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"orderList":[{"clientOid":"id1","symbol":"BTC-USDT","type":"limit","side":"buy","price":"30000","size":"0.00001"}]}'

#### JSON Request

    {
      "orderList": [
        {
          "clientOid": "id1",
          "symbol": "BTC-USDT",
          "type": "limit",
          "side": "buy",
          "price": "30000",
          "size": "0.00001"
        },
        {
          "clientOid": "id2",
          "symbol": "ETH-USDT",
          "type": "limit",
          "side": "buy",
          "price": "2000",
          "size": "0.001"
        }
      ]
    }

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "orderId": "6710d8336afcdb0007319c27",
          "clientOid": "client order id 12",
          "success": true
        },
        {
          "success": false,
          "failMsg": "The order funds should more then 0.1 USDT."
        }
      ]
    }

#### Usage

    KucoinTrading$add_order_batch(order_list)

#### Arguments

- `order_list`:

  List of named lists; each containing order parameters (`type`,
  `symbol`, `side`, plus optional fields). Maximum 20 orders.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with per-order results:

- `order_id` (character): KuCoin order ID (if successful).

- `client_oid` (character): Client order ID (if provided).

- `success` (logical): Whether the order was placed successfully.

- `fail_msg` (character): Error message (if failed).

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    orders <- trading$add_order_batch(list(
      list(type = "limit", symbol = "BTC-USDT", side = "buy",
           price = "30000", size = "0.00001", clientOid = "order1"),
      list(type = "limit", symbol = "ETH-USDT", side = "buy",
           price = "2000", size = "0.001", clientOid = "order2")
    ))
    print(orders[success == TRUE, .(order_id, client_oid)])
    print(orders[success == FALSE, .(fail_msg)])
    }

------------------------------------------------------------------------

### Method `cancel_order_by_id()`

Cancel Order by Order ID

Cancels a specific spot HF order by its KuCoin-assigned order ID.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders/{orderId}?symbol={symbol}`

#### Official Documentation

[KuCoin Cancel Order By
OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-orderld)

Verified: 2026-02-01

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders/671124f9365ccb00073debd4?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "671124f9365ccb00073debd4"
      }
    }

#### Usage

    KucoinTrading$cancel_order_by_id(orderId, symbol)

#### Arguments

- `orderId`:

  Character; the KuCoin order ID to cancel.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `order_id` (character): Cancelled order ID.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$cancel_order_by_id("671124f9365ccb00073debd4", "BTC-USDT")
    print(result$order_id)
    }

------------------------------------------------------------------------

### Method `cancel_order_by_client_oid()`

Cancel Order by Client OID

Cancels a spot HF order by its client-assigned order ID.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders/client-order/{clientOid}?symbol={symbol}`

#### Official Documentation

[KuCoin Cancel Order By
ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-clientoid)

Verified: 2026-02-01

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders/client-order/myClientOid123?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "clientOid": "myClientOid123"
      }
    }

#### Usage

    KucoinTrading$cancel_order_by_client_oid(clientOid, symbol)

#### Arguments

- `clientOid`:

  Character; client order ID.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `client_oid` (character): Cancelled client order ID.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$cancel_order_by_client_oid("myClientOid123", "BTC-USDT")
    print(result$client_oid)
    }

------------------------------------------------------------------------

### Method `cancel_partial_order()`

Cancel Partial Order

Decreases the quantity of an existing open order without fully
cancelling it.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders/cancel/{orderId}?symbol={symbol}&cancelSize={cancelSize}`

#### Official Documentation

[KuCoin Cancel Partial
Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-partial-order)

Verified: 2026-02-01

#### Automated Trading Usage

- **Position Scaling**: Reduce open order size without losing queue
  priority.

- **Risk Management**: Partially withdraw from a large resting order.

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders/cancel/671124f9365ccb00073debd4?symbol=BTC-USDT&cancelSize=0.00001' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "671124f9365ccb00073debd4",
        "cancelSize": "0.00001"
      }
    }

#### Usage

    KucoinTrading$cancel_partial_order(orderId, symbol, cancelSize)

#### Arguments

- `orderId`:

  Character; order ID.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

- `cancelSize`:

  Numeric; quantity to cancel from the order.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with cancellation result.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$cancel_partial_order(
      "671124f9365ccb00073debd4", "BTC-USDT", cancelSize = 0.00001
    )
    }

------------------------------------------------------------------------

### Method `cancel_all_by_symbol()`

Cancel All Orders by Symbol

Cancels all open HF orders for a specific trading pair.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders?symbol={symbol}`

#### Official Documentation

[KuCoin Cancel All Orders By
Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-all-orders-by-symbol)

Verified: 2026-02-01

#### Automated Trading Usage

- **Emergency Stop**: Cancel all orders for a pair when risk limits are
  breached.

- **Strategy Reset**: Clear all open orders before deploying a new
  strategy.

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": "success"
    }

#### Usage

    KucoinTrading$cancel_all_by_symbol(symbol)

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with column `result` containing the cancellation
response.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    trading$cancel_all_by_symbol("BTC-USDT")
    }

------------------------------------------------------------------------

### Method `cancel_all()`

Cancel All Orders

Cancels all open spot HF orders across all trading pairs.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders/cancelAll`

#### Official Documentation

[KuCoin Cancel All HF
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-all-orders)

Verified: 2026-02-01

#### Automated Trading Usage

- **Emergency Kill Switch**: Cancel everything when a critical error is
  detected.

- **End of Session**: Clear all orders at the end of a trading session.

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders/cancelAll' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "succeedSymbols": ["BTC-USDT", "ETH-USDT"],
        "failedSymbols": []
      }
    }

#### Usage

    KucoinTrading$cancel_all()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `symbol` (character): Trading pair symbol.

- `status` (character): `"succeed"` or `"failed"`.

Returns an empty `data.table` if no orders were open.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$cancel_all()
    print(result[status == "failed"])
    }

------------------------------------------------------------------------

### Method `get_order_by_id()`

Get Order by Order ID

Retrieves full details for a specific order by its KuCoin-assigned ID.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/orders/{orderId}?symbol={symbol}`

#### Official Documentation

[KuCoin Get Order By
OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-order-by-orderld)

Verified: 2026-02-01

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/orders/671124f9365ccb00073debd4?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "671124f9365ccb00073debd4",
        "symbol": "BTC-USDT",
        "opType": "DEAL",
        "type": "limit",
        "side": "buy",
        "price": "50000",
        "size": "0.00001",
        "funds": "0",
        "dealSize": "0.00001",
        "dealFunds": "0.50000",
        "fee": "0.00050000",
        "feeCurrency": "USDT",
        "stp": "",
        "timeInForce": "GTC",
        "postOnly": false,
        "hidden": false,
        "iceberg": false,
        "visibleSize": "0",
        "cancelAfter": 0,
        "channel": "API",
        "clientOid": "5c52e11203aa677f33e493fb",
        "remark": "",
        "tags": "",
        "cancelExist": false,
        "createdAt": 1729176273859,
        "lastUpdatedAt": 1729176273952,
        "tradeType": "TRADE",
        "inOrderBook": false,
        "cancelledSize": "0",
        "cancelledFunds": "0",
        "remainSize": "0",
        "remainFunds": "0",
        "active": false,
        "tax": "0"
      }
    }

#### Usage

    KucoinTrading$get_order_by_id(orderId, symbol = NULL)

#### Arguments

- `orderId`:

  Character; the KuCoin order ID.

- `symbol`:

  Character (optional); trading pair (e.g., `"BTC-USDT"`). Defaults to
  `NULL`.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with full order details including `created_at` and
`last_updated_at` (POSIXct) if timestamps are present.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    order <- trading$get_order_by_id("671124f9365ccb00073debd4", "BTC-USDT")
    print(order)
    }

------------------------------------------------------------------------

### Method `get_order_by_client_oid()`

Get Order by Client OID

Retrieves full details for a specific order by its client-assigned ID.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/orders/client-order/{clientOid}?symbol={symbol}`

#### Official Documentation

[KuCoin Get Order By
ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-order-by-clientoid)

Verified: 2026-02-01

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/orders/client-order/myClientOid123?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "671124f9365ccb00073debd4",
        "symbol": "BTC-USDT",
        "opType": "DEAL",
        "type": "limit",
        "side": "buy",
        "price": "50000",
        "size": "0.00001",
        "funds": "0",
        "dealSize": "0.00001",
        "dealFunds": "0.50000",
        "fee": "0.00050000",
        "feeCurrency": "USDT",
        "stp": "",
        "timeInForce": "GTC",
        "postOnly": false,
        "hidden": false,
        "iceberg": false,
        "visibleSize": "0",
        "cancelAfter": 0,
        "channel": "API",
        "clientOid": "myClientOid123",
        "remark": "",
        "tags": "",
        "cancelExist": false,
        "createdAt": 1729176273859,
        "lastUpdatedAt": 1729176273952,
        "tradeType": "TRADE",
        "inOrderBook": false,
        "cancelledSize": "0",
        "cancelledFunds": "0",
        "remainSize": "0",
        "remainFunds": "0",
        "active": false,
        "tax": "0"
      }
    }

#### Usage

    KucoinTrading$get_order_by_client_oid(clientOid, symbol)

#### Arguments

- `clientOid`:

  Character; client order ID.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with full order details including `created_at` and
`last_updated_at` (POSIXct) columns.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    order <- trading$get_order_by_client_oid("myClientOid123", "BTC-USDT")
    print(order)
    }

------------------------------------------------------------------------

### Method `get_fills()`

Get Trade Fills

Retrieves execution history for filled or partially filled HF orders.
Returns detailed fill information including fees, liquidity type, and
trade IDs.

#### Workflow

1.  **Request**: Authenticated GET with symbol (required) and optional
    filters.

2.  **Parsing**: Extracts `items` array, converts to `data.table`.

3.  **Timestamp Conversion**: Coerces `created_at` (ms) to POSIXct
    in-place.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/fills`

#### Official Documentation

[KuCoin Get Trade
History](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-trade-history)

Verified: 2026-02-01

#### Automated Trading Usage

- **P&L Tracking**: Use `price`, `size`, `fee`, and `fee_currency` for
  profit calculations.

- **Fill Analysis**: Check `liquidity` (maker/taker) to optimise
  execution strategy.

- **Audit Trail**: Build comprehensive trade logs with `trade_id` for
  reconciliation.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/fills?symbol=BTC-USDT&limit=100' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "items": [
          {
            "id": 19814995255305,
            "orderId": "6717422bd51c29000775ea03",
            "counterOrderId": "67174228135f9e000709da8c",
            "tradeId": 11029373945659392,
            "symbol": "BTC-USDT",
            "side": "buy",
            "liquidity": "taker",
            "type": "limit",
            "forceTaker": false,
            "price": "67717.6",
            "size": "0.00001",
            "funds": "0.677176",
            "fee": "0.000677176",
            "feeRate": "0.001",
            "feeCurrency": "USDT",
            "stop": "",
            "tradeType": "TRADE",
            "taxRate": "0",
            "tax": "0",
            "createdAt": 1729577515473
          }
        ],
        "lastId": 19814995255305
      }
    }

#### Usage

    KucoinTrading$get_fills(
      symbol = NULL,
      orderId = NULL,
      side = NULL,
      type = NULL,
      lastId = NULL,
      limit = NULL,
      startAt = NULL,
      endAt = NULL
    )

#### Arguments

- `symbol`:

  Character or NULL; trading pair (e.g., `"BTC-USDT"`). If NULL, returns
  fills across all symbols.

- `orderId`:

  Character or NULL; filter by specific order ID.

- `side`:

  Character or NULL; `"buy"` or `"sell"`.

- `type`:

  Character or NULL; `"limit"` or `"market"`.

- `lastId`:

  Character or NULL; pagination cursor for fetching next page.

- `limit`:

  Integer or NULL; results per page (default 100, max 200).

- `startAt`:

  Integer or NULL; start timestamp in milliseconds.

- `endAt`:

  Integer or NULL; end timestamp in milliseconds.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `id` (numeric): Fill identifier.

- `order_id` (character): Parent order ID.

- `counter_order_id` (character): Counterparty order ID.

- `trade_id` (numeric): Trade identifier.

- `symbol` (character): Trading pair.

- `side` (character): Trade direction.

- `liquidity` (character): `"maker"` or `"taker"`.

- `type` (character): Order type.

- `price` (character): Fill price.

- `size` (character): Fill size.

- `funds` (character): Fill value in quote currency.

- `fee` (character): Fee charged.

- `fee_rate` (character): Fee rate applied.

- `fee_currency` (character): Currency of fee.

- `created_at` (POSIXct): Creation datetime (coerced from epoch
  milliseconds).

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    fills <- trading$get_fills("BTC-USDT")
    # Get all fills across symbols
    all_fills <- trading$get_fills()
    }

------------------------------------------------------------------------

### Method `get_symbols_with_open_orders()`

Get Symbols with Open Orders

Returns a list of symbols that have at least one active HF order. Useful
for determining which pairs need attention.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/orders/active/symbols`

#### Official Documentation

[KuCoin Get Symbols With Open
Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-symbols-with-open-order)

Verified: 2026-02-01

#### Automated Trading Usage

- **Order Monitoring**: Quickly check which symbols have active orders.

- **Cleanup**: Iterate over symbols to cancel or manage outstanding
  orders.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/orders/active/symbols' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "symbols": ["BTC-USDT", "ETH-USDT"]
      }
    }

#### Usage

    KucoinTrading$get_symbols_with_open_orders()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with column:

- `symbols` (character): Trading pairs with open orders.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    active <- trading$get_symbols_with_open_orders()
    print(active$symbols)
    }

------------------------------------------------------------------------

### Method `get_open_orders()`

Get Open Orders

Retrieves all currently open HF orders for a specific symbol.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/orders/active?symbol={symbol}`

#### Official Documentation

[KuCoin Get Open
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-open-orders)

Verified: 2026-02-01

#### Automated Trading Usage

- **Order Book Reconciliation**: Compare your open orders against
  expected state.

- **Stale Order Detection**: Identify and cancel orders that have been
  open too long.

- **Position Management**: Track total open exposure per symbol.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/orders/active?symbol=BTC-USDT' \
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
          "id": "671124f9365ccb00073debd4",
          "symbol": "BTC-USDT",
          "opType": "DEAL",
          "type": "limit",
          "side": "buy",
          "price": "50000",
          "size": "0.00001",
          "funds": "0",
          "dealSize": "0",
          "dealFunds": "0",
          "fee": "0",
          "feeCurrency": "USDT",
          "stp": "",
          "timeInForce": "GTC",
          "postOnly": false,
          "hidden": false,
          "iceberg": false,
          "visibleSize": "0",
          "cancelAfter": 0,
          "channel": "API",
          "clientOid": "5c52e11203aa677f33e493fb",
          "remark": "",
          "tags": "",
          "cancelExist": false,
          "createdAt": 1729176273859,
          "lastUpdatedAt": 1729176273952,
          "tradeType": "TRADE",
          "inOrderBook": true,
          "cancelledSize": "0",
          "cancelledFunds": "0",
          "remainSize": "0.00001",
          "remainFunds": "0",
          "active": true,
          "tax": "0"
        }
      ]
    }

#### Usage

    KucoinTrading$get_open_orders(symbol = NULL)

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`). **Required** by the API.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with open order details including `created_at`
(POSIXct).

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    open_orders <- trading$get_open_orders("BTC-USDT")
    }

------------------------------------------------------------------------

### Method `get_closed_orders()`

Get Closed Orders

Retrieves recently closed (filled or cancelled) HF orders for a symbol.
Supports filtering by side, type, and time range.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/orders/done`

#### Official Documentation

[KuCoin Get Closed
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-closed-orders)

Verified: 2026-02-01

#### Automated Trading Usage

- **Order History**: Build trade logs from completed orders.

- **Fill Rate Analysis**: Calculate fill rates across order types and
  time periods.

- **Strategy Evaluation**: Review historical order outcomes for strategy
  tuning.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/orders/done?symbol=BTC-USDT&limit=50' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "lastId": 19814995255305,
        "items": [
          {
            "id": "671124f9365ccb00073debd4",
            "symbol": "BTC-USDT",
            "opType": "DEAL",
            "type": "limit",
            "side": "buy",
            "price": "50000",
            "size": "0.00001",
            "funds": "0",
            "dealSize": "0.00001",
            "dealFunds": "0.50000",
            "fee": "0.00050000",
            "feeCurrency": "USDT",
            "stp": "",
            "timeInForce": "GTC",
            "postOnly": false,
            "hidden": false,
            "iceberg": false,
            "visibleSize": "0",
            "cancelAfter": 0,
            "channel": "API",
            "clientOid": "5c52e11203aa677f33e493fb",
            "remark": "",
            "tags": "",
            "cancelExist": false,
            "createdAt": 1729176273859,
            "lastUpdatedAt": 1729176273952,
            "tradeType": "TRADE",
            "inOrderBook": false,
            "cancelledSize": "0",
            "cancelledFunds": "0",
            "remainSize": "0",
            "remainFunds": "0",
            "active": false,
            "tax": "0"
          }
        ]
      }
    }

#### Usage

    KucoinTrading$get_closed_orders(
      symbol = NULL,
      side = NULL,
      type = NULL,
      startAt = NULL,
      endAt = NULL,
      limit = NULL,
      lastId = NULL
    )

#### Arguments

- `symbol`:

  Character or NULL; trading pair (e.g., `"BTC-USDT"`). If NULL, returns
  closed orders across all symbols.

- `side`:

  Character or NULL; `"buy"` or `"sell"`.

- `type`:

  Character or NULL; `"limit"` or `"market"`.

- `startAt`:

  Integer or NULL; start timestamp in milliseconds.

- `endAt`:

  Integer or NULL; end timestamp in milliseconds.

- `limit`:

  Integer or NULL; results per page (max 200).

- `lastId`:

  Character or NULL; pagination cursor.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with closed order details including `created_at`
(POSIXct).

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    closed <- trading$get_closed_orders("BTC-USDT", limit = 20)
    # Get all closed orders across symbols
    all_closed <- trading$get_closed_orders()
    }

------------------------------------------------------------------------

### Method `add_order_sync()`

Place an Order (Synchronous Return)

Places a new limit or market order and waits for the matching engine to
process it before returning. Returns the fill result in one round trip,
eliminating the need to poll `get_order_by_id()`.

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders/sync`

#### Official Documentation

[KuCoin Add Order
Sync](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-order-sync)

Verified: 2026-02-03

#### Automated Trading Usage

- **Low-Latency Fills**: Get fill result in a single round trip instead
  of polling.

- **Market Orders**: Ideal for market orders where immediate fill
  confirmation is critical.

- **Race-Free**: No gap between order placement and status check.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders/sync' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"type":"limit","symbol":"BTC-USDT","side":"buy","price":"50000","size":"0.00001"}'

#### JSON Request

    {
      "type": "limit",
      "symbol": "BTC-USDT",
      "side": "buy",
      "price": "50000",
      "size": "0.00001",
      "clientOid": "5c52e11203aa677f33e493fb"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "670fd33bf9406e0007ab3945",
        "orderTime": 1729176273859,
        "originSize": "0.00001",
        "dealSize": "0.00001",
        "remainSize": "0",
        "canceledSize": "0",
        "status": "done",
        "matchTime": 1729176273952
      }
    }

#### Usage

    KucoinTrading$add_order_sync(
      type,
      symbol,
      side,
      clientOid = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      tags = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL
    )

#### Arguments

- `type`:

  Character; `"limit"` or `"market"`.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

- `side`:

  Character; `"buy"` or `"sell"`.

- `clientOid`:

  Character or NULL; unique client order ID (max 40 chars).

- `price`:

  Numeric or NULL; price for limit orders.

- `size`:

  Numeric or NULL; quantity in base currency.

- `funds`:

  Numeric or NULL; amount in quote currency for market orders.

- `stp`:

  Character or NULL; self-trade prevention: `"CN"`, `"CO"`, `"CB"`,
  `"DC"`.

- `tags`:

  Character or NULL; order tag (max 20 ASCII chars).

- `remark`:

  Character or NULL; remarks (max 20 ASCII chars).

- `timeInForce`:

  Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.

- `cancelAfter`:

  Numeric or NULL; auto-cancel seconds (requires `timeInForce = "GTT"`).

- `postOnly`:

  Logical or NULL; if TRUE, order rejected if it would match
  immediately.

- `hidden`:

  Logical or NULL; if TRUE, order hidden from order book.

- `iceberg`:

  Logical or NULL; if TRUE, only `visibleSize` is shown.

- `visibleSize`:

  Numeric or NULL; visible quantity for iceberg orders.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `order_id` (character): KuCoin-assigned order identifier.

- `client_oid` (character): Client-provided order identifier (NA if not
  supplied).

- `order_time` (numeric): Order placement time in milliseconds.

- `origin_size` (character): Original order size.

- `deal_size` (character): Filled size.

- `remain_size` (character): Remaining unfilled size.

- `canceled_size` (character): Cancelled size.

- `status` (character): `"open"` or `"done"`.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    order <- trading$add_order_sync(
      type = "limit", symbol = "BTC-USDT", side = "buy",
      price = 50000, size = 0.00001
    )
    cat("Status:", order$status, "Filled:", order$deal_size, "\n")
    }

------------------------------------------------------------------------

### Method `add_order_batch_sync()`

Place Batch Orders (Synchronous Return)

Places up to 20 orders in a single request and waits for the matching
engine to process them before returning. Returns per-order fill results.

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders/multi/sync`

#### Official Documentation

[KuCoin Batch Add Orders
Sync](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-add-orders-sync)

Verified: 2026-02-03

#### Automated Trading Usage

- **Grid Trading**: Place a grid of limit orders and get immediate fill
  status for all.

- **Rebalancing**: Submit multiple orders with guaranteed fill
  confirmation.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders/multi/sync' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"orderList":[{"clientOid":"id1","symbol":"BTC-USDT","type":"limit","side":"buy","price":"30000","size":"0.00001"}]}'

#### JSON Request

    {
      "orderList": [
        {
          "clientOid": "id1",
          "symbol": "BTC-USDT",
          "type": "limit",
          "side": "buy",
          "price": "30000",
          "size": "0.00001"
        },
        {
          "clientOid": "id2",
          "symbol": "ETH-USDT",
          "type": "limit",
          "side": "buy",
          "price": "2000",
          "size": "0.001"
        }
      ]
    }

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "orderId": "6710d8336afcdb0007319c27",
          "clientOid": "id1",
          "success": true,
          "orderTime": 1729176273859,
          "originSize": "0.00001",
          "dealSize": "0.00001",
          "remainSize": "0",
          "canceledSize": "0",
          "status": "done"
        },
        {
          "orderId": "6710d8336afcdb0007319c28",
          "clientOid": "id2",
          "success": true,
          "orderTime": 1729176273860,
          "originSize": "0.001",
          "dealSize": "0",
          "remainSize": "0.001",
          "canceledSize": "0",
          "status": "open"
        }
      ]
    }

#### Usage

    KucoinTrading$add_order_batch_sync(order_list)

#### Arguments

- `order_list`:

  List of named lists; each containing order parameters. Maximum 20
  orders.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with per-order results:

- `order_id` (character): KuCoin-assigned order identifier.

- `client_oid` (character): Client-provided order identifier (NA if not
  supplied).

- `success` (logical): Whether the order was accepted.

- `status` (character): Fill status.

- `deal_size` (character): Filled quantity.

- `remain_size` (character): Remaining unfilled quantity.

- `canceled_size` (character): Cancelled quantity.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    orders <- trading$add_order_batch_sync(list(
      list(type = "limit", symbol = "BTC-USDT", side = "buy",
           price = "30000", size = "0.00001", clientOid = "order1"),
      list(type = "limit", symbol = "ETH-USDT", side = "buy",
           price = "2000", size = "0.001", clientOid = "order2")
    ))
    print(orders[success == TRUE, .(order_id, status, deal_size)])
    }

------------------------------------------------------------------------

### Method `cancel_order_by_id_sync()`

Cancel Order by Order ID (Synchronous Return)

Cancels an order and waits for the cancellation to complete before
returning. Returns the final order state including fill and cancellation
sizes.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders/sync/{orderId}?symbol={symbol}`

#### Official Documentation

[KuCoin Cancel Order By OrderId
Sync](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-orderld-sync)

Verified: 2026-02-03

#### Automated Trading Usage

- **Atomic Cancel**: Confirm cancellation and get final fill state in
  one call.

- **Partial Fill Detection**: Check `deal_size` to know if any fills
  occurred before cancellation.

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders/sync/671128ee365ccb0007534d45?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "671128ee365ccb0007534d45",
        "originSize": "0.00001",
        "dealSize": "0",
        "remainSize": "0",
        "canceledSize": "0.00001",
        "status": "done"
      }
    }

#### Usage

    KucoinTrading$cancel_order_by_id_sync(orderId, symbol)

#### Arguments

- `orderId`:

  Character; the KuCoin order ID to cancel.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `order_id` (character): Order ID.

- `origin_size` (character): Original order size.

- `deal_size` (character): Filled size.

- `remain_size` (character): Remaining size.

- `canceled_size` (character): Cancelled size.

- `status` (character): `"open"` or `"done"`.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$cancel_order_by_id_sync("671128ee365ccb0007534d45", "BTC-USDT")
    cat("Status:", result$status, "Cancelled:", result$canceled_size, "\n")
    }

------------------------------------------------------------------------

### Method `cancel_order_by_client_oid_sync()`

Cancel Order by Client OID (Synchronous Return)

Cancels an order by client OID and waits for completion before
returning.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v1/hf/orders/sync/client-order/{clientOid}?symbol={symbol}`

#### Official Documentation

[KuCoin Cancel Order By ClientOid
Sync](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-clientoid-sync)

Verified: 2026-02-03

#### curl

    curl --location --request DELETE \
      'https://api.kucoin.com/api/v1/hf/orders/sync/client-order/myClientOid123?symbol=BTC-USDT' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "671128ee365ccb0007534d45",
        "clientOid": "myClientOid123",
        "originSize": "0.00001",
        "dealSize": "0",
        "remainSize": "0",
        "canceledSize": "0.00001",
        "status": "done"
      }
    }

#### Usage

    KucoinTrading$cancel_order_by_client_oid_sync(clientOid, symbol)

#### Arguments

- `clientOid`:

  Character; client order ID.

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`).

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `client_oid` (character): Client order ID.

- `origin_size` (character): Original order size.

- `deal_size` (character): Filled size.

- `remain_size` (character): Remaining size.

- `canceled_size` (character): Cancelled size.

- `status` (character): `"open"` or `"done"`.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$cancel_order_by_client_oid_sync("myClientOid123", "BTC-USDT")
    cat("Status:", result$status, "\n")
    }

------------------------------------------------------------------------

### Method `modify_order()`

Modify Order

Amends the price and/or size of an existing open order atomically.
Internally, KuCoin cancels the original order and places a replacement.
If the new size is less than the already filled quantity, the order is
simply cancelled with no replacement.

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders/alter`

#### Official Documentation

[KuCoin Modify
Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/modify-order)

Verified: 2026-02-03

#### Automated Trading Usage

- **Price Adjustment**: Move a resting limit order to a new price level
  without cancel+replace gap.

- **Size Adjustment**: Increase or decrease order size atomically.

- **Trailing Logic**: Continuously adjust price as the market moves.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders/alter' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"symbol":"BTC-USDT","orderId":"671124f9365ccb00073debd4","newPrice":"51000"}'

#### JSON Request

    {
      "symbol": "BTC-USDT",
      "orderId": "671124f9365ccb00073debd4",
      "newPrice": "51000",
      "newSize": "0.00002"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "newOrderId": "671124f9365ccb00073debff"
      }
    }

#### Usage

    KucoinTrading$modify_order(
      symbol,
      orderId = NULL,
      clientOid = NULL,
      newPrice = NULL,
      newSize = NULL
    )

#### Arguments

- `symbol`:

  Character; trading pair (e.g., `"BTC-USDT"`). Required.

- `orderId`:

  Character or NULL; KuCoin order ID. At least one of `orderId` or
  `clientOid` required.

- `clientOid`:

  Character or NULL; client order ID. At least one of `orderId` or
  `clientOid` required.

- `newPrice`:

  Character or NULL; new order price. At least one of `newPrice` or
  `newSize` required.

- `newSize`:

  Character or NULL; new order size. At least one of `newPrice` or
  `newSize` required.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `new_order_id` (character): The replacement order's ID.

- `client_oid` (character): The original client order ID.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    result <- trading$modify_order(
      symbol = "BTC-USDT",
      orderId = "671124f9365ccb00073debd4",
      newPrice = "51000"
    )
    cat("New order ID:", result$new_order_id, "\n")
    }

------------------------------------------------------------------------

### Method `set_dcp()`

Set DCP (Dead Connection Protection)

Configures KuCoin's dead-man's switch. If no user requests are received
within the timeout window, KuCoin automatically cancels all open HF
orders for the specified symbols (or all symbols if none specified).

#### API Endpoint

`POST https://api.kucoin.com/api/v1/hf/orders/dead-cancel-all`

#### Official Documentation

[KuCoin Set
DCP](https://www.kucoin.com/docs-new/rest/spot-trading/orders/set-dcp)

Verified: 2026-02-03

#### Automated Trading Usage

- **Crash Safety**: Heartbeat every N seconds; if bot crashes, KuCoin
  cancels all orders.

- **Network Failsafe**: Protects against network outages leaving stale
  orders.

- **Selective Protection**: Specify symbols to protect only active
  trading pairs.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v1/hf/orders/dead-cancel-all' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"timeout":30,"symbols":"BTC-USDT"}'

#### JSON Request

    {
      "timeout": 30,
      "symbols": "BTC-USDT,ETH-USDT"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currentTime": 1729176273,
        "triggerTime": 1729176303
      }
    }

#### Usage

    KucoinTrading$set_dcp(timeout, symbols = NULL)

#### Arguments

- `timeout`:

  Integer; trigger duration in seconds. Use `-1` to disable, or `5` to
  `86400`.

- `symbols`:

  Character or NULL; comma-separated trading pairs (max 50). Empty or
  NULL applies to all pairs.

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `current_time` (integer): Current server time in seconds.

- `trigger_time` (integer): When cancellation will trigger, in seconds.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    # Enable DCP with 30-second timeout for BTC-USDT
    result <- trading$set_dcp(timeout = 30, symbols = "BTC-USDT")
    cat("Trigger at:", result$trigger_time, "\n")

    # Disable DCP
    trading$set_dcp(timeout = -1)
    }

------------------------------------------------------------------------

### Method `get_dcp()`

Get DCP Settings

Queries the current Dead Connection Protection (dead-man's switch)
configuration. Returns an empty `data.table` if DCP is not configured.

#### API Endpoint

`GET https://api.kucoin.com/api/v1/hf/orders/dead-cancel-all/query`

#### Official Documentation

[KuCoin Get
DCP](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-dcp)

Verified: 2026-02-03

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v1/hf/orders/dead-cancel-all/query' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "timeout": 30,
        "symbols": "BTC-USDT,ETH-USDT",
        "currentTime": 1729176273,
        "triggerTime": 1729176303
      }
    }

#### Usage

    KucoinTrading$get_dcp()

#### Returns

`data.table` (or `promise<data.table>` if constructed with
`async = TRUE`) with columns:

- `timeout` (integer): Auto-cancel trigger time in seconds. `-1` if
  unset.

- `symbols` (character): Comma-separated trading pairs, or empty for
  all.

- `current_time` (integer): Current server time in seconds.

- `trigger_time` (integer): When cancellation will trigger.

#### Examples

    \dontrun{
    trading <- KucoinTrading$new()
    dcp <- trading$get_dcp()
    if (nrow(dcp) > 0) {
      cat("DCP timeout:", dcp$timeout, "seconds\n")
      cat("Symbols:", dcp$symbols, "\n")
    }
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinTrading$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
trading <- KucoinTrading$new()
order <- trading$add_order_test(type = "limit", symbol = "BTC-USDT",
                                 side = "buy", price = 50000, size = 0.0001)
print(order)

# Asynchronous
trading_async <- KucoinTrading$new(async = TRUE)
main <- coro::async(function() {
  order <- await(trading_async$add_order_test(
    type = "limit", symbol = "BTC-USDT", side = "buy",
    price = 50000, size = 0.0001
  ))
  print(order)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinTrading$add_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()

# Limit buy order
order <- trading$add_order(
  type = "limit", symbol = "BTC-USDT", side = "buy",
  price = 50000, size = 0.00001
)
print(order$order_id)

# Market sell order by size
order <- trading$add_order(
  type = "market", symbol = "BTC-USDT", side = "sell",
  size = 0.00001
)
} # }

## ------------------------------------------------
## Method `KucoinTrading$add_order_test`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
test <- trading$add_order_test(
  type = "limit", symbol = "BTC-USDT", side = "buy",
  price = 50000, size = 0.00001
)
print(test)
} # }

## ------------------------------------------------
## Method `KucoinTrading$add_order_batch`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
orders <- trading$add_order_batch(list(
  list(type = "limit", symbol = "BTC-USDT", side = "buy",
       price = "30000", size = "0.00001", clientOid = "order1"),
  list(type = "limit", symbol = "ETH-USDT", side = "buy",
       price = "2000", size = "0.001", clientOid = "order2")
))
print(orders[success == TRUE, .(order_id, client_oid)])
print(orders[success == FALSE, .(fail_msg)])
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_order_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$cancel_order_by_id("671124f9365ccb00073debd4", "BTC-USDT")
print(result$order_id)
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_order_by_client_oid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$cancel_order_by_client_oid("myClientOid123", "BTC-USDT")
print(result$client_oid)
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_partial_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$cancel_partial_order(
  "671124f9365ccb00073debd4", "BTC-USDT", cancelSize = 0.00001
)
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_all_by_symbol`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
trading$cancel_all_by_symbol("BTC-USDT")
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_all`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$cancel_all()
print(result[status == "failed"])
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_order_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
order <- trading$get_order_by_id("671124f9365ccb00073debd4", "BTC-USDT")
print(order)
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_order_by_client_oid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
order <- trading$get_order_by_client_oid("myClientOid123", "BTC-USDT")
print(order)
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_fills`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
fills <- trading$get_fills("BTC-USDT")
# Get all fills across symbols
all_fills <- trading$get_fills()
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_symbols_with_open_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
active <- trading$get_symbols_with_open_orders()
print(active$symbols)
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_open_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
open_orders <- trading$get_open_orders("BTC-USDT")
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_closed_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
closed <- trading$get_closed_orders("BTC-USDT", limit = 20)
# Get all closed orders across symbols
all_closed <- trading$get_closed_orders()
} # }

## ------------------------------------------------
## Method `KucoinTrading$add_order_sync`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
order <- trading$add_order_sync(
  type = "limit", symbol = "BTC-USDT", side = "buy",
  price = 50000, size = 0.00001
)
cat("Status:", order$status, "Filled:", order$deal_size, "\n")
} # }

## ------------------------------------------------
## Method `KucoinTrading$add_order_batch_sync`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
orders <- trading$add_order_batch_sync(list(
  list(type = "limit", symbol = "BTC-USDT", side = "buy",
       price = "30000", size = "0.00001", clientOid = "order1"),
  list(type = "limit", symbol = "ETH-USDT", side = "buy",
       price = "2000", size = "0.001", clientOid = "order2")
))
print(orders[success == TRUE, .(order_id, status, deal_size)])
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_order_by_id_sync`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$cancel_order_by_id_sync("671128ee365ccb0007534d45", "BTC-USDT")
cat("Status:", result$status, "Cancelled:", result$canceled_size, "\n")
} # }

## ------------------------------------------------
## Method `KucoinTrading$cancel_order_by_client_oid_sync`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$cancel_order_by_client_oid_sync("myClientOid123", "BTC-USDT")
cat("Status:", result$status, "\n")
} # }

## ------------------------------------------------
## Method `KucoinTrading$modify_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
result <- trading$modify_order(
  symbol = "BTC-USDT",
  orderId = "671124f9365ccb00073debd4",
  newPrice = "51000"
)
cat("New order ID:", result$new_order_id, "\n")
} # }

## ------------------------------------------------
## Method `KucoinTrading$set_dcp`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
# Enable DCP with 30-second timeout for BTC-USDT
result <- trading$set_dcp(timeout = 30, symbols = "BTC-USDT")
cat("Trigger at:", result$trigger_time, "\n")

# Disable DCP
trading$set_dcp(timeout = -1)
} # }

## ------------------------------------------------
## Method `KucoinTrading$get_dcp`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- KucoinTrading$new()
dcp <- trading$get_dcp()
if (nrow(dcp) > 0) {
  cat("DCP timeout:", dcp$timeout, "seconds\n")
  cat("Symbols:", dcp$symbols, "\n")
}
} # }
```
