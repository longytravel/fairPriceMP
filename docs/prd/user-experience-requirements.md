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
