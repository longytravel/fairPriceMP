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
