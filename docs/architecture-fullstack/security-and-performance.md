# Security and Performance
**Frontend Security**
- CSP Headers: N/A (MT5 chart)
- XSS Prevention: Limit inputs to ASCII; sanitize text before drawing.
- Secure Storage: No sensitive data stored in UI; only derived telemetry.

**Backend Security**
- Input Validation: Config loader rejects unsupported symbols, Unicode, or invalid numeric ranges.
- Rate Limiting: Guard correlation recalculation frequency via scheduler.
- CORS Policy: N/A.

**Authentication Security**
- Token Storage: Not applicable; rely on broker login.
- Session Management: MT5 terminal session.
- Password Policy: Managed by broker; do not log or persist credentials.

**Performance Optimization**
- Frontend: Limit chart objects per refresh to fewer than 400; reuse object IDs to avoid flicker; throttle redraw to 1 Hz.
- Backend: Target tick processing under 10 ms; cache MA buffers; stagger correlation evaluations; rotate snapshot files to avoid I/O spikes.