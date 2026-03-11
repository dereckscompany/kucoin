# Retrieve KuCoin API Base URL

Returns the base URL for the KuCoin API in the following priority:

1.  The explicitly provided `url` parameter.

2.  The `KUCOIN_API_ENDPOINT` environment variable.

3.  The default `"https://api.kucoin.com"`.

## Usage

``` r
get_base_url(url = Sys.getenv("KUCOIN_API_ENDPOINT"))
```

## Arguments

- url:

  Character string; explicit base URL. Defaults to
  `Sys.getenv("KUCOIN_API_ENDPOINT")`.

## Value

Character string; the API base URL.

## Examples

``` r
if (FALSE) { # \dontrun{
get_base_url()
get_base_url("https://openapi-sandbox.kucoin.com")
} # }
```
