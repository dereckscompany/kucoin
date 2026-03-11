#' BTC-USDT 4-Hour OHLCV Data from KuCoin
#'
#' Historical candlestick (OHLCV) data for BTC-USDT on the KuCoin exchange
#' at 4-hour intervals. Contains 18,351 candles from October 2017 through
#' March 2026. Produced by `KucoinMarketData$get_klines()`.
#'
#' @format A [data.table::data.table] with 18,351 rows and 9 columns:
#'   - `symbol` (character): Trading pair identifier, e.g. `"BTC-USDT"`.
#'   - `datetime` (POSIXct): Candle open time in UTC.
#'   - `open` (numeric): Opening price.
#'   - `high` (numeric): Highest price during the interval.
#'   - `low` (numeric): Lowest price during the interval.
#'   - `close` (numeric): Closing price.
#'   - `volume` (numeric): Trading volume in base currency (BTC).
#'   - `turnover` (numeric): Trading turnover in quote currency (USDT).
#'   - `freq` (character): Candle interval, `"4h"`.
#'
#' @source KuCoin API via [kucoin_backfill_klines()]
#' @examples
#' data(kucoin_btc_usdt_4h_ohlcv)
#' head(kucoin_btc_usdt_4h_ohlcv)
"kucoin_btc_usdt_4h_ohlcv"
