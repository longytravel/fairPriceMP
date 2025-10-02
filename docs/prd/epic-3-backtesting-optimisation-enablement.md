# Epic 3 Backtesting & Optimisation Enablement
### Story 3.1 Strategy Tester Readiness
As a trader, I want the EA to run multi-currency backtests without manual symbol setup, so that optimisation workflows are frictionless.

#### Acceptance Criteria
1: On init in strategy tester mode, the EA auto-subscribes every configured symbol or timeframe needed for correlation and indicators, reporting gaps as errors.
2: The EA preloads historical data (prices, MAs) for each symbol before the test clock starts to avoid mid-run delays.
3: Backtests complete without runtime errors with the default 28-symbol configuration, matching live-trading behaviour.
4: Tester logs include a summary of subscribed symbols, initial parameter values, and correlation settings for traceability.

### Story 3.2 Deterministic Metrics & Logs
As a trader, I want per-symbol metrics and logs exported consistently after each backtest, so I can compare optimisation runs.

#### Acceptance Criteria
1: At test completion the EA writes a structured log (for example CSV or JSON) capturing per-symbol statistics: trades taken, win or loss, peak drawdown, correlation blocks, and alerts triggered.
2: Metrics generated from identical data and settings match across repeated runs (within tolerance), proving determinism.
3: Traders can toggle which metrics to export via inputs and specify an output file prefix or date stamp.
4: Failure to write logs raises a clear tester alert with troubleshooting guidance.

### Story 3.3 Backtest-Friendly Parameter Profiles
As a trader, I want ready-made parameter groupings for optimisation, so I can iterate through correlation and risk scenarios efficiently.

#### Acceptance Criteria
1: EA exposes grouped input sets (for example correlation window and cap presets, risk profile presets) documented in the PRD so users can run standard optimisations.
2: Documentation (README or strategy tester notes) explains how to vary key parameters and interpret exported metrics.
3: Optional baseline and aggressive presets are provided to showcase how the EA behaves under different concurrency and risk tolerances.
4: Running optimisation across these presets produces distinct, analysable output files without manual editing.
