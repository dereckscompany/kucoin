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
#' @param req An [httr2::request] object to sign.
#' @param keys List of API credentials containing `api_key`, `api_secret`,
#'   `api_passphrase`, and `key_version`.
#' @param method Character; HTTP method (e.g., `"GET"`, `"POST"`, `"DELETE"`).
#' @param path Character; the API path including query string.
#' @param body Character; the JSON request body, or `""` for GET/DELETE requests.
#' @param .get_timestamp_ms Function or NULL; zero-argument function returning
#'   epoch milliseconds. When `NULL` (default), falls back to the local UTC clock.
#' @return The signed [httr2::request] object with authentication headers added.
#'
#' @importFrom digest hmac
#' @importFrom base64enc base64encode
#' @importFrom httr2 req_headers
#' @keywords internal
#' @noRd
sign_request <- function(req, keys, method, path, body = "", .get_timestamp_ms = NULL) {
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

  return(req)
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
#' @param body Named list or NULL; the request body.
#' @return Character scalar of compact JSON, or NULL when `body` is empty.
#'
#' @importFrom jsonlite toJSON
#' @keywords internal
#' @noRd
kucoin_serialize_body <- function(body) {
  if (is.null(body) || length(body) == 0L) {
    return(NULL)
  }
  return(as.character(jsonlite::toJSON(body, auto_unbox = TRUE)))
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
#' @param req An [httr2::request] object, already built by connectcore.
#' @param keys List; API credentials (`api_key`, `api_secret`, `api_passphrase`,
#'   `key_version`).
#' @param ctx List; the signing context. Only `ctx$get_timestamp_ms` is used (the
#'   clock source); method, path, and body are derived from `req`.
#' @return The signed [httr2::request] object.
#'
#' @importFrom httr2 url_parse
#' @keywords internal
#' @noRd
kucoin_sign_req <- function(req, keys, ctx) {
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

  return(sign_request(
    req,
    keys,
    method = method,
    path = sign_path,
    body = body,
    .get_timestamp_ms = ctx$get_timestamp_ms
  ))
}

#' Parse and Validate a KuCoin API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status and KuCoin
#' API status code (`"200000"`), and returns the `$data` element. This is the
#' `.parse_envelope()` seam [KucoinBase] plugs into [connectcore::RestClient].
#'
#' @param resp An [httr2::response] object.
#' @return The `$data` element from the parsed JSON response.
#'
#' @importFrom httr2 resp_status resp_body_json resp_body_string
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
parse_kucoin_response <- function(resp) {
  status <- httr2::resp_status(resp)
  if (status != 200L) {
    body_text <- tryCatch(
      httr2::resp_body_string(resp),
      error = function(e) "<unable to read body>"
    )
    rlang::abort(paste0("KuCoin HTTP error ", status, "\n", body_text))
  }

  # NOTE: simplifyVector must be FALSE to preserve JSON structure faithfully.
  # When TRUE, jsonlite coerces arrays-of-arrays (e.g. orderbook bids/asks,
  # klines) into matrices, breaking downstream vapply-based parsers.
  # See research/json_matrix_behavior.R for details.
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  if (is.null(parsed$code)) {
    rlang::abort("Invalid KuCoin API response: missing 'code' field.")
  }
  if (as.character(parsed$code) != "200000") {
    rlang::abort(paste0(
      "KuCoin API error ",
      parsed$code,
      ": ",
      if (is.null(parsed$msg)) "No error message provided." else parsed$msg
    ))
  }

  return(parsed$data)
}

#' Paginate a KuCoin API Endpoint
#'
#' Iteratively fetches pages from a paginated KuCoin endpoint. Aggregates
#' the items from each page into a list.
#'
#' @param base_url Character; the API base URL.
#' @param endpoint Character; the API path.
#' @param method Character; HTTP method. Default `"GET"`.
#' @param query Named list; initial query parameters. Default `list()`.
#' @param body Named list or NULL; request body. Default `NULL`.
#' @param keys List or NULL; API credentials. Default `NULL`.
#' @param sign Function or NULL; the `.sign()` seam forwarded to
#'   [connectcore::build_request()]. Default `NULL` (use KuCoin's own
#'   `kucoin_sign_req()` signer).
#' @param parse_envelope Function; the `.parse_envelope()` seam forwarded to
#'   [connectcore::build_request()]. Default `parse_kucoin_response()`.
#' @param .perform Function; the httr2 perform function.
#' @param .parser Function; post-processing for the final accumulated result.
#'   Default `identity`.
#' @param is_async Logical; whether in async mode. Default `FALSE`.
#' @param page_size Integer; results per page. Default `50`.
#' @param max_pages Numeric; maximum pages to fetch. Default `Inf`.
#' @param items_field Character; name of the items field. Default `"items"`.
#' @param timeout Numeric; request timeout in seconds. Default `30`.
#' @param .get_timestamp_ms Function or NULL; custom timestamp provider for
#'   request signing. If `NULL`, uses the default internal timestamp function.
#' @return Parsed and post-processed result, or a promise thereof.
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

  fetch_page <- function(page) {
    q <- query
    q$currentPage <- page
    q$pageSize <- page_size

    result <- connectcore::build_request(
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
    )

    return(connectcore::then_or_now(
      result,
      function(data) {
        page_items <- data[[items_field]]
        if (!is.null(page_items)) {
          accumulator[[length(accumulator) + 1L]] <<- page_items
        }

        total <- 1L
        if (!is.null(data$totalPage)) {
          total <- data$totalPage
        }

        if (page < total && page < max_pages) {
          return(fetch_page(page + 1L))
        }

        return(.parser(accumulator))
      },
      is_async = is_async
    ))
  }

  return(fetch_page(1L))
}
