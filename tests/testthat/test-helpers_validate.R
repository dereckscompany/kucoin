# tests/testthat/test-helpers_validate.R
# Tests for input validation helpers.

# -- verify_symbol --

test_that("verify_symbol accepts valid symbols", {
  expect_true(verify_symbol("BTC-USDT"))
  expect_true(verify_symbol("ETH-BTC"))
  expect_true(verify_symbol("DOGE-USDT"))
  expect_true(verify_symbol("btc-usdt"))
  expect_true(verify_symbol("XRP3S-USDT"))
})

test_that("verify_symbol rejects invalid symbols", {
  expect_false(verify_symbol("BTCUSDT"))
  expect_false(verify_symbol("BTC_USDT"))
  expect_false(verify_symbol("BTC-"))
  expect_false(verify_symbol("-USDT"))
  expect_false(verify_symbol("BTC-USDT-ETH"))
})

# -- validate_order_params --

test_that("validate_order_params validates limit order correctly", {
  params <- validate_order_params(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = 67000,
    size = 0.001
  )

  expect_equal(params$type, "limit")
  expect_equal(params$symbol, "BTC-USDT")
  expect_equal(params$side, "buy")
  expect_equal(params$price, "67000") # converted to character
  expect_equal(params$size, "0.001")
  expect_null(params$funds)
})

test_that("validate_order_params validates market buy with funds", {
  params <- validate_order_params(
    type = "market",
    symbol = "BTC-USDT",
    side = "buy",
    funds = 100
  )

  expect_equal(params$type, "market")
  expect_equal(params$funds, "100")
  expect_null(params$price)
  expect_null(params$size)
})

test_that("validate_order_params validates market sell with size", {
  params <- validate_order_params(
    type = "market",
    symbol = "BTC-USDT",
    side = "sell",
    size = 0.5
  )

  expect_equal(params$size, "0.5")
  expect_null(params$funds)
})

test_that("validate_order_params rejects limit order without price", {
  expect_error(
    validate_order_params(type = "limit", symbol = "BTC-USDT", side = "buy", size = 0.001),
    "price.*required"
  )
})

test_that("validate_order_params rejects limit order without size", {
  expect_error(
    validate_order_params(type = "limit", symbol = "BTC-USDT", side = "buy", price = 67000),
    "size.*required"
  )
})

test_that("validate_order_params rejects limit order with funds", {
  expect_error(
    validate_order_params(type = "limit", symbol = "BTC-USDT", side = "buy", price = 67000, size = 0.001, funds = 100),
    "funds.*not applicable"
  )
})

test_that("validate_order_params rejects market order with price", {
  expect_error(
    validate_order_params(type = "market", symbol = "BTC-USDT", side = "buy", price = 67000, size = 0.001),
    "price.*not applicable"
  )
})

test_that("validate_order_params rejects market order without size or funds", {
  expect_error(
    validate_order_params(type = "market", symbol = "BTC-USDT", side = "buy"),
    "size.*funds"
  )
})

test_that("validate_order_params rejects both size and funds for market", {
  expect_error(
    validate_order_params(type = "market", symbol = "BTC-USDT", side = "buy", size = 0.1, funds = 100),
    "mutually exclusive"
  )
})

test_that("validate_order_params rejects invalid symbol", {
  expect_error(
    validate_order_params(type = "limit", symbol = "BTCUSDT", side = "buy", price = 67000, size = 0.001),
    "valid ticker"
  )
})

test_that("validate_order_params rejects invalid type", {
  expect_error(
    validate_order_params(type = "stop", symbol = "BTC-USDT", side = "buy", size = 0.001),
    class = "rlang_error"
  )
})

test_that("validate_order_params enforces GTT requires cancelAfter", {
  expect_error(
    validate_order_params(
      type = "limit",
      symbol = "BTC-USDT",
      side = "buy",
      price = 67000,
      size = 0.001,
      time_in_force = "GTT"
    ),
    "cancel_after.*required"
  )
})

test_that("validate_order_params enforces postOnly with IOC", {
  expect_error(
    validate_order_params(
      type = "limit",
      symbol = "BTC-USDT",
      side = "buy",
      price = 67000,
      size = 0.001,
      time_in_force = "IOC",
      post_only = TRUE
    ),
    "post_only.*cannot"
  )
})

test_that("validate_order_params enforces iceberg and hidden mutual exclusion", {
  expect_error(
    validate_order_params(
      type = "limit",
      symbol = "BTC-USDT",
      side = "buy",
      price = 67000,
      size = 0.001,
      iceberg = TRUE,
      hidden = TRUE
    ),
    "iceberg.*hidden"
  )
})

test_that("validate_order_params strips NULLs from output", {
  params <- validate_order_params(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = 67000,
    size = 0.001
  )
  # NULLs should not be in the result
  expect_false(any(vapply(params, is.null, logical(1))))
})

test_that("validate_order_params accepts valid optional params", {
  params <- validate_order_params(
    type = "limit",
    symbol = "BTC-USDT",
    side = "buy",
    price = 67000,
    size = 0.001,
    client_order_id = "order-123",
    stp = "CN",
    tags = "bot-v1",
    remark = "test-order",
    time_in_force = "GTT",
    cancel_after = 3600,
    post_only = FALSE
  )

  expect_equal(params$clientOid, "order-123")
  expect_equal(params$stp, "CN")
  expect_equal(params$tags, "bot-v1")
  expect_equal(params$remark, "test-order")
  expect_equal(params$timeInForce, "GTT")
  expect_equal(params$cancelAfter, 3600L)
})

# -- validate_batch_order --

test_that("validate_batch_order validates a single order list", {
  order <- list(type = "limit", symbol = "BTC-USDT", side = "buy", price = 67000, size = 0.001)
  params <- validate_batch_order(order)
  expect_equal(params$type, "limit")
  expect_equal(params$price, "67000")
})

test_that("validate_batch_order rejects non-list input", {
  expect_error(validate_batch_order("not a list"), "list")
})

test_that("validate_batch_order rejects missing required fields", {
  expect_error(
    validate_batch_order(list(type = "limit", symbol = "BTC-USDT")),
    "Missing.*side"
  )
})
