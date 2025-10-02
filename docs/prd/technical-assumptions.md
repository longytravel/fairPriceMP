# Technical Assumptions
### Repository Structure: Monorepo
We will keep the EA under the existing `fairPriceMP` workspace as a single repository so all MQL5 modules (core engine, correlation services, dashboard renderer) and docs live together. That keeps strategy, configuration, QA artefacts, and future modules aligned without cross-repo coordination overhead.

### Service Architecture
Single-process EA modularised into distinct service classes or namespaces: per-symbol engine (state, risk, trade execution), correlation service, dashboard UI renderer, alert dispatcher, persistence utilities, and shared helpers for logging and configuration.

### Testing Requirements
Unit and integration coverage where feasible (for example buffer calculations, correlation math via MQL5 test harness) plus strategy tester scenarios for end-to-end validation. Backtests become the primary regression mechanism, with scripted optimisation runs to capture metrics per symbol.

### Additional Technical Assumptions and Requests
- Language: MQL5, using object-oriented patterns available in MetaEditor 5.
- Correlation engine built on cached time-series arrays sourced via `CopyRates` or `CopyClose`, computing Pearson coefficients on log returns; cadence and lookback configurable.
- Dashboard built with MT5 graphical primitives (for example `CCanvas`, labels) to stay performant and themeable.
- Configuration stored via EA inputs, with optional CSV or JSON import reserved for a later module.
- Logging via `Print` plus optional file logs for backtest export; log format should be `[timestamp][symbol][event] message`.
- Persistence may leverage Global Variables of the Terminal or file-based snapshots so restarts restore per-symbol state.
- Alerts use MT5 native notifications or email; additional integrations are deferred.

## Technical Decision Guidance
- Pearson correlation on 30-minute returns balances responsiveness with noise control; alternative models (for example cointegration) are deferred to keep the MVP simple.
- A modular per-symbol engine inside one EA avoids the operational cost of running 28 chart instances while keeping code reuse high; microservice patterns are unnecessary in MT5.
- Logging to both terminal and file trades storage space for debuggability; users can tune verbosity to manage disk usage.
- Restart persistence relies on MT5 global variables or files; risk is data loss on abrupt shutdown, mitigated by writing snapshots after each significant state change.
- Known technical risks include correlation computation cost at scale and ensuring indicator buffers are available during tester runs; development should profile these paths early.
- Technical debt tolerance: document shortcuts taken for the MVP (for example minimal alert routing) and create follow-up tasks so they are addressed in future iterations.
