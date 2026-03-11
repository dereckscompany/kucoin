# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  # API timestamp columns coerced in-place via := assignments
  "c_time",
  "time",
  "created_at",
  "created_time",
  "last_updated_at",
  "order_time",
  "match_time",
  "apply_time",
  "global_time",
  # Orderbook / trade columns
  "sequence",
  "side",
  "price",
  "size",
  # Backfill / klines columns
  "datetime",
  "symbol",
  "timeframe",
  "freq",
  # Order columns
  "client_oid",
  # Sub-account columns
  "account_type",
  "sub_user_id",
  "sub_name",
  # Futures-specific columns
  "ts",
  "time_point",
  "funding_time",
  "timepoint",
  "trade_time",
  "updated_at",
  "opening_timestamp",
  "current_timestamp",
  "open_time",
  "close_time"
))
