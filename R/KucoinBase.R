# File: R/KucoinBase.R
# Abstract R6 base class for all KuCoin API client classes.

#' KucoinBase: Abstract Base Class for KuCoin API Clients
#'
#' Provides shared infrastructure for all KuCoin R6 classes, including API
#' credential management, sync/async execution mode, timestamp source
#' configuration, and a standardised method for calling implementation
#' functions.
#'
#' ### Sync vs Async
#' The `async` parameter controls execution mode for all API methods:
#' - `async = FALSE` (default): methods return results directly (`data.table`, character, etc.).
#' - `async = TRUE`: methods return [promises::promise] objects that resolve to the same types.
#'
#' When async, use [coro::async()] and `await()` or [promises::then()] to consume results.
#' The `promises` package must be installed for async mode (`Suggests` dependency).
#'
#' ### Timestamp Source
#' The `time_source` parameter controls which clock is used for HMAC request
#' signing:
#' - `"local"` (default): uses `lubridate::now()` from the local machine.
#' - `"server"`: fetches the KuCoin server time via `GET /api/v1/timestamp`
#'   before each authenticated request. This is slower (one extra HTTP round
#'   trip) but ensures signing works even when the local clock is out of sync.
#'
#' ### Design
#' This class is not meant to be instantiated directly. Subclasses (e.g.,
#' [KucoinMarketData], [KucoinTrading]) inherit from it and define their
#' own public methods that delegate to `private$.request()` and `private$.paginate()`.
#'
#' @section Fields:
#' All fields are private:
#' - `.keys`: List; API credentials from [get_api_keys()].
#' - `.base_url`: Character; API base URL from [get_base_url()].
#' - `.perform`: Function; either [httr2::req_perform] or [httr2::req_perform_promise].
#' - `.is_async`: Logical; whether the instance is in async mode.
#' - `.time_source`: Character; `"local"` or `"server"`.
#' - `.get_timestamp_ms`: Function; returns epoch milliseconds for HMAC signing.
#'
#' @examples
#' \dontrun{
#' # Not instantiated directly; use subclasses:
#' market <- KucoinMarketData$new()          # sync
#' market_async <- KucoinMarketData$new(async = TRUE)  # async
#'
#' # Use server time for HMAC signing (avoids clock-drift issues):
#' trading <- KucoinTrading$new(time_source = "server")
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom httr2 req_perform
#' @export
KucoinBase <- R6::R6Class(
  "KucoinBase",
  public = list(
    #' @description
    #' Initialise a KucoinBase Object
    #'
    #' @param keys List; API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url Character; API base URL. Defaults to `get_base_url()`.
    #' @param async Logical; if `TRUE`, methods return promises. Default `FALSE`.
    #' @param time_source Character; clock source for HMAC request signing.
    #'   `"local"` (default) uses `lubridate::now()`. `"server"` fetches the KuCoin
    #'   server time before each authenticated request, which adds latency but
    #'   avoids clock-drift issues.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      private$.keys <- keys
      private$.base_url <- base_url
      private$.is_async <- isTRUE(async)
      private$.time_source <- match.arg(time_source)

      if (private$.time_source == "server") {
        # Capture base_url in closure so fetch_server_time_ms is self-contained
        url <- base_url
        private$.get_timestamp_ms <- function() fetch_server_time_ms(url)
      } else {
        private$.get_timestamp_ms <- function() floor(as.numeric(lubridate::now()) * 1000)
      }

      if (private$.is_async) {
        if (!requireNamespace("promises", quietly = TRUE)) {
          rlang::abort(
            "Package 'promises' is required for async mode. Install with: install.packages('promises')"
          )
        }
        private$.perform <- httr2::req_perform_promise
      } else {
        private$.perform <- httr2::req_perform
      }

      return(invisible(self))
    }
  ),
  active = list(
    #' @field is_async Logical; read-only flag indicating whether this instance
    #'   operates in async mode.
    is_async = function() {
      return(private$.is_async)
    },
    #' @field time_source Character; read-only flag indicating the timestamp
    #'   source used for HMAC signing (`"local"` or `"server"`).
    time_source = function() {
      return(private$.time_source)
    }
  ),
  private = list(
    .keys = NULL,
    .base_url = NULL,
    .perform = NULL,
    .is_async = FALSE,
    .time_source = "local",
    .get_timestamp_ms = NULL,

    # Execute a KuCoin API Request
    #
    # Convenience wrapper around kucoin_build_request() that injects the
    # instance's base URL, credentials, and perform function. Accepts a .parser
    # callback so subclass methods can define their data transformation without
    # any sync/async awareness.
    .request = function(
      endpoint,
      method = "GET",
      query = list(),
      body = NULL,
      auth = TRUE,
      .parser = identity,
      timeout = 10
    ) {
      return(kucoin_build_request(
        base_url = private$.base_url,
        endpoint = endpoint,
        method = method,
        query = query,
        body = body,
        keys = if (auth) private$.keys else NULL,
        .perform = private$.perform,
        .parser = .parser,
        is_async = private$.is_async,
        timeout = timeout,
        .get_timestamp_ms = private$.get_timestamp_ms
      ))
    },

    # Execute a Paginated KuCoin API Request
    #
    # Convenience wrapper around kucoin_paginate() that injects instance
    # configuration. Accepts a .parser callback for the final accumulated result.
    .paginate = function(
      endpoint,
      method = "GET",
      query = list(),
      body = NULL,
      auth = TRUE,
      .parser = identity,
      page_size = 50,
      max_pages = Inf,
      items_field = "items"
    ) {
      return(kucoin_paginate(
        base_url = private$.base_url,
        endpoint = endpoint,
        method = method,
        query = query,
        body = body,
        keys = if (auth) private$.keys else NULL,
        .perform = private$.perform,
        .parser = .parser,
        is_async = private$.is_async,
        page_size = page_size,
        max_pages = max_pages,
        items_field = items_field
      ))
    }
  )
)
