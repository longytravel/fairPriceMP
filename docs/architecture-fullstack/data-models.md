# Data Models

### SymbolConfigEntry
**Purpose:** Capture trader-defined global defaults and per-symbol overrides that drive engines, correlation caps, and dashboard presentation.

**Key Attributes:**
- `symbol`: `string` � MT5 symbol name; must match broker symbol exactly (ASCII only).
- `isEnabled`: `bool` � Whether the symbol participates in trading.
- `overrides`: `struct SymbolOverrides` � Optional per-symbol parameter deltas.
- `dashboardStyle`: `struct DashboardStyle` � Row-level colour or font overrides for readability.

```typescript
struct SymbolConfigEntry {
  string symbol;
  bool isEnabled;
  SymbolOverrides overrides;
  DashboardStyle dashboardStyle;
};
```

**Relationships:** Feed `SymbolRuntimeState` during init; shared with `CorrelationSnapshot` to determine concurrency caps.
### SymbolRuntimeState
**Purpose:** Hold live telemetry for each active symbol so engines, dashboard, and persistence remain in sync.
**Key Attributes:**
- `symbol`: `string` – Identifier linking to config entry.
- `signalState`: `ENUM_SIGNAL_STATE` – Current signal (Buy, Sell, Idle, Blocked).
- `openTrades`: `int` – Count of active trades tracked by MagicNumber.
- `drawdownPercent`: `double` – Peak-to-current equity drawdown for the symbol.
- `lastActionTime`: `datetime` – Timestamp of last trade or correlation block update.
- `correlationBlocked`: `bool` – Whether new entries are currently prevented.
```typescript
struct SymbolRuntimeState {
  string symbol;
  ENUM_SIGNAL_STATE signalState;
  int openTrades;
  double drawdownPercent;
  datetime lastActionTime;
  bool correlationBlocked;
};
```

**Relationships:** Updated by `SymbolEngine`, rendered by dashboard view models, serialized into `PersistenceSnapshot`.
### CorrelationSnapshot
**Purpose:** Persist outputs of the correlation service per evaluation cycle to enforce guardrails and provide audit trail.

**Key Attributes:**
- `evaluationTime`: `datetime` – When the correlations were computed.
- `pairwiseScores`: `struct PairwiseScore[]` – Symbol pairs with Pearson values.
- `blockedSymbols`: `string[]` – Symbols blocked this cycle due to exceeding cap.
- `capThreshold`: `int` – Global limit on concurrent correlated symbols.
```typescript
struct CorrelationSnapshot {
  datetime evaluationTime;
  PairwiseScore pairwiseScores[];
  string blockedSymbols[];
  int capThreshold;
};
```
**Relationships:** Consumed by `SymbolEngine` to decide entry eligibility, logged for diagnostics, stored in Files directory for backtest exports.
### StructuredLogEntry
**Purpose:** Standardize log output for live runs and tester replays so analysis scripts can diff behaviour deterministically.

**Key Attributes:**
- `timestamp`: `datetime` – UTC timestamp of the event.
- `module`: `ENUM_MODULE` – Originating module (Engine, Correlation, Dashboard, Persistence).
- `eventCode`: `string` – Short ASCII code describing the event.
- `message`: `string` – ASCII-only detail string.
- `metadata`: `struct KeyValue[]` – Optional key-value pairs.
```typescript
struct StructuredLogEntry {
  datetime timestamp;
  ENUM_MODULE module;
  string eventCode;
  string message;
  KeyValue metadata[];
};
```
**Relationships:** Emitted by all modules through the shared logging facade; basis for alert routing and tester log comparisons.
### PersistenceSnapshot
**Purpose:** Provide crash-safe restore point for engines and correlation state by writing to MT5 `Files` directory.

**Key Attributes:**
- `snapshotId`: `string` – Sequential or timestamp-based identifier (ASCII).
- `capturedAt`: `datetime` – When snapshot was taken.
- `runtimeStates`: `SymbolRuntimeState[]` – Serialized runtime state array.
- `pendingOrders`: `struct PendingOrderRecord[]` – Info on grid orders queued but not filled.
- `correlation`: `CorrelationSnapshot` – Latest correlation data.
```typescript
struct PersistenceSnapshot {
  string snapshotId;
  datetime capturedAt;
  SymbolRuntimeState runtimeStates[];
  PendingOrderRecord pendingOrders[];
  CorrelationSnapshot correlation;
};
```
**Relationships:** Written by persistence worker on schedule, read during EA init to resume state, exported post-backtest for optimisation analysis.