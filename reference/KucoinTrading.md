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

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
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

Verified: 2026-05-23

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
      client_order_id = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      tags = NULL,
      remark = NULL,
      time_in_force = NULL,
      cancel_after = NULL,
      post_only = NULL,
      hidden = NULL,
      iceberg = NULL,
      visible_size = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) `"limit"` or `"market"`.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

- `side`:

  (scalar\<character\>) `"buy"` or `"sell"`.

- `client_order_id`:

  (scalar\<character\> \| NULL) unique client order ID (max 40 chars).

- `price`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) price for limit
  orders. Must align with `priceIncrement`. Required for limit orders;
  must NOT be set for market orders.

- `size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) quantity in base
  currency. Must align with `baseIncrement`. Required for limit orders;
  optional for market orders (mutually exclusive with `funds`).

- `funds`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) amount in quote
  currency for market orders. Mutually exclusive with `size`. Not
  applicable for limit orders.

- `stp`:

  (scalar\<character\> \| NULL) self-trade prevention: `"CN"`, `"CO"`,
  `"CB"`, `"DC"`.

- `tags`:

  (scalar\<character\> \| NULL) order tag (max 20 ASCII chars).

- `remark`:

  (scalar\<character\> \| NULL) remarks (max 20 ASCII chars).

- `time_in_force`:

  (scalar\<character\> \| NULL) `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.

- `cancel_after`:

  (scalar\<numeric\> \| NULL) auto-cancel seconds (requires
  `timeInForce = "GTT"`).

- `post_only`:

  (scalar\<logical\> \| NULL) if TRUE, order rejected if it would match
  immediately.

- `hidden`:

  (scalar\<logical\> \| NULL) if TRUE, order hidden from order book.

- `iceberg`:

  (scalar\<logical\> \| NULL) if TRUE, only `visibleSize` is shown.

- `visible_size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) visible quantity
  for iceberg orders.

#### Returns

(data.table \| promise\<data.table\>) one row giving the KuCoin-assigned
order identifier and the client-provided order identifier:

- order_id (character) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

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

Verified: 2026-05-23

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
      client_order_id = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      tags = NULL,
      remark = NULL,
      time_in_force = NULL,
      cancel_after = NULL,
      post_only = NULL,
      hidden = NULL,
      iceberg = NULL,
      visible_size = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) `"limit"` or `"market"`.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

- `side`:

  (scalar\<character\>) `"buy"` or `"sell"`.

- `client_order_id`:

  (scalar\<character\> \| NULL) unique client order ID (max 40 chars).

- `price`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) price for limit
  orders.

- `size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) quantity in base
  currency.

- `funds`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) amount in quote
  currency for market orders.

- `stp`:

  (scalar\<character\> \| NULL) self-trade prevention: `"CN"`, `"CO"`,
  `"CB"`, `"DC"`.

- `tags`:

  (scalar\<character\> \| NULL) order tag (max 20 ASCII chars).

- `remark`:

  (scalar\<character\> \| NULL) remarks (max 20 ASCII chars).

- `time_in_force`:

  (scalar\<character\> \| NULL) `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.

- `cancel_after`:

  (scalar\<numeric\> \| NULL) auto-cancel seconds (requires
  `timeInForce = "GTT"`).

- `post_only`:

  (scalar\<logical\> \| NULL) if TRUE, order rejected if it would match
  immediately.

- `hidden`:

  (scalar\<logical\> \| NULL) if TRUE, order hidden from order book.

- `iceberg`:

  (scalar\<logical\> \| NULL) if TRUE, only `visibleSize` is shown.

- `visible_size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) visible quantity
  for iceberg orders.

#### Returns

(data.table \| promise\<data.table\>) one row giving the simulated order
identifier and the client-provided order identifier:

- order_id (character) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

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

Verified: 2026-05-23

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
      --data-raw \
      '{"orderList":[{"clientOid":"id1","symbol":"BTC-USDT","type":"limit","side":"buy","price":"30000",
      "size":"0.00001"}]}'

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

  (list) list of named lists; each containing order parameters (`type`,
  `symbol`, `side`, plus optional fields). Maximum 20 orders.

#### Returns

(data.table \| promise\<data.table\>) one row per order giving the
KuCoin order ID, client order ID, the success flag, and any failure
message:

- order_id (character \| NA) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

- success (logical) whether the order succeeded.

- fail_msg (character \| NA) the failure message.

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

KuCoin Cancel Order By OrderId:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-orderld>

Verified: 2026-05-23

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

    KucoinTrading$cancel_order_by_id(order_id, symbol)

#### Arguments

- `order_id`:

  (scalar\<character\>) the KuCoin order ID to cancel.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the cancelled order
ID:

- order_id (character) the system order identifier.

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

KuCoin Cancel Order By ClientOid:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-clientoid>

Verified: 2026-05-23

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

    KucoinTrading$cancel_order_by_client_oid(client_order_id, symbol)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) client order ID.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the cancelled
client order ID:

- client_oid (character \| NA) the client-supplied order identifier.

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

Verified: 2026-05-23

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

    KucoinTrading$cancel_partial_order(order_id, symbol, cancel_size)

#### Arguments

- `order_id`:

  (scalar\<character\>) order ID.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

- `cancel_size`:

  (scalar\<numeric\> \| scalar\<character\>) quantity to cancel from the
  order.

#### Returns

(data.table \| promise\<data.table\>) one row giving the cancellation
result:

- order_id (character) the system order identifier.

- cancel_size (numeric \| NA) the cancelled size.

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

KuCoin Cancel All Orders By Symbol:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-all-orders-by-symbol>

Verified: 2026-05-23

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

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the cancellation
response:

- result (character) the KuCoin response string, e.g. `"success"`.

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

Verified: 2026-05-23

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

(data.table \| promise\<data.table\>) one row per cancelled symbol; an
empty (but typed) data.table if no orders were open:

- symbol (character) the trading pair, e.g. `"BTC-USDT"`.

- status (character) per-symbol outcome, `"succeed"` or `"failed"`.

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

Verified: 2026-05-23

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

    KucoinTrading$get_order_by_id(order_id, symbol = NULL)

#### Arguments

- `order_id`:

  (scalar\<character\>) the KuCoin order ID.

- `symbol`:

  (scalar\<character\> \| NULL) trading pair (e.g., `"BTC-USDT"`).
  Defaults to `NULL`.

#### Returns

(data.table \| promise\<data.table\>) one row of full order details,
including the creation and last-updated datetimes (POSIXct) when
timestamps are present:

- order_id (character) the system order identifier.

- symbol (character) the trading pair symbol.

- side (character) the order side.

- type (character) the type.

- price (numeric \| NA) the price.

- size (numeric \| NA) the size.

- created_at (POSIXct) the created at (UTC).

- last_updated_at (POSIXct) the last updated at (UTC).

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

Verified: 2026-05-23

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

    KucoinTrading$get_order_by_client_oid(client_order_id, symbol)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) client order ID.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row of full order details,
including the creation and last-updated datetimes (POSIXct):

- client_oid (character \| NA) the client-supplied order identifier.

- symbol (character) the trading pair symbol.

- side (character) the order side.

- created_at (POSIXct) the created at (UTC).

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

Verified: 2026-05-23

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
      order_id = NULL,
      side = NULL,
      type = NULL,
      last_id = NULL,
      limit = NULL,
      start_at = NULL,
      end_at = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) trading pair (e.g., `"BTC-USDT"`). If
  NULL, returns fills across all symbols.

- `order_id`:

  (scalar\<character\> \| NULL) filter by specific order ID.

- `side`:

  (scalar\<character\> \| NULL) `"buy"` or `"sell"`.

- `type`:

  (scalar\<character\> \| NULL) `"limit"` or `"market"`.

- `last_id`:

  (scalar\<character\> \| NULL) pagination cursor for fetching next
  page.

- `limit`:

  (scalar\<count\> \| NULL) results per page (default 100, max 200).

- `start_at`:

  (scalar\<numeric\> \| NULL) start timestamp in milliseconds.

- `end_at`:

  (scalar\<numeric\> \| NULL) end timestamp in milliseconds.

#### Returns

(data.table \| promise\<data.table\>) one row per fill giving the fill
and trade identifiers, the parent and counterparty order IDs, the
trading pair, side, liquidity, type, price, size, funds, fee, fee rate,
fee currency, and the creation datetime (POSIXct, coerced from epoch
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

KuCoin Get Symbols With Open Order:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-symbols-with-open-order>

Verified: 2026-05-23

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

(data.table \| promise\<data.table\>) one row per trading pair that has
at least one open order:

- symbols (character) the trading pair, e.g. `"BTC-USDT"`.

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

Verified: 2026-05-23

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

  (scalar\<character\> \| NULL) trading pair (e.g., `"BTC-USDT"`).
  **Required** by the API.

#### Returns

(data.table \| promise\<data.table\>) one row per open order, including
the creation datetime (POSIXct).

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

Verified: 2026-05-23

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
      start_at = NULL,
      end_at = NULL,
      limit = NULL,
      last_id = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) trading pair (e.g., `"BTC-USDT"`). If
  NULL, returns closed orders across all symbols.

- `side`:

  (scalar\<character\> \| NULL) `"buy"` or `"sell"`.

- `type`:

  (scalar\<character\> \| NULL) `"limit"` or `"market"`.

- `start_at`:

  (scalar\<numeric\> \| NULL) start timestamp in milliseconds.

- `end_at`:

  (scalar\<numeric\> \| NULL) end timestamp in milliseconds.

- `limit`:

  (scalar\<count\> \| NULL) results per page (max 200).

- `last_id`:

  (scalar\<character\> \| NULL) pagination cursor.

#### Returns

(data.table \| promise\<data.table\>) one row per closed order,
including the creation datetime (POSIXct):

- order_id (character) the system order identifier.

- symbol (character) the trading pair symbol.

- side (character) the order side.

- created_at (POSIXct) the created at (UTC).

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

Verified: 2026-05-23

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
      client_order_id = NULL,
      price = NULL,
      size = NULL,
      funds = NULL,
      stp = NULL,
      tags = NULL,
      remark = NULL,
      time_in_force = NULL,
      cancel_after = NULL,
      post_only = NULL,
      hidden = NULL,
      iceberg = NULL,
      visible_size = NULL
    )

#### Arguments

- `type`:

  (scalar\<character\>) `"limit"` or `"market"`.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

- `side`:

  (scalar\<character\>) `"buy"` or `"sell"`.

- `client_order_id`:

  (scalar\<character\> \| NULL) unique client order ID (max 40 chars).

- `price`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) price for limit
  orders.

- `size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) quantity in base
  currency.

- `funds`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) amount in quote
  currency for market orders.

- `stp`:

  (scalar\<character\> \| NULL) self-trade prevention: `"CN"`, `"CO"`,
  `"CB"`, `"DC"`.

- `tags`:

  (scalar\<character\> \| NULL) order tag (max 20 ASCII chars).

- `remark`:

  (scalar\<character\> \| NULL) remarks (max 20 ASCII chars).

- `time_in_force`:

  (scalar\<character\> \| NULL) `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.

- `cancel_after`:

  (scalar\<numeric\> \| NULL) auto-cancel seconds (requires
  `timeInForce = "GTT"`).

- `post_only`:

  (scalar\<logical\> \| NULL) if TRUE, order rejected if it would match
  immediately.

- `hidden`:

  (scalar\<logical\> \| NULL) if TRUE, order hidden from order book.

- `iceberg`:

  (scalar\<logical\> \| NULL) if TRUE, only `visibleSize` is shown.

- `visible_size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) visible quantity
  for iceberg orders.

#### Returns

(data.table \| promise\<data.table\>) one row giving the order and
client identifiers, the order placement datetime, the original, filled,
remaining, and cancelled sizes, and the fill status.

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

Verified: 2026-05-23

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
      --data-raw \
      '{"orderList":[{"clientOid":"id1","symbol":"BTC-USDT","type":"limit","side":"buy","price":"30000",
      "size":"0.00001"}]}'

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

  (list) list of named lists; each containing order parameters. Maximum
  20 orders.

#### Returns

(data.table \| promise\<data.table\>) one row per order giving the order
and client identifiers, the success flag, the fill status, and the
filled, remaining, and cancelled quantities:

- order_id (character \| NA) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

- success (logical) whether the order succeeded.

- status (character \| NA) the status.

- deal_size (numeric \| NA) the filled size.

- remain_size (numeric \| NA) the unfilled size.

- canceled_size (numeric \| NA) the cancelled size.

- fail_msg (character \| NA) the failure message.

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

KuCoin Cancel Order By OrderId Sync:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-orderld-sync>

Verified: 2026-05-23

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

    KucoinTrading$cancel_order_by_id_sync(order_id, symbol)

#### Arguments

- `order_id`:

  (scalar\<character\>) the KuCoin order ID to cancel.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the order ID, the
original, filled, remaining, and cancelled sizes, and the fill status:

- order_id (character) the system order identifier.

- origin_size (numeric \| NA) the original size.

- deal_size (numeric \| NA) the filled size.

- remain_size (numeric \| NA) the unfilled size.

- canceled_size (numeric \| NA) the cancelled size.

- status (character) the status.

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

KuCoin Cancel Order By ClientOid Sync:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-clientoid-sync>

Verified: 2026-05-23

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

    KucoinTrading$cancel_order_by_client_oid_sync(client_order_id, symbol)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) client order ID.

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the client order
ID, the original, filled, remaining, and cancelled sizes, and the fill
status:

- client_oid (character \| NA) the client-supplied order identifier.

- origin_size (numeric \| NA) the original size.

- deal_size (numeric \| NA) the filled size.

- remain_size (numeric \| NA) the unfilled size.

- canceled_size (numeric \| NA) the cancelled size.

- status (character) the status.

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

Verified: 2026-05-23

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
      order_id = NULL,
      client_order_id = NULL,
      new_price = NULL,
      new_size = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`). Required.

- `order_id`:

  (scalar\<character\> \| NULL) KuCoin order ID. At least one of
  `order_id` or `client_order_id` is required.

- `client_order_id`:

  (scalar\<character\> \| NULL) client order ID. At least one of
  `order_id` or `client_order_id` is required.

- `new_price`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) new order price. At
  least one of `new_price` or `new_size` required.

- `new_size`:

  (scalar\<numeric\> \| scalar\<character\> \| NULL) new order size. At
  least one of `new_price` or `new_size` required.

#### Returns

(data.table \| promise\<data.table\>) one row giving the replacement
order's ID and the original client order ID:

- new_order_id (character) the new order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

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

Verified: 2026-05-23

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

  (scalar\<numeric\>) trigger duration in seconds. Use `-1` to disable,
  or `5` to `86400`.

- `symbols`:

  (scalar\<character\> \| NULL) comma-separated trading pairs (max 50).
  Empty or NULL applies to all pairs.

#### Returns

(data.table \| promise\<data.table\>) one row giving the current server
time and the time at which cancellation will trigger, both in seconds:

- current_time (integer) the current server time, in epoch seconds.

- trigger_time (integer) the time at which cancellation triggers, in
  epoch seconds.

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

Verified: 2026-05-23

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

(data.table \| promise\<data.table\>) one row giving the auto-cancel
trigger time, the protected symbols, the current server time, and the
time at which cancellation will trigger; an empty data.table if DCP is
not configured.

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
