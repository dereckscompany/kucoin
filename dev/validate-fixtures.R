#!/usr/bin/env Rscript
# dev/validate-fixtures.R
# Compare each committed fixture's `data` record keys against the matching real
# capture under local/raw-data/kucoin/. Reports MATCH / DIVERGENCE per fixture.
suppressWarnings(suppressMessages(library(jsonlite)))

FIX <- "tests/testthat/fixtures"
RAW <- "local/raw-data/kucoin"

# fixture basename -> capture basename (only where they differ or need mapping).
map <- c(
  sub_accounts_page = "sub_accounts_list",
  orderbook = "orderbook",
  futures_orderbook = "futures_orderbook"
)
# Fixtures that are WRITE/POST responses or otherwise have no GET capture.
no_capture <- c(
  "cancel_order", "order_response", "oco_order_response", "stop_order_response",
  "margin_order_response", "margin_borrow_response", "margin_repay_response",
  "purchase_response", "redeem_response", "futures_order_response",
  "futures_cancel_order", "futures_margin_response", "futures_dcp",
  "sub_accounts_empty_page", "empty", "futures_order_detail", "futures_order_list",
  "futures_fills", "futures_positions_history"
)

# Pull the representative record(s) from a parsed KuCoin envelope's `data`.
record_keys <- function(parsed) {
  d <- parsed$data
  if (is.null(d)) return(list(kind = "null", keys = character()))
  # Paginated: data$items is an array of records.
  if (is.list(d) && !is.null(d$items)) {
    items <- d$items
    if (length(items) == 0L) return(list(kind = "items-empty", keys = character()))
    ks <- unique(unlist(lapply(items, names)))
    return(list(kind = "items", keys = ks))
  }
  # Array of records (unnamed list of named lists).
  if (is.list(d) && is.null(names(d)) && length(d) > 0L && is.list(d[[1]])) {
    ks <- unique(unlist(lapply(d, function(x) if (is.list(x)) names(x) else NULL)))
    return(list(kind = "array", keys = ks))
  }
  # Single object.
  if (is.list(d) && !is.null(names(d))) {
    return(list(kind = "object", keys = names(d)))
  }
  return(list(kind = "scalar/other", keys = character()))
}

fix_files <- list.files(FIX, pattern = "\\.json$", full.names = FALSE)
cat(sprintf("%-28s %-14s %s\n", "FIXTURE", "STATUS", "DETAIL"))
cat(strrep("-", 100), "\n")

for (f in sort(fix_files)) {
  base <- sub("\\.json$", "", f)
  if (base %in% no_capture) {
    cat(sprintf("%-28s %-14s %s\n", base, "SKIP", "(write/no-GET-capture or synthetic)"))
    next
  }
  cap_base <- if (!is.na(map[base])) map[base] else base
  cap_path <- file.path(RAW, paste0(cap_base, ".json"))
  if (!file.exists(cap_path)) {
    cat(sprintf("%-28s %-14s %s\n", base, "NO-CAPTURE", cap_path))
    next
  }
  fx <- tryCatch(jsonlite::fromJSON(file.path(FIX, f), simplifyVector = FALSE), error = function(e) NULL)
  cp <- tryCatch(jsonlite::fromJSON(cap_path, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(fx) || is.null(cp)) {
    cat(sprintf("%-28s %-14s %s\n", base, "PARSE-ERR", ""))
    next
  }
  fk <- record_keys(fx)
  ck <- record_keys(cp)
  if (ck$kind %in% c("items-empty", "null")) {
    cat(sprintf("%-28s %-14s capture-%s (no rows to compare)\n", base, "CAP-EMPTY", ck$kind))
    next
  }
  missing_in_fix <- setdiff(ck$keys, fk$keys) # real has, fixture lacks
  extra_in_fix <- setdiff(fk$keys, ck$keys)   # fixture has, real lacks
  if (length(missing_in_fix) == 0L && length(extra_in_fix) == 0L) {
    cat(sprintf("%-28s %-14s kind=%s keys=%d\n", base, "MATCH", ck$kind, length(ck$keys)))
  } else {
    cat(sprintf("%-28s %-14s kind=%s\n", base, "DIVERGE", ck$kind))
    if (length(missing_in_fix) > 0L) {
      cat("    + real-only (enrich fixture):", paste(missing_in_fix, collapse = ", "), "\n")
    }
    if (length(extra_in_fix) > 0L) {
      cat("    - fixture-only (not in real):", paste(extra_in_fix, collapse = ", "), "\n")
    }
  }
}
