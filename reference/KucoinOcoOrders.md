# KucoinOcoOrders: OCO Order Management

KucoinOcoOrders: OCO Order Management

KucoinOcoOrders: OCO Order Management

## Details

Provides methods for managing OCO (One-Cancels-Other) orders on KuCoin
Spot. Inherits from
[KucoinBase](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md).

### Purpose and Scope

- **Order Placement**: Place OCO orders combining a limit order with a
  stop-limit order, where triggering one automatically cancels the
  other.

- **Order Cancellation**: Cancel OCO orders by order ID, client OID, or
  in batch.

- **Order Queries**: Retrieve OCO order summaries, detailed sub-order
  breakdowns, and paginated order lists with filtering.

### Usage

All methods require authentication (valid API key, secret, passphrase).
OCO orders are useful for setting simultaneous take-profit and stop-loss
levels on a position. When one side fills, the other is automatically
cancelled.

    oco <- KucoinOcoOrders$new()

    # Place an OCO order: limit sell at 110k, stop-limit sell at 90k
    order <- oco$add_order(
      symbol = "BTC-USDT", side = "sell",
      price = "110000", size = "0.0001",
      stopPrice = "90000", limitPrice = "89500"
    )

    # List all OCO orders
    orders <- oco$get_order_list()

### Official Documentation

[KuCoin Spot OCO
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-oco-order)

### Endpoints Covered

|  |  |  |
|----|----|----|
| Method | Endpoint | HTTP |
| add_order | POST /api/v3/oco/order | POST |
| cancel_order_by_id | DELETE /api/v3/oco/order/{orderId} | DELETE |
| cancel_order_by_client_oid | DELETE /api/v3/oco/client-order/{clientOid} | DELETE |
| cancel_all | DELETE /api/v3/oco/orders | DELETE |
| get_order_by_id | GET /api/v3/oco/order/{orderId} | GET |
| get_order_by_client_oid | GET /api/v3/oco/client-order/{clientOid} | GET |
| get_order_detail_by_id | GET /api/v3/oco/order/details/{orderId} | GET |
| get_order_list | GET /api/v3/oco/orders | GET |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`kucoin::KucoinBase`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.md)
-\> `KucoinOcoOrders`

## Methods

### Public methods

- [`KucoinOcoOrders$add_order()`](#method-KucoinOcoOrders-add_order)

- [`KucoinOcoOrders$cancel_order_by_id()`](#method-KucoinOcoOrders-cancel_order_by_id)

- [`KucoinOcoOrders$cancel_order_by_client_oid()`](#method-KucoinOcoOrders-cancel_order_by_client_oid)

- [`KucoinOcoOrders$cancel_all()`](#method-KucoinOcoOrders-cancel_all)

- [`KucoinOcoOrders$get_order_by_id()`](#method-KucoinOcoOrders-get_order_by_id)

- [`KucoinOcoOrders$get_order_by_client_oid()`](#method-KucoinOcoOrders-get_order_by_client_oid)

- [`KucoinOcoOrders$get_order_detail_by_id()`](#method-KucoinOcoOrders-get_order_detail_by_id)

- [`KucoinOcoOrders$get_order_list()`](#method-KucoinOcoOrders-get_order_list)

- [`KucoinOcoOrders$clone()`](#method-KucoinOcoOrders-clone)

Inherited methods

- [`kucoin::KucoinBase$initialize()`](https://dereckscompany.github.io/kucoin/reference/KucoinBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_order()`

Place an OCO Order

Places a new OCO (One-Cancels-Other) order on KuCoin Spot. An OCO order
combines a limit order with a stop-limit order. When one side triggers
or fills, the other side is automatically cancelled.

#### Workflow

1.  **Validation**: Verifies `symbol` format and matches `side` against
    allowed values.

2.  **Body Construction**: Builds the request body with price, size,
    stop, and limit parameters.

3.  **Request**: Authenticated POST to the OCO order endpoint.

4.  **Parsing**: Returns `data.table` with the assigned `order_id`.

#### API Endpoint

`POST https://api.kucoin.com/api/v3/oco/order`

#### Official Documentation

[KuCoin Add OCO
Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-oco-order)

Verified: 2026-05-23

#### Automated Trading Usage

- **Take-Profit + Stop-Loss**: Place a sell OCO with `price` as
  take-profit and `stopPrice`/`limitPrice` as stop-loss to protect
  positions automatically.

- **Bracket Entry**: Use a buy OCO to enter a position at a limit price
  while also setting a stop-entry above resistance.

- **Client OID Tracking**: Set `clientOid` to a unique strategy
  identifier for programmatic order tracking and reconciliation.

#### curl

    curl --location --request POST 'https://api.kucoin.com/api/v3/oco/order' \
      --header 'Content-Type: application/json' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2' \
      --data-raw \
      '{"symbol":"BTC-USDT","side":"sell","price":"110000","size":"0.0001","stopPrice":"90000","limitPrice":"89500",
      "tradeType":"TRADE"}'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "674c40d38b4b2f00073deef3"
      }
    }

#### Usage

    KucoinOcoOrders$add_order(
      symbol,
      side,
      price,
      size,
      stop_price,
      limit_price,
      client_order_id = NULL,
      remark = NULL,
      trade_type = "TRADE"
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) trading pair (e.g., `"BTC-USDT"`); must match
  the `BASE-QUOTE` format validated by
  [`verify_symbol()`](https://dereckscompany.github.io/kucoin/reference/verify_symbol.md).

- `side`:

  (scalar\<character\>) order side, one of `"buy"` or `"sell"`.

- `price`:

  (scalar\<numeric\> \| scalar\<character\>) limit order price for the
  take-profit leg; must align with the symbol's `priceIncrement`.

- `size`:

  (scalar\<numeric\> \| scalar\<character\>) order quantity in base
  currency (e.g., `"0.0001"` BTC); must align with the symbol's
  `baseIncrement`.

- `stop_price`:

  (scalar\<numeric\> \| scalar\<character\>) trigger price for the
  stop-limit leg; when the market reaches this price the stop-limit
  order is activated.

- `limit_price`:

  (scalar\<numeric\> \| scalar\<character\>) limit price for the
  stop-limit leg after the stop is triggered; this is the price at which
  the stop-limit order is placed.

- `client_order_id`:

  (scalar\<character\> \| NULL) unique client-assigned order identifier
  (max 40 characters); useful for idempotent order placement and
  tracking.

- `remark`:

  (scalar\<character\> \| NULL) order remarks or notes (max 20
  characters).

- `trade_type`:

  (scalar\<character\>) trade type, defaults to `"TRADE"` for spot
  trading.

#### Returns

(data.table \| promise\<data.table\>) one row giving the KuCoin-assigned
OCO order identifier and the client-provided order identifier (NA if not
supplied):

- order_id (character) the system order identifier.

- client_oid (character \| NA) the client-supplied order identifier.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Sell OCO: take-profit at 110k, stop-loss at 90k
    order <- oco$add_order(
      symbol = "BTC-USDT", side = "sell",
      price = "110000", size = "0.0001",
      stopPrice = "90000", limitPrice = "89500"
    )
    print(order$order_id)

    # Buy OCO with client OID for tracking
    order <- oco$add_order(
      symbol = "ETH-USDT", side = "buy",
      price = "3000", size = "0.01",
      stopPrice = "3500", limitPrice = "3550",
      clientOid = "my-bot-oco-001"
    )
    }

------------------------------------------------------------------------

### Method `cancel_order_by_id()`

Cancel OCO Order by Order ID

Cancels an active OCO order using its KuCoin-assigned order ID. Both the
limit and stop-limit legs of the OCO order are cancelled.

#### Workflow

1.  **Request**: Authenticated DELETE to the order-specific endpoint.

2.  **Cancellation**: KuCoin cancels both legs of the OCO order.

3.  **Parsing**: Returns `data.table` with the cancelled order IDs.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v3/oco/order/{orderId}`

#### Official Documentation

KuCoin Cancel OCO Order By OrderId:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-orderld>

Verified: 2026-05-23

#### Automated Trading Usage

- **Position Exit**: Cancel an OCO order when manually closing a
  position or switching strategies.

- **Order Replacement**: Cancel the existing OCO and place a new one
  with updated price levels.

- **Error Recovery**: Cancel orphaned OCO orders detected during
  periodic order audits.

#### curl

    curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/order/674c40d38b4b2f00073deef3' \
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
          "674c40d38b4b2f00073deef3",
          "674c40d38b4b2f00073deef4",
          "674c40d38b4b2f00073deef5"
        ]
      }
    }

#### Usage

    KucoinOcoOrders$cancel_order_by_id(order_id)

#### Arguments

- `order_id`:

  (scalar\<character\>) the KuCoin-assigned OCO order ID to cancel
  (e.g., `"674c40d38b4b2f00073deef3"`).

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order giving
the cancelled order ID (the parent OCO and each of its sub-orders appear
as separate rows); an empty data.table if nothing matched.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Cancel a specific OCO order
    result <- oco$cancel_order_by_id("674c40d38b4b2f00073deef3")
    print(result$cancelled_order_id)
    }

------------------------------------------------------------------------

### Method `cancel_order_by_client_oid()`

Cancel OCO Order by Client OID

Cancels an active OCO order using the client-assigned order ID
(`clientOid`). Both the limit and stop-limit legs of the OCO order are
cancelled.

#### Workflow

1.  **Request**: Authenticated DELETE to the client-order endpoint.

2.  **Lookup**: KuCoin resolves the `clientOid` to the internal OCO
    order.

3.  **Cancellation**: Both legs of the OCO order are cancelled.

4.  **Parsing**: Returns `data.table` with cancelled order IDs.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v3/oco/client-order/{clientOid}`

#### Official Documentation

KuCoin Cancel OCO Order By ClientOid:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-clientoid>

Verified: 2026-05-23

#### Automated Trading Usage

- **Strategy-Based Cancellation**: Cancel OCO orders by your own
  strategy IDs without needing to store KuCoin order IDs.

- **Idempotent Operations**: Use deterministic `clientOid` values so
  re-running cancellation logic is safe.

- **Multi-Bot Coordination**: Each bot uses a unique `clientOid` prefix
  to manage its own OCO orders independently.

#### curl

    curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/client-order/my-bot-oco-001' \
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
          "674c40d38b4b2f00073deef3",
          "674c40d38b4b2f00073deef4",
          "674c40d38b4b2f00073deef5"
        ]
      }
    }

#### Usage

    KucoinOcoOrders$cancel_order_by_client_oid(client_order_id)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) the client-assigned order ID used when placing
  the OCO order (e.g., `"my-bot-oco-001"`).

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order giving
the cancelled order ID (the parent OCO and each of its sub-orders appear
as separate rows); an empty data.table if nothing matched.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Cancel by client-assigned ID
    result <- oco$cancel_order_by_client_oid("my-bot-oco-001")
    print(result$cancelled_order_id)
    }

------------------------------------------------------------------------

### Method `cancel_all()`

Cancel All OCO Orders

Cancels all active OCO orders matching the given filters. Can filter by
`symbol` or specify individual `orderIds`. If no filters are provided,
all active OCO orders are cancelled.

#### Workflow

1.  **Filter Construction**: Builds query parameters from the provided
    filter list.

2.  **Request**: Authenticated DELETE to the batch cancellation
    endpoint.

3.  **Cancellation**: KuCoin cancels all matching OCO orders.

4.  **Parsing**: Returns `data.table` with cancelled order IDs.

#### API Endpoint

`DELETE https://api.kucoin.com/api/v3/oco/orders`

#### Official Documentation

[KuCoin Batch Cancel OCO
Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-cancel-oco-order)

Verified: 2026-05-23

#### Automated Trading Usage

- **Emergency Kill Switch**: Call with no filters to cancel all OCO
  orders during market anomalies or system errors.

- **Symbol Cleanup**: Pass `symbol` to cancel all OCO orders for a
  specific pair when exiting a position entirely.

- **Selective Batch Cancel**: Pass specific `orderIds` to cancel a
  subset of OCO orders during strategy rebalancing.

#### curl

    curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/orders?symbol=BTC-USDT' \
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
          "674c40d38b4b2f00073deef3",
          "674c40d38b4b2f00073deef4",
          "674c40d38b4b2f00073deef5",
          "674c40d38b4b2f00073deef6"
        ]
      }
    }

#### Usage

    KucoinOcoOrders$cancel_all(query = list())

#### Arguments

- `query`:

  (list) optional filter parameters for batch cancellation. Supported
  keys: `symbol` (trading pair to filter by e.g. `"BTC-USDT"`) and
  `orderIds` (comma-separated order IDs to cancel specifically). If
  empty, all active OCO orders are cancelled.

#### Returns

(data.table \| promise\<data.table\>) one row per cancelled order giving
the cancelled order ID; an empty data.table if no active OCO orders
matched the filter.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Cancel all OCO orders for BTC-USDT
    result <- oco$cancel_all(query = list(symbol = "BTC-USDT"))
    print(result$cancelled_order_id)

    # Cancel all OCO orders (no filter)
    result <- oco$cancel_all()
    }

------------------------------------------------------------------------

### Method `get_order_by_id()`

Get OCO Order by Order ID

Retrieves summary information for a specific OCO order using its
KuCoin-assigned order ID. Returns the OCO order metadata without
detailed sub-order information (use `get_order_detail_by_id()` for
that).

#### Workflow

1.  **Request**: Authenticated GET to the order-specific endpoint.

2.  **Response**: KuCoin returns the OCO order summary.

3.  **Parsing**: Returns `data.table` with order metadata.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/oco/order/{orderId}`

#### Official Documentation

KuCoin Get OCO Order By OrderId:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-orderld>

Verified: 2026-05-23

#### Automated Trading Usage

- **Status Polling**: Periodically check OCO order status to determine
  if either leg has triggered.

- **Audit Logging**: Retrieve order metadata for trade journal and
  performance tracking.

- **Conditional Logic**: Check the `status` field to decide whether to
  place replacement orders.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v3/oco/order/674c40d38b4b2f00073deef3' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "674c40d38b4b2f00073deef3",
        "symbol": "BTC-USDT",
        "clientOid": "my-bot-oco-001",
        "orderTime": 1729176273859,
        "status": "NEW"
      }
    }

#### Usage

    KucoinOcoOrders$get_order_by_id(order_id)

#### Arguments

- `order_id`:

  (scalar\<character\>) the KuCoin-assigned OCO order ID (e.g.,
  `"674c40d38b4b2f00073deef3"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the OCO order
identifier, trading pair, client-assigned order identifier, order
creation datetime (POSIXct, coerced from epoch milliseconds), and order
status (e.g., `"NEW"`, `"DONE"`, `"TRIGGERED"`):

- order_id (character) the system order identifier.

- symbol (character) the trading pair symbol.

- client_oid (character \| NA) the client-supplied order identifier.

- order_time (POSIXct) the order time (UTC).

- status (character) the status.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Get OCO order summary
    order <- oco$get_order_by_id("674c40d38b4b2f00073deef3")
    print(order$status)
    print(order$symbol)
    }

------------------------------------------------------------------------

### Method `get_order_by_client_oid()`

Get OCO Order by Client OID

Retrieves summary information for a specific OCO order using the
client-assigned order ID (`clientOid`). Useful when you track orders by
your own identifiers rather than KuCoin-assigned IDs.

#### Workflow

1.  **Request**: Authenticated GET to the client-order endpoint.

2.  **Lookup**: KuCoin resolves the `clientOid` to the internal OCO
    order.

3.  **Parsing**: Returns `data.table` with order metadata.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/oco/client-order/{clientOid}`

#### Official Documentation

KuCoin Get OCO Order By ClientOid:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-clientoid>

Verified: 2026-05-23

#### Automated Trading Usage

- **Strategy Reconciliation**: Look up OCO orders using your
  strategy-generated IDs for post-trade analysis.

- **Duplicate Detection**: Check if an OCO order with a given
  `clientOid` already exists before placing a new one.

- **Bot State Recovery**: On restart, recover OCO order state using
  stored `clientOid` values.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v3/oco/client-order/my-bot-oco-001' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "674c40d38b4b2f00073deef3",
        "symbol": "BTC-USDT",
        "clientOid": "my-bot-oco-001",
        "orderTime": 1729176273859,
        "status": "NEW"
      }
    }

#### Usage

    KucoinOcoOrders$get_order_by_client_oid(client_order_id)

#### Arguments

- `client_order_id`:

  (scalar\<character\>) the client-assigned order ID used when placing
  the OCO order (e.g., `"my-bot-oco-001"`).

#### Returns

(data.table \| promise\<data.table\>) one row giving the KuCoin-assigned
OCO order identifier, trading pair, client-assigned order identifier,
order creation datetime (POSIXct, coerced from epoch milliseconds), and
order status (e.g., `"NEW"`, `"DONE"`, `"TRIGGERED"`):

- order_id (character) the system order identifier.

- symbol (character) the trading pair symbol.

- client_oid (character \| NA) the client-supplied order identifier.

- order_time (POSIXct) the order time (UTC).

- status (character) the status.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Retrieve by client OID
    order <- oco$get_order_by_client_oid("my-bot-oco-001")
    print(order$order_id)
    print(order$status)
    }

------------------------------------------------------------------------

### Method `get_order_detail_by_id()`

Get OCO Order Details by Order ID

Retrieves detailed information for a specific OCO order, including the
individual sub-orders (limit leg and stop-limit leg) and their
respective statuses. This provides more information than
`get_order_by_id()`.

#### Workflow

1.  **Request**: Authenticated GET to the order details endpoint.

2.  **Response**: KuCoin returns the OCO order with full sub-order
    breakdown.

3.  **Parsing**: Returns `data.table` with detailed order information.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/oco/order/details/{orderId}`

#### Official Documentation

KuCoin Get OCO Order Detail By OrderId:
<https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-detail-by-orderld>

Verified: 2026-05-23

#### Automated Trading Usage

- **Fill Analysis**: Inspect sub-order details to determine which leg
  filled and at what price.

- **Partial Fill Detection**: Check individual sub-order fill quantities
  for partial execution scenarios.

- **Trade Journaling**: Extract complete execution details for
  performance attribution and reporting.

#### curl

    curl --location --request GET 'https://api.kucoin.com/api/v3/oco/order/details/674c40d38b4b2f00073deef3' \
      --header 'KC-API-KEY: your-api-key' \
      --header 'KC-API-SIGN: your-signature' \
      --header 'KC-API-TIMESTAMP: 1729176273859' \
      --header 'KC-API-PASSPHRASE: your-passphrase' \
      --header 'KC-API-KEY-VERSION: 2'

#### JSON Response

    {
      "code": "200000",
      "data": {
        "orderId": "674c40d38b4b2f00073deef3",
        "symbol": "BTC-USDT",
        "clientOid": "my-bot-oco-001",
        "orderTime": 1729176273859,
        "status": "NEW",
        "orders": [
          {
            "id": "674c40d38b4b2f00073deef4",
            "symbol": "BTC-USDT",
            "side": "sell",
            "price": "110000",
            "size": "0.0001",
            "status": "NEW"
          },
          {
            "id": "674c40d38b4b2f00073deef5",
            "symbol": "BTC-USDT",
            "side": "sell",
            "price": "89500",
            "stopPrice": "90000",
            "size": "0.0001",
            "status": "NEW"
          }
        ]
      }
    }

#### Usage

    KucoinOcoOrders$get_order_detail_by_id(order_id)

#### Arguments

- `order_id`:

  (scalar\<character\>) the KuCoin-assigned OCO order ID (e.g.,
  `"674c40d38b4b2f00073deef3"`).

#### Returns

(data.table \| promise\<data.table\>) one row per sub-order, each giving
the OCO order identifier, trading pair, client-assigned order
identifier, order creation datetime (POSIXct, coerced from epoch
milliseconds), and overall OCO order status, with the nested `orders`
array (typically the limit leg plus the stop-limit leg) exploded to long
format by replicating the parent OCO row once per sub-order and adding
each sub-order's id, symbol, side, price, size, status, and stop price
(present only on the stop leg) as `sub_order_`-prefixed columns:

- order_id (character) the system order identifier.

- symbol (character) the trading pair symbol.

- client_oid (character \| NA) the client-supplied order identifier.

- order_time (POSIXct) the order time (UTC).

- status (character) the status.

- sub_order_id (character) the sub order id.

- sub_order_symbol (character) the sub order symbol.

- sub_order_side (character) the sub order side.

- sub_order_price (numeric \| NA) the sub order price.

- sub_order_size (numeric \| NA) the sub order size.

- sub_order_status (character) the sub order status.

- sub_order_stop_price (numeric \| NA) the sub order stop price.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Get full OCO order details with sub-orders. The `orders` array
    # is exploded to long format, so each sub-order is its own row
    # with `sub_order_*` columns alongside the parent OCO fields.
    details <- oco$get_order_detail_by_id("674c40d38b4b2f00073deef3")
    details[, .(order_id, status, sub_order_id, sub_order_side, sub_order_price)]
    }

------------------------------------------------------------------------

### Method `get_order_list()`

Get OCO Order List

Retrieves a paginated list of OCO orders with optional filtering by
symbol, time range, and pagination parameters. Returns all OCO orders
matching the specified criteria.

#### Workflow

1.  **Filter Construction**: Builds query parameters from the provided
    filter list.

2.  **Request**: Authenticated GET to the order list endpoint.

3.  **Pagination**: KuCoin returns a paginated response with `items`
    array.

4.  **Parsing**: Binds all items into a single `data.table` using
    `rbindlist()`.

#### API Endpoint

`GET https://api.kucoin.com/api/v3/oco/orders`

#### Official Documentation

[KuCoin Get OCO Order
List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-list)

Verified: 2026-05-23

#### Automated Trading Usage

- **Portfolio Overview**: List all active OCO orders to display current
  take-profit/stop-loss levels across positions.

- **Stale Order Detection**: Filter by `startAt`/`endAt` to find OCO
  orders that have been open too long and may need adjustment.

- **Pagination Loop**: Use `currentPage` and `pageSize` to iterate
  through large result sets in batch processing.

#### curl

    curl --location --request GET \
      'https://api.kucoin.com/api/v3/oco/orders?symbol=BTC-USDT&pageSize=20&currentPage=1' \
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
        "pageSize": 20,
        "totalNum": 2,
        "totalPage": 1,
        "items": [
          {
            "orderId": "674c40d38b4b2f00073deef3",
            "symbol": "BTC-USDT",
            "clientOid": "my-bot-oco-001",
            "orderTime": 1729176273859,
            "status": "NEW"
          },
          {
            "orderId": "674c40d38b4b2f00073deef6",
            "symbol": "ETH-USDT",
            "clientOid": "my-bot-oco-002",
            "orderTime": 1729176274000,
            "status": "TRIGGERED"
          }
        ]
      }
    }

#### Usage

    KucoinOcoOrders$get_order_list(query = list())

#### Arguments

- `query`:

  (list) optional filter and pagination parameters. Supported keys:
  `symbol` (trading pair to filter by e.g. `"BTC-USDT"`), `startAt`
  (start time in milliseconds, inclusive), `endAt` (end time in
  milliseconds, inclusive), `pageSize` (number of results per page,
  default 20, max 100), and `currentPage` (page number to retrieve,
  default 1).

#### Returns

(data.table \| promise\<data.table\>) one row per OCO order, each giving
the OCO order identifier, trading pair, client-assigned order
identifier, order creation datetime (POSIXct, coerced from epoch
milliseconds), and order status (e.g., `"NEW"`, `"DONE"`,
`"TRIGGERED"`); an empty data.table if no orders match.

#### Examples

    \dontrun{
    oco <- KucoinOcoOrders$new()

    # Get all OCO orders
    orders <- oco$get_order_list()
    print(orders)

    # Filter by symbol with pagination
    orders <- oco$get_order_list(query = list(
      symbol = "BTC-USDT",
      pageSize = 50,
      currentPage = 1
    ))
    print(orders)

    # Filter by time range
    orders <- oco$get_order_list(query = list(
      startAt = as.numeric(lubridate::now() - 86400) * 1000,
      endAt = as.numeric(lubridate::now()) * 1000
    ))
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    KucoinOcoOrders$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous
oco <- KucoinOcoOrders$new()
orders <- oco$get_order_list()
print(orders)

# Asynchronous
oco_async <- KucoinOcoOrders$new(async = TRUE)
main <- coro::async(function() {
  orders <- await(oco_async$get_order_list())
  print(orders)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `KucoinOcoOrders$add_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Sell OCO: take-profit at 110k, stop-loss at 90k
order <- oco$add_order(
  symbol = "BTC-USDT", side = "sell",
  price = "110000", size = "0.0001",
  stopPrice = "90000", limitPrice = "89500"
)
print(order$order_id)

# Buy OCO with client OID for tracking
order <- oco$add_order(
  symbol = "ETH-USDT", side = "buy",
  price = "3000", size = "0.01",
  stopPrice = "3500", limitPrice = "3550",
  clientOid = "my-bot-oco-001"
)
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$cancel_order_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Cancel a specific OCO order
result <- oco$cancel_order_by_id("674c40d38b4b2f00073deef3")
print(result$cancelled_order_id)
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$cancel_order_by_client_oid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Cancel by client-assigned ID
result <- oco$cancel_order_by_client_oid("my-bot-oco-001")
print(result$cancelled_order_id)
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$cancel_all`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Cancel all OCO orders for BTC-USDT
result <- oco$cancel_all(query = list(symbol = "BTC-USDT"))
print(result$cancelled_order_id)

# Cancel all OCO orders (no filter)
result <- oco$cancel_all()
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$get_order_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Get OCO order summary
order <- oco$get_order_by_id("674c40d38b4b2f00073deef3")
print(order$status)
print(order$symbol)
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$get_order_by_client_oid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Retrieve by client OID
order <- oco$get_order_by_client_oid("my-bot-oco-001")
print(order$order_id)
print(order$status)
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$get_order_detail_by_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Get full OCO order details with sub-orders. The `orders` array
# is exploded to long format, so each sub-order is its own row
# with `sub_order_*` columns alongside the parent OCO fields.
details <- oco$get_order_detail_by_id("674c40d38b4b2f00073deef3")
details[, .(order_id, status, sub_order_id, sub_order_side, sub_order_price)]
} # }

## ------------------------------------------------
## Method `KucoinOcoOrders$get_order_list`
## ------------------------------------------------

if (FALSE) { # \dontrun{
oco <- KucoinOcoOrders$new()

# Get all OCO orders
orders <- oco$get_order_list()
print(orders)

# Filter by symbol with pagination
orders <- oco$get_order_list(query = list(
  symbol = "BTC-USDT",
  pageSize = 50,
  currentPage = 1
))
print(orders)

# Filter by time range
orders <- oco$get_order_list(query = list(
  startAt = as.numeric(lubridate::now() - 86400) * 1000,
  endAt = as.numeric(lubridate::now()) * 1000
))
} # }
```
