# Core Workflows
```mermaid
sequenceDiagram
    participant Tick as MT5 Tick Stream
    participant Orchestrator as Core Orchestrator
    participant Engine as Symbol Engine (EURUSD)
    participant Corr as Correlation Service
    participant Dash as Dashboard Renderer
    participant Persist as Persistence Manager
    participant Logger as Structured Logger
    Tick->>Orchestrator: OnTick(_Symbol, MqlTick)
    Orchestrator->>Engine: ProcessTick(tick)
    Engine->>Corr: RequestCorrelationStatus(symbol)
    Corr-->>Engine: ShouldBlock = false
    Engine->>Engine: EvaluateEntry or Exit Rules
    Engine->>Logger: Log(SIG_UPD)
    Engine->>Dash: Publish SymbolRuntimeState
    Dash->>Logger: Log(UI_REFRESH)
    Orchestrator->>Persist: QueueSnapshotIfDue()
    Persist-->>Logger: Log(SNAP_WRITE or SNAP_SKIP)
```
```mermaid
sequenceDiagram
    participant Timer as OnTimer Scheduler
    participant Corr as Correlation Service
    participant Engines as All Symbol Engines
    participant Persist as Persistence Manager
    participant Logger as Structured Logger
    participant Files as MQL5 Files
    Timer->>Corr: EvaluateCorrelation()
    Corr->>Corr: Compute Pearson Windows
    Corr->>Logger: Log(CORR_EVAL)
    Corr-->>Engines: Broadcast BlockedSymbols
    Engines->>Logger: Log(BLOCK_SET or BLOCK_CLEAR)
    Timer->>Persist: SaveSnapshot(latestState)
    Persist->>Files: Write ASCII JSON or CSV file
    Persist-->>Logger: Log(SNAP_WRITE, requestId)
```
```mermaid
sequenceDiagram
    participant Init as OnInit
    participant Persist as Persistence Manager
    participant Orchestrator as Core Orchestrator
    participant Engines as Symbol Engines
    participant Dash as Dashboard Renderer
    participant Logger as Structured Logger
    Init->>Persist: LoadLatestSnapshot()
    Persist-->>Init: Snapshot or null
    Init->>Logger: Log(INIT_START)
    Init->>Engines: HydrateFromSnapshot()
    Init->>Dash: InitializeLayout()
    Init-->>Logger: Log(INIT_COMPLETE)
```