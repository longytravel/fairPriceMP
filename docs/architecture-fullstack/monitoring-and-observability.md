# Monitoring and Observability
- Frontend Monitoring: Structured logger events (`UI_REFRESH`, `ALERT_TAP`), optional screenshot script on critical alerts.
- Backend Monitoring: Structured logs per module, heartbeat entry every 60 seconds, scheduler duration metrics.
- Error Tracking: MT5 alerts (popup, email, push) plus log flag `severity=CRITICAL` for downstream filters.
- Performance Monitoring: Snapshot exports capturing tick latency, correlation duration, snapshot write time; PowerShell summarizer emails daily stats.

**Key Metrics**
- Frontend: dashboard redraw latency, object count, warning badge count, operator acknowledgement time for critical alerts.
- Backend: average tick processing time, correlation evaluation duration and blocked symbol count, snapshot success rate, strategy tester runtime vs baseline.