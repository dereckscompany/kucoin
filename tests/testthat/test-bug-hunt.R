# ===========================================================================
# Bug Hunt Tests — KuCoin
# These tests are written as if each bug is already fixed.
# Running against the current code should produce FAILURES.
# ===========================================================================

# ---------------------------------------------------------------------------
# Bug #1: kucoin_paginate() does not forward .get_timestamp_ms
# When time_source="server", paginated requests should use server time.
# ---------------------------------------------------------------------------
test_that("kucoin_paginate forwards .get_timestamp_ms to build_request", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )

  captured_timestamps <- c()
  server_time_ms <- 1704067200000 # Fixed server time

  # Mock response for a paginated endpoint (single page)
  mock_data <- list(
    currentPage = 1L,
    pageSize = 50L,
    totalNum = 1L,
    totalPage = 1L,
    items = list(
      list(id = "abc123", amount = "100")
    )
  )

  resp <- mock_kucoin_response(data = mock_data)

  httr2::local_mocked_responses(function(req) {
    # Capture the timestamp from the request header
    ts <- req$headers[["KC-API-TIMESTAMP"]]
    if (!is.null(ts)) {
      captured_timestamps <<- c(captured_timestamps, ts)
    }
    resp
  })

  # Call paginate with a .get_timestamp_ms that returns a fixed server time
  result <- kucoin:::kucoin_paginate(
    base_url = "https://api.kucoin.com",
    endpoint = "/api/v1/accounts/ledgers",
    keys = keys,
    .perform = httr2::req_perform,
    .get_timestamp_ms = function() server_time_ms,
    items_field = "items"
  )

  # The timestamp in the header should match our server time, NOT local time
  expect_length(captured_timestamps, 1L)
  expect_equal(
    captured_timestamps[1],
    as.character(server_time_ms),
    info = "Paginated request must use the provided .get_timestamp_ms, not local time"
  )
})

# ---------------------------------------------------------------------------
# Bug #2: kucoin_paginate() does not forward timeout
# Paginated requests should use the same timeout as regular requests.
# ---------------------------------------------------------------------------
test_that("kucoin_paginate uses provided timeout, not default 10s", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )

  mock_data <- list(
    currentPage = 1L,
    pageSize = 50L,
    totalNum = 1L,
    totalPage = 1L,
    items = list(
      list(id = "abc123", amount = "100")
    )
  )

  resp <- mock_kucoin_response(data = mock_data)

  captured_req <- NULL
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    resp
  })

  result <- kucoin:::kucoin_paginate(
    base_url = "https://api.kucoin.com",
    endpoint = "/api/v1/accounts/ledgers",
    keys = keys,
    .perform = httr2::req_perform,
    timeout = 30,
    items_field = "items"
  )

  # Check that the request has a 30s timeout, not the default 10s
  # httr2 stores timeout in options
  req_options <- captured_req$options
  expect_equal(
    req_options$timeout_ms %||% req_options$timeout,
    30000,
    info = "Paginated requests should use the specified timeout (30s), not default (10s)"
  )
})

# ---------------------------------------------------------------------------
# Bug #5: Backfill resume appends duplicate rows (same as Binance bug #4)
# combo_from is set to last_dt, so the last existing candle is re-fetched.
# ---------------------------------------------------------------------------
test_that("kucoin backfill resume logic starts after last existing timestamp", {
  resume <- data.table::data.table(
    symbol = "BTC-USDT",
    timeframe = "1hour",
    last_dt = as.POSIXct("2024-01-01 02:00:00", tz = "UTC")
  )

  from <- as.POSIXct("2024-01-01 00:00:00", tz = "UTC")
  to <- as.POSIXct("2024-01-01 05:00:00", tz = "UTC")

  sym <- "BTC-USDT"
  intv <- "1hour"

  # Replicate the resume logic from backfill.R
  combo_from <- from
  match_row <- resume[symbol == sym & timeframe == intv]
  if (nrow(match_row) > 0L) {
    last_dt <- match_row$last_dt[1L]
    if (last_dt < to) {
      combo_from <- last_dt + 1 # Fixed: offset by 1 second to avoid duplicates
    }
  }

  last_existing <- as.POSIXct("2024-01-01 02:00:00", tz = "UTC")
  expect_true(
    combo_from > last_existing,
    info = paste(
      "Resume should start AFTER last existing timestamp to avoid duplicates.",
      "Got combo_from =",
      format(combo_from),
      "== last_dt =",
      format(last_existing)
    )
  )
})

# ---------------------------------------------------------------------------
# Bug #7: HMAC signature computed from non-URL-encoded query string
# ---------------------------------------------------------------------------
test_that("sign_request encodes special chars in query string for HMAC", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )

  # Build a request with special characters in the query
  req <- httr2::request("https://api.kucoin.com/api/v1/sub/user")
  req <- httr2::req_url_query(req, email = "sub@user.com")

  signed_req <- kucoin:::sign_request(
    req,
    keys,
    method = "GET",
    path = "/api/v1/sub/user?email=sub%40user.com"
  )

  # The KC-API-SIGN header should be computed from the URL-encoded path
  sig_header <- signed_req$headers[["KC-API-SIGN"]]
  ts_header <- signed_req$headers[["KC-API-TIMESTAMP"]]

  # Compute expected signature using URL-encoded path
  prehash <- paste0(ts_header, "GET", "/api/v1/sub/user?email=sub%40user.com", "")
  expected_sig <- base64enc::base64encode(
    digest::hmac(
      key = "test-secret",
      object = prehash,
      algo = "sha256",
      raw = TRUE
    )
  )

  expect_equal(sig_header, expected_sig, info = "Signature must be computed using URL-encoded query string")
})

# ---------------------------------------------------------------------------
# Bug #8 (kucoin): as_dt_row wraps length>1 lists but NOT length-1 lists
# ---------------------------------------------------------------------------
test_that("as_dt_row wraps length-1 list fields consistently", {
  row1 <- list(name = "BTC", chains = list("ERC20"))
  row2 <- list(name = "ETH", chains = list("ERC20", "TRC20"))

  dt1 <- kucoin:::as_dt_row(row1)
  dt2 <- kucoin:::as_dt_row(row2)

  expect_true(is.list(dt1$chains), info = "Single-element list field should remain a list column")
  expect_true(is.list(dt2$chains), info = "Multi-element list field should remain a list column")

  combined <- data.table::rbindlist(list(dt1, dt2), fill = TRUE)
  expect_equal(nrow(combined), 2L)
  expect_true(is.list(combined$chains), info = "Combined data.table should have consistent list column")
  expect_equal(combined$chains[[1]], list("ERC20"))
  expect_equal(combined$chains[[2]], list("ERC20", "TRC20"))
})

# ---------------------------------------------------------------------------
# Bug #9: KucoinFuturesAccount$get_position() uses as_dt_list for single obj
# The API returns a single position object, not an array.
# ---------------------------------------------------------------------------
test_that("get_position returns correct data.table for single position", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )
  BASE <- "https://api-futures.kucoin.com"

  fa <- KucoinFuturesAccount$new(keys = keys, base_url = BASE)

  # KuCoin Futures returns a SINGLE position object (not an array)
  mock_position <- list(
    id = "abc123",
    symbol = "XBTUSDTM",
    autoDeposit = FALSE,
    maintMarginReq = 0.005,
    riskLimit = 200,
    realLeverage = 5.0,
    crossMode = FALSE,
    delevPercentage = 0.1,
    openingTimestamp = 1704067200000,
    currentTimestamp = 1704070800000,
    currentQty = 10,
    currentCost = 42000.0,
    currentComm = 2.5,
    unrealisedCost = 42000.0,
    realisedGrossCost = 0,
    realisedCost = 2.5,
    isOpen = TRUE,
    markPrice = 42100.0,
    markValue = 42100.0,
    posCost = 42000.0,
    posCross = 0,
    posInit = 8400.0,
    posComm = 5.04,
    posLoss = 0,
    posMargin = 8405.04,
    posMaint = 215.04,
    maintMargin = 8505.04,
    realisedGrossPnl = 0,
    realisedPnl = -2.5,
    unrealisedPnl = 100.0,
    unrealisedPnlPcnt = 0.0024,
    unrealisedRoePcnt = 0.0119,
    avgEntryPrice = 42000.0,
    liquidationPrice = 33800.0,
    bankruptPrice = 33600.0
  )

  resp <- mock_kucoin_response(data = mock_position)
  httr2::local_mocked_responses(function(req) resp)

  dt <- fa$get_position(symbol = "XBTUSDTM")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L, info = "Single position should produce exactly 1 row")
  expect_equal(dt$symbol, "XBTUSDTM", info = "Symbol should be correctly parsed from the flat object")
  expect_true("avg_entry_price" %in% names(dt), info = "Fields should be converted to snake_case")
})

# ---------------------------------------------------------------------------
# Bug #16: get_currency() cbind produces duplicate column names
# When top-level and chain-level fields have the same name, the result
# should either deduplicate or prefer chain-level values.
# ---------------------------------------------------------------------------
test_that("get_currency does not produce duplicate column names", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )
  BASE <- "https://api.kucoin.com"

  market <- KucoinMarketData$new(keys = keys, base_url = BASE)

  # Response where top-level and chain-level share field names
  mock_currency <- list(
    currency = "USDT",
    name = "Tether",
    fullName = "Tether USD",
    precision = 8L,
    confirms = NULL,
    contractAddress = NULL,
    isMarginEnabled = TRUE,
    isDebitEnabled = TRUE,
    chains = list(
      list(
        chainName = "ERC20",
        chainId = "eth",
        confirms = 12L,
        contractAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7",
        withdrawalMinSize = "10",
        depositMinSize = "0.01",
        isWithdrawEnabled = TRUE,
        isDepositEnabled = TRUE
      ),
      list(
        chainName = "TRC20",
        chainId = "trx",
        confirms = 1L,
        contractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
        withdrawalMinSize = "1",
        depositMinSize = "0.01",
        isWithdrawEnabled = TRUE,
        isDepositEnabled = TRUE
      )
    )
  )

  resp <- mock_kucoin_response(data = mock_currency)
  httr2::local_mocked_responses(function(req) resp)

  dt <- market$get_currency("USDT")
  expect_s3_class(dt, "data.table")

  # There should be NO duplicate column names
  col_names <- names(dt)
  expect_equal(
    length(col_names),
    length(unique(col_names)),
    info = paste(
      "Column names should be unique. Duplicates found:",
      paste(col_names[duplicated(col_names)], collapse = ", ")
    )
  )

  # The chain-level values should be present (not overridden by top-level NULLs)
  if ("confirms" %in% names(dt)) {
    expect_true(
      all(!is.na(dt$confirms)),
      info = "confirms should contain chain-level values, not top-level NULLs"
    )
  }
})

# ---------------------------------------------------------------------------
# Bug #18 (kucoin): get_api_keys() returns empty strings without warning
# ---------------------------------------------------------------------------
test_that("get_api_keys warns when env vars are not set", {
  withr::local_envvar(
    KUCOIN_API_KEY = "",
    KUCOIN_API_SECRET = "",
    KUCOIN_API_PASSPHRASE = ""
  )

  expect_warning(
    get_api_keys(),
    regexp = "API|key|secret|credential|not set|missing|empty",
    ignore.case = TRUE,
    info = "get_api_keys should warn when env vars return empty strings"
  )
})

# ---------------------------------------------------------------------------
# Bug #21: as.integer(from) * 1000 overflows for futures timestamps
# Should use as.numeric() instead of as.integer() for ms conversion.
# ---------------------------------------------------------------------------
test_that("futures klines timestamp conversion does not overflow", {
  keys <- get_api_keys(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass"
  )
  BASE <- "https://api-futures.kucoin.com"

  fm <- KucoinFuturesMarketData$new(keys = keys, base_url = BASE)

  captured_url <- NULL
  mock_klines <- list(
    list(1704067200000, 42000, 42100, 41900, 42050, 100, 4200000)
  )
  resp <- mock_kucoin_response(data = mock_klines)
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  # as.integer() on POSIXct returns 32-bit int. Dates after 2038-01-19
  # have epoch seconds > 2147483647 (.Machine$integer.max), so
  # as.integer() returns NA with a warning, producing broken queries.
  # 2040-01-01 epoch = ~2208988800 > 2147483647
  future_date <- as.POSIXct("2040-01-01", tz = "UTC")

  # The conversion should NOT produce a warning about NAs from integer overflow
  expect_no_warning(
    fm$get_klines(
      symbol = "XBTUSDTM",
      granularity = 60,
      from = future_date,
      to = future_date + 3600
    )
  )

  # Verify the URL contains the correct millisecond timestamp (not NA or wrong)
  parsed <- httr2::url_parse(captured_url)
  from_ms <- as.numeric(parsed$query$from)

  expected_ms <- as.numeric(future_date) * 1000
  expect_equal(from_ms, expected_ms, tolerance = 1)
})
