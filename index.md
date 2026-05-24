# kucoin ![kucoin R package logo](reference/figures/logo-small.png)

An R API wrapper for the [KuCoin](https://www.kucoin.com/)
cryptocurrency exchange. Provides `R6` classes for spot market data,
trading, stop orders, OCO orders, account management, deposits,
transfers, withdrawals, sub-accounts, margin trading, margin lending,
and futures trading. Supports both synchronous and asynchronous (promise
based) operation via `httr2`.

## Disclaimer

This software is provided “as is”, without warranty of any kind. **This
package interacts with live cryptocurrency exchange accounts and can
execute real trades, transfers, and withdrawals involving real money.**
By using this package you accept full responsibility for any financial
losses, erroneous transactions, or other damages that may result. Always
test with small amounts first, use API key permissions to restrict
access to only what you need, and never share your API credentials. The
author(s) and contributor(s) are not liable for any financial loss or
damage arising from the use of this software.

We invite you to read the source code and make contributions if you find
a bug or wish to make an improvement.

## Design Philosophy

All API responses are returned as `data.table` objects with three
transformations applied:

1.  **snake_case column names** — camelCase keys from the JSON response
    (e.g. `clientOid`, `orderType`, `createdAt`) become snake_case
    (`client_oid`, `order_type`, `created_at`). A handful of endpoints
    additionally reshape nested objects to wide `parent_child` columns
    (e.g. `baseAsset.currency` → `base_asset_currency`) or collapse
    array fields under a plural form. See each method’s `@return` for
    the exact column list.

2.  **Type coercion** for well-known columns — KuCoin’s millisecond
    timestamps (most endpoints) and nanosecond timestamps (futures
    orderbooks / klines) are both parsed to `POSIXct` in UTC. Numeric
    quantities, prices, and ratios stay as `character` strings because
    KuCoin emits them as strings and the precision matters; cast with
    [`as.numeric()`](https://rdrr.io/r/base/numeric.html) at the point
    of use if you need arithmetic.

3.  **One entity = one row, no list columns** — every method follows the
    rule *“identify the entity for the endpoint, return one row per
    entity”*. The same convention is shared with the sister `alpaca` and
    `binance` packages so switching between exchanges doesn’t mean
    switching mental models.

The five shape treatments the parsers apply, depending on the nested
structure:

| Nested shape | Treatment | Example |
|----|----|----|
| Array of plain strings (`annType`, `permissions`) | Collapsed into one `;`-separated character column. Recover with `strsplit(x, ";", fixed = TRUE)[[1]]`. | `dt$ann_type` → `"latest-announcements;new-listings"` |
| Array of objects (orderbook levels, OCO `orders`, sub-account `balances`) | Exploded to long format with parent fields replicated. A 1-indexed `level` / `sub_order_*` / similar position column is added when order matters. | `get_part_orderbook()` → one row per `(side, level)`. |
| Fixed-schema nested object (`baseAsset` / `quoteAsset` on isolated-margin pairs) | Flattened to wide `parent_child` columns. | `get_isolated_margin_account()` → `base_asset_currency`, `base_asset_borrow_enabled`, … |
| Sibling collection that doesn’t fit the row entity | Exposed via a sibling method on the same class so every method still returns one `data.table`. | `KucoinAccount$get_isolated_margin_account()` returns per-pair rows; ad-hoc summaries are sibling methods. |
| Dynamic-key or array-of-array objects | Serialised as a JSON string column; recover with `jsonlite::fromJSON(x)`. | Lending product `tierAnnualPercentageRate` blocks. |

**Two cross-cutting rules** apply to every shape treatment:

1.  **Empty / null array → `NA_character_`** (no list cells). An OCO
    order with no children returns `sub_order_id = NA`, not
    `sub_order_id = list()`.
2.  **Empty response → empty `data.table`** (no synthetic stub rows).
    `KucoinTrading$cancel_all()` with no open orders returns a zero-row
    table, not a fabricated `(symbol, status = "cancelled")`
    placeholder. The absence of an error is the success signal.

For the full per-treatment catalogue with worked examples, see
[`vignette("data-shapes", package = "kucoin")`](https://dereckscompany.github.io/kucoin/articles/data-shapes.md).

## Installation

``` r

# install.packages("remotes")
remotes::install_github("dereckscompany/kucoin")
```

## Setup

``` r

# special mock for local build
box::use(
  kucoin[
    get_api_keys,
    get_futures_base_url
  ],
  ./tests/testthat/mock_router[mock_router]
)

KEYS <- get_api_keys(
  api_key = "fake-key",
  api_secret = "fake-secret",
  api_passphrase = "fake-passphrase"
)

BASE <- "https://api.kucoin.com"
FBASE <- "https://api-futures.kucoin.com"

options(httr2_mock = mock_router)

# normal imports
box::use(
  kucoin[
    KucoinMarketData,
    KucoinTrading,
    KucoinAccount,
    KucoinMarginTrading,
    KucoinMarginData,
    KucoinLending,
    KucoinFuturesMarketData,
    KucoinFuturesTrading,
    KucoinFuturesAccount
  ],
  lubridate[ymd_hms]
)
```

Set your API credentials as environment variables in `.Renviron`:

``` bash
KUCOIN_API_ENDPOINT = "https://api.kucoin.com"
KUCOIN_API_KEY = your-api-key
KUCOIN_API_SECRET = your-api-secret
KUCOIN_API_PASSPHRASE = your-api-passphrase
```

If you don’t have a key, visit the [KuCoin API
documentation](https://www.kucoin.com/docs-new).

## Quick Start – Market Data

Market data endpoints are public and require no authentication.

``` r

market <- KucoinMarketData$new(keys = KEYS, base_url = BASE)
```

### Price Ticker

``` r

market$get_ticker(symbol = "BTC-USDT")
```

``` R
#>                   time      sequence   price       size best_bid best_bid_size
#>                 <POSc>        <char>  <char>     <char>   <char>        <char>
#> 1: 2024-10-17 10:04:19 1550467636704 67232.9 0.00007682  67232.8    0.41861839
#>    best_ask best_ask_size
#>      <char>        <char>
#> 1:  67232.9    1.24808993
```

### 24hr Statistics

``` r

market$get_24hr_stats(symbol = "BTC-USDT")
```

``` R
#>                   time   symbol     buy    sell change_rate change_price
#>                 <POSc>   <char>  <char>  <char>      <char>       <char>
#> 1: 2024-10-17 10:04:19 BTC-USDT 67232.8 67232.9     -0.0114       -772.1
#>       high     low           vol    vol_value    last average_price
#>     <char>  <char>        <char>       <char>  <char>        <char>
#> 1: 68100.0 66800.0 3456.78901234 232456789.12 67232.9       67450.5
#>    taker_fee_rate maker_fee_rate taker_coefficient maker_coefficient
#>            <char>         <char>            <char>            <char>
#> 1:          0.001          0.001                 1                 1
```

### Klines (Candlestick Data)

``` r

market$get_klines(
  symbol = "BTC-USDT",
  timeframe = "1hour",
  from = ymd_hms("2025-01-01 00:00:00"),
  to = ymd_hms("2025-01-02 00:00:00")
)
```

``` R
#>               datetime     open     high      low    close   volume turnover
#>                 <POSc>    <num>    <num>    <num>    <num>    <num>    <num>
#> 1: 2025-07-26 12:00:00 117775.9 118221.2 117766.4 118128.9 264.6461 31241540
#> 2: 2025-07-26 16:00:00 118129.0 118291.8 117940.3 118227.4 197.8112 23355797
#> 3: 2025-07-26 20:00:00 118227.3 118299.3 117880.4 117915.0 252.9352 29854685
```

## Trading

Trading endpoints require authentication. Use `add_order_test()` to
validate order parameters without placing a real order.

``` r

trading <- KucoinTrading$new(keys = KEYS, base_url = BASE)
```

### Test Order (No Execution)

``` r

trading$add_order_test(
  type = "limit",
  symbol = "BTC-USDT",
  side = "buy",
  price = "50000",
  size = "0.0001"
)
```

``` R
#>             order_id         client_oid
#>               <char>             <char>
#> 1: futures-order-001 futures-client-001
```

### Get Open Orders

``` r

trading$get_open_orders(symbol = "BTC-USDT")
```

``` R
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
#>      tags          created_at     last_updated_at
#>    <char>              <POSc>              <POSc>
#> 1:        2024-10-22 06:11:55 2024-10-22 06:11:55
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
| `KucoinMarginTrading` | Margin trading: open/close short and long positions, borrow, repay, leverage |
| `KucoinMarginData` | Margin pair info, config, collateral ratios, risk limits |
| `KucoinLending` | Lend assets to earn interest, manage lending orders |
| `KucoinFuturesMarketData` | Futures contract specs, tickers, orderbooks, klines, funding rates |
| `KucoinFuturesTrading` | Place, cancel, and query futures orders; batch orders; DCP |
| `KucoinFuturesAccount` | Futures account overview, positions, margin, leverage, risk limits |

## Fund Transfers and Withdrawals

Essential for trading bots: deposits land in the **main** account, but
HF spot orders require funds in the **trade** account.

``` r

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

# Download historical klines for multiple symbols
kucoin_backfill_klines(
  symbols = c("BTC-USDT", "ETH-USDT"),
  freqs = c("1hour", "1day"),
  from = ymd_hms("2024-01-01 00:00:00"),
  to = ymd_hms("2025-01-01 00:00:00"),
  output_dir = "data/klines"
)
```

## Margin Trading

Margin trading enables short selling and leveraged longs. The package
provides intent-based methods that handle borrowing and repayment
automatically.

``` r

margin <- KucoinMarginTrading$new(keys = KEYS, base_url = BASE)
margin_data <- KucoinMarginData$new(keys = KEYS, base_url = BASE)
lending <- KucoinLending$new(keys = KEYS, base_url = BASE)
```

### Open / Close a Short

``` r

margin$open_short(symbol = "BTC-USDT", size = 0.001)
```

``` R
#>                    order_id       client_oid borrow_size  loan_apply_id
#>                      <char>           <char>      <char>         <char>
#> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001
```

``` r

margin$close_short(symbol = "BTC-USDT", size = 0.001)
```

``` R
#>                    order_id       client_oid borrow_size  loan_apply_id
#>                      <char>           <char>      <char>         <char>
#> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001
```

### Borrow Rates

``` r

margin$get_borrow_rate(query = list(currency = "BTC,USDT,ETH"))
```

``` R
#>    currency hourly_borrow_rate annualized_borrow_rate
#>      <char>             <char>                 <char>
#> 1:      BTC           0.000021                 0.1839
#> 2:     USDT           0.000015                 0.1314
#> 3:      ETH           0.000018                 0.1577
```

### Cross Margin Pairs

``` r

margin_data$get_cross_margin_symbols()
```

``` R
#>      symbol     name base_currency quote_currency base_increment base_min_size
#>      <char>   <char>        <char>         <char>         <char>        <char>
#> 1: BTC-USDT BTC-USDT           BTC           USDT     0.00000001       0.00001
#> 2: ETH-USDT ETH-USDT           ETH           USDT      0.0000001        0.0001
#>    base_max_size quote_increment quote_min_size quote_max_size price_increment
#>           <char>          <char>         <char>         <char>          <char>
#> 1:   10000000000        0.000001            0.1       99999999             0.1
#> 2:   10000000000        0.000001            0.1       99999999            0.01
#>    fee_currency price_limit_rate min_funds enable_trading market
#>          <char>           <char>    <char>         <lgcl> <char>
#> 1:         USDT             0.01       0.1           TRUE   USDS
#> 2:         USDT             0.01       0.1           TRUE   USDS
```

### Loan Market

``` r

lending$get_loan_market()
```

``` R
#>    currency purchase_enable redeem_enable increment min_purchase_size
#>      <char>          <lgcl>        <lgcl>    <char>            <char>
#> 1:     USDT            TRUE          TRUE      0.01                10
#> 2:      BTC            TRUE          TRUE   0.00001             0.001
#>    max_purchase_size interest_increment min_interest_rate market_interest_rate
#>               <char>             <char>            <char>               <char>
#> 1:           1000000             0.0001             0.004                 0.05
#> 2:               100             0.0001             0.003                 0.04
#>    max_interest_rate auto_purchase_enable
#>               <char>               <lgcl>
#> 1:               0.1                 TRUE
#> 2:              0.08                 TRUE
```

For full margin documentation see
[`vignette("margin-trading")`](https://dereckscompany.github.io/kucoin/articles/margin-trading.md).

## Futures Trading

Trade perpetual futures contracts (e.g. XBTUSDTM, ETHUSDTM) with
leverage up to 125x. Futures classes use a separate base URL
(`https://api-futures.kucoin.com`).

### Futures Market Data

``` r

futures_market <- KucoinFuturesMarketData$new(keys = KEYS, base_url = FBASE)
```

#### Contract Details

``` r

futures_market$get_contract(symbol = "XBTUSDTM")
```

``` R
#>      symbol root_symbol   type first_open_date base_currency quote_currency
#>      <char>      <char> <char>           <num>        <char>         <char>
#> 1: XBTUSDTM        USDT FFWCSX    1.585555e+12           XBT           USDT
#>    settle_currency max_order_qty max_price lot_size tick_size
#>             <char>         <int>     <int>    <int>     <num>
#> 1:            USDT       1000000   1000000        1       0.1
#>    index_price_tick_size multiplier initial_margin maintain_margin
#>                    <num>      <num>          <num>           <num>
#> 1:                  0.01      0.001          0.008           0.004
#>    max_risk_limit min_risk_limit risk_step maker_fee_rate taker_fee_rate
#>             <int>          <int>     <int>          <num>          <num>
#> 1:         100000         100000     50000          2e-04          6e-04
#>    maker_fix_fee taker_fix_fee is_deleverage is_quanto is_inverse mark_method
#>            <int>         <int>        <lgcl>    <lgcl>     <lgcl>      <char>
#> 1:             0             0          TRUE     FALSE      FALSE   FairPrice
#>    fair_method status funding_fee_rate predicted_funding_fee_rate open_interest
#>         <char> <char>            <num>                      <num>        <char>
#> 1: FundingRate   Open            1e-04                      1e-04         27228
#>    turnover_of24h volume_of24h mark_price index_price last_trade_price
#>             <num>        <int>      <num>       <num>            <int>
#> 1:       23472918          239    98252.1    98232.45            98260
#>    next_funding_rate_time max_leverage funding_rate_symbol low_price high_price
#>                     <int>        <int>              <char>     <int>      <int>
#> 1:               21467281          125      .XBTUSDTMFPI8H     96891      99133
```

#### Futures Ticker

``` r

futures_market$get_ticker(symbol = "XBTUSDTM")
```

``` R
#>      sequence   symbol   side  size   price best_bid_size best_bid_price
#>         <int>   <char> <char> <int>  <char>         <int>         <char>
#> 1: 1729159460 XBTUSDTM   sell     1 98250.0            50        98249.9
#>    best_ask_price best_ask_size         trade_id                  ts
#>            <char>         <int>           <char>              <POSc>
#> 1:        98250.1            30 67fd1234abcd5678 2024-10-17 10:04:19
```

### Futures Trading

``` r

futures_trading <- KucoinFuturesTrading$new(keys = KEYS, base_url = FBASE)
futures_account <- KucoinFuturesAccount$new(keys = KEYS, base_url = FBASE)
```

#### Futures Test Order

``` r

futures_trading$add_order_test(
  clientOid = "readme-test-001",
  symbol = "XBTUSDTM",
  side = "buy",
  type = "limit",
  leverage = 5,
  size = 1,
  price = "98000"
)
```

``` R
#>             order_id         client_oid
#>               <char>             <char>
#> 1: futures-order-001 futures-client-001
```

#### Positions

``` r

futures_account$get_positions()
```

``` R
#>         id   symbol auto_deposit real_leverage cross_mode delev_percentage
#>     <char>   <char>       <lgcl>         <int>     <lgcl>            <num>
#> 1: pos-001 XBTUSDTM        FALSE             5      FALSE              0.5
#>      opening_timestamp   current_timestamp current_qty current_cost
#>                 <POSc>              <POSc>       <int>       <char>
#> 1: 2024-10-17 10:04:19 2024-10-17 10:46:40           1        98.25
#>    current_comm unrealised_cost realised_gross_cost realised_cost is_open
#>          <char>          <char>              <char>        <char>  <lgcl>
#> 1:      0.05895           98.25                   0       0.05895    TRUE
#>    mark_price mark_value pos_cost pos_cross pos_init pos_comm pos_loss
#>         <int>     <char>   <char>    <char>   <char>   <char>   <char>
#> 1:      98350      98.35    98.25         0    19.65  0.07861        0
#>    pos_margin pos_maint maint_margin realised_gross_pnl realised_pnl
#>        <char>    <char>       <char>             <char>       <char>
#> 1:   19.72861    0.4423     19.82861                  0     -0.05895
#>    unrealised_pnl unrealised_pnl_pcnt avg_entry_price liquidation_price
#>            <char>               <num>          <char>            <char>
#> 1:            0.1               0.001         98250.0           79000.0
#>    bankrupt_price settle_currency margin_mode position_side
#>            <char>          <char>      <char>        <char>
#> 1:        78500.0            USDT    ISOLATED          BOTH
```

For full futures documentation see
[`vignette("futures-trading")`](https://dereckscompany.github.io/kucoin/articles/futures-trading.md).

## Async Usage

This package is meant to be used in an asynchronous non-blocking event
loop (i.e. à la JavaScript) and is written around promises. Please use
`later` to run your event loop. I recommend the pattern shown below.

We offer a synchronous and asynchronous instance of the classes. All
classes accept `async = TRUE`, this makes methods return promises
instead of objects. You can resolve promises in whichever way you like,
either `$then()` chaining or `async`/`await` patterns.

I recommend use
[`coro::async()`](https://coro.r-lib.org/reference/async.html) to write
sequential looking async code:

``` r

box::use(coro, later)

market_async <- KucoinMarketData$new(keys = KEYS, base_url = BASE, async = TRUE)

main <- coro$async(function() {
  ticker <- await(market_async$get_ticker(symbol = "BTC-USDT"))
  klines <- await(market_async$get_klines(symbol = "BTC-USDT", timeframe = "1hour"))

  print(ticker)
  print(klines)
})

main()

while (!later$loop_empty()) {
  later$run_now()
}
```

``` R
#>                   time      sequence   price       size best_bid best_bid_size
#>                 <POSc>        <char>  <char>     <char>   <char>        <char>
#> 1: 2024-10-17 10:04:19 1550467636704 67232.9 0.00007682  67232.8    0.41861839
#>    best_ask best_ask_size
#>      <char>        <char>
#> 1:  67232.9    1.24808993
#>               datetime     open     high      low    close   volume turnover
#>                 <POSc>    <num>    <num>    <num>    <num>    <num>    <num>
#> 1: 2025-07-26 12:00:00 117775.9 118221.2 117766.4 118128.9 264.6461 31241540
#> 2: 2025-07-26 16:00:00 118129.0 118291.8 117940.3 118227.4 197.8112 23355797
#> 3: 2025-07-26 20:00:00 118227.3 118299.3 117880.4 117915.0 252.9352 29854685
```

## Sample Data

The package includes bundled historical OHLCV data for BTC-USDT at
4-hour intervals (October 2017 through March 2026):

``` r

data(kucoin_btc_usdt_4h_ohlcv)
head(kucoin_btc_usdt_4h_ohlcv)
```

``` R
#>      symbol            datetime     open     high      low    close     volume
#>      <char>              <POSc>    <num>    <num>    <num>    <num>      <num>
#> 1: BTC-USDT 2017-10-18 16:00:00 3996.866 4318.733 3806.382 3811.101 0.12096412
#> 2: BTC-USDT 2017-10-18 20:00:00 3811.101 4088.281 3811.101 3812.004 0.06215084
#> 3: BTC-USDT 2017-10-19 00:00:00 3812.004 5548.231 3812.000 4060.403 0.13683638
#> 4: BTC-USDT 2017-10-19 04:00:00 4060.021 5693.211 3806.382 5123.414 0.37534149
#> 5: BTC-USDT 2017-10-19 08:00:00 5093.211 5693.211 5093.211 5093.211 0.93088201
#> 6: BTC-USDT 2017-10-19 12:00:00 5094.149 5693.000 5093.211 5408.350 0.47226735
#>     turnover   freq
#>        <num> <char>
#> 1:  467.0677     4h
#> 2:  241.1115     4h
#> 3:  545.1717     4h
#> 4: 1647.8900     4h
#> 5: 5071.2131     4h
#> 6: 2535.2478     4h
```

## Citation

If you use this package in your work, please cite it:

``` r

citation("kucoin")
```

> Mezquita, D. (2026). kucoin: R API Wrapper to KuCoin Cryptocurrency
> Exchange. R package version 4.0.0.

## Licence

MIT © [Dereck Mezquita](https://github.com/dereckmezquita)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--9307--6762-green)](https://orcid.org/0000-0002-9307-6762).
See [LICENSE](https://dereckscompany.github.io/kucoin/LICENSE) for the
full text.
