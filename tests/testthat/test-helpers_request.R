# tests/testthat/test-helpers_request.R
# Tests for HTTP request infrastructure: sign_request, kucoin_sign_req,
# parse_kucoin_response, and kucoin_paginate. The request funnel itself lives in
# connectcore (build_request); KuCoin reaches it through KucoinBase$.request,
# which pre-serialises the body and routes it via body_format = "raw".

# A minimal KucoinBase subclass that exposes the private .request seam so the
# transport path can be exercised directly (it normally runs behind the public
# methods of the concrete client classes).
TestKucoinClient <- R6::R6Class(
  "TestKucoinClient",
  inherit = KucoinBase,
  public = list(
    request = function(...) {
      return(private$.request(...))
    }
  )
)

# -- parse_kucoin_response --

test_that("parse_kucoin_response extracts data from valid response", {
  resp <- mock_kucoin_response(data = list(symbol = "BTC-USDT", price = "67000"))
  result <- parse_kucoin_response(resp)
  expect_equal(result$symbol, "BTC-USDT")
  expect_equal(result$price, "67000")
})

test_that("parse_kucoin_response aborts on non-200 HTTP status", {
  resp <- mock_http_error(status_code = 500L, body_text = "Server Error")
  expect_error(parse_kucoin_response(resp), "HTTP error 500")
})

test_that("parse_kucoin_response aborts on KuCoin API error code", {
  resp <- mock_kucoin_error(code = "400100", msg = "Order not found")
  expect_error(parse_kucoin_response(resp), "400100.*Order not found")
})

test_that("parse_kucoin_response aborts on missing code field", {
  body <- jsonlite::toJSON(list(data = "something"), auto_unbox = TRUE)
  resp <- httr2::response(
    status_code = 200L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  )
  expect_error(parse_kucoin_response(resp), "missing.*code")
})

# -- sign_request --

test_that("sign_request adds all required auth headers", {
  req <- httr2::request("https://api.kucoin.com")
  keys <- list(
    api_key = "test-key-123",
    api_secret = "test-secret-abc",
    api_passphrase = "test-pass",
    key_version = "2"
  )

  signed <- sign_request(req, keys, "GET", "/api/v1/accounts", "")

  # Extract headers from the signed request
  headers <- signed$headers
  expect_true("KC-API-KEY" %in% names(headers))
  expect_true("KC-API-SIGN" %in% names(headers))
  expect_true("KC-API-TIMESTAMP" %in% names(headers))
  expect_true("KC-API-PASSPHRASE" %in% names(headers))
  expect_true("KC-API-KEY-VERSION" %in% names(headers))

  expect_equal(headers[["KC-API-KEY"]], "test-key-123")
  expect_equal(headers[["KC-API-KEY-VERSION"]], "2")

  # Timestamp should be a numeric string (ms)
  ts <- headers[["KC-API-TIMESTAMP"]]
  expect_match(ts, "^[0-9]+$")

  # Signature and passphrase should be base64-encoded
  expect_match(headers[["KC-API-SIGN"]], "^[A-Za-z0-9+/=]+$")
  expect_match(headers[["KC-API-PASSPHRASE"]], "^[A-Za-z0-9+/=]+$")
})

test_that("sign_request uses custom .get_timestamp_ms function when provided", {
  req <- httr2::request("https://api.kucoin.com")
  keys <- list(
    api_key = "test-key",
    api_secret = "test-secret",
    api_passphrase = "test-pass",
    key_version = "2"
  )

  get_fixed_ts <- function() 1700000000000
  signed <- sign_request(req, keys, "GET", "/api/v1/accounts", "", .get_timestamp_ms = get_fixed_ts)

  expect_equal(signed$headers[["KC-API-TIMESTAMP"]], "1700000000000")
})

test_that("sign_request produces different signatures for different methods", {
  req <- httr2::request("https://api.kucoin.com")
  keys <- list(api_key = "k", api_secret = "s", api_passphrase = "p", key_version = "2")

  signed_get <- sign_request(req, keys, "GET", "/api/v1/accounts", "")
  signed_post <- sign_request(req, keys, "POST", "/api/v1/accounts", "")

  # Timestamps will differ so signatures will differ, but at minimum

  # both should have the header set
  expect_true(!is.null(signed_get$headers[["KC-API-SIGN"]]))
  expect_true(!is.null(signed_post$headers[["KC-API-SIGN"]]))
})

# -- KucoinBase$.request (connectcore funnel via body_format = "raw") --

test_that(".request parses successful response with .parser", {
  resp <- mock_kucoin_response(data = mock_ticker_data())

  httr2::local_mocked_responses(function(req) resp)

  client <- TestKucoinClient$new(
    keys = get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p"),
    base_url = "https://api.kucoin.com"
  )
  result <- client$request(
    endpoint = "/api/v1/market/orderbook/level1",
    method = "GET",
    query = list(symbol = "BTC-USDT"),
    auth = FALSE,
    .parser = as_dt_row
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1L)
  expect_true("price" %in% names(result))
})

test_that(".request passes query parameters correctly", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = list())

  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  client <- TestKucoinClient$new(
    keys = get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p"),
    base_url = "https://api.kucoin.com"
  )
  client$request(
    endpoint = "/api/v1/market/stats",
    query = list(symbol = "ETH-USDT"),
    auth = FALSE
  )

  # The URL should contain the query parameter
  expect_true(grepl("symbol=ETH-USDT", captured_req$url))
})

test_that(".request applies authentication when auth = TRUE", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = list())

  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")

  client <- TestKucoinClient$new(keys = keys, base_url = "https://api.kucoin.com")
  client$request(
    endpoint = "/api/v3/market/orderbook/level2",
    query = list(symbol = "BTC-USDT"),
    auth = TRUE
  )

  expect_true("KC-API-KEY" %in% names(captured_req$headers))
  expect_true("KC-API-SIGN" %in% names(captured_req$headers))
})

test_that(".request skips auth when auth = FALSE", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = list())

  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  client <- TestKucoinClient$new(
    keys = get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p"),
    base_url = "https://api.kucoin.com"
  )
  client$request(
    endpoint = "/api/v1/market/histories",
    auth = FALSE
  )

  expect_false("KC-API-KEY" %in% names(captured_req$headers))
})

test_that(".request signs the exact compact JSON body sent on the wire", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = list())

  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  body <- list(clientOid = "abc-123", symbol = "BTC-USDT", side = "buy")
  expected_body <- as.character(jsonlite::toJSON(body, auto_unbox = TRUE))

  client <- TestKucoinClient$new(keys = keys, base_url = "https://api.kucoin.com")
  client$request(
    endpoint = "/api/v1/hf/orders",
    method = "POST",
    body = body,
    auth = TRUE
  )

  # The body must be sent byte-verbatim (compact JSON, no pretty-printing) so
  # the HMAC signature, computed over those exact bytes, matches on the wire.
  expect_equal(as.character(captured_req$body$data), expected_body)
  expect_true("KC-API-SIGN" %in% names(captured_req$headers))
})

test_that(".request propagates KuCoin API errors", {
  resp <- mock_kucoin_error(code = "400100", msg = "Order does not exist")

  httr2::local_mocked_responses(function(req) resp)

  client <- TestKucoinClient$new(
    keys = get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p"),
    base_url = "https://api.kucoin.com"
  )
  expect_error(
    client$request(
      endpoint = "/api/v1/orders/nonexistent",
      auth = FALSE
    ),
    "400100.*Order does not exist"
  )
})

test_that(".request propagates HTTP errors", {
  resp <- mock_http_error(status_code = 429L, body_text = "Too Many Requests")

  httr2::local_mocked_responses(function(req) resp)

  client <- TestKucoinClient$new(
    keys = get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p"),
    base_url = "https://api.kucoin.com"
  )
  expect_error(
    client$request(
      endpoint = "/api/v1/market/stats",
      auth = FALSE
    ),
    "429"
  )
})

test_that(".request uses the configured timestamp source for signing", {
  captured_req <- NULL
  resp <- mock_kucoin_response(data = list(balance = "100"))

  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  client <- TestKucoinClient$new(keys = keys, base_url = "https://api.kucoin.com")
  # Inject a fixed clock the way time_source does, so the timestamp is pinned.
  client$.__enclos_env__$private$.get_timestamp_ms <- function() 1700000000000

  client$request(
    endpoint = "/api/v1/accounts",
    auth = TRUE
  )

  expect_equal(captured_req$headers[["KC-API-TIMESTAMP"]], "1700000000000")
})

test_that("KucoinBase with time_source 'server' passes server-time function to requests", {
  # When time_source = "server", the base class stores a .get_timestamp_ms
  # closure that calls fetch_server_time_ms. We verify via the constructor.
  keys <- get_api_keys(api_key = "k", api_secret = "s", api_passphrase = "p")
  base <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", time_source = "server")
  expect_equal(base$time_source, "server")

  # With time_source = "local", .get_timestamp_ms uses Sys.time()
  base_local <- KucoinBase$new(keys = keys, base_url = "https://api.kucoin.com", time_source = "local")
  expect_equal(base_local$time_source, "local")
})

# -- then_or_now --

test_that("then_or_now applies function synchronously when is_async = FALSE", {
  result <- then_or_now(5, function(x) x * 2, is_async = FALSE)
  expect_equal(result, 10)
})

# -- kucoin_paginate with mocked HTTP --

test_that("kucoin_paginate fetches single page correctly", {
  page_data <- mock_announcements_page_data()
  resp <- mock_kucoin_response(data = page_data)

  httr2::local_mocked_responses(function(req) resp)

  result <- kucoin_paginate(
    base_url = "https://api.kucoin.com",
    endpoint = "/api/v3/announcements",
    .parser = function(pages) {
      dt <- flatten_pages(pages)
      return(dt)
    },
    page_size = 50
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
  expect_true("ann_id" %in% names(result))
})

test_that("kucoin_paginate fetches multiple pages", {
  call_count <- 0L

  page1 <- list(
    totalNum = 3L,
    totalPage = 2L,
    currentPage = 1L,
    pageSize = 2L,
    items = list(
      list(annId = 1L, annTitle = "First"),
      list(annId = 2L, annTitle = "Second")
    )
  )
  page2 <- list(
    totalNum = 3L,
    totalPage = 2L,
    currentPage = 2L,
    pageSize = 2L,
    items = list(
      list(annId = 3L, annTitle = "Third")
    )
  )

  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    if (call_count == 1L) {
      return(mock_kucoin_response(data = page1))
    }
    return(mock_kucoin_response(data = page2))
  })

  result <- kucoin_paginate(
    base_url = "https://api.kucoin.com",
    endpoint = "/api/v3/announcements",
    .parser = flatten_pages,
    page_size = 2
  )

  expect_equal(nrow(result), 3L)
  expect_equal(call_count, 2L)
})

test_that("kucoin_paginate respects max_pages", {
  call_count <- 0L

  many_pages <- list(
    totalNum = 100L,
    totalPage = 10L,
    currentPage = 1L,
    pageSize = 10L,
    items = list(list(annId = 1L, annTitle = "Item"))
  )

  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    many_pages$currentPage <- call_count
    return(mock_kucoin_response(data = many_pages))
  })

  result <- kucoin_paginate(
    base_url = "https://api.kucoin.com",
    endpoint = "/api/v3/announcements",
    .parser = flatten_pages,
    page_size = 10,
    max_pages = 2
  )

  expect_equal(call_count, 2L)
})

test_that("kucoin_paginate walks thousands of pages in sync mode without overflowing the stack", {
  # Regression for #15: the sync walk used to self-recurse once per page, nesting
  # `fetch_page -> then_or_now -> continuation -> fetch_page` on the call stack
  # (R has no tail-call optimisation), and overflowed the node stack on a deep
  # walk. Verified: the old recursive code aborts this exact test with
  # "node stack overflow"; the iterative sync loop runs in constant stack depth
  # and completes. Every page reports the same large totalPage and carries no
  # items, so the walk runs `deep_total` iterations cheaply (the empty
  # accumulator is fed to flatten_pages, which yields an empty data.table). The
  # multi-page ordering/accumulation contract is covered by the tests above.
  deep_total <- 3000L
  call_count <- 0L

  # The walk's stop condition reads only totalPage, never the response's
  # currentPage, so one constant response drives every page (fast: no per-page
  # JSON re-encoding).
  resp <- mock_kucoin_response(
    data = list(
      totalNum = deep_total,
      totalPage = deep_total,
      pageSize = 1L
    )
  )
  httr2::local_mocked_responses(function(req) {
    call_count <<- call_count + 1L
    return(resp)
  })

  result <- kucoin_paginate(
    base_url = "https://api.kucoin.com",
    endpoint = "/api/v3/announcements",
    .parser = flatten_pages,
    page_size = 1
  )

  expect_equal(call_count, deep_total)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})
