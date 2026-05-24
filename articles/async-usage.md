# Asynchronous Usage with kucoin

Every R6 class in `kucoin` accepts an `async = TRUE` flag at
construction. When enabled, all methods return
[`promises::promise`](https://rstudio.github.io/promises/reference/promise.html)
objects instead of direct values. This vignette shows how to consume
those promises with
[`coro::async`](https://coro.r-lib.org/reference/async.html)/`await` and
[`later::run_now`](https://later.r-lib.org/reference/run_now.html).

## Why Async?

Synchronous HTTP blocks the R session while waiting for a reply.
Asynchronous mode lets you fire off multiple requests and process
results as they arrive — useful for bots that poll several endpoints or
place orders in parallel.

## Setup

``` r

box::use(
  kucoin[KucoinMarketData, KucoinTrading, KucoinAccount, get_api_keys],
  coro[async, await],
  later[run_now, loop_empty],
  promises[then, catch, promise_all, promise_resolve]
)

keys <- get_api_keys(
  api_key = "your-api-key",
  api_secret = "your-api-secret",
  api_passphrase = "your-api-passphrase"
)
```

> **Event loop**: R does not have a built-in event loop like Node.js or
> Python’s `asyncio`. Promises only resolve when the event loop ticks
> via
> [`later::run_now()`](https://later.r-lib.org/reference/run_now.html).
> In scripts and vignettes, drain the loop with
> `while (!loop_empty()) run_now()`. In **Shiny** apps the event loop
> runs automatically.

------------------------------------------------------------------------

## Basic Async: `coro::async` + `await`

The most ergonomic way to work with promises in R is
[`coro::async`](https://coro.r-lib.org/reference/async.html), which lets
you write code that *looks* synchronous but runs asynchronously under
the hood — just like TypeScript’s `async`/`await`.

``` r

market <- KucoinMarketData$new(async = TRUE)
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

get_stats <- async(function() {
  stats <- await(market$get_24hr_stats(symbol = "BTC-USDT"))
  return(stats)
})

get_stats()
while (!loop_empty()) {
  run_now()
}
```

> **Key pattern**: define an `async` function, `await` each API call,
> return the result. Drain the event loop with
> `while (!loop_empty()) run_now()`.

------------------------------------------------------------------------

## Sequential Async: Multiple `await` Calls

Chain several awaited calls in sequence — each one resolves before the
next begins, just like `await` in TypeScript:

``` r

results <- NULL

fetch_tickers <- async(function() {
  btc <- await(market$get_ticker(symbol = "BTC-USDT"))
  eth <- await(market$get_ticker(symbol = "ETH-USDT"))
  results <<- list(btc = btc, eth = eth)
  return(invisible(NULL))
})

fetch_tickers()
while (!loop_empty()) {
  run_now()
}
results$btc
results$eth
```

    #>                   time      sequence   price       size best_bid best_bid_size
    #>                 <POSc>        <char>  <char>     <char>   <char>        <char>
    #> 1: 2024-10-17 10:04:19 1550467636704 67232.9 0.00007682  67232.8    0.41861839
    #>    best_ask best_ask_size
    #>      <char>        <char>
    #> 1:  67232.9    1.24808993
    #>                   time sequence  price   size best_bid best_bid_size best_ask
    #>                 <POSc>   <char> <char> <char>   <char>        <char>   <char>
    #> 1: 2024-10-17 10:04:19   200001 2530.6    0.5   2530.5          12.0   2530.8
    #>    best_ask_size
    #>           <char>
    #> 1:           8.5

------------------------------------------------------------------------

## Concurrent Requests with `promise_all`

When requests are independent, fire them simultaneously and collect all
results at once — the async equivalent of `Promise.all()` in TypeScript:

``` r

results <- NULL

fetch_parallel <- async(function() {
  # Launch both requests concurrently — no await yet, just collect promises
  btc_promise <- market$get_ticker(symbol = "BTC-USDT")
  eth_promise <- market$get_ticker(symbol = "ETH-USDT")
  # Await them together — like Promise.all([btc, eth])
  res <- await(promise_all(btc = btc_promise, eth = eth_promise))
  results <<- res
  return(invisible(NULL))
})

fetch_parallel()
while (!loop_empty()) {
  run_now()
}
results$btc
results$eth
```

    #>                   time      sequence   price       size best_bid best_bid_size
    #>                 <POSc>        <char>  <char>     <char>   <char>        <char>
    #> 1: 2024-10-17 10:04:19 1550467636704 67232.9 0.00007682  67232.8    0.41861839
    #>    best_ask best_ask_size
    #>      <char>        <char>
    #> 1:  67232.9    1.24808993
    #>                   time sequence  price   size best_bid best_bid_size best_ask
    #>                 <POSc>   <char> <char> <char>   <char>        <char>   <char>
    #> 1: 2024-10-17 10:04:19   200001 2530.6    0.5   2530.5          12.0   2530.8
    #>    best_ask_size
    #>           <char>
    #> 1:           8.5

------------------------------------------------------------------------

## Promise Chaining with `then` / `catch`

If you prefer the promise-pipeline style (common in JavaScript), use
`then` and `catch`:

``` r

account <- KucoinAccount$new(async = TRUE)
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

chain_result <- NULL

account$get_summary() |>
  then(function(summary) {
    chain_result <<- summary
    return(invisible(NULL))
  }) |>
  catch(function(err) {
    message("Error: ", conditionMessage(err))
    return(invisible(NULL))
  })

while (!loop_empty()) {
  run_now()
}
chain_result
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

------------------------------------------------------------------------

## Async Trading Example

Place a test order and immediately query open orders — sequential
`await` keeps the flow readable:

``` r

trading <- KucoinTrading$new(async = TRUE)
```

    #> Warning: KuCoin API credentials are empty. Set KUCOIN_API_KEY,
    #> KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them
    #> explicitly.

``` r

results <- NULL

place_and_check <- async(function() {
  # Place a test order
  order <- await(trading$add_order_test(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = "50000",
    size = "0.0001"
  ))

  # Query open orders
  open <- await(trading$get_open_orders(symbol = "BTC-USDT"))

  results <<- list(order = order, open = open)
  return(invisible(NULL))
})

place_and_check()
while (!loop_empty()) {
  run_now()
}
results$order
results$open
```

    #>             order_id         client_oid
    #>               <char>             <char>
    #> 1: futures-order-001 futures-client-001
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

------------------------------------------------------------------------

## Error Handling with `tryCatch`

Inside `async` functions, you can use `tryCatch` around `await` calls
for structured error handling — just like `try`/`catch` in TypeScript:

``` r

safe_fetch <- async(function() {
  result <- tryCatch(
    await(market$get_ticker(symbol = "INVALID-PAIR")),
    error = function(e) {
      message("Caught error: ", conditionMessage(e))
      return(NULL)
    }
  )
  return(result)
})

safe_fetch()
while (!loop_empty()) {
  run_now()
}
```

------------------------------------------------------------------------

## Running the Event Loop

The critical piece of async R is the **event loop**. Promises do not
resolve until the event loop ticks. In an interactive session or Shiny
app, the event loop runs automatically. In scripts or vignettes, you
must drive it manually.

``` r

# Idiomatic event loop drain
while (!later::loop_empty()) {
  later::run_now()
}
```

Or with a timeout guard:

``` r

deadline <- lubridate::now() + 30 # 30-second timeout
while (!later::loop_empty() && lubridate::now() < deadline) {
  later::run_now(timeoutSecs = 0.1)
}
```

In **Shiny** applications, the event loop is managed for you — simply
return promises from reactive expressions and Shiny handles resolution.

For bots or long-running processes, use the **Scheduler / Looper**
pattern (see package README) where `later` drives the loop
automatically.

------------------------------------------------------------------------

## `coro::await` Cheat Sheet

| Pattern | Works? | Notes |
|----|----|----|
| `x <- await(promise)` | Yes | Standard pattern |
| `x <- await(obj$method(arg))` | Yes | Await wrapping a call is fine |
| `await(promise)` (bare, no assignment) | Yes | Side-effect only |
| `await` inside loops/if/tryCatch | Yes | Full control flow support |
| `x <<- await(promise)` | **No** | `<<-` not supported by coro |
| `f(await(promise))` | **No** | Nested inside function args |

> **Rule of thumb**: `await()` must appear as the RHS of a `<-` or as a
> bare statement — never inside another expression. Return values from
> the async function and extract them via `then()` or the `<<-` pattern
> outside the async body.

------------------------------------------------------------------------

## Choosing Sync vs Async

| Scenario | Recommendation |
|----|----|
| Interactive exploration | **Sync** — simpler, results print immediately |
| Scripts fetching one endpoint | **Sync** — no event loop needed |
| Bots polling multiple symbols | **Async** — concurrent requests reduce latency |
| Shiny dashboards | **Async** — keeps the UI responsive |
| Bulk data downloads | Use [`kucoin_backfill_klines()`](https://dereckscompany.github.io/kucoin/reference/kucoin_backfill_klines.md) (sync, handles batching internally) |

------------------------------------------------------------------------

## Next Steps

- See
  [`vignette("getting-started")`](https://dereckscompany.github.io/kucoin/articles/getting-started.md)
  for a full tour of all spot classes in sync mode.
- See
  [`vignette("margin-trading")`](https://dereckscompany.github.io/kucoin/articles/margin-trading.md)
  for margin trading, short selling, and lending.
- See
  [`vignette("futures-trading")`](https://dereckscompany.github.io/kucoin/articles/futures-trading.md)
  for perpetual futures contracts.
- Browse the [pkgdown site](https://dereckscompany.github.io/kucoin/)
  for full method documentation.
