# File: R/KucoinMarketData.R
# R6 class for KuCoin Spot market data retrieval.

#' KucoinMarketData: Spot Market Data Retrieval
#'
#' Provides methods for retrieving market data from KuCoin's Spot trading API,
#' including announcements, klines, currencies, symbols, tickers, orderbooks,
#' trade history, and 24-hour statistics.
#'
#' Inherits from [KucoinBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Announcements**: Fetch paginated KuCoin platform announcements filtered by type, language, and date range.
#' - **Currencies**: Retrieve metadata for individual or all listed currencies, including chain-specific
#'   deposit/withdrawal details.
#' - **Symbols**: Retrieve trading pair metadata including precision, size limits, fee rates, and trading status.
#' - **Tickers**: Access real-time Level 1 best bid/ask data for individual symbols or all pairs.
#' - **Order Books**: Get partial (20/100 levels) or full depth order book snapshots.
#' - **Trade History**: Retrieve the most recent 100 trades for any symbol.
#' - **24hr Statistics**: Get rolling 24-hour market statistics (OHLCV, change rate, fees).
#' - **Market List**: Discover all available market segments (e.g., USDS, DeFi, Meme).
#' - **Klines**: Fetch historical candlestick data with automatic time-range segmentation to bypass the
#'   1500-candle-per-request limit.
#'
#' ### Usage
#' Most methods are public endpoints requiring no authentication. The one exception
#' is `get_full_orderbook()` which requires valid API credentials.
#'
#' ### Official Documentation
#' [KuCoin Spot Market Data](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Auth |
#' |--------|----------|------|
#' | get_announcements | GET /api/v3/announcements | No |
#' | get_currency | GET /api/v3/currencies/\{currency\} | No |
#' | get_all_currencies | GET /api/v3/currencies | No |
#' | get_symbol | GET /api/v2/symbols/\{symbol\} | No |
#' | get_all_symbols | GET /api/v2/symbols | No |
#' | get_ticker | GET /api/v1/market/orderbook/level1 | No |
#' | get_all_tickers | GET /api/v1/market/allTickers | No |
#' | get_trade_history | GET /api/v1/market/histories | No |
#' | get_part_orderbook | GET /api/v1/market/orderbook/level2_\{size\} | No |
#' | get_full_orderbook | GET /api/v3/market/orderbook/level2 | Yes |
#' | get_24hr_stats | GET /api/v1/market/stats | No |
#' | get_market_list | GET /api/v1/markets | No |
#' | get_klines | GET /api/v1/market/candles | No |
#' | get_server_time | GET /api/v1/timestamp | No |
#' | get_service_status | GET /api/v1/status | No |
#' | get_fiat_prices | GET /api/v1/prices | No |
#'
#' @examples
#' \dontrun{
#' # Synchronous usage
#' market <- KucoinMarketData$new()
#' ticker <- market$get_ticker("BTC-USDT")
#' print(ticker)
#'
#' # Asynchronous usage
#' market_async <- KucoinMarketData$new(async = TRUE)
#' main <- coro::async(function() {
#'   ticker <- await(market_async$get_ticker("BTC-USDT"))
#'   print(ticker)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom lubridate as_datetime now dhours
#' @export
KucoinMarketData <- R6::R6Class(
  "KucoinMarketData",
  inherit = KucoinBase,
  public = list(
    #' @description
    #' Get Announcements
    #'
    #' Retrieves paginated market announcements from KuCoin. Announcements include
    #' new listings, delistings, maintenance notices, and other platform updates.
    #'
    #' ### Workflow
    #' 1. **Request**: Sends paginated GET request with optional filters.
    #' 2. **Pagination**: Automatically fetches multiple pages via `.paginate()`.
    #' 3. **Parsing**: Flattens paginated results into a single `data.table`.
    #' 4. **Timestamp Conversion**: Coerces `c_time` (ms) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/announcements`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Announcements](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **New Listing Detection**: Monitor for new token listings to automate early trading strategies.
    #' - **Maintenance Alerts**: Detect scheduled maintenance windows to pause trading bots.
    #' - **Delisting Warnings**: Identify tokens being delisted to trigger position exit logic.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/announcements?currentPage=1&pageSize=50&annType=latest-announcements&lang=en_US'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "totalNum": 195,
    #'     "totalPage": 13,
    #'     "currentPage": 1,
    #'     "pageSize": 15,
    #'     "items": [
    #'       {
    #'         "annId": 129045,
    #'         "annTitle": "KuCoin Will List Token XYZ",
    #'         "annType": ["latest-announcements"],
    #'         "annDesc": "Description of announcement...",
    #'         "cTime": 1729594043000,
    #'         "language": "en_US",
    #'         "annUrl": "https://www.kucoin.com/announcement/..."
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param query (list) filter parameters. Supported keys: `annType`
    #'   (announcement type filter e.g. `"latest-announcements"`, `"activities"`,
    #'   `"new-listings"`, `"product-updates"`), `lang` (language code e.g.
    #'   `"en_US"`, `"zh_CN"`), `startTime` (start timestamp in milliseconds), and
    #'   `endTime` (end timestamp in milliseconds).
    #' @param page_size (scalar<count in [1, Inf[>) results per page (default 50,
    #'   max 100).
    #' @param max_pages (scalar<numeric in [1, Inf]>) maximum number of pages to
    #'   fetch (default `Inf` for all).
    #' @return (data.table | promise<data.table>) one row per announcement, each
    #'   giving the announcement ID, title, `;`-separated category tags, short
    #'   description, creation datetime (POSIXct, coerced from epoch milliseconds),
    #'   language code, and the full announcement URL:
    #' - ann_id (integer) the ann id.
    #' - ann_title (character | NA) the ann title.
    #' - ann_type (character | NA) the ann type.
    #' - ann_desc (character | NA) the ann desc.
    #' - c_time (POSIXct) the c time (UTC).
    #' - language (character) the language.
    #' - ann_url (character | NA) the ann url.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #'
    #' # Get latest announcements
    #' anns <- market$get_announcements()
    #' print(anns[, .(ann_id, ann_title, c_time)])
    #'
    #' # Filter by type and language
    #' listings <- market$get_announcements(
    #'   query = list(annType = "new-listings", lang = "en_US"),
    #'   page_size = 20,
    #'   max_pages = 3
    #' )
    #' }
    get_announcements = function(query = list(), page_size = 50, max_pages = Inf) {
      assert_args_KucoinMarketData__get_announcements(query, page_size, max_pages)
      res <- private$.paginate(
        endpoint = "/api/v3/announcements",
        query = query,
        auth = FALSE,
        .parser = function(pages) {
          if (length(pages) == 0) {
            return(data.table::data.table()[])
          }
          # Treatment A: `annType` is an array of plain strings (e.g.
          # `c("latest-announcements", "new-listings")`). Collapse to a
          # single `;`-separated character column via the shared helper
          # so we keep one row per announcement (no list-column, no row
          # multiplication). Matches the cross-package convention used
          # by `alpaca`/`binance` for `permissions`, `order_types`, etc.
          pages_clean <- lapply(pages, function(page) {
            return(lapply(page, collapse_string_array_fields, "annType"))
          })
          dt <- flatten_pages(pages_clean)
          if (nrow(dt) == 0) {
            return(dt[])
          }
          coerce_cols(dt, "c_time", ms_to_datetime)
          return(dt[])
        },
        page_size = page_size,
        max_pages = max_pages
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_announcements,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Currency Details
    #'
    #' Retrieves metadata for a specific currency, including per-chain deposit and
    #' withdrawal details (fees, minimums, confirmations, contract addresses).
    #'
    #' ### Workflow
    #' 1. **Request**: GET with currency code in URL path, optional chain filter.
    #' 2. **Parsing**: Extracts top-level currency fields and nested `chains` array.
    #' 3. **Flattening**: Combines currency metadata with chain details via `cbind`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/currencies/{currency}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Deposit Monitoring**: Check `is_deposit_enabled` and `deposit_min_size` before initiating deposits.
    #' - **Withdrawal Validation**: Verify `is_withdraw_enabled`, `withdrawal_min_size`, `withdrawal_min_fee`,
    #'   and `withdraw_precision` before submitting withdrawals.
    #' - **Chain Selection**: Compare fees and confirmation times across chains to optimise transfers.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/currencies/BTC'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "currency": "BTC",
    #'     "name": "BTC",
    #'     "fullName": "Bitcoin",
    #'     "precision": 8,
    #'     "confirms": null,
    #'     "contractAddress": null,
    #'     "isMarginEnabled": true,
    #'     "isDebitEnabled": true,
    #'     "chains": [
    #'       {
    #'         "chainName": "BTC",
    #'         "withdrawalMinSize": "0.001",
    #'         "depositMinSize": "0.0002",
    #'         "withdrawFeeRate": "0",
    #'         "withdrawalMinFee": "0.0005",
    #'         "isWithdrawEnabled": true,
    #'         "isDepositEnabled": true,
    #'         "confirms": 3,
    #'         "preConfirms": 1,
    #'         "contractAddress": "",
    #'         "withdrawPrecision": 8,
    #'         "maxWithdraw": null,
    #'         "maxDeposit": null,
    #'         "needTag": false,
    #'         "chainId": "btc"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @param currency (scalar<character>) currency code (e.g., `"BTC"`, `"ETH"`,
    #'   `"USDT"`).
    #' @param chain (scalar<character> | NULL) specific chain to filter (e.g.,
    #'   `"ERC20"`, `"TRC20"`).
    #' @return (data.table | promise<data.table>) one row per chain for the
    #'   currency, each combining the currency metadata (code, short name, full
    #'   name, precision, and the margin- and debit-enabled flags) with that
    #'   chain's details (network name, minimum withdrawal/deposit sizes, minimum
    #'   withdrawal fee, withdraw- and deposit-enabled flags, required and
    #'   pre-confirmations, contract address, withdrawal precision, the memo/tag
    #'   requirement flag, and chain identifier).
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' btc <- market$get_currency("BTC")
    #' print(btc[, .(chain_name, withdrawal_min_fee, is_deposit_enabled, confirms)])
    #'
    #' # Specific chain
    #' usdt_erc20 <- market$get_currency("USDT", chain = "ERC20")
    #' }
    get_currency = function(currency, chain = NULL) {
      assert_args_KucoinMarketData__get_currency(currency, chain)
      assert::assert_nonempty_strings(currency)
      res <- private$.request(
        endpoint = paste0("/api/v3/currencies/", currency),
        query = list(chain = chain),
        auth = FALSE,
        .parser = function(data) {
          chains <- data$chains
          data$chains <- NULL
          summary_dt <- as_dt_row(data)

          if (!is.null(chains) && length(chains) > 0) {
            chains_dt <- data.table::rbindlist(
              lapply(chains, as_dt_row),
              fill = TRUE
            )
            if (nrow(summary_dt) > 0 && nrow(chains_dt) > 0) {
              # Remove columns from summary that also exist in chains to avoid duplicates
              dup_cols <- intersect(names(summary_dt), names(chains_dt))
              if (length(dup_cols) > 0) {
                summary_dt[, (dup_cols) := NULL]
              }
              return(cbind(summary_dt, chains_dt))
            }
            return(chains_dt)
          }
          return(summary_dt)
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_currency,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get All Currencies
    #'
    #' Retrieves metadata for all listed currencies, including chain-specific
    #' deposit/withdrawal details. Useful for building currency reference tables.
    #'
    #' ### Workflow
    #' 1. **Request**: GET for all currencies (no parameters).
    #' 2. **Parsing**: Iterates over each currency, extracting chain details.
    #' 3. **Flattening**: Combines per-currency metadata with chain arrays into rows.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/currencies`
    #'
    #' ### Official Documentation
    #' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Universe Construction**: Build a reference table of all supported assets.
    #' - **Chain Discovery**: Determine which blockchains are available for each asset.
    #' - **Fee Comparison**: Compare withdrawal fees across all assets for arbitrage costing.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v3/currencies'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "currency": "BTC",
    #'       "name": "BTC",
    #'       "fullName": "Bitcoin",
    #'       "precision": 8,
    #'       "confirms": null,
    #'       "contractAddress": null,
    #'       "isMarginEnabled": true,
    #'       "isDebitEnabled": true,
    #'       "chains": [
    #'         {
    #'           "chainName": "BTC",
    #'           "withdrawalMinSize": "0.001",
    #'           "depositMinSize": "0.0002",
    #'           "withdrawalMinFee": "0.0005",
    #'           "isWithdrawEnabled": true,
    #'           "isDepositEnabled": true,
    #'           "confirms": 3,
    #'           "preConfirms": 1,
    #'           "contractAddress": "",
    #'           "withdrawPrecision": 8,
    #'           "needTag": false,
    #'           "chainId": "btc"
    #'         }
    #'       ]
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per currency-chain
    #'   combination, carrying the same currency metadata and chain details as
    #'   `get_currency()`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' all_currencies <- market$get_all_currencies()
    #' # Find all ERC20 tokens
    #' erc20 <- all_currencies[chain_name == "ERC20"]
    #' print(erc20[, .(currency, withdrawal_min_fee, is_deposit_enabled)])
    #' }
    get_all_currencies = function() {
      res <- private$.request(
        endpoint = "/api/v3/currencies",
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          rows <- lapply(data, function(item) {
            chains <- item$chains
            item$chains <- NULL
            summary_row <- as_dt_row(item)
            if (!is.null(chains) && length(chains) > 0) {
              chains_dt <- data.table::rbindlist(
                lapply(chains, as_dt_row),
                fill = TRUE
              )
              return(cbind(summary_row, chains_dt))
            }
            return(summary_row)
          })
          return(data.table::rbindlist(rows, fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_all_currencies,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Symbol Details
    #'
    #' Retrieves trading pair metadata for a specific symbol, including precision
    #' increments, size limits, fee rates, and trading status.
    #'
    #' ### Workflow
    #' 1. **Request**: GET with symbol in URL path.
    #' 2. **Parsing**: Returns single-row `data.table` with all symbol fields.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v2/symbols/{symbol}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-symbol)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Order Validation**: Read `price_increment`, `base_increment`, `base_min_size`, and
    #'   `quote_min_size` to validate order parameters before submission.
    #' - **Trading Status**: Check `enable_trading` before attempting to place orders.
    #' - **Fee Calculation**: Use `maker_fee_coefficient` and `taker_fee_coefficient` for
    #'   accurate P&L estimation.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v2/symbols/BTC-USDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "symbol": "BTC-USDT",
    #'     "name": "BTC-USDT",
    #'     "baseCurrency": "BTC",
    #'     "quoteCurrency": "USDT",
    #'     "feeCurrency": "USDT",
    #'     "market": "USDS",
    #'     "baseMinSize": "0.00001",
    #'     "quoteMinSize": "0.1",
    #'     "baseMaxSize": "10000000000",
    #'     "quoteMaxSize": "99999999",
    #'     "baseIncrement": "0.00000001",
    #'     "quoteIncrement": "0.000001",
    #'     "priceIncrement": "0.1",
    #'     "priceLimitRate": "0.1",
    #'     "minFunds": "0.1",
    #'     "isMarginEnabled": true,
    #'     "enableTrading": true,
    #'     "feeCategory": 1,
    #'     "makerFeeCoefficient": "1.00",
    #'     "takerFeeCoefficient": "1.00",
    #'     "st": false
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading symbol (e.g., `"BTC-USDT"`).
    #' @return (data.table | promise<data.table>) one row giving the symbol
    #'   metadata: the pair identifier, base/quote/fee currencies, market segment,
    #'   the base and quote minimum and maximum order sizes, the base and quote
    #'   size increments, the price increment and price-limit rate, the minimum
    #'   order value in quote currency, the margin- and trading-enabled flags, and
    #'   the maker and taker fee coefficients:
    #' - symbol (character) the trading pair symbol.
    #' - name (character) the name.
    #' - base_currency (character) the base currency.
    #' - quote_currency (character) the quote currency.
    #' - fee_currency (character) the fee currency.
    #' - market (character) the market.
    #' - base_min_size (character | NA) the base min size.
    #' - quote_min_size (character | NA) the quote min size.
    #' - base_max_size (character | NA) the base max size.
    #' - quote_max_size (character | NA) the quote max size.
    #' - base_increment (character | NA) the base increment.
    #' - quote_increment (character | NA) the quote increment.
    #' - price_increment (character | NA) the price increment.
    #' - price_limit_rate (character | NA) the price limit rate.
    #' - min_funds (character | NA) the min funds.
    #' - is_margin_enabled (logical) the is margin enabled.
    #' - enable_trading (logical) the enable trading.
    #' - fee_category (integer) the fee category.
    #' - maker_fee_coefficient (character | NA) the maker fee coefficient.
    #' - taker_fee_coefficient (character | NA) the taker fee coefficient.
    #' - st (logical) whether the symbol is in special treatment.
    #' - callauction_is_enabled (logical) the callauction is enabled.
    #' - callauction_price_floor (character | NA) the callauction price floor.
    #' - callauction_price_ceiling (character | NA) the callauction price ceiling.
    #' - callauction_first_stage_start_time (numeric | NA) the callauction first stage start time (epoch ms).
    #' - callauction_second_stage_start_time (numeric | NA) the callauction second stage start time (epoch ms).
    #' - callauction_third_stage_start_time (numeric | NA) the callauction third stage start time (epoch ms).
    #' - trading_start_time (numeric | NA) the trading start time (epoch ms).
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' btc <- market$get_symbol("BTC-USDT")
    #' print(btc[, .(price_increment, base_increment, base_min_size, enable_trading)])
    #' }
    get_symbol = function(symbol) {
      assert_args_KucoinMarketData__get_symbol(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = paste0("/api/v2/symbols/", symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          # KuCoin returns the call-auction fields as null for non-auction
          # symbols; coerce so each column lands as its documented type (price
          # strings / epoch-ms numerics) rather than an all-logical NA vector.
          coerce_cols(dt, c("callauction_price_floor", "callauction_price_ceiling"), as.character)
          coerce_cols(
            dt,
            c(
              "callauction_first_stage_start_time",
              "callauction_second_stage_start_time",
              "callauction_third_stage_start_time",
              "trading_start_time"
            ),
            as.numeric
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_symbol,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get All Symbols
    #'
    #' Retrieves metadata for all trading pairs, optionally filtered by market
    #' segment. Returns the same fields as `get_symbol()` for every pair.
    #'
    #' ### Workflow
    #' 1. **Request**: GET with optional `market` query parameter.
    #' 2. **Parsing**: Converts array of symbol objects to `data.table` rows.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v2/symbols`
    #'
    #' ### Official Documentation
    #' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Universe Filtering**: Filter by `market`, `enable_trading`, `is_margin_enabled` to
    #'   build your trading universe.
    #' - **Precision Lookup**: Cache the result and look up `price_increment` / `base_increment`
    #'   before placing orders.
    #' - **New Pair Detection**: Compare against a cached version to detect newly listed pairs.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v2/symbols?market=USDS'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "symbol": "BTC-USDT",
    #'       "name": "BTC-USDT",
    #'       "baseCurrency": "BTC",
    #'       "quoteCurrency": "USDT",
    #'       "feeCurrency": "USDT",
    #'       "market": "USDS",
    #'       "baseMinSize": "0.00001",
    #'       "quoteMinSize": "0.1",
    #'       "baseMaxSize": "10000000000",
    #'       "quoteMaxSize": "99999999",
    #'       "baseIncrement": "0.00000001",
    #'       "quoteIncrement": "0.000001",
    #'       "priceIncrement": "0.1",
    #'       "priceLimitRate": "0.1",
    #'       "minFunds": "0.1",
    #'       "isMarginEnabled": true,
    #'       "enableTrading": true,
    #'       "feeCategory": 1,
    #'       "makerFeeCoefficient": "1.00",
    #'       "takerFeeCoefficient": "1.00",
    #'       "st": false
    #'     },
    #'     {
    #'       "symbol": "ETH-USDT",
    #'       "name": "ETH-USDT",
    #'       "baseCurrency": "ETH",
    #'       "quoteCurrency": "USDT",
    #'       "feeCurrency": "USDT",
    #'       "market": "USDS",
    #'       "baseMinSize": "0.0001",
    #'       "quoteMinSize": "0.1",
    #'       "baseMaxSize": "10000000000",
    #'       "quoteMaxSize": "99999999",
    #'       "baseIncrement": "0.0000001",
    #'       "quoteIncrement": "0.000001",
    #'       "priceIncrement": "0.01",
    #'       "priceLimitRate": "0.1",
    #'       "minFunds": "0.1",
    #'       "isMarginEnabled": true,
    #'       "enableTrading": true,
    #'       "feeCategory": 1,
    #'       "makerFeeCoefficient": "1.00",
    #'       "takerFeeCoefficient": "1.00",
    #'       "st": false
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param market (scalar<character> | NULL) market segment filter (e.g.,
    #'   `"USDS"`, `"BTC"`, `"KCS"`, `"DeFi"`). Use `get_market_list()` for
    #'   available values.
    #' @return (data.table | promise<data.table>) one row per trading pair,
    #'   carrying the same symbol metadata as `get_symbol()`:
    #' - symbol (character) the trading pair symbol.
    #' - name (character) the name.
    #' - base_currency (character) the base currency.
    #' - quote_currency (character) the quote currency.
    #' - fee_currency (character) the fee currency.
    #' - market (character) the market.
    #' - base_min_size (character | NA) the base min size.
    #' - quote_min_size (character | NA) the quote min size.
    #' - base_max_size (character | NA) the base max size.
    #' - quote_max_size (character | NA) the quote max size.
    #' - base_increment (character | NA) the base increment.
    #' - quote_increment (character | NA) the quote increment.
    #' - price_increment (character | NA) the price increment.
    #' - price_limit_rate (character | NA) the price limit rate.
    #' - min_funds (character | NA) the min funds.
    #' - is_margin_enabled (logical) the is margin enabled.
    #' - enable_trading (logical) the enable trading.
    #' - fee_category (integer) the fee category.
    #' - maker_fee_coefficient (character | NA) the maker fee coefficient.
    #' - taker_fee_coefficient (character | NA) the taker fee coefficient.
    #' - st (logical) whether the symbol is in special treatment.
    #' - callauction_is_enabled (logical) the callauction is enabled.
    #' - callauction_price_floor (character | NA) the callauction price floor.
    #' - callauction_price_ceiling (character | NA) the callauction price ceiling.
    #' - callauction_first_stage_start_time (numeric | NA) the callauction first stage start time (epoch ms).
    #' - callauction_second_stage_start_time (numeric | NA) the callauction second stage start time (epoch ms).
    #' - callauction_third_stage_start_time (numeric | NA) the callauction third stage start time (epoch ms).
    #' - trading_start_time (numeric | NA) the trading start time (epoch ms).
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' all_symbols <- market$get_all_symbols()
    #' # Filter to active USDT pairs
    #' usdt_pairs <- all_symbols[quote_currency == "USDT" & enable_trading == TRUE]
    #' print(usdt_pairs[, .(symbol, base_min_size, price_increment)])
    #' }
    get_all_symbols = function(market = NULL) {
      assert_args_KucoinMarketData__get_all_symbols(market)
      res <- private$.request(
        endpoint = "/api/v2/symbols",
        query = list(market = market),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(lapply(data, as_dt_row), fill = TRUE)
          # As in get_symbol: coerce the call-auction fields (null for
          # non-auction symbols) to their documented types.
          coerce_cols(dt, c("callauction_price_floor", "callauction_price_ceiling"), as.character)
          coerce_cols(
            dt,
            c(
              "callauction_first_stage_start_time",
              "callauction_second_stage_start_time",
              "callauction_third_stage_start_time",
              "trading_start_time"
            ),
            as.numeric
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_all_symbols,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Ticker (Level 1 Market Data)
    #'
    #' Retrieves real-time Level 1 ticker data for a symbol: the best bid/ask
    #' prices, sizes, and the most recent trade price and size.
    #'
    #' ### Workflow
    #' 1. **Request**: GET with `symbol` query parameter.
    #' 2. **Parsing**: Single-row `data.table` with ticker fields.
    #' 3. **Timestamp Conversion**: Coerces `time` (ms) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/market/orderbook/level1`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Spread Monitoring**: Calculate `best_ask - best_bid` for spread-based strategies.
    #' - **Price Feeds**: Use as a lightweight price feed for mid-price calculation.
    #' - **Execution Timing**: Monitor `sequence` to detect order book changes.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/market/orderbook/level1?symbol=BTC-USDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "time": 1729172965609,
    #'     "sequence": "14609309753",
    #'     "price": "67269",
    #'     "size": "0.000025",
    #'     "bestBid": "67267.5",
    #'     "bestBidSize": "0.000025",
    #'     "bestAsk": "67267.6",
    #'     "bestAskSize": "1.24808993"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading symbol (e.g., `"BTC-USDT"`).
    #' @return (data.table | promise<data.table>) one row giving the Level 1
    #'   snapshot: server datetime (POSIXct, coerced from epoch milliseconds), the
    #'   order book sequence number, the last trade price and size, and the best
    #'   bid and ask prices with their sizes:
    #' - time (POSIXct) the time (UTC).
    #' - sequence (character) the sequence.
    #' - price (character | NA) the price.
    #' - size (character | NA) the size.
    #' - best_bid (character | NA) the best bid price.
    #' - best_bid_size (character | NA) the best bid size.
    #' - best_ask (character | NA) the best ask price.
    #' - best_ask_size (character | NA) the best ask size.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' ticker <- market$get_ticker("BTC-USDT")
    #' spread <- as.numeric(ticker$best_ask) - as.numeric(ticker$best_bid)
    #' print(paste("Spread:", spread))
    #' }
    get_ticker = function(symbol) {
      assert_args_KucoinMarketData__get_ticker(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/market/orderbook/level1",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
            data.table::setcolorder(dt, c("time"))
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_ticker,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get All Tickers
    #'
    #' Retrieves ticker data for all trading pairs in a single request.
    #' Snapshots are captured every 2 seconds on the server side.
    #'
    #' ### Workflow
    #' 1. **Request**: GET with no parameters (public, rate limit weight 15).
    #' 2. **Parsing**: Extracts global `time` and array of `ticker` objects.
    #' 3. **Flattening**: Converts ticker array to `data.table`, adds `time`.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/market/allTickers`
    #'
    #' ### Official Documentation
    #' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Market Screening**: Scan all pairs for volume, change rate, or spread anomalies.
    #' - **Pair Selection**: Rank pairs by `vol_value` to focus on liquid markets.
    #' - **Cross-Pair Analysis**: Detect arbitrage opportunities across related pairs.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/market/allTickers'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "time": 1729173207043,
    #'     "ticker": [
    #'       {
    #'         "symbol": "BTC-USDT",
    #'         "symbolName": "BTC-USDT",
    #'         "buy": "67192.5",
    #'         "bestBidSize": "0.000025",
    #'         "sell": "67192.6",
    #'         "bestAskSize": "1.24949204",
    #'         "changeRate": "-0.0014",
    #'         "changePrice": "-98.5",
    #'         "high": "68321.4",
    #'         "low": "66683.3",
    #'         "vol": "1836.03034612",
    #'         "volValue": "124068431.06726933",
    #'         "last": "67193",
    #'         "averagePrice": "67281.21437289",
    #'         "takerFeeRate": "0.001",
    #'         "makerFeeRate": "0.001",
    #'         "takerCoefficient": "1",
    #'         "makerCoefficient": "1"
    #'       }
    #'     ]
    #'   }
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per trading pair, each
    #'   giving the pair symbol and display name, the best bid and ask prices with
    #'   their sizes, the 24-hour change rate and amount, the 24-hour high, low,
    #'   base-currency volume and quote-currency volume, the last trade and average
    #'   prices, the taker and maker fee rates, and the snapshot datetime (POSIXct,
    #'   coerced from epoch milliseconds):
    #' - symbol (character) the trading pair symbol.
    #' - symbol_name (character) the symbol name.
    #' - buy (character | NA) the best bid price.
    #' - sell (character | NA) the best ask price.
    #' - change_rate (character | NA) the 24h change rate.
    #' - change_price (character | NA) the 24h change in price.
    #' - high (character | NA) the 24h high price.
    #' - low (character | NA) the 24h low price.
    #' - vol (character | NA) the 24h traded volume.
    #' - vol_value (character | NA) the 24h traded turnover.
    #' - last (character | NA) the last traded price.
    #' - average_price (character | NA) the average price.
    #' - taker_fee_rate (character | NA) the taker fee rate.
    #' - maker_fee_rate (character | NA) the maker fee rate.
    #' - time (POSIXct) the time (UTC).
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' all_tickers <- market$get_all_tickers()
    #' # Top 10 by 24h volume
    #' all_tickers[, vol_value := as.numeric(vol_value)]
    #' top10 <- all_tickers[order(-vol_value)][1:10]
    #' print(top10[, .(symbol, vol_value, change_rate)])
    #' }
    get_all_tickers = function() {
      res <- private$.request(
        endpoint = "/api/v1/market/allTickers",
        auth = FALSE,
        .parser = function(data) {
          global_time <- data$time
          tickers <- data$ticker
          if (is.null(tickers) || length(tickers) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(
            lapply(tickers, as_dt_row),
            fill = TRUE
          )
          dt[, time := ms_to_datetime(global_time)]
          data.table::setcolorder(dt, c("symbol", "symbol_name"))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_all_tickers,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Trade History
    #'
    #' Retrieves the most recent 100 trades for a symbol. Each trade includes
    #' the price, size, side (buy/sell), and nanosecond-precision timestamp.
    #'
    #' ### Workflow
    #' 1. **Request**: GET with `symbol` query parameter.
    #' 2. **Parsing**: Converts array of trade objects to `data.table`.
    #' 3. **Timestamp Conversion**: Coerces `time` (nanoseconds) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/market/histories`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Volume Analysis**: Aggregate recent trade sizes to estimate real-time volume flow.
    #' - **Trade Direction**: Analyse buy/sell ratio for order flow imbalance signals.
    #' - **Execution Benchmarking**: Compare your fills against recent market trades.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/market/histories?symbol=BTC-USDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     {
    #'       "sequence": "10976028003549185",
    #'       "price": "67122",
    #'       "size": "0.000025",
    #'       "side": "buy",
    #'       "time": 1729177117877000000
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading symbol (e.g., `"BTC-USDT"`).
    #' @return (data.table | promise<data.table>) one row per recent trade, each
    #'   giving the trade sequence number, price, quantity, direction (`"buy"` or
    #'   `"sell"`), and the trade datetime (POSIXct, coerced from the nanosecond
    #'   timestamp):
    #' - sequence (character) the sequence.
    #' - side (character) the order side.
    #' - price (character | NA) the price.
    #' - size (character | NA) the size.
    #' - time (POSIXct) the time (UTC).
    #' - trade_id (character) the trade identifier.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' trades <- market$get_trade_history("BTC-USDT")
    #' # Buy/sell ratio
    #' buys <- trades[side == "buy", sum(as.numeric(size))]
    #' sells <- trades[side == "sell", sum(as.numeric(size))]
    #' print(paste("Buy/Sell ratio:", round(buys / sells, 3)))
    #' }
    get_trade_history = function(symbol) {
      assert_args_KucoinMarketData__get_trade_history(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/market/histories",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::rbindlist(
            lapply(data, as_dt_row),
            fill = TRUE
          )
          if ("time" %in% names(dt)) {
            dt[, time := ns_to_datetime(time)]
          }
          data.table::setcolorder(dt, c("sequence", "side", "price", "size", "time"))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_trade_history,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Partial Orderbook
    #'
    #' Retrieves a partial order book snapshot with either 20 or 100 levels of
    #' depth on each side (bids and asks). Public endpoint, no authentication required.
    #'
    #' ### Workflow
    #' 1. **Validation**: Ensures `size` is 20 or 100.
    #' 2. **Request**: GET with size embedded in endpoint path.
    #' 3. **Parsing**: Calls `parse_orderbook()` to convert nested bid/ask arrays
    #'    into a long-format `data.table` with `side`, `level`, `price`, and `size` columns.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/market/orderbook/level2_{20|100}`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Part Orderbook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-part-orderbook)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Depth Analysis**: Assess liquidity at various price levels for slippage estimation.
    #' - **Support/Resistance**: Identify large resting orders as potential support/resistance.
    #' - **Market Making**: Use top-of-book levels for dynamic spread calculation.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/market/orderbook/level2_20?symbol=BTC-USDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "time": 1729176273859,
    #'     "sequence": "14610502970",
    #'     "bids": [["66976.4", "0.69109872"], ["66976.3", "0.14377"]],
    #'     "asks": [["66976.5", "0.05408199"], ["66976.8", "0.0005"]]
    #'   }
    #' }
    #' ```
    #'
    #' @noassert size
    #' @param symbol (scalar<character>) trading symbol (e.g., `"BTC-USDT"`).
    #' @param size (scalar<count>) depth levels: `20` or `100` (default `20`).
    #' @return (Orderbook | promise<Orderbook>) one row per price level per side,
    #'   best price first.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' ob <- market$get_part_orderbook("BTC-USDT", size = 20)
    #' best_bid <- ob[side == "bid" & level == 1L]
    #' best_ask <- ob[side == "ask" & level == 1L]
    #' print(paste("Best bid:", best_bid$price, "Best ask:", best_ask$price))
    #' }
    get_part_orderbook = function(symbol, size = 20) {
      assert_args_KucoinMarketData__get_part_orderbook(symbol)
      assert::assert_nonempty_strings(symbol)
      if (!size %in% c(20, 100)) {
        rlang::abort("Parameter 'size' must be 20 or 100.")
      }

      res <- private$.request(
        endpoint = paste0("/api/v1/market/orderbook/level2_", size),
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = parse_orderbook
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_part_orderbook,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Full Orderbook
    #'
    #' Retrieves the complete order book for a symbol with all price levels.
    #' **Requires authentication** (API key with Spot trading permissions).
    #'
    #' ### Workflow
    #' 1. **Request**: Authenticated GET with `symbol` query parameter.
    #' 2. **Parsing**: Calls `parse_orderbook()` for long-format conversion.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v3/market/orderbook/level2`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Full Orderbook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-full-orderbook)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Full Depth Analysis**: Build complete order book profiles for advanced strategies.
    #' - **Liquidity Assessment**: Sum volume across all levels for total market depth.
    #' - **VWAP Calculation**: Compute volume-weighted average price for large order execution.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v3/market/orderbook/level2?symbol=BTC-USDT' \
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
    #'     "time": 1729176273859,
    #'     "sequence": "14610502970",
    #'     "bids": [["66976.4", "0.69109872"], ["66976.3", "0.14377"]],
    #'     "asks": [["66976.5", "0.05408199"], ["66976.8", "0.0005"]]
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading symbol (e.g., `"BTC-USDT"`).
    #' @return (Orderbook | promise<Orderbook>) one row per price level per side,
    #'   best price first.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' full_ob <- market$get_full_orderbook("BTC-USDT")
    #' # Total bid depth
    #' total_bid_volume <- full_ob[side == "bid", sum(size)]
    #' print(paste("Total bid depth:", total_bid_volume, "BTC"))
    #' }
    get_full_orderbook = function(symbol) {
      assert_args_KucoinMarketData__get_full_orderbook(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v3/market/orderbook/level2",
        query = list(symbol = symbol),
        auth = TRUE,
        .parser = parse_orderbook
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_full_orderbook,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get 24-Hour Statistics
    #'
    #' Retrieves rolling 24-hour market statistics for a symbol, including
    #' OHLCV data, change rate, average price, and fee rates.
    #'
    #' ### Workflow
    #' 1. **Request**: GET with `symbol` query parameter.
    #' 2. **Parsing**: Single-row `data.table` with all statistics fields.
    #' 3. **Timestamp Conversion**: Coerces `time` (ms) to POSIXct in-place.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/market/stats`
    #'
    #' ### Official Documentation
    #' [KuCoin Get 24hr Stats](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-24hr-stats)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Volatility Assessment**: Use `high - low` range or `change_rate` for volatility signals.
    #' - **Volume Confirmation**: Verify `vol_value` exceeds minimum thresholds for strategy activation.
    #' - **Fee-Adjusted Returns**: Use `taker_fee_rate`/`maker_fee_rate` for precise P&L calculation.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/market/stats?symbol=BTC-USDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "time": 1729175612158,
    #'     "symbol": "BTC-USDT",
    #'     "buy": "66982.4",
    #'     "sell": "66982.5",
    #'     "changeRate": "-0.0114",
    #'     "changePrice": "-778.1",
    #'     "high": "68107.7",
    #'     "low": "66683.3",
    #'     "vol": "1738.02898182",
    #'     "volValue": "117321982.415978333",
    #'     "last": "66981.5",
    #'     "averagePrice": "67281.21437289",
    #'     "takerFeeRate": "0.001",
    #'     "makerFeeRate": "0.001",
    #'     "takerCoefficient": "1",
    #'     "makerCoefficient": "1"
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol (scalar<character>) trading symbol (e.g., `"BTC-USDT"`).
    #' @return (data.table | promise<data.table>) one row giving the rolling
    #'   24-hour statistics: server datetime (POSIXct, coerced from epoch
    #'   milliseconds), the trading pair, the best bid and ask prices, the 24-hour
    #'   change rate and amount, the 24-hour high, low, base-currency volume and
    #'   quote-currency volume, the last trade and average prices, and the taker
    #'   and maker fee rates:
    #' - time (POSIXct) the time (UTC).
    #' - symbol (character) the trading pair symbol.
    #' - buy (character | NA) the best bid price.
    #' - sell (character | NA) the best ask price.
    #' - change_rate (character | NA) the 24h change rate.
    #' - change_price (character | NA) the 24h change in price.
    #' - high (character | NA) the 24h high price.
    #' - low (character | NA) the 24h low price.
    #' - vol (character | NA) the 24h traded volume.
    #' - vol_value (character | NA) the 24h traded turnover.
    #' - last (character | NA) the last traded price.
    #' - average_price (character | NA) the average price.
    #' - taker_fee_rate (character | NA) the taker fee rate.
    #' - maker_fee_rate (character | NA) the maker fee rate.
    #' - taker_coefficient (character | NA) the taker fee coefficient.
    #' - maker_coefficient (character | NA) the maker fee coefficient.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' stats <- market$get_24hr_stats("BTC-USDT")
    #' range <- as.numeric(stats$high) - as.numeric(stats$low)
    #' print(paste("24h range:", range, "USDT"))
    #' }
    get_24hr_stats = function(symbol) {
      assert_args_KucoinMarketData__get_24hr_stats(symbol)
      assert::assert_nonempty_strings(symbol)
      res <- private$.request(
        endpoint = "/api/v1/market/stats",
        query = list(symbol = symbol),
        auth = FALSE,
        .parser = function(data) {
          dt <- as_dt_row(data)
          if (nrow(dt) > 0 && "time" %in% names(dt)) {
            dt[, time := ms_to_datetime(time)]
            data.table::setcolorder(dt, c("time", "symbol"))
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_24hr_stats,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Market List
    #'
    #' Retrieves the list of all available market segments on KuCoin.
    #' Market segments group trading pairs by theme (e.g., DeFi, Meme, Layer 1).
    #'
    #' ### Workflow
    #' 1. **Request**: GET with no parameters.
    #' 2. **Parsing**: Returns character vector of market identifiers.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/markets`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Market List](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-market-list)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Market Discovery**: Enumerate available segments for the `market` filter in `get_all_symbols()`.
    #' - **Sector Rotation**: Monitor segment-level volume for sector rotation strategies.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/markets'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": ["USDS", "TON", "AI", "DePIN", "PoW", "BRC-20", "ETF",
    #'            "KCS", "Meme", "Solana", "FIAT", "DeFi", "Polkadot",
    #'            "BTC", "ALTS", "Layer 1"]
    #' }
    #' ```
    #'
    #' @return (data.table | promise<data.table>) one row per market segment:
    #' - market (character) the segment identifier, e.g. `"USDS"`, `"DeFi"`:
    #' - market (character) the market.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' markets <- market$get_market_list()
    #' print(markets)
    #' # Use to filter symbols by market
    #' defi_symbols <- market$get_all_symbols(market = "DeFi")
    #' }
    get_market_list = function() {
      res <- private$.request(
        endpoint = "/api/v1/markets",
        auth = FALSE,
        .parser = function(data) {
          return(data.table::data.table(market = as.character(unlist(data)))[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_market_list,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Klines (Candlestick Data)
    #'
    #' Retrieves historical OHLCV candlestick data for a symbol. Automatically
    #' segments requests to handle KuCoin's 1500-candle-per-request limit,
    #' fetching and combining as many segments as needed to cover the requested
    #' time range.
    #'
    #' ### Workflow
    #' 1. **Validation**: Validates timeframe string against allowed intervals.
    #' 2. **Segmentation**: Splits the `[from, to]` range into chunks of up to 1500 candles.
    #' 3. **Fetching**: Requests each segment sequentially (sync) or in parallel (async).
    #' 4. **Parsing**: Each segment's array-of-arrays response is converted to a typed `data.table`.
    #' 5. **Deduplication**: Removes duplicate candles at segment boundaries.
    #' 6. **Sorting**: Returns rows ordered by `datetime` ascending.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/market/candles`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### Automated Trading Usage
    #' - **Backtesting**: Fetch large historical ranges for strategy backtesting.
    #' - **Technical Indicators**: Feed OHLCV data into indicator calculations (SMA, RSI, MACD).
    #' - **Real-Time Candles**: Poll with short `[from, to]` windows for live candle updates.
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/market/candles?symbol=BTC-USDT&type=1hour&startAt=1750389927&endAt=1750393527'
    #' ```
    #'
    #' ### JSON Response
    #' Each candle is an array: `[timestamp, open, close, high, low, volume, turnover]`
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": [
    #'     ["1566789720", "10411.5", "10401.9", "10411.5", "10396.3", "29.11357276", "302889.301529914"],
    #'     ["1566789660", "10416", "10411.5", "10422.3", "10411.5", "15.61781842", "162703.708997029"]
    #'   ]
    #' }
    #' ```
    #'
    #' @noassert from, to
    #' @param symbol (scalar<character>) trading pair (e.g., `"BTC-USDT"`).
    #' @param timeframe (scalar<character>) candle interval. One of:
    #'   `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`,
    #'   `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`,
    #'   `"1day"`, `"1week"`, `"1month"`. Default `"15min"`.
    #' @param from (POSIXct | scalar<numeric> | NULL) start time. When both `from`
    #'   and `to` are `NULL`, the API returns up to 1500 most recent candles.
    #' @param to (POSIXct | scalar<numeric> | NULL) end time.
    #' @return (Klines | promise<Klines>) one row per candle ascending by datetime.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #'
    #' # Most recent candles (up to 1500)
    #' klines <- market$get_klines("BTC-USDT")
    #' print(head(klines))
    #'
    #' # 7 days of hourly candles
    #' klines_7d <- market$get_klines(
    #'   symbol = "ETH-USDT",
    #'   timeframe = "1hour",
    #'   from = lubridate::now() - lubridate::days(7),
    #'   to = lubridate::now()
    #' )
    #' print(paste("Fetched", nrow(klines_7d), "candles"))
    #' }
    get_klines = function(
      symbol,
      timeframe = "15min",
      from = NULL,
      to = NULL
    ) {
      assert_args_KucoinMarketData__get_klines(symbol, timeframe)
      assert::assert_nonempty_strings(symbol)
      res <- kucoin_fetch_klines(
        symbol = symbol,
        timeframe = timeframe,
        from = from,
        to = to,
        .req_fn = private$.request,
        is_async = private$.is_async
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_klines,
        is_async = private$.is_async
      ))
    },

    # ---- Server Time & Service Status ----

    #' @description
    #' Get Server Time
    #'
    #' Retrieves the current server timestamp from KuCoin in milliseconds.
    #' Useful for detecting clock drift and ensuring HMAC signatures are valid.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/timestamp`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Server Time](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-server-time)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/timestamp'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": 1729176273859
    #' }
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **Clock Drift Detection**: Compare server time against local clock to detect drift.
    #' - **Auth Debugging**: KuCoin tolerates +/-5s; verify your timestamps are in range.
    #' - **Heartbeat**: Lightweight endpoint suitable for connectivity health checks.
    #'
    #' @return (data.table | promise<data.table>) one row:
    #' - server_time (numeric) the server clock in epoch milliseconds.
    #' - datetime (POSIXct) the same instant as a POSIXct (UTC):
    #' - server_time (numeric) the server time.
    #' - datetime (POSIXct) the datetime (UTC).
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' st <- market$get_server_time()
    #' drift <- as.numeric(lubridate::now()) * 1000 - st$server_time
    #' cat("Clock drift:", round(drift), "ms\n")
    #' }
    get_server_time = function() {
      res <- private$.request(
        endpoint = "/api/v1/timestamp",
        auth = FALSE,
        .parser = function(data) {
          ts <- as.numeric(data)
          return(data.table::data.table(
            server_time = ts,
            datetime = ms_to_datetime(ts)
          )[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_server_time,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Service Status
    #'
    #' Retrieves the current operational status of the KuCoin platform.
    #' Bots should check this before placing orders to avoid silent failures
    #' during maintenance windows.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/status`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Service Status](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-service-status)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET 'https://api.kucoin.com/api/v1/status'
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
    #' ### Automated Trading Usage
    #' - **Pre-Flight Check**: Verify `status == "open"` before placing orders.
    #' - **Maintenance Detection**: Detect `"close"` status to pause bot activity.
    #' - **Cancel-Only Mode**: Detect `"cancelonly"` to only run cancellation logic.
    #'
    #' @return (data.table | promise<data.table>) one row giving the operational
    #'   status (`"open"`, `"close"`, or `"cancelonly"`) and an optional
    #'   remark/message:
    #' - status (character) the status.
    #' - msg (character) the msg.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' status <- market$get_service_status()
    #' if (status$status != "open") {
    #'   cat("Exchange not operational:", status$msg, "\n")
    #' }
    #' }
    get_service_status = function() {
      res <- private$.request(
        endpoint = "/api/v1/status",
        auth = FALSE,
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_service_status,
        is_async = private$.is_async
      ))
    },

    #' @description
    #' Get Fiat Prices
    #'
    #' Retrieves current fiat-equivalent prices for cryptocurrencies.
    #' Useful for portfolio valuation and P&L reporting in fiat terms.
    #'
    #' ### API Endpoint
    #' `GET https://api.kucoin.com/api/v1/prices`
    #'
    #' ### Official Documentation
    #' [KuCoin Get Fiat Price](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-fiat-price)
    #'
    #' Verified: 2026-05-23
    #'
    #' ### curl
    #' ```
    #' curl --location --request GET \
    #'   'https://api.kucoin.com/api/v1/prices?base=USD&currencies=BTC,ETH,USDT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "code": "200000",
    #'   "data": {
    #'     "BTC": "67269.15",
    #'     "ETH": "2485.73",
    #'     "USDT": "1.0002"
    #'   }
    #' }
    #' ```
    #'
    #' ### Automated Trading Usage
    #' - **Portfolio Valuation**: Convert all holdings to USD/EUR for dashboard reporting.
    #' - **Position Sizing**: Size positions in native fiat currency terms.
    #' - **PnL Reporting**: Calculate profit/loss in fiat for accounting.
    #'
    #' @param base (scalar<character> | NULL) fiat currency ticker (e.g.,
    #'   `"USD"`, `"EUR"`). Default `"USD"`.
    #' @param currencies (scalar<character> | NULL) comma-separated crypto tickers
    #'   to convert (e.g., `"BTC,ETH,USDT"`). If NULL, returns all available.
    #' @return (data.table | promise<data.table>) one row per cryptocurrency,
    #'   giving its ticker and fiat price as a string.
    #'
    #' @examples
    #' \dontrun{
    #' market <- KucoinMarketData$new()
    #' prices <- market$get_fiat_prices(base = "USD", currencies = "BTC,ETH,USDT")
    #' print(prices)
    #' }
    get_fiat_prices = function(base = NULL, currencies = NULL) {
      assert_args_KucoinMarketData__get_fiat_prices(base, currencies)
      res <- private$.request(
        endpoint = "/api/v1/prices",
        query = list(base = base, currencies = currencies),
        auth = FALSE,
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::data.table(
            currency = names(data),
            price = as.character(unlist(data))
          )[])
        }
      )
      return(connectcore::then_or_now(
        res,
        assert_return_KucoinMarketData__get_fiat_prices,
        is_async = private$.is_async
      ))
    }
  )
)
