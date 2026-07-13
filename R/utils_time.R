# File: R/utils_time.R
# Timestamp conversion utilities for KuCoin API interaction.

#' Convert KuCoin Timestamp to POSIXct
#'
#' Converts a UNIX timestamp from KuCoin's API into a POSIXct object in UTC.
#'
#' @param time_value (vector<numeric, 1..>) the UNIX timestamp(s).
#' @param unit (scalar<character in c("ms", "ns", "s")>) input unit: `"ms"`
#'   (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).
#' @return (class<POSIXct>) POSIXct in UTC.
#'
#' @examples
#' \dontrun{
#' time_convert_from_kucoin(1698777600000, unit = "ms")
#' time_convert_from_kucoin(1698777600000000000, unit = "ns")
#' time_convert_from_kucoin(1698777600, unit = "s")
#' }
#'
#' @importFrom lubridate as_datetime
#' @importFrom rlang abort
#' @export
#' @noassert time_value, unit
time_convert_from_kucoin <- function(time_value, unit = c("ms", "ns", "s")) {
  unit <- match.arg(unit)
  if (!is.numeric(time_value)) {
    abort_kucoin_validation_error("Input must be a numeric value.")
  }

  seconds <- switch(
    unit,
    ms = time_value / 1000,
    ns = time_value / 1e9,
    s = time_value
  )

  return(assert_return_time_convert_from_kucoin(lubridate::as_datetime(seconds)))
}

#' Convert POSIXct to KuCoin Timestamp
#'
#' Converts a POSIXct object into a UNIX timestamp in the specified unit.
#'
#' @param datetime (class<POSIXct>) the object to convert.
#' @param unit (scalar<character in c("ms", "ns", "s")>) output unit: `"ms"`
#'   (milliseconds, default), `"ns"` (nanoseconds), or `"s"` (seconds).
#' @return (scalar<numeric> | scalar<integer>) UNIX timestamp in the specified
#'   unit (`numeric` for `"ms"`/`"ns"`, `integer` for `"s"`).
#'
#' @examples
#' \dontrun{
#' dt <- lubridate::as_datetime("2023-10-31 16:00:00", tz = "UTC")
#' time_convert_to_kucoin(dt, unit = "ms")  # 1698777600000
#' time_convert_to_kucoin(dt, unit = "s")   # 1698777600
#' }
#'
#' @importFrom rlang abort
#' @export
#' @noassert datetime, unit
time_convert_to_kucoin <- function(datetime, unit = c("ms", "ns", "s")) {
  unit <- match.arg(unit)
  if (!inherits(datetime, "POSIXct")) {
    abort_kucoin_validation_error("Input must be a POSIXct object.")
  }

  seconds <- as.numeric(datetime)

  result <- switch(
    unit,
    ms = seconds * 1000,
    ns = seconds * 1e9,
    s = as.integer(seconds)
  )

  return(assert_return_time_convert_to_kucoin(result))
}
