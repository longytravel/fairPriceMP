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
