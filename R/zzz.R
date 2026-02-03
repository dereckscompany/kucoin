# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  # Standardised datetime columns used in := assignments
  "datetime",
  "datetime_created",
  "datetime_updated",
  "datetime_order",
  # Raw API columns consumed then removed in := assignments
  "c_time",
  "time",
  "created_at",
  "last_updated_at",
  "order_time",
  # Orderbook / trade columns
  "sequence",
  "side",
  "price",
  "size",
  # Backfill columns
  "symbol",
  "freq"
))
