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

  Character vector of trading pair symbols (e.g.,
  `c("BTC-USDT", "ETH-USDT")`). Must not be NULL or empty.

- timeframes:

  Character vector of candle timeframes (e.g., `c("1day", "1hour")`).
  Valid values are the names of the internal timeframe map: `"1min"`,
  `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`,
  `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`,
  `"1month"`.

- from:

  POSIXct or numeric; start of the backfill window. Defaults to one year
  ago. Values before `"2017-01-01"` (or `-Inf`) are clamped to
  `"2017-01-01"` since KuCoin data does not exist before that date.

- to:

  POSIXct or numeric; end of the backfill window. Defaults to current
  time. `Inf` is replaced with current time.

- file:

  Character; path to the output CSV file. Data is appended incrementally
  so progress is saved even if the process is interrupted.

- base_url:

  Character; KuCoin API base URL.

- sleep:

  Numeric; seconds to sleep between each symbol-timeframe combination to
  respect rate limits.

- verbose:

  Logical; if `TRUE`, prints progress messages via
  [`rlang::inform()`](https://rlang.r-lib.org/reference/abort.html).

## Value

The file path (invisibly). If any symbol-timeframe combinations failed,
a `"failures"` attribute is attached containing a
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns `symbol`, `timeframe`, and `error`.

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
