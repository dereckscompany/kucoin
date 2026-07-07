# KucoinFuturesTrading: Futures Order Management

KucoinFuturesTrading: Futures Order Management

KucoinFuturesTrading: Futures Order Management

## Details

Provides methods for placing, cancelling, and querying futures orders on
KuCoin. Supports limit and market orders, stop orders, batch operations,
and Dead Connection Protection (DCP). Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Order Placement**: Place single or batch limit/market futures orders
  with configurable leverage, margin mode, and position side.

- **Order Cancellation**: Cancel individual orders by system ID or
  client OID, or cancel all open/stop orders at once.

- **Order Queries**: Retrieve order details, paginated order lists,
  recent closed orders, and stop orders.

- **Trade History**: Query fill records (paginated or recent) with fee
  and liquidity details.

- **Risk Management**: Configure Dead Connection Protection (DCP) to
  auto-cancel orders on connectivity loss.

### Usage

All methods require authentication with Futures trading permission
enabled. Use `add_order_test()` to validate order parameters before
placing real orders. For automated trading, configure DCP via
`set_dcp()` to protect against unintended open positions during bot
failures.

### Official Documentation

[KuCoin Futures
Orders](https://www.kucoin.com/docs-new/rest/futures-trading/orders/add-order)

### Endpoints Covered

|  |  |  |
|----|----|----|
| Method | Endpoint | HTTP |
| add_order | POST /api/v1/orders | POST |
| add_order_test | POST /api/v1/orders/test | POST |
| add_order_batch | POST /api/v1/orders/multi | POST |
| cancel_order_by_id | DELETE /api/v1/orders/{orderId} | DELETE |
| cancel_order_by_client_oid | DELETE /api/v1/orders/client-order/{clientOid} | DELETE |
| cancel_all | DELETE /api/v1/orders | DELETE |
| cancel_all_stop_orders | DELETE /api/v1/stopOrders | DELETE |
| get_order_by_id | GET /api/v1/orders/{orderId} | GET |
| get_order_by_client_oid | GET /api/v1/orders/byClientOid | GET |
| get_order_list | GET /api/v1/orders | GET |
| get_recent_closed_orders | GET /api/v1/recentDoneOrders | GET |
| get_stop_orders | GET /api/v1/stopOrders | GET |
| get_fills | GET /api/v1/fills | GET |
| get_recent_fills | GET /api/v1/recentFills | GET |
| get_open_order_value | GET /api/v1/openOrderStatistics | GET |
| set_dcp | POST /api/ua/v1/dcp/set (spot host, tradeType=FUTURES) | POST |
| get_dcp | GET /api/ua/v1/dcp/query (spot host, tradeType=FUTURES) | GET |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinFuturesTrading`

## Methods

### Public methods

- [`KucoinFuturesTrading$new()`](#method-KucoinFuturesTrading-new)

- [`KucoinFuturesTrading$add_order()`](#method-KucoinFuturesTrading-add_order)

- [`KucoinFuturesTrading$add_order_test()`](#method-KucoinFuturesTrading-add_order_test)

- [`KucoinFuturesTrading$add_order_batch()`](#method-KucoinFuturesTrading-add_order_batch)

- [`KucoinFuturesTrading$cancel_order_by_id()`](#method-KucoinFuturesTrading-cancel_order_by_id)

- [`KucoinFuturesTrading$cancel_order_by_client_oid()`](#method-KucoinFuturesTrading-cancel_order_by_client_oid)

- [`KucoinFuturesTrading$cancel_all()`](#method-KucoinFuturesTrading-cancel_all)

- [`KucoinFuturesTrading$cancel_all_stop_orders()`](#method-KucoinFuturesTrading-cancel_all_stop_orders)

- [`KucoinFuturesTrading$get_order_by_id()`](#method-KucoinFuturesTrading-get_order_by_id)

- [`KucoinFuturesTrading$get_order_by_client_oid()`](#method-KucoinFuturesTrading-get_order_by_client_oid)

- [`KucoinFuturesTrading$get_order_list()`](#method-KucoinFuturesTrading-get_order_list)

- [`KucoinFuturesTrading$get_recent_closed_orders()`](#method-KucoinFuturesTrading-get_recent_closed_orders)

- [`KucoinFuturesTrading$get_stop_orders()`](#method-KucoinFuturesTrading-get_stop_orders)

- [`KucoinFuturesTrading$get_fills()`](#method-KucoinFuturesTrading-get_fills)

- [`KucoinFuturesTrading$get_recent_fills()`](#method-KucoinFuturesTrading-get_recent_fills)

- [`KucoinFuturesTrading$get_open_order_value()`](#method-KucoinFuturesTrading-get_open_order_value)

- [`KucoinFuturesTrading$set_dcp()`](#method-KucoinFuturesTrading-set_dcp)

- [`KucoinFuturesTrading$get_dcp()`](#method-KucoinFuturesTrading-get_dcp)

- [`KucoinFuturesTrading$clone()`](#method-KucoinFuturesTrading-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new KucoinFuturesTrading instance.

#### Usage

    KucoinFuturesTrading$new(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    )

#### Arguments

- `keys`:

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/kucoin/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) Futures API base URL. Defaults to
  [`get_futures_base_url()`](https://dereckscompany.github.io/kucoin/reference/get_futures_base_url.md).

- `async`:

  (scalar\<logical\>) if TRUE, methods return promises.

- `time_source`:

  (scalar\<character\>) `"local"` or `"server"`.

#### Returns

(class\<KucoinFuturesTrading\>) invisibly, the new instance.

------------------------------------------------------------------------

### Method `add_order()`

Place a Futures Order

Places a new futures order (limit or market) on KuCoin. Supports
isolated and cross margin modes, one-way and hedge position modes, and
optional reduce-only constraints.

#### Workflow

1.  **Build Body**: Constructs JSON body with all non-NULL order
    parameters.

2.  **Request**: Authenticated POST to the futures order placement
    endpoint.

3.  **Parsing**: Returns `data.table` with the system-assigned order ID
    and client OID.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/orders`

#### Official Documentation

[KuCoin Add Futures
Order](https://www.kucoin.com/docs-new/rest/futures-trading/orders/add-order)

Verified: 2026-05-23

#### Automated Trading Usage

- **Leverage Control**: Set `leverage` to manage risk exposure per
  order.

- **Position Modes**: Use `positionSide = "LONG"` or `"SHORT"` in hedge
  mode to manage both directions simultaneously.

- **Reduce-Only**: Set `reduceOnly = TRUE` to ensure the order only
  closes existing positions, preventing accidental position increases.

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/orders' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{
        "clientOid": "my-order-001",
        "symbol": "XBTUSDTM",
        "side": "buy",
        "type": "limit",
        "leverage": 5,
        "size": 1,
        "price": "50000",
        "marginMode": "ISOLATED",
        "positionSide": "BOTH",
        "timeInForce": "GTC"
      }'

#### JSON Request

    {
      "clientOid": "my-order-001",
      "symbol": "XBTUSDTM",
      "side": "buy",
      "type": "limit",
      "leverage": 5,
      "size": 1,
      "price": "50000",
      "marginMode": "ISOLATED",
      "positionSide": "BOTH",
      "timeInForce": "GTC"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "234125150956625920",
        "clientOid": "my-order-001"
      }
    }

#### Usage

    KucoinFuturesTrading$add_order(
      client_order_id,
      symbol,
      side,
      type,
      leverage,
      size,
      price = NULL,
      margin_mode = "ISOLATED",
      position_side = "BOTH",
      time_in_force = NULL,
      reduce_only = NULL,
      remark = NULL,
      ...
    )

#### Arguments

- `client_order_id`:

  (scalar\<character\>) unique client order ID.

- `symbol`:

  (scalar\<character\>) futures symbol (e.g., `"XBTUSDTM"`).

- `side`:

  (scalar\<character\>) `"buy"` or `"sell"`.

- `type`:

  (scalar\<character\>) `"limit"` or `"market"`.

- `leverage`:

  (scalar\<count in \[1, Inf\[\>) leverage multiplier.

- `size`:

  (scalar\<count in \[1, Inf\[\>) order quantity (number of contracts).

- `price`:

  (scalar\<character\> \| NULL) price (required for limit orders).

- `margin_mode`:

  (scalar\<character\>) `"ISOLATED"` or `"CROSS"`. Default `"ISOLATED"`.

- `position_side`:

  (scalar\<character\>) `"BOTH"` for one-way mode, `"LONG"` or `"SHORT"`
  for hedge mode. Default `"BOTH"`.

- `time_in_force`:

  (scalar\<character\> \| NULL) e.g., `"GTC"`, `"IOC"`, `"FOK"`.

- `reduce_only`:

  (scalar\<logical\> \| NULL) if TRUE, order only reduces position.

- `remark`:

  (scalar\<character\> \| NULL) order notes.

- `...`:

  Additional order parameters.

#### Returns

(data.table \| promise\<data.table\>) one row giving the system-assigned
order ID and the client-provided order ID:

- order_id (character) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Place a limit buy order
    result <- ft$add_order(
      clientOid = "my-order-001",
      symbol = "XBTUSDTM",
      side = "buy",
      type = "limit",
      leverage = 5,
      size = 1,
      price = "50000"
    )
    print(result$order_id)

    # Place a market sell order
    result <- ft$add_order(
      clientOid = "my-order-002",
      symbol = "XBTUSDTM",
      side = "sell",
      type = "market",
      leverage = 10,
      size = 2,
      reduceOnly = TRUE
    )
    }

------------------------------------------------------------------------

### Method `add_order_test()`

Place a Test Futures Order (Dry Run)

Validates order parameters without placing a real order. The API
performs all validation checks (balance, symbol, price, etc.) and
returns a simulated order ID. Useful for pre-flight checks in automated
systems.

#### Workflow

1.  **Build Body**: Constructs JSON body with all non-NULL order
    parameters (identical to `add_order()`).

2.  **Request**: Authenticated POST to the test endpoint; no real order
    is placed.

3.  **Parsing**: Returns `data.table` with a simulated order ID and
    client OID.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/orders/test`

#### Official Documentation

[KuCoin Add Futures Order
Test](https://www.kucoin.com/docs-new/rest/futures-trading/orders/add-order-test)

Verified: 2026-05-23

#### Automated Trading Usage

- **Pre-Flight Validation**: Validate order parameters at bot startup to
  confirm API keys have trading permissions and symbols are correct.

- **Parameter Testing**: Test edge-case parameters (extreme leverage,
  unusual sizes) without risking capital.

- **Integration Testing**: Use in CI/CD pipelines to verify order
  construction logic.

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/orders/test' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{
        "clientOid": "test-001",
        "symbol": "XBTUSDTM",
        "side": "buy",
        "type": "limit",
        "leverage": 5,
        "size": 1,
        "price": "50000",
        "marginMode": "ISOLATED",
        "positionSide": "BOTH"
      }'

#### JSON Request

    {
      "clientOid": "test-001",
      "symbol": "XBTUSDTM",
      "side": "buy",
      "type": "limit",
      "leverage": 5,
      "size": 1,
      "price": "50000",
      "marginMode": "ISOLATED",
      "positionSide": "BOTH"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "234125150956625920",
        "clientOid": "test-001"
      }
    }

#### Usage

    KucoinFuturesTrading$add_order_test(
      client_order_id,
      symbol,
      side,
      type,
      leverage,
      size,
      price = NULL,
      margin_mode = "ISOLATED",
      position_side = "BOTH",
      time_in_force = NULL,
      reduce_only = NULL,
      remark = NULL,
      ...
    )

#### Arguments

- `client_order_id`:

  (scalar\<character\>) unique client order ID.

- `symbol`:

  (scalar\<character\>) futures symbol (e.g., `"XBTUSDTM"`).

- `side`:

  (scalar\<character\>) `"buy"` or `"sell"`.

- `type`:

  (scalar\<character\>) `"limit"` or `"market"`.

- `leverage`:

  (scalar\<count in \[1, Inf\[\>) leverage multiplier.

- `size`:

  (scalar\<count in \[1, Inf\[\>) order quantity (number of contracts).

- `price`:

  (scalar\<character\> \| NULL) price (required for limit orders).

- `margin_mode`:

  (scalar\<character\>) `"ISOLATED"` or `"CROSS"`. Default `"ISOLATED"`.

- `position_side`:

  (scalar\<character\>) `"BOTH"` for one-way mode, `"LONG"` or `"SHORT"`
  for hedge mode. Default `"BOTH"`.

- `time_in_force`:

  (scalar\<character\> \| NULL) e.g., `"GTC"`, `"IOC"`, `"FOK"`.

- `reduce_only`:

  (scalar\<logical\> \| NULL) if TRUE, order only reduces position.

- `remark`:

  (scalar\<character\> \| NULL) order notes.

- `...`:

  Additional order parameters.

#### Returns

(data.table \| promise\<data.table\>) one row giving the simulated order
ID and the client-provided order ID:

- order_id (character) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Validate a limit order without placing it
    result <- ft$add_order_test(
      clientOid = "test-001",
      symbol = "XBTUSDTM",
      side = "buy",
      type = "limit",
      leverage = 5,
      size = 1,
      price = "50000"
    )
    print(result)
    }

------------------------------------------------------------------------

### Method `add_order_batch()`

Batch Place Futures Orders

Places multiple futures orders in a single API request. Each order in
the batch uses the same parameter structure as `add_order()`. The API
processes orders independently; partial failures are possible (some
orders may succeed while others fail).

#### Workflow

1.  **Build Body**: Accepts a list of order lists, each containing order
    parameters.

2.  **Request**: Authenticated POST to the batch order endpoint.

3.  **Parsing**: Returns `data.table` with one row per order result.

#### API Endpoint

`POST https://api-futures.kucoin.com/api/v1/orders/multi`

#### Official Documentation

[KuCoin Batch Add Futures
Orders](https://www.kucoin.com/docs-new/rest/futures-trading/orders/batch-add-orders)

Verified: 2026-05-23

#### Automated Trading Usage

- **Grid Trading**: Place multiple limit orders at different price
  levels in a single request.

- **Hedging**: Submit simultaneous long and short orders across
  different symbols.

- **Efficiency**: Reduce API call overhead by batching orders instead of
  sending them individually.

#### curl

    curl --location --request POST 'https://api-futures.kucoin.com/api/v1/orders/multi' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '[
        {
          "clientOid": "batch-001",
          "symbol": "XBTUSDTM",
          "side": "buy",
          "type": "limit",
          "leverage": 5,
          "size": 1,
          "price": "49000"
        },
        {
          "clientOid": "batch-002",
          "symbol": "XBTUSDTM",
          "side": "buy",
          "type": "limit",
          "leverage": 5,
          "size": 1,
          "price": "48000"
        }
      ]'

#### JSON Request

    [
      {
        "clientOid": "batch-001",
        "symbol": "XBTUSDTM",
        "side": "buy",
        "type": "limit",
        "leverage": 5,
        "size": 1,
        "price": "49000"
      },
      {
        "clientOid": "batch-002",
        "symbol": "XBTUSDTM",
        "side": "buy",
        "type": "limit",
        "leverage": 5,
        "size": 1,
        "price": "48000"
      }
    ]

#### JSON Response

    {
      "code": "200000",
      "data": [
        {
          "orderId": "234125150956625920",
          "clientOid": "batch-001",
          "symbol": "XBTUSDTM",
          "code": "200000",
          "msg": "success"
        },
        {
          "orderId": "234125150956625921",
          "clientOid": "batch-002",
          "symbol": "XBTUSDTM",
          "code": "200000",
          "msg": "success"
        }
      ]
    }

#### Usage

    KucoinFuturesTrading$add_order_batch(orders)

#### Arguments

- `orders`:

  (list) list of order lists, each with the same fields as `add_order()`
  (i.e., `clientOid`, `symbol`, `side`, `type`, `leverage`, `size`, and
  optional `price`, `marginMode`, `positionSide`, etc.).

#### Returns

(data.table \| promise\<data.table\>) one row per order result giving
the system-assigned order ID, the client-provided order ID, the futures
symbol, the per-order status code, and the per-order status message:

- order_id (character) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    orders <- list(
      list(clientOid = "b1", symbol = "XBTUSDTM", side = "buy",
           type = "limit", leverage = 5, size = 1, price = "49000"),
      list(clientOid = "b2", symbol = "XBTUSDTM", side = "buy",
           type = "limit", leverage = 5, size = 1, price = "48000")
    )
    results <- ft$add_order_batch(orders)
    print(results[, .(order_id, client_oid, code)])
    }

------------------------------------------------------------------------

### Method `cancel_order_by_id()`

Cancel Order by Order ID

Cancels an open futures order using the system-assigned order ID. If the
order has already been filled or cancelled, the API returns an error.

#### Workflow

1.  **Request**: Authenticated DELETE with the order ID in the URL path.

2.  **Parsing**: Returns `data.table` with the list of cancelled order
    IDs.

#### API Endpoint

`DELETE https://api-futures.kucoin.com/api/v1/orders/{orderId}`

#### Official Documentation

KuCoin Cancel Futures Order By OrderId:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/cancel-order-by-orderld>

Verified: 2026-05-23

#### Automated Trading Usage

- **Stale Order Cleanup**: Cancel orders that have not filled within a
  timeout window.

- **Position Exit**: Cancel pending limit orders before placing a market
  close to avoid double fills.

#### curl

    curl --location --request DELETE \
      'https://api-futures.kucoin.com/api/v1/orders/234125150956625920' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "cancelledOrderIds": [
          "234125150956625920"
        ]
      }
    }

#### Usage

    KucoinFuturesTrading$cancel_order_by_id(order_id)

#### Arguments

- `order_id`:

  (scalar\<character\>) the system order ID to cancel.

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order giving
the cancelled order ID; an empty data.table if no orders matched.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()
    result <- ft$cancel_order_by_id("234125150956625920")
    print(result$cancelled_order_id)
    }

------------------------------------------------------------------------

### Method `cancel_order_by_client_oid()`

Cancel Order by Client Order ID

Cancels an open futures order using the client-provided order ID.
Requires the symbol to disambiguate in case client OIDs are reused
across symbols.

#### Workflow

1.  **Request**: Authenticated DELETE with the client OID in the URL
    path and `symbol` as a query parameter.

2.  **Parsing**: Returns `data.table` with the cancelled client order
    ID.

#### API Endpoint

`DELETE https://api-futures.kucoin.com/api/v1/orders/client-order/{clientOid}`

#### Official Documentation

KuCoin Cancel Futures Order By ClientOid:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/cancel-order-by-clientoid>

Verified: 2026-05-23

#### Automated Trading Usage

- **Idempotent Cancellation**: Use client OIDs to cancel orders without
  needing to store system order IDs.

- **Consistent State**: Cancel by the same ID used to place the order
  for easier state management in trading bots.

#### curl

    curl --location --request DELETE \
      'https://api-futures.kucoin.com/api/v1/orders/client-order/my-order-001?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "clientOid": "my-order-001"
      }
    }

#### Usage

    KucoinFuturesTrading$cancel_order_by_client_oid(client_order_id, symbol)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) the client order ID to cancel.

- `symbol`:

  (scalar\<character\>) futures symbol (e.g., `"XBTUSDTM"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the cancelled
client order ID.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()
    result <- ft$cancel_order_by_client_oid("my-order-001", symbol = "XBTUSDTM")
    print(result$client_oid)
    }

------------------------------------------------------------------------

### Method `cancel_all()`

Cancel All Orders

Cancels all open futures orders, optionally filtered by symbol. This is
a bulk operation that cancels limit and market orders (but not stop
orders; use `cancel_all_stop_orders()` for those).

#### Workflow

1.  **Request**: Authenticated DELETE with optional `symbol` query
    parameter.

2.  **Parsing**: Returns `data.table` with the list of all cancelled
    order IDs.

#### API Endpoint

`DELETE https://api-futures.kucoin.com/api/v1/orders`

#### Official Documentation

[KuCoin Cancel All Futures
Orders](https://www.kucoin.com/docs-new/rest/futures-trading/orders/cancel-all-orders)

Verified: 2026-05-23

#### Automated Trading Usage

- **Emergency Stop**: Cancel all open orders as part of a kill-switch or
  panic button.

- **Strategy Reset**: Clear all pending orders before deploying a new
  trading strategy.

- **Symbol-Scoped Cleanup**: Pass `symbol` to cancel only orders for a
  specific contract without affecting other positions.

#### curl

    curl --location --request DELETE \
      'https://api-futures.kucoin.com/api/v1/orders?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "cancelledOrderIds": [
          "234125150956625920",
          "234125150956625921",
          "234125150956625922"
        ]
      }
    }

#### Usage

    KucoinFuturesTrading$cancel_all(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) filter by futures symbol. When NULL,
  cancels all open orders across all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order giving
the cancelled order ID; an empty data.table if no orders matched.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Cancel all open orders for XBTUSDTM
    result <- ft$cancel_all(symbol = "XBTUSDTM")
    print(result$cancelled_order_id)

    # Cancel all open orders across all symbols
    result <- ft$cancel_all()
    }

------------------------------------------------------------------------

### Method `cancel_all_stop_orders()`

Cancel All Stop Orders

Cancels all untriggered stop orders, optionally filtered by symbol. This
only affects stop orders that have not yet been triggered;
already-triggered stop orders become regular orders and must be
cancelled via `cancel_all()`.

#### Workflow

1.  **Request**: Authenticated DELETE to the stop orders endpoint with
    optional `symbol` query parameter.

2.  **Parsing**: Returns `data.table` with the list of all cancelled
    stop order IDs.

#### API Endpoint

`DELETE https://api-futures.kucoin.com/api/v1/stopOrders`

#### Official Documentation

KuCoin Cancel All Futures Stop Orders:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/cancel-all-stop-orders>

Verified: 2026-05-23

#### Automated Trading Usage

- **Strategy Teardown**: Remove all pending stop-loss and take-profit
  orders when a strategy is deactivated.

- **Recalibration**: Cancel existing stop orders before placing updated
  ones at new price levels.

#### curl

    curl --location --request DELETE \
      'https://api-futures.kucoin.com/api/v1/stopOrders?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "cancelledOrderIds": [
          "234125150956625930",
          "234125150956625931"
        ]
      }
    }

#### Usage

    KucoinFuturesTrading$cancel_all_stop_orders(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) filter by futures symbol. When NULL,
  cancels all untriggered stop orders across all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order giving
the cancelled order ID; an empty data.table if no orders matched:

- cancelled_order_id (character) the cancelled order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Cancel all stop orders for XBTUSDTM
    result <- ft$cancel_all_stop_orders(symbol = "XBTUSDTM")
    print(result$cancelled_order_id)

    # Cancel all stop orders across all symbols
    result <- ft$cancel_all_stop_orders()
    }

------------------------------------------------------------------------

### Method `get_order_by_id()`

Get Order by Order ID

Retrieves full details of a single futures order by its system-assigned
order ID. Returns order status, fill details, timestamps, and all
configuration parameters.

#### Workflow

1.  **Request**: Authenticated GET with the order ID in the URL path.

2.  **Parsing**: Returns a single-row `data.table` with all order
    fields.

3.  **Timestamp Conversion**: Coerces `created_at` and `updated_at` from
    milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/orders/{orderId}`

#### Official Documentation

KuCoin Get Futures Order By OrderId:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-order-by-orderld>

Verified: 2026-05-23

#### Automated Trading Usage

- **Order Tracking**: Poll order status to determine when a limit order
  has been filled.

- **Fill Verification**: Check `deal_size` and `deal_value` to confirm
  partial or complete fills.

- **Audit Trail**: Log full order details for post-trade analysis.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/orders/234125150956625920' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "234125150956625920",
        "symbol": "XBTUSDTM",
        "type": "limit",
        "side": "buy",
        "price": "50000",
        "size": 1,
        "value": "0.00002",
        "dealValue": "0",
        "dealSize": 0,
        "stp": "",
        "stop": "",
        "stopPriceType": "",
        "stopTriggered": false,
        "stopPrice": null,
        "timeInForce": "GTC",
        "postOnly": false,
        "hidden": false,
        "iceberg": false,
        "leverage": "5",
        "forceHold": false,
        "closeOrder": false,
        "visibleSize": null,
        "clientOid": "my-order-001",
        "remark": null,
        "tags": null,
        "isActive": true,
        "cancelExist": false,
        "createdAt": 1729577515473,
        "updatedAt": 1729577515473,
        "endAt": null,
        "orderTime": 1729577515473000000,
        "settleCurrency": "USDT",
        "marginMode": "ISOLATED",
        "avgDealPrice": "0",
        "filledSize": 0,
        "filledValue": "0",
        "status": "open",
        "reduceOnly": false
      }
    }

#### Usage

    KucoinFuturesTrading$get_order_by_id(order_id)

#### Arguments

- `order_id`:

  (scalar\<character\>) the system order ID.

#### Returns

(data.table \| promise\<data.table\>) one row of full order details,
including the creation and last-updated datetimes (POSIXct, coerced from
epoch milliseconds):

- id (character) the record identifier.

- symbol (character) the trading pair symbol.

- type (character) the type.

- side (character) the order side.

- price (numeric \| NA) the price.

- size (numeric \| NA) the size.

- value (numeric \| NA) the order value.

- deal_value (numeric \| NA) the filled value.

- deal_size (numeric \| NA) the filled size.

- leverage (integer \| NA) the leverage.

- margin_mode (character) the margin mode.

- position_side (character) the position side.

- status (character) the status.

- created_at (POSIXct) the created at (UTC).

- updated_at (POSIXct \| NA) the updated at (UTC).

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()
    order <- ft$get_order_by_id("234125150956625920")
    print(order[, .(id, symbol, side, price, size, status)])
    }

------------------------------------------------------------------------

### Method `get_order_by_client_oid()`

Get Order by Client Order ID

Retrieves full details of a single futures order by its client-provided
order ID. Useful when the system order ID was not stored at placement
time.

#### Workflow

1.  **Request**: Authenticated GET with `clientOid` as a query
    parameter.

2.  **Parsing**: Returns a single-row `data.table` with all order
    fields.

3.  **Timestamp Conversion**: Coerces `created_at` and `updated_at` from
    milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/orders/byClientOid`

#### Official Documentation

KuCoin Get Futures Order By ClientOid:
<https://www.kucoin.com/docs-new/rest/futures-trading/get-stop-order-by-clientoid>

Note: KuCoin's URL slug here contains `get-stop-order-by-clientoid`, but
the page actually documents the regular order endpoint
(`GET /api/v1/orders/byClientOid`) — the sidebar title is "Get Order By
ClientOid" and the documented method and path match the source. Slug is
misleading; the URL is canonical.

Verified: 2026-05-23

#### Automated Trading Usage

- **Stateless Lookups**: Retrieve order status using only the client OID
  without needing to track system IDs.

- **Idempotency Checks**: Verify if a previously placed order is still
  active before re-submitting.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/orders/byClientOid?clientOid=my-order-001' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "id": "234125150956625920",
        "symbol": "XBTUSDTM",
        "type": "limit",
        "side": "buy",
        "price": "50000",
        "size": 1,
        "value": "0.00002",
        "dealValue": "0",
        "dealSize": 0,
        "stp": "",
        "stop": "",
        "stopPriceType": "",
        "stopTriggered": false,
        "stopPrice": null,
        "timeInForce": "GTC",
        "postOnly": false,
        "hidden": false,
        "iceberg": false,
        "leverage": "5",
        "forceHold": false,
        "closeOrder": false,
        "visibleSize": null,
        "clientOid": "my-order-001",
        "remark": null,
        "tags": null,
        "isActive": true,
        "cancelExist": false,
        "createdAt": 1729577515473,
        "updatedAt": 1729577515473,
        "endAt": null,
        "orderTime": 1729577515473000000,
        "settleCurrency": "USDT",
        "marginMode": "ISOLATED",
        "avgDealPrice": "0",
        "filledSize": 0,
        "filledValue": "0",
        "status": "open",
        "reduceOnly": false
      }
    }

#### Usage

    KucoinFuturesTrading$get_order_by_client_oid(client_order_id)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) the client order ID.

#### Returns

(data.table \| promise\<data.table\>) one row of full order details;
same columns as `get_order_by_id()`:

- id (character) the record identifier.

- symbol (character) the trading pair symbol.

- type (character) the type.

- side (character) the order side.

- price (numeric \| NA) the price.

- size (numeric \| NA) the size.

- value (numeric \| NA) the order value.

- deal_value (numeric \| NA) the filled value.

- deal_size (numeric \| NA) the filled size.

- leverage (integer \| NA) the leverage.

- margin_mode (character) the margin mode.

- position_side (character) the position side.

- status (character) the status.

- created_at (POSIXct) the created at (UTC).

- updated_at (POSIXct \| NA) the updated at (UTC).

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()
    order <- ft$get_order_by_client_oid("my-order-001")
    print(order[, .(id, symbol, side, price, size, status)])
    }

------------------------------------------------------------------------

### Method `get_order_list()`

Get Order List

Retrieves a paginated list of futures orders with optional filtering by
status, symbol, side, type, and time range. Use `status = "active"` for
open orders or `status = "done"` for closed/cancelled orders.

#### Workflow

1.  **Pagination**: Uses `private$.paginate()` to fetch all pages of
    order records.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Timestamp Conversion**: Coerces `created_at` and `updated_at` from
    milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/orders`

#### Official Documentation

[KuCoin Get Futures Order
List](https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-order-list)

Verified: 2026-05-23

#### Automated Trading Usage

- **Open Order Monitoring**: Query `status = "active"` to track all
  pending orders and detect stale ones.

- **Historical Analysis**: Query `status = "done"` with
  `startAt`/`endAt` for trade performance review.

- **Symbol Filtering**: Pass `symbol` to retrieve orders for a specific
  contract only.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/orders?status=active&symbol=XBTUSDTM&currentPage=1&pageSize=50' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currentPage": 1,
        "pageSize": 50,
        "totalNum": 1,
        "totalPage": 1,
        "items": [
          {
            "id": "234125150956625920",
            "symbol": "XBTUSDTM",
            "type": "limit",
            "side": "buy",
            "price": "50000",
            "size": 1,
            "value": "0.00002",
            "dealValue": "0",
            "dealSize": 0,
            "stp": "",
            "stop": "",
            "stopPriceType": "",
            "stopTriggered": false,
            "stopPrice": null,
            "timeInForce": "GTC",
            "postOnly": false,
            "hidden": false,
            "iceberg": false,
            "leverage": "5",
            "forceHold": false,
            "closeOrder": false,
            "visibleSize": null,
            "clientOid": "my-order-001",
            "remark": null,
            "tags": null,
            "isActive": true,
            "cancelExist": false,
            "createdAt": 1729577515473,
            "updatedAt": 1729577515473,
            "endAt": null,
            "orderTime": 1729577515473000000,
            "settleCurrency": "USDT",
            "marginMode": "ISOLATED",
            "avgDealPrice": "0",
            "filledSize": 0,
            "filledValue": "0",
            "status": "open",
            "reduceOnly": false
          }
        ]
      }
    }

#### Usage

    KucoinFuturesTrading$get_order_list(query = list())

#### Arguments

- `query`:

  (list) query parameters. Use `status = "active"` for open orders,
  `status = "done"` for closed orders. Optional: `symbol`, `side`,
  `type`, `startAt`, `endAt`.

#### Returns

(data.table \| promise\<data.table\>) one row per order record (same
columns as `get_order_by_id()`); an empty data.table if no orders match
the filters:

- id (character) the record identifier.

- symbol (character) the trading pair symbol.

- type (character) the type.

- side (character) the order side.

- price (numeric \| NA) the price.

- size (numeric \| NA) the size.

- value (numeric \| NA) the order value.

- deal_value (numeric \| NA) the filled value.

- deal_size (numeric \| NA) the filled size.

- leverage (integer \| NA) the leverage.

- margin_mode (character) the margin mode.

- position_side (character) the position side.

- status (character) the status.

- created_at (POSIXct) the created at (UTC).

- updated_at (POSIXct \| NA) the updated at (UTC).

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Get all active orders for XBTUSDTM
    active <- ft$get_order_list(query = list(status = "active", symbol = "XBTUSDTM"))
    print(active[, .(id, side, price, size, status)])

    # Get completed orders from the last 7 days
    now_ms <- as.integer(as.numeric(lubridate::now("UTC")) * 1000)
    done <- ft$get_order_list(query = list(
      status = "done",
      startAt = now_ms - 7 * 86400000L,
      endAt = now_ms
    ))
    }

------------------------------------------------------------------------

### Method `get_recent_closed_orders()`

Get Recent Closed Orders

Retrieves the most recently closed (filled or cancelled) futures orders
from the last 24 hours. This is a convenience endpoint that does not
require pagination – it returns up to 1000 records in a single response.

#### Workflow

1.  **Request**: Authenticated GET with optional `symbol` query
    parameter.

2.  **Parsing**: Returns `data.table` with all recently closed order
    records.

3.  **Timestamp Conversion**: Coerces `created_at` and `updated_at` from
    milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/recentDoneOrders`

#### Official Documentation

KuCoin Get Recent Closed Futures Orders:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-recent-closed-orders>

Verified: 2026-05-23

#### Automated Trading Usage

- **Quick Fill Check**: Rapidly check which orders completed recently
  without paginating through the full order list.

- **Slippage Analysis**: Compare `avg_deal_price` against the original
  `price` for recently filled limit orders.

- **Periodic Sync**: Poll this endpoint at intervals to update local
  order state.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/recentDoneOrders?symbol=XBTUSDTM' \
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
          "id": "234125150956625920",
          "symbol": "XBTUSDTM",
          "type": "limit",
          "side": "buy",
          "price": "50000",
          "size": 1,
          "value": "0.00002",
          "dealValue": "0.00002",
          "dealSize": 1,
          "stp": "",
          "stop": "",
          "stopPriceType": "",
          "stopTriggered": false,
          "stopPrice": null,
          "timeInForce": "GTC",
          "postOnly": false,
          "hidden": false,
          "iceberg": false,
          "leverage": "5",
          "forceHold": false,
          "closeOrder": false,
          "visibleSize": null,
          "clientOid": "my-order-001",
          "remark": null,
          "tags": null,
          "isActive": false,
          "cancelExist": false,
          "createdAt": 1729577515473,
          "updatedAt": 1729577815473,
          "endAt": 1729577815473,
          "orderTime": 1729577515473000000,
          "settleCurrency": "USDT",
          "marginMode": "ISOLATED",
          "avgDealPrice": "50100",
          "filledSize": 1,
          "filledValue": "0.00002",
          "status": "done",
          "reduceOnly": false
        }
      ]
    }

#### Usage

    KucoinFuturesTrading$get_recent_closed_orders(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) filter by futures symbol.

#### Returns

(data.table \| promise\<data.table\>) one row per order record (same
columns as `get_order_by_id()`); an empty data.table if no recently
closed orders exist:

- id (character) the record identifier.

- symbol (character) the trading pair symbol.

- type (character) the type.

- side (character) the order side.

- price (numeric \| NA) the price.

- size (numeric \| NA) the size.

- value (numeric \| NA) the order value.

- deal_value (numeric \| NA) the filled value.

- deal_size (numeric \| NA) the filled size.

- leverage (integer \| NA) the leverage.

- margin_mode (character) the margin mode.

- position_side (character) the position side.

- status (character) the status.

- created_at (POSIXct) the created at (UTC).

- updated_at (POSIXct \| NA) the updated at (UTC).

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Get recently closed orders for XBTUSDTM
    recent <- ft$get_recent_closed_orders(symbol = "XBTUSDTM")
    print(recent[, .(id, side, price, status, created_at)])

    # Get all recently closed orders
    all_recent <- ft$get_recent_closed_orders()
    }

------------------------------------------------------------------------

### Method `get_stop_orders()`

Get Stop Orders List

Retrieves a paginated list of untriggered stop orders. Stop orders are
conditional orders that become active when a trigger price is reached.
Once triggered, they appear in the regular order list.

#### Workflow

1.  **Pagination**: Uses `private$.paginate()` to fetch all pages of
    stop order records.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Timestamp Conversion**: Coerces `created_at` from milliseconds to
    POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/stopOrders`

#### Official Documentation

KuCoin Get Futures Untriggered Stop Order List:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-stop-order-list>

Verified: 2026-05-23

#### Automated Trading Usage

- **Stop-Loss Audit**: Verify that stop-loss orders are correctly placed
  and have not been accidentally cancelled.

- **Risk Dashboard**: Monitor all pending stop orders to assess
  worst-case risk exposure.

- **Strategy Sync**: Compare existing stop orders against the strategy's
  intended levels and correct any drift.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/stopOrders?symbol=XBTUSDTM&currentPage=1&pageSize=50' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currentPage": 1,
        "pageSize": 50,
        "totalNum": 1,
        "totalPage": 1,
        "items": [
          {
            "id": "234125150956625940",
            "symbol": "XBTUSDTM",
            "type": "limit",
            "side": "sell",
            "price": "55000",
            "size": 1,
            "stop": "up",
            "stopPriceType": "TP",
            "stopTriggered": false,
            "stopPrice": "54000",
            "timeInForce": "GTC",
            "leverage": "5",
            "clientOid": "stop-001",
            "isActive": true,
            "createdAt": 1729577515473,
            "marginMode": "ISOLATED",
            "status": "open",
            "reduceOnly": true
          }
        ]
      }
    }

#### Usage

    KucoinFuturesTrading$get_stop_orders(query = list())

#### Arguments

- `query`:

  (list) query parameters. Optional: `symbol`, `side`, `type`,
  `startAt`, `endAt`.

#### Returns

(data.table \| promise\<data.table\>) one row per stop order record
(same columns as `get_order_by_id()`); an empty data.table if no
untriggered stop orders exist.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Get all untriggered stop orders for XBTUSDTM
    stops <- ft$get_stop_orders(query = list(symbol = "XBTUSDTM"))
    print(stops[, .(id, side, stop_price, price, status)])

    # Get all untriggered stop orders
    all_stops <- ft$get_stop_orders()
    }

------------------------------------------------------------------------

### Method `get_fills()`

Get Trade History (Fills)

Retrieves paginated fill (trade execution) history. Each fill represents
a partial or complete execution of an order. Includes fee details,
liquidity type (maker/taker), and precise trade timestamps.

#### Workflow

1.  **Pagination**: Uses `private$.paginate()` to fetch all pages of
    fill records.

2.  **Flattening**: Combines all pages into a single `data.table` via
    `flatten_pages()`.

3.  **Timestamp Conversion**: Coerces `trade_time` from nanoseconds and
    `created_at` from milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/fills`

#### Official Documentation

[KuCoin Get Futures Filled
List](https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-trade-history)

Verified: 2026-05-23

#### Automated Trading Usage

- **PnL Calculation**: Aggregate fill prices and sizes to compute
  realized profit/loss per position.

- **Fee Tracking**: Sum fees across fills for accurate cost accounting.

- **Maker/Taker Analysis**: Monitor `liquidity` field to optimize order
  placement for fee savings.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/fills?symbol=XBTUSDTM&currentPage=1&pageSize=50' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "currentPage": 1,
        "pageSize": 50,
        "totalNum": 2,
        "totalPage": 1,
        "items": [
          {
            "symbol": "XBTUSDTM",
            "tradeId": "5ce24c1f0c19fc3c2ebc1b1a",
            "orderId": "234125150956625920",
            "side": "buy",
            "liquidity": "taker",
            "forceTaker": false,
            "price": "50100.5",
            "size": 1,
            "value": "50.1005",
            "feeRate": "0.0006",
            "fixFee": "0",
            "feeCurrency": "USDT",
            "stop": "",
            "fee": "0.0300603",
            "orderType": "limit",
            "tradeType": "trade",
            "createdAt": 1729577515473,
            "settleCurrency": "USDT",
            "openFeePay": "0.0300603",
            "closeFeePay": "0",
            "tradeTime": 1729577515473000000,
            "marginMode": "ISOLATED"
          },
          {
            "symbol": "XBTUSDTM",
            "tradeId": "5ce24c1f0c19fc3c2ebc1b1b",
            "orderId": "234125150956625921",
            "side": "sell",
            "liquidity": "maker",
            "forceTaker": false,
            "price": "51200.0",
            "size": 1,
            "value": "51.2",
            "feeRate": "0.0002",
            "fixFee": "0",
            "feeCurrency": "USDT",
            "stop": "",
            "fee": "0.01024",
            "orderType": "limit",
            "tradeType": "trade",
            "createdAt": 1729577815473,
            "settleCurrency": "USDT",
            "openFeePay": "0",
            "closeFeePay": "0.01024",
            "tradeTime": 1729577815473000000,
            "marginMode": "ISOLATED"
          }
        ]
      }
    }

#### Usage

    KucoinFuturesTrading$get_fills(query = list())

#### Arguments

- `query`:

  (list) query parameters. Optional: `orderId`, `symbol`, `side`,
  `type`, `startAt`, `endAt`.

#### Returns

(data.table \| promise\<data.table\>) one row per fill giving the
contract symbol, trade identifier, associated order ID, side, liquidity,
price, size in contracts, value in settlement currency, fee, fee
currency, fee rate, the trade datetime (POSIXct, coerced from
nanoseconds), and the record creation datetime (POSIXct, coerced from
epoch milliseconds); an empty data.table if no fills match the filters.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Get all fills for XBTUSDTM
    fills <- ft$get_fills(query = list(symbol = "XBTUSDTM"))
    print(fills[, .(trade_id, side, price, size, fee, trade_time)])

    # Get fills for a specific order
    order_fills <- ft$get_fills(query = list(orderId = "234125150956625920"))
    }

------------------------------------------------------------------------

### Method `get_recent_fills()`

Get Recent Fills

Retrieves the most recent fills (last 24 hours, max 1000 records)
without pagination. This is a convenience endpoint for quickly checking
recent trade executions.

#### Workflow

1.  **Request**: Authenticated GET with optional `symbol` query
    parameter.

2.  **Parsing**: Returns `data.table` with all recent fill records.

3.  **Timestamp Conversion**: Coerces `trade_time` from nanoseconds and
    `created_at` from milliseconds to POSIXct.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/recentFills`

#### Official Documentation

KuCoin Get Recent Futures Filled List:
<https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-recent-trade-history>

Verified: 2026-05-23

#### Automated Trading Usage

- **Real-Time Monitoring**: Poll recent fills to quickly detect new
  executions without paginating.

- **Position Updates**: Use fill data to update local position tracking
  in real time.

- **Latency Checks**: Compare `trade_time` against order placement time
  to measure execution speed.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/recentFills?symbol=XBTUSDTM' \
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
          "symbol": "XBTUSDTM",
          "tradeId": "5ce24c1f0c19fc3c2ebc1b1a",
          "orderId": "234125150956625920",
          "side": "buy",
          "liquidity": "taker",
          "forceTaker": false,
          "price": "50100.5",
          "size": 1,
          "value": "50.1005",
          "feeRate": "0.0006",
          "fixFee": "0",
          "feeCurrency": "USDT",
          "stop": "",
          "fee": "0.0300603",
          "orderType": "limit",
          "tradeType": "trade",
          "createdAt": 1729577515473,
          "settleCurrency": "USDT",
          "openFeePay": "0.0300603",
          "closeFeePay": "0",
          "tradeTime": 1729577515473000000,
          "marginMode": "ISOLATED"
        }
      ]
    }

#### Usage

    KucoinFuturesTrading$get_recent_fills(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) filter by futures symbol.

#### Returns

(data.table \| promise\<data.table\>) one row per fill (same columns as
`get_fills()`); an empty data.table if no recent fills exist:

- symbol (character) the trading pair symbol.

- trade_id (character) the trade identifier.

- order_id (character) the system order identifier.

- side (character) the order side.

- liquidity (character) the liquidity role.

- force_taker (logical) the force taker.

- price (numeric \| NA) the price.

- size (numeric \| NA) the size.

- value (numeric \| NA) the order value.

- fee_rate (numeric \| NA) the fee rate.

- fix_fee (numeric \| NA) the fix fee.

- fee_currency (character) the fee currency.

- fee (numeric \| NA) the fee.

- order_type (character) the order type.

- trade_type (character) the trade type.

- trade_time (POSIXct) the trade time (UTC).

- created_at (POSIXct) the created at (UTC).

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Get recent fills for XBTUSDTM
    recent <- ft$get_recent_fills(symbol = "XBTUSDTM")
    print(recent[, .(trade_id, side, price, size, fee, trade_time)])

    # Get all recent fills
    all_recent <- ft$get_recent_fills()
    }

------------------------------------------------------------------------

### Method `get_open_order_value()`

Get Open Order Value Statistics

Retrieves aggregate statistics about open orders for a specific futures
symbol, including total buy/sell quantity and cost. Useful for assessing
margin usage and exposure from pending orders.

#### Workflow

1.  **Request**: Authenticated GET with `symbol` as a required query
    parameter.

2.  **Parsing**: Returns a single-row `data.table` with aggregate order
    statistics.

#### API Endpoint

`GET https://api-futures.kucoin.com/api/v1/openOrderStatistics`

#### Official Documentation

[KuCoin Get Open Order
Value](https://www.kucoin.com/docs-new/rest/futures-trading/orders/get-open-order-value)

Verified: 2026-05-23

#### Automated Trading Usage

- **Margin Check**: Verify available margin before placing new orders by
  checking existing order costs.

- **Exposure Monitoring**: Track total buy vs sell open order quantities
  for risk assessment.

- **Order Capacity**: Determine remaining order capacity based on
  current open order value.

#### curl

    curl --location --request GET \
      'https://api-futures.kucoin.com/api/v1/openOrderStatistics?symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "openOrderBuySize": 5,
        "openOrderSellSize": 3,
        "openOrderBuyCost": "0.0005",
        "openOrderSellCost": "0.0003",
        "settleCurrency": "USDT"
      }
    }

#### Usage

    KucoinFuturesTrading$get_open_order_value(symbol)

#### Arguments

- `symbol`:

  (scalar\<character\>) futures symbol (e.g., `"XBTUSDTM"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the total buy order
size, total sell order size, total buy order cost, total sell order
cost, and the settlement currency:

- open_order_buy_size (integer \| NA) the open order buy size.

- open_order_sell_size (integer \| NA) the open order sell size.

- open_order_buy_cost (numeric \| NA) the open order buy cost.

- open_order_sell_cost (numeric \| NA) the open order sell cost.

- settle_currency (character) the settle currency.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()
    stats <- ft$get_open_order_value(symbol = "XBTUSDTM")
    print(stats[, .(open_order_buy_size, open_order_sell_size, settle_currency)])
    }

------------------------------------------------------------------------

### Method `set_dcp()`

Set Dead Connection Protection (DCP)

Configures a dead-man's switch that auto-cancels open futures orders if
the client stops sending heartbeat requests within the specified
timeout. This protects against scenarios where the trading bot crashes
or loses connectivity, preventing orders from remaining open
indefinitely.

#### Workflow

1.  **Build Body**: Constructs JSON body with `timeout` (required) and
    optional `symbol`.

2.  **Request**: Authenticated POST to the DCP endpoint.

3.  **Parsing**: Returns `data.table` with the configured timeout and
    applicable symbols.

#### API Endpoint

`POST https://api.kucoin.com/api/ua/v1/dcp/set`

The legacy futures-specific endpoint
(`POST /api/v1/orders/dead-cancel-all` on `api-futures.kucoin.com`) was
retired by KuCoin around 2026-05 and replaced with a unified
Universal-Trading-Account endpoint on the spot host that accepts a
`tradeType` parameter. We hardcode `tradeType = "FUTURES"` and override
the base URL to the spot host so the public method API stays unchanged.

#### Official Documentation

[KuCoin Set DCP
(Classic)](https://www.kucoin.com/docs-new/rest/ua/set-dcp-classic)

Verified: 2026-05-23

#### Automated Trading Usage

- **Safety Net**: Set DCP at bot startup so orders are cancelled if the
  bot crashes.

- **Heartbeating**: Call `set_dcp()` periodically (e.g., every 30s with
  `timeout = 60`) to refresh the timer.

- **Disable DCP**: Pass `timeout = -1` to disable the dead-man's switch.

- **Symbol Scoping**: Use `symbol` to restrict DCP to specific
  contracts.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/ua/v1/dcp/set' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw '{"timeout": 60, "symbol": "XBTUSDTM", "tradeType": "FUTURES"}'

#### JSON Request

    {
      "timeout": 60,
      "symbol": "XBTUSDTM",
      "tradeType": "FUTURES"
    }

#### JSON Response

    {
      "code": "200000",
      "data": {
        "timeout": 60,
        "symbols": "XBTUSDTM",
        "currentTime": 1729577515473
      }
    }

#### Usage

    KucoinFuturesTrading$set_dcp(timeout, symbol = NULL)

#### Arguments

- `timeout`:

  (scalar\<numeric\>) timeout in seconds. The DCP will cancel all
  applicable orders if no heartbeat (re-call of `set_dcp()`) is received
  within this period. Use `-1` to disable DCP.

- `symbol`:

  (scalar\<character\> \| NULL) restrict DCP to a specific futures
  symbol. When NULL, DCP applies to all symbols.

#### Returns

(data.table \| promise\<data.table\>) one row acknowledging the DCP
configuration change:

- trade_type (character) the trading account the setting applies to
  (always "FUTURES").

- symbol (character \| NA) the futures symbol the setting is scoped to;
  NA when it applies to all symbols.

- system_time (numeric) the server time when the setting was applied,
  epoch.

- trigger_time (numeric) the epoch time at which armed DCP would fire; 0
  when DCP is disabled.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Enable DCP with 60-second timeout for XBTUSDTM
    result <- ft$set_dcp(timeout = 60, symbol = "XBTUSDTM")
    print(result)

    # Disable DCP
    ft$set_dcp(timeout = -1)
    }

------------------------------------------------------------------------

### Method `get_dcp()`

Get Dead Connection Protection (DCP) Settings

Retrieves the current DCP configuration, including the active timeout
value, applicable symbols, and the server time of the query. Use this to
verify that DCP is correctly configured.

#### Workflow

1.  **Request**: Authenticated GET with optional `symbol` query
    parameter.

2.  **Parsing**: Returns a single-row `data.table` with the current DCP
    settings.

#### API Endpoint

`GET https://api.kucoin.com/api/ua/v1/dcp/query`

The legacy futures-specific endpoint
(`GET /api/v1/orders/dead-cancel-all/query` on `api-futures.kucoin.com`)
was retired by KuCoin around 2026-05 (the page was withdrawn and the
endpoint now returns HTTP 404) and replaced with the unified
Universal-Trading-Account endpoint that takes a `tradeType` query
parameter. We hardcode `tradeType = "FUTURES"` and override the base URL
to the spot host so the public method API stays unchanged.

#### Official Documentation

[KuCoin Get DCP
(Classic)](https://www.kucoin.com/docs-new/rest/ua/get-dcp-classic)

Verified: 2026-05-23

#### Automated Trading Usage

- **Health Check**: Periodically query DCP settings to confirm the
  safety net is active.

- **Timeout Verification**: Confirm the timeout value matches
  expectations after calling `set_dcp()`.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/ua/v1/dcp/query?tradeType=FUTURES&symbol=XBTUSDTM' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "timeout": 60,
        "symbols": "XBTUSDTM",
        "currentTime": 1729577515473
      }
    }

#### Usage

    KucoinFuturesTrading$get_dcp(symbol = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\> \| NULL) query DCP settings for a specific
  futures symbol. When NULL, returns the global DCP configuration.

#### Returns

(data.table \| promise\<data.table\>) one row giving the configured
timeout in seconds, the applicable symbols, and the server time of the
query:

- timeout (integer \| NA) the timeout.

- symbols (character) the symbols.

- current_time (numeric) the current time.

#### Examples

    \dontrun{
    ft <- KucoinFuturesTrading$new()

    # Check DCP settings for XBTUSDTM
    dcp <- ft$get_dcp(symbol = "XBTUSDTM")
    print(dcp[, .(timeout, symbols)])

    # Check global DCP settings
    dcp_global <- ft$get_dcp()
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinFuturesTrading$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
futures_trading <- KucoinFuturesTrading$new()

# Place a test order (dry run)
result <- futures_trading$add_order_test(
  clientOid = "test-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "limit",
  leverage = 5,
  size = 1,
  price = "50000"
)

# Cancel an order
futures_trading$cancel_order_by_id("order-id-here")

# Asynchronous
futures_async <- KucoinFuturesTrading$new(async = TRUE)
main <- coro::async(function() {
  orders <- await(futures_async$get_order_list(query = list(status = "active")))
  print(orders)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinFuturesTrading$add_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Place a limit buy order
result <- ft$add_order(
  clientOid = "my-order-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "limit",
  leverage = 5,
  size = 1,
  price = "50000"
)
print(result$order_id)

# Place a market sell order
result <- ft$add_order(
  clientOid = "my-order-002",
  symbol = "XBTUSDTM",
  side = "sell",
  type = "market",
  leverage = 10,
  size = 2,
  reduceOnly = TRUE
)
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$add_order_test`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Validate a limit order without placing it
result <- ft$add_order_test(
  clientOid = "test-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "limit",
  leverage = 5,
  size = 1,
  price = "50000"
)
print(result)
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$add_order_batch`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

orders <- list(
  list(clientOid = "b1", symbol = "XBTUSDTM", side = "buy",
       type = "limit", leverage = 5, size = 1, price = "49000"),
  list(clientOid = "b2", symbol = "XBTUSDTM", side = "buy",
       type = "limit", leverage = 5, size = 1, price = "48000")
)
results <- ft$add_order_batch(orders)
print(results[, .(order_id, client_oid, code)])
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$cancel_order_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()
result <- ft$cancel_order_by_id("234125150956625920")
print(result$cancelled_order_id)
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$cancel_order_by_client_oid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()
result <- ft$cancel_order_by_client_oid("my-order-001", symbol = "XBTUSDTM")
print(result$client_oid)
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$cancel_all`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Cancel all open orders for XBTUSDTM
result <- ft$cancel_all(symbol = "XBTUSDTM")
print(result$cancelled_order_id)

# Cancel all open orders across all symbols
result <- ft$cancel_all()
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$cancel_all_stop_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Cancel all stop orders for XBTUSDTM
result <- ft$cancel_all_stop_orders(symbol = "XBTUSDTM")
print(result$cancelled_order_id)

# Cancel all stop orders across all symbols
result <- ft$cancel_all_stop_orders()
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_order_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()
order <- ft$get_order_by_id("234125150956625920")
print(order[, .(id, symbol, side, price, size, status)])
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_order_by_client_oid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()
order <- ft$get_order_by_client_oid("my-order-001")
print(order[, .(id, symbol, side, price, size, status)])
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_order_list`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Get all active orders for XBTUSDTM
active <- ft$get_order_list(query = list(status = "active", symbol = "XBTUSDTM"))
print(active[, .(id, side, price, size, status)])

# Get completed orders from the last 7 days
now_ms <- as.integer(as.numeric(lubridate::now("UTC")) * 1000)
done <- ft$get_order_list(query = list(
  status = "done",
  startAt = now_ms - 7 * 86400000L,
  endAt = now_ms
))
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_recent_closed_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Get recently closed orders for XBTUSDTM
recent <- ft$get_recent_closed_orders(symbol = "XBTUSDTM")
print(recent[, .(id, side, price, status, created_at)])

# Get all recently closed orders
all_recent <- ft$get_recent_closed_orders()
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_stop_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Get all untriggered stop orders for XBTUSDTM
stops <- ft$get_stop_orders(query = list(symbol = "XBTUSDTM"))
print(stops[, .(id, side, stop_price, price, status)])

# Get all untriggered stop orders
all_stops <- ft$get_stop_orders()
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_fills`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Get all fills for XBTUSDTM
fills <- ft$get_fills(query = list(symbol = "XBTUSDTM"))
print(fills[, .(trade_id, side, price, size, fee, trade_time)])

# Get fills for a specific order
order_fills <- ft$get_fills(query = list(orderId = "234125150956625920"))
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_recent_fills`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Get recent fills for XBTUSDTM
recent <- ft$get_recent_fills(symbol = "XBTUSDTM")
print(recent[, .(trade_id, side, price, size, fee, trade_time)])

# Get all recent fills
all_recent <- ft$get_recent_fills()
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_open_order_value`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()
stats <- ft$get_open_order_value(symbol = "XBTUSDTM")
print(stats[, .(open_order_buy_size, open_order_sell_size, settle_currency)])
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$set_dcp`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Enable DCP with 60-second timeout for XBTUSDTM
result <- ft$set_dcp(timeout = 60, symbol = "XBTUSDTM")
print(result)

# Disable DCP
ft$set_dcp(timeout = -1)
} # }

## ------------------------------------------------
## Method `KucoinFuturesTrading$get_dcp`
## ------------------------------------------------

if (FALSE) { # \dontrun{
ft <- KucoinFuturesTrading$new()

# Check DCP settings for XBTUSDTM
dcp <- ft$get_dcp(symbol = "XBTUSDTM")
print(dcp[, .(timeout, symbols)])

# Check global DCP settings
dcp_global <- ft$get_dcp()
} # }
```
