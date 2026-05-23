# tests/testthat/test-KucoinSubAccount.R
# Tests for KucoinSubAccount R6 class with mocked HTTP.

KEYS <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
BASE <- "https://api.kucoin.com"

new_sub <- function() {
  KucoinSubAccount$new(keys = KEYS, base_url = BASE)
}

# -- Construction --

test_that("KucoinSubAccount inherits from KucoinBase", {
  s <- new_sub()
  expect_s3_class(s, "KucoinSubAccount")
  expect_s3_class(s, "KucoinBase")
})

# -- add_sub_account --

test_that("add_sub_account returns data.table with uid and sub_name", {
  resp <- mock_kucoin_response(
    data = list(
      uid = 169630809,
      subName = "mysubacct1",
      remarks = "bot-alpha",
      access = "Spot"
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$add_sub_account(
    password = "MyPass123",
    subName = "mysubacct1",
    access = "Spot",
    remarks = "bot-alpha"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$uid, 169630809)
  expect_equal(dt$sub_name, "mysubacct1")
  expect_equal(dt$access, "Spot")
})

test_that("add_sub_account validates access parameter", {
  expect_error(
    new_sub()$add_sub_account(password = "p", subName = "s", access = "Invalid"),
    "must be one of"
  )
})

# -- get_sub_account_list --

test_that("get_sub_account_list returns paginated data with created_at", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 100,
      totalNum = 2,
      totalPage = 1,
      items = list(
        list(
          userId = "641e7f09df0db80001f1e5ac",
          uid = 169630809,
          subName = "mysubacct1",
          status = 2,
          type = 0,
          access = "Spot",
          remarks = "bot-alpha",
          createdAt = 1679726345000
        ),
        list(
          userId = "641e8027df0db80001f1e6bb",
          uid = 169630810,
          subName = "futuresbot1",
          status = 2,
          type = 0,
          access = "Futures",
          remarks = NA,
          createdAt = 1679726400000
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_sub_account_list()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("created_at" %in% names(dt))
  expect_false("datetime_created" %in% names(dt))
  expect_s3_class(dt$created_at, "POSIXct")
})

test_that("get_sub_account_list handles empty items", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 100,
      totalNum = 0,
      totalPage = 1,
      items = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_sub_account_list()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_detail_balance --

test_that("get_detail_balance returns rows across account types", {
  resp <- mock_kucoin_response(
    data = list(
      subUserId = "169630809",
      subName = "mysubacct1",
      mainAccounts = list(
        list(
          currency = "USDT",
          balance = "1500.00",
          available = "1200.00",
          holds = "300.00",
          baseCurrency = "USDT",
          baseCurrencyPrice = "1",
          baseAmount = "1500.00",
          tag = ""
        ),
        list(
          currency = "BTC",
          balance = "0.05",
          available = "0.05",
          holds = "0.00",
          baseCurrency = "USDT",
          baseCurrencyPrice = "96500",
          baseAmount = "4825.00",
          tag = ""
        )
      ),
      tradeAccounts = list(
        list(
          currency = "USDT",
          balance = "500.00",
          available = "450.00",
          holds = "50.00",
          baseCurrency = "USDT",
          baseCurrencyPrice = "1",
          baseAmount = "500.00",
          tag = ""
        )
      ),
      marginAccounts = list(
        list(
          currency = "ETH",
          balance = "2.50",
          available = "2.50",
          holds = "0.00",
          baseCurrency = "USDT",
          baseCurrencyPrice = "3200",
          baseAmount = "8000.00",
          tag = ""
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_detail_balance("169630809")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 4L)
  expect_true("account_type" %in% names(dt))
  expect_true("sub_user_id" %in% names(dt))
  expect_true("sub_name" %in% names(dt))
  expect_equal(sum(dt$account_type == "main"), 2L)
  expect_equal(sum(dt$account_type == "trade"), 1L)
  expect_equal(sum(dt$account_type == "margin"), 1L)
  # Check column ordering
  expect_equal(names(dt)[1:3], c("sub_user_id", "sub_name", "account_type"))
})

test_that("get_detail_balance handles empty accounts", {
  resp <- mock_kucoin_response(
    data = list(
      subUserId = "169630809",
      subName = "mysubacct1",
      mainAccounts = list(),
      tradeAccounts = list(),
      marginAccounts = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_detail_balance("169630809")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

# -- get_all_spot_balances --

test_that("get_all_spot_balances returns paginated multi-sub-account balances", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 100,
      totalNum = 2,
      totalPage = 1,
      items = list(
        list(
          subUserId = "169630809",
          subName = "mysubacct1",
          mainAccounts = list(
            list(
              currency = "USDT",
              balance = "1500.00",
              available = "1200.00",
              holds = "300.00",
              baseCurrency = "USDT",
              baseCurrencyPrice = "1",
              baseAmount = "1500.00",
              tag = ""
            )
          ),
          tradeAccounts = list(
            list(
              currency = "BTC",
              balance = "0.01",
              available = "0.01",
              holds = "0.00",
              baseCurrency = "USDT",
              baseCurrencyPrice = "96500",
              baseAmount = "965.00",
              tag = ""
            )
          ),
          marginAccounts = list()
        ),
        list(
          subUserId = "169630810",
          subName = "futuresbot1",
          mainAccounts = list(
            list(
              currency = "ETH",
              balance = "5.00",
              available = "5.00",
              holds = "0.00",
              baseCurrency = "USDT",
              baseCurrencyPrice = "3200",
              baseAmount = "16000.00",
              tag = ""
            )
          ),
          tradeAccounts = list(),
          marginAccounts = list()
        )
      )
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_all_spot_balances()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("account_type" %in% names(dt))
  expect_true("sub_user_id" %in% names(dt))
  expect_true("sub_name" %in% names(dt))
  # Check column ordering
  expect_equal(names(dt)[1:3], c("sub_user_id", "sub_name", "account_type"))
  # Sub 1 has main + trade (2 rows), sub 2 has main (1 row)
  expect_equal(sum(dt$sub_user_id == "169630809"), 2L)
  expect_equal(sum(dt$sub_user_id == "169630810"), 1L)
})

test_that("get_all_spot_balances handles empty pages", {
  resp <- mock_kucoin_response(
    data = list(
      currentPage = 1,
      pageSize = 100,
      totalNum = 0,
      totalPage = 1,
      items = list()
    )
  )
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_sub()$get_all_spot_balances()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})
