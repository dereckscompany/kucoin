# File: R/helpers_request.R
# Core HTTP request infrastructure for the kucoin package.
# Provides sign_request(), kucoin_sign_req(), parse_kucoin_response(), and
# kucoin_paginate().
#
# KuCoin owns NO transport funnel: every request flows through
# connectcore::build_request (the shared transport base). The body-signing twist
# — KuCoin signs the *exact compact JSON body* and must send that same byte
# sequence on the wire — is handled by routing the pre-serialised compact JSON
# through connectcore's `body_format = "raw"` path (byte-verbatim, no
# NULL-pruning, no pretty-printing) and reading those exact bytes back off the
# request inside the `.sign` seam (kucoin_sign_req).

#' Sign an httr2 Request for KuCoin Authentication
#'
#' Adds KuCoin authentication headers (KC-API-KEY, KC-API-SIGN, KC-API-TIMESTAMP,
#' KC-API-PASSPHRASE, KC-API-KEY-VERSION) to an [httr2::request] object. This is
#' the header-based HMAC scheme KuCoin uses (it signs the timestamp, HTTP method,
#' request path including the URL-encoded query string, and the raw body), so it
#' cannot use [connectcore::hmac_query_sign()], which signs only the query string.
#' It is the `.sign()` seam [KucoinBase] plugs into [connectcore::RestClient].
#'
#' @param req (class<httr2_request>) the request object to sign.
#' @param keys (list) API credentials from [get_api_keys()]:
#' - api_key (character) the API key.
#' - api_secret (character) the API secret.
#' - api_passphrase (character) the API passphrase.
#' - key_version (character) the API key version.
#' @param method (scalar<character>) HTTP method (e.g., `"GET"`, `"POST"`,
#'   `"DELETE"`).
#' @param path (scalar<character>) the API path including query string.
#' @param body (scalar<character>) the JSON request body, or `""` for
#'   GET/DELETE requests.
#' @param .get_timestamp_ms (function | NULL) zero-argument function returning
#'   epoch milliseconds. When `NULL` (default), falls back to the local UTC
#'   clock.
#' @return (class<httr2_request>) the signed request with authentication
#'   headers added.
#'
#' @importFrom digest hmac
#' @importFrom base64enc base64encode
#' @importFrom httr2 req_headers
#' @keywords internal
#' @noRd
sign_request <- function(req, keys, method, path, body = "", .get_timestamp_ms = NULL) {
  assert_args_sign_request(req, keys, method, path, body, .get_timestamp_ms)
  # NOTE: epoch milliseconds exceed R's integer max (2^31-1 ~= 2.1e9) so we
  # must use floor() + format() to get a clean integer string without
  # overflow, decimals, or scientific notation.
  if (is.null(.get_timestamp_ms)) {
    .get_timestamp_ms <- function() floor(as.numeric(lubridate::now("UTC")) * 1000)
  }
  timestamp <- format(.get_timestamp_ms(), scientific = FALSE)
  prehash <- paste0(timestamp, toupper(method), path, body)

  sig_raw <- digest::hmac(
    key = keys$api_secret,
    object = prehash,
    algo = "sha256",
    serialize = FALSE,
    raw = TRUE
  )
  signature <- base64enc::base64encode(sig_raw)

  passphrase_raw <- digest::hmac(
    key = keys$api_secret,
    object = keys$api_passphrase,
    algo = "sha256",
    serialize = FALSE,
    raw = TRUE
  )
  encrypted_passphrase <- base64enc::base64encode(passphrase_raw)

  req <- httr2::req_headers(
    req,
    `KC-API-KEY` = keys$api_key,
    `KC-API-SIGN` = signature,
    `KC-API-TIMESTAMP` = timestamp,
    `KC-API-PASSPHRASE` = encrypted_passphrase,
    `KC-API-KEY-VERSION` = keys$key_version,
    `Content-Type` = "application/json"
  )

  return(assert_return_sign_request(req))
}

#' Serialise a KuCoin Request Body to Compact JSON
#'
#' Turns a named list body into the exact compact JSON string KuCoin both signs
#' and sends on the wire. Returns `NULL` for an empty body so the caller can omit
#' the body entirely (the `.sign` seam then signs against an empty body string).
#'
#' Pre-serialising here — and routing the result through connectcore's
#' `body_format = "raw"` path — is what keeps the signed bytes and the wire bytes
#' identical: no NULL-pruning, no pretty-printing, no re-encoding.
#'
#' @param body (list | NULL) the request body.
#' @return (scalar<character> | NULL) compact JSON, or NULL when `body` is
#'   empty.
#'
#' @importFrom jsonlite toJSON
#' @keywords internal
#' @noRd
kucoin_serialize_body <- function(body) {
  assert_args_kucoin_serialize_body(body)
  if (is.null(body) || length(body) == 0L) {
    return(assert_return_kucoin_serialize_body(NULL))
  }
  return(assert_return_kucoin_serialize_body(as.character(jsonlite::toJSON(body, auto_unbox = TRUE))))
}

#' KuCoin `.sign` Seam: Sign a Built Request from Its Own Bytes
#'
#' The `function(req, keys, ctx)` seam connectcore's `build_request` invokes after
#' the request (URL, method, query, raw body) is fully built. KuCoin signs the
#' HTTP method, the path *including its URL-encoded query string*, and the *exact
#' body bytes*, so this reads all three straight off `req` — the body is whatever
#' `body_format = "raw"` placed in `req$body$data`, byte-for-byte — and delegates
#' to `sign_request()`.
#'
#' @param req (class<httr2_request>) the request object, already built by
#'   connectcore.
#' @param keys (list) API credentials from [get_api_keys()]:
#' - api_key (character) the API key.
#' - api_secret (character) the API secret.
#' - api_passphrase (character) the API passphrase.
#' - key_version (character) the API key version.
#' @param ctx (list) the signing context. Only `ctx$get_timestamp_ms` is used
#'   (the clock source); method, path, and body are derived from `req`.
#' @return (class<httr2_request>) the signed request.
#'
#' @importFrom httr2 url_parse
#' @keywords internal
#' @noRd
kucoin_sign_req <- function(req, keys, ctx) {
  assert_args_kucoin_sign_req(req, keys, ctx)
  method <- if (is.null(req$method)) "GET" else req$method

  parsed_url <- httr2::url_parse(req$url)
  sign_path <- parsed_url$path
  if (length(parsed_url$query) > 0) {
    encoded_vals <- vapply(
      parsed_url$query,
      function(v) {
        return(utils::URLencode(as.character(v), reserved = TRUE))
      },
      character(1)
    )
    qs <- paste0(names(parsed_url$query), "=", encoded_vals, collapse = "&")
    sign_path <- paste0(sign_path, "?", qs)
  }

  # The raw body bytes connectcore set via req_body_raw; "" when there is none.
  body <- if (is.null(req$body)) "" else as.character(req$body$data)

  return(assert_return_kucoin_sign_req(sign_request(
    req,
    keys,
    method = method,
    path = sign_path,
    body = body,
    .get_timestamp_ms = ctx$get_timestamp_ms
  )))
}

#' Parse and Validate a KuCoin API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status and KuCoin
#' API status code (`"200000"`), and returns the `$data` element. This is the
#' `.parse_envelope()` seam [KucoinBase] plugs into [connectcore::RestClient].
#'
#' @param resp (class<httr2_response>) the response object.
#' @return (any | NULL) the `$data` element from the parsed JSON response (its R
#'   type varies by endpoint: a list, a scalar, or NULL).
#'
#' @importFrom httr2 resp_status resp_body_json resp_body_string
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
parse_kucoin_response <- function(resp) {
  assert_args_parse_kucoin_response(resp)
  status <- httr2::resp_status(resp)
  if (status != 200L) {
    body_text <- tryCatch(
      httr2::resp_body_string(resp),
      error = function(e) "<unable to read body>"
    )
    abort_kucoin_error(
      status = status,
      url = resp$url,
      body = body_text,
      message = paste0("KuCoin HTTP error ", status, "\n", body_text)
    )
  }

  # NOTE: simplifyVector must be FALSE to preserve JSON structure faithfully.
  # When TRUE, jsonlite coerces arrays-of-arrays (e.g. orderbook bids/asks,
  # klines) into matrices, breaking downstream vapply-based parsers.
  # See research/json_matrix_behavior.R for details.
  #
  # check_type = FALSE: KuCoin's futures `GET /api/v1/status` returns a JSON
  # body with a `text/plain` Content-Type (observed live 2026-06), which makes
  # the default content-type guard in `resp_body_json()` abort before parsing.
  # The body is still valid JSON, so we parse it regardless of the declared
  # type. Synthetic mock fixtures (served as `application/json`) hid this.
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE, check_type = FALSE)
  body_text <- tryCatch(httr2::resp_body_string(resp), error = function(e) NULL)

  if (is.null(parsed$code)) {
    # A parsed-but-malformed body (no `code` field) is connectcore's response
    # error surface, not an API error — raise it directly so it nests under
    # connectcore_response_error / connectcore_error.
    connectcore::abort_response_error(
      message = "Invalid KuCoin API response: missing 'code' field.",
      field = "code",
      url = resp$url,
      body = body_text
    )
  }
  if (as.character(parsed$code) != "200000") {
    abort_kucoin_error(
      status = status,
      code = parsed$code,
      msg = parsed$msg,
      url = resp$url,
      body = body_text
    )
  }

  return(assert_return_parse_kucoin_response(parsed$data))
}

#' Paginate a KuCoin API Endpoint
#'
#' Iteratively fetches pages from a paginated KuCoin endpoint. Aggregates
#' the items from each page into a list.
#'
#' @param base_url (scalar<character>) the API base URL.
#' @param endpoint (scalar<character>) the API path.
#' @param method (scalar<character>) HTTP method. Default `"GET"`.
#' @param query (list) initial query parameters. Default `list()`.
#' @param body (list | NULL) request body. Default `NULL`.
#' @param keys (list | NULL) API credentials from [get_api_keys()], or `NULL`:
#' - api_key (character) the API key.
#' - api_secret (character) the API secret.
#' - api_passphrase (character) the API passphrase.
#' - key_version (character) the API key version.
#' @param sign (function | NULL) the `.sign()` seam forwarded to
#'   [connectcore::build_request()]. Default `NULL` (use KuCoin's own
#'   `kucoin_sign_req()` signer).
#' @param parse_envelope (function) the `.parse_envelope()` seam forwarded to
#'   [connectcore::build_request()]. Default `parse_kucoin_response()`.
#' @param .perform (function) the httr2 perform function.
#' @param .parser (function) post-processing for the final accumulated result.
#'   Default `identity`.
#' @param is_async (scalar<logical>) whether in async mode. Default `FALSE`.
#' @param page_size (scalar<count in [1, Inf]>) results per page. Default `50`.
#' @param max_pages (scalar<numeric in [1, Inf]>) maximum pages to fetch.
#'   Default `Inf`.
#' @param items_field (scalar<character>) name of the items field. Default
#'   `"items"`.
#' @param timeout (scalar<numeric in ]0, Inf[>) request timeout in seconds.
#'   Default `30`.
#' @param .get_timestamp_ms (function | NULL) custom timestamp provider for
#'   request signing. If `NULL`, uses the default internal timestamp function.
#' @return (any | promise<any>) parsed and post-processed result, or a promise
#'   thereof.
#'
#' @importFrom jsonlite toJSON
#' @export
kucoin_paginate <- function(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  sign = NULL,
  parse_envelope = parse_kucoin_response,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  page_size = 50,
  max_pages = Inf,
  items_field = "items",
  timeout = 30,
  .get_timestamp_ms = NULL
) {
  assert_args_kucoin_paginate(
    base_url,
    endpoint,
    method,
    query,
    body,
    keys,
    sign,
    parse_envelope,
    .perform,
    .parser,
    is_async,
    page_size,
    max_pages,
    items_field,
    timeout,
    .get_timestamp_ms
  )
  # KuCoin owns no funnel: every page flows through connectcore::build_request.
  # The body (rare for paginated endpoints) is pre-serialised to compact JSON and
  # sent byte-verbatim via body_format = "raw"; the KuCoin signer reads those
  # exact bytes back off the request. With no body, body_format = "none".
  if (is.null(sign)) {
    sign <- kucoin_sign_req
  }
  body_json <- kucoin_serialize_body(body)
  body_format <- if (is.null(body_json)) "none" else "raw"

  accumulator <- list()

  # Issue one page request. Returns the parsed page data in sync mode, or a
  # promise resolving to it in async mode. Both walk paths below build the
  # request identically through this seam, so the two modes stay bit-identical.
  request_page <- function(page) {
    q <- query
    q$currentPage <- page
    q$pageSize <- page_size

    return(connectcore::build_request(
      base_url = base_url,
      endpoint = endpoint,
      method = method,
      query = q,
      body = body_json,
      keys = keys,
      sign = sign,
      parse_envelope = parse_envelope,
      body_format = body_format,
      .perform = .perform,
      is_async = is_async,
      timeout = timeout,
      ctx = list(get_timestamp_ms = .get_timestamp_ms)
    ))
  }

  # Fold one page's items into the accumulator and report its `totalPage`
  # (defaulting to 1 when the field is absent, exactly as before). Shared by
  # both walk paths so ordering and stop conditions are identical.
  absorb_page <- function(data) {
    page_items <- data[[items_field]]
    if (!is.null(page_items)) {
      accumulator[[length(accumulator) + 1L]] <<- page_items
    }

    total <- 1L
    if (!is.null(data$totalPage)) {
      total <- data$totalPage
    }

    return(total)
  }

  # Sync and async walk the same pages with the same stop condition; only the
  # control structure differs, because each mode has a different stack model.
  result <- NULL
  if (is_async) {
    # Async: promise-based recursion. `promises::then()` schedules each
    # continuation as a fresh event-loop task, so the call stack unwinds between
    # pages (the recursion is trampolined by the event loop and does not grow
    # the stack with page count). Left as recursion deliberately.
    fetch_page <- function(page) {
      return(connectcore::then_or_now(
        request_page(page),
        function(data) {
          total <- absorb_page(data)
          if (page < total && page < max_pages) {
            return(fetch_page(page + 1L))
          }
          return(.parser(accumulator))
        },
        is_async = TRUE
      ))
    }
    result <- fetch_page(1L)
  } else {
    # Sync: iterative while-loop. R has no tail-call optimisation and runs the
    # continuation inline, so expressing the walk as self-recursion nested
    # `fetch_page -> then_or_now -> continuation -> fetch_page` and overflowed
    # the stack on a deep walk (thousands of pages). The loop runs in constant
    # stack depth while preserving the exact page ordering.
    page <- 1L
    walking <- TRUE
    while (walking) {
      total <- absorb_page(request_page(page))
      if (page < total && page < max_pages) {
        page <- page + 1L
      } else {
        walking <- FALSE
      }
    }
    result <- .parser(accumulator)
  }

  return(assert_return_kucoin_paginate(result))
}
