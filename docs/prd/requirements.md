# Requirements
### Functional Requirements
- FR1: The EA must load the fairPrice trade logic for a configurable list of up to 28 MT5 forex symbols from a single instance, implemented as discrete modules (symbol registry, per-symbol engine, correlation service, dashboard renderer, utilities).
- FR2: For each symbol the EA must run an isolated state and risk engine that preserves pair-specific inputs, signal tracking, open position management, and the 2 percent equity drawdown stop without cross-contamination.
- FR3: The EA must compute a rolling Pearson correlation of 30-minute log returns over a configurable lookback window (default 12 bars ~ 6 hours) on a configurable cadence (default every 5 minutes). New trades that would exceed the configured cap of highly correlated symbols must be skipped, flagged as blocked on the dashboard, and automatically reconsidered on the next correlation refresh.
- FR4: The EA must render an on-chart dashboard with one row per configured symbol showing signal state, open trades or lot exposure, drawdown utilisation, pending correlation blocks (including timestamp of last check), and other key telemetry at a glance, while allowing traders to adjust dashboard colours and font sizes via EA inputs.
- FR5: Every control point must be exposed as EA inputs, including max correlated trades, correlation lookback and cadence thresholds, dashboard refresh interval, per-symbol equity stop percent, lot sizing, grid spacing, pending order count, and notification toggles, so traders can set values such as 2 or 22 without code changes.
- FR6: The EA must support per-symbol overrides for core strategy parameters (equity stop percent, max simultaneous trades, trigger distance, grid configuration, trend filter settings), falling back to global defaults when not provided.
- FR7: The EA must support MT5 multi-currency backtesting by auto-subscribing required symbols, aligning indicator and correlation data across timeframes, and producing optimisation-friendly per-symbol metrics and logs.
- FR8: For each symbol the EA must replicate the current fairPrice trading style:
  - Entry triggers when price deviates from the fast EMA (default 200 EMA) by at least `Initial_Trigger_Pips`, respecting the optional slow EMA trend filter (default 800 EMA) to align direction.
  - On an entry signal the EA opens a market order then seeds a grid of limit orders (count = `NumberOfPendingOrders`, distributed across `PendingOrderRangePips`) sharing the initial lot size and catastrophe stop (`CatastropheSLPips`).
  - Open exposure closes when price touches the fast EMA if `CloseOnMA_Touch` is enabled, and the equity stop monitors drawdown from peak equity when `UseEquityStop` is true.
  - Safety filters (max spread, trading hours, slippage, broker filling mode) must carry over exactly from the single-symbol implementation.
- FR9: The EA must produce verbose logs for every decision (signal detection, correlation checks, order placement, closures) and persist per-symbol state so trade management resumes immediately after MT5 restarts, including reapplying open position handling and pending order oversight.

### Non-Functional Requirements
- NFR1: Modules must be loosely coupled (interface-driven services for correlation, risk, UI, backtesting) to keep future feature additions localised.
- NFR2: The EA must sustain monitoring of all 28 symbols with CPU usage under 10 percent on a 2 vCPU/4 GB VPS while keeping dashboard updates smooth.
- NFR3: Correlation calculations must use cached price or indicator data and complete within the EA's processing budget so trade execution responsiveness is unaffected.
- NFR4: Dashboard updates must stay legible in live trading and MT5 visual backtests, with layout density, refresh cadence, and colour coding tuned for rapid situational awareness.
- NFR5: Backtests with identical historical data and settings must be deterministic to support optimisation workflows.
- NFR6: Code must follow project standards for file organisation, naming, and inline documentation to preserve maintainability as modules expand.
- NFR7: On restart the EA must reconcile existing positions and pending orders for every symbol within one tick and resume correlation scheduling without manual intervention.
- NFR8: Logging verbosity must be configurable, and log records must include timestamp, symbol, event type, and decision context so investigations and audits are straightforward.
