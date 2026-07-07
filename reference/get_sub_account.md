# Retrieve KuCoin Sub-Account Configuration

Fetches sub-account credentials from environment variables or explicit
arguments.

## Usage

``` r
get_sub_account(
  sub_account_name = Sys.getenv("KUCOIN_SUBACCOUNT_NAME"),
  sub_account_password = Sys.getenv("KUCOIN_SUBACCOUNT_PASSWORD")
)
```

## Arguments

- sub_account_name:

  (scalar\<character\>) sub-account name. Defaults to
  `Sys.getenv("KUCOIN_SUBACCOUNT_NAME")`.

- sub_account_password:

  (scalar\<character\>) sub-account password. Defaults to
  `Sys.getenv("KUCOIN_SUBACCOUNT_PASSWORD")`.

## Value

(list) named list with `sub_account_name` and `sub_account_password`.
