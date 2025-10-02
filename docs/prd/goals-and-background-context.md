# Goals and Background Context
### Goals
- Enable the fairPrice strategy to run across multiple currency pairs from one MT5 EA while keeping the codebase modular for future feature additions.
- Surface a dashboard that tracks each pair's state, signals, open trades, and risk independently so the trader sees per-pair exposure at a glance.
- Enforce a correlation-aware cap on simultaneously traded pairs so correlated or co-trending symbols do not overlap.
- Support MT5 strategy tester workflows so parameter sets can be backtested, compared, and tuned for optimal performance while respecting per-pair equity limits.
- Scale the architecture to manage all 28 major and secondary forex pairs from a single deployment without performance degradation.
- Provide comprehensive logging, state persistence, and configurable alerts so trading decisions remain auditable and resilient across restarts.

### Background Context
Small retail MT5 traders currently run multiple chart instances to watch different pairs and manually coordinate risk. The single-symbol fairPrice EA was designed for one chart, so scaling to a portfolio is error prone, hard to monitor, and impossible to optimise end-to-end. This MVP consolidates the strategy into one modular EA that can manage all 28 forex pairs, supply a live dashboard, and enforce correlation guardrails so the trader can focus on tuning settings and reaching profitability within the next three months.
