#' BTC-USDT 4-Hour OHLCV Data from KuCoin
#'
#' Historical candlestick (OHLCV) data for BTC-USDT on the KuCoin exchange
#' at 4-hour intervals. Contains 18,141 candles from October 2017 through
#' February 2026. Produced by [kucoin_backfill_klines()].
#'
#' @format A [data.table::data.table] with 18,141 rows and 9 columns:
#' \describe{
#'   \item{symbol}{Character. Trading pair identifier, e.g. `"BTC-USDT"`.}
#'   \item{datetime}{POSIXct. Candle open time in UTC.}
#'   \item{open}{Numeric. Opening price.}
#'   \item{high}{Numeric. Highest price during the interval.}
#'   \item{low}{Numeric. Lowest price during the interval.}
#'   \item{close}{Numeric. Closing price.}
#'   \item{volume}{Numeric. Trading volume in base currency (BTC).}
#'   \item{turnover}{Numeric. Trading turnover in quote currency (USDT).}
#'   \item{freq}{Character. Candle interval, `"4h"`.}
#' }
#'
#' @source KuCoin API via [kucoin_backfill_klines()]
#' @examples
#' data(kucoin_btc_usdt_4h_ohlcv)
#' head(kucoin_btc_usdt_4h_ohlcv)
"kucoin_btc_usdt_4h_ohlcv"
