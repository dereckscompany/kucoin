# KuCoin return shapes

Reusable roxyassert `@type` shapes for the parsed KuCoin `data.table`s
with a fixed schema. Column types follow the package's lean-permissive
convention. The continuous measurement columns (prices, sizes, volume,
turnover) are `numeric | NA`: they carry the strict double type but
tolerate a missing value, since a contract stricter than the live feed
can guarantee is a latent abort. The structural columns stay strict:
`count` is a non-negative whole number (the 1-indexed order-book
`level`, which the parser builds with
[`seq_along()`](https://rdrr.io/r/base/seq.html) so it is never NA), the
identifier the parser stringifies (`sequence`) is `character`, `side` is
`character`, and datetime columns are the parser's `POSIXct` (UTC). An
empty result is the typed zero-row table.

Shapes: `Klines` (the spot and futures OHLCV candles – identical column
set and types; they differ only upstream, spot values arriving as
strings and futures as numbers, both coerced to double) and `Orderbook`
(the spot level-2 book in long format).
