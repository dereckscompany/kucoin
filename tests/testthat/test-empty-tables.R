# tests/testthat/test-empty-tables.R
# Every shared empty_dt_*() helper must be a zero-row data.table whose columns
# and types satisfy the column contract of a method that returns it. This is the
# guard that would have caught empty_dt_orderbook() typing `level` as character
# when the contract requires assert_count (integer).

test_that("empty_dt_* helpers satisfy their methods' return contracts", {
  cases <- list(
    list(empty_dt_dcp(), assert_return_KucoinFuturesTrading__get_dcp),
    list(empty_dt_futures_order(), assert_return_KucoinFuturesTrading__get_order_by_id),
    list(empty_dt_futures_orderbook(), assert_return_KucoinFuturesMarketData__get_part_orderbook),
    list(empty_dt_isolated_margin(), assert_return_KucoinFuturesAccount__add_isolated_margin),
    list(empty_dt_klines(), assert_return_KucoinMarketData__get_klines),
    list(empty_dt_leverage(), assert_return_KucoinFuturesAccount__get_cross_margin_leverage),
    list(empty_dt_margin_mode(), assert_return_KucoinFuturesAccount__get_margin_mode),
    list(empty_dt_oco_order(), assert_return_KucoinOcoOrders__get_order_by_id),
    list(empty_dt_order_ack(), assert_return_KucoinFuturesTrading__add_order),
    list(empty_dt_order_id(), assert_return_KucoinStopOrders__add_order),
    list(empty_dt_order_no(), assert_return_KucoinLending__purchase),
    list(empty_dt_orderbook(), assert_return_KucoinMarketData__get_part_orderbook),
    list(empty_dt_service_status(), assert_return_KucoinFuturesMarketData__get_service_status),
    list(empty_dt_symbol(), assert_return_KucoinMarketData__get_symbol)
  )
  for (case in cases) {
    empty <- case[[1]]
    contract <- case[[2]]
    expect_s3_class(empty, "data.table")
    expect_identical(nrow(empty), 0L)
    # The contract (assert_has_columns + per-column type asserts) must accept the
    # typed empty without aborting — an empty response has to pass cleanly.
    expect_no_error(contract(empty))
  }
})
