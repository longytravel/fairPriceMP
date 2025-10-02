<!-- Auto-generated summary; edit shard files instead. -->
> NOTE: Edit the sharded files in docs/prd/ and regenerate this compiled view with md-tree assemble docs/prd docs/prd.md. Shard directory is the source of truth.

# Table of Contents

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

### Delivery Priorities
- Priority 1: Epic 1 Multi-Pair Core Foundation delivers the platform scaffolding and must ship first.
- Priority 2: Epic 2 Correlation Guardrails & Dashboard adds portfolio guardrails and trader visibility.
- Priority 3: Epic 3 Backtesting & Optimisation Enablement completes the MVP by enabling optimisation workflows.

### MVP Validation Plan
- Execute MT5 backtests for priority pairs using at least five parameter sets each, capturing profit factor, drawdown, and correlation block frequency.
- Run a two-week demo account pilot covering representative trading hours to confirm behaviour matches backtest expectations and restart resilience.
- Review logs to ensure every trade decision includes correlation status, trigger distance, and risk checks for traceability.
- Assess profitability after the first three months of live or extended demo trading, targeting positive net P&L while enforcing the 2 percent per-symbol equity stop.
- Verify that configuration adjustments can be completed entirely through EA inputs without code changes.

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

# User Interface Design Goals
### Overall UX Vision
Deliver an on-chart control panel that gives the trader instant situational awareness across all configured pairs, colour-coded signals, blocked-trade alerts, and risk stats without obscuring price action, and scales cleanly as more modules arrive.

### Key Interaction Paradigms
- Status-at-a-glance rows per symbol (traffic-light signal colours, icons for blocks and warnings).
- Hover or tooltip affordances for drilling into per-symbol parameters during live tuning.
- Input-driven configuration via the MT5 inputs dialog; the dashboard remains read-only in the MVP.
- Optional quick-action affordances (pause pair, resume pair) left inactive but visually positioned for future updates.

### Core Screens and Views
- Multi-Pair Dashboard on-chart panel (default top-left, repositionable).
- MT5 Inputs dialog for configuring global and per-symbol parameters.
- Strategy Tester visual mode overlay mirroring the live dashboard for replay and analysis.

### Accessibility: WCAG AA
### Branding
- Minimalist, broker-neutral styling with MT5 system fonts; allow the future addition of custom colour palettes.

### Target Device and Platforms: Desktop Only

# User Experience Requirements
### Primary User Journey
- Configure the EA once with desired symbols and overrides, applying settings via the MT5 input dialog.
- Launch the EA on a single chart and monitor the dashboard to understand live signals, risk usage, and blocked pairs.
- Adjust parameters between sessions (or mid-session if required) through EA inputs, relying on warnings before any disruptive changes take effect.
- Review logs and exported metrics after each session to decide on parameter tweaks for the next trading window.

### Dashboard Interaction Flow
- Rows sorted by symbol or custom priority, showing signal status, exposure, drawdown, and correlation block badge.
- Warning icon lights when correlation blocks, equity stop proximity, or data copy failures occur; clicking or hovering reveals detail text if MT5 allows.
- Colour and font settings adjustable via inputs so the trader can align the panel with personal readability preferences.
- Dashboard persists state across restarts and refreshes on the configured interval without flicker.

### Error and Alert Handling
- All blocked trades, indicator data errors, or spread violations trigger a dashboard warning, a log entry, and optional MT5 alert or email depending on toggled settings.
- Correlation refresh failures queue a retry and keep the affected row in a degraded warning state until resolved.
- Equity stop triggers generate an immediate alert and annotate the dashboard row with the drawdown percentage hit.
- Non-fatal issues (for example skipped trade due to hours filter) log once per configurable cooldown to avoid noise.

### Accessibility and Customisation
- Support high-contrast themes, colour-blind friendly palettes, and adjustable font sizes via EA inputs.
- Ensure dashboard content fits within common 1080p chart dimensions while still readable on smaller laptops.
- Provide tooltips or legend text so icons and colour codes remain understandable without memorisation.

### Performance Expectations
- Dashboard refresh should complete within 200 ms for 28 symbols so the viewport remains responsive.
- Correlation recalculation should not block UI updates; any longer-running tasks must be chunked or cached.
- Alerts and logs must be emitted asynchronously so trade execution stays prioritised.

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

### Technical Decision Guidance
- Pearson correlation on 30-minute returns balances responsiveness with noise control; alternative models (for example cointegration) are deferred to keep the MVP simple.
- A modular per-symbol engine inside one EA avoids the operational cost of running 28 chart instances while keeping code reuse high; microservice patterns are unnecessary in MT5.
- Logging to both terminal and file trades storage space for debuggability; users can tune verbosity to manage disk usage.
- Restart persistence relies on MT5 global variables or files; risk is data loss on abrupt shutdown, mitigated by writing snapshots after each significant state change.
- Known technical risks include correlation computation cost at scale and ensuring indicator buffers are available during tester runs; development should profile these paths early.
- Technical debt tolerance: document shortcuts taken for the MVP (for example minimal alert routing) and create follow-up tasks so they are addressed in future iterations.

# Cross-Functional Requirements
### Data Requirements
- Price history and indicator buffers cached per symbol to avoid redundant requests.
- Log files retained for at least 90 days in a dedicated directory for audit and troubleshooting.
- Exported optimisation metrics stored in CSV or JSON with clear headers for later analysis.
- No external user data or PII is collected.

### Integration and Alerts
- Optional MT5 terminal pop-ups, push notifications, or emails configurable per alert type.
- No third-party APIs or data feeds are integrated in the MVP; all data comes from subscribed MT5 symbols.
- Provide a simple toggle matrix in inputs for enabling or disabling each alert category.

### Operational Requirements
- Target deployment on Windows VPS (2 vCPU, 4 GB RAM) or desktop; the EA must handle MT5 restarts gracefully.
- Provide start-up diagnostics that list loaded symbols, parameter overrides, and correlation settings.
- Include guidance on how to schedule regular log backups or clean-up to manage disk usage.
- Document the restart procedure so the trader knows how to verify state restoration.

### Security and Compliance
- The EA operates entirely within MT5 and stores configuration locally; no external credential sharing.
- Sensitive information (account numbers, magic numbers) remains within MT5 and should not be written to external logs unless necessary.
- Follow MT5 best practices for secure file writing (for example `FilesDirectory`).

### Support and Monitoring
- Recommend daily or session-based log review focusing on warnings and blocked trades.
- Provide a troubleshooting section (to be completed later) covering common issues such as missing history or indicator initialisation failures.
- Highlight key metrics to watch in the dashboard (blocked trade count, drawdown utilisation) for quick health checks.
- Document contact points or self-help steps for future support automation.

# Epic List
- Epic 1: Multi-Pair Core Foundation - Stand up the modular scaffolding that lets a single EA instance manage up to 28 forex pairs, spinning up per-symbol engines that mirror today's fairPrice trading style while keeping risk, configuration, and lifecycle logic cleanly isolated for future expansion.
- Epic 2: Correlation Guardrails & Dashboard - Introduce the correlation service, enforce the configurable concurrency cap across the full 28-pair universe, surface blocked-trade messaging, and deliver the per-symbol dashboard for live situational awareness.
- Epic 3: Backtesting & Optimisation Enablement - Harden multi-currency strategy tester support for all 28 pairs, capture per-symbol metrics and logs, and ensure parameter input and export workflows make optimisation runs repeatable and deterministic.

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

## Checklist Results Report
### pm-checklist (2025-10-02)
- Overall decision: Ready for architect engagement.
- Estimated completeness: ~95 percent; MVP scope reads as Just Right and the document supports hand-off to design and engineering.
- Architecture readiness: Ready. All core constraints, risks, and priorities are captured.

**Category Outcomes**
- Problem Definition & Context - PASS: Problem, persona, success metrics, and differentiation are clearly articulated.
- MVP Scope Definition - PASS: In-scope, out-of-scope, delivery priorities, and validation plan provide actionable boundaries.
- User Experience Requirements - PASS: Journeys, dashboard interaction, error handling, and accessibility expectations are covered.
- Functional Requirements - PASS: Requirements are testable, prioritised, and tied to the epics; logging and persistence obligations are explicit.
- Non-Functional Requirements - PASS: Performance, determinism, restart behaviour, and logging constraints are defined.
- Epic & Story Structure - PASS: Epics are sequential, dependencies are listed, and stories remain developer-sized with acceptance criteria.
- Technical Guidance - PASS: Decisions, trade-offs, and known risks are captured for the architect.
- Cross-Functional Requirements - PASS: Data, integration, operational, security, and monitoring needs are documented.
- Clarity & Communication - PASS: Document structure, stakeholder notes, and change log readiness support ongoing collaboration.

**Follow-Up Suggestions (No Blockers)**
- Prepare the upcoming troubleshooting appendix and expand the change log as iterations occur.
- Define log file naming conventions and retention scripts during implementation to align with the operational plan.
- Coordinate with UX and architecture to keep dashboard visuals and module interfaces aligned with this scope.


# Next Steps
### UX Expert Prompt
Use this PRD to draft a lightweight MT5 dashboard specification that outlines row layout, warning states, colour and font customisation inputs, and guidance on keeping the panel readable for up to 28 symbols.

### Architect Prompt
Use this PRD to design the modular multi-symbol EA architecture, covering per-symbol engines, correlation scheduling, logging and persistence mechanisms, and performance strategies for monitoring 28 pairs with restart resilience.









