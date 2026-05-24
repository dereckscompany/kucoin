# File: R/helpers_request.R
# Core HTTP request infrastructure for the kucoin package.
# Provides sign_request(), kucoin_build_request(), and kucoin_paginate().

#' Apply Continuation to a Value or Promise
#'
#' Routes a value through `fn` either synchronously or asynchronously depending on
#' whether the caller is in async mode. This is the single sync/async branching
#' point in the package -- called only from `.request()` and `.paginate()`.
#'
#' @param x A value or a [promises::promise].
#' @param fn A function to apply to the resolved value of `x`.
#' @param is_async Logical; whether the caller is in async mode.
#' @return If `is_async`, returns `promises::then(x, fn)`. Otherwise returns `fn(x)`.
#' @keywords internal
#' @noRd
then_or_now <- function(x, fn, is_async = FALSE) {
  if (is_async) {
    return(promises::then(x, fn))
  }
  return(fn(x))
}

#' Fetch KuCoin Server Time (Milliseconds)
#'
#' Makes a lightweight synchronous `GET /api/v1/timestamp` request and returns
#' the server's epoch time in milliseconds. Used internally when
#' `time_source = "server"` to avoid clock-drift issues with HMAC signing.
#'
#' @param base_url Character; the API base URL.
#' @return Numeric; server time in epoch milliseconds.
#' @keywords internal
#' @noRd
fetch_server_time_ms <- function(base_url) {
  req <- httr2::request(base_url)
  req <- httr2::req_url_path_append(req, "/api/v1/timestamp")
  req <- httr2::req_method(req, "GET")
  req <- httr2::req_timeout(req, 5)
  resp <- httr2::req_perform(req)
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  if (as.character(parsed$code) != "200000") {
    rlang::abort(paste0(
      "Failed to fetch server time: KuCoin API error ",
      parsed$code,
      ": ",
      if (is.null(parsed$msg)) "No message." else parsed$msg
    ))
  }
  return(as.numeric(parsed$data))
}

#' Sign an httr2 Request for KuCoin Authentication
#'
#' Adds KuCoin authentication headers (KC-API-KEY, KC-API-SIGN, KC-API-TIMESTAMP,
#' KC-API-PASSPHRASE, KC-API-KEY-VERSION) to an [httr2::request] object.
#'
#' @param req An [httr2::request] object to sign.
#' @param keys List of API credentials containing `api_key`, `api_secret`,
#'   `api_passphrase`, and `key_version`.
#' @param method Character; HTTP method (e.g., `"GET"`, `"POST"`, `"DELETE"`).
#' @param path Character; the API path including query string.
#' @param body Character; the JSON request body, or `""` for GET/DELETE requests.
#' @param .get_timestamp_ms Function or NULL; zero-argument function returning
#'   epoch milliseconds. When `NULL` (default), falls back to `lubridate::now()`.
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
    .get_timestamp_ms <- function() floor(as.numeric(lubridate::now()) * 1000)
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

#' Build and Execute a KuCoin API Request
#'
#' Constructs an [httr2::request], optionally signs it, performs it via the supplied
#' `.perform` function, and parses the KuCoin JSON response. This is the single
#' point through which all KuCoin API calls flow.
#'
#' ### Sync vs Async
#' The `.perform` argument controls execution mode:
#' - `httr2::req_perform` (default): synchronous, returns an [httr2::response].
#' - `httr2::req_perform_promise`: asynchronous, returns a [promises::promise].
#'
#' @param base_url Character; the API base URL.
#' @param endpoint Character; the API path.
#' @param method Character; HTTP method. Default `"GET"`.
#' @param query Named list; query parameters. Default `list()`.
#' @param body Named list or NULL; request body. Default `NULL`.
#' @param keys List or NULL; API credentials. Default `NULL`.
#' @param .perform Function; the httr2 perform function. Default `httr2::req_perform`.
#' @param .parser Function; post-processing function applied to parsed `$data`.
#'   Default `identity`.
#' @param is_async Logical; whether `.perform` returns promises. Default `FALSE`.
#' @param timeout Numeric; request timeout in seconds. Default `10`.
#' @param .get_timestamp_ms Function or NULL; zero-argument function returning
#'   epoch milliseconds for HMAC signing. When `NULL` (default), uses
#'   `lubridate::now()`. Pass a custom function (e.g. one that fetches KuCoin server
#'   time) to avoid clock-drift issues.
#' @return Parsed and post-processed API response data, or a promise thereof.
#'
#' @importFrom httr2 request req_method req_url_path_append req_url_query req_body_raw
#'   req_timeout req_perform url_parse
#' @importFrom jsonlite toJSON
#' @export
kucoin_build_request <- function(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  timeout = 10,
  .get_timestamp_ms = NULL
) {
  req <- httr2::request(base_url)
  req <- httr2::req_url_path_append(req, endpoint)
  req <- httr2::req_method(req, method)
  req <- httr2::req_timeout(req, timeout)

  # Add query parameters (drop NULLs)
  query <- query[!vapply(query, is.null, logical(1))]
  if (length(query) > 0) {
    req <- httr2::req_url_query(req, !!!query)
  }

  # Build JSON body
  body_json <- ""
  if (!is.null(body)) {
    body_json <- jsonlite::toJSON(body, auto_unbox = TRUE)
    req <- httr2::req_body_raw(req, body_json, type = "application/json")
  }

  # Sign if authenticated
  if (!is.null(keys)) {
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

    req <- sign_request(req, keys, method, sign_path, body_json, .get_timestamp_ms = .get_timestamp_ms)
  }

  result <- .perform(req)

  # Single branching point: parse response then apply .parser
  return(then_or_now(
    result,
    function(resp) {
      data <- parse_kucoin_response(resp)
      return(.parser(data))
    },
    is_async = is_async
  ))
}

#' Parse and Validate a KuCoin API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status and KuCoin
#' API status code (`"200000"`), and returns the `$data` element.
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
#' @export
kucoin_paginate <- function(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  page_size = 50,
  max_pages = Inf,
  items_field = "items",
  timeout = 30,
  .get_timestamp_ms = NULL
) {
  accumulator <- list()

  fetch_page <- function(page) {
    q <- query
    q$currentPage <- page
    q$pageSize <- page_size

    result <- kucoin_build_request(
      base_url = base_url,
      endpoint = endpoint,
      method = method,
      query = q,
      body = body,
      keys = keys,
      .perform = .perform,
      is_async = is_async,
      timeout = timeout,
      .get_timestamp_ms = .get_timestamp_ms
    )

    return(then_or_now(
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
