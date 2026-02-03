# tests/testthat/test-utils_time.R
# Tests for timestamp conversion utilities.

# Known reference: 2023-10-31 16:00:00 UTC = epoch 1698768000
EPOCH_S <- 1698768000
EPOCH_MS <- EPOCH_S * 1000
EPOCH_NS <- EPOCH_S * 1e9
DATETIME_STR <- "2023-10-31 16:00:00"

# -- time_convert_from_kucoin --

test_that("time_convert_from_kucoin converts milliseconds", {
  result <- time_convert_from_kucoin(EPOCH_MS, unit = "ms")
  expect_s3_class(result, "POSIXct")
  expect_equal(as.numeric(result), EPOCH_S, tolerance = 0.001)
})

test_that("time_convert_from_kucoin converts nanoseconds", {
  result <- time_convert_from_kucoin(EPOCH_NS, unit = "ns")
  expect_s3_class(result, "POSIXct")
  expect_equal(as.numeric(result), EPOCH_S, tolerance = 0.001)
})

test_that("time_convert_from_kucoin converts seconds", {
  result <- time_convert_from_kucoin(EPOCH_S, unit = "s")
  expect_s3_class(result, "POSIXct")
  expect_equal(as.numeric(result), EPOCH_S, tolerance = 0.001)
})

test_that("time_convert_from_kucoin defaults to milliseconds", {
  result <- time_convert_from_kucoin(EPOCH_MS)
  expect_equal(as.numeric(result), EPOCH_S, tolerance = 0.001)
})

test_that("time_convert_from_kucoin rejects non-numeric input", {
  expect_error(time_convert_from_kucoin("not-a-number"), "numeric")
})

# -- time_convert_to_kucoin --

test_that("time_convert_to_kucoin converts to milliseconds", {
  dt <- lubridate::as_datetime(DATETIME_STR, tz = "UTC")
  result <- time_convert_to_kucoin(dt, unit = "ms")
  expect_equal(result, EPOCH_MS, tolerance = 1)
})

test_that("time_convert_to_kucoin converts to nanoseconds", {
  dt <- lubridate::as_datetime(DATETIME_STR, tz = "UTC")
  result <- time_convert_to_kucoin(dt, unit = "ns")
  expect_equal(result, EPOCH_NS, tolerance = 1e6)
})

test_that("time_convert_to_kucoin converts to seconds", {
  dt <- lubridate::as_datetime(DATETIME_STR, tz = "UTC")
  result <- time_convert_to_kucoin(dt, unit = "s")
  expect_equal(result, as.integer(EPOCH_S))
  expect_type(result, "integer")
})

test_that("time_convert_to_kucoin defaults to milliseconds", {
  dt <- lubridate::as_datetime(DATETIME_STR, tz = "UTC")
  result <- time_convert_to_kucoin(dt)
  expect_equal(result, EPOCH_MS, tolerance = 1)
})

test_that("time_convert_to_kucoin rejects non-POSIXct input", {
  expect_error(time_convert_to_kucoin("2023-10-31"), "POSIXct")
  expect_error(time_convert_to_kucoin(EPOCH_S), "POSIXct")
})

# -- Round-trip consistency --

test_that("from/to kucoin round-trips correctly", {
  original_ms <- 1729159459033
  posixct <- time_convert_from_kucoin(original_ms, unit = "ms")
  back_to_ms <- time_convert_to_kucoin(posixct, unit = "ms")
  expect_equal(back_to_ms, original_ms, tolerance = 1)
})
