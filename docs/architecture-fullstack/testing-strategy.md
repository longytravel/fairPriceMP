# Testing Strategy
```
E2E Tests
/        \
Integration Tests
/            \
Frontend Unit  Backend Unit
```

**Frontend Tests**
```
- Snapshot comparison of dashboard rows via view model harness
- Rendering smoke test asserting chart object counts and ASCII validation success
```

**Backend Tests**
```
- SymbolEngine deterministic replay using recorded tick streams
- CorrelationService window maths validated against reference CSV
- Persistence round-trip: serialize, deserialize, compare DTOs
```

**E2E Tests**
```
- MT5 strategy tester multi-symbol runs with assertion script diffing exported logs
- VPS smoke test: compile, sync, start terminal, verify snapshot and log directories populated
```

**Test Example**
```typescript
void TestCorrelationBlocksWhenAboveCap()
{
  CorrelationService svc(...);
  svc.LoadHistory(mockData);
  CorrelationSnapshot snap = svc.Evaluate();
  assert(snap.blockedSymbols[0] == "GBPUSD");
}
```