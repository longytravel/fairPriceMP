# MVP Scope & Validation
### In Scope (Core MVP)
- Multi-symbol configuration registry supporting up to 28 forex pairs with global defaults and per-symbol overrides.
- Per-symbol execution engines that replicate the existing fairPrice entry, grid, and exit logic including equity stops.
- Correlation service computing Pearson metrics, enforcing trade concurrency caps, and rechecking on a configurable cadence.
- On-chart dashboard showing per-symbol status, warnings, and blocked trades with input-driven colour and font customisation.
- Comprehensive logging of signals, decisions, and correlation outcomes plus optional MT5 alerts that can be toggled per event type.
- State persistence so open trades and configuration resume correctly after MT5 restarts and during backtests.
- MT5 strategy tester compatibility for multi-currency runs, including metric export for optimisation.

### Out of Scope (For MVP)
- Automated lot sizing strategies or advanced money management beyond existing parameters.
- Auto-optimisation, AI, or machine learning based parameter tuning.
- Mobile or web dashboards, broker API integrations, or third-party data feeds.
- Portfolio analytics beyond the in-platform dashboard (for example equity curve visualisations).
- Multi-user configuration interfaces or remote management consoles.

### Future Enhancements
- Preset risk profiles and auto-tuning workflows for different portfolio styles.
- Broker or messaging integrations (email, Telegram, SMS) for advanced alerts.
- Visual analytics dashboards outside MT5 and historical performance reporting.
- Shared parameter libraries or cloud synchronisation for multiple traders.
- Additional correlation models such as cointegration or volatility clustering.

## Delivery Priorities
- Priority 1: Epic 1 Multi-Pair Core Foundation delivers the platform scaffolding and must ship first.
- Priority 2: Epic 2 Correlation Guardrails & Dashboard adds portfolio guardrails and trader visibility.
- Priority 3: Epic 3 Backtesting & Optimisation Enablement completes the MVP by enabling optimisation workflows.

### MVP Validation Plan
- Execute MT5 backtests for priority pairs using at least five parameter sets each, capturing profit factor, drawdown, and correlation block frequency.
- Run a two-week demo account pilot covering representative trading hours to confirm behaviour matches backtest expectations and restart resilience.
- Review logs to ensure every trade decision includes correlation status, trigger distance, and risk checks for traceability.
- Assess profitability after the first three months of live or extended demo trading, targeting positive net P&L while enforcing the 2 percent per-symbol equity stop.
- Verify that configuration adjustments can be completed entirely through EA inputs without code changes.
