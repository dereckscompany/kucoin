# kucoin — Roadmap

> Version 4.0.0 · Last updated 2026-03-11

**98 endpoints implemented** across 12 R6 classes. MarketData (16),
Trading (21), StopOrders (7), OcoOrders (8), Account (11), Deposit (3),
Withdrawal (5), Transfer (2), SubAccount (4), MarginTrading (9),
MarginData (5), Lending (7) — all complete for spot + margin trading
scope.

## Naming convention

| Verb       | Meaning         | Suffixes                            |
|------------|-----------------|-------------------------------------|
| `get_*`    | Query           | `_by_id`, `_by_client_oid`          |
| `add_*`    | Create (POST)   | `_sync`, `_batch`                   |
| `cancel_*` | Cancel (DELETE) | `_sync`, `_by_id`, `_by_client_oid` |
| `modify_*` | Amend in place  |                                     |
| `set_*`    | Configure       |                                     |

snake_case throughout. No API version numbers in method names.

------------------------------------------------------------------------

## Done

### ~~1. Withdrawals — `KucoinWithdrawal` class~~ ✓

Implemented: `add_withdrawal`, `cancel_withdrawal`,
`get_withdrawal_quotas`, `get_withdrawal_history`,
`get_withdrawal_by_id` (5 endpoints).

### ~~2. Transfers — `KucoinTransfer` class~~ ✓

Implemented: `add_transfer`, `get_transferable` (2 endpoints).

### ~~3. Sync order endpoints — add to `KucoinTrading`~~ ✓

Implemented: `add_order_sync`, `add_order_batch_sync`,
`cancel_order_by_id_sync`, `cancel_order_by_client_oid_sync` (4
endpoints).

### ~~4. Modify order — add to `KucoinTrading`~~ ✓

Implemented: `modify_order` (1 endpoint).

### ~~5. DCP (Dead Connection Protection) — add to `KucoinTrading`~~ ✓

Implemented: `set_dcp`, `get_dcp` (2 endpoints).

### ~~6. Fee rates — add to `KucoinAccount`~~ ✓

Implemented: `get_base_fee_rate`, `get_fee_rate` (2 endpoints).

### ~~7. HF ledger — add to `KucoinAccount`~~ ✓

Implemented: `get_hf_ledger` (1 endpoint).

### ~~8. Server time + Service status — add to `KucoinMarketData`~~ ✓

Implemented: `get_server_time`, `get_service_status` (2 endpoints).

### ~~9. Fiat prices — add to `KucoinMarketData`~~ ✓

Implemented: `get_fiat_prices` (1 endpoint).

------------------------------------------------------------------------

### ~~10. Margin Trading — `KucoinMarginTrading` class~~ ✓

Implemented: `open_short`, `close_short`, `open_long`, `close_long`
(intent-based wrappers around private `.add_order`), `borrow`, `repay`,
`get_borrow_history`, `get_repay_history`, `get_interest_history`,
`get_borrow_rate`, `modify_leverage` (9 endpoints).

### ~~11. Margin Market Data — `KucoinMarginData` class~~ ✓

Implemented: `get_cross_margin_symbols`, `get_isolated_margin_symbols`,
`get_margin_config`, `get_collateral_ratio`, `get_risk_limit` (5
endpoints).

### ~~12. Lending — `KucoinLending` class~~ ✓

Implemented: `get_loan_market`, `get_loan_market_rate`, `purchase`,
`modify_purchase`, `get_purchase_orders`, `redeem`, `get_redeem_orders`
(7 endpoints).

------------------------------------------------------------------------

### ~~13. Futures — `KucoinFuturesMarketData`, `KucoinFuturesTrading`, `KucoinFuturesAccount` classes~~ ✓

Implemented: 44 endpoints across 3 R6 classes covering contracts,
tickers, orderbooks, klines, order lifecycle, positions, margin
management, risk limits, and funding history.

------------------------------------------------------------------------

## Won’t do (for now)

- **Sub-account admin**: API key CRUD, permission management —
  operational, not trading
- **WebSocket**: real-time feeds — significant separate architecture
- **Call auction**: pre-market orderbook + clearing data — niche,
  listing-sniper only
- **Other**: KYC regions, broker endpoints, client IP lookup

------------------------------------------------------------------------

## All items complete. Roadmap fulfilled for v4.0.0 spot + margin + futures trading scope.
