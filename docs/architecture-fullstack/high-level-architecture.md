# High Level Architecture

### Technical Summary
The system centers on a modular Expert Advisor running inside a Windows-based MT5 terminal, organized into independent per-symbol engines, a shared correlation service, and a dashboard renderer that share a common event bus. The frontend experience is the on-chart dashboard layer, built with structured drawing primitives and input bindings that surface state from the core trading modules; the backend is a set of MQL5 services that manage trade lifecycle, correlation monitoring, persistence, and logging. A lightweight orchestration layer coordinates configuration loading, task scheduling, and health reporting while background workers handle persistence snapshots and alert fan-out. All components execute in one MT5 process but are isolated via namespaces, consistent state DTOs, and test seams so the codebase remains maintainable even as we scale to 28 symbols. Supporting scripts (PowerShell for sync, CSV exporters) run alongside the EA to move artefacts into the MT5 `MQL5\\Experts`, `MQL5\\Indicators`, `MQL5\\Include`, and `MQL5\\Files` directories, satisfying the repository and terminal alignment the trader depends on. This structure meets the PRD goals by preserving proven fairPrice trade logic, adding correlation guardrails, guaranteeing restart resilience, and exposing deterministic telemetry for both live trading and strategy tester runs.
### Platform and Infrastructure Choice
**Option A � Windows VPS with MT5 Terminal (Recommended)**
- Pros: Always-on environment, stable network latency to broker, easy to back up MT5 data folders, simplifies automation of log exports.
- Cons: Monthly VPS cost, need to harden Windows security.
- Fit: Aligns with requirement to run 28 symbols concurrently and keep persistent state and logs.

**Option B � High-Spec Local Trading Workstation**
- Pros: Zero hosting cost, straightforward hardware control, quick manual intervention.
- Cons: Dependent on user uptime and internet, harder to automate backups across restarts.
- Fit: Acceptable for early tuning but risks downtime for production trading.

**Option C � Managed Prop-Firm Hosting (MT5 SaaS)**
- Pros: Broker-grade redundancy, managed OS patching.
- Cons: Limited filesystem access (difficult to manage Include or Files directories), vendor lock-in, reduced control over correlation snapshots.
- Fit: Conflicts with need for custom persistence and log handling.

**Recommendation**

**Platform:** Windows VPS (MT5 Terminal on Windows Server 2019/2022)  
**Key Services:** MT5 Terminal, MQL5 scheduler (OnTimer), PowerShell sync scripts, optional cloud storage for log backup  
**Deployment Host and Regions:** Primary VPS in broker-preferred region (for example London LD4) with secondary standby image for failover
### Repository Structure
```
**Structure:** Monorepo mirroring MT5 directory layout inside `src/MT5`
**Monorepo Tool:** Native Git (no extra tooling)
**Package Organization:**
- `src/MT5/Experts/fairPriceMP/` for EA modules
- `src/MT5/Include/fairPriceMP/` for shared headers and utilities
- `src/MT5/Indicators/` for custom indicators
- `src/MT5/Files/` for persistence snapshots and exported metrics
- `scripts/` for PowerShell or BAT sync helpers
```

### High Level Architecture Diagram
```mermaid
graph TD
    Trader[Trader UI Interaction] --> MT5Terminal[MT5 Terminal (Windows VPS)]
    MT5Terminal -->|loads| FairPriceEA[fairPriceMP EA (Experts/fairPriceMP)]
    FairPriceEA -->|publishes state| Dashboard[On-Chart Dashboard Renderer]
    FairPriceEA -->|dispatches| SymbolEngines[Per-Symbol Engines]
    SymbolEngines -->|trade ops| TradeOps[MQL5 Trade API]
    FairPriceEA --> CorrelationSvc[Correlation & Guardrail Service]
    FairPriceEA --> Persistence[State Persistence (Files/Global Vars)]
    FairPriceEA --> Logging[Structured Logging & Alerts]
    Persistence --> FilesDir[MT5 Files Directory (Snapshots/Exports)]
    Logging --> Alerts[MT5 Alerts (Popup/Email/Push)]
    scripts[Sync & Export Scripts] -->|sync artefacts| MT5Terminal
    StrategyTester[Strategy Tester] --> FairPriceEA
```

### Architectural Patterns
- **Modular Monolith EA:** Single MT5 process with explicit module boundaries and dependency inversion between orchestration, engines, correlation, and UI components. _Rationale:_ Matches MT5 execution constraints while keeping the codebase maintainable and testable.
- **Event-Driven Intra-EA Messaging:** Publish or subscribe dispatcher for state updates (ticks, correlation events, dashboard refresh). _Rationale:_ Decouples modules and avoids tight coupling when scaling to 28 symbols.
- **Repository and DTO Pattern for State:** Shared DTOs in `Include/fairPriceMP` with repository-style accessors for configuration, persistence, and telemetry. _Rationale:_ Ensures consistent state handling across modules and simplifies strategy tester determinism.
- **Scheduled Task Loop Pattern:** Central OnTimer scheduler triggers correlation recalculations, persistence snapshots, and dashboard updates. _Rationale:_ Provides predictable cadence from the PRD without blocking tick processing.
- **Layered Error Handling:** Standardized error facade wrapping MT5 return codes with uniform logging and dashboard error badges. _Rationale:_ Supports unified alerting and simplifies debugging across modules.