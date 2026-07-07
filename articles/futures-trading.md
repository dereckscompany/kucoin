# Futures Trading with kucoin

This vignette covers KuCoin Futures trading using the `kucoin` package.
Futures contracts let you trade with leverage — amplifying both gains
and losses — on perpetual contracts like XBTUSDTM (BTC) and ETHUSDTM
(ETH).

## Overview

The package provides three classes for futures operations:

| Class | Purpose |
|----|----|
| `KucoinFuturesMarketData` | Contract specs, tickers, orderbooks, klines, funding rates |
| `KucoinFuturesTrading` | Place, cancel, and query futures orders |
| `KucoinFuturesAccount` | Positions, margin, leverage, risk limits |

All futures classes use a separate base URL
(`https://api-futures.kucoin.com`) but share the same API key
credentials as spot trading.

## Setup

``` r

box::use(
  kucoin[
    KucoinFuturesMarketData, KucoinFuturesTrading, KucoinFuturesAccount,
    get_api_keys
  ]
)

keys <- get_api_keys(
  api_key = "your-api-key",
  api_secret = "your-api-secret",
  api_passphrase = "your-api-passphrase"
)

market <- KucoinFuturesMarketData$new(keys = keys)
trading <- KucoinFuturesTrading$new(keys = keys)
account <- KucoinFuturesAccount$new(keys = keys)
```

------------------------------------------------------------------------

## Market Data

### Contract Details

Query the specification of a futures contract — lot sizes, tick sizes,
leverage limits, and fee rates:

``` r

contract <- market$get_contract(symbol = "XBTUSDTM")
contract[, .(symbol, max_leverage, tick_size, maker_fee_rate, taker_fee_rate)]
```

    #>      symbol max_leverage tick_size maker_fee_rate taker_fee_rate
    #>      <char>        <int>     <num>          <num>          <num>
    #> 1: XBTUSDTM          125       0.1          2e-04          6e-04

### All Active Contracts

``` r

contracts <- market$get_all_contracts()
contracts[, .(symbol, status)]
```

    #>      symbol status
    #>      <char> <char>
    #> 1: XBTUSDTM   Open
    #> 2: ETHUSDTM   Open

### Ticker

Real-time price and best bid/ask for a single contract:

``` r

ticker <- market$get_ticker(symbol = "XBTUSDTM")
ticker[, .(symbol, price, best_bid_price, best_ask_price, ts)]
```

    #>      symbol price best_bid_price best_ask_price                  ts
    #>      <char> <num>          <num>          <num>              <POSc>
    #> 1: XBTUSDTM 98250        98249.9        98250.1 2024-10-17 10:04:19

### All Tickers

``` r

tickers <- market$get_all_tickers()
tickers[, .(symbol, price, ts)]
```

    #>      symbol    price                  ts
    #>      <char>    <num>              <POSc>
    #> 1: XBTUSDTM 98250.00 2024-10-17 10:04:19
    #> 2: ETHUSDTM  3456.78 2024-10-17 10:04:19

### Orderbook

The partial orderbook returns the top 20 or 100 price levels:

``` r

ob <- market$get_part_orderbook(symbol = "XBTUSDTM", size = 20)
ob
```

    #>                     ts sequence   side level   price  size   symbol
    #>                 <POSc>   <char> <char> <int>   <num> <num>   <char>
    #> 1: 2024-10-17 10:04:19      100    bid     1 98249.9    50 XBTUSDTM
    #> 2: 2024-10-17 10:04:19      100    bid     2 98249.0   100 XBTUSDTM
    #> 3: 2024-10-17 10:04:19      100    ask     1 98250.1    30 XBTUSDTM
    #> 4: 2024-10-17 10:04:19      100    ask     2 98251.0    75 XBTUSDTM

### Trade History

``` r

trades <- market$get_trade_history(symbol = "XBTUSDTM")
trades[, .(side, price, size, ts)]
```

    #>      side price  size                  ts
    #>    <char> <num> <num>              <POSc>
    #> 1:    buy 98250     1 2024-10-17 10:04:19
    #> 2:   sell 98251     2 2024-10-17 10:04:19

### Klines (Candlesticks)

Retrieve historical OHLCV data. Granularity is in minutes:

``` r

klines <- market$get_klines(symbol = "XBTUSDTM", granularity = 60)
klines
```

    #>               datetime  open  high   low close volume turnover
    #>                 <POSc> <num> <num> <num> <num>  <num>    <num>
    #> 1: 2024-10-17 09:00:00 98100 98300 98000 98250    150 14737500
    #> 2: 2024-10-17 10:00:00 98250 98400 98200 98350    120 11802000
    #> 3: 2024-10-17 11:00:00 98350 98500 98300 98450    100  9845000

### Mark Price

The mark price is used for liquidation calculations and PNL:

``` r

mark <- market$get_mark_price(symbol = "XBTUSDTM")
mark
```

    #>      symbol granularity          time_point   value index_price
    #>      <char>       <int>              <POSc>   <num>       <num>
    #> 1: XBTUSDTM        1000 2024-10-17 10:04:19 98252.1    98232.45

### Funding Rate

Perpetual futures settle funding every 8 hours. Positive rates mean
longs pay shorts; negative means shorts pay longs:

``` r

rate <- market$get_funding_rate(symbol = "XBTUSDTM")
rate
```

    #>      symbol granularity          time_point value daily_interest_rate
    #>      <char>       <int>              <POSc> <num>               <num>
    #> 1: XBTUSDTM    28800000 2024-10-17 08:00:00 1e-04               3e-04
    #>    funding_rate_cap funding_rate_floor period        funding_time
    #>               <num>              <num>  <int>              <POSc>
    #> 1:            0.003             -0.003      1 2024-10-17 16:00:00

### Server Time and Status

``` r

market$get_server_time()
market$get_service_status()
```

    #>            server_time
    #>                 <POSc>
    #> 1: 2024-10-17 10:04:19
    #>    status    msg
    #>    <char> <char>
    #> 1:   open

------------------------------------------------------------------------

## Trading

All trading methods require API keys with **Futures trading permission**
enabled on KuCoin.

### Place an Order (Dry Run)

Use `add_order_test()` to validate parameters without placing a real
order:

``` r

result <- trading$add_order_test(
  client_order_id = "my-test-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "limit",
  leverage = 5,
  size = 1,
  price = "98000"
)
result
```

    #>             order_id         client_oid
    #>               <char>             <char>
    #> 1: futures-order-001 futures-client-001

### Place a Real Order

``` r

# Market order — no price needed
order <- trading$add_order(
  client_order_id = "my-market-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "market",
  leverage = 10,
  size = 1
)

# Limit order
order <- trading$add_order(
  client_order_id = "my-limit-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "limit",
  leverage = 5,
  size = 1,
  price = "95000",
  time_in_force = "GTC"
)
```

### Cancel Orders

``` r

# Cancel by system order ID
trading$cancel_order_by_id(order_id = "order-id-here")

# Cancel by client order ID
trading$cancel_order_by_client_oid(client_order_id = "my-limit-001", symbol = "XBTUSDTM")

# Cancel all orders for a symbol
trading$cancel_all(symbol = "XBTUSDTM")

# Cancel all stop orders
trading$cancel_all_stop_orders(symbol = "XBTUSDTM")
```

### Query Orders

``` r

# Get a specific order
order <- trading$get_order_by_id(order_id = "order-id")

# Get open orders
open <- trading$get_order_list(query = list(status = "active"))

# Get recent closed orders
closed <- trading$get_recent_closed_orders(symbol = "XBTUSDTM")
```

### Fills (Trade History)

``` r

# All fills
fills <- trading$get_fills(query = list(symbol = "XBTUSDTM"))

# Recent fills (last 24h)
recent <- trading$get_recent_fills(symbol = "XBTUSDTM")
```

### Dead Connection Protection (DCP)

A dead-man’s switch that auto-cancels orders if your bot stops sending
heartbeats:

``` r

# Set DCP with 5-second timeout
trading$set_dcp(timeout = 5)

# Check current DCP settings
trading$get_dcp()
```

    #>    trade_type symbol system_time trigger_time
    #>        <char> <char>       <num>        <num>
    #> 1:    FUTURES   <NA>  1729159459            0
    #>    timeout symbols current_time
    #>      <int>  <char>        <num>
    #> 1:       5         1.729159e+12

------------------------------------------------------------------------

## Account and Positions

### Account Overview

``` r

overview <- account$get_account_overview(currency = "USDT")
overview[, .(account_equity, available_balance, unrealised_pnl, currency)]
```

    #>    account_equity available_balance unrealised_pnl currency
    #>             <num>             <num>          <num>   <char>
    #> 1:       100000.5          98550.75          50.25     USDT

### Positions

``` r

# All open positions
positions <- account$get_positions()
positions[, .(symbol, current_qty, avg_entry_price, unrealised_pnl, margin_mode)]
```

    #>      symbol current_qty avg_entry_price unrealised_pnl margin_mode
    #>      <char>       <int>          <char>         <char>      <char>
    #> 1: XBTUSDTM           1         98250.0            0.1    ISOLATED

### Position History

``` r

history <- account$get_positions_history()
history
```

    #>      symbol settle_currency realised_gross_pnl realised_pnl           open_time
    #>      <char>          <char>             <char>       <char>              <POSc>
    #> 1: XBTUSDTM            USDT              10.50        10.25 2024-10-16 17:33:20
    #>             close_time leverage   type
    #>                 <POSc>    <int> <char>
    #> 1: 2024-10-17 10:04:19        5  Close

### Margin Mode

Switch between isolated and cross margin:

``` r

# Check current mode
account$get_margin_mode(symbol = "XBTUSDTM")
```

    #>      symbol margin_mode
    #>      <char>      <char>
    #> 1: XBTUSDTM    ISOLATED

``` r

# Switch to cross margin
account$set_margin_mode(symbol = "XBTUSDTM", margin_mode = "CROSS")
```

### Leverage

``` r

account$get_cross_margin_leverage(symbol = "XBTUSDTM")
```

    #>      symbol leverage
    #>      <char>   <char>
    #> 1: XBTUSDTM        5

``` r

account$set_cross_margin_leverage(symbol = "XBTUSDTM", leverage = 10)
```

### Risk Limits

Each contract has tiered risk limits that reduce maximum leverage as
position size increases:

``` r

limits <- account$get_risk_limit(symbol = "XBTUSDTM")
limits[, .(level, max_leverage, max_risk_limit, initial_margin)]
```

    #>    level max_leverage max_risk_limit initial_margin
    #>    <int>        <int>          <int>          <num>
    #> 1:     1          125         100000          0.008
    #> 2:     2          100         200000          0.010

### Funding Fee History

Track funding fees you’ve paid or received:

``` r

funding <- account$get_funding_history(symbol = "XBTUSDTM")
funding
```

    #>       id   symbol          time_point funding_rate mark_price position_qty
    #>    <int>   <char>              <POSc>        <num>      <int>        <int>
    #> 1:     1 XBTUSDTM 2024-10-17 08:00:00        1e-04      98250            1
    #>    position_cost   funding settle_currency
    #>           <char>    <char>          <char>
    #> 1:         98.25 -0.009825            USDT

------------------------------------------------------------------------

## Method Reference

### KucoinFuturesMarketData

| Method                  | Description                       |
|-------------------------|-----------------------------------|
| `get_contract()`        | Single contract specification     |
| `get_all_contracts()`   | All active contracts              |
| `get_ticker()`          | Real-time ticker for one contract |
| `get_all_tickers()`     | Tickers for all contracts         |
| `get_part_orderbook()`  | Top 20 or 100 orderbook levels    |
| `get_full_orderbook()`  | Full L2 orderbook (auth required) |
| `get_trade_history()`   | Recent trades                     |
| `get_klines()`          | OHLCV candlestick data            |
| `get_mark_price()`      | Current mark price                |
| `get_funding_rate()`    | Current funding rate              |
| `get_funding_history()` | Historical funding rates          |
| `get_server_time()`     | Server timestamp                  |
| `get_service_status()`  | Exchange operational status       |

### KucoinFuturesTrading

| Method                         | Description                    |
|--------------------------------|--------------------------------|
| `add_order()`                  | Place a futures order          |
| `add_order_test()`             | Dry-run order validation       |
| `add_order_batch()`            | Place multiple orders          |
| `cancel_order_by_id()`         | Cancel by system ID            |
| `cancel_order_by_client_oid()` | Cancel by client ID            |
| `cancel_all()`                 | Cancel all open orders         |
| `cancel_all_stop_orders()`     | Cancel all stop orders         |
| `get_order_by_id()`            | Query order by system ID       |
| `get_order_by_client_oid()`    | Query order by client ID       |
| `get_order_list()`             | Paginated order list           |
| `get_recent_closed_orders()`   | Recent closed orders           |
| `get_stop_orders()`            | Untriggered stop orders        |
| `get_fills()`                  | Paginated fill history         |
| `get_recent_fills()`           | Recent fills (24h)             |
| `get_open_order_value()`       | Open order statistics          |
| `set_dcp()`                    | Set dead connection protection |
| `get_dcp()`                    | Query DCP settings             |

### KucoinFuturesAccount

| Method                        | Description                     |
|-------------------------------|---------------------------------|
| `get_account_overview()`      | Balance, equity, margin summary |
| `get_position()`              | Position for one symbol         |
| `get_positions()`             | All open positions              |
| `get_positions_history()`     | Historical closed positions     |
| `get_margin_mode()`           | Query margin mode               |
| `set_margin_mode()`           | Switch isolated/cross           |
| `get_cross_margin_leverage()` | Query cross leverage            |
| `set_cross_margin_leverage()` | Set cross leverage              |
| `get_max_open_size()`         | Max contracts openable          |
| `get_max_withdraw_margin()`   | Max withdrawable margin         |
| `add_isolated_margin()`       | Deposit margin to position      |
| `remove_isolated_margin()`    | Withdraw margin from position   |
| `get_risk_limit()`            | Risk limit tiers                |
| `get_funding_history()`       | Personal funding fee records    |
