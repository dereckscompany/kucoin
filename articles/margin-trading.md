# Margin Trading with kucoin

This vignette covers margin trading, lending, and margin market data
using the `kucoin` package. All examples assume synchronous usage.

## Overview

The package provides three classes for margin operations:

| Class | Purpose |
|----|----|
| `KucoinMarginTrading` | Open/close short and long positions, borrow, repay, manage leverage |
| `KucoinMarginData` | Query margin-enabled symbols, config, risk limits, collateral ratios |
| `KucoinLending` | Lend assets to earn interest, manage lending orders |

## Setup

``` r

box::use(
  kucoin[
    KucoinMarginTrading, KucoinMarginData, KucoinLending, get_api_keys
  ]
)

keys <- get_api_keys(
  api_key = "your-api-key",
  api_secret = "your-api-secret",
  api_passphrase = "your-api-passphrase"
)

margin <- KucoinMarginTrading$new(keys = keys)
margin_data <- KucoinMarginData$new(keys = keys)
lending <- KucoinLending$new(keys = keys)
```

------------------------------------------------------------------------

## Margin Trading

### Short Selling

Short selling lets you profit from a price decline. The package uses
intent-based methods that handle borrowing and repayment automatically:

``` r

# Open a short: borrows BTC and sells it
order <- margin$open_short(
  symbol = "BTC-USDT",
  size = 0.001
)
order

# Later, close the short: buys BTC back and repays the loan
close <- margin$close_short(
  symbol = "BTC-USDT",
  size = 0.001
)
close
```

    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001
    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001

### Leveraged Long

A leveraged long lets you buy more of an asset than your balance allows:

``` r

# Open a leveraged long: borrows USDT and buys BTC
order <- margin$open_long(
  symbol = "BTC-USDT",
  size = 0.001
)
order

# Later, close the long: sells BTC and repays the USDT loan
close <- margin$close_long(
  symbol = "BTC-USDT",
  size = 0.001
)
close
```

    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001
    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001

### Limit Orders

All four methods default to market orders. Use `type = "limit"` for
limit orders:

``` r

order <- margin$open_short(
  symbol = "BTC-USDT",
  type = "limit",
  price = 100000,
  size = 0.001,
  timeInForce = "GTC"
)
order
```

    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001

### Cross vs Isolated Margin

By default, all methods use **cross margin** (shared collateral pool).
For **isolated margin** (risk limited to one pair), set
`isIsolated = TRUE`:

``` r

order <- margin$open_short(
  symbol = "BTC-USDT",
  size = 0.001,
  isIsolated = TRUE
)
order
```

    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001

### Dry Run (Test Orders)

Validate parameters without placing a real order:

``` r

test <- margin$open_short(
  symbol = "BTC-USDT",
  size = 0.001,
  dry_run = TRUE
)
test
```

    #>                    order_id       client_oid borrow_size  loan_apply_id
    #>                      <char>           <char>      <char>         <char>
    #> 1: 6789abcd1234ef0007ab1234 margin-order-001       0.001 loan-apply-001

### Client Order IDs

Track orders with your own identifiers:

``` r

order <- margin$open_short(
  symbol = "BTC-USDT",
  size = 0.001,
  clientOid = "my-strategy-short-001"
)
order$client_oid
```

    #> [1] "margin-order-001"

------------------------------------------------------------------------

## Manual Borrow and Repay

The intent-based methods (`open_short`, `close_short`, etc.) handle
borrowing and repayment automatically. For advanced workflows where you
want explicit control:

``` r

# Manually borrow USDT
loan <- margin$borrow(currency = "USDT", size = 1000)
loan

# ... do your trading ...

# Manually repay
result <- margin$repay(currency = "USDT", size = 1000)
result
```

    #>            order_no actual_size
    #>              <char>      <char>
    #> 1: borrow-order-001        1000
    #>           order_no actual_size           timestamp
    #>             <char>      <char>              <POSc>
    #> 1: repay-order-001        1000 2024-10-23 03:53:26

### Borrow History and Interest

``` r

# Check borrow history
borrows <- margin$get_borrow_history(query = list(currency = "USDT"))
borrows

# Check repayment history
repays <- margin$get_repay_history(query = list(currency = "USDT"))
repays

# Check interest accrued
interest <- margin$get_interest_history(query = list(currency = "USDT"))
interest

# Current borrow rates
rates <- margin$get_borrow_rate(query = list(currency = "BTC,USDT,ETH"))
rates
```

    #>            order_no currency principal interest        created_time
    #>              <char>   <char>    <char>   <char>              <POSc>
    #> 1: borrow-order-001     USDT      1000      0.5 2024-10-23 03:53:26
    #> 2: borrow-order-002     USDT       500      0.2 2024-10-23 03:55:06
    #>           order_no currency principal interest        created_time
    #>             <char>   <char>    <char>   <char>              <POSc>
    #> 1: repay-order-001     USDT      1000      0.5 2024-10-23 03:53:26
    #>    currency interest_payment_amount        created_time
    #>      <char>                  <char>              <POSc>
    #> 1:     USDT                     0.5 2024-10-23 03:53:26
    #>    currency hourly_borrow_rate annualized_borrow_rate
    #>      <char>             <char>                 <char>
    #> 1:      BTC           0.000021                 0.1839
    #> 2:     USDT           0.000015                 0.1314
    #> 3:      ETH           0.000018                 0.1577

### Leverage

``` r

# Set leverage multiplier
margin$modify_leverage(leverage = 5)
```

    #>    leverage  status
    #>       <num>  <char>
    #> 1:        5 success

------------------------------------------------------------------------

## Margin Market Data

Query margin-specific market information:

``` r

# Available cross margin trading pairs
symbols <- margin_data$get_cross_margin_symbols()
symbols[, .(symbol, enable_trading)]

# Available isolated margin trading pairs
iso_symbols <- margin_data$get_isolated_margin_symbols()
iso_symbols[, .(symbol, max_leverage, trade_enable)]

# Global margin config
config <- margin_data$get_margin_config()
cat("Max leverage:", config$max_leverage, "\n")
cat("Liquidation debt ratio:", config$liq_debt_ratio, "\n")

# Collateral ratios
ratios <- margin_data$get_collateral_ratio()
ratios
```

    #>      symbol enable_trading
    #>      <char>         <lgcl>
    #> 1: BTC-USDT           TRUE
    #> 2: ETH-USDT           TRUE
    #>      symbol max_leverage trade_enable
    #>      <char>        <int>       <lgcl>
    #> 1: BTC-USDT           10         TRUE
    #> 2: ETH-USDT            5         TRUE
    #> Max leverage: 10 10 10 10 
    #> Liquidation debt ratio: 0.97 0.97 0.97 0.97 
    #>    currency lower_limit upper_limit collateral_ratio
    #>      <char>      <char>      <char>           <char>
    #> 1:      BTC           0          10              1.0
    #> 2:      BTC          10         100              0.9
    #> 3:      ETH           0          50             0.95
    #> 4:      ETH          50         500             0.85

``` r

# Risk limits (requires auth)
limits <- margin_data$get_risk_limit(isIsolated = FALSE)
limits[, .(currency, borrow_max_amount, borrow_enabled)]
```

    #>    currency borrow_max_amount borrow_enabled
    #>      <char>            <char>         <lgcl>
    #> 1:      BTC               100           TRUE
    #> 2:     USDT           1000000           TRUE

------------------------------------------------------------------------

## Lending

Earn passive income by lending your assets to the margin lending pool:

``` r

# Check available lending currencies
market <- lending$get_loan_market()
market

# Check market interest rates (last 7 days)
rates <- lending$get_loan_market_rate(currency = "USDT")
rates

# Lend 1000 USDT at 5% interest
order <- lending$purchase(currency = "USDT", size = 1000, interestRate = 0.05)
order$order_no

# Update the interest rate
lending$modify_purchase(
  currency = "USDT",
  purchaseOrderNo = order$order_no,
  interestRate = 0.06
)

# Check your lending orders
orders <- lending$get_purchase_orders(query = list(currency = "USDT", status = "DONE"))
orders

# Redeem (withdraw) lent assets
result <- lending$redeem(
  currency = "USDT",
  size = 500,
  purchaseOrderNo = order$order_no
)
result$order_no

# Check redemption history
redeems <- lending$get_redeem_orders(query = list(currency = "USDT", status = "DONE"))
redeems
```

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
    #>            time market_interest_rate
    #>          <char>               <char>
    #> 1: 202603070000                 0.05
    #> 2: 202603060000                0.048
    #> 3: 202603050000                0.052
    #> [1] "lending-purchase-001"
    #>    currency    purchase_order_no interest_rate  status
    #>      <char>               <char>         <num>  <char>
    #> 1:     USDT lending-purchase-001          0.06 success
    #>    currency    purchase_order_no purchase_size match_size interest_rate
    #>      <char>               <char>        <char>     <char>        <char>
    #> 1:     USDT lending-purchase-001          1000        800          0.05
    #>    income_size          apply_time status
    #>         <char>              <POSc> <char>
    #> 1:        3.42 2024-10-23 03:53:26   DONE
    #> [1] "lending-redeem-001"
    #>    currency    purchase_order_no    redeem_order_no redeem_size receipt_size
    #>      <char>               <char>             <char>      <char>       <char>
    #> 1:     USDT lending-purchase-001 lending-redeem-001         500          500
    #>             apply_time status
    #>                 <POSc> <char>
    #> 1: 2024-10-23 03:53:26   DONE

------------------------------------------------------------------------

## Method Reference

### KucoinMarginTrading

| Method                   | Description                               |
|--------------------------|-------------------------------------------|
| `open_short()`           | Borrow + sell (profit from price decline) |
| `close_short()`          | Buy back + repay (close a short position) |
| `open_long()`            | Borrow + buy (leveraged long)             |
| `close_long()`           | Sell + repay (close a leveraged long)     |
| `borrow()`               | Manually borrow assets                    |
| `repay()`                | Manually repay borrowed assets            |
| `get_borrow_history()`   | Query borrow records                      |
| `get_repay_history()`    | Query repayment records                   |
| `get_interest_history()` | Query interest accrual history            |
| `get_borrow_rate()`      | Current borrow interest rates             |
| `modify_leverage()`      | Update leverage multiplier                |

### KucoinMarginData

| Method                          | Description                             |
|---------------------------------|-----------------------------------------|
| `get_cross_margin_symbols()`    | Cross margin trading pairs              |
| `get_isolated_margin_symbols()` | Isolated margin trading pairs           |
| `get_margin_config()`           | Global margin config (leverage, ratios) |
| `get_collateral_ratio()`        | Collateral ratio tiers                  |
| `get_risk_limit()`              | Borrow/hold limits per currency         |

### KucoinLending

| Method                   | Description                  |
|--------------------------|------------------------------|
| `get_loan_market()`      | Available lending currencies |
| `get_loan_market_rate()` | Market interest rate history |
| `purchase()`             | Lend assets to earn interest |
| `modify_purchase()`      | Update lending interest rate |
| `get_purchase_orders()`  | Query lending orders         |
| `redeem()`               | Withdraw lent assets         |
| `get_redeem_orders()`    | Query redemption orders      |
