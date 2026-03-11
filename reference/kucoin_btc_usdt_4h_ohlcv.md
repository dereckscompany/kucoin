# BTC-USDT 4-Hour OHLCV Data from KuCoin

Historical candlestick (OHLCV) data for BTC-USDT on the KuCoin exchange
at 4-hour intervals. Contains 18,351 candles from October 2017 through
March 2026. Produced by `KucoinMarketData$get_klines()`.

## Usage

``` r
kucoin_btc_usdt_4h_ohlcv
```

## Format

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with 18,351 rows and 9 columns:

- `symbol` (character): Trading pair identifier, e.g. `"BTC-USDT"`.

- `datetime` (POSIXct): Candle open time in UTC.

- `open` (numeric): Opening price.

- `high` (numeric): Highest price during the interval.

- `low` (numeric): Lowest price during the interval.

- `close` (numeric): Closing price.

- `volume` (numeric): Trading volume in base currency (BTC).

- `turnover` (numeric): Trading turnover in quote currency (USDT).

- `freq` (character): Candle interval, `"4h"`.

## Source

KuCoin API via
[`kucoin_backfill_klines()`](https://dereckscompany.github.io/kucoin/reference/kucoin_backfill_klines.md)

## Examples

``` r
data(kucoin_btc_usdt_4h_ohlcv)
head(kucoin_btc_usdt_4h_ohlcv)
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
