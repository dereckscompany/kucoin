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
    return(c(
      as.character(ts),
      as.character(row$open),
      as.character(row$close),
      as.character(row$high),
      as.character(row$low),
      as.character(row$volume),
      as.character(row$turnover)
    ))
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

# ---------------------------------------------------------------------------
# Margin Trading fixtures
# ---------------------------------------------------------------------------

#' Margin order placement response (open_long, close_long, open_short, close_short)
#' @export
mock_margin_order_response <- function() {
  return(list(
    orderId = "6789abcd1234ef0007ab1234",
    clientOid = "margin-order-001",
    borrowSize = "0.001",
    loanApplyId = "loan-apply-001"
  ))
}

#' Margin borrow response
#' @export
mock_margin_borrow_response <- function() {
  return(list(
    orderNo = "borrow-order-001",
    actualSize = "1000"
  ))
}

#' Margin repay response
#' @export
mock_margin_repay_response <- function() {
  return(list(
    orderNo = "repay-order-001",
    actualSize = "1000",
    timestamp = 1729655606816
  ))
}

#' Borrow history — 2 records
#' @export
mock_borrow_history_data <- function() {
  return(list(
    items = list(
      list(
        orderNo = "borrow-order-001",
        currency = "USDT",
        principal = "1000",
        interest = "0.5",
        createdTime = 1729655606816
      ),
      list(
        orderNo = "borrow-order-002",
        currency = "USDT",
        principal = "500",
        interest = "0.2",
        createdTime = 1729655706816
      )
    )
  ))
}

#' Repay history — 1 record
#' @export
mock_repay_history_data <- function() {
  return(list(
    items = list(
      list(
        orderNo = "repay-order-001",
        currency = "USDT",
        principal = "1000",
        interest = "0.5",
        createdTime = 1729655606816
      )
    )
  ))
}

#' Interest history — 1 record
#' @export
mock_interest_history_data <- function() {
  return(list(
    items = list(
      list(
        currency = "USDT",
        interestPaymentAmount = "0.5",
        createdTime = 1729655606816
      )
    )
  ))
}

#' Borrow rates — BTC, USDT, ETH
#' @export
mock_borrow_rate_data <- function() {
  return(list(
    items = list(
      list(currency = "BTC", hourlyBorrowRate = "0.000021", annualizedBorrowRate = "0.1839"),
      list(currency = "USDT", hourlyBorrowRate = "0.000015", annualizedBorrowRate = "0.1314"),
      list(currency = "ETH", hourlyBorrowRate = "0.000018", annualizedBorrowRate = "0.1577")
    )
  ))
}

#' Empty response for endpoints that return invisible(NULL)
#' @export
mock_empty_response <- function() {
  return(list())
}

# ---------------------------------------------------------------------------
# Margin Data fixtures
# ---------------------------------------------------------------------------

#' Cross margin symbols — BTC-USDT + ETH-USDT
#' @export
mock_cross_margin_symbols_data <- function() {
  return(list(
    timestamp = 1772993986642,
    items = list(
      list(
        symbol = "BTC-USDT",
        name = "BTC-USDT",
        baseCurrency = "BTC",
        quoteCurrency = "USDT",
        baseIncrement = "0.00000001",
        baseMinSize = "0.00001",
        baseMaxSize = "10000000000",
        quoteIncrement = "0.000001",
        quoteMinSize = "0.1",
        quoteMaxSize = "99999999",
        priceIncrement = "0.1",
        feeCurrency = "USDT",
        priceLimitRate = "0.01",
        minFunds = "0.1",
        enableTrading = TRUE,
        market = "USDS"
      ),
      list(
        symbol = "ETH-USDT",
        name = "ETH-USDT",
        baseCurrency = "ETH",
        quoteCurrency = "USDT",
        baseIncrement = "0.0000001",
        baseMinSize = "0.0001",
        baseMaxSize = "10000000000",
        quoteIncrement = "0.000001",
        quoteMinSize = "0.1",
        quoteMaxSize = "99999999",
        priceIncrement = "0.01",
        feeCurrency = "USDT",
        priceLimitRate = "0.01",
        minFunds = "0.1",
        enableTrading = TRUE,
        market = "USDS"
      )
    )
  ))
}

#' Isolated margin symbols — BTC-USDT + ETH-USDT
#' @export
mock_isolated_margin_symbols_data <- function() {
  return(list(
    list(
      symbol = "BTC-USDT",
      symbolName = "BTC-USDT",
      baseCurrency = "BTC",
      quoteCurrency = "USDT",
      maxLeverage = 10L,
      flDebtRatio = "0.97",
      tradeEnable = TRUE,
      baseBorrowEnable = TRUE,
      quoteBorrowEnable = TRUE,
      baseTransferInEnable = TRUE,
      quoteTransferInEnable = TRUE
    ),
    list(
      symbol = "ETH-USDT",
      symbolName = "ETH-USDT",
      baseCurrency = "ETH",
      quoteCurrency = "USDT",
      maxLeverage = 5L,
      flDebtRatio = "0.97",
      tradeEnable = TRUE,
      baseBorrowEnable = TRUE,
      quoteBorrowEnable = TRUE,
      baseTransferInEnable = TRUE,
      quoteTransferInEnable = TRUE
    )
  ))
}

#' Margin config — global settings
#' @export
mock_margin_config_data <- function() {
  return(list(
    maxLeverage = 10L,
    warningDebtRatio = "0.95",
    liqDebtRatio = "0.97",
    currencyList = list("BTC", "ETH", "USDT", "KCS")
  ))
}

#' Collateral ratios — BTC + ETH
#' @export
mock_collateral_ratio_data <- function() {
  return(list(
    list(
      currencyList = list("BTC"),
      items = list(
        list(lowerLimit = "0", upperLimit = "10", collateralRatio = "1.0"),
        list(lowerLimit = "10", upperLimit = "100", collateralRatio = "0.9")
      )
    ),
    list(
      currencyList = list("ETH"),
      items = list(
        list(lowerLimit = "0", upperLimit = "50", collateralRatio = "0.95"),
        list(lowerLimit = "50", upperLimit = "500", collateralRatio = "0.85")
      )
    )
  ))
}

#' Risk limits — BTC + USDT
#' @export
mock_risk_limit_data <- function() {
  return(list(
    list(
      currency = "BTC",
      borrowMaxAmount = "100",
      buyMaxAmount = "100",
      holdMaxAmount = "100",
      borrowCoefficient = "1",
      marginCoefficient = "1",
      precision = 8L,
      borrowMinAmount = "0.001",
      borrowMinUnit = "0.001",
      borrowEnabled = TRUE
    ),
    list(
      currency = "USDT",
      borrowMaxAmount = "1000000",
      buyMaxAmount = "1000000",
      holdMaxAmount = "1000000",
      borrowCoefficient = "1",
      marginCoefficient = "1",
      precision = 2L,
      borrowMinAmount = "10",
      borrowMinUnit = "0.01",
      borrowEnabled = TRUE
    )
  ))
}

# ---------------------------------------------------------------------------
# Lending fixtures
# ---------------------------------------------------------------------------

#' Loan market — USDT + BTC
#' @export
mock_loan_market_data <- function() {
  return(list(
    list(
      currency = "USDT",
      purchaseEnable = TRUE,
      redeemEnable = TRUE,
      increment = "0.01",
      minPurchaseSize = "10",
      maxPurchaseSize = "1000000",
      interestIncrement = "0.0001",
      minInterestRate = "0.004",
      marketInterestRate = "0.05",
      maxInterestRate = "0.1",
      autoPurchaseEnable = TRUE
    ),
    list(
      currency = "BTC",
      purchaseEnable = TRUE,
      redeemEnable = TRUE,
      increment = "0.00001",
      minPurchaseSize = "0.001",
      maxPurchaseSize = "100",
      interestIncrement = "0.0001",
      minInterestRate = "0.003",
      marketInterestRate = "0.04",
      maxInterestRate = "0.08",
      autoPurchaseEnable = TRUE
    )
  ))
}

#' Loan market rates — 3 days
#' @export
mock_loan_market_rate_data <- function() {
  return(list(
    list(time = "202603070000", marketInterestRate = "0.05"),
    list(time = "202603060000", marketInterestRate = "0.048"),
    list(time = "202603050000", marketInterestRate = "0.052")
  ))
}

#' Purchase (lend) response
#' @export
mock_purchase_response <- function() {
  return(list(orderNo = "lending-purchase-001"))
}

#' Purchase orders — 1 record
#' @export
mock_purchase_orders_data <- function() {
  return(list(
    currentPage = 1L,
    pageSize = 50L,
    totalNum = 1L,
    totalPage = 1L,
    items = list(
      list(
        currency = "USDT",
        purchaseOrderNo = "lending-purchase-001",
        purchaseSize = "1000",
        matchSize = "800",
        interestRate = "0.05",
        incomeSize = "3.42",
        applyTime = 1729655606816,
        status = "DONE"
      )
    )
  ))
}

#' Redeem response
#' @export
mock_redeem_response <- function() {
  return(list(orderNo = "lending-redeem-001"))
}

#' Redeem orders — 1 record
#' @export
mock_redeem_orders_data <- function() {
  return(list(
    currentPage = 1L,
    pageSize = 50L,
    totalNum = 1L,
    totalPage = 1L,
    items = list(
      list(
        currency = "USDT",
        purchaseOrderNo = "lending-purchase-001",
        redeemOrderNo = "lending-redeem-001",
        redeemSize = "500",
        receiptSize = "500",
        applyTime = 1729655606816,
        status = "DONE"
      )
    )
  ))
}

# ---------------------------------------------------------------------------
# Futures Market Data fixtures
# ---------------------------------------------------------------------------

#' Futures contract details — XBTUSDTM
#' @export
mock_futures_contract_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    rootSymbol = "USDT",
    type = "FFWCSX",
    firstOpenDate = 1585555200000,
    baseCurrency = "XBT",
    quoteCurrency = "USDT",
    settleCurrency = "USDT",
    maxOrderQty = 1000000,
    maxPrice = 1000000,
    lotSize = 1,
    tickSize = 0.1,
    indexPriceTickSize = 0.01,
    multiplier = 0.001,
    initialMargin = 0.008,
    maintainMargin = 0.004,
    maxRiskLimit = 100000,
    minRiskLimit = 100000,
    riskStep = 50000,
    makerFeeRate = 0.0002,
    takerFeeRate = 0.0006,
    makerFixFee = 0,
    takerFixFee = 0,
    isDeleverage = TRUE,
    isQuanto = FALSE,
    isInverse = FALSE,
    markMethod = "FairPrice",
    fairMethod = "FundingRate",
    status = "Open",
    fundingFeeRate = 0.0001,
    predictedFundingFeeRate = 0.0001,
    openInterest = "27228",
    turnoverOf24h = 23472917.51,
    volumeOf24h = 239,
    markPrice = 98252.1,
    indexPrice = 98232.45,
    lastTradePrice = 98260.0,
    nextFundingRateTime = 21467281,
    maxLeverage = 125,
    fundingRateSymbol = ".XBTUSDTMFPI8H",
    lowPrice = 96891.0,
    highPrice = 99133.0
  ))
}

#' All active futures contracts (2 items)
#' @export
mock_futures_all_contracts_data <- function() {
  return(list(
    mock_futures_contract_data(),
    list(
      symbol = "ETHUSDTM",
      rootSymbol = "USDT",
      type = "FFWCSX",
      baseCurrency = "ETH",
      quoteCurrency = "USDT",
      settleCurrency = "USDT",
      maxOrderQty = 10000000,
      lotSize = 1,
      tickSize = 0.01,
      multiplier = 0.01,
      initialMargin = 0.02,
      maintainMargin = 0.01,
      makerFeeRate = 0.0002,
      takerFeeRate = 0.0006,
      status = "Open",
      maxLeverage = 100,
      markPrice = 3456.78,
      lastTradePrice = 3455.50,
      lowPrice = 3400.00,
      highPrice = 3500.00
    )
  ))
}

#' Futures ticker — XBTUSDTM
#' @export
mock_futures_ticker_data <- function() {
  return(list(
    sequence = 1729159460,
    symbol = "XBTUSDTM",
    side = "sell",
    size = 1,
    price = "98250.0",
    bestBidSize = 50,
    bestBidPrice = "98249.9",
    bestAskPrice = "98250.1",
    bestAskSize = 30,
    tradeId = "67fd1234abcd5678",
    ts = 1729159459033000000
  ))
}

#' All futures tickers (2 items)
#' @export
mock_futures_all_tickers_data <- function() {
  return(list(
    mock_futures_ticker_data(),
    list(
      sequence = 1729159461,
      symbol = "ETHUSDTM",
      side = "buy",
      size = 5,
      price = "3456.78",
      bestBidSize = 100,
      bestBidPrice = "3456.50",
      bestAskPrice = "3457.00",
      bestAskSize = 80,
      tradeId = "67fd5678efgh9012",
      ts = 1729159459034000000
    )
  ))
}

#' Futures partial orderbook — XBTUSDTM
#' @export
mock_futures_orderbook_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    sequence = 100,
    ts = 1729159459033000000,
    bids = list(
      list(98249.9, 50),
      list(98249.0, 100)
    ),
    asks = list(
      list(98250.1, 30),
      list(98251.0, 75)
    )
  ))
}

#' Futures trade history — XBTUSDTM
#' @export
mock_futures_trade_history_data <- function() {
  return(list(
    list(
      sequence = 100,
      tradeId = "trade-001",
      takerOrderId = "order-001",
      makerOrderId = "order-002",
      price = "98250.0",
      size = 1,
      side = "buy",
      ts = 1729159459033000000
    ),
    list(
      sequence = 101,
      tradeId = "trade-002",
      takerOrderId = "order-003",
      makerOrderId = "order-004",
      price = "98251.0",
      size = 2,
      side = "sell",
      ts = 1729159459034000000
    )
  ))
}

#' Futures klines — XBTUSDTM
#' @export
mock_futures_klines_data <- function() {
  return(list(
    list(1729155600000, 98100.0, 98300.0, 98000.0, 98250.0, 150, 14737500),
    list(1729159200000, 98250.0, 98400.0, 98200.0, 98350.0, 120, 11802000),
    list(1729162800000, 98350.0, 98500.0, 98300.0, 98450.0, 100, 9845000)
  ))
}

#' Futures mark price — XBTUSDTM
#' @export
mock_futures_mark_price_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    granularity = 1000,
    timePoint = 1729159459000,
    value = 98252.1,
    indexPrice = 98232.45
  ))
}

#' Futures funding rate — XBTUSDTM
#' @export
mock_futures_funding_rate_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    granularity = 28800000,
    timePoint = 1729152000000,
    value = 0.0001,
    predictedValue = 0.0001,
    fundingTime = 1729180800000
  ))
}

#' Futures funding rate history — XBTUSDTM
#' @export
mock_futures_funding_history_data <- function() {
  return(list(
    list(
      symbol = "XBTUSDTM",
      fundingRate = 0.0001,
      timepoint = 1729152000000
    ),
    list(
      symbol = "XBTUSDTM",
      fundingRate = 0.00012,
      timepoint = 1729123200000
    )
  ))
}

#' Futures server time
#' @export
mock_futures_server_time_data <- function() {
  return(1729159459033)
}

#' Futures service status
#' @export
mock_futures_service_status_data <- function() {
  return(list(
    status = "open",
    msg = ""
  ))
}

# ---------------------------------------------------------------------------
# Futures Trading fixtures
# ---------------------------------------------------------------------------

#' Futures order response
#' @export
mock_futures_order_response <- function() {
  return(list(
    orderId = "futures-order-001",
    clientOid = "futures-client-001"
  ))
}

#' Futures cancel order response
#' @export
mock_futures_cancel_order_data <- function() {
  return(list(
    cancelledOrderIds = list("futures-order-001")
  ))
}

#' Futures order detail
#' @export
mock_futures_order_detail_data <- function() {
  return(list(
    id = "futures-order-001",
    symbol = "XBTUSDTM",
    type = "limit",
    side = "buy",
    price = "98000",
    size = 1,
    value = "98",
    dealValue = "0",
    dealSize = 0,
    leverage = 5,
    marginMode = "ISOLATED",
    positionSide = "BOTH",
    status = "open",
    createdAt = 1729159459033,
    updatedAt = 1729159459033,
    clientOid = "futures-client-001"
  ))
}

#' Futures order list (paginated)
#' @export
mock_futures_order_list_data <- function() {
  return(list(
    currentPage = 1L,
    pageSize = 50L,
    totalNum = 1L,
    totalPage = 1L,
    items = list(
      mock_futures_order_detail_data()
    )
  ))
}

#' Futures recent fills
#' @export
mock_futures_fills_data <- function() {
  return(list(
    list(
      symbol = "XBTUSDTM",
      tradeId = "fill-001",
      orderId = "futures-order-001",
      side = "buy",
      liquidity = "taker",
      forceTaker = TRUE,
      price = "98250.0",
      size = 1,
      value = "98.25",
      feeRate = "0.0006",
      fixFee = "0",
      feeCurrency = "USDT",
      fee = "0.05895",
      orderType = "limit",
      tradeType = "trade",
      tradeTime = 1729159459033000000,
      createdAt = 1729159459033
    )
  ))
}

#' Futures open order value
#' @export
mock_futures_open_order_value_data <- function() {
  return(list(
    openOrderBuyQty = 1,
    openOrderSellQty = 0,
    openOrderBuyCost = "0.0196",
    openOrderSellCost = "0",
    settleCurrency = "USDT"
  ))
}

#' Futures DCP settings
#' @export
mock_futures_dcp_data <- function() {
  return(list(
    timeout = 5,
    symbols = "",
    currentTime = 1729159459033
  ))
}

# ---------------------------------------------------------------------------
# Futures Account fixtures
# ---------------------------------------------------------------------------

#' Futures account overview
#' @export
mock_futures_account_overview_data <- function() {
  return(list(
    accountEquity = 100000.5,
    unrealisedPNL = 50.25,
    marginBalance = 100050.75,
    positionMargin = 1000.0,
    orderMargin = 500.0,
    frozenFunds = 0,
    availableBalance = 98550.75,
    currency = "USDT"
  ))
}

#' Futures position detail
#' @export
mock_futures_position_data <- function() {
  return(list(
    list(
      id = "pos-001",
      symbol = "XBTUSDTM",
      autoDeposit = FALSE,
      realLeverage = 5.0,
      crossMode = FALSE,
      delevPercentage = 0.5,
      openingTimestamp = 1729159459033,
      currentTimestamp = 1729162000000,
      currentQty = 1,
      currentCost = "98.25",
      currentComm = "0.05895",
      unrealisedCost = "98.25",
      realisedGrossCost = "0",
      realisedCost = "0.05895",
      isOpen = TRUE,
      markPrice = 98350.0,
      markValue = "98.35",
      posCost = "98.25",
      posCross = "0",
      posInit = "19.65",
      posComm = "0.07861",
      posLoss = "0",
      posMargin = "19.72861",
      posMaint = "0.4423",
      maintMargin = "19.82861",
      realisedGrossPnl = "0",
      realisedPnl = "-0.05895",
      unrealisedPnl = "0.1",
      unrealisedPnlPcnt = 0.001,
      avgEntryPrice = "98250.0",
      liquidationPrice = "79000.0",
      bankruptPrice = "78500.0",
      settleCurrency = "USDT",
      marginMode = "ISOLATED",
      positionSide = "BOTH"
    )
  ))
}

#' Futures positions history
#' @export
mock_futures_positions_history_data <- function() {
  return(list(
    items = list(
      list(
        symbol = "XBTUSDTM",
        settleCurrency = "USDT",
        realisedGrossPnl = "10.50",
        realisedPnl = "10.25",
        openTime = 1729100000000,
        closeTime = 1729159459033,
        leverage = 5,
        type = "Close"
      )
    )
  ))
}

#' Futures margin mode
#' @export
mock_futures_margin_mode_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    marginMode = "ISOLATED"
  ))
}

#' Futures cross margin leverage
#' @export
mock_futures_cross_leverage_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    leverage = "5"
  ))
}

#' Futures max open size
#' @export
mock_futures_max_open_size_data <- function() {
  return(list(
    symbol = "XBTUSDTM",
    maxBuyOpenSize = 500,
    maxSellOpenSize = 500
  ))
}

#' Futures max withdraw margin
#' @export
mock_futures_max_withdraw_margin_data <- function() {
  return("15.00")
}

#' Futures add/remove margin response
#' @export
mock_futures_margin_response <- function() {
  return(list(
    id = "margin-001",
    symbol = "XBTUSDTM",
    margin = "10.00",
    marginType = "ADD"
  ))
}

#' Futures risk limit tiers
#' @export
mock_futures_risk_limit_data <- function() {
  return(list(
    list(
      symbol = "XBTUSDTM",
      level = 1,
      maxRiskLimit = 100000,
      minRiskLimit = 0,
      maxLeverage = 125,
      initialMargin = 0.008,
      maintainMargin = 0.004
    ),
    list(
      symbol = "XBTUSDTM",
      level = 2,
      maxRiskLimit = 200000,
      minRiskLimit = 100000,
      maxLeverage = 100,
      initialMargin = 0.01,
      maintainMargin = 0.005
    )
  ))
}

#' Futures private funding history
#' @export
mock_futures_private_funding_data <- function() {
  return(list(
    dataList = list(
      list(
        id = 1,
        symbol = "XBTUSDTM",
        timePoint = 1729152000000,
        fundingRate = 0.0001,
        markPrice = 98250.0,
        positionQty = 1,
        positionCost = "98.25",
        funding = "-0.009825",
        settleCurrency = "USDT"
      )
    ),
    hasMore = FALSE
  ))
}
