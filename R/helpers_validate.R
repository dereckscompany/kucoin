# File: R/helpers_validate.R
# Input validation helpers for order parameters and symbol formats.

#' Verify Ticker Symbol Format
#'
#' Checks whether a ticker symbol matches the `"BASE-QUOTE"` format
#' (e.g., `"BTC-USDT"`), consisting of alphanumeric characters separated
#' by a single dash.
#'
#' @param ticker Character string; the ticker symbol to verify.
#' @return Logical; `TRUE` if valid, `FALSE` otherwise.
#'
#' @examples
#' \dontrun{
#' verify_symbol("BTC-USDT")   # TRUE
#' verify_symbol("btc-usdt")   # TRUE (case-insensitive)
#' verify_symbol("BTC_USDT")   # FALSE
#' verify_symbol("BTCUSDT")    # FALSE
#' }
#' @export
verify_symbol <- function(ticker) {
  return(grepl("^[A-Za-z0-9]+-[A-Za-z0-9]+$", ticker))
}

#' Validate Order Parameters
#'
#' Validates and normalises parameters for a single order (limit or market).
#' Converts numeric price/size/funds to character strings as required by the
#' KuCoin API. Returns a clean named list ready for JSON serialisation.
#'
#' ### Validation Rules
#' - **Limit orders**: require `price` and `size`; `funds` not allowed.
#' - **Market orders**: require either `size` or `funds` (mutually exclusive);
#'   `price` not allowed.
#' - `timeInForce = "GTT"` requires `cancelAfter`.
#' - `postOnly` cannot be `TRUE` with IOC/FOK.
#' - `iceberg` and `hidden` cannot both be `TRUE`.
#'
#' @param type Character; `"limit"` or `"market"`.
#' @param symbol Character; trading pair (e.g., `"BTC-USDT"`).
#' @param side Character; `"buy"` or `"sell"`.
#' @param clientOid Character or NULL; client order ID (max 40 chars).
#' @param price Numeric or NULL; price for limit orders.
#' @param size Numeric or NULL; quantity.
#' @param funds Numeric or NULL; funds for market orders.
#' @param stp Character or NULL; self-trade prevention: `"CN"`, `"CO"`, `"CB"`, `"DC"`.
#' @param tags Character or NULL; order tag (max 20 ASCII chars).
#' @param remark Character or NULL; remarks (max 20 ASCII chars).
#' @param timeInForce Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.
#' @param cancelAfter Numeric or NULL; seconds until cancel (for GTT).
#' @param postOnly Logical or NULL; passive order flag.
#' @param hidden Logical or NULL; hidden order flag.
#' @param iceberg Logical or NULL; iceberg order flag.
#' @param visibleSize Numeric or NULL; visible quantity for iceberg.
#' @return Named list of validated order parameters (NULLs removed).
#'
#' @importFrom rlang abort arg_match0
#' @keywords internal
#' @noRd
validate_order_params <- function(
  type,
  symbol,
  side,
  clientOid = NULL,
  price = NULL,
  size = NULL,
  funds = NULL,
  stp = NULL,
  tags = NULL,
  remark = NULL,
  timeInForce = NULL,
  cancelAfter = NULL,
  postOnly = NULL,
  hidden = NULL,
  iceberg = NULL,
  visibleSize = NULL
) {
  # Required field validation
  type <- rlang::arg_match0(type, c("limit", "market"))
  side <- rlang::arg_match0(side, c("buy", "sell"))

  if (!verify_symbol(symbol)) {
    rlang::abort("Parameter 'symbol' must be a valid ticker (e.g., 'BTC-USDT').")
  }

  # Convert numerics to character for the API
  if (!is.null(price)) {
    price <- as.character(price)
  }
  if (!is.null(size)) {
    size <- as.character(size)
  }
  if (!is.null(funds)) {
    funds <- as.character(funds)
  }
  if (!is.null(visibleSize)) {
    visibleSize <- as.character(visibleSize)
  }

  # Type-specific validation
  if (type == "limit") {
    if (is.null(price)) {
      rlang::abort("Parameter 'price' is required for limit orders.")
    }
    if (is.null(size)) {
      rlang::abort("Parameter 'size' is required for limit orders.")
    }
    if (!is.null(funds)) rlang::abort("Parameter 'funds' is not applicable for limit orders.")
  } else if (type == "market") {
    if (!is.null(price)) {
      rlang::abort("Parameter 'price' is not applicable for market orders.")
    }
    if (is.null(size) && is.null(funds)) {
      rlang::abort("Either 'size' or 'funds' must be specified for market orders.")
    }
    if (!is.null(size) && !is.null(funds)) {
      rlang::abort("Parameters 'size' and 'funds' are mutually exclusive for market orders.")
    }
  }

  # Optional parameter validation
  if (!is.null(clientOid)) {
    if (!is.character(clientOid) || nchar(clientOid) > 40 || !grepl("^[a-zA-Z0-9_-]+$", clientOid)) {
      rlang::abort("Parameter 'clientOid' must be <= 40 chars, alphanumeric/underscore/hyphen.")
    }
  }

  if (!is.null(stp)) {
    stp <- rlang::arg_match0(stp, c("CN", "CO", "CB", "DC"))
  }

  if (!is.null(tags)) {
    if (!is.character(tags) || nchar(tags) > 20 || !all(charToRaw(tags) <= 127)) {
      rlang::abort("Parameter 'tags' must be ASCII and max 20 characters.")
    }
  }

  if (!is.null(remark)) {
    if (!is.character(remark) || nchar(remark) > 20 || !all(charToRaw(remark) <= 127)) {
      rlang::abort("Parameter 'remark' must be ASCII and max 20 characters.")
    }
  }

  if (!is.null(timeInForce)) {
    timeInForce <- rlang::arg_match0(timeInForce, c("GTC", "GTT", "IOC", "FOK"))
  }

  if (!is.null(cancelAfter)) {
    if (!is.numeric(cancelAfter) || cancelAfter <= 0) {
      rlang::abort("Parameter 'cancelAfter' must be a positive number.")
    }
    cancelAfter <- as.integer(cancelAfter)
  }

  if (!is.null(postOnly) && !is.logical(postOnly)) {
    rlang::abort("Parameter 'postOnly' must be logical.")
  }
  if (!is.null(hidden) && !is.logical(hidden)) {
    rlang::abort("Parameter 'hidden' must be logical.")
  }
  if (!is.null(iceberg) && !is.logical(iceberg)) {
    rlang::abort("Parameter 'iceberg' must be logical.")
  }

  if (!is.null(visibleSize) && !isTRUE(iceberg)) {
    rlang::abort("Parameter 'visibleSize' is only applicable when 'iceberg' is TRUE.")
  }

  # Cross-field validation
  if (identical(timeInForce, "GTT") && is.null(cancelAfter)) {
    rlang::abort("Parameter 'cancelAfter' is required when 'timeInForce' is 'GTT'.")
  }
  if (isTRUE(postOnly) && timeInForce %in% c("IOC", "FOK")) {
    rlang::abort("Parameter 'postOnly' cannot be TRUE when 'timeInForce' is 'IOC' or 'FOK'.")
  }
  if (isTRUE(iceberg) && isTRUE(hidden)) {
    rlang::abort("Parameters 'iceberg' and 'hidden' cannot both be TRUE.")
  }

  # Build the result list, dropping NULLs
  params <- list(
    type = type,
    symbol = symbol,
    side = side,
    clientOid = clientOid,
    price = price,
    size = size,
    funds = funds,
    stp = stp,
    tags = tags,
    remark = remark,
    timeInForce = timeInForce,
    cancelAfter = cancelAfter,
    postOnly = postOnly,
    hidden = hidden,
    iceberg = iceberg,
    visibleSize = visibleSize
  )
  params <- params[!vapply(params, is.null, logical(1))]

  return(params)
}

#' Validate a Single Order in a Batch
#'
#' Validates one order within a batch request by delegating to
#' `validate_order_params()`. Accepts a named list and extracts fields.
#'
#' @param order Named list; a single order's parameters.
#' @return Named list of validated order parameters.
#'
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
validate_batch_order <- function(order) {
  if (!is.list(order)) {
    rlang::abort("Each order in a batch must be a list.")
  }

  required <- c("symbol", "type", "side")
  missing <- setdiff(required, names(order))
  if (length(missing) > 0) {
    rlang::abort(paste0("Missing required field(s) in batch order: ", paste(missing, collapse = ", ")))
  }

  return(validate_order_params(
    type = order$type,
    symbol = order$symbol,
    side = order$side,
    clientOid = order$clientOid,
    price = order$price,
    size = order$size,
    funds = order$funds,
    stp = order$stp,
    tags = order$tags,
    remark = order$remark,
    timeInForce = order$timeInForce,
    cancelAfter = order$cancelAfter,
    postOnly = order$postOnly,
    hidden = order$hidden,
    iceberg = order$iceberg,
    visibleSize = order$visibleSize
  ))
}
