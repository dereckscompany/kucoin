# Retrieve KuCoin API Credentials

Fetches API credentials from environment variables or explicit
arguments. Required environment variables: `KUCOIN_API_KEY`,
`KUCOIN_API_SECRET`, `KUCOIN_API_PASSPHRASE`.

## Usage

``` r
get_api_keys(
  api_key = Sys.getenv("KUCOIN_API_KEY"),
  api_secret = Sys.getenv("KUCOIN_API_SECRET"),
  api_passphrase = Sys.getenv("KUCOIN_API_PASSPHRASE"),
  key_version = "2"
)
```

## Arguments

- api_key:

  Character string; KuCoin API key. Defaults to
  `Sys.getenv("KUCOIN_API_KEY")`.

- api_secret:

  Character string; KuCoin API secret. Defaults to
  `Sys.getenv("KUCOIN_API_SECRET")`.

- api_passphrase:

  Character string; KuCoin API passphrase. Defaults to
  `Sys.getenv("KUCOIN_API_PASSPHRASE")`.

- key_version:

  Character string; API key version. Defaults to `"2"`.

## Value

Named list with `api_key`, `api_secret`, `api_passphrase`,
`key_version`.

## Examples

``` r
if (FALSE) { # \dontrun{
keys <- get_api_keys()
keys <- get_api_keys(api_key = "my_key", api_secret = "my_secret", api_passphrase = "my_pass")
} # }
```
