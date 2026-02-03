# tests/testthat/test-KucoinBase.R
# Tests for the abstract base class.

test_that("KucoinBase initializes with default sync mode", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com")

  expect_s3_class(base, "KucoinBase")
  expect_false(base$is_async)
})

test_that("KucoinBase initializes with async mode", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", async = TRUE)

  expect_true(base$is_async)
})

test_that("KucoinBase is_async is read-only", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com")

  # Active binding should not allow setting
  expect_error(base$is_async <- TRUE)
})

test_that("KucoinBase initialize returns invisible self", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  result <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com")

  # Should return self (an R6 object)
  expect_s3_class(result, "KucoinBase")
})

test_that("KucoinBase defaults to local time_source", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com")

  expect_equal(base$time_source, "local")
})

test_that("KucoinBase accepts server time_source", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", time_source = "server")

  expect_equal(base$time_source, "server")
})

test_that("KucoinBase rejects invalid time_source", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")

  expect_error(
    KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", time_source = "invalid"),
    "arg"
  )
})

test_that("KucoinBase time_source is read-only", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com")

  expect_error(base$time_source <- "server")
})
