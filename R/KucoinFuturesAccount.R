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
#' | get_margin_mode | GET /api/v2/position/getMarginMode | GET |
#' | set_margin_mode | POST /api/v2/position/changeMarginMode | POST |
#' | get_cross_margin_leverage | GET /api/v2/getCrossUserLeverage | GET |
#' | set_cross_margin_leverage | POST /api/v2/changeCrossUserLeverage | POST |
#' | get_max_open_size | GET /api/v2/getMaxOpenSize | GET |
#' | get_max_withdraw_margin | GET /api/v1/margin/maxWithdrawMargin | GET |
#' | add_isolated_margin | POST /api/v1/position/margin/deposit-margin | POST |
#' | remove_isolated_margin | POST /api/v1/margin/withdrawMargin | POST |
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
    #' @noassert time_source
    #' @param keys (list) API credentials from [get_api_keys()].
    #' @param base_url (scalar<character>) Futures API base URL. Defaults to
    #'   [get_futures_base_url()].
    #' @param async (scalar<logical>) if TRUE, methods return promises.
    #' @param time_source (scalar<character>) `"local"` or `"server"`.
    #' @return (class<KucoinFuturesAccount>) invisibly, the new instance.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      assert_args_KucoinFuturesAccount__initialize(keys, base_url, async)
      super$initialize(keys = keys, base_url = base_url, async = async, time_source = time_source)
      return(invisible(self))
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
    #' KuCoin Get Account - Futures:
    #' <https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-futures>
    #'
    #' Verified: 2026-05-23
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
    #' @param currency (scalar<character>) settlement currency (e.g., `"USDT"`).
    #'   Default `"USDT"`.
    #' @return (data.table | promise<data.table>) one row giving the futures
    #'   account overview: total account equity, unrealised profit and loss,
    #'   margin balance, position and order margin, frozen funds, available
    #'   balance, and the settlement currency code:
    #' - account_equity (numeric) the account equity.
    #' - unrealised_pnl (numeric) the unrealised pnl.
    #' - margin_balance (numeric) the margin balance.
    #' - available_balance (numeric) the available balance.
    #' - available_margin (numeric) the available margin.
    #' - currency (character) the currency code.
    #' - risk_ratio (numeric) the risk ratio.
    #' - max_withdraw_amount (numeric) the max withdraw amount.
    get_account_overview = function(currency = "USDT") {
      assert_args_KucoinFuturesAccount__get_account_overview(currency)
      res <- private$.request(
        endpoint = "/api/v1/account-overview",
        query = list(currency = currency),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_account_overview,
        is_async = private$.is_async
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
    #' KuCoin Get Position Details:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-position-details>
    #'
    #' Verified: 2026-05-23
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
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) one row giving the position
    #'   details: identifier, contract symbol, auto-deposit flag, effective
    #'   leverage, cross-mode flag, auto-deleveraging percentage, current
    #'   position size, current and unrealised/realised costs and commissions,
    #'   open flag, mark price and value, position cost/init/commission/margin,
    #'   unrealised PnL and its percentage, average entry, liquidation and
    #'   bankruptcy prices, settlement currency, margin mode, position side, and
    #'   the opening and current datetimes (POSIXct, coerced from epoch
    #'   milliseconds).
    get_position = function(symbol) {
      assert_args_KucoinFuturesAccount__get_position(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v2/position",
        query = list(symbol = symbol),
        .parser = function(data) {
          dt <- as_dt_row(data)
          coerce_cols(dt, c("opening_timestamp", "current_timestamp"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_position,
        is_async = private$.is_async
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
    #' Verified: 2026-05-23
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
    #' @param currency (scalar<character> | NULL) filter by settlement currency.
    #' @return (data.table | promise<data.table>) one row per open position,
    #'   carrying the same columns as `get_position()`; an empty `data.table`
    #'   when there are no open positions.
    get_positions = function(currency = NULL) {
      assert_args_KucoinFuturesAccount__get_positions(currency)
      res <- private$.request(
        endpoint = "/api/v1/positions",
        query = list(currency = currency),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, c("opening_timestamp", "current_timestamp"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_positions,
        is_async = private$.is_async
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
    #' KuCoin Get Position History:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-positions-history>
    #'
    #' Verified: 2026-05-23
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
    #' @param query (list) query parameters. Optional keys: symbol, from, to,
    #'   limit, pageId.
    #' @return (data.table | promise<data.table>) one row per closed position
    #'   record, each giving the close-event and position identifiers, numeric
    #'   and string user IDs, contract symbol, settlement currency, leverage,
    #'   close type, realised PnL, gross realised cost, withdrawn PnL, trade and
    #'   funding fees, average open and close prices, margin mode, and the
    #'   opening and closing datetimes (POSIXct, coerced from epoch
    #'   milliseconds); an empty `data.table` when no history records match.
    get_positions_history = function(query = list()) {
      assert_args_KucoinFuturesAccount__get_positions_history(query)
      res <- private$.request(
        endpoint = "/api/v1/history-positions",
        query = query,
        .parser = function(data) {
          items <- data
          if (is.list(data) && !is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(items)
          coerce_cols(dt, c("open_time", "close_time"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_positions_history,
        is_async = private$.is_async
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
    #' `GET https://api-futures.kucoin.com/api/v2/position/getMarginMode`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Margin Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-margin-mode)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v2/position/getMarginMode?symbol=XBTUSDTM' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @return (data.table | promise<data.table>) one row giving the contract
    #'   symbol and its current margin mode (`"ISOLATED"` or `"CROSS"`):
    #' - symbol (character) the trading pair symbol.
    #' - margin_mode (character) the margin mode.
    get_margin_mode = function(symbol) {
      assert_args_KucoinFuturesAccount__get_margin_mode(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v2/position/getMarginMode",
        query = list(symbol = symbol),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_margin_mode,
        is_async = private$.is_async
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
    #' `POST https://api-futures.kucoin.com/api/v2/position/changeMarginMode`
    #'
    #' ### Official Documentation
    #' [KuCoin Switch Margin Mode](https://www.kucoin.com/docs-new/rest/futures-trading/positions/switch-margin-mode)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v2/position/changeMarginMode' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @param marginMode (scalar<character>) `"ISOLATED"` or `"CROSS"`.
    #' @return (data.table | promise<data.table>) one row giving the contract
    #'   symbol and its updated margin mode:
    #' - symbol (character) the trading pair symbol.
    #' - margin_mode (character) the margin mode.
    set_margin_mode = function(symbol, marginMode) {
      assert_args_KucoinFuturesAccount__set_margin_mode(symbol, marginMode)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v2/position/changeMarginMode",
        method = "POST",
        body = list(symbol = symbol, marginMode = marginMode),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__set_margin_mode,
        is_async = private$.is_async
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
    #' `GET https://api-futures.kucoin.com/api/v2/getCrossUserLeverage`
    #'
    #' ### Official Documentation
    #' KuCoin Get Cross Margin Leverage:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-cross-margin-leverage>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v2/getCrossUserLeverage?symbol=XBTUSDTM' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @return (data.table | promise<data.table>) one row giving the contract
    #'   symbol and its current cross-margin leverage multiplier:
    #' - symbol (character) the trading pair symbol.
    #' - leverage (character) the leverage.
    get_cross_margin_leverage = function(symbol) {
      assert_args_KucoinFuturesAccount__get_cross_margin_leverage(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v2/getCrossUserLeverage",
        query = list(symbol = symbol),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_cross_margin_leverage,
        is_async = private$.is_async
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
    #' `POST https://api-futures.kucoin.com/api/v2/changeCrossUserLeverage`
    #'
    #' ### Official Documentation
    #' KuCoin Modify Cross Margin Leverage:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/modify-cross-margin-leverage>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v2/changeCrossUserLeverage' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @param leverage (scalar<count in [1, Inf[>) leverage multiplier.
    #' @return (data.table | promise<data.table>) one row giving the contract
    #'   symbol and its updated cross-margin leverage multiplier:
    #' - symbol (character) the trading pair symbol.
    #' - leverage (character) the leverage.
    set_cross_margin_leverage = function(symbol, leverage) {
      assert_args_KucoinFuturesAccount__set_cross_margin_leverage(symbol, leverage)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v2/changeCrossUserLeverage",
        method = "POST",
        body = list(symbol = symbol, leverage = leverage),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__set_cross_margin_leverage,
        is_async = private$.is_async
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
    #' `GET https://api-futures.kucoin.com/api/v2/getMaxOpenSize`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Max Open Size](https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-max-open-size)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v2/getMaxOpenSize?symbol=XBTUSDTM&price=40000&leverage=10' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @param price (scalar<numeric in ]0, Inf[>) order price.
    #' @param leverage (scalar<count in [1, Inf[>) leverage multiplier.
    #' @return (data.table | promise<data.table>) one row giving the contract
    #'   symbol and the maximum number of contracts that can be opened on the
    #'   buy and sell sides:
    #' - symbol (character) the trading pair symbol.
    #' - max_buy_open_size (integer) the max buy open size.
    #' - max_sell_open_size (integer) the max sell open size.
    get_max_open_size = function(symbol, price, leverage) {
      assert_args_KucoinFuturesAccount__get_max_open_size(symbol, price, leverage)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v2/getMaxOpenSize",
        query = list(symbol = symbol, price = price, leverage = leverage),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_max_open_size,
        is_async = private$.is_async
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
    #' `GET https://api-futures.kucoin.com/api/v1/margin/maxWithdrawMargin`
    #'
    #' ### Official Documentation
    #' KuCoin Get Max Withdraw Margin:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-max-withdraw-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/margin/maxWithdrawMargin?symbol=XBTUSDTM' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @return (data.table | promise<data.table>) one row giving the maximum
    #'   amount of isolated margin that can be withdrawn from the position,
    #'   returned by KuCoin as a fixed-precision string so the caller controls
    #'   numeric coercion.
    get_max_withdraw_margin = function(symbol) {
      assert_args_KucoinFuturesAccount__get_max_withdraw_margin(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/margin/maxWithdrawMargin",
        query = list(symbol = symbol),
        .parser = function(data) {
          # KuCoin returns a scalar string here (e.g. "21.1234") rather than
          # a named object. Wrap it explicitly so the caller gets a
          # one-row, one-column data.table with a meaningful name rather
          # than the default `v1` `as_dt_row()` would assign.
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          return(data.table::data.table(
            max_withdraw_margin = as.character(data)
          )[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_max_withdraw_margin,
        is_async = private$.is_async
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
    #' `POST https://api-futures.kucoin.com/api/v1/position/margin/deposit-margin`
    #'
    #' ### Official Documentation
    #' [KuCoin Add Isolated Margin](https://www.kucoin.com/docs-new/rest/futures-trading/positions/add-isolated-margin)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v1/position/margin/deposit-margin' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @param margin (scalar<numeric>) amount of margin to add.
    #' @param bizNo (scalar<character>) unique business ID for idempotency.
    #' @return (data.table | promise<data.table>) one row giving the margin
    #'   operation ID, contract symbol, amount deposited, and operation type
    #'   (e.g., `"ADD"`):
    #' - id (character) the record identifier.
    #' - symbol (character) the trading pair symbol.
    #' - margin (character) the margin amount.
    #' - margin_type (character) the margin type.
    add_isolated_margin = function(symbol, margin, bizNo) {
      assert_args_KucoinFuturesAccount__add_isolated_margin(symbol, margin, bizNo)
      assert::assert_nonempty_strings(symbol)
      assert::assert_nonempty_strings(bizNo)
      res <- private$.request(
        endpoint = "/api/v1/position/margin/deposit-margin",
        method = "POST",
        body = list(symbol = symbol, margin = margin, bizNo = bizNo),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__add_isolated_margin,
        is_async = private$.is_async
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
    #' `POST https://api-futures.kucoin.com/api/v1/margin/withdrawMargin`
    #'
    #' ### Official Documentation
    #' KuCoin Remove Isolated Margin:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/remove-isolated-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request POST 'https://api-futures.kucoin.com/api/v1/margin/withdrawMargin' \
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @param withdrawAmount (scalar<numeric>) amount of margin to withdraw.
    #' @return (data.table | promise<data.table>) one row giving the margin
    #'   operation ID, contract symbol, amount withdrawn, and operation type:
    #' - id (character) the record identifier.
    #' - symbol (character) the trading pair symbol.
    #' - margin (character) the margin amount.
    #' - margin_type (character) the margin type.
    remove_isolated_margin = function(symbol, withdrawAmount) {
      assert_args_KucoinFuturesAccount__remove_isolated_margin(symbol, withdrawAmount)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/margin/withdrawMargin",
        method = "POST",
        body = list(symbol = symbol, withdrawAmount = withdrawAmount),
        .parser = function(data) {
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__remove_isolated_margin,
        is_async = private$.is_async
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
    #' KuCoin Get Isolated Margin Risk Limit:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/positions/get-isolated-margin-risk-limit>
    #'
    #' Verified: 2026-05-23
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @return (data.table | promise<data.table>) one row per risk-limit tier,
    #'   each giving the contract symbol, tier level, maximum and minimum
    #'   position values for the tier, maximum leverage, and the initial and
    #'   maintenance margin rates; an empty `data.table` when KuCoin returns no
    #'   tiers.
    get_risk_limit = function(symbol) {
      assert_args_KucoinFuturesAccount__get_risk_limit(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = paste0("/api/v1/contracts/risk-limit/", symbol),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_risk_limit,
        is_async = private$.is_async
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
    #' KuCoin Get Private Funding History:
    #' <https://www.kucoin.com/docs-new/rest/futures-trading/funding-fees/get-private-funding-history>
    #'
    #' Verified: 2026-05-23
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
    #' @param symbol (scalar<character>) futures symbol.
    #' @param query (list) additional query parameters. Optional keys: startAt,
    #'   endAt, reverse, offset, forward, maxCount.
    #' @return (data.table | promise<data.table>) one row per funding
    #'   settlement, each giving the record identifier, contract symbol, the
    #'   funding settlement datetime (POSIXct, coerced from epoch milliseconds),
    #'   funding rate applied, mark price at settlement, position size and cost
    #'   at settlement, the funding fee amount (negative = paid, positive =
    #'   received), and the settlement currency; an empty `data.table` when no
    #'   records are returned.
    get_funding_history = function(symbol, query = list()) {
      assert_args_KucoinFuturesAccount__get_funding_history(symbol, query)
      assert::assert_nonempty_strings(symbol)
      query$symbol <- symbol
      res <- private$.request(
        endpoint = "/api/v1/funding-history",
        query = query,
        .parser = function(data) {
          items <- data
          if (is.list(data) && !is.null(data$dataList)) {
            items <- data$dataList
          }
          if (is.null(items) || length(items) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(items)
          coerce_cols(dt, "time_point", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesAccount__get_funding_history,
        is_async = private$.is_async
      ))
    }
  )
)
