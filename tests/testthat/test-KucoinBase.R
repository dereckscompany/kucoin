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

test_that("KucoinBase rejects max_tries outside [1, 10]", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  expect_error(KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", max_tries = 0L))
  expect_error(KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", max_tries = 11L))
})

# -- max_tries: the hard GET-only retry carve-out --
#
# `httr2::req_perform()` short-circuits its retry loop whenever the `httr2_mock`
# option is set, so `local_mocked_responses()` cannot exercise retry. We mock the
# per-attempt fetch (`httr2:::req_perform1`) instead, letting `req_perform()`
# re-drive it against the policy the constructor's `max_tries` threaded into
# `connectcore::build_request()`; `sys_sleep` is stubbed so backoff is instant.

test_that("a non-idempotent POST is performed exactly once even with max_tries = 5", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", max_tries = 5L)
  n <- 0L
  testthat::local_mocked_bindings(
    sys_sleep = function(seconds, ...) invisible(),
    req_perform1 = function(req, req_prep, path, handle, resend_count) {
      n <<- n + 1L
      return(mock_http_error(status_code = 500L, body_text = "Internal Server Error"))
    },
    .package = "httr2"
  )
  priv <- base$.__enclos_env__$private
  expect_error(priv$.request(endpoint = "/api/v1/orders", method = "POST", auth = FALSE))
  expect_identical(n, 1L) # never a silent resend of an order
})

test_that("a transient 500 on a GET is retried and then succeeds (max_tries = 3)", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", max_tries = 3L)
  n <- 0L
  testthat::local_mocked_bindings(
    sys_sleep = function(seconds, ...) invisible(),
    req_perform1 = function(req, req_prep, path, handle, resend_count) {
      n <<- n + 1L
      if (n == 1L) {
        return(mock_http_error(status_code = 500L, body_text = "Internal Server Error"))
      }
      return(mock_kucoin_response(data = list(ok = TRUE)))
    },
    .package = "httr2"
  )
  priv <- base$.__enclos_env__$private
  out <- priv$.request(endpoint = "/api/v1/status", method = "GET", auth = FALSE)
  expect_true(out$ok)
  expect_identical(n, 2L) # retried once on the 500, then succeeded
})
