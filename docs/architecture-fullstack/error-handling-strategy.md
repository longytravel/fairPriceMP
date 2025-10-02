# Error Handling Strategy

### Error Flow
```mermaid
sequenceDiagram
    participant Module as Module (Engine or Service or UI)
    participant Logger as StructuredLogger
    participant Alerts as MT5 Alerts
    participant Dashboard as Dashboard Renderer
    participant Persist as Persistence Manager

    Module->>Module: Execute operation
    Module-->>Logger: Log(event)
    alt severity == CRITICAL
        Logger-->>Alerts: Send popup or email or push (ASCII text)
        Alerts-->>Dashboard: Raise badge via orchestrator
    else severity == WARNING
        Logger-->>Dashboard: Display warning badge
    end
    alt persistence impacted
        Module-->>Persist: Set needsRecovery flag
        Persist-->>Logger: Log(RECOVERY_REQ)
    end
```

### Error Response Format
```typescript
struct StructuredError
{
  string code;
  string message;
  long timestamp;
  string requestId;
  string module;
  string severity;
};
```

### Frontend Error Handling
```typescript
void DashboardRenderer::RenderErrorBadge(const StructuredError &err)
{
  string badgeId = "fp_error_" + err.code;
  color col = (err.severity == "CRITICAL") ? clrRed : clrOrange;
  DrawBadge(badgeId, "[" + err.code + "] " + err.message, col);
}
```

### Backend Error Handling
```typescript
bool SymbolEngine::PlaceOrder(const TradeRequest &req)
{
  bool ok = tradeProxy.Execute(req, lastError);
  if(!ok)
  {
    StructuredError err;
    err.code = "TRADE_FAIL";
    err.message = "OrderSend failed (" + IntegerToString(lastError) + ")";
    err.timestamp = TimeCurrent();
    err.module = this.symbol;
    err.severity = "CRITICAL";
    logger.Log(err);
    return false;
  }
  return true;
}
```
