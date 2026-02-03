# File: R/utils.R
# General utility functions for the kucoin package.

#' Retrieve KuCoin API Base URL
#'
#' Returns the base URL for the KuCoin API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `KC-API-ENDPOINT` environment variable.
#' 3. The default `"https://api.kucoin.com"`.
#'
#' @param url Character string; explicit base URL. Defaults to
#'   `Sys.getenv("KC-API-ENDPOINT")`.
#' @return Character string; the API base URL.
#'
#' @examples
#' \dontrun{
#' get_base_url()
#' get_base_url("https://openapi-sandbox.kucoin.com")
#' }
#' @export
get_base_url <- function(url = Sys.getenv("KC-API-ENDPOINT")) {
  if (is.null(url) || !nzchar(url)) {
    return("https://api.kucoin.com")
  }
  return(url)
}

#' Retrieve KuCoin API Credentials
#'
#' Fetches API credentials from environment variables or explicit arguments.
#' Required environment variables: `KC-API-KEY`, `KC-API-SECRET`, `KC-API-PASSPHRASE`.
#'
#' @param api_key Character string; KuCoin API key. Defaults to `Sys.getenv("KC-API-KEY")`.
#' @param api_secret Character string; KuCoin API secret. Defaults to `Sys.getenv("KC-API-SECRET")`.
#' @param api_passphrase Character string; KuCoin API passphrase. Defaults to `Sys.getenv("KC-API-PASSPHRASE")`.
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
  api_key = Sys.getenv("KC-API-KEY"),
  api_secret = Sys.getenv("KC-API-SECRET"),
  api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
  key_version = "2"
) {
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
#'   Defaults to `Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME")`.
#' @param sub_account_password Character string; sub-account password.
#'   Defaults to `Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")`.
#' @return Named list with `sub_account_name` and `sub_account_password`.
#'
#' @export
get_sub_account <- function(
  sub_account_name = Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME"),
  sub_account_password = Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")
) {
  return(list(
    sub_account_name = sub_account_name,
    sub_account_password = sub_account_password
  ))
}
