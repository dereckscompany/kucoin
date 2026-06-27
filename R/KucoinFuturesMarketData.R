# File: R/KucoinFuturesMarketData.R
# R6 class for KuCoin Futures market data retrieval.

#' KucoinFuturesMarketData: Futures Market Data Retrieval
#'
#' Provides methods for querying KuCoin Futures public market data, including
#' contract details, tickers, orderbooks, trade history, klines, mark prices,
#' and funding rates. Inherits from [KucoinBase].
#'
#' ### Purpose and Scope
#' - **Contract Specifications**: Retrieve details for individual or all active futures contracts.
#' - **Real-Time Pricing**: Access tickers, orderbooks, and recent trade history.
#' - **Historical Data**: Fetch kline/candlestick data with automatic multi-page segmentation.
#' - **Funding Rates**: Query current and historical funding rates for perpetual contracts.
#' - **System Info**: Check server time and service status.
#'
#' ### Usage
#' Most endpoints are public and do not require authentication. The full
#' orderbook (`get_full_orderbook()`) is the only method that requires a
#' valid API key, secret, and passphrase. All other methods can be called
#' without credentials.
#'
#' ### Official Documentation
#' [KuCoin Futures Market Data](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-all-symbols)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_contract | GET /api/v1/contracts/\{symbol\} | GET |
#' | get_all_contracts | GET /api/v1/contracts/active | GET |
#' | get_ticker | GET /api/v1/ticker | GET |
#' | get_all_tickers | GET /api/v1/allTickers | GET |
#' | get_part_orderbook | GET /api/v1/level2/depth20 or depth100 | GET |
#' | get_full_orderbook | GET /api/v1/level2/snapshot | GET |
#' | get_trade_history | GET /api/v1/trade/history | GET |
#' | get_klines | GET /api/v1/kline/query | GET |
#' | get_mark_price | GET /api/v1/mark-price/\{symbol\}/current | GET |
#' | get_funding_rate | GET /api/v1/funding-rate/\{symbol\}/current | GET |
#' | get_funding_history | GET /api/v1/contract/funding-rates | GET |
#' | get_server_time | GET /api/v1/timestamp | GET |
#' | get_service_status | GET /api/v1/status | GET |
#'
#' @examples
#' \dontrun{
#' futures_market <- KucoinFuturesMarketData$new()
#'
#' # Get contract details
#' contract <- futures_market$get_contract("XBTUSDTM")
#'
#' # Get ticker
#' ticker <- futures_market$get_ticker("XBTUSDTM")
#'
#' # Get klines
#' klines <- futures_market$get_klines("XBTUSDTM", granularity = 60)
#'
#' # Get current funding rate
#' rate <- futures_market$get_funding_rate("XBTUSDTM")
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinFuturesMarketData <- R6::R6Class(
  "KucoinFuturesMarketData",
  inherit = KucoinBase,
  public = list(
    #' @description Create a new KucoinFuturesMarketData instance.
    #' @noassert time_source
    #' @param keys (list) API credentials from [get_api_keys()].
    #' @param base_url (scalar<character>) Futures API base URL. Defaults to
    #'   [get_futures_base_url()].
    #' @param async (scalar<logical>) if TRUE, methods return promises.
    #' @param time_source (scalar<character>) `"local"` or `"server"`.
    #' @return (class<KucoinFuturesMarketData>) invisibly, the new instance.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_futures_base_url(),
      async = FALSE,
      time_source = c("local", "server")
    ) {
      assert_args_KucoinFuturesMarketData__initialize(keys, base_url, async)
      super$initialize(keys = keys, base_url = base_url, async = async, time_source = time_source)
      return(invisible(self))
    },

    #' @description Get Contract Details
    #'
    #' Retrieves detailed contract specification for a single symbol.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET to the contract detail endpoint with the symbol in the URL path.
    #' 2. **Parsing**: Returns a single-row `data.table` with all contract specification fields.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/contracts/{symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-symbol)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Contract Discovery**: Query contract specs to determine lot size, tick size, and leverage limits before
    #'   placing orders.
    #' - **Margin Calculations**: Use `initial_margin` and `maintain_margin` rates to pre-validate margin requirements.
    #' - **Fee Estimation**: Read `maker_fee_rate` and `taker_fee_rate` to estimate trading costs.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/contracts/XBTUSDTM'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "XBTUSDTM",
    #'     "rootSymbol": "USDT",
    #'     "type": "FFWCSX",
    #'     "firstOpenDate": 1585555200000,
    #'     "baseCurrency": "XBT",
    #'     "quoteCurrency": "USDT",
    #'     "settleCurrency": "USDT",
    #'     "maxOrderQty": 1000000,
    #'     "maxPrice": 1000000.0,
    #'     "lotSize": 1,
    #'     "tickSize": 0.1,
    #'     "indexPriceTickSize": 0.01,
    #'     "multiplier": 0.001,
    #'     "initialMargin": 0.008,
    #'     "maintainMargin": 0.004,
    #'     "maxRiskLimit": 200,
    #'     "minRiskLimit": 200,
    #'     "riskStep": 100,
    #'     "makerFeeRate": 0.0002,
    #'     "takerFeeRate": 0.0006,
    #'     "makerFixFee": 0.0,
    #'     "takerFixFee": 0.0,
    #'     "isDeleverage": true,
    #'     "isQuanto": false,
    #'     "isInverse": false,
    #'     "markMethod": "FairPrice",
    #'     "fairMethod": "FundingRate",
    #'     "fundingBaseSymbol": ".XBTINT8H",
    #'     "fundingQuoteSymbol": ".USDTINT8H",
    #'     "fundingRateSymbol": ".XBTUSDTMFPI8H",
    #'     "indexSymbol": ".KXBTUSDT",
    #'     "settlementSymbol": "",
    #'     "status": "Open",
    #'     "fundingFeeRate": 0.000065,
    #'     "predictedFundingFeeRate": 0.000035,
    #'     "fundingRateGranularity": 28800000,
    #'     "openInterest": "12584792",
    #'     "turnoverOf24h": 298536274.8925,
    #'     "volumeOf24h": 4382198.0,
    #'     "markPrice": 68125.37,
    #'     "indexPrice": 68120.15,
    #'     "lastTradePrice": 68126.1,
    #'     "nextFundingRateTime": 14399583,
    #'     "maxLeverage": 125,
    #'     "lowPrice": 66800.0,
    #'     "highPrice": 69500.0,
    #'     "priceChgPct": 0.0152,
    #'     "priceChg": 1026.1
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) one row giving the contract
    #'   specification flattened to a single row, carrying the contract symbol,
    #'   root symbol, type, base/quote/settlement currencies, lot and tick sizes,
    #'   value multiplier, initial and maintenance margin rates, maximum leverage,
    #'   maker and taker fee rates, status, mark/index/last-trade prices, current
    #'   and predicted funding fee rates, open interest, 24-hour turnover, volume,
    #'   low and high prices, and the 24-hour price change percentage and amount.
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' contract <- futures_market$get_contract("XBTUSDTM")
    #' print(contract[, .(symbol, lot_size, tick_size, max_leverage)])
    #' }
    get_contract = function(symbol) {
      assert_args_KucoinFuturesMarketData__get_contract(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = paste0("/api/v1/contracts/", symbol),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_contract,
        is_async = private$.is_async
      ))
    },

    #' @description Get All Active Contracts
    #'
    #' Retrieves details of all actively traded futures contracts.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET to the active contracts endpoint.
    #' 2. **Parsing**: Returns a `data.table` with one row per active contract.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/contracts/active`
    #'
    #' ### Official Documentation
    #' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-all-symbols)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Market Scanning**: Iterate over all contracts to find high-volume or high-leverage opportunities.
    #' - **Universe Construction**: Build a trading universe of active perpetual contracts filtered by settle currency.
    #' - **Contract Rotation**: Detect newly listed or delisted contracts by comparing snapshots over time.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/contracts/active'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "symbol": "XBTUSDTM",
    #'       "rootSymbol": "USDT",
    #'       "type": "FFWCSX",
    #'       "baseCurrency": "XBT",
    #'       "quoteCurrency": "USDT",
    #'       "settleCurrency": "USDT",
    #'       "lotSize": 1,
    #'       "tickSize": 0.1,
    #'       "multiplier": 0.001,
    #'       "initialMargin": 0.008,
    #'       "maintainMargin": 0.004,
    #'       "makerFeeRate": 0.0002,
    #'       "takerFeeRate": 0.0006,
    #'       "status": "Open",
    #'       "maxLeverage": 125,
    #'       "markPrice": 68125.37,
    #'       "lastTradePrice": 68126.1,
    #'       "fundingFeeRate": 0.000065
    #'     },
    #'     {
    #'       "symbol": "ETHUSDTM",
    #'       "rootSymbol": "USDT",
    #'       "type": "FFWCSX",
    #'       "baseCurrency": "ETH",
    #'       "quoteCurrency": "USDT",
    #'       "settleCurrency": "USDT",
    #'       "lotSize": 1,
    #'       "tickSize": 0.01,
    #'       "multiplier": 0.01,
    #'       "initialMargin": 0.01,
    #'       "maintainMargin": 0.005,
    #'       "makerFeeRate": 0.0002,
    #'       "takerFeeRate": 0.0006,
    #'       "status": "Open",
    #'       "maxLeverage": 100,
    #'       "markPrice": 3542.15,
    #'       "lastTradePrice": 3542.80,
    #'       "fundingFeeRate": 0.000042
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per active contract,
    #'   carrying the same contract metadata as `get_contract()`.
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' contracts <- futures_market$get_all_contracts()
    #' print(contracts[, .(symbol, status, max_leverage, mark_price)])
    #' }
    get_all_contracts = function() {
      res <- private$.request(
        endpoint = "/api/v1/contracts/active",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_list(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_all_contracts,
        is_async = private$.is_async
      ))
    },

    #' @description Get Futures Ticker
    #'
    #' Retrieves real-time ticker data for a futures contract.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET with the symbol as a query parameter.
    #' 2. **Parsing**: Returns a single-row `data.table`; coerces `ts` from nanoseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/ticker?symbol={symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-ticker)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Price Monitoring**: Poll the ticker to track best bid/ask spreads and last trade prices for signal
    #'   generation.
    #' - **Execution Timing**: Use `side` of the last trade to gauge short-term directional momentum.
    #' - **Spread Analysis**: Compare `best_bid_price` and `best_ask_price` to measure market liquidity.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/ticker?symbol=XBTUSDTM'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "sequence": 1638574985237,
    #'     "symbol": "XBTUSDTM",
    #'     "side": "sell",
    #'     "size": 12,
    #'     "tradeId": "6537b3ae7a12a70007c6b1e0",
    #'     "price": "68125.3",
    #'     "bestBidSize": 356,
    #'     "bestBidPrice": "68125.2",
    #'     "bestAskPrice": "68125.4",
    #'     "bestAskSize": 189,
    #'     "ts": 1698267054123456789
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) one row giving the real-time
    #'   ticker snapshot: the sequence number, contract symbol, last trade side,
    #'   size, trade identifier and price, the best bid and ask prices with their
    #'   sizes, and the ticker datetime (POSIXct, coerced from the nanosecond
    #'   timestamp).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' ticker <- futures_market$get_ticker("XBTUSDTM")
    #' print(ticker[, .(symbol, price, best_bid_price, best_ask_price, ts)])
    #' }
    get_ticker = function(symbol) {
      assert_args_KucoinFuturesMarketData__get_ticker(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/ticker",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_row(data)
          coerce_cols(dt, "ts", ns_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_ticker,
        is_async = private$.is_async
      ))
    },

    #' @description Get All Futures Tickers
    #'
    #' Retrieves real-time ticker data for all futures contracts.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET to the all-tickers endpoint.
    #' 2. **Parsing**: Returns a `data.table` with one row per contract; coerces `ts` from nanoseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/allTickers`
    #'
    #' ### Official Documentation
    #' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-all-tickers)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Market Screening**: Scan all tickers for contracts with the tightest spreads or highest volume.
    #' - **Cross-Market Signals**: Compare price movements across multiple contracts simultaneously.
    #' - **Dashboard Feeds**: Power a real-time monitoring dashboard with a single API call.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/allTickers'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "sequence": 1638574985237,
    #'       "symbol": "XBTUSDTM",
    #'       "side": "sell",
    #'       "size": 12,
    #'       "price": "68125.3",
    #'       "bestBidSize": 356,
    #'       "bestBidPrice": "68125.2",
    #'       "bestAskPrice": "68125.4",
    #'       "bestAskSize": 189,
    #'       "ts": 1698267054123456789
    #'     },
    #'     {
    #'       "sequence": 1638574985122,
    #'       "symbol": "ETHUSDTM",
    #'       "side": "buy",
    #'       "size": 45,
    #'       "price": "3542.15",
    #'       "bestBidSize": 1204,
    #'       "bestBidPrice": "3542.10",
    #'       "bestAskPrice": "3542.20",
    #'       "bestAskSize": 876,
    #'       "ts": 1698267054234567890
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per contract, carrying
    #'   the same ticker fields as `get_ticker()`.
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' all_tickers <- futures_market$get_all_tickers()
    #' print(all_tickers[, .(symbol, price, best_bid_price, best_ask_price)])
    #' }
    get_all_tickers = function() {
      res <- private$.request(
        endpoint = "/api/v1/allTickers",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "ts", ns_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_all_tickers,
        is_async = private$.is_async
      ))
    },

    #' @description Get Partial Orderbook
    #'
    #' Retrieves the top 20 or 100 levels of the orderbook. Does not require
    #' authentication.
    #'
    #' ### Workflow
    #' 1. **Validation**: Checks that `size` is `20` or `100`.
    #' 2. **Request**: Public GET to the depth endpoint with the symbol as a query parameter.
    #' 3. **Parsing**: Converts bid/ask arrays into a long-format `data.table` via `parse_futures_orderbook()`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/level2/depth20?symbol={symbol}`
    #' `GET https://api.kucoin.com/api/v1/level2/depth100?symbol={symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Part Orderbook](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-part-orderbook)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Spread Monitoring**: Use the top-of-book levels to track bid-ask spreads in real time.
    #' - **Depth Analysis**: Assess orderbook depth before placing large orders to estimate slippage.
    #' - **Support/Resistance Detection**: Identify large resting orders that may act as price barriers.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/level2/depth20?symbol=XBTUSDTM'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "XBTUSDTM",
    #'     "sequence": 1638574985237,
    #'     "asks": [
    #'       [68125.4, 189],
    #'       [68125.5, 342],
    #'       [68125.8, 512]
    #'     ],
    #'     "bids": [
    #'       [68125.2, 356],
    #'       [68125.1, 278],
    #'       [68124.9, 441]
    #'     ],
    #'     "ts": 1698267054123456789
    #'   }
    #' }
    #' ```
    #'
    #' @noassert size
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @param size (scalar<count>) number of levels, either `20` or `100`.
    #'   Default `20`.
    #' @return (data.table | promise<data.table>) the level-2 order book in long
    #'   format (ts, sequence, side, level, price, size, and symbol when present).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' ob <- futures_market$get_part_orderbook("XBTUSDTM", size = 20)
    #' print(ob[side == "bid"][order(level)][1:5])
    #' }
    get_part_orderbook = function(symbol, size = 20) {
      assert_args_KucoinFuturesMarketData__get_part_orderbook(symbol)
      assert::assert_nonempty_strings(symbol)
      size <- match.arg(as.character(size), c("20", "100"))
      res <- private$.request(
        endpoint = paste0("/api/v1/level2/depth", size),
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          return(parse_futures_orderbook(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_part_orderbook,
        is_async = private$.is_async
      ))
    },

    #' @description Get Full Orderbook
    #'
    #' Retrieves the full Level 2 orderbook snapshot. **Requires authentication.**
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET to the Level 2 snapshot endpoint.
    #' 2. **Parsing**: Converts bid/ask arrays into a long-format `data.table` via `parse_futures_orderbook()`.
    #'
    #' ### API Endpoint
    #' `GET https://api-futures.kucoin.com/api/v1/level2/snapshot?symbol={symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Full Orderbook](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-full-orderbook)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Full Depth Analysis**: Access every price level to build accurate volume profiles and detect iceberg orders.
    #' - **Orderbook Imbalance**: Compare total bid vs ask volume to gauge directional pressure.
    #' - **Execution Algorithms**: Feed the full orderbook into TWAP/VWAP algorithms for optimal execution.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api-futures.kucoin.com/api/v1/level2/snapshot?symbol=XBTUSDTM' \
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
    #'     "sequence": 1638574985237,
    #'     "asks": [
    #'       [68125.4, 189],
    #'       [68125.5, 342],
    #'       [68125.8, 512],
    #'       [68126.0, 1024]
    #'     ],
    #'     "bids": [
    #'       [68125.2, 356],
    #'       [68125.1, 278],
    #'       [68124.9, 441],
    #'       [68124.5, 890]
    #'     ],
    #'     "ts": 1698267054123456789
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) the level-2 order book in long
    #'   format (ts, sequence, side, level, price, size, and symbol when present).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' full_ob <- futures_market$get_full_orderbook("XBTUSDTM")
    #' print(full_ob[, .N, by = side])
    #' }
    get_full_orderbook = function(symbol) {
      assert_args_KucoinFuturesMarketData__get_full_orderbook(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/level2/snapshot",
        query = list(symbol = symbol),
        auth = TRUE,
        .parser = function(data) {
          return(parse_futures_orderbook(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_full_orderbook,
        is_async = private$.is_async
      ))
    },

    #' @description Get Recent Trade History
    #'
    #' Retrieves the most recent trades for a futures contract.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET with the symbol as a query parameter.
    #' 2. **Parsing**: Returns a `data.table` of recent trades; coerces `ts` from nanoseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/trade/history?symbol={symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-trade-history)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Tape Reading**: Analyze recent trades to detect large block trades or aggressive buying/selling.
    #' - **Volume Confirmation**: Confirm breakout signals by checking if recent trade volume supports the price move.
    #' - **Trade-Flow Analysis**: Track maker vs taker order IDs to understand order flow dynamics.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/trade/history?symbol=XBTUSDTM'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "sequence": 1638574985230,
    #'       "tradeId": "6537b3ae7a12a70007c6b1e0",
    #'       "takerOrderId": "6537b3ae7a12a70007c6b1df",
    #'       "makerOrderId": "6537b3a07a12a70007c6b1c2",
    #'       "price": "68125.3",
    #'       "size": 12,
    #'       "side": "sell",
    #'       "ts": 1698267054123456789
    #'     },
    #'     {
    #'       "sequence": 1638574985229,
    #'       "tradeId": "6537b3ab7a12a70007c6b1de",
    #'       "takerOrderId": "6537b3ab7a12a70007c6b1dd",
    #'       "makerOrderId": "6537b39f7a12a70007c6b1b8",
    #'       "price": "68125.2",
    #'       "size": 5,
    #'       "side": "buy",
    #'       "ts": 1698267051234567890
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) one row per recent trade, each
    #'   giving the trade sequence number, trade identifier, taker and maker order
    #'   identifiers, price, size in contracts, taker side (`"buy"` or `"sell"`),
    #'   and the trade datetime (POSIXct, coerced from the nanosecond timestamp).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' trades <- futures_market$get_trade_history("XBTUSDTM")
    #' print(trades[, .(price, size, side, ts)])
    #' }
    get_trade_history = function(symbol) {
      assert_args_KucoinFuturesMarketData__get_trade_history(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/trade/history",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "ts", ns_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_trade_history,
        is_async = private$.is_async
      ))
    },

    #' @description Get Klines (Candlestick Data)
    #'
    #' Retrieves historical kline/candlestick data for a futures contract.
    #' Supports both single-call mode and automatic multi-segment fetching
    #' for large time ranges.
    #'
    #' ### Workflow
    #' 1. **fetch_all Mode** (when `fetch_all = TRUE`): Segments the time range into chunks of up to 200 candles,
    #'    fetches each segment via `kucoin_fetch_futures_klines()`, deduplicates overlapping boundaries, and
    #'    returns the combined result sorted by `datetime`.
    #' 2. **Single-Call Mode** (default): Sends a single GET request with `from`/`to` query parameters.
    #' 3. **Parsing**: Converts the nested array response into a `data.table` via `parse_futures_klines()`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/kline/query?symbol={symbol}&granularity={granularity}&from={from}&to={to}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-klines)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Technical Analysis**: Feed OHLCV data into indicator calculations (RSI, MACD, Bollinger Bands, etc.).
    #' - **Backtesting**: Use `fetch_all = TRUE` to download complete historical datasets for strategy backtesting.
    #' - **Real-Time Charting**: Poll the latest candle at regular intervals to update live charts.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/kline/query?symbol=XBTUSDTM&granularity=60&from=1698220800000&to=1698307200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     [1698220800000, 68100.0, 68250.5, 68050.2, 68200.1, 15234.0, 1037945.82],
    #'     [1698224400000, 68200.1, 68400.0, 68150.3, 68350.7, 12876.0, 879654.31],
    #'     [1698228000000, 68350.7, 68500.2, 68300.0, 68125.3, 18492.0, 1263571.45]
    #'   ]
    #' }
    #' ```
    #'
    #' @noassert from, to
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @param granularity (scalar<count in [1, Inf[>) candle interval in minutes.
    #'   Supported values: 1, 5, 15, 30, 60, 120, 240, 480, 720, 1440, 10080.
    #' @param from (POSIXct | scalar<numeric> | NULL) start time. If POSIXct,
    #'   converted to milliseconds. If numeric, assumed to be milliseconds.
    #' @param to (POSIXct | scalar<numeric> | NULL) end time.
    #' @param fetch_all (scalar<logical>) if `TRUE`, automatically segments the
    #'   time range into multiple API calls of up to 200 candles each, fetches all
    #'   segments, deduplicates overlapping boundaries, and returns the combined
    #'   result sorted by `datetime`. Both `from` and `to` are required when
    #'   enabled. **Warning**: large date ranges will consume multiple API requests
    #'   and may impact your rate-limit quota. Default `FALSE`.
    #' @param sleep (scalar<numeric in [0, Inf[>) seconds to wait between
    #'   consecutive API calls when `fetch_all = TRUE`. Use this to avoid hitting
    #'   KuCoin rate limits. Only applies in synchronous mode; async mode chains
    #'   requests sequentially via promises. Default `0.2`.
    #' @return (Klines | promise<Klines>) one row per candle ascending by datetime.
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #'
    #' # Single call: last 200 hourly candles
    #' klines <- futures_market$get_klines(
    #'   "XBTUSDTM",
    #'   granularity = 60,
    #'   from = as.numeric(Sys.time() - 200 * 3600) * 1000,
    #'   to = as.numeric(Sys.time()) * 1000
    #' )
    #' print(klines[, .(datetime, open, high, low, close, volume)])
    #'
    #' # Fetch all: complete hourly history for a date range
    #' all_klines <- futures_market$get_klines(
    #'   "XBTUSDTM",
    #'   granularity = 60,
    #'   from = as.POSIXct("2024-10-01", tz = "UTC"),
    #'   to = as.POSIXct("2024-10-31", tz = "UTC"),
    #'   fetch_all = TRUE,
    #'   sleep = 0.3
    #' )
    #' print(nrow(all_klines))
    #' }
    get_klines = function(symbol, granularity, from = NULL, to = NULL, fetch_all = FALSE, sleep = 0.2) {
      assert_args_KucoinFuturesMarketData__get_klines(symbol, granularity, fetch_all, sleep)
      assert::assert_nonempty_strings(symbol)
      # fetch_all mode: segment the time range into multiple API calls
      if (isTRUE(fetch_all)) {
        if (is.null(from) || is.null(to)) {
          rlang::abort("Both `from` and `to` are required when `fetch_all = TRUE`.")
        }
        # Keep as POSIXct for the fetch function. Declare with the
        # already-POSIXct branch as the default; reassign when the
        # input is epoch-ms instead.
        from_posix <- from
        if (!inherits(from, "POSIXct")) {
          from_posix <- as.POSIXct(as.numeric(from) / 1000, origin = "1970-01-01", tz = "UTC")
        }
        to_posix <- to
        if (!inherits(to, "POSIXct")) {
          to_posix <- as.POSIXct(as.numeric(to) / 1000, origin = "1970-01-01", tz = "UTC")
        }
        res <- kucoin_fetch_futures_klines(
          symbol = symbol,
          granularity = granularity,
          from = from_posix,
          to = to_posix,
          .req_fn = private$.request,
          is_async = private$.is_async,
          max_candles = 200L,
          sleep = sleep
        )
        return(connectcore::then_or_now(
          res,
          assert_return_KucoinFuturesMarketData__get_klines,
          is_async = private$.is_async
        ))
      }

      # Single-call mode (default)
      if (inherits(from, "POSIXct")) {
        from <- as.numeric(from) * 1000
      }
      if (inherits(to, "POSIXct")) {
        to <- as.numeric(to) * 1000
      }

      res <- private$.request(
        endpoint = "/api/v1/kline/query",
        query = list(symbol = symbol, granularity = granularity, from = from, to = to),
        auth = FALSE,
        .parser = function(data) {
          return(parse_futures_klines(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_klines,
        is_async = private$.is_async
      ))
    },

    #' @description Get Mark Price
    #'
    #' Retrieves the current mark price for a futures contract. The mark price
    #' is used for margin calculations and liquidation triggers.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET with the symbol in the URL path.
    #' 2. **Parsing**: Returns a single-row `data.table`; coerces `time_point` from milliseconds to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/mark-price/{symbol}/current`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Mark Price](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-mark-price)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Liquidation Monitoring**: Compare mark price against your position entry to track proximity to liquidation.
    #' - **Fair Value Assessment**: Use `index_price` alongside `value` (mark price) to detect basis/premium.
    #' - **PnL Estimation**: Calculate unrealised PnL using the mark price rather than the last trade price.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/mark-price/XBTUSDTM/current'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "XBTUSDTM",
    #'     "granularity": 1000,
    #'     "timePoint": 1698267054000,
    #'     "value": 68125.37,
    #'     "indexPrice": 68120.15
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) one row giving the current mark
    #'   price: the contract symbol, price granularity in milliseconds, the rate
    #'   datetime (POSIXct, coerced from epoch milliseconds), the mark price, and
    #'   the underlying index price.
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' mark <- futures_market$get_mark_price("XBTUSDTM")
    #' print(mark[, .(symbol, value, index_price, time_point)])
    #' }
    get_mark_price = function(symbol) {
      assert_args_KucoinFuturesMarketData__get_mark_price(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = paste0("/api/v1/mark-price/", symbol, "/current"),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_row(data)
          coerce_cols(dt, "time_point", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_mark_price,
        is_async = private$.is_async
      ))
    },

    #' @description Get Current Funding Rate
    #'
    #' Retrieves the current funding rate for a perpetual futures contract.
    #' Funding rates are charged/received every 8 hours for perpetual contracts.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET with the symbol in the URL path.
    #' 2. **Parsing**: Returns a single-row `data.table`; coerces `time_point` and `funding_time` from milliseconds to
    #'    POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/funding-rate/{symbol}/current`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Current Funding Rate](https://www.kucoin.com/docs-new/rest/futures-trading/funding-fees/get-current-funding-rate)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Funding Arbitrage**: Compare funding rates across exchanges to identify cash-and-carry arbitrage
    #'   opportunities.
    #' - **Position Timing**: Avoid entering positions just before a large negative funding rate settlement.
    #' - **Predicted Rate Monitoring**: Use `predicted_value` to anticipate the next funding cycle and adjust positions.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/funding-rate/XBTUSDTM/current'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "XBTUSDTM",
    #'     "granularity": 28800000,
    #'     "timePoint": 1698267054000,
    #'     "value": 0.000065,
    #'     "predictedValue": 0.000035,
    #'     "fundingTime": 1698278400000
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @return (data.table | promise<data.table>) one row giving the current
    #'   funding rate: the contract symbol, funding interval in milliseconds, the
    #'   rate datetime (POSIXct, coerced from epoch milliseconds), the current and
    #'   predicted funding rates, and the next funding settlement datetime (POSIXct,
    #'   coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' rate <- futures_market$get_funding_rate("XBTUSDTM")
    #' print(rate[, .(symbol, value, predicted_value, funding_time)])
    #' }
    get_funding_rate = function(symbol) {
      assert_args_KucoinFuturesMarketData__get_funding_rate(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = paste0("/api/v1/funding-rate/", symbol, "/current"),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_row(data)
          coerce_cols(dt, c("time_point", "funding_time"), ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_funding_rate,
        is_async = private$.is_async
      ))
    },

    #' @description Get Public Funding Rate History
    #'
    #' Retrieves historical funding rates for a futures contract over a
    #' specified time range.
    #'
    #' ### Workflow
    #' 1. **Time Conversion**: Converts POSIXct `from`/`to` to milliseconds if needed.
    #' 2. **Request**: Public GET with `symbol`, `from`, and `to` query parameters.
    #' 3. **Parsing**: Returns a `data.table` with one row per funding settlement; coerces `timepoint` from milliseconds
    #'    to POSIXct.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/contract/funding-rates?symbol={symbol}&from={from}&to={to}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Public Funding Rate History](https://www.kucoin.com/docs-new/rest/futures-trading/funding-fees/get-public-funding-history)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Funding Rate Analysis**: Analyse historical funding rates to understand market sentiment (positive = longs
    #'   pay shorts).
    #' - **Mean Reversion Signals**: Extreme funding rates often precede reversals; use historical data to calibrate
    #'   thresholds.
    #' - **Carry Trade Evaluation**: Calculate cumulative funding paid/received over a time period for carry trade
    #'   analysis.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/contract/funding-rates?symbol=XBTUSDTM&from=1698220800000&to=1698307200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "symbol": "XBTUSDTM",
    #'       "fundingRate": 0.000065,
    #'       "timepoint": 1698220800000
    #'     },
    #'     {
    #'       "symbol": "XBTUSDTM",
    #'       "fundingRate": 0.000042,
    #'       "timepoint": 1698249600000
    #'     },
    #'     {
    #'       "symbol": "XBTUSDTM",
    #'       "fundingRate": 0.000035,
    #'       "timepoint": 1698278400000
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @noassert from, to
    #' @param symbol (scalar<character>) futures symbol (e.g., `"XBTUSDTM"`).
    #' @param from (POSIXct | scalar<numeric>) start time. If POSIXct, converted to
    #'   milliseconds. If numeric, assumed to be milliseconds.
    #' @param to (POSIXct | scalar<numeric>) end time. If POSIXct, converted to
    #'   milliseconds. If numeric, assumed to be milliseconds.
    #' @return (data.table | promise<data.table>) one row per funding settlement,
    #'   each giving the contract symbol, the funding rate for the period, and the
    #'   settlement datetime (POSIXct, coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' history <- futures_market$get_funding_history(
    #'   symbol = "XBTUSDTM",
    #'   from = as.POSIXct("2024-10-25", tz = "UTC"),
    #'   to = as.POSIXct("2024-10-26", tz = "UTC")
    #' )
    #' print(history[, .(symbol, funding_rate, timepoint)])
    #' }
    get_funding_history = function(symbol, from, to) {
      assert_args_KucoinFuturesMarketData__get_funding_history(symbol)
      assert::assert_nonempty_strings(symbol)
      if (inherits(from, "POSIXct")) {
        from <- as.numeric(from) * 1000
      }
      if (inherits(to, "POSIXct")) {
        to <- as.numeric(to) * 1000
      }

      res <- private$.request(
        endpoint = "/api/v1/contract/funding-rates",
        query = list(symbol = symbol, from = from, to = to),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          dt <- as_dt_list(data)
          coerce_cols(dt, "timepoint", ms_to_datetime)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_funding_history,
        is_async = private$.is_async
      ))
    },

    #' @description Get Server Time
    #'
    #' Retrieves the KuCoin Futures server timestamp. Useful for synchronising
    #' local clocks and debugging timestamp-related authentication issues.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET to the timestamp endpoint.
    #' 2. **Parsing**: Wraps the scalar millisecond timestamp into a single-row `data.table` with POSIXct conversion.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/timestamp`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Server Time](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-server-time)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Clock Synchronisation**: Compare server time with local time to detect and compensate for clock drift.
    #' - **Auth Debugging**: Verify that your timestamp is within the acceptable window for HMAC signature generation.
    #' - **Latency Measurement**: Calculate round-trip latency by comparing request send time to server time.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/timestamp'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": 1698267054123
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row giving the server
    #'   datetime (POSIXct, coerced from epoch milliseconds).
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' server_time <- futures_market$get_server_time()
    #' print(server_time$server_time)
    #' }
    get_server_time = function() {
      res <- private$.request(
        endpoint = "/api/v1/timestamp",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          return(data.table::data.table(server_time = ms_to_datetime(data))[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_server_time,
        is_async = private$.is_async
      ))
    },

    #' @description Get Service Status
    #'
    #' Retrieves the current service status of the KuCoin Futures exchange.
    #' Check this before placing orders to confirm the exchange is operational.
    #'
    #' ### Workflow
    #' 1. **Request**: Public GET to the status endpoint.
    #' 2. **Parsing**: Returns a single-row `data.table` with the service status and message.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/status`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Service Status](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-service-status)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Health Check**: Poll service status at bot startup and periodically during operation to detect maintenance
    #'   windows.
    #' - **Graceful Degradation**: When status is `"close"`, pause order placement and alert the operator.
    #' - **Maintenance Scheduling**: Use the `msg` field to extract maintenance window details for automated scheduling.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/status'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "status": "open",
    #'     "msg": ""
    #'   }
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row giving the operational
    #'   status (`"open"`, `"close"`, or `"cancelonly"`) and an optional
    #'   remark/message.
    #'
    #' @examples
    #' \dontrun{
    #' futures_market <- KucoinFuturesMarketData$new()
    #' status <- futures_market$get_service_status()
    #' if (status$status == "open") message("Exchange is operational")
    #' }
    get_service_status = function() {
      res <- private$.request(
        endpoint = "/api/v1/status",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0L) {
            return(data.table::data.table()[])
          }
          return(as_dt_row(data)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinFuturesMarketData__get_service_status,
        is_async = private$.is_async
      ))
    }
  )
)

# ---------------------------------------------------------------------------
# Internal parsers for futures-specific response shapes
# ---------------------------------------------------------------------------

#' Parse Futures Orderbook into a data.table
#'
#' Futures orderbook entries are `[price_num, size_int]` (numeric values, not
#' strings like spot). Timestamps are nanoseconds in `ts` field.
#'
#' @param data (list) the parsed orderbook response.
#' @return (class<data.table>) the futures order book in long format.
#' @keywords internal
#' @noRd
parse_futures_orderbook <- function(data) {
  assert_args_parse_futures_orderbook(data)
  parse_side <- function(entries, side_label) {
    if (is.null(entries) || length(entries) == 0) {
      return(data.table::data.table(
        side = character(),
        level = integer(),
        price = numeric(),
        size = numeric()
      )[])
    }
    # KuCoin returns best price first; `level = 1` is the top of the
    # book for the given side. Matches `parse_orderbook` (spot) and the
    # cross-package long-format convention.
    return(data.table::data.table(
      side = side_label,
      level = seq_along(entries),
      price = vapply(entries, function(e) as.numeric(e[[1]]), numeric(1)),
      size = vapply(entries, function(e) as.numeric(e[[2]]), numeric(1))
    )[])
  }

  bids_dt <- parse_side(data$bids, "bid")
  asks_dt <- parse_side(data$asks, "ask")
  result <- data.table::rbindlist(list(bids_dt, asks_dt))

  result[, ts := ns_to_datetime(data$ts)]
  result[, sequence := as.character(data$sequence)]
  if (!is.null(data$symbol)) {
    result[, symbol := data$symbol]
  }
  data.table::setcolorder(result, c("ts", "sequence", "side", "level", "price", "size"))

  return(assert_return_parse_futures_orderbook(result[]))
}

#' Parse Futures Klines into a data.table
#'
#' Futures klines are `[timestamp_ms, open, high, low, close, volume, turnover]`
#' with numeric values (not strings like spot).
#'
#' @param data (list | NULL) list of numeric vectors.
#' @return (Klines) one row per candle.
#' @keywords internal
#' @noRd
parse_futures_klines <- function(data) {
  assert_args_parse_futures_klines(data)
  if (is.null(data) || length(data) == 0) {
    return(assert_return_parse_futures_klines(empty_dt_klines()))
  }
  return(assert_return_parse_futures_klines(data.table::data.table(
    datetime = ms_to_datetime(vapply(data, `[[`, numeric(1), 1L)),
    open = vapply(data, `[[`, numeric(1), 2L),
    high = vapply(data, `[[`, numeric(1), 3L),
    low = vapply(data, `[[`, numeric(1), 4L),
    close = vapply(data, `[[`, numeric(1), 5L),
    volume = vapply(data, function(e) as.numeric(e[[6]]), numeric(1)),
    turnover = vapply(data, function(e) as.numeric(e[[7]]), numeric(1))
  )[]))
}
