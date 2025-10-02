# fairPriceMP UI/UX Specification

## Introduction
This document defines the user experience goals, information architecture, user flows, and visual design specifications for fairPriceMP’s user interface. It serves as the foundation for visual design and frontend development, ensuring a cohesive and user-centered experience.

### Overall UX Goals & Principles
#### Target User Personas
- **Independent MT5 Portfolio Trader:** Trades a curated basket of forex pairs, relies on automation for execution, needs immediate clarity on which pairs are active, blocked, or at risk.
- **Strategy Tuner / Analyst:** Runs frequent backtests and optimises parameters, needs rapid visibility into signal quality, correlation impacts, and performance history.
- **Risk-Focused Overseer:** Monitors exposure across accounts or sessions, demands trustworthy alerts, audit-ready logs, and a quick path to intervene when conditions drift.

#### Usability Goals
- Ensure at-a-glance situational awareness so traders can scan per-pair status, correlation blocks, and equity utilisation without drilling into MT5 internals.
- Compress intervention time—changing per-pair settings, pausing a symbol, or acknowledging alerts should be achievable in under three clicks.
- Prevent configuration or trading errors by guiding users through clear validation, confirmations for destructive changes, and contextual tooltips.
- Support confident backtesting workflows by keeping controls and telemetry consistent between live and strategy-tester contexts.

#### Design Principles
1. **Clarity over Complexity** – Highlight the critical pair-level signals first, relegating advanced metrics to progressive disclosure.
2. **Trust through Transparency** – Every automated action should surface its reason, timestamp, and source module to build operator confidence.
3. **Actionable Feedback** – Status changes and warnings must include the next recommended step so the trader never wonders “what now?”.
4. **Consistency Across Modes** – Keep live-trading and backtesting affordances aligned so muscle memory transfers between environments.
5. **Accessibility in the Dark** – Design for low-light trading desks with high contrast, keyboard navigation, and readable typography.

## Information Architecture (IA)

### Site Map / Screen Inventory
`mermaid
graph TD
    A[MT5 Workspace Entry] --> B[Multi-Pair Dashboard]
    B --> C[Pair Detail Drawer]
    B --> D[Correlation Guardrail Center]
    B --> E[Alert & Event Inbox]
    B --> F[Configuration Hub]
    F --> F1[Global Defaults]
    F --> F2[Symbol Overrides]
    F --> F3[Alert Settings]
    B --> G[Backtest & Replay Center]
    G --> G1[Parameter Library]
    G --> G2[Scenario Runner]
    G --> G3[Result Inspector]
    B --> H[Logs & Audit Trail]
`

### Navigation Structure
**Primary Navigation:** Persistent tab bar across the top (or pinned sidebar) with Dashboard, Configuration Hub, Backtest Center, and Logs so operators can pivot between live oversight, tuning, and forensics instantly.

**Secondary Navigation:** Contextual sub-navigation inside each primary area (e.g., tabs within Configuration Hub for Global Defaults vs Symbol Overrides; within Backtest Center for Parameter Library, Scenario Runner, Result Inspector).

**Breadcrumb Strategy:** Lightweight breadcrumb that appears only within deep drill-ins (e.g., Dashboard › EURUSD › Signal History) to preserve spatial orientation during detailed inspections.

## Dashboard Specification

### Core Layout
- **Single View Table:** One scrollable grid lists every configured symbol so traders never leave the dashboard.
- **Symbol Launcher:** Symbol name is rendered as a button/hyperlink that triggers MT5 to open that pair's chart (via ChartOpen() or equivalent script hook).
- **Column Set (Live Telemetry):**
  - **Signal State:** Current signal (Buy/Sell/Idle) with timestamp of the most recent trigger.
  - **Exposure & Orders:** Open trade count, net lots, and pending orders versus NumberOfPendingOrders.
  - **Equity Guard:** Real-time drawdown % against the per-symbol equity stop, color-coded when crossing warning (+ configurable threshold).
  - **Correlation Blocker:** Current correlation score, blocked/clear status, next recalculation countdown.
  - **Session P&L:** Rolling 24h or session P&L so traders validate behaviour quickly (optional if data source exists).
- **Column Set (Active Settings):** Inline chips or sub-columns reveal each symbol's overrides:
  - Initial_Trigger_Pips
  - Initial_Lot_Size
  - PendingOrderRangePips
  - NumberOfPendingOrders
  - EquityStopPercent
  - Trend filter toggle (UseTrendFilter/EMA values)
  - Safety filters (spread cap, trading hours window, slippage guard)
- **Inline Alerts:** Badges flag blocked trades, validation issues, or paused symbols without leaving the table.

### Interaction Model
- Clicking the symbol name opens its chart; shift-click (desktop) can open in a new MT5 window when supported.
- Hovering the settings column shows a tooltip contrasting overrides with global defaults.
- Quick actions stay limited to essentials (Pause Pair, Retry Blocked Trade once) to preserve clarity.
- Top summary strip calls out total open exposure, count of blocked symbols, and countdown to next correlation refresh.

*Rationale:* This condenses everything operators need—live state, risk posture, and the exact configuration driving it—into one screen. Surfacing the per-symbol inputs beside telemetry lets traders immediately reconcile unexpected behaviour with the underlying settings, while the direct chart launcher removes context switching friction.

