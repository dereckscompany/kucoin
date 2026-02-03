# tests/testthat/test-utils.R
# Tests for general utility functions.

# -- get_base_url --

test_that("get_base_url returns default when no env var set", {
  withr::with_envvar(c("KC-API-ENDPOINT" = ""), {
    expect_equal(get_base_url(), "https://api.kucoin.com")
  })
})

test_that("get_base_url returns explicit url when provided", {
  expect_equal(
    get_base_url("https://openapi-sandbox.kucoin.com"),
    "https://openapi-sandbox.kucoin.com"
  )
})

test_that("get_base_url returns env var when set", {
  withr::with_envvar(c("KC-API-ENDPOINT" = "https://custom.kucoin.com"), {
    expect_equal(get_base_url(), "https://custom.kucoin.com")
  })
})

test_that("get_base_url handles NULL input", {
  expect_equal(get_base_url(NULL), "https://api.kucoin.com")
})

# -- get_api_keys --

test_that("get_api_keys returns list with correct structure", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )

  expect_type(keys, "list")
  expect_equal(keys$api_key, "test-key")
  expect_equal(keys$api_secret, "test-secret")
  expect_equal(keys$api_passphrase, "test-pass")
  expect_equal(keys$key_version, "2")
})

test_that("get_api_keys respects key_version parameter", {
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p", key_version = "3")
  expect_equal(keys$key_version, "3")
})

# -- get_sub_account --

test_that("get_sub_account returns list with correct fields", {
  sub <- get_sub_account(sub_account_name = "test-sub", sub_account_password = "pass123")
  expect_type(sub, "list")
  expect_equal(sub$sub_account_name, "test-sub")
  expect_equal(sub$sub_account_password, "pass123")
})
