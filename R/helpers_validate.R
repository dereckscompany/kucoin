# File: R/helpers_validate.R
# Input validation helpers for order parameters and symbol formats.

#' Verify Ticker Symbol Format
#'
#' Checks whether a ticker symbol matches the `"BASE-QUOTE"` format
#' (e.g., `"BTC-USDT"`), consisting of alphanumeric characters separated
#' by a single dash.
#'
#' @param ticker (scalar<character>) the ticker symbol to verify.
#' @return (scalar<logical>) `TRUE` if valid, `FALSE` otherwise.
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
  assert_args_verify_symbol(ticker)
  return(assert_return_verify_symbol(grepl("^[A-Za-z0-9]+-[A-Za-z0-9]+$", ticker)))
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
#' @param type (scalar<character in c("limit", "market")>) the order type.
#' @param symbol (scalar<character>) trading pair (e.g., `"BTC-USDT"`).
#' @param side (scalar<character in c("buy", "sell")>) the order side.
#' @param client_order_id (scalar<character> | NULL) client order ID (max 40 chars).
#' @param price (scalar<numeric> | scalar<character> | NULL) price for limit
#'   orders.
#' @param size (scalar<numeric> | scalar<character> | NULL) quantity.
#' @param funds (scalar<numeric> | scalar<character> | NULL) funds for market
#'   orders.
#' @param stp (scalar<character> | NULL) self-trade prevention: `"CN"`, `"CO"`,
#'   `"CB"`, `"DC"`.
#' @param tags (scalar<character> | NULL) order tag (max 20 ASCII chars).
#' @param remark (scalar<character> | NULL) remarks (max 20 ASCII chars).
#' @param time_in_force (scalar<character> | NULL) `"GTC"`, `"GTT"`, `"IOC"`,
#'   `"FOK"`.
#' @param cancel_after (scalar<numeric> | NULL) seconds until cancel (for GTT).
#' @param post_only (scalar<logical> | NULL) passive order flag.
#' @param hidden (scalar<logical> | NULL) hidden order flag.
#' @param iceberg (scalar<logical> | NULL) iceberg order flag.
#' @param visible_size (scalar<numeric> | scalar<character> | NULL) visible
#'   quantity for iceberg.
#' @return (list) named list of validated order parameters (NULLs removed).
#'
#' @importFrom rlang abort arg_match0
#' @keywords internal
#' @noRd
validate_order_params <- function(
  type,
  symbol,
  side,
  client_order_id = NULL,
  price = NULL,
  size = NULL,
  funds = NULL,
  stp = NULL,
  tags = NULL,
  remark = NULL,
  time_in_force = NULL,
  cancel_after = NULL,
  post_only = NULL,
  hidden = NULL,
  iceberg = NULL,
  visible_size = NULL
) {
  assert_args_validate_order_params(
    type,
    symbol,
    side,
    client_order_id,
    price,
    size,
    funds,
    stp,
    tags,
    remark,
    time_in_force,
    cancel_after,
    post_only,
    hidden,
    iceberg,
    visible_size
  )
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
  if (!is.null(visible_size)) {
    visible_size <- as.character(visible_size)
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
  if (!is.null(client_order_id)) {
    if (!is.character(client_order_id) || nchar(client_order_id) > 40 || !grepl("^[a-zA-Z0-9_-]+$", client_order_id)) {
      rlang::abort("Parameter 'client_order_id' must be <= 40 chars, alphanumeric/underscore/hyphen.")
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

  if (!is.null(time_in_force)) {
    time_in_force <- rlang::arg_match0(time_in_force, c("GTC", "GTT", "IOC", "FOK"))
  }

  if (!is.null(cancel_after)) {
    if (!is.numeric(cancel_after) || cancel_after <= 0) {
      rlang::abort("Parameter 'cancel_after' must be a positive number.")
    }
    cancel_after <- as.integer(cancel_after)
  }

  if (!is.null(post_only) && !is.logical(post_only)) {
    rlang::abort("Parameter 'post_only' must be logical.")
  }
  if (!is.null(hidden) && !is.logical(hidden)) {
    rlang::abort("Parameter 'hidden' must be logical.")
  }
  if (!is.null(iceberg) && !is.logical(iceberg)) {
    rlang::abort("Parameter 'iceberg' must be logical.")
  }

  if (!is.null(visible_size) && !isTRUE(iceberg)) {
    rlang::abort("Parameter 'visible_size' is only applicable when 'iceberg' is TRUE.")
  }

  # Cross-field validation
  if (identical(time_in_force, "GTT") && is.null(cancel_after)) {
    rlang::abort("Parameter 'cancel_after' is required when 'time_in_force' is 'GTT'.")
  }
  if (isTRUE(post_only) && time_in_force %in% c("IOC", "FOK")) {
    rlang::abort("Parameter 'post_only' cannot be TRUE when 'time_in_force' is 'IOC' or 'FOK'.")
  }
  if (isTRUE(iceberg) && isTRUE(hidden)) {
    rlang::abort("Parameters 'iceberg' and 'hidden' cannot both be TRUE.")
  }

  # Build the result list, dropping NULLs
  params <- list(
    type = type,
    symbol = symbol,
    side = side,
    clientOid = client_order_id,
    price = price,
    size = size,
    funds = funds,
    stp = stp,
    tags = tags,
    remark = remark,
    timeInForce = time_in_force,
    cancelAfter = cancel_after,
    postOnly = post_only,
    hidden = hidden,
    iceberg = iceberg,
    visibleSize = visible_size
  )
  params <- params[!vapply(params, is.null, logical(1))]

  return(assert_return_validate_order_params(params))
}

#' Validate Margin Order Parameters
#'
#' Validates and normalises parameters for a margin order. Extends spot order
#' validation with margin-specific fields (`isIsolated`, `autoBorrow`,
#' `autoRepay`). Delegates core order validation to `validate_order_params()`.
#'
#' @inheritParams validate_order_params
#' @param is_isolated (scalar<logical> | NULL) `TRUE` for isolated margin,
#'   `FALSE` (default) for cross margin.
#' @param auto_borrow (scalar<logical> | NULL) if `TRUE`, auto-borrow any
#'   shortfall at the lowest market rate.
#' @param auto_repay (scalar<logical> | NULL) if `TRUE`, auto-repay when closing
#'   positions.
#' @return (list) named list of validated order parameters (NULLs removed).
#'
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
validate_margin_order_params <- function(
  type,
  symbol,
  side,
  client_order_id = NULL,
  price = NULL,
  size = NULL,
  funds = NULL,
  stp = NULL,
  tags = NULL,
  remark = NULL,
  time_in_force = NULL,
  cancel_after = NULL,
  post_only = NULL,
  hidden = NULL,
  iceberg = NULL,
  visible_size = NULL,
  is_isolated = NULL,
  auto_borrow = NULL,
  auto_repay = NULL
) {
  # The order-shared parameters are validated by `validate_order_params()`'s own
  # contract (this function delegates to it); the generated contract here covers
  # only the margin-specific additions, which `@inheritParams` does not re-type.
  assert_args_validate_margin_order_params(is_isolated, auto_borrow, auto_repay)
  # clientOid is required for margin orders; auto-generate a real UUID via the
  # vetted `uuid` package if the caller did not supply one (replaces a
  # hand-rolled 4-group hex string that was neither a valid UUID nor unique).
  if (is.null(client_order_id)) {
    client_order_id <- uuid::UUIDgenerate()
  }

  # Validate core order params via existing helper
  params <- validate_order_params(
    type = type,
    symbol = symbol,
    side = side,
    client_order_id = client_order_id,
    price = price,
    size = size,
    funds = funds,
    stp = stp,
    tags = tags,
    remark = remark,
    time_in_force = time_in_force,
    cancel_after = cancel_after,
    post_only = post_only,
    hidden = hidden,
    iceberg = iceberg,
    visible_size = visible_size
  )

  # Margin-specific validation
  if (!is.null(is_isolated) && !is.logical(is_isolated)) {
    rlang::abort("Parameter 'is_isolated' must be logical.")
  }
  if (!is.null(auto_borrow) && !is.logical(auto_borrow)) {
    rlang::abort("Parameter 'autoBorrow' must be logical.")
  }
  if (!is.null(auto_repay) && !is.logical(auto_repay)) {
    rlang::abort("Parameter 'autoRepay' must be logical.")
  }

  # Append margin-specific fields
  params$isIsolated <- is_isolated
  params$autoBorrow <- auto_borrow
  params$autoRepay <- auto_repay

  # Drop NULLs again
  params <- params[!vapply(params, is.null, logical(1))]

  return(assert_return_validate_margin_order_params(params))
}

#' Validate a Single Order in a Batch
#'
#' Validates one order within a batch request by delegating to
#' `validate_order_params()`. Accepts a named list and extracts fields.
#'
#' @param order (list) a single order's parameters.
#' @return (list) named list of validated order parameters.
#'
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
validate_batch_order <- function(order) {
  assert_args_validate_batch_order(order)
  if (!is.list(order)) {
    rlang::abort("Each order in a batch must be a list.")
  }

  required <- c("symbol", "type", "side")
  missing <- setdiff(required, names(order))
  if (length(missing) > 0) {
    rlang::abort(paste0("Missing required field(s) in batch order: ", paste(missing, collapse = ", ")))
  }

  return(assert_return_validate_batch_order(validate_order_params(
    type = order$type,
    symbol = order$symbol,
    side = order$side,
    client_order_id = order$clientOid,
    price = order$price,
    size = order$size,
    funds = order$funds,
    stp = order$stp,
    tags = order$tags,
    remark = order$remark,
    time_in_force = order$timeInForce,
    cancel_after = order$cancelAfter,
    post_only = order$postOnly,
    hidden = order$hidden,
    iceberg = order$iceberg,
    visible_size = order$visibleSize
  )))
}
