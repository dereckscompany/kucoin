# Retrieve KuCoin Futures API Base URL

Returns the base URL for the KuCoin Futures API in the following
priority:

1.  The explicitly provided `url` parameter.

2.  The `KUCOIN_FUTURES_API_ENDPOINT` environment variable.

3.  The default `"https://api-futures.kucoin.com"`.

## Usage

``` r
get_futures_base_url(url = Sys.getenv("KUCOIN_FUTURES_API_ENDPOINT"))
```

## Arguments

- url:

  Character string; explicit base URL. Defaults to
  `Sys.getenv("KUCOIN_FUTURES_API_ENDPOINT")`.

## Value

Character string; the Futures API base URL.

## Examples

``` r
if (FALSE) { # \dontrun{
get_futures_base_url()
} # }
```
