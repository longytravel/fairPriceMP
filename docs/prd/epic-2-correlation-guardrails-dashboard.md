# Epic 2 Correlation Guardrails & Dashboard
### Story 2.1 Correlation Data Pipeline
As a trader, I want the EA to maintain rolling correlation metrics across my configured symbols, so that trade concurrency decisions use timely, objective data.

#### Acceptance Criteria
1: The EA computes Pearson correlation on 30-minute log returns over a configurable lookback (default 12 bars) for every symbol pair in the portfolio.
2: Correlation refresh runs on a configurable timer (default 5 minutes) without blocking trade execution; results are cached for reuse.
3: Traders can adjust lookback size, refresh cadence, and correlation threshold via EA inputs, and see the current settings logged on init.
4: Any data gaps or subscription failures are surfaced in logs and flagged for dashboard display.

### Story 2.2 Correlation-Aware Trade Gatekeeper
As a trader, I want the EA to block or defer new trades that would exceed my correlated-pair limit, so that I avoid stacking risk across co-trending symbols.

#### Acceptance Criteria
1: Before opening a new position, the EA evaluates active positions plus the candidate pair against the configured max-correlated-pair limit and threshold.
2: If adding the trade breaches the limit, the trade is skipped, logged with reason, and the pair is marked as blocked until the next correlation refresh.
3: On each correlation refresh, the EA re-evaluates blocked pairs and automatically re-enables trading when conditions allow.
4: Traders can adjust the correlated pair cap (for example 2 to 28) and opt into optional alerts (terminal notification or email) whenever blocks trigger or clear.

### Story 2.3 Multi-Pair Dashboard Overlay
As a trader, I want a compact on-chart dashboard showing each symbol's status, exposure, drawdown, and correlation blocks, so I can make quicker decisions without digging through logs.

#### Acceptance Criteria
1: Dashboard renders one row per symbol with columns for signal state (colour-coded), open positions or lot size, drawdown percent, correlation block flag, last action time, and configurable metrics.
2: When a pair is correlation-blocked, the row shows a clear blocked badge plus the timestamp of the last correlation check.
3: Dashboard refresh interval is configurable (default 1 second) and remains performant across 28 symbols, with the ability to reposition it on the chart.
4: Layout and colours maintain legibility in both live charts and MT5 visual backtests, respecting high-contrast defaults.
