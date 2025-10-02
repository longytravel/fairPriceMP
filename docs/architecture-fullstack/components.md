# Components

### Orchestrator Core
**Responsibility:** Bootstraps the EA, loads configuration from `Include/fairPriceMP/config`, owns event loop (`OnInit`, `OnTick`, `OnTimer`), and coordinates handoffs between modules.

**Key Interfaces:**
- `bool InitSystem(string configPath)`
- `void DispatchTick(string symbol, MqlTick tick)`
- `void ScheduleTask(ENUM_TASK taskId, int delayMs)`

**Dependencies:** Configuration loader, symbol engines, correlation service, persistence manager, logging facade.

**Technology Stack:** MQL5 class in `Experts/fairPriceMP/CoreOrchestrator.mqh` leveraging MT5 built-ins.
### Configuration Loader
**Responsibility:** Parse global defaults and per-symbol overrides, validate ASCII-only values, surface DTOs to other modules.

**Key Interfaces:**
- `ConfigDto LoadConfig(string fileName)`
- `ValidationResult ValidateSymbolList(string symbols[])`

**Dependencies:** Files directory access, logging facade.

**Technology Stack:** Utility in `Include/fairPriceMP/ConfigLoader.mqh` using MT5 file API and ASCII validator.
### Symbol Engine
**Responsibility:** Execute fairPrice trade lifecycle (signal evaluation, grid placement, equity stop) independently per symbol.

**Key Interfaces:**
- `void ProcessTick(MqlTick tick)`
- `void ApplyCorrelationBlock(bool blocked)`
- `SymbolRuntimeState GetRuntimeState()`

**Dependencies:** Configuration DTOs, correlation service, trade execution proxy, logging facade, persistence manager.

**Technology Stack:** Class in `Experts/fairPriceMP/Engines/SymbolEngine.mqh`.
### Correlation Service
**Responsibility:** Maintain rolling correlation windows, compute Pearson coefficients, enforce concurrency caps, publish block or unblock events.

**Key Interfaces:**
- `CorrelationSnapshot EvaluateCorrelation(map<string, double[]> ticksBySymbol)`
- `bool ShouldBlock(string symbol)`

**Dependencies:** Configuration, orchestrator scheduler, logging, persistence.

**Technology Stack:** `Experts/fairPriceMP/Services/CorrelationService.mqh` with math helpers in `Include`.
### Dashboard Renderer
**Responsibility:** Draw on-chart table, warnings, and summary strip; respond to user inputs; ensure ASCII-safe labels.

**Key Interfaces:**
- `void Render(const SymbolRuntimeState states[], const CorrelationSnapshot &corr)`
- `void HighlightAlert(string symbol, string code)`

**Dependencies:** Symbol engine data, configuration for styles, logging for UI actions.

**Technology Stack:** `Experts/fairPriceMP/UI/DashboardRenderer.mqh` using MT5 drawing primitives.
### Persistence Manager
**Responsibility:** Serialize runtime state and snapshots to `Files/fairPriceMP`, load them on init, manage versioning.

**Key Interfaces:**
- `bool SaveSnapshot(const PersistenceSnapshot &state)`
- `bool LoadLatestSnapshot(PersistenceSnapshot &outState)`

**Dependencies:** Symbol engines, correlation service, logging, file IO guardrails.

**Technology Stack:** `Experts/fairPriceMP/Persistence/PersistenceManager.mqh` writing ASCII JSON or CSV.
### Logging and Alert Facade
**Responsibility:** Standardize log entries, wrap MT5 journal output, optional alert broadcasting, enforce ASCII-only text.

**Key Interfaces:**
- `void Log(const StructuredLogEntry &entry)`
- `void Alert(string eventCode, string message)`

**Dependencies:** All modules; optional PowerShell export scripts.

**Technology Stack:** `Include/fairPriceMP/Logging/StructuredLogger.mqh`.
### Strategy Tester Exporter
**Responsibility:** At tester completion, export metrics and logs to CSV or JSON for diffing and optimisation analysis.

**Key Interfaces:**
- `bool ExportMetrics(const PersistenceSnapshot &snapshot, string outputPath)`

**Dependencies:** Persistence manager, logging.

**Technology Stack:** `Experts/fairPriceMP/Export/TesterExporter.mqh`.
### Deployment Sync Scripts
**Responsibility:** Mirror repository artefacts into MT5 VPS directories (`MQL5\\Experts`, `Include`, `Files`).

**Key Interfaces:** PowerShell script parameters (source path, terminal data path).

**Dependencies:** Local filesystem, optional scheduling.

**Technology Stack:** `scripts/MT5_File_Sync.ps1`, `Start_MT5_Sync.bat`.
```mermaid
graph LR
    ConfigLoader --> Orchestrator
    Orchestrator --> SymbolEngines
    Orchestrator --> CorrelationService
    Orchestrator --> PersistenceManager
    SymbolEngines --> TradeProxy((Trade API Wrapper))
    SymbolEngines --> DashboardRenderer
    CorrelationService --> SymbolEngines
    CorrelationService --> PersistenceManager
    PersistenceManager --> FilesDir((MQL5\\Files))
    Orchestrator --> Logger
    SymbolEngines --> Logger
    CorrelationService --> Logger
    DashboardRenderer --> Logger
    Logger --> Alerts((MT5 Alerts))
    TesterExporter --> FilesDir
    SyncScripts -->|sync| MT5TerminalDataDir
```