# Backend Architecture

### Service Architecture
```
Experts/fairPriceMP/
  CoreOrchestrator.mqh
  Engines/
    SymbolEngine.mqh
    SymbolEngineFactory.mqh
  Services/
    CorrelationService.mqh
    Scheduler.mqh
    TradeProxy.mqh
  Persistence/
    PersistenceManager.mqh
    SnapshotSerializer.mqh
  Export/
    TesterExporter.mqh
Include/fairPriceMP/
  DTO/
    ConfigDto.mqh
    SymbolRuntimeState.mqh
    CorrelationSnapshot.mqh
  Logging/
    StructuredLogger.mqh
    LogFormatter.mqh
  Validation/
    AsciiGuard.mqh
    ConfigValidator.mqh
```

### Controller Template
```typescript
void OnTick()
{
  MqlTick tick;
  if(!SymbolInfoTick(_Symbol, tick))
  {
    logger.LogError("TICK_FETCH", "Failed to read tick for " + _Symbol);
    return;
  }

  SymbolEngine *engine = engineRegistry.Get(_Symbol);
  if(engine == NULL)
  {
    logger.LogError("ENGINE_MISSING", "No engine registered for " + _Symbol);
    return;
  }

  engine.ProcessTick(tick);
}
```
### Data Access Layer Template
```typescript
class SnapshotRepository
{
private:
  string basePath;

public:
  SnapshotRepository(const string _basePath)
  {
    basePath = _basePath;
  }

  bool Save(const PersistenceSnapshot &snapshot)
  {
    string path = basePath + "\\" + snapshot.snapshotId + ".json";
    string payload = SnapshotSerializer::ToJson(snapshot);
    AsciiGuard::EnsureAscii(payload);
    return FileSystem::WriteFile(path, payload);
  }

  bool LoadLatest(PersistenceSnapshot &outSnapshot)
  {
    string latestPath = FileSystem::FindLatest(basePath);
    if(latestPath == "")
      return false;

    string payload = FileSystem::ReadFile(latestPath);
    AsciiGuard::EnsureAscii(payload);
    return SnapshotSerializer::FromJson(payload, outSnapshot);
  }
};
```

### Authentication and Authorization
MT5 terminals authenticate via broker credentials; the EA runs under the logged-in account. No additional authentication layers exist or are needed for the MVP.