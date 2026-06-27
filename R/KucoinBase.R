# File: R/KucoinBase.R
# Abstract R6 base class for all KuCoin API client classes.

#' KucoinBase: Abstract Base Class for KuCoin API Clients
#'
#' Provides shared infrastructure for all KuCoin R6 classes, including API
#' credential management, sync/async execution mode, timestamp source
#' configuration, and a standardised method for calling implementation
#' functions.
#'
#' ### Transport
#' This class is a thin KuCoin specialisation of [connectcore::RestClient], the
#' shared transport base. Credential storage, the sync/async mode flag, the
#' server-time clock source, and the `is_async` / `time_source` active bindings
#' all live in `connectcore`; `KucoinBase` supplies the two venue-specific seams
#' — how KuCoin authenticates a request (`.sign()`, which adds the header-based
#' HMAC signature, encrypted passphrase, and `KC-API-*` headers) and how it
#' reports an error (`.parse_envelope()`, which honours KuCoin's `code`/`data`
#' envelope).
#'
#' Unlike most connectors, KuCoin signs the *exact compact JSON request body* and
#' must send that same byte sequence on the wire, so the request funnel is
#' KuCoin's own [kucoin_build_request()] (which signs and sends an identical
#' `req_body_raw` payload) rather than the connectcore default funnel; the two
#' overridable seams are driven through it.
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
#' - `"local"` (default): uses the local UTC clock.
#' - `"server"`: fetches the KuCoin server time via `GET /api/v1/timestamp`
#'   before each authenticated request. This is slower (one extra HTTP round
#'   trip) but ensures signing works even when the local clock is out of sync.
#'
#' ### Design
#' This class is not meant to be instantiated directly. Subclasses (e.g.,
#' [KucoinMarketData], [KucoinTrading]) inherit from it and define their
#' own public methods that delegate to `private$.request()` and `private$.paginate()`.
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
#' @export
KucoinBase <- R6::R6Class(
  "KucoinBase",
  inherit = connectcore::RestClient,
  public = list(
    #' @description
    #' Initialise a KucoinBase Object
    #'
    #' @param keys List; API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url Character; API base URL. Defaults to `get_base_url()`.
    #' @param async Logical; if `TRUE`, methods return promises. Default `FALSE`.
    #' @param time_source Character; clock source for HMAC request signing.
    #'   `"local"` (default) uses the local UTC clock. `"server"` fetches the
    #'   KuCoin server time before each authenticated request, which adds latency
    #'   but avoids clock-drift issues.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      if (isTRUE(async) && !requireNamespace("promises", quietly = TRUE)) {
        rlang::abort(
          "Package 'promises' is required for async mode. Install with: install.packages('promises')"
        )
      }
      super$initialize(
        keys = keys,
        base_url = base_url,
        async = async,
        time_source = match.arg(time_source),
        time_endpoint = "/api/v1/timestamp",
        time_field = "data",
        body_format = "none"
      )
      return(invisible(self))
    }
  ),
  private = list(
    # Authenticate a KuCoin request via the header-based HMAC scheme: KC-API-KEY /
    # KC-API-SIGN / KC-API-TIMESTAMP / KC-API-PASSPHRASE / KC-API-KEY-VERSION,
    # signing against the configured (local or server) clock exposed via
    # `ctx$get_timestamp_ms`. KuCoin signs the request method, path (with the
    # URL-encoded query string), and the raw body, so the seam receives them via
    # `ctx` and delegates to sign_request().
    .sign = function(req, keys, ctx) {
      return(sign_request(
        req,
        keys,
        method = ctx$method,
        path = ctx$path,
        body = ctx$body,
        .get_timestamp_ms = ctx$get_timestamp_ms
      ))
    },

    # Parse a KuCoin response, honouring its `code`/`data` envelope (a `code`
    # other than "200000" signals an API error even on a 200 HTTP status).
    .parse_envelope = function(resp) {
      return(parse_kucoin_response(resp))
    },

    # Execute a KuCoin API Request
    #
    # Routes through KuCoin's kucoin_build_request() funnel (which signs and
    # sends a byte-identical compact JSON body) rather than the connectcore
    # default funnel, injecting the instance's base URL, credentials, perform
    # function, and the .sign / .parse_envelope seams. Accepts a .parser callback
    # so subclass methods define their data transformation with no sync/async
    # awareness.
    .request = function(
      endpoint,
      method = "GET",
      query = list(),
      body = NULL,
      auth = TRUE,
      .parser = identity,
      timeout = 30,
      base_url = NULL
    ) {
      # `base_url = NULL` (the default) uses the instance's configured host
      # (spot for most classes, futures for the `KucoinFutures*` classes).
      # An explicit `base_url` overrides for the rare cross-host endpoint —
      # e.g. KuCoin's unified `/api/ua/v1/dcp/*` lives on the spot host but
      # is exposed to futures callers through `KucoinFuturesTrading`.
      effective_base <- private$.base_url
      if (!is.null(base_url)) {
        effective_base <- base_url
      }
      return(kucoin_build_request(
        base_url = effective_base,
        endpoint = endpoint,
        method = method,
        query = query,
        body = body,
        keys = if (auth) private$.keys else NULL,
        sign = private$.sign,
        parse_envelope = private$.parse_envelope,
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
    # configuration and the .sign / .parse_envelope seams. Accepts a .parser
    # callback for the final accumulated result.
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
        sign = private$.sign,
        parse_envelope = private$.parse_envelope,
        .perform = private$.perform,
        .parser = .parser,
        is_async = private$.is_async,
        page_size = page_size,
        max_pages = max_pages,
        items_field = items_field,
        .get_timestamp_ms = private$.get_timestamp_ms
      ))
    }
  )
)
