# Problem Definition & Success Metrics
### Problem Statement
Small-scale retail traders who rely on MT5 spend excessive time cloning charts, tracking pending orders, and reconciling trades across symbols. Without a unified EA they risk overlapping correlated positions, missing signals, and losing track of drawdown, which blocks their ability to grow equity. The MVP removes this friction by running the trusted fairPrice logic across many pairs with built-in visibility and guardrails.

### Target User & Persona
- Independent MT5 retail trader operating from a home office or VPS.
- Comfortable adjusting EA inputs but does not want to edit code.
- Needs quick insight into what the EA is doing and why so they can intervene only when necessary.

### Success Metrics & Timeline
- Within three months of go-live, operate the desired portfolio from a single EA instance while maintaining positive net P&L on a demo or small live account.
- Reduce manual chart management to one EA deployment, cutting setup time by at least 80 percent compared to cloning 28 charts.
- Keep unexpected correlated overlaps below two incidents per month by relying on the correlation guardrail.
- Produce MT5 backtest reports for the top five parameter sets per focus pair with reproducible profit factor and drawdown metrics.

### Competitive Landscape & Differentiation
- Many grid or multi-symbol EAs still require one chart per pair, provide weak transparency, or lack per-symbol risk isolation.
- Off-the-shelf correlation filters are often inflexible and do not expose reusable metrics for backtesting.
- This MVP differentiates by retaining fairPrice's proven trade logic, layering a modular correlation service, delivering full logging with restart resilience, and focusing on configurability for a single retail operator.
