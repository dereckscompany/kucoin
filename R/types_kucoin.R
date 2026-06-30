# File: R/types_kucoin.R
# Reusable roxyassert `@type` shapes for the few KuCoin `data.table`s whose
# columns are fixed by a dedicated parser. The contract roclet expands a shape
# into the generated `assert_return_*` of every method that documents its return
# as `(Shape | promise<Shape>)`, so the column set and per-column type are
# enforced at the public boundary -- for the synchronous value and for the
# resolved value of a promise alike (wired through `connectcore::then_or_now()`).
#
# Only the candlestick (`parse_klines`, `parse_futures_klines`) and the spot
# order-book (`parse_orderbook`) parsers produce a fixed schema, so only those
# get a named shape. Every other public method returns a table built by the
# generic, schemaless flatteners (`as_dt_row` / `as_dt_list` / `flatten_pages`)
# or a bespoke inline parser, whose columns vary with the endpoint payload; per
# the cross-package convention those are documented as the generic
# `(data.table | promise<data.table>)`. The futures order-book carries an
# OPTIONAL `symbol` column (present only when the payload includes it), so it is
# variable-shape and likewise stays generic rather than a fixed `Orderbook`.

#' @title KuCoin return shapes
#' @description Reusable roxyassert `@type` shapes for the parsed KuCoin
#' `data.table`s with a fixed schema. Column types follow the package
#' convention: `numeric` is the strict double (every continuous price/size/volume
#' value), `count` is a non-negative whole number (the 1-indexed order-book
#' `level`, which the parser builds with `seq_along()` so it is never NA), and an
#' identifier the parser stringifies (`sequence`) is `character`. Datetime
#' columns are the parser's `POSIXct` (UTC). These shapes carry no `| NA`: each
#' parser coerces every value to its column type (`as.numeric()` /
#' `lubridate::as_datetime()` / `as.character()`) and the fixed-schema parsers
#' never coalesce a missing field to `NA` within a row, so a present row is
#' always fully typed and an empty result is the typed zero-row table.
#'
#' Shapes: `Klines` (the spot and futures OHLCV candles -- identical column set
#' and types; they differ only upstream, spot values arriving as strings and
#' futures as numbers, both coerced to double) and `Orderbook` (the spot
#' level-2 book in long format).
#' @name kucoin_shapes
#'
#' @type Klines (data.table) one row per candle, ascending by `datetime`
#'   (`parse_klines` / `parse_futures_klines`):
#' - datetime (POSIXct) candle open time (UTC).
#' - open (numeric | NA) open price.
#' - high (numeric | NA) high price.
#' - low (numeric | NA) low price.
#' - close (numeric | NA) close price.
#' - volume (numeric | NA) traded volume in the base asset.
#' - turnover (numeric | NA) traded turnover in the quote asset.
#'
#' @type Orderbook (data.table) the spot level-2 order book in long format, one
#'   row per price level per side, best price first (`parse_orderbook`):
#' - time (POSIXct) snapshot time (UTC).
#' - sequence (character) the book sequence number (a large integer kept as a
#'   verbatim string to avoid precision loss).
#' - side (character) the book side, `"bid"` or `"ask"`.
#' - level (count) 1-indexed depth from the top of book (`1` is best bid/ask).
#' - price (numeric | NA) the price at this level.
#' - size (numeric | NA) the size at this level.
NULL
