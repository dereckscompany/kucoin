# File: R/KucoinFuturesAccount.R
# R6 class for KuCoin Futures account and position management.

#' KucoinFuturesAccount: Futures Account and Position Management
#'
#' Provides methods for querying futures account details, managing positions,
#' configuring margin mode and leverage, and tracking funding fee history.
#' Inherits from [KucoinBase].
#'
#' ### Official Documentation
#' [KuCoin Futures Positions](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-details)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_account_overview | GET /api/v1/account-overview | GET |
#' | get_position | GET /api/v2/position | GET |
#' | get_positions | GET /api/v1/positions | GET |
#' | get_positions_history | GET /api/v1/history-positions | GET |
#' | get_margin_mode | GET /api/v1/marginMode | GET |
#' | set_margin_mode | POST /api/v1/marginMode | POST |
#' | get_cross_margin_leverage | GET /api/v1/crossMarginLeverage | GET |
#' | set_cross_margin_leverage | POST /api/v1/crossMarginLeverage | POST |
#' | get_max_open_size | GET /api/v1/maxOpenSize | GET |
#' | get_max_withdraw_margin | GET /api/v1/maxWithdrawMargin | GET |
#' | add_isolated_margin | POST /api/v1/marginDepositIn | POST |
#' | remove_isolated_margin | POST /api/v1/marginWithdrawOut | POST |
#' | get_risk_limit | GET /api/v1/contracts/risk-limit/\{symbol\} | GET |
#' | get_funding_history | GET /api/v1/funding-history | GET |
#'
#' @examples
#' \dontrun{
#' futures_account <- KucoinFuturesAccount$new()
#'
#' # Get account overview
#' overview <- futures_account$get_account_overview(currency = "USDT")
#'
#' # Get open positions
#' positions <- futures_account$get_positions()
#'
#' # Get position for a specific symbol
#' pos <- futures_account$get_position("XBTUSDTM")
#' }
#'
#' @export
KucoinFuturesAccount <- R6::R6Class(
  "KucoinFuturesAccount",
  inherit = KucoinBase,
  public = list(
    #' @description Create a new KucoinFuturesAccount instance.
    #' @param keys List; API credentials from [get_api_keys()].
    #' @param base_url Character; Futures API base URL. Defaults to [get_futures_base_url()].
    #' @param async Logical; if TRUE, methods return promises.
    #' @param time_source Character; `"local"` or `"server"`.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      return(super$initialize(keys = keys, base_url = base_url, async = async, time_source = time_source))
    },

    #' @description Get Account Overview
    #'
    #' Retrieves the futures account overview, including balance, equity,
    #' margin, and P&L.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `currency` query parameter.
    #' 2. **Parsing**: Returns a single-row `data.table` with account balance details.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/account-overview`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Futures Account Overview](https://www.kucoin.com/docs-new/rest/futures-trading/account/get-account-overview)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/account-overview?currency=USDT' \
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
    #'     "accountEquity": 99.8999305281,
    #'     "unrealisedPNL": 0,
    #'     "marginBalance": 99.8999305281,
    #'     "positionMargin": 0,
    #'     "orderMargin": 0,
    #'     "frozenFunds": 0,
    #'     "availableBalance": 99.8999305281,
    #'     "currency": "USDT"
    #'   }
    #' }
    #' ```
    #'
    #' @param currency Character; settlement currency (e.g., `"USDT"`).
    #'   Default `"USDT"`.
    #' @return A single-row `data.table` with columns:
    #'   - `account_equity` (numeric): Total account equity.
    #'   - `unrealised_pnl` (numeric): Unrealised profit and loss.
    #'   - `margin_balance` (numeric): Margin balance (equity + unrealised PNL).
    #'   - `position_margin` (numeric): Margin held by open positions.
    #'   - `order_margin` (numeric): Margin held by open orders.
    #'   - `frozen_funds` (numeric): Frozen funds.
    #'   - `available_balance` (numeric): Available balance for trading.
    #'   - `currency` (character): Settlement currency code.
    get_account_overview = function(currency = "USDT") {
      return(private$.request(
        endpoint = "/api/v1/account-overview",
        query = list(currency = currency),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Get Position Details
    #'
    #' Retrieves position details for a specific symbol.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` query parameter.
    #' 2. **Parsing**: Returns a single-row `data.table` with position details.
    #' 3. **Timestamp Conversion**: Coerces `opening_timestamp` and `current_timestamp` from milliseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v2/position`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Position Details](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-details)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v2/position?symbol=XBTUSDTM' \
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
    #'     "id": "615ba79f27adbe000854c352",
    #'     "symbol": "XBTUSDTM",
    #'     "autoDeposit": false,
    #'     "realLeverage": 2.05,
    #'     "crossMode": false,
    #'     "delevPercentage": 0.66,
    #'     "currentQty": 1,
    #'     "currentCost": "40.008",
    #'     "currentComm": "0.0240048",
    #'     "unrealisedCost": "40.008",
    #'     "realisedGrossCost": "0.0",
    #'     "realisedCost": "0.0240048",
    #'     "isOpen": true,
    #'     "markPrice": 40014.93,
    #'     "markValue": "40.01493",
    #'     "posCost": "40.008",
    #'     "posInit": "20.004",
    #'     "posComm": "0.02400588",
    #'     "posMargin": "20.02800588",
    #'     "unrealisedPnl": 0.00693,
    #'     "unrealisedPnlPcnt": 0.0002,
    #'     "avgEntryPrice": "40008.0",
    #'     "liquidationPrice": "20332.0",
    #'     "bankruptPrice": "20012.0",
    #'     "settleCurrency": "USDT",
    #'     "marginMode": "ISOLATED",
    #'     "openingTimestamp": 1729176273859,
    #'     "currentTimestamp": 1729176573859
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol (e.g., `"XBTUSDTM"`).
    #' @return A `data.table` with columns:
    #'   - `id` (character): Position identifier.
    #'   - `symbol` (character): Contract symbol.
    #'   - `real_leverage` (numeric): Effective leverage.
    #'   - `cross_mode` (logical): Whether cross margin mode is active.
    #'   - `current_qty` (integer): Current position size in contracts.
    #'   - `current_cost` (character): Cost of the current position.
    #'   - `is_open` (logical): Whether the position is open.
    #'   - `mark_price` (numeric): Current mark price.
    #'   - `mark_value` (character): Mark value of the position.
    #'   - `pos_margin` (character): Position margin.
    #'   - `unrealised_pnl` (numeric): Unrealised profit and loss.
    #'   - `avg_entry_price` (character): Average entry price.
    #'   - `liquidation_price` (character): Estimated liquidation price.
    #'   - `margin_mode` (character): `"ISOLATED"` or `"CROSS"`.
    #'   - `opening_timestamp` (POSIXct): Position opened time (coerced from milliseconds).
    #'   - `current_timestamp` (POSIXct): Current server time (coerced from milliseconds).
    get_position = function(symbol) {
      return(private$.request(
        endpoint = "/api/v2/position",
        query = list(symbol = symbol),
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "opening_timestamp" %in% names(dt)) {
            dt[, opening_timestamp := ms_to_datetime(opening_timestamp)]
          }
          if (nrow(dt) > 0 && "current_timestamp" %in% names(dt)) {
            dt[, current_timestamp := ms_to_datetime(current_timestamp)]
          }
          return(dt)
        }
      ))
    },

    #' @description Get All Positions
    #'
    #' Retrieves all open positions.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with optional `currency` query parameter.
    #' 2. **Parsing**: Returns a multi-row `data.table` with one row per open position.
    #' 3. **Timestamp Conversion**: Coerces `opening_timestamp` and `current_timestamp` from milliseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/positions`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Position List](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-list)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/positions?currency=USDT' \
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
    #'       "id": "615ba79f27adbe000854c352",
    #'       "symbol": "XBTUSDTM",
    #'       "realLeverage": 2.05,
    #'       "crossMode": false,
    #'       "currentQty": 1,
    #'       "currentCost": "40.008",
    #'       "isOpen": true,
    #'       "markPrice": 40014.93,
    #'       "markValue": "40.01493",
    #'       "posMargin": "20.02800588",
    #'       "unrealisedPnl": 0.00693,
    #'       "avgEntryPrice": "40008.0",
    #'       "liquidationPrice": "20332.0",
    #'       "marginMode": "ISOLATED",
    #'       "openingTimestamp": 1729176273859,
    #'       "currentTimestamp": 1729176573859
    #'     },
    #'     {
    #'       "id": "615ba7a027adbe000854c358",
    #'       "symbol": "ETHUSDTM",
    #'       "realLeverage": 5.12,
    #'       "crossMode": true,
    #'       "currentQty": 10,
    #'       "currentCost": "200.50",
    #'       "isOpen": true,
    #'       "markPrice": 2210.45,
    #'       "markValue": "221.045",
    #'       "posMargin": "44.209",
    #'       "unrealisedPnl": 0.545,
    #'       "avgEntryPrice": "2005.0",
    #'       "liquidationPrice": "1650.0",
    #'       "marginMode": "CROSS",
    #'       "openingTimestamp": 1729176273859,
    #'       "currentTimestamp": 1729176573859
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param currency Character or NULL; filter by settlement currency.
    #' @return A `data.table`; same columns as `get_position()`.
    get_positions = function(currency = NULL) {
      return(private$.request(
        endpoint = "/api/v1/positions",
        query = list(currency = currency),
        .parser = function(data) {
          dt <- as_dt_list(data)
          if (nrow(dt) > 0 && "opening_timestamp" %in% names(dt)) {
            dt[, opening_timestamp := ms_to_datetime(opening_timestamp)]
          }
          if (nrow(dt) > 0 && "current_timestamp" %in% names(dt)) {
            dt[, current_timestamp := ms_to_datetime(current_timestamp)]
          }
          return(dt)
        }
      ))
    },

    #' @description Get Position History
    #'
    #' Retrieves historical position records.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with optional query parameters for filtering and pagination.
    #' 2. **Parsing**: Extracts `items` from paginated response into a `data.table`.
    #' 3. **Timestamp Conversion**: Coerces `open_time` and `close_time` from milliseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/history-positions`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Position History](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-positions-history)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/history-positions?symbol=XBTUSDTM&limit=20' \
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
    #'     "pageSize": 20,
    #'     "totalNum": 1,
    #'     "totalPage": 1,
    #'     "items": [
    #'       {
    #'         "closeId": "615ba79f27adbe000854c360",
    #'         "positionId": "615ba79f27adbe000854c352",
    #'         "uid": 123456789,
    #'         "userId": "5e1234567890abcdef123456",
    #'         "symbol": "XBTUSDTM",
    #'         "settleCurrency": "USDT",
    #'         "leverage": "10",
    #'         "type": "Close",
    #'         "pnl": "2.345",
    #'         "realisedGrossCost": "2.5",
    #'         "withdrawPnl": "0",
    #'         "tradeFee": "0.155",
    #'         "fundingFee": "0.012",
    #'         "openTime": 1729176273859,
    #'         "closeTime": 1729262673859,
    #'         "openPrice": "40008.0",
    #'         "closePrice": "40250.0",
    #'         "marginMode": "ISOLATED"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query Named list; query parameters. Optional: `symbol`,
    #'   `from`, `to`, `limit`, `pageId`.
    #' @return A `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `settle_currency` (character): Settlement currency.
    #'   - `realised_gross_pnl` (character): Gross realised PNL.
    #'   - `realised_pnl` (character): Net realised PNL (after fees).
    #'   - `leverage` (integer): Leverage used.
    #'   - `type` (character): Close type (e.g., `"Close"`).
    #'   - `open_time` (POSIXct): Position opened time (coerced from milliseconds).
    #'   - `close_time` (POSIXct): Position closed time (coerced from milliseconds).
    get_positions_history = function(query = list()) {
      return(private$.request(
        endpoint = "/api/v1/history-positions",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          dt <- as_dt_list(items)
          if (nrow(dt) > 0 && "open_time" %in% names(dt)) {
            dt[, open_time := ms_to_datetime(open_time)]
          }
          if (nrow(dt) > 0 && "close_time" %in% names(dt)) {
            dt[, close_time := ms_to_datetime(close_time)]
          }
          return(dt)
        }
      ))
    },

    #' @description Get Margin Mode
    #'
    #' Retrieves the current margin mode for a symbol.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` query parameter.
    #' 2. **Parsing**: Returns a single-row `data.table` with the current margin mode.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/marginMode`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Margin Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-margin-mode)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/marginMode?symbol=XBTUSDTM' \
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
    #'     "symbol": "XBTUSDTM",
    #'     "marginMode": "ISOLATED"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @return A single-row `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `margin_mode` (character): `"ISOLATED"` or `"CROSS"`.
    get_margin_mode = function(symbol) {
      return(private$.request(
        endpoint = "/api/v1/marginMode",
        query = list(symbol = symbol),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Set Margin Mode
    #'
    #' Switches the margin mode for a symbol between ISOLATED and CROSS.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with `symbol` and `marginMode`.
    #' 2. **Request**: Authenticated POST to the margin mode endpoint.
    #' 3. **Parsing**: Returns a single-row `data.table` confirming the updated mode.
    #'
    #' ### API Endpoint
    #' `POST https://api-futures.kucoin.com/api/v1/marginMode`
    #'
    #' ### Official Documentation
    #' [KuCoin Modify Margin Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/modify-margin-mode)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v1/marginMode' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"symbol":"XBTUSDTM","marginMode":"CROSS"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "XBTUSDTM",
    #'   "marginMode": "CROSS"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "XBTUSDTM",
    #'     "marginMode": "CROSS"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @param marginMode Character; `"ISOLATED"` or `"CROSS"`.
    #' @return A single-row `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `margin_mode` (character): Updated margin mode.
    set_margin_mode = function(symbol, marginMode) {
      return(private$.request(
        endpoint = "/api/v1/marginMode",
        method = "POST",
        body = list(symbol = symbol, marginMode = marginMode),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Get Cross Margin Leverage
    #'
    #' Retrieves the current cross margin leverage for a symbol.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` query parameter.
    #' 2. **Parsing**: Returns a single-row `data.table` with the current leverage setting.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/crossMarginLeverage`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Cross Margin Leverage](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-cross-margin-leverage)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/crossMarginLeverage?symbol=XBTUSDTM' \
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
    #'     "symbol": "XBTUSDTM",
    #'     "leverage": "5"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @return A single-row `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `leverage` (character): Current leverage multiplier.
    get_cross_margin_leverage = function(symbol) {
      return(private$.request(
        endpoint = "/api/v1/crossMarginLeverage",
        query = list(symbol = symbol),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Set Cross Margin Leverage
    #'
    #' Modifies the cross margin leverage for a symbol.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with `symbol` and `leverage`.
    #' 2. **Request**: Authenticated POST to the cross margin leverage endpoint.
    #' 3. **Parsing**: Returns a single-row `data.table` confirming the updated leverage.
    #'
    #' ### API Endpoint
    #' `POST https://api-futures.kucoin.com/api/v1/crossMarginLeverage`
    #'
    #' ### Official Documentation
    #' [KuCoin Modify Cross Margin Leverage](https://www.kucoin.com/docs-new/rest/futures-trading/positions/modify-cross-margin-leverage)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v1/crossMarginLeverage' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"symbol":"XBTUSDTM","leverage":"10"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "XBTUSDTM",
    #'   "leverage": "10"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "XBTUSDTM",
    #'     "leverage": "10"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @param leverage Integer; leverage multiplier.
    #' @return A single-row `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `leverage` (character): Updated leverage multiplier.
    set_cross_margin_leverage = function(symbol, leverage) {
      return(private$.request(
        endpoint = "/api/v1/crossMarginLeverage",
        method = "POST",
        body = list(symbol = symbol, leverage = leverage),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Get Maximum Open Size
    #'
    #' Retrieves the maximum number of contracts that can be opened.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol`, `price`, and `leverage` query parameters.
    #' 2. **Parsing**: Returns a single-row `data.table` with maximum buy and sell open sizes.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/maxOpenSize`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Max Open Size](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-maximum-open-position-size)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/maxOpenSize?symbol=XBTUSDTM&price=40000&leverage=10' \
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
    #'     "symbol": "XBTUSDTM",
    #'     "maxBuyOpenSize": 100,
    #'     "maxSellOpenSize": 100
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @param price Character; order price.
    #' @param leverage Integer; leverage multiplier.
    #' @return A single-row `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `max_buy_open_size` (integer): Maximum buy contracts.
    #'   - `max_sell_open_size` (integer): Maximum sell contracts.
    get_max_open_size = function(symbol, price, leverage) {
      return(private$.request(
        endpoint = "/api/v1/maxOpenSize",
        query = list(symbol = symbol, price = price, leverage = leverage),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Get Maximum Withdrawable Margin
    #'
    #' Retrieves the maximum margin that can be withdrawn from an isolated position.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` query parameter.
    #' 2. **Parsing**: Returns a single-row `data.table` with the maximum withdrawable margin.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/maxWithdrawMargin`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Max Withdraw Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-max-withdraw-margin)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/maxWithdrawMargin?symbol=XBTUSDTM' \
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
    #'   "data": "21.1234"
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @return A single-row `data.table` with the maximum withdrawable margin amount.
    get_max_withdraw_margin = function(symbol) {
      return(private$.request(
        endpoint = "/api/v1/maxWithdrawMargin",
        query = list(symbol = symbol),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Add Isolated Margin
    #'
    #' Deposits additional margin into an isolated margin position.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with `symbol`, `margin`, and `bizNo`.
    #' 2. **Request**: Authenticated POST to the margin deposit endpoint.
    #' 3. **Parsing**: Returns a single-row `data.table` confirming the deposit.
    #'
    #' ### API Endpoint
    #' `POST https://api-futures.kucoin.com/api/v1/marginDepositIn`
    #'
    #' ### Official Documentation
    #' [KuCoin Add Isolated Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/add-isolated-margin)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v1/marginDepositIn' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"symbol":"XBTUSDTM","margin":5,"bizNo":"abc123-unique-id"}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "XBTUSDTM",
    #'   "margin": 5,
    #'   "bizNo": "abc123-unique-id"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "id": "615ba79f27adbe000854c370",
    #'     "symbol": "XBTUSDTM",
    #'     "margin": "5",
    #'     "marginType": "ADD"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @param margin Numeric; amount of margin to add.
    #' @param bizNo Character; unique business ID for idempotency.
    #' @return A single-row `data.table` with columns:
    #'   - `id` (character): Margin operation ID.
    #'   - `symbol` (character): Contract symbol.
    #'   - `margin` (character): Amount deposited.
    #'   - `margin_type` (character): Operation type (e.g., `"ADD"`).
    add_isolated_margin = function(symbol, margin, bizNo) {
      return(private$.request(
        endpoint = "/api/v1/marginDepositIn",
        method = "POST",
        body = list(symbol = symbol, margin = margin, bizNo = bizNo),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Remove Isolated Margin
    #'
    #' Withdraws excess margin from an isolated margin position.
    #'
    #' ### Workflow
    #' 1. **Build Body**: Constructs JSON body with `symbol` and `withdrawAmount`.
    #' 2. **Request**: Authenticated POST to the margin withdrawal endpoint.
    #' 3. **Parsing**: Returns a single-row `data.table` confirming the withdrawal.
    #'
    #' ### API Endpoint
    #' `POST https://api-futures.kucoin.com/api/v1/marginWithdrawOut`
    #'
    #' ### Official Documentation
    #' [KuCoin Remove Isolated Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/remove-isolated-margin)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v1/marginWithdrawOut' \
    #'   --header 'Content-Type: application/json' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2' \
    #'   --data-raw '{"symbol":"XBTUSDTM","withdrawAmount":3}'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "XBTUSDTM",
    #'   "withdrawAmount": 3
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "id": "615ba79f27adbe000854c375",
    #'     "symbol": "XBTUSDTM",
    #'     "margin": "3",
    #'     "marginType": "WITHDRAW"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @param withdrawAmount Numeric; amount of margin to withdraw.
    #' @return A single-row `data.table` with columns:
    #'   - `id` (character): Margin operation ID.
    #'   - `symbol` (character): Contract symbol.
    #'   - `margin` (character): Amount withdrawn.
    #'   - `margin_type` (character): Operation type.
    remove_isolated_margin = function(symbol, withdrawAmount) {
      return(private$.request(
        endpoint = "/api/v1/marginWithdrawOut",
        method = "POST",
        body = list(symbol = symbol, withdrawAmount = withdrawAmount),
        .parser = function(data) {
          return(as_dt_row(data))
        }
      ))
    },

    #' @description Get Risk Limit Level
    #'
    #' Retrieves risk limit tiers for a futures contract.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` embedded in the URL path.
    #' 2. **Parsing**: Returns a multi-row `data.table` with one row per risk limit tier.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/contracts/risk-limit/{symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Risk Limit Level](https://www.kucoin.com/docs-new/rest/futures-trading/risk-limit/get-futures-risk-limit-level)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/contracts/risk-limit/XBTUSDTM' \
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
    #'       "symbol": "XBTUSDTM",
    #'       "level": 1,
    #'       "maxRiskLimit": 500000,
    #'       "minRiskLimit": 0,
    #'       "maxLeverage": 125,
    #'       "initialMargin": 0.008,
    #'       "maintainMargin": 0.004
    #'     },
    #'     {
    #'       "symbol": "XBTUSDTM",
    #'       "level": 2,
    #'       "maxRiskLimit": 1000000,
    #'       "minRiskLimit": 500000,
    #'       "maxLeverage": 100,
    #'       "initialMargin": 0.01,
    #'       "maintainMargin": 0.005
    #'     },
    #'     {
    #'       "symbol": "XBTUSDTM",
    #'       "level": 3,
    #'       "maxRiskLimit": 2000000,
    #'       "minRiskLimit": 1000000,
    #'       "maxLeverage": 75,
    #'       "initialMargin": 0.0133,
    #'       "maintainMargin": 0.007
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @return A `data.table` with columns:
    #'   - `symbol` (character): Contract symbol.
    #'   - `level` (integer): Risk limit tier level.
    #'   - `max_risk_limit` (integer): Maximum position value for this tier.
    #'   - `min_risk_limit` (integer): Minimum position value for this tier.
    #'   - `max_leverage` (integer): Maximum leverage at this tier.
    #'   - `initial_margin` (numeric): Initial margin rate.
    #'   - `maintain_margin` (numeric): Maintenance margin rate.
    get_risk_limit = function(symbol) {
      return(private$.request(
        endpoint = paste0("/api/v1/contracts/risk-limit/", symbol),
        .parser = function(data) {
          return(as_dt_list(data))
        }
      ))
    },

    #' @description Get Private Funding Fee History
    #'
    #' Retrieves your personal funding fee settlement records.
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` (required) and optional pagination/filtering query parameters.
    #' 2. **Parsing**: Extracts `dataList` from response into a `data.table`.
    #' 3. **Timestamp Conversion**: Coerces `time_point` from milliseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/funding-history`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Private Funding History](https://www.kucoin.com/docs-new/rest/futures-trading/funding-fees/get-private-funding-history)
    #'
    #' Verified: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/funding-history?symbol=XBTUSDTM&maxCount=100' \
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
    #'     "dataList": [
    #'       {
    #'         "id": 1742547891234,
    #'         "symbol": "XBTUSDTM",
    #'         "timePoint": 1729176000000,
    #'         "fundingRate": 0.0001,
    #'         "markPrice": 40125.56,
    #'         "positionQty": 10,
    #'         "positionCost": "400.12556",
    #'         "funding": "-0.04001256",
    #'         "settleCurrency": "USDT"
    #'       },
    #'       {
    #'         "id": 1742547891235,
    #'         "symbol": "XBTUSDTM",
    #'         "timePoint": 1729147200000,
    #'         "fundingRate": -0.00005,
    #'         "markPrice": 39987.12,
    #'         "positionQty": 10,
    #'         "positionCost": "399.8712",
    #'         "funding": "0.01999356",
    #'         "settleCurrency": "USDT"
    #'       }
    #'     ],
    #'     "hasMore": false
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; futures symbol.
    #' @param query Named list; additional query parameters. Optional:
    #'   `startAt`, `endAt`, `reverse`, `offset`, `forward`, `maxCount`.
    #' @return A `data.table` with columns:
    #'   - `id` (integer): Record identifier.
    #'   - `symbol` (character): Contract symbol.
    #'   - `time_point` (POSIXct): Funding settlement time (coerced from milliseconds).
    #'   - `funding_rate` (numeric): Funding rate applied.
    #'   - `mark_price` (numeric): Mark price at settlement.
    #'   - `position_qty` (integer): Position size at settlement.
    #'   - `position_cost` (character): Position cost at settlement.
    #'   - `funding` (character): Funding fee amount (negative = paid, positive = received).
    #'   - `settle_currency` (character): Settlement currency.
    get_funding_history = function(symbol, query = list()) {
      query$symbol <- symbol
      return(private$.request(
        endpoint = "/api/v1/funding-history",
        query = query,
        .parser = function(data) {
          items <- data
          if (!is.null(data$dataList)) {
            items <- data$dataList
          }
          dt <- as_dt_list(items)
          if (nrow(dt) > 0 && "time_point" %in% names(dt)) {
            dt[, time_point := ms_to_datetime(time_point)]
          }
          return(dt)
        }
      ))
    }
  )
)
