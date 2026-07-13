# Typed KuCoin input-validation conditions. Every non-transport abort is raised
# through abort_kucoin_validation_error(), classed c("kucoin_validation_error",
# "kucoin_error") -- kucoin_error is the connector's DOMAIN root, parallel to the
# transport connectcore_error root. The message strings stay byte-identical to
# the bare rlang::abort() calls each site replaced (the goldens below pin that).
# If a golden fails, the backward-compatibility contract broke.

test_that("abort_kucoin_validation_error layers kucoin_validation_error then kucoin_error", {
  err <- tryCatch(kucoin:::abort_kucoin_validation_error("boom"), error = function(e) e)
  expect_identical(
    class(err),
    c("kucoin_validation_error", "kucoin_error", "rlang_error", "error", "condition")
  )
  expect_identical(conditionMessage(err), "boom")
})

test_that("kucoin_validation_error is caught by the kucoin_error root but is NOT a transport error", {
  caught <- tryCatch(kucoin:::abort_kucoin_validation_error("x"), kucoin_error = function(e) "root")
  expect_identical(caught, "root")
  err <- tryCatch(kucoin:::abort_kucoin_validation_error("x"), error = function(e) e)
  expect_false(inherits(err, "connectcore_error"))
})

# ---- Real sites: class, and byte-identical message (golden) ----

test_that("time_convert_from_kucoin rejects a non-numeric with kucoin_validation_error (golden)", {
  err <- tryCatch(time_convert_from_kucoin("not-a-number"), error = function(e) e)
  expect_s3_class(err, "kucoin_validation_error")
  expect_s3_class(err, "kucoin_error")
  expect_identical(conditionMessage(err), "Input must be a numeric value.")
})

test_that("validate_order_params rejects a limit order without price with kucoin_validation_error (golden)", {
  err <- tryCatch(
    validate_order_params(type = "limit", symbol = "BTC-USDT", side = "buy", size = 0.001),
    error = function(e) e
  )
  expect_s3_class(err, "kucoin_validation_error")
  expect_s3_class(err, "kucoin_error")
  expect_identical(conditionMessage(err), "Parameter 'price' is required for limit orders.")
})
