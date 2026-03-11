# Verify Ticker Symbol Format

Checks whether a ticker symbol matches the `"BASE-QUOTE"` format (e.g.,
`"BTC-USDT"`), consisting of alphanumeric characters separated by a
single dash.

## Usage

``` r
verify_symbol(ticker)
```

## Arguments

- ticker:

  Character string; the ticker symbol to verify.

## Value

Logical; `TRUE` if valid, `FALSE` otherwise.

## Examples

``` r
if (FALSE) { # \dontrun{
verify_symbol("BTC-USDT")   # TRUE
verify_symbol("btc-usdt")   # TRUE (case-insensitive)
verify_symbol("BTC_USDT")   # FALSE
verify_symbol("BTCUSDT")    # FALSE
} # }
```
