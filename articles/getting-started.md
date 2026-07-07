# Getting Started with kucoin

This vignette demonstrates how to use `kucoin` in **synchronous** mode.

## Setup

``` r

box::use(
  kucoin[
    KucoinMarketData, KucoinTrading, KucoinAccount,
    KucoinStopOrders, KucoinOcoOrders, KucoinDeposit,
    KucoinSubAccount, get_api_keys
  ],
  lubridate[ymd_hms]
)

keys <- get_api_keys(
  api_key = "your-api-key",
  api_secret = "your-api-secret",
  api_passphrase = "your-api-passphrase"
)
```

------------------------------------------------------------------------

## Market Data

The `KucoinMarketData` class covers all public (no auth) market
endpoints.

``` r

market <- KucoinMarketData$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

### Ticker

``` r

ticker <- market$get_ticker(symbol = "BTC-USDT")
ticker
```

    #>                   time      sequence   price      size best_bid best_bid_size
    #>                 <POSc>        <char>   <num>     <num>    <num>         <num>
    #> 1: 2024-10-17 10:04:19 1550467636704 67232.9 7.682e-05  67232.8     0.4186184
    #>    best_ask best_ask_size
    #>       <num>         <num>
    #> 1:  67232.9       1.24809

### 24hr Statistics

``` r

stats <- market$get_24hr_stats(symbol = "BTC-USDT")
stats
```

    #>                   time   symbol     buy    sell change_rate change_price  high
    #>                 <POSc>   <char>   <num>   <num>       <num>        <num> <num>
    #> 1: 2024-10-17 10:04:19 BTC-USDT 67232.8 67232.9     -0.0114       -772.1 68100
    #>      low      vol vol_value    last average_price taker_fee_rate maker_fee_rate
    #>    <num>    <num>     <num>   <num>         <num>          <num>          <num>
    #> 1: 66800 3456.789 232456789 67232.9       67450.5          0.001          0.001
    #>    taker_coefficient maker_coefficient
    #>                <num>             <num>
    #> 1:                 1                 1

### All Tickers

``` r

tickers <- market$get_all_tickers()
tickers
```

    #>      symbol symbol_name     buy    sell change_rate change_price  high   low
    #>      <char>      <char>   <num>   <num>       <num>        <num> <num> <num>
    #> 1: BTC-USDT    BTC-USDT 67232.8 67232.9     -0.0114       -772.1 68100 66800
    #> 2: ETH-USDT    ETH-USDT  2530.5  2530.8      0.0235         58.2  2560  2470
    #>          vol vol_value    last average_price taker_fee_rate maker_fee_rate
    #>        <num>     <num>   <num>         <num>          <num>          <num>
    #> 1:  3456.789 232456789 67232.9       67450.5          0.001          0.001
    #> 2: 45678.123 115432000  2530.6        2515.3          0.001          0.001
    #>                   time
    #>                 <POSc>
    #> 1: 2024-10-17 10:04:19
    #> 2: 2024-10-17 10:04:19

### Trade History

``` r

trades <- market$get_trade_history(symbol = "BTC-USDT")
trades
```

    #>         sequence   side   price      size                time      trade_id
    #>           <char> <char>   <num>     <num>              <POSc>        <char>
    #> 1: 1550467636704    buy 67232.9 7.682e-05 2024-10-17 10:04:19 1550467636704
    #> 2: 1550467636705   sell 67231.5 1.234e-02 2024-10-17 10:04:20 1550467636705
    #> 3: 1550467636706    buy 67233.0 5.000e-03 2024-10-17 10:04:21 1550467636706

### Partial Orderbook

``` r

book <- market$get_part_orderbook(symbol = "BTC-USDT", size = 20)
book
```

    #>                   time      sequence   side level   price      size
    #>                 <POSc>        <char> <char> <int>   <num>     <num>
    #> 1: 2024-10-17 10:04:19 1550467636704    bid     1 67232.8 0.4186184
    #> 2: 2024-10-17 10:04:19 1550467636704    bid     2 67232.5 1.5000000
    #> 3: 2024-10-17 10:04:19 1550467636704    bid     3 67230.0 0.8000000
    #> 4: 2024-10-17 10:04:19 1550467636704    ask     1 67232.9 1.2480899
    #> 5: 2024-10-17 10:04:19 1550467636704    ask     2 67233.5 0.5000000
    #> 6: 2024-10-17 10:04:19 1550467636704    ask     3 67235.0 2.1000000

### Klines (Candlestick Data)

``` r

klines <- market$get_klines(
  symbol = "BTC-USDT",
  timeframe = "15min",
  from = ymd_hms("2024-10-16 20:00:00"),
  to = ymd_hms("2024-10-16 21:00:00")
)
klines
```

    #>               datetime     open     high      low    close   volume turnover
    #>                 <POSc>    <num>    <num>    <num>    <num>    <num>    <num>
    #> 1: 2025-07-26 12:00:00 117775.9 118221.2 117766.4 118128.9 264.6461 31241540
    #> 2: 2025-07-26 16:00:00 118129.0 118291.8 117940.3 118227.4 197.8112 23355797
    #> 3: 2025-07-26 20:00:00 118227.3 118299.3 117880.4 117915.0 252.9352 29854685

### Currency Info

``` r

btc <- market$get_currency(currency = "BTC")
btc
```

    #>    currency   name full_name precision is_margin_enabled is_debit_enabled
    #>      <char> <char>    <char>     <int>            <lgcl>           <lgcl>
    #> 1:      BTC    BTC   Bitcoin         8              TRUE             TRUE
    #> 2:      BTC    BTC   Bitcoin         8              TRUE             TRUE
    #>    chain_name withdrawal_min_size deposit_min_size withdraw_fee_rate
    #>        <char>               <num>            <num>             <num>
    #> 1:        BTC               1e-03            2e-04                 0
    #> 2:        KCC               8e-04            2e-05                 0
    #>    withdrawal_min_fee is_withdraw_enabled is_deposit_enabled confirms
    #>                 <num>              <lgcl>             <lgcl>    <int>
    #> 1:              5e-04                TRUE               TRUE        3
    #> 2:              2e-05                TRUE               TRUE       20
    #>    pre_confirms   contract_address withdraw_precision max_withdraw max_deposit
    #>           <int>             <char>              <int>       <lgcl>       <num>
    #> 1:            1                                     8           NA          NA
    #> 2:           20 0xfa93c12cd345c658                  8           NA          NA
    #>    need_tag chain_id
    #>      <lgcl>   <char>
    #> 1:    FALSE      btc
    #> 2:    FALSE      kcc

### Symbol Info

``` r

sym <- market$get_symbol(symbol = "BTC-USDT")
sym
```

    #>      symbol     name base_currency quote_currency fee_currency market
    #>      <char>   <char>        <char>         <char>       <char> <char>
    #> 1: BTC-USDT BTC-USDT           BTC           USDT         USDT   USDS
    #>    base_min_size quote_min_size base_max_size quote_max_size base_increment
    #>            <num>          <num>         <num>          <num>          <num>
    #> 1:         1e-05            0.1         1e+10          1e+08          1e-08
    #>    quote_increment price_increment price_limit_rate min_funds is_margin_enabled
    #>              <num>           <num>            <num>     <num>            <lgcl>
    #> 1:           1e-06             0.1              0.1       0.1              TRUE
    #>    enable_trading fee_category maker_fee_coefficient taker_fee_coefficient
    #>            <lgcl>        <int>                 <num>                 <num>
    #> 1:           TRUE            1                     1                     1
    #>        st callauction_is_enabled callauction_price_floor
    #>    <lgcl>                 <lgcl>                   <num>
    #> 1:  FALSE                  FALSE                      NA
    #>    callauction_price_ceiling callauction_first_stage_start_time
    #>                        <num>                              <num>
    #> 1:                        NA                                 NA
    #>    callauction_second_stage_start_time callauction_third_stage_start_time
    #>                                  <num>                              <num>
    #> 1:                                  NA                                 NA
    #>    trading_start_time
    #>                 <num>
    #> 1:                 NA

------------------------------------------------------------------------

## Trading

The `KucoinTrading` class manages HF spot orders. All trading endpoints
require authentication.

### Place a Test Order

Test orders validate parameters without executing:

``` r

trading <- KucoinTrading$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

result <- trading$add_order_test(
  type = "limit",
  symbol = "BTC-USDT",
  side = "buy",
  price = "50000",
  size = "0.0001"
)
result
```

    #>             order_id         client_oid
    #>               <char>             <char>
    #> 1: futures-order-001 futures-client-001

### Cancel an Order

``` r

cancelled <- trading$cancel_order_by_id(order_id = "670fd33bf9406e0007ab3945", symbol = "BTC-USDT")
cancelled
```

    #>                    order_id
    #>                      <char>
    #> 1: 670fd33bf9406e0007ab3945

### Query Open Orders

``` r

open_orders <- trading$get_open_orders(symbol = "BTC-USDT")
open_orders
```

    #>                          id   symbol op_type   type   side price  size  funds
    #>                      <char>   <char>  <char> <char> <char> <num> <num> <char>
    #> 1: 670fd33bf9406e0007ab3945 BTC-USDT    DEAL  limit    buy 50000 1e-04      0
    #>    deal_size deal_funds   fee fee_currency    stp time_in_force cancel_after
    #>        <num>     <char> <num>       <char> <char>        <char>        <int>
    #> 1:         0          0     0         USDT                  GTC           -1
    #>    post_only hidden iceberg visible_size cancelled_size cancelled_funds
    #>       <lgcl> <lgcl>  <lgcl>       <char>         <char>          <char>
    #> 1:     FALSE  FALSE   FALSE            0              0               0
    #>    remain_size remain_funds active in_order_book               client_oid
    #>          <num>       <char> <lgcl>        <lgcl>                   <char>
    #> 1:       1e-04            0   TRUE          TRUE 5c52e11203aa677f33e493fb
    #>      tags          created_at     last_updated_at
    #>    <char>              <POSc>              <POSc>
    #> 1:        2024-10-22 06:11:55 2024-10-22 06:11:55

------------------------------------------------------------------------

## Stop Orders

``` r

stop <- KucoinStopOrders$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

result <- stop$add_order(
  type = "limit",
  symbol = "BTC-USDT",
  side = "sell",
  price = "60000",
  size = "0.0001",
  stop_price = "59000"
)
result
```

    #>                    order_id     client_oid
    #>                      <char>         <char>
    #> 1: vs8hoo8q2ceshiue003b67c0 stop-limit-001

------------------------------------------------------------------------

## OCO Orders

An OCO (One-Cancels-Other) order pairs a limit order with a stop-limit
order; when one side fills, the other is cancelled automatically.

``` r

oco <- KucoinOcoOrders$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

result <- oco$add_order(
  symbol = "BTC-USDT",
  side = "sell",
  price = "110000",
  size = "0.0001",
  stop_price = "90000",
  limit_price = "89500"
)
result
```

    #>                    order_id client_oid
    #>                      <char>     <char>
    #> 1: 674c40d38b4b2f00073deef3       <NA>

------------------------------------------------------------------------

## Account Management

### Account Summary

``` r

account <- KucoinAccount$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

summary <- account$get_summary()
summary
```

    #>    level sub_quantity max_default_sub_quantity max_sub_quantity
    #>    <int>        <int>                    <int>            <int>
    #> 1:     1            3                        5                5
    #>    spot_sub_quantity margin_sub_quantity futures_sub_quantity
    #>                <int>               <int>                <int>
    #> 1:                 2                   1                    0
    #>    option_sub_quantity max_spot_sub_quantity max_margin_sub_quantity
    #>                  <int>                 <int>                   <int>
    #> 1:                   0                     5                       5
    #>    max_futures_sub_quantity max_option_sub_quantity
    #>                       <int>                   <int>
    #> 1:                        5                       5

### Spot Account Balances

``` r

balances <- account$get_spot_accounts()
balances
```

    #>                          id currency   type      balance available       holds
    #>                      <char>   <char> <char>        <num>     <num>       <num>
    #> 1: 6717422bd51c29000775ea01     USDT  trade 10000.500000   9500.25 500.2500000
    #> 2: 6717422bd51c29000775ea02      BTC  trade     1.234568      1.00   0.2345679

------------------------------------------------------------------------

## Deposits

### Get Deposit Addresses

``` r

deposit <- KucoinDeposit$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

addrs <- deposit$get_deposit_addresses(currency = "USDT")
addrs
```

    #>                                       address   memo  chain chain_id     to
    #>                                        <char> <char> <char>   <char> <char>
    #> 1: 0x1a2b3c4d5e6f7890abcdef1234567890abcdef12         ERC20      eth   main
    #> 2:    TXyz123abcDEF456ghiJKL789mnoPQR012stuVW         TRC20      trx   main
    #>    currency                           contract_address remark chain_name
    #>      <char>                                     <char> <char>     <char>
    #> 1:     USDT 0xdac17f958d2ee523a2206206994597c13d831ec7             ERC20
    #> 2:     USDT         TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t             TRC20
    #>    expiration_date
    #>              <int>
    #> 1:               0
    #> 2:               0

### Sync Orders and Modify

Sync variants return fill results in a single round trip:

``` r

# Place order and get immediate fill result
order <- trading$add_order_sync(
  type = "limit", symbol = "BTC-USDT", side = "buy",
  price = "50000", size = "0.0001"
)
cat("Status:", order$status, "Filled:", order$deal_size, "\n")

# Modify an existing order's price
modified <- trading$modify_order(
  symbol = "BTC-USDT",
  order_id = order$order_id,
  new_price = "51000"
)
cat("New order ID:", modified$new_order_id, "\n")
```

### Dead Connection Protection (DCP)

A dead-man’s switch that auto-cancels orders if your bot stops
heartbeating:

``` r

# Enable: cancel all BTC-USDT orders if no request in 30 seconds
trading$set_dcp(timeout = 30, symbols = "BTC-USDT")

# Check current DCP settings
dcp <- trading$get_dcp()
cat("Timeout:", dcp$timeout, "s\n")

# Disable
trading$set_dcp(timeout = -1)
```

------------------------------------------------------------------------

## Fee Rates

``` r

# Base fee rate (account tier default)
base_fees <- account$get_base_fee_rate()
cat("Base taker:", base_fees$taker_fee_rate, "\n")

# Per-symbol actual rates (after VIP/KCS discounts)
actual_fees <- account$get_fee_rate(symbols = "BTC-USDT,ETH-USDT")
actual_fees
```

## HF Trading Ledger

The HF ledger contains fills, fees, and settlements from HF orders
(7-day window):

``` r

hf_ledger <- account$get_hf_ledger(currency = "USDT", biz_type = "TRADE_EXCHANGE")
hf_ledger
```

## Server Time and Service Status

``` r

# Check clock drift
st <- market$get_server_time()
drift_ms <- as.numeric(lubridate::now()) * 1000 - st$server_time
cat("Clock drift:", round(drift_ms), "ms\n")

# Pre-flight: is the exchange operational?
status <- market$get_service_status()
if (status$status != "open") stop("Exchange not operational: ", status$msg)
```

## Fiat Prices

``` r

prices <- market$get_fiat_prices(base = "USD", currencies = "BTC,ETH,USDT")
prices
```

------------------------------------------------------------------------

## Fund Transfers

Deposits land in the **main** account, but HF spot orders require funds
in the **trade** account. Use `KucoinTransfer` to move funds between
account types.

``` r

box::use(kucoin[KucoinTransfer])

transfer <- KucoinTransfer$new()

# Check how much USDT is available to transfer
balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
balance

# Transfer USDT from main to trade account
result <- transfer$add_transfer(
  client_order_id = "unique-id-here",
  currency = "USDT",
  amount = "100",
  type = "INTERNAL",
  from_account_type = "MAIN",
  to_account_type = "TRADE"
)
result
```

------------------------------------------------------------------------

## Withdrawals

Use `KucoinWithdrawal` to check withdrawal limits, initiate withdrawals,
and monitor withdrawal status.

``` r

box::use(kucoin[KucoinWithdrawal])

withdrawal <- KucoinWithdrawal$new()

# Check withdrawal quotas and fees
quotas <- withdrawal$get_withdrawal_quotas(currency = "USDT", chain = "trx")
quotas

# Withdraw USDT via TRC20
result <- withdrawal$add_withdrawal(
  currency = "USDT",
  to_address = "your-trc20-address",
  amount = "10",
  withdraw_type = "ADDRESS",
  chain = "trx"
)
result

# Check withdrawal history
history <- withdrawal$get_withdrawal_history(currency = "USDT")
history
```

------------------------------------------------------------------------

## Sub-Account Management

### List Sub-Accounts

``` r

sub <- KucoinSubAccount$new()
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

subs <- sub$get_sub_account_list()
subs
```

    #>                     user_id       uid  sub_name status  type  access
    #>                      <char>     <int>    <char>  <int> <int>  <char>
    #> 1: 641e7f09df0db80001f1e5ac 169630809 bot-alpha      2     0    Spot
    #> 2: 641e8027df0db80001f1e6bb 169630810  bot-beta      2     0 Futures
    #>    trade_types opened_trade_types     remarks          created_at
    #>         <list>             <list>      <char>              <POSc>
    #> 1:   <list[1]>          <list[1]> Trading bot 2024-10-17 10:04:19
    #> 2:   <list[2]>          <list[2]> Futures bot 2024-10-17 10:05:59

------------------------------------------------------------------------

## Clock Drift: Server Time Signing

By default, HMAC request signatures use your local machine’s clock. If
your system time is out of sync with KuCoin’s servers, authenticated
requests may fail. You can configure any class to fetch the server time
before each authenticated request:

``` r

# Use server time for signing (adds one round trip per request)
trading <- KucoinTrading$new(time_source = "server")

# All authenticated calls now use the exchange clock
order <- trading$add_order_test(
  type = "limit", symbol = "BTC-USDT", side = "buy",
  price = "50000", size = "0.0001"
)
```

The `time_source` parameter is available on all class constructors:
`KucoinTrading`, `KucoinAccount`, `KucoinStopOrders`, `KucoinOcoOrders`,
`KucoinDeposit`, `KucoinTransfer`, `KucoinWithdrawal`, and
`KucoinSubAccount`.

------------------------------------------------------------------------

## Next Steps

- See
  [`vignette("async-usage")`](https://dereckscompany.github.io/kucoin/articles/async-usage.md)
  for promise-based asynchronous operation.
- See
  [`vignette("margin-trading")`](https://dereckscompany.github.io/kucoin/articles/margin-trading.md)
  for margin trading, short selling, and lending.
- See
  [`vignette("futures-trading")`](https://dereckscompany.github.io/kucoin/articles/futures-trading.md)
  for perpetual futures contracts.
- Browse the [pkgdown site](https://dereckscompany.github.io/kucoin/)
  for full method documentation.
- For bulk historical data downloads, see
  [`?kucoin_backfill_klines`](https://dereckscompany.github.io/kucoin/reference/kucoin_backfill_klines.md).
