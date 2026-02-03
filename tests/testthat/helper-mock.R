# tests/testthat/helper-mock.R
# Shared mock response builders for KuCoin API tests.
# Imports data fixtures from mockery.R and adds test-only helpers.

# NOTE: We source() mockery.R rather than box::use(./mockery) because
# helper files are source()'d by testthat, and box::use(./path) resolves
# relative to the *calling* script in `Rscript file.R` mode — not relative
# to this file — which breaks scripts/TEST.R.
source(file.path(testthat::test_path(), "mockery.R"), local = TRUE)

# Backward-compatible alias: existing tests use mock_kucoin_response
mock_kucoin_response <- mock_response

# ---------------------------------------------------------------------------
# Test-only helpers (not shared with README/vignettes)
# ---------------------------------------------------------------------------

#' Build a fake KuCoin error response
mock_kucoin_error <- function(code = "400100", msg = "Order not found", status_code = 200L) {
  body <- jsonlite::toJSON(
    list(code = code, msg = msg),
    auto_unbox = TRUE
  )
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

#' Build a fake HTTP error response (non-200 status)
mock_http_error <- function(status_code = 500L, body_text = "Internal Server Error") {
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "text/plain"),
    body = charToRaw(body_text)
  ))
}
