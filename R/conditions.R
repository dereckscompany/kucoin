# File: R/conditions.R
# KuCoin's typed API-error condition. KuCoin has three failure surfaces, all
# funnelled through `parse_kucoin_response()`: a non-2xx HTTP status; a venue
# error signalled by a `code` other than "200000" in the JSON body (KuCoin
# returns HTTP 200 with the error carried in the body); and a malformed body
# missing its `code` field. The first two are API errors — `abort_kucoin_error()`
# layers KuCoin's own class family IN FRONT of connectcore's, per the recipe in
# `?connectcore_conditions`. The third is a parsed-but-malformed body, which is
# exactly connectcore's response-error surface, so it uses
# [connectcore::abort_response_error()] directly.
#
# The per-status class is keyed on the HTTP status (200 on the venue-code path,
# since KuCoin signals venue errors on a 200); the KuCoin `code` rides along as a
# structured field. A caller can then catch `kucoin_api_error` (any KuCoin API
# failure), `connectcore_api_error` (any HTTP failure fleet-wide), or
# `connectcore_error` (any transport failure, including the malformed-body case)
# — reading `e$status` / `e$code` / `e$url` / `e$body_snippet` instead of grepping
# the message text.
#
# Backward compatibility is a hard contract: the message strings are
# byte-identical to the bare `rlang::abort()` calls this replaced — "KuCoin API
# error <code>: <msg>" for the venue-code surface and "KuCoin HTTP error
# <status>\n<body>" for the HTTP surface. The classes and fields are purely
# additive.

#' Raise a typed KuCoin API error
#'
#' Signals a condition classed
#' `c("kucoin_api_error_<status>", "kucoin_api_error",`
#' `"connectcore_api_error_<status>", "connectcore_api_error",`
#' `"connectcore_error")` (on top of rlang's error classes), carrying the HTTP
#' `status`, the venue error `code` (a non-`"200000"` KuCoin code on failure;
#' `NULL` for a plain HTTP failure), the request `url` (query-string credentials
#' redacted with [connectcore::scrub_url()]), and the response `body_snippet` as
#' structured fields. With `message = NULL` the message defaults to the
#' byte-identical venue-code string `"KuCoin API error <code>: <msg>"`; the
#' HTTP-status funnel passes its own byte-identical `"KuCoin HTTP error
#' <status>\n<body>"` string as `message`. See
#' [connectcore::connectcore_conditions] for the taxonomy and the subclass recipe.
#'
#' @param status (scalar<count in [100, 599]>) the HTTP status code. Also names
#'   the most specific classes, `kucoin_api_error_<status>` and
#'   `connectcore_api_error_<status>`.
#' @param code (scalar<character> | NULL) the KuCoin venue error code (a string
#'   such as `"400100"`), stored on the `code` field. `NULL` for a plain HTTP
#'   failure. Default `NULL`.
#' @param msg (scalar<character> | NULL) the venue error message; rendered into
#'   the default message after the code. `NULL` renders
#'   `"No error message provided."`. Default `NULL`.
#' @param url (scalar<character> | NULL) the request URL; query-string credentials
#'   are redacted with [connectcore::scrub_url()] before storing on the `url`
#'   field. Default `NULL`.
#' @param body (scalar<character> | NULL) the response body text; stored on the
#'   `body_snippet` field (named `body_snippet`, not `body`, because
#'   `rlang::abort()` reserves `body`). Default `NULL`.
#' @param message (scalar<character> | NULL) the condition message. `NULL`
#'   (default) derives the byte-identical venue-code string from `code` and `msg`;
#'   the HTTP funnel supplies its own string here.
#' @return (class<connectcore_error>) never returns normally; signals the classed
#'   condition described above.
#'
#' @importFrom rlang abort caller_env
#' @keywords internal
#' @noassert
#' @noRd
abort_kucoin_error <- function(status, code = NULL, msg = NULL, url = NULL, body = NULL, message = NULL) {
  if (is.null(message)) {
    resolved_msg <- if (is.null(msg)) "No error message provided." else msg
    message <- paste0("KuCoin API error ", code, ": ", resolved_msg)
  }
  return(rlang::abort(
    message = message,
    class = c(
      sprintf("kucoin_api_error_%d", as.integer(status)),
      "kucoin_api_error",
      sprintf("connectcore_api_error_%d", as.integer(status)),
      "connectcore_api_error",
      "connectcore_error"
    ),
    status = as.integer(status),
    code = code,
    url = connectcore::scrub_url(url),
    body_snippet = body,
    call = rlang::caller_env()
  ))
}
