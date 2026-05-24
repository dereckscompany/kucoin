# File: R/KucoinMarginTrading.R
# R6 class for KuCoin Margin trading: order placement, borrowing, repaying.

#' KucoinMarginTrading: Margin Order and Debit Management
#'
#' Provides intent-based methods for margin trading on KuCoin. Instead of
#' raw `side = "buy"` / `side = "sell"` parameters (which are ambiguous in a
#' margin context), this class exposes four clear actions:
#'
#' - **`open_long()`**: Buy an asset with borrowed funds (leveraged long).
#' - **`close_long()`**: Sell a previously-bought asset and repay the loan.
#' - **`open_short()`**: Borrow and sell an asset you don't own (short sell).
#' - **`close_short()`**: Buy back a previously-shorted asset and repay the loan.
#'
#' Additionally provides methods for manual borrowing, repaying, interest
#' queries, and leverage configuration. Inherits from [KucoinBase].
#'
#' ### How Margin Short Selling Works
#' 1. **`open_short()`** borrows the base asset (e.g. BTC) and immediately
#'    sells it at market price. You now hold the proceeds (e.g. USDT) but
#'    owe the borrowed BTC plus interest.
#' 2. If the price drops, **`close_short()`** buys back the asset at the
#'    lower price and automatically repays the loan. The difference is profit.
#' 3. If the price rises instead, you lose money — margin trading carries
#'    liquidation risk.
#'
#' ### Cross vs Isolated Margin
#' - **Cross margin** (default): All margin positions share the same collateral
#'   pool. A loss in one pair can be offset by gains in another, but a
#'   liquidation affects your entire margin account.
#' - **Isolated margin** (`isIsolated = TRUE`): Each trading pair has its own
#'   collateral. Losses are contained to that pair, but you need to allocate
#'   collateral per pair.
#'
#' ### Usage
#' All methods require authentication (valid API key, secret, passphrase)
#' with Margin permission enabled.
#'
#' ### Official Documentation
#' [KuCoin Margin Trading](https://www.kucoin.com/docs-new/rest/margin-trading/orders/add-order)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | open_long / close_long / open_short / close_short | POST /api/v3/hf/margin/order | POST |
#' | borrow | POST /api/v3/margin/borrow | POST |
#' | repay | POST /api/v3/margin/repay | POST |
#' | get_borrow_history | GET /api/v3/margin/borrow | GET |
#' | get_repay_history | GET /api/v3/margin/repay | GET |
#' | get_interest_history | GET /api/v3/margin/interest | GET |
#' | get_borrow_rate | GET /api/v3/margin/borrowRate | GET |
#' | modify_leverage | POST /api/v3/position/update-user-leverage | POST |
#'
#' @examples
#' \dontrun{
#' margin <- KucoinMarginTrading$new()
#'
#' # --- Short selling workflow ---
#' # 1. Open short: borrow BTC and sell it immediately
#' order <- margin$open_short(symbol = "BTC-USDT", size = 0.001)
#' print(order)
#'
#' # 2. Close short: buy back BTC and repay the loan
#' order <- margin$close_short(symbol = "BTC-USDT", size = 0.001)
#' print(order)
#'
#' # --- Leveraged long workflow ---
#' # 1. Open long: borrow USDT and buy BTC with it
#' order <- margin$open_long(symbol = "BTC-USDT", size = 0.001)
#' print(order)
#'
#' # 2. Close long: sell BTC and repay borrowed USDT
#' order <- margin$close_long(symbol = "BTC-USDT", size = 0.001)
#' print(order)
#'
#' # --- Manual borrow/repay ---
#' loan <- margin$borrow(currency = "USDT", size = 100)
#' margin$repay(currency = "USDT", size = 100)
#'
#' # --- Check rates before trading ---
#' rates <- margin$get_borrow_rate(query = list(currency = "BTC,USDT"))
#' print(rates)
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinMarginTrading <- R6::R6Class(
  "KucoinMarginTrading",
  inherit = KucoinBase,
  public = list(
    # ---- Position Opening ----

    #' @description
    #' Open a Short Position (Borrow and Sell)
    #'
    #' Borrows the base asset and sells it immediately. This is how you bet
    #' that an asset's price will go **down**. The exchange automatically
    #' borrows the asset you are selling (you don't need to call `borrow()`
    #' separately).
    #'
    #' **What happens under the hood:**
    #' 1. KuCoin borrows the base asset (e.g. BTC) on your behalf.
    #' 2. That borrowed asset is immediately sold on the market.
    #' 3. You now owe the borrowed amount plus interest.
    #' 4. Use `close_short()` later to buy it back and repay.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/hf/margin/order`
    #'
    #' ### Official Documentation
    #' [KuCoin Margin Add Order](https://www.kucoin.com/docs-new/rest/margin-trading/orders/add-order)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/hf/margin/order' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"clientOid":"my-short-001","side":"sell","symbol":"BTC-USDT","type":"market","size":"0.001","autoBorrow":true,"autoRepay":false}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "clientOid": "my-short-001",
    #'   "side": "sell",
    #'   "symbol": "BTC-USDT",
    #'   "type": "market",
    #'   "size": "0.001",
    #'   "autoBorrow": true,
    #'   "autoRepay": false
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "6745e8f3a7b2c1d4e5f6a7b8",
    #'     "clientOid": "my-short-001",
    #'     "borrowSize": "0.001",
    #'     "loanApplyId": "7856f9a4b8c3d2e5f6a7b8c9"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair to short (e.g., `"BTC-USDT"`).
    #'   You will borrow and sell the base currency (BTC in this example).
    #' @param size Numeric or NULL; quantity of the base asset to short.
    #'   For market orders, specify either `size` (base qty) or `funds` (quote qty), not both.
    #' @param funds Numeric or NULL; amount in quote currency to receive from the short sale.
    #'   Only for market orders; mutually exclusive with `size`.
    #' @param type Character; `"limit"` or `"market"` (default `"market"`).
    #' @param price Numeric or NULL; required for limit orders. The price at which to sell.
    #' @param isIsolated Logical; `TRUE` for isolated margin (risk limited to this pair),
    #'   `FALSE` (default) for cross margin (shared collateral pool).
    #' @param clientOid Character or NULL; your own unique order ID (max 40 chars).
    #'   Auto-generated if not provided (required by KuCoin for margin orders).
    #' @param stp Character or NULL; self-trade prevention: `"CN"`, `"CO"`, `"CB"`, `"DC"`.
    #' @param remark Character or NULL; order remark (max 20 ASCII chars).
    #' @param timeInForce Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.
    #' @param cancelAfter Numeric or NULL; auto-cancel seconds (requires `timeInForce = "GTT"`).
    #' @param postOnly Logical or NULL; if TRUE, order rejected if it would match immediately.
    #' @param hidden Logical or NULL; if TRUE, order hidden from order book.
    #' @param iceberg Logical or NULL; if TRUE, only `visibleSize` is shown.
    #' @param visibleSize Numeric or NULL; visible quantity for iceberg orders.
    #' @param dry_run Logical; if `TRUE`, validates the order without actually placing it.
    #'   Useful for testing your parameters. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned order identifier.
    #'   - `client_oid` (character): Client-provided order identifier.
    #'   - `borrow_size` (character): Amount borrowed.
    #'   - `loan_apply_id` (character): Loan application ID.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #'
    #' # Market short: sell 0.001 BTC you don't own
    #' order <- margin$open_short(symbol = "BTC-USDT", size = 0.001)
    #'
    #' # Limit short: sell at a specific price
    #' order <- margin$open_short(
    #'   symbol = "BTC-USDT", type = "limit",
    #'   price = 100000, size = 0.001
    #' )
    #'
    #' # Dry run (test without placing)
    #' margin$open_short(symbol = "BTC-USDT", size = 0.001, dry_run = TRUE)
    #' }
    open_short = function(
      symbol,
      size = NULL,
      funds = NULL,
      type = "market",
      price = NULL,
      isIsolated = FALSE,
      clientOid = NULL,
      stp = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL,
      dry_run = FALSE
    ) {
      return(private$.add_order(
        side = "sell",
        auto_borrow = TRUE,
        auto_repay = FALSE,
        symbol = symbol,
        size = size,
        funds = funds,
        type = type,
        price = price,
        isIsolated = isIsolated,
        clientOid = clientOid,
        stp = stp,
        remark = remark,
        timeInForce = timeInForce,
        cancelAfter = cancelAfter,
        postOnly = postOnly,
        hidden = hidden,
        iceberg = iceberg,
        visibleSize = visibleSize,
        dry_run = dry_run
      ))
    },

    #' @description
    #' Close a Short Position (Buy Back and Repay)
    #'
    #' Buys back the base asset and automatically repays the loan. This
    #' closes a short position opened with `open_short()`.
    #'
    #' **What happens under the hood:**
    #' 1. KuCoin buys the base asset (e.g. BTC) on the market.
    #' 2. The purchased asset is automatically used to repay your loan.
    #' 3. If the price dropped since you opened the short, you profit.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/hf/margin/order`
    #'
    #' ### Official Documentation
    #' [KuCoin Margin Add Order](https://www.kucoin.com/docs-new/rest/margin-trading/orders/add-order)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/hf/margin/order' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"clientOid":"my-close-short-001","side":"buy","symbol":"BTC-USDT","type":"market","size":"0.001","autoBorrow":false,"autoRepay":true}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "clientOid": "my-close-short-001",
    #'   "side": "buy",
    #'   "symbol": "BTC-USDT",
    #'   "type": "market",
    #'   "size": "0.001",
    #'   "autoBorrow": false,
    #'   "autoRepay": true
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "6745e8f3a7b2c1d4e5f6a7b9",
    #'     "clientOid": "my-close-short-001"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair to close (must match the pair you shorted).
    #' @param size Numeric or NULL; quantity of the base asset to buy back.
    #'   Should match the size you shorted. For market orders, specify either
    #'   `size` or `funds`, not both.
    #' @param funds Numeric or NULL; amount in quote currency to spend buying back.
    #'   Only for market orders; mutually exclusive with `size`.
    #' @param type Character; `"limit"` or `"market"` (default `"market"`).
    #' @param price Numeric or NULL; required for limit orders.
    #' @param isIsolated Logical; must match the margin mode used in `open_short()`.
    #' @param clientOid Character or NULL; your own unique order ID.
    #' @param stp Character or NULL; self-trade prevention.
    #' @param remark Character or NULL; order remark.
    #' @param timeInForce Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.
    #' @param cancelAfter Numeric or NULL; auto-cancel seconds.
    #' @param postOnly Logical or NULL; passive order flag.
    #' @param hidden Logical or NULL; hidden order flag.
    #' @param iceberg Logical or NULL; iceberg order flag.
    #' @param visibleSize Numeric or NULL; visible quantity for iceberg.
    #' @param dry_run Logical; if `TRUE`, validates without placing. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned order identifier.
    #'   - `client_oid` (character): Client-provided order identifier (NA if not supplied).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' order <- margin$close_short(symbol = "BTC-USDT", size = 0.001)
    #' print(order)
    #' }
    close_short = function(
      symbol,
      size = NULL,
      funds = NULL,
      type = "market",
      price = NULL,
      isIsolated = FALSE,
      clientOid = NULL,
      stp = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL,
      dry_run = FALSE
    ) {
      return(private$.add_order(
        side = "buy",
        auto_borrow = FALSE,
        auto_repay = TRUE,
        symbol = symbol,
        size = size,
        funds = funds,
        type = type,
        price = price,
        isIsolated = isIsolated,
        clientOid = clientOid,
        stp = stp,
        remark = remark,
        timeInForce = timeInForce,
        cancelAfter = cancelAfter,
        postOnly = postOnly,
        hidden = hidden,
        iceberg = iceberg,
        visibleSize = visibleSize,
        dry_run = dry_run
      ))
    },

    #' @description
    #' Open a Leveraged Long Position (Borrow and Buy)
    #'
    #' Borrows quote currency (e.g. USDT) and uses it to buy the base asset
    #' (e.g. BTC). This is how you take a leveraged bet that an asset's
    #' price will go **up**. The exchange automatically borrows the funds
    #' needed.
    #'
    #' **What happens under the hood:**
    #' 1. KuCoin borrows the quote currency (e.g. USDT) on your behalf.
    #' 2. That borrowed currency is used to buy the base asset.
    #' 3. You now hold the asset but owe the borrowed amount plus interest.
    #' 4. Use `close_long()` later to sell and repay.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/hf/margin/order`
    #'
    #' ### Official Documentation
    #' [KuCoin Margin Add Order](https://www.kucoin.com/docs-new/rest/margin-trading/orders/add-order)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/hf/margin/order' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"clientOid":"my-long-001","side":"buy","symbol":"BTC-USDT","type":"market","size":"0.001","autoBorrow":true,"autoRepay":false}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "clientOid": "my-long-001",
    #'   "side": "buy",
    #'   "symbol": "BTC-USDT",
    #'   "type": "market",
    #'   "size": "0.001",
    #'   "autoBorrow": true,
    #'   "autoRepay": false
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "6745e8f3a7b2c1d4e5f6a7c0",
    #'     "clientOid": "my-long-001",
    #'     "borrowSize": "95.50",
    #'     "loanApplyId": "7856f9a4b8c3d2e5f6a7b8d0"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair to go long on (e.g., `"BTC-USDT"`).
    #'   You will borrow quote currency (USDT) and buy the base (BTC).
    #' @param size Numeric or NULL; quantity of the base asset to buy.
    #' @param funds Numeric or NULL; amount in quote currency to spend.
    #'   Only for market orders; mutually exclusive with `size`.
    #' @param type Character; `"limit"` or `"market"` (default `"market"`).
    #' @param price Numeric or NULL; required for limit orders.
    #' @param isIsolated Logical; `TRUE` for isolated margin, `FALSE` (default) for cross.
    #' @param clientOid Character or NULL; your own unique order ID.
    #' @param stp Character or NULL; self-trade prevention.
    #' @param remark Character or NULL; order remark.
    #' @param timeInForce Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.
    #' @param cancelAfter Numeric or NULL; auto-cancel seconds.
    #' @param postOnly Logical or NULL; passive order flag.
    #' @param hidden Logical or NULL; hidden order flag.
    #' @param iceberg Logical or NULL; iceberg order flag.
    #' @param visibleSize Numeric or NULL; visible quantity for iceberg.
    #' @param dry_run Logical; if `TRUE`, validates without placing. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned order identifier.
    #'   - `client_oid` (character): Client-provided order identifier.
    #'   - `borrow_size` (character): Amount borrowed.
    #'   - `loan_apply_id` (character): Loan application ID.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #'
    #' # Market long: buy 0.001 BTC with borrowed USDT
    #' order <- margin$open_long(symbol = "BTC-USDT", size = 0.001)
    #'
    #' # Limit long: buy at a specific price
    #' order <- margin$open_long(
    #'   symbol = "BTC-USDT", type = "limit",
    #'   price = 50000, size = 0.001
    #' )
    #' }
    open_long = function(
      symbol,
      size = NULL,
      funds = NULL,
      type = "market",
      price = NULL,
      isIsolated = FALSE,
      clientOid = NULL,
      stp = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL,
      dry_run = FALSE
    ) {
      return(private$.add_order(
        side = "buy",
        auto_borrow = TRUE,
        auto_repay = FALSE,
        symbol = symbol,
        size = size,
        funds = funds,
        type = type,
        price = price,
        isIsolated = isIsolated,
        clientOid = clientOid,
        stp = stp,
        remark = remark,
        timeInForce = timeInForce,
        cancelAfter = cancelAfter,
        postOnly = postOnly,
        hidden = hidden,
        iceberg = iceberg,
        visibleSize = visibleSize,
        dry_run = dry_run
      ))
    },

    #' @description
    #' Close a Leveraged Long Position (Sell and Repay)
    #'
    #' Sells the base asset and automatically repays the borrowed quote
    #' currency. This closes a long position opened with `open_long()`.
    #'
    #' **What happens under the hood:**
    #' 1. KuCoin sells the base asset (e.g. BTC) on the market.
    #' 2. The proceeds are automatically used to repay your loan.
    #' 3. If the price rose since you opened the long, you profit.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/hf/margin/order`
    #'
    #' ### Official Documentation
    #' [KuCoin Margin Add Order](https://www.kucoin.com/docs-new/rest/margin-trading/orders/add-order)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/hf/margin/order' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"clientOid":"my-close-long-001","side":"sell","symbol":"BTC-USDT","type":"market","size":"0.001","autoBorrow":false,"autoRepay":true}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "clientOid": "my-close-long-001",
    #'   "side": "sell",
    #'   "symbol": "BTC-USDT",
    #'   "type": "market",
    #'   "size": "0.001",
    #'   "autoBorrow": false,
    #'   "autoRepay": true
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderId": "6745e8f3a7b2c1d4e5f6a7c1",
    #'     "clientOid": "my-close-long-001"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; trading pair to close (must match the pair you longed).
    #' @param size Numeric or NULL; quantity of the base asset to sell.
    #' @param funds Numeric or NULL; amount in quote currency.
    #'   Only for market orders; mutually exclusive with `size`.
    #' @param type Character; `"limit"` or `"market"` (default `"market"`).
    #' @param price Numeric or NULL; required for limit orders.
    #' @param isIsolated Logical; must match the margin mode used in `open_long()`.
    #' @param clientOid Character or NULL; your own unique order ID.
    #' @param stp Character or NULL; self-trade prevention.
    #' @param remark Character or NULL; order remark.
    #' @param timeInForce Character or NULL; `"GTC"`, `"GTT"`, `"IOC"`, `"FOK"`.
    #' @param cancelAfter Numeric or NULL; auto-cancel seconds.
    #' @param postOnly Logical or NULL; passive order flag.
    #' @param hidden Logical or NULL; hidden order flag.
    #' @param iceberg Logical or NULL; iceberg order flag.
    #' @param visibleSize Numeric or NULL; visible quantity for iceberg.
    #' @param dry_run Logical; if `TRUE`, validates without placing. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_id` (character): KuCoin-assigned order identifier.
    #'   - `client_oid` (character): Client-provided order identifier (NA if not supplied).
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' order <- margin$close_long(symbol = "BTC-USDT", size = 0.001)
    #' print(order)
    #' }
    close_long = function(
      symbol,
      size = NULL,
      funds = NULL,
      type = "market",
      price = NULL,
      isIsolated = FALSE,
      clientOid = NULL,
      stp = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL,
      dry_run = FALSE
    ) {
      return(private$.add_order(
        side = "sell",
        auto_borrow = FALSE,
        auto_repay = TRUE,
        symbol = symbol,
        size = size,
        funds = funds,
        type = type,
        price = price,
        isIsolated = isIsolated,
        clientOid = clientOid,
        stp = stp,
        remark = remark,
        timeInForce = timeInForce,
        cancelAfter = cancelAfter,
        postOnly = postOnly,
        hidden = hidden,
        iceberg = iceberg,
        visibleSize = visibleSize,
        dry_run = dry_run
      ))
    },

    # ---- Borrowing & Repaying ----

    #' @description
    #' Borrow Assets for Margin Trading
    #'
    #' Manually borrows a specified amount of a currency for margin trading.
    #' You typically don't need this if you use `open_short()` or
    #' `open_long()` which auto-borrow for you. Use this for advanced
    #' workflows where you want explicit control over the borrow/trade/repay
    #' lifecycle.
    #'
    #' ### Workflow
    #' 1. **Validation**: Checks required fields and types.
    #' 2. **Request**: Authenticated POST to borrow endpoint.
    #' 3. **Parsing**: Returns `data.table` with loan details.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/margin/borrow`
    #'
    #' ### Official Documentation
    #' [KuCoin Margin Borrow](https://www.kucoin.com/docs-new/rest/margin-trading/debit/borrow)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/margin/borrow' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"currency":"USDT","size":"100","timeInForce":"IOC","isIsolated":false,"isHf":false}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "currency": "USDT",
    #'   "size": "100",
    #'   "timeInForce": "IOC",
    #'   "isIsolated": false,
    #'   "isHf": false
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "orderNo": "abc123",
    #'     "actualSize": "100"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency Character; the currency to borrow (e.g., `"USDT"`, `"BTC"`).
    #' @param size Numeric; the amount to borrow.
    #' @param timeInForce Character; order time-in-force policy (default `"IOC"`).
    #'   Valid values: `"IOC"` (immediate-or-cancel), `"FOK"` (fill-or-kill).
    #' @param isIsolated Logical; `TRUE` for isolated margin, `FALSE` (default) for cross.
    #' @param symbol Character or NULL; required when `isIsolated = TRUE`. Trading pair (e.g., `"BTC-USDT"`).
    #' @param isHf Logical; `TRUE` for high-frequency trading mode, `FALSE` (default).
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `order_no` (character): Borrow order number.
    #'   - `actual_size` (character): Amount actually borrowed.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #'
    #' # Cross margin borrow
    #' loan <- margin$borrow(currency = "USDT", size = 100)
    #' print(loan)
    #'
    #' # Isolated margin borrow
    #' loan <- margin$borrow(
    #'   currency = "BTC", size = 0.01,
    #'   isIsolated = TRUE, symbol = "BTC-USDT"
    #' )
    #' }
    borrow = function(
      currency,
      size,
      timeInForce = "IOC",
      isIsolated = FALSE,
      symbol = NULL,
      isHf = FALSE
    ) {
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.numeric(size) || size <= 0) {
        rlang::abort("Parameter 'size' must be a positive number.")
      }
      if (isTRUE(isIsolated) && (is.null(symbol) || !verify_symbol(symbol))) {
        rlang::abort("Parameter 'symbol' is required and must be a valid ticker when 'isIsolated' is TRUE.")
      }

      body <- list(
        currency = currency,
        size = as.character(size),
        timeInForce = timeInForce,
        isIsolated = isIsolated,
        symbol = symbol,
        isHf = isHf
      )
      body <- body[!vapply(body, is.null, logical(1))]

      return(private$.request(
        endpoint = "/api/v3/margin/borrow",
        method = "POST",
        body = body,
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Repay Borrowed Assets
    #'
    #' Manually repays a specified amount of a borrowed currency. You
    #' typically don't need this if you use `close_short()` or
    #' `close_long()` which auto-repay for you. Use this for advanced
    #' workflows or to repay interest independently.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/margin/repay`
    #'
    #' ### Official Documentation
    #' [KuCoin Margin Repay](https://www.kucoin.com/docs-new/rest/margin-trading/debit/repay)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/margin/repay' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"currency":"USDT","size":"100"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "currency": "USDT",
    #'   "size": "100"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "timestamp": 1729655606816,
    #'     "orderNo": "abc123",
    #'     "actualSize": "100"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency Character; the currency to repay (e.g., `"USDT"`, `"BTC"`).
    #' @param size Numeric; the amount to repay.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`)
    #'   with a single row and columns:
    #'   - `timestamp` (POSIXct): Server-side acceptance time of the repay.
    #'   - `order_no` (character): Repayment order number.
    #'   - `actual_size` (character): Amount actually repaid.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' result <- margin$repay(currency = "USDT", size = 100)
    #' print(result)
    #' }
    repay = function(currency, size) {
      if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("Parameter 'currency' must be a non-empty string.")
      }
      if (!is.numeric(size) || size <= 0) {
        rlang::abort("Parameter 'size' must be a positive number.")
      }

      body <- list(
        currency = currency,
        size = as.character(size)
      )

      return(private$.request(
        endpoint = "/api/v3/margin/repay",
        method = "POST",
        body = body,
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, "timestamp", ms_to_datetime)
          return(dt[])
        }
      ))
    },

    # ---- History & Queries ----

    #' @description
    #' Get Borrow History
    #'
    #' Retrieves paginated borrow history records.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/borrow`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Borrow History](https://www.kucoin.com/docs-new/rest/margin-trading/debit/get-borrow-history)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/borrow?currency=USDT&currentPage=1&pageSize=50' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "currentPage": 1,
    #'     "pageSize": 50,
    #'     "totalNum": 1,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "orderNo": "abc123456",
    #'         "symbol": "BTC-USDT",
    #'         "currency": "USDT",
    #'         "size": "100",
    #'         "actualSize": "100",
    #'         "status": "DONE",
    #'         "createdTime": 1729577515473
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `currency` (character): Filter by currency.
    #'   - `isIsolated` (logical): Filter by margin type.
    #'   - `symbol` (character): Filter by trading pair.
    #'   - `orderNo` (character): Filter by order number.
    #'   - `startTime` (integer): Start timestamp in milliseconds.
    #'   - `endTime` (integer): End timestamp in milliseconds.
    #'   - `currentPage` (integer): Page number.
    #'   - `pageSize` (integer): Items per page.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`)
    #'   with **one row per borrow record** and columns:
    #'   - `order_no` (character): Borrow order number.
    #'   - `symbol` (character): Trading pair (NA on cross-margin records).
    #'   - `currency` (character): Borrowed currency.
    #'   - `size` (character): Requested borrow amount.
    #'   - `actual_size` (character): Amount actually borrowed.
    #'   - `status` (character): Lifecycle status (e.g. `"DONE"`).
    #'   - `created_time` (POSIXct): Borrow timestamp (millisecond epoch coerced).
    #'
    #'   Empty response yields an empty `data.table`.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' history <- margin$get_borrow_history(query = list(currency = "USDT"))
    #' print(history)
    #' }
    get_borrow_history = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/margin/borrow",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
          if ("created_time" %in% names(dt)) {
            dt[, created_time := ms_to_datetime(created_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Repay History
    #'
    #' Retrieves paginated repayment history records.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/repay`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Repay History](https://www.kucoin.com/docs-new/rest/margin-trading/debit/get-repay-history)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/repay?currency=USDT&currentPage=1&pageSize=50' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "currentPage": 1,
    #'     "pageSize": 50,
    #'     "totalNum": 1,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "orderNo": "def456789",
    #'         "symbol": "BTC-USDT",
    #'         "currency": "USDT",
    #'         "size": "100",
    #'         "actualSize": "100",
    #'         "status": "DONE",
    #'         "createdTime": 1729577815473
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Same keys as `get_borrow_history()`.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`)
    #'   with **one row per repay record** and columns:
    #'   - `order_no` (character): Repay order number.
    #'   - `symbol` (character): Trading pair (NA on cross-margin records).
    #'   - `currency` (character): Repaid currency.
    #'   - `size` (character): Requested repay amount.
    #'   - `actual_size` (character): Amount actually repaid.
    #'   - `status` (character): Lifecycle status.
    #'   - `created_time` (POSIXct): Repay timestamp (millisecond epoch coerced).
    #'
    #'   Empty response yields an empty `data.table`.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' history <- margin$get_repay_history(query = list(currency = "USDT"))
    #' print(history)
    #' }
    get_repay_history = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/margin/repay",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
          if ("created_time" %in% names(dt)) {
            dt[, created_time := ms_to_datetime(created_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Interest History
    #'
    #' Retrieves paginated interest accrual history for margin borrowing.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/interest`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Interest History](https://www.kucoin.com/docs-new/rest/margin-trading/debit/get-interest-history)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/interest?currency=USDT&currentPage=1&pageSize=50' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "currentPage": 1,
    #'     "pageSize": 50,
    #'     "totalNum": 1,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "currency": "USDT",
    #'         "dayRatio": "0.0001",
    #'         "interestAmount": "0.01",
    #'         "createdTime": 1729577515473
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `currency` (character): Filter by currency.
    #'   - `isIsolated` (logical): Cross vs isolated.
    #'   - `symbol` (character): Trading pair.
    #'   - `startTime` (integer): Start timestamp in milliseconds.
    #'   - `endTime` (integer): End timestamp in milliseconds.
    #'   - `currentPage` (integer): Page number.
    #'   - `pageSize` (integer): Items per page.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`)
    #'   with **one row per interest record** and columns:
    #'   - `currency` (character): Currency on which interest accrued.
    #'   - `day_ratio` (character): Daily rate applied.
    #'   - `interest_amount` (character): Interest charged in the period.
    #'   - `created_time` (POSIXct): Accrual timestamp (millisecond epoch coerced).
    #'
    #'   Empty response yields an empty `data.table`.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' interest <- margin$get_interest_history(query = list(currency = "USDT"))
    #' print(interest)
    #' }
    get_interest_history = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/margin/interest",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
          if ("created_time" %in% names(dt)) {
            dt[, created_time := ms_to_datetime(created_time)]
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Borrow Interest Rate
    #'
    #' Retrieves current borrow interest rates for one or more currencies.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/borrowRate`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Borrow Interest Rate](https://www.kucoin.com/docs-new/rest/margin-trading/debit/get-borrow-interest-rate)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/borrowRate?currency=BTC,USDT' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "currency": "BTC",
    #'       "hourlyBorrowRate": "0.000004",
    #'       "annualizedBorrowRate": "0.035"
    #'     },
    #'     {
    #'       "currency": "USDT",
    #'       "hourlyBorrowRate": "0.000006",
    #'       "annualizedBorrowRate": "0.0526"
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param query Named list; optional filter parameters. Supported keys:
    #'   - `currency` (character): Comma-separated currency list (e.g., `"BTC,USDT"`).
    #'   - `vipLevel` (integer): VIP tier level.
    #' @return `data.table` (or `promise<data.table>` if constructed with `async = TRUE`) with columns:
    #'   - `currency` (character): Currency code.
    #'   - `hourly_borrow_rate` (character): Hourly interest rate.
    #'   - `annualized_borrow_rate` (character): Annualized interest rate.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' rates <- margin$get_borrow_rate(query = list(currency = "BTC,USDT,ETH"))
    #' print(rates)
    #' }
    get_borrow_rate = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v3/margin/borrowRate",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)[])
        }
      ))
    },

    # ---- Configuration ----

    #' @description
    #' Modify Leverage
    #'
    #' Updates the leverage multiplier for the margin account. Higher
    #' leverage means you can borrow more relative to your collateral,
    #' but also increases liquidation risk.
    #'
    #' ### API Endpoint
    #' `POST https://api.kucoin.com/api/v3/position/update-user-leverage`
    #'
    #' ### Official Documentation
    #' [KuCoin Modify Leverage](https://www.kucoin.com/docs-new/rest/margin-trading/debit/modify-leverage)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api.kucoin.com/api/v3/position/update-user-leverage' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"leverage":"5"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "leverage": "5"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": null
    #' }
    #' ```
    #'
    #' @param leverage Numeric; the desired leverage multiplier (e.g., `3`, `5`, `10`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row with columns:
    #'   - `leverage` (numeric): The new leverage multiplier.
    #'   - `status` (character): `"success"`.
    #'
    #' @examples
    #' \dontrun{
    #' margin <- KucoinMarginTrading$new()
    #' margin$modify_leverage(leverage = 5)
    #' }
    modify_leverage = function(leverage) {
      if (!is.numeric(leverage) || leverage <= 0) {
        rlang::abort("Parameter 'leverage' must be a positive number.")
      }

      body <- list(leverage = as.character(leverage))

      return(private$.request(
        endpoint = "/api/v3/position/update-user-leverage",
        method = "POST",
        body = body,
        .parser = function(data) {
          return(data.table::data.table(
            leverage = leverage,
            status = "success"
          )[])
        }
      ))
    }
  ),
  private = list(
    # Internal: Place a Margin Order
    #
    # Low-level method that maps directly to the KuCoin margin order API.
    # Not exposed publicly because the raw side/autoBorrow/autoRepay
    # parameters are ambiguous. Use the public convenience methods instead:
    # open_short(), close_short(), open_long(), close_long().
    #
    # @param side Character; "buy" or "sell" (set by calling method).
    # @param auto_borrow Logical; whether to auto-borrow (set by calling method).
    # @param auto_repay Logical; whether to auto-repay (set by calling method).
    # @param dry_run Logical; if TRUE, use test endpoint.
    # @param ... All other order parameters forwarded to validate_margin_order_params().
    .add_order = function(
      side,
      auto_borrow,
      auto_repay,
      symbol,
      size = NULL,
      funds = NULL,
      type = "market",
      price = NULL,
      isIsolated = FALSE,
      clientOid = NULL,
      stp = NULL,
      remark = NULL,
      timeInForce = NULL,
      cancelAfter = NULL,
      postOnly = NULL,
      hidden = NULL,
      iceberg = NULL,
      visibleSize = NULL,
      dry_run = FALSE
    ) {
      body <- validate_margin_order_params(
        type = type,
        symbol = symbol,
        side = side,
        clientOid = clientOid,
        price = price,
        size = size,
        funds = funds,
        stp = stp,
        remark = remark,
        timeInForce = timeInForce,
        cancelAfter = cancelAfter,
        postOnly = postOnly,
        hidden = hidden,
        iceberg = iceberg,
        visibleSize = visibleSize,
        isIsolated = {
          val <- NULL
          if (isTRUE(isIsolated)) {
            val <- TRUE
          }
          val
        },
        autoBorrow = {
          val <- NULL
          if (isTRUE(auto_borrow)) {
            val <- TRUE
          }
          val
        },
        autoRepay = {
          val <- NULL
          if (isTRUE(auto_repay)) {
            val <- TRUE
          }
          val
        }
      )

      endpoint <- "/api/v3/hf/margin/order"
      if (isTRUE(dry_run)) {
        endpoint <- "/api/v3/hf/margin/order/test"
      }

      return(private$.request(
        endpoint = endpoint,
        method = "POST",
        body = body,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (is.null(dt$client_oid)) {
            dt[, client_oid := NA_character_]
          }
          cols <- intersect(
            c("order_id", "client_oid", "borrow_size", "loan_apply_id"),
            names(dt)
          )
          data.table::setcolorder(dt, cols)
          return(dt[])
        }
      ))
    }
  )
)
