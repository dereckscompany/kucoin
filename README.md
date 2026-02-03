
# kucoin <img src="man/figures/logo-small.png" alt="kucoin R package logo" align="right" height="139" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/dereckmezquita/kucoin/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dereckmezquita/kucoin/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R API wrapper for the [KuCoin](https://www.kucoin.com/)
cryptocurrency exchange. Provides R6 classes for spot market data,
trading, stop orders, OCO orders, account management, deposits,
transfers, withdrawals, and sub-accounts. Supports both synchronous and
asynchronous (promise-based) operation via httr2.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckmezquita/kucoin")
```

## Setup

Set your API credentials as environment variables in `.Renviron`:

``` bash
KC-API-ENDPOINT = "https://api.kucoin.com"
KC-API-KEY = your-api-key
KC-API-SECRET = your-api-secret
KC-API-PASSPHRASE = your-api-passphrase
```

If you don’t have a key, visit the [KuCoin API
documentation](https://www.kucoin.com/docs-new).

## Quick Start

### Market Data (No Auth Required)

``` r
box::use(kucoin[KucoinMarketData])

market <- KucoinMarketData$new()
```

``` r
# Get BTC-USDT ticker
ticker <- market$get_ticker("BTC-USDT")
print(ticker)
#>               datetime      sequence   price       size best_bid best_bid_size
#>                 <POSc>        <char>  <char>     <char>   <char>        <char>
#> 1: 2024-10-17 10:04:19 1550467636704 67232.9 0.00007682  67232.8    0.41861839
#>    best_ask best_ask_size
#>      <char>        <char>
#> 1:  67232.9    1.24808993
```

``` r
# Get 24hr stats
stats <- market$get_24hr_stats("BTC-USDT")
print(stats)
#>               datetime   symbol     buy    sell change_rate change_price
#>                 <POSc>   <char>  <char>  <char>      <char>       <char>
#> 1: 2024-10-17 10:04:19 BTC-USDT 67232.8 67232.9     -0.0114       -772.1
#>       high     low           vol    vol_value    last average_price
#>     <char>  <char>        <char>       <char>  <char>        <char>
#> 1: 68100.0 66800.0 3456.78901234 232456789.12 67232.9       67450.5
#>    taker_fee_rate maker_fee_rate taker_coefficient maker_coefficient
#>            <char>         <char>            <char>            <char>
#> 1:          0.001          0.001                 1                 1
```

``` r
# Get klines (candlestick data)
klines <- market$get_klines("BTC-USDT", "1hour",
  from = ymd_hms("2025-01-01 00:00:00"),
  to = ymd_hms("2025-01-02 00:00:00")
)
print(klines)
#>               datetime     open     high      low    close   volume turnover
#>                 <POSc>    <num>    <num>    <num>    <num>    <num>    <num>
#> 1: 2025-07-26 12:00:00 117775.9 118221.2 117766.4 118128.9 264.6461 31241540
#> 2: 2025-07-26 16:00:00 118129.0 118291.8 117940.3 118227.4 197.8112 23355797
#> 3: 2025-07-26 20:00:00 118227.3 118299.3 117880.4 117915.0 252.9352 29854685
```

### Trading (Auth Required)

``` r
box::use(kucoin[KucoinTrading])

trading <- KucoinTrading$new()
```

``` r
# Place a test order (validates without executing)
order <- trading$add_order_test(
  type = "limit",
  symbol = "BTC-USDT",
  side = "buy",
  price = "50000",
  size = "0.0001"
)
print(order)
#>                    order_id               client_oid
#>                      <char>                   <char>
#> 1: 670fd33bf9406e0007ab3945 5c52e11203aa677f33e493fb
```

``` r
# Query open orders
open <- trading$get_open_orders("BTC-USDT")
print(open)
#>                          id   symbol op_type   type   side  price   size  funds
#>                      <char>   <char>  <char> <char> <char> <char> <char> <char>
#> 1: 670fd33bf9406e0007ab3945 BTC-USDT    DEAL  limit    buy  50000 0.0001      0
#>    deal_size deal_funds    fee fee_currency    stp time_in_force cancel_after
#>       <char>     <char> <char>       <char> <char>        <char>        <int>
#> 1:         0          0      0         USDT                  GTC           -1
#>    post_only hidden iceberg visible_size cancelled_size cancelled_funds
#>       <lgcl> <lgcl>  <lgcl>       <char>         <char>          <char>
#> 1:     FALSE  FALSE   FALSE            0              0               0
#>    remain_size remain_funds active in_order_book               client_oid
#>         <char>       <char> <lgcl>        <lgcl>                   <char>
#> 1:      0.0001            0   TRUE          TRUE 5c52e11203aa677f33e493fb
#>      tags last_updated_at    datetime_created
#>    <char>           <num>              <POSc>
#> 1:           1.729578e+12 2024-10-22 06:11:55
```

### Async Mode

All classes support asynchronous operation with promises:

``` r
box::use(
  kucoin[KucoinMarketData],
  coro[async, await],
  later[run_now, loop_empty]
)

market_async <- KucoinMarketData$new(async = TRUE)
```

``` r
result <- NULL

main <- async(function() {
  ticker <- await(market_async$get_ticker("BTC-USDT"))
  result <<- ticker
})

main()
while (!loop_empty()) run_now()
result
```

## Available Classes

| Class | Purpose |
|----|----|
| `KucoinMarketData` | Tickers, klines, orderbooks, currencies, symbols, trade history, server time, service status, fiat prices |
| `KucoinTrading` | Place, cancel, modify, and query HF spot orders; sync variants; DCP dead-man’s switch |
| `KucoinStopOrders` | Stop order management with trigger prices |
| `KucoinOcoOrders` | One-Cancels-Other order pairs |
| `KucoinAccount` | Account balances, ledger, HF ledger, fee rates, API key info |
| `KucoinDeposit` | Deposit addresses and history |
| `KucoinTransfer` | Internal transfers between account types (main, trade, margin) |
| `KucoinWithdrawal` | Withdrawal creation, cancellation, quotas, and history |
| `KucoinSubAccount` | Sub-account creation and balance queries |

## Fund Transfers and Withdrawals

Essential for trading bots: deposits land in the **main** account, but
HF spot orders require funds in the **trade** account.

``` r
box::use(kucoin[KucoinTransfer, KucoinWithdrawal])

transfer <- KucoinTransfer$new()

# Check transferable balance
balance <- transfer$get_transferable(currency = "USDT", type = "MAIN")
print(balance[, .(currency, balance, transferable)])

# Move funds from main to trade account
result <- transfer$add_transfer(
  clientOid = "my-unique-id",
  currency = "USDT",
  amount = "100",
  type = "INTERNAL",
  fromAccountType = "MAIN",
  toAccountType = "TRADE"
)
print(result$order_id)

# Check withdrawal quotas
withdrawal <- KucoinWithdrawal$new()
quotas <- withdrawal$get_withdrawal_quotas(currency = "USDT", chain = "trx")
print(quotas[, .(currency, available_amount, withdraw_min_fee)])
```

## Bulk Kline Download

``` r
box::use(kucoin[kucoin_backfill_klines])
box::use(lubridate[ymd_hms])

# Download historical klines for multiple symbols
kucoin_backfill_klines(
  symbols = c("BTC-USDT", "ETH-USDT"),
  freqs = c("1hour", "1day"),
  from = ymd_hms("2024-01-01 00:00:00"),
  to = ymd_hms("2025-01-01 00:00:00"),
  output_dir = "data/klines"
)
```

## Citation

If you use this package in your work, please cite it:

``` r
citation("kucoin")
```

> Mezquita, D. (2026). kucoin: R API Wrapper to KuCoin Cryptocurrency
> Exchange. R package version 3.0.0.

## Licence

MIT © [Dereck Mezquita](https://github.com/dereckmezquita)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--9307--6762-green)](https://orcid.org/0000-0002-9307-6762).
See [LICENSE.md](LICENSE.md) for the full text, including the citation
clause.
