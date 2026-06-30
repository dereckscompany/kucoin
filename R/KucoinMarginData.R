# File: R/KucoinMarginData.R
# R6 class for KuCoin margin market data: symbols, config, risk limits.

#' KucoinMarginData: Margin Market Information
#'
#' Provides methods for querying margin-specific market data including
#' supported symbols, configuration, risk limits, and collateral ratios.
#' Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Cross Margin Symbols**: Query symbols available for cross margin trading.
#' - **Isolated Margin Symbols**: Query symbols available for isolated margin trading.
#' - **Margin Config**: Retrieve global margin configuration (max leverage, liquidation ratios).
#' - **Collateral Ratios**: Query collateral ratio tiers by currency.
#' - **Risk Limits**: Query borrow/hold limits per currency or symbol.
#'
#' ### Usage
#' Most methods are public (no auth required). `get_risk_limit()` requires
#' authentication with General permission.
#'
#' ### Official Documentation
#' [KuCoin Margin Info](https://www.kucoin.com/docs-new/rest/margin-trading/risk-limit/get-margin-risk-limit)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_cross_margin_symbols | GET /api/v3/margin/symbols | GET |
#' | get_isolated_margin_symbols | GET /api/v1/isolated/symbols | GET |
#' | get_margin_config | GET /api/v1/margin/config | GET |
#' | get_collateral_ratio | GET /api/v3/margin/collateralRatio | GET |
#' | get_risk_limit | GET /api/v3/margin/currencies | GET |
#'
#' @examples
#' \dontrun{
#' margin_data <- KucoinMarginData$new()
#'
#' # Check available cross margin trading pairs
#' symbols <- margin_data$get_cross_margin_symbols()
#' print(symbols)
#'
#' # Get margin configuration
#' config <- margin_data$get_margin_config()
#' print(config)
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinMarginData <- R6::R6Class(
  "KucoinMarginData",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Get Cross Margin Symbols
    #'
    #' Retrieves symbols (trading pairs) available for cross margin trading,
    #' including increment sizes, min/max order sizes, and fee information.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/symbols`
    #'
    #' ### Official Documentation
    #' KuCoin Get Cross Margin Symbols:
    #' <https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-symbols-cross-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/symbols?symbol=BTC-USDT' \
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
    #'     "timestamp": 1772993986642,
    #'     "items": [
    #'       {
    #'         "symbol": "BTC-USDT",
    #'         "name": "BTC-USDT",
    #'         "enableTrading": true,
    #'         "market": "USDS",
    #'         "baseCurrency": "BTC",
    #'         "quoteCurrency": "USDT",
    #'         "baseIncrement": "0.00000001",
    #'         "baseMinSize": "0.00001",
    #'         "baseMaxSize": "10000000000",
    #'         "quoteIncrement": "0.000001",
    #'         "quoteMinSize": "0.1",
    #'         "quoteMaxSize": "99999999",
    #'         "priceIncrement": "0.1",
    #'         "feeCurrency": "USDT",
    #'         "priceLimitRate": "0.01",
    #'         "minFunds": "0.1"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query (list)
    #' @return (data.table | promise<data.table>) one row per cross-margin symbol with trading-pair identifiers, base
    #'   and quote currencies, increment and min/max order sizes, fee currency, price-limit rate, and minimum funds; an
    #'   empty response yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' margin_data <- KucoinMarginData$new()
    #' symbols <- margin_data$get_cross_margin_symbols(query = list(symbol = "BTC-USDT"))
    #' print(symbols)
    #' }
    get_cross_margin_symbols = function(query = list()) {
      assert_args_KucoinMarginData__get_cross_margin_symbols(query)
      res <- private$.request(
        endpoint = "/api/v3/margin/symbols",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          # API wraps response in {timestamp, items} envelope
          items <- data
          if (!is.null(data$items)) {
            items <- data$items
          }
          if (is.null(items) || length(items) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarginData__get_cross_margin_symbols,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Isolated Margin Symbols
    #'
    #' Retrieves symbols available for isolated margin trading, including
    #' leverage limits, debt ratios, and borrowing parameters per pair.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/isolated/symbols`
    #'
    #' ### Official Documentation
    #' KuCoin Get Isolated Margin Symbols:
    #' <https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-symbols-isolated-margin>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/isolated/symbols' \
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
    #'       "symbol": "BTC-USDT",
    #'       "symbolName": "BTC-USDT",
    #'       "baseCurrency": "BTC",
    #'       "quoteCurrency": "USDT",
    #'       "maxLeverage": 10,
    #'       "flDebtRatio": "0.97",
    #'       "tradeEnable": true,
    #'       "baseBorrowEnable": true,
    #'       "quoteBorrowEnable": true,
    #'       "baseTransferInEnable": true,
    #'       "quoteTransferInEnable": true
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per isolated-margin pair with the trading-pair identifier,
    #'   display name, base and quote currencies, maximum leverage, forced-liquidation debt ratio, and the trade, borrow
    #'   and transfer-in enablement flags; an empty response yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' margin_data <- KucoinMarginData$new()
    #' symbols <- margin_data$get_isolated_margin_symbols()
    #' print(symbols[trade_enable == TRUE])
    #' }
    get_isolated_margin_symbols = function() {
      res <- private$.request(
        endpoint = "/api/v1/isolated/symbols",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarginData__get_isolated_margin_symbols,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Margin Configuration
    #'
    #' Retrieves global margin configuration including maximum leverage,
    #' warning debt ratio, liquidation debt ratio, and list of supported
    #' currencies.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/margin/config`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Margin Config](https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-margin-config)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/margin/config' \
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
    #'     "maxLeverage": 10,
    #'     "warningDebtRatio": "0.95",
    #'     "liqDebtRatio": "0.97",
    #'     "currencyList": ["BTC", "ETH", "USDT"]
    #'   }
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per supported currency, with the `currencyList` array exploded
    #'   so each currency carries the replicated config-level fields for maximum leverage, warning debt ratio and
    #'   liquidation debt ratio; an empty `currencyList` yields a zero-row data.table with this schema:
    #' - currency (character) the currency code.
    #' - max_leverage (integer | NA) the max leverage.
    #' - warning_debt_ratio (character | NA) the warning debt ratio.
    #' - liq_debt_ratio (character | NA) the liq debt ratio.
    #'
    #' @examples
    #' \dontrun{
    #' margin_data <- KucoinMarginData$new()
    #' config <- margin_data$get_margin_config()
    #' cat("Max leverage:", config$max_leverage[1], "\n")
    #' cat("Supported currencies:", paste(config$currency, collapse = ", "), "\n")
    #' }
    get_margin_config = function() {
      res <- private$.request(
        endpoint = "/api/v1/margin/config",
        auth = FALSE,
        .parser = function(data) {
          # Schema-stable empty `data.table` — same columns as a populated
          # response, just zero rows. Documented in NEWS as the contract.
          empty_dt <- data.table::data.table(
            currency = character(),
            max_leverage = integer(),
            warning_debt_ratio = character(),
            liq_debt_ratio = character()
          )
          if (is.null(data) || length(data) == 0L) {
            return(empty_dt[])
          }
          # Treatment B: explode `currencyList` (array of plain strings) so
          # each supported currency gets its own row with the config-level
          # fields replicated.
          currencies <- as.character(unlist(data$currencyList))
          data$currencyList <- NULL
          dt <- as_dt_row(data)
          if (length(currencies) == 0L) {
            return(empty_dt[])
          }
          dt <- dt[rep(1L, length(currencies))]
          dt[, currency := currencies]
          data.table::setcolorder(dt, c("currency", setdiff(names(dt), "currency")))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarginData__get_margin_config,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Collateral Ratios
    #'
    #' Retrieves collateral ratio tiers for margin currencies. Each currency
    #' has multiple tiers based on collateral amount ranges.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/collateralRatio`
    #'
    #' ### Official Documentation
    #' KuCoin Get Collateral Ratio:
    #' <https://www.kucoin.com/docs-new/rest/margin-trading/market-data/get-margin-collateral-ratio>
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/collateralRatio?currencyList=BTC,ETH' \
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
    #'       "currencyList": ["BTC"],
    #'       "items": [
    #'         {
    #'           "lowerLimit": "0",
    #'           "upperLimit": "10",
    #'           "collateralRatio": "1.0"
    #'         }
    #'       ]
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param query (list)
    #' @return (data.table | promise<data.table>) one row per (currency, tier) pair, with the nested `currencyList` and
    #'   `items` arrays cross-joined into a flat long table carrying the currency code, lower and upper bounds of the
    #'   collateral range, and the collateral ratio applied in that range; an empty response yields a zero-row
    #'   data.table with this schema:
    #' - currency (character) the currency code.
    #' - lower_limit (character | NA) the lower limit.
    #' - upper_limit (character | NA) the upper limit.
    #' - collateral_ratio (character | NA) the collateral ratio.
    #'
    #' @examples
    #' \dontrun{
    #' margin_data <- KucoinMarginData$new()
    #' ratios <- margin_data$get_collateral_ratio(query = list(currencyList = "BTC,ETH"))
    #' print(ratios)
    #' # Filter high-ratio tiers
    #' ratios[as.numeric(collateral_ratio) >= 0.9]
    #' }
    get_collateral_ratio = function(query = list()) {
      assert_args_KucoinMarginData__get_collateral_ratio(query)
      res <- private$.request(
        endpoint = "/api/v3/margin/collateralRatio",
        query = query,
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table(
              currency = character(),
              lower_limit = character(),
              upper_limit = character(),
              collateral_ratio = character()
            )[])
          }
          rows <- list()
          for (group in data) {
            currencies <- as.character(unlist(group$currencyList))
            for (item in group$items) {
              for (cur in currencies) {
                rows[[length(rows) + 1L]] <- data.table::data.table(
                  currency = cur,
                  lower_limit = as.character(if (is.null(item$lowerLimit)) NA else item$lowerLimit),
                  upper_limit = as.character(if (is.null(item$upperLimit)) NA else item$upperLimit),
                  collateral_ratio = as.character(if (is.null(item$collateralRatio)) NA else item$collateralRatio)
                )
              }
            }
          }
          return(data.table::rbindlist(rows)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarginData__get_collateral_ratio,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Margin Risk Limit
    #'
    #' Retrieves borrow and hold limits for margin currencies. Supports both
    #' cross and isolated margin. This endpoint requires authentication.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/margin/currencies`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Risk Limit](https://www.kucoin.com/docs-new/rest/margin-trading/risk-limit/get-margin-risk-limit)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/margin/currencies?isIsolated=false&currency=BTC' \
    #'   --header 'KC-API-KEY: your-api-key' \
    #'   --header 'KC-API-SIGN: your-signature' \
    #'   --header 'KC-API-TIMESTAMP: 1729176273859' \
    #'   --header 'KC-API-PASSPHRASE: your-passphrase' \
    #'   --header 'KC-API-KEY-VERSION: 2'
    #' ```
    #'
    #' ### JSON Response (cross margin)
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "currency": "BTC",
    #'       "borrowMaxAmount": "100",
    #'       "buyMaxAmount": "100",
    #'       "holdMaxAmount": "100",
    #'       "borrowCoefficient": "1",
    #'       "marginCoefficient": "1",
    #'       "precision": 8,
    #'       "borrowMinAmount": "0.001",
    #'       "borrowMinUnit": "0.001",
    #'       "borrowEnabled": true
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param isIsolated (scalar<logical>)
    #' @param query (list)
    #' @return (data.table | promise<data.table>) one row per currency (cross) or per (symbol, currency) pair
    #'   (isolated), carrying the currency code, maximum borrow, buy and hold amounts, borrow and margin coefficients,
    #'   decimal precision, minimum borrow amount and unit, and the borrow-enabled flag, with an extra `symbol` column
    #'   for isolated margin; an empty response yields an empty data.table.
    #'
    #' @examples
    #' \dontrun{
    #' margin_data <- KucoinMarginData$new()
    #'
    #' # Cross margin risk limits
    #' limits <- margin_data$get_risk_limit(isIsolated = FALSE)
    #' print(limits)
    #'
    #' # Isolated margin risk limits for BTC-USDT
    #' limits <- margin_data$get_risk_limit(
    #'   isIsolated = TRUE,
    #'   query = list(symbol = "BTC-USDT")
    #' )
    #' }
    get_risk_limit = function(isIsolated, query = list()) {
      assert_args_KucoinMarginData__get_risk_limit(isIsolated, query)
      if (!is.logical(isIsolated)) {
        rlang::abort("Parameter 'isIsolated' must be logical (TRUE or FALSE).")
      }

      query$isIsolated <- isIsolated

      res <- private$.request(
        endpoint = "/api/v3/margin/currencies",
        query = query,
        auth = TRUE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarginData__get_risk_limit,
        is_async = private$.is_async
      ))
    }
  )
)
