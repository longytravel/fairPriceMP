# Epic 1 Multi-Pair Core Foundation
### Story 1.1 Multi-Symbol Configuration Registry
As a trader, I want to configure up to 28 symbols with global defaults and per-symbol overrides, so that I can manage the entire portfolio from one EA without code edits.

#### Acceptance Criteria
1: EA inputs expose symbol list management, global defaults, and per-symbol override slots (grid, risk, correlation, dashboard settings).
2: Duplicate or unsupported symbols are rejected with descriptive errors before trading starts.
3: On init, the EA auto-subscribes required symbols or timeframes and reports readiness per symbol in the log or dashboard.
4: Configuration data is stored in a structure accessible to downstream modules (risk, correlation, UI) without direct coupling.

### Story 1.2 Per-Symbol Engine & Trade Lifecycle
As a trader, I want each configured pair to run the fairPrice entry, grid, and exit rules independently, so that multi-pair trading behaves exactly like the proven single-symbol EA.

#### Acceptance Criteria
1: Entry triggers only when the price deviates from the fast EMA by at least the configured trigger pips, respecting the optional slow EMA trend filter.
2: On a valid signal, the engine opens the market order and seeds the pending-order grid using pair-specific parameters (lot size, count, spacing, catastrophe SL).
3: Spread, slippage, and trading-hour filters are enforced per pair before any order is sent.
4: Exit logic closes all exposure for that pair when price touches the fast EMA if enabled, matching single-symbol behaviour in back-to-back regression runs.

### Story 1.3 Pair-Isolated Risk & State Management
As a trader, I want each pair's risk controls, drawdown tracking, and logging to stay isolated, so that an issue on one symbol never disturbs the others.

#### Acceptance Criteria
1: Equity stop logic tracks peak equity per symbol and closes only that symbol's positions when the configured drawdown threshold is breached.
2: Position or pending counts and state caches are namespaced by symbol and do not leak between engines.
3: Logs and dashboard lines include symbol identifiers and summarise current exposure, drawdown utilisation, and last action.
4: Unit or backtest verification compares single-symbol and multi-symbol runs to confirm parity within an acceptable tolerance.
