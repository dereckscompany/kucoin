# File: R/utils.R
# General utility functions for the kucoin package.

#' Retrieve KuCoin API Base URL
#'
#' Returns the base URL for the KuCoin API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `KUCOIN_API_ENDPOINT` environment variable.
#' 3. The default `"https://api.kucoin.com"`.
#'
#' @param url Character string; explicit base URL. Defaults to
#'   `Sys.getenv("KUCOIN_API_ENDPOINT")`.
#' @return Character string; the API base URL.
#'
#' @examples
#' \dontrun{
#' get_base_url()
#' get_base_url("https://openapi-sandbox.kucoin.com")
#' }
#' @export
get_base_url <- function(url = Sys.getenv("KUCOIN_API_ENDPOINT")) {
  if (is.null(url) || !nzchar(url)) {
    return("https://api.kucoin.com")
  }
  return(url)
}

#' Retrieve KuCoin Futures API Base URL
#'
#' Returns the base URL for the KuCoin Futures API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `KUCOIN_FUTURES_API_ENDPOINT` environment variable.
#' 3. The default `"https://api-futures.kucoin.com"`.
#'
#' @param url Character string; explicit base URL. Defaults to
#'   `Sys.getenv("KUCOIN_FUTURES_API_ENDPOINT")`.
#' @return Character string; the Futures API base URL.
#'
#' @examples
#' \dontrun{
#' get_futures_base_url()
#' }
#' @export
get_futures_base_url <- function(url = Sys.getenv("KUCOIN_FUTURES_API_ENDPOINT")) {
  if (is.null(url) || !nzchar(url)) {
    return("https://api-futures.kucoin.com")
  }
  return(url)
}

#' Retrieve KuCoin API Credentials
#'
#' Fetches API credentials from environment variables or explicit arguments.
#' Required environment variables: `KUCOIN_API_KEY`, `KUCOIN_API_SECRET`, `KUCOIN_API_PASSPHRASE`.
#'
#' @param api_key Character string; KuCoin API key. Defaults to `Sys.getenv("KUCOIN_API_KEY")`.
#' @param api_secret Character string; KuCoin API secret. Defaults to `Sys.getenv("KUCOIN_API_SECRET")`.
#' @param api_passphrase Character string; KuCoin API passphrase. Defaults to `Sys.getenv("KUCOIN_API_PASSPHRASE")`.
#' @param key_version Character string; API key version. Defaults to `"2"`.
#' @return Named list with `api_key`, `api_secret`, `api_passphrase`, `key_version`.
#'
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' keys <- get_api_keys(api_key = "my_key", api_secret = "my_secret", api_passphrase = "my_pass")
#' }
#' @export
get_api_keys <- function(
  api_key = Sys.getenv("KUCOIN_API_KEY"),
  api_secret = Sys.getenv("KUCOIN_API_SECRET"),
  api_passphrase = Sys.getenv("KUCOIN_API_PASSPHRASE"),
  key_version = "2"
) {
  if (!nzchar(api_key) || !nzchar(api_secret) || !nzchar(api_passphrase)) {
    rlang::warn(
      "KuCoin API credentials are empty. Set KUCOIN_API_KEY, KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them explicitly."
    )
  }
  return(list(
    api_key = api_key,
    api_secret = api_secret,
    api_passphrase = api_passphrase,
    key_version = key_version
  ))
}

#' Retrieve KuCoin Sub-Account Configuration
#'
#' Fetches sub-account credentials from environment variables or explicit arguments.
#'
#' @param sub_account_name Character string; sub-account name.
#'   Defaults to `Sys.getenv("KUCOIN_SUBACCOUNT_NAME")`.
#' @param sub_account_password Character string; sub-account password.
#'   Defaults to `Sys.getenv("KUCOIN_SUBACCOUNT_PASSWORD")`.
#' @return Named list with `sub_account_name` and `sub_account_password`.
#'
#' @export
get_sub_account <- function(
  sub_account_name = Sys.getenv("KUCOIN_SUBACCOUNT_NAME"),
  sub_account_password = Sys.getenv("KUCOIN_SUBACCOUNT_PASSWORD")
) {
  return(list(
    sub_account_name = sub_account_name,
    sub_account_password = sub_account_password
  ))
}
