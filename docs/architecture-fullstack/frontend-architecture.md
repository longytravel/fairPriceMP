# Frontend Architecture

### Component Organization
```
Experts/fairPriceMP/UI/
  DashboardRenderer.mqh
  DashboardTable.mqh
  DashboardBadges.mqh
  InputHandler.mqh
  ThemeProfiles.mqh
Include/fairPriceMP/UI/
  ViewModels.mqh
  DrawPrimitives.mqh
  AsciiValidator.mqh
```

### Component Template
```typescript
void RenderDashboardRow(const DashboardRowViewModel &row, const int index)
{
  string rowId = "fp_row_" + IntegerToString(index);
  DrawLabel(rowId + "_symbol", row.symbol, row.position, ThemeProfiles::GetFont(row.themeId));
  DrawBadge(rowId + "_status", FormatStatus(row.signalState), row.badgeColor);
  DrawMetric(rowId + "_exposure", DoubleToString(row.exposureLots, 2));
  DrawMetric(rowId + "_dd", DoubleToString(row.drawdownPercent, 2) + "%");
  DrawBadge(rowId + "_corr", row.correlationBadgeText, row.correlationBadgeColor);
}
```

### State Structure
```typescript
struct DashboardRowViewModel
{
  string symbol;
  ENUM_SIGNAL_STATE signalState;
  double exposureLots;
  double drawdownPercent;
  bool correlationBlocked;
  string correlationBadgeText;
  color badgeColor;
  color correlationBadgeColor;
  DashboardRowPosition position;
  int themeId;
};
```

### State Management Patterns
- Per-symbol state pulled from `SymbolRuntimeState` each redraw; no caching beyond the current tick.
- Summary strip recalculated every refresh cycle using aggregated runtime states.
- All strings pass through `AsciiValidator::Sanitize` before drawing to prevent Unicode artefacts.
- Input events push commands back to orchestrator via queue to avoid UI modules mutating engines directly.

### Routing Architecture
```
OnChartEvent
  -> InputHandler::HandleClick()
     -> CommandQueue::Enqueue(command)
  -> InputHandler::HandleHotKey()
     -> CommandQueue::Enqueue(command)
DashboardRenderer::Refresh()
  -> Iterates view models and draws components sequentially
```