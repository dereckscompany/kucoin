# Shared mock response builders and data fixtures for KuCoin API.
#
# Provides realistic mock data matching KuCoin API response shapes.
# Used by tests, README, and vignettes via box::use() relative imports.

# This file is used in two ways:
# 1. As a box module via box::use() from README.Rmd and vignettes
# 2. Via source() from helper-mock.R (testthat context)
# We use :: notation so it works in both contexts.

# ---------------------------------------------------------------------------
# Response builder
# ---------------------------------------------------------------------------

#' Build a fake httr2 response with KuCoin JSON envelope
#' @export
mock_response <- function(data, code = "200000", status_code = 200L) {
  body <- jsonlite::toJSON(
    list(code = code, data = data),
    auto_unbox = TRUE,
    null = "null"
  )
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

# ---------------------------------------------------------------------------
# Market Data fixtures
# ---------------------------------------------------------------------------

#' Ticker (Level 1) — BTC-USDT
#' @export
mock_ticker_data <- function() {
  return(list(
    sequence = "1550467636704",
    price = "67232.9",
    size = "0.00007682",
    bestBid = "67232.8",
    bestBidSize = "0.41861839",
    bestAsk = "67232.9",
    bestAskSize = "1.24808993",
    time = 1729159459033
  ))
}

#' 24hr Statistics — BTC-USDT
#' @export
mock_24hr_stats_data <- function() {
  return(list(
    time = 1729159459033,
    symbol = "BTC-USDT",
    buy = "67232.8",
    sell = "67232.9",
    changeRate = "-0.0114",
    changePrice = "-772.1",
    high = "68100.0",
    low = "66800.0",
    vol = "3456.78901234",
    volValue = "232456789.12",
    last = "67232.9",
    averagePrice = "67450.5",
    takerFeeRate = "0.001",
    makerFeeRate = "0.001",
    takerCoefficient = "1",
    makerCoefficient = "1"
  ))
}

#' All Tickers — BTC-USDT + ETH-USDT
#' @export
mock_all_tickers_data <- function() {
  return(list(
    time = 1729159459033,
    ticker = list(
      list(
        symbol = "BTC-USDT",
        symbolName = "BTC-USDT",
        buy = "67232.8",
        sell = "67232.9",
        changeRate = "-0.0114",
        changePrice = "-772.1",
        high = "68100.0",
        low = "66800.0",
        vol = "3456.78901234",
        volValue = "232456789.12",
        last = "67232.9",
        averagePrice = "67450.5",
        takerFeeRate = "0.001",
        makerFeeRate = "0.001"
      ),
      list(
        symbol = "ETH-USDT",
        symbolName = "ETH-USDT",
        buy = "2530.5",
        sell = "2530.8",
        changeRate = "0.0235",
        changePrice = "58.2",
        high = "2560.0",
        low = "2470.0",
        vol = "45678.123",
        volValue = "115432000.00",
        last = "2530.6",
        averagePrice = "2515.3",
        takerFeeRate = "0.001",
        makerFeeRate = "0.001"
      )
    )
  ))
}

#' Trade History — 3 recent trades
#' @export
mock_trade_history_data <- function() {
  return(list(
    list(
      sequence = "1550467636704",
      price = "67232.9",
      size = "0.00007682",
      side = "buy",
      time = 1729159459033000000 # nanoseconds
    ),
    list(
      sequence = "1550467636705",
      price = "67231.5",
      size = "0.01234",
      side = "sell",
      time = 1729159460150000000
    ),
    list(
      sequence = "1550467636706",
      price = "67233.0",
      size = "0.005",
      side = "buy",
      time = 1729159461200000000
    )
  ))
}

#' Partial Orderbook — 3 levels each side
#' @export
mock_orderbook_data <- function() {
  return(list(
    time = 1729159459033,
    sequence = "1550467636704",
    bids = list(
      list("67232.8", "0.41861839"),
      list("67232.5", "1.5"),
      list("67230.0", "0.8")
    ),
    asks = list(
      list("67232.9", "1.24808993"),
      list("67233.5", "0.5"),
      list("67235.0", "2.1")
    )
  ))
}

#' Klines (candles) — uses real BTC-USDT 4h data from kucoin_data
#' KuCoin format: [timestamp_seconds, open, close, high, low, volume, turnover]
#' @param n Number of candles to return.
#' @param start_ts Optional start timestamp (seconds). When provided, candles
#'   are generated starting from this timestamp using 4h intervals with prices
#'   sampled from the real dataset. This preserves backward compatibility with
#'   tests that rely on specific timestamps.
#' @param offset Row offset into kucoin_data (1-indexed). Default 17000
#'   gives candles from late 2024. Ignored when start_ts is provided.
#' @export
mock_klines_data <- function(n = 5, start_ts = NULL, offset = 17000) {
  dt <- kucoin::kucoin_btc_usdt_4h_ohlcv[seq(offset, offset + n - 1)]
  return(lapply(seq_len(nrow(dt)), function(i) {
    row <- dt[i]
    ts <- start_ts
    if (is.null(ts)) {
      ts <- as.integer(row$datetime)
    } else {
      ts <- as.integer(start_ts + (i - 1) * 14400) # 4h intervals
    }
    c(
      as.character(ts),
      as.character(row$open),
      as.character(row$close),
      as.character(row$high),
      as.character(row$low),
      as.character(row$volume),
      as.character(row$turnover)
    )
  }))
}

#' Currency Detail — BTC with 2 chains
#' @export
mock_currency_data <- function() {
  return(list(
    currency = "BTC",
    name = "BTC",
    fullName = "Bitcoin",
    precision = 8L,
    confirms = NULL,
    contractAddress = NULL,
    isMarginEnabled = TRUE,
    isDebitEnabled = TRUE,
    chains = list(
      list(
        chainName = "BTC",
        withdrawalMinSize = "0.001",
        depositMinSize = "0.0002",
        withdrawFeeRate = "0",
        withdrawalMinFee = "0.0005",
        isWithdrawEnabled = TRUE,
        isDepositEnabled = TRUE,
        confirms = 3L,
        preConfirms = 1L,
        contractAddress = "",
        withdrawPrecision = 8L,
        maxWithdraw = NULL,
        maxDeposit = NULL,
        needTag = FALSE,
        chainId = "btc"
      ),
      list(
        chainName = "KCC",
        withdrawalMinSize = "0.0008",
        depositMinSize = "0.00002",
        withdrawFeeRate = "0",
        withdrawalMinFee = "0.00002",
        isWithdrawEnabled = TRUE,
        isDepositEnabled = TRUE,
        confirms = 20L,
        preConfirms = 20L,
        contractAddress = "0xfa93c12cd345c658",
        withdrawPrecision = 8L,
        maxWithdraw = NULL,
        maxDeposit = NULL,
        needTag = FALSE,
        chainId = "kcc"
      )
    )
  ))
}

#' Symbol Detail — BTC-USDT
#' @export
mock_symbol_data <- function() {
  return(list(
    symbol = "BTC-USDT",
    name = "BTC-USDT",
    baseCurrency = "BTC",
    quoteCurrency = "USDT",
    feeCurrency = "USDT",
    market = "USDS",
    baseMinSize = "0.00001",
    quoteMinSize = "0.1",
    baseMaxSize = "10000000000",
    quoteMaxSize = "99999999",
    baseIncrement = "0.00000001",
    quoteIncrement = "0.000001",
    priceIncrement = "0.1",
    priceLimitRate = "0.1",
    minFunds = "0.1",
    isMarginEnabled = TRUE,
    enableTrading = TRUE,
    feeCategory = 1L,
    makerFeeCoefficient = "1.00",
    takerFeeCoefficient = "1.00",
    st = FALSE
  ))
}

#' Market List
#' @export
mock_market_list_data <- function() {
  return(c("USDS", "BTC", "KCS", "DeFi", "NFT", "Metaverse", "Meme"))
}

#' Announcements (paginated)
#' @export
mock_announcements_page_data <- function() {
  return(list(
    totalNum = 2L,
    totalPage = 1L,
    currentPage = 1L,
    pageSize = 50L,
    items = list(
      list(
        annId = 129045L,
        annTitle = "KuCoin Will List Token XYZ (XYZ)",
        annType = list("latest-announcements", "new-listings"),
        annDesc = "KuCoin is pleased to announce the listing of XYZ.",
        cTime = 1729594043000,
        language = "en_US",
        annUrl = "https://www.kucoin.com/announcement/listing-xyz"
      ),
      list(
        annId = 129044L,
        annTitle = "Scheduled System Maintenance Notice",
        annType = list("latest-announcements"),
        annDesc = "KuCoin will undergo scheduled maintenance.",
        cTime = 1729507643000,
        language = "en_US",
        annUrl = "https://www.kucoin.com/announcement/maintenance-2024"
      )
    )
  ))
}

# ---------------------------------------------------------------------------
# Trading fixtures
# ---------------------------------------------------------------------------

#' Order placement response
#' @export
mock_order_response <- function() {
  return(list(
    orderId = "670fd33bf9406e0007ab3945",
    clientOid = "5c52e11203aa677f33e493fb"
  ))
}

#' Open orders list — 2 orders
#' @export
mock_open_orders_data <- function() {
  return(list(
    list(
      id = "670fd33bf9406e0007ab3945",
      symbol = "BTC-USDT",
      opType = "DEAL",
      type = "limit",
      side = "buy",
      price = "50000",
      size = "0.0001",
      funds = "0",
      dealSize = "0",
      dealFunds = "0",
      fee = "0",
      feeCurrency = "USDT",
      stp = "",
      timeInForce = "GTC",
      cancelAfter = -1L,
      postOnly = FALSE,
      hidden = FALSE,
      iceberg = FALSE,
      visibleSize = "0",
      cancelledSize = "0",
      cancelledFunds = "0",
      remainSize = "0.0001",
      remainFunds = "0",
      active = TRUE,
      inOrderBook = TRUE,
      clientOid = "5c52e11203aa677f33e493fb",
      tags = "",
      createdAt = 1729577515473,
      lastUpdatedAt = 1729577515500
    )
  ))
}

#' Cancel order response
#' @export
mock_cancel_order_data <- function() {
  return(list(orderId = "670fd33bf9406e0007ab3945"))
}

# ---------------------------------------------------------------------------
# Account fixtures
# ---------------------------------------------------------------------------

#' Account summary
#' @export
mock_account_summary_data <- function() {
  return(list(
    level = 1L,
    subQuantity = 3L,
    maxDefaultSubQuantity = 5L,
    maxSubQuantity = 5L,
    spotSubQuantity = 2L,
    marginSubQuantity = 1L,
    futuresSubQuantity = 0L,
    optionSubQuantity = 0L,
    maxSpotSubQuantity = 5L,
    maxMarginSubQuantity = 5L,
    maxFuturesSubQuantity = 5L,
    maxOptionSubQuantity = 5L
  ))
}

#' Spot account balances — USDT + BTC
#' @export
mock_spot_accounts_data <- function() {
  return(list(
    list(
      id = "6717422bd51c29000775ea01",
      currency = "USDT",
      type = "trade",
      balance = "10000.50",
      available = "9500.25",
      holds = "500.25"
    ),
    list(
      id = "6717422bd51c29000775ea02",
      currency = "BTC",
      type = "trade",
      balance = "1.23456789",
      available = "1.0",
      holds = "0.23456789"
    )
  ))
}

# ---------------------------------------------------------------------------
# Stop Order fixtures
# ---------------------------------------------------------------------------

#' Stop order placement response
#' @export
mock_stop_order_response <- function() {
  return(list(
    orderId = "vs8hoo8q2ceshiue003b67c0",
    clientOid = "stop-limit-001"
  ))
}

# ---------------------------------------------------------------------------
# OCO Order fixtures
# ---------------------------------------------------------------------------

#' OCO order placement response
#' @export
mock_oco_order_response <- function() {
  return(list(
    orderId = "674c40d38b4b2f00073deef3"
  ))
}

# ---------------------------------------------------------------------------
# Deposit fixtures
# ---------------------------------------------------------------------------

#' Deposit addresses — USDT on ERC20 + TRC20
#' @export
mock_deposit_addresses_data <- function() {
  return(list(
    list(
      address = "0x1a2b3c4d5e6f7890abcdef1234567890abcdef12",
      memo = "",
      chain = "ERC20",
      chainId = "eth",
      to = "main",
      currency = "USDT",
      contractAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7",
      chainName = "ERC20",
      expirationDate = 0L
    ),
    list(
      address = "TXyz123abcDEF456ghiJKL789mnoPQR012stuVW",
      memo = "",
      chain = "TRC20",
      chainId = "trx",
      to = "main",
      currency = "USDT",
      contractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
      chainName = "TRC20",
      expirationDate = 0L
    )
  ))
}

# ---------------------------------------------------------------------------
# Sub-Account fixtures
# ---------------------------------------------------------------------------

#' Sub-accounts paginated list — 2 sub-accounts
#' @export
mock_sub_accounts_page_data <- function() {
  return(list(
    currentPage = 1L,
    pageSize = 100L,
    totalNum = 2L,
    totalPage = 1L,
    items = list(
      list(
        userId = "641e7f09df0db80001f1e5ac",
        uid = 169630809L,
        subName = "bot-alpha",
        status = 2L,
        type = 0L,
        access = "Spot",
        remarks = "Trading bot",
        createdAt = 1729159459033
      ),
      list(
        userId = "641e8027df0db80001f1e6bb",
        uid = 169630810L,
        subName = "bot-beta",
        status = 2L,
        type = 0L,
        access = "Futures",
        remarks = "Futures bot",
        createdAt = 1729159559033
      )
    )
  ))
}

#' Empty sub-accounts page (for paginated stop)
#' @export
mock_sub_accounts_empty_page <- function() {
  return(list(
    currentPage = 1L,
    pageSize = 100L,
    totalNum = 2L,
    totalPage = 1L,
    items = list()
  ))
}

#' ETH Ticker (Level 1) — variant of BTC fixture for multi-symbol examples
#' @export
mock_eth_ticker_data <- function() {
  return(list(
    sequence = "200001",
    price = "2530.6",
    size = "0.5",
    bestBid = "2530.5",
    bestBidSize = "12.0",
    bestAsk = "2530.8",
    bestAskSize = "8.5",
    time = 1729159459033
  ))
}
