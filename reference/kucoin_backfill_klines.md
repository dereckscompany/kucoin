# Backfill KuCoin Kline Data to CSV

Downloads historical OHLCV candlestick data for one or more trading
pairs and timeframes, writing results incrementally to a CSV file.
Supports resuming from a partially completed backfill by reading the
existing file and skipping symbol-timeframe combinations that are
already up to date.

## Usage

``` r
kucoin_backfill_klines(
  symbols,
  timeframes = "1day",
  from = lubridate::now("UTC") - lubridate::ddays(365),
  to = lubridate::now("UTC"),
  file = "kucoin_klines.csv",
  base_url = "https://api.kucoin.com",
  sleep = 0.3,
  verbose = TRUE
)
```

## Arguments

- symbols:

  (vector\<character, 1..\>) trading pair symbols (e.g.,
  `c("BTC-USDT", "ETH-USDT")`). Must not be NULL or empty.

- timeframes:

  (vector\<character, 1..\>) candle timeframes (e.g.,
  `c("1day", "1hour")`). Valid values are the names of the internal
  timeframe map: `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`,
  `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`,
  `"1day"`, `"1week"`, `"1month"`.

- from:

  (POSIXct \| scalar\<numeric\>) start of the backfill window. Defaults
  to one year ago. Values before `"2017-01-01"` (or `-Inf`) are clamped
  to `"2017-01-01"` since KuCoin data does not exist before that date.

- to:

  (POSIXct \| scalar\<numeric\>) end of the backfill window. Defaults to
  current time. `Inf` is replaced with current time.

- file:

  (scalar\<character\>) path to the output CSV file. Data is appended
  incrementally so progress is saved even if the process is interrupted.

- base_url:

  (scalar\<character\>) KuCoin API base URL.

- sleep:

  (scalar\<numeric in \[0, Inf\[\>) seconds to sleep between each
  symbol-timeframe combination to respect rate limits.

- verbose:

  (scalar\<logical\>) if `TRUE`, prints progress messages via
  [`rlang::inform()`](https://rlang.r-lib.org/reference/abort.html).

## Value

(scalar\<character\>) the file path (invisibly).

Per-combo failures are surfaced as warnings during the run (one
[`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) per
failed `(symbol, timeframe)` pair, with the underlying error message).
After the loop, if any combinations failed, a final summary warning
lists the count and the affected pairs. No failure data is hidden on the
return value.

## Examples

``` r
if (FALSE) { # \dontrun{
kucoin_backfill_klines(
  symbols = c("BTC-USDT", "ETH-USDT"),
  timeframes = c("1day", "1hour"),
  from = lubridate::as_datetime("2020-01-01"),
  file = "my_klines.csv"
)
} # }
```
