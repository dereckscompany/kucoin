# File: R/utils.R
# General utility functions for the kucoin package.

#' Retrieve KuCoin API Base URL
#'
#' Returns the base URL for the KuCoin API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `KUCOIN_API_ENDPOINT` environment variable.
#' 3. The default `"https://api.kucoin.com"`.
#'
#' @param url (scalar<character> | NULL) explicit base URL. Defaults to
#'   `Sys.getenv("KUCOIN_API_ENDPOINT")`.
#' @return (scalar<character>) the API base URL.
#'
#' @examples
#' \dontrun{
#' get_base_url()
#' get_base_url("https://openapi-sandbox.kucoin.com")
#' }
#' @export
get_base_url <- function(url = Sys.getenv("KUCOIN_API_ENDPOINT")) {
  assert_args_get_base_url(url)
  if (is.null(url) || !nzchar(url)) {
    return(assert_return_get_base_url("https://api.kucoin.com"))
  }
  return(assert_return_get_base_url(url))
}

#' Retrieve KuCoin Futures API Base URL
#'
#' Returns the base URL for the KuCoin Futures API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `KUCOIN_FUTURES_API_ENDPOINT` environment variable.
#' 3. The default `"https://api-futures.kucoin.com"`.
#'
#' @param url (scalar<character> | NULL) explicit base URL. Defaults to
#'   `Sys.getenv("KUCOIN_FUTURES_API_ENDPOINT")`.
#' @return (scalar<character>) the Futures API base URL.
#'
#' @examples
#' \dontrun{
#' get_futures_base_url()
#' }
#' @export
get_futures_base_url <- function(url = Sys.getenv("KUCOIN_FUTURES_API_ENDPOINT")) {
  assert_args_get_futures_base_url(url)
  if (is.null(url) || !nzchar(url)) {
    return(assert_return_get_futures_base_url("https://api-futures.kucoin.com"))
  }
  return(assert_return_get_futures_base_url(url))
}

#' Retrieve KuCoin API Credentials
#'
#' Fetches API credentials from environment variables or explicit arguments.
#' Required environment variables: `KUCOIN_API_KEY`, `KUCOIN_API_SECRET`, `KUCOIN_API_PASSPHRASE`.
#'
#' @param api_key (scalar<character>) KuCoin API key. Defaults to
#'   `Sys.getenv("KUCOIN_API_KEY")`.
#' @param api_secret (scalar<character>) KuCoin API secret. Defaults to
#'   `Sys.getenv("KUCOIN_API_SECRET")`.
#' @param api_passphrase (scalar<character>) KuCoin API passphrase. Defaults to
#'   `Sys.getenv("KUCOIN_API_PASSPHRASE")`.
#' @param key_version (scalar<character>) API key version. Defaults to `"2"`.
#' @return (list) named list with `api_key`, `api_secret`, `api_passphrase`,
#'   `key_version`.
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
  assert_args_get_api_keys(api_key, api_secret, api_passphrase, key_version)
  if (!nzchar(api_key) || !nzchar(api_secret) || !nzchar(api_passphrase)) {
    rlang::warn(
      "KuCoin API credentials are empty. Set KUCOIN_API_KEY, KUCOIN_API_SECRET, and KUCOIN_API_PASSPHRASE environment variables or pass them explicitly."
    )
  }
  return(assert_return_get_api_keys(list(
    api_key = api_key,
    api_secret = api_secret,
    api_passphrase = api_passphrase,
    key_version = key_version
  )))
}

#' Retrieve KuCoin Sub-Account Configuration
#'
#' Fetches sub-account credentials from environment variables or explicit arguments.
#'
#' @param sub_account_name (scalar<character>) sub-account name.
#'   Defaults to `Sys.getenv("KUCOIN_SUBACCOUNT_NAME")`.
#' @param sub_account_password (scalar<character>) sub-account password.
#'   Defaults to `Sys.getenv("KUCOIN_SUBACCOUNT_PASSWORD")`.
#' @return (list) named list with `sub_account_name` and
#'   `sub_account_password`.
#'
#' @export
get_sub_account <- function(
  sub_account_name = Sys.getenv("KUCOIN_SUBACCOUNT_NAME"),
  sub_account_password = Sys.getenv("KUCOIN_SUBACCOUNT_PASSWORD")
) {
  assert_args_get_sub_account(sub_account_name, sub_account_password)
  return(assert_return_get_sub_account(list(
    sub_account_name = sub_account_name,
    sub_account_password = sub_account_password
  )))
}
