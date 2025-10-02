# Database Schema
We do not use a traditional database; persistence relies on MT5 `Files` directory with ASCII-encoded JSON or CSV artefacts. The snapshot format below is the contract developers must follow.
```json
{
  "snapshotId": "20251002T201500Z",
  "capturedAt": "2025-10-02T20:15:00Z",
  "runtimeStates": [
    {
      "symbol": "EURUSD",
      "signalState": "BUY",
      "openTrades": 2,
      "drawdownPercent": 0.45,
      "lastActionTime": "2025-10-02T20:14:37Z",
      "correlationBlocked": false
    }
  ],
  "pendingOrders": [
    {
      "symbol": "EURUSD",
      "ticket": 12345678,
      "type": "BUY_LIMIT",
      "price": 1.06750,
      "volume": 0.01,
      "expiry": "2025-10-03T00:00:00Z"
    }
  ],
  "correlation": {
    "evaluationTime": "2025-10-02T20:14:30Z",
    "capThreshold": 3,
    "blockedSymbols": ["GBPNZD"],
    "pairwiseScores": [
      { "symbolA": "EURUSD", "symbolB": "GBPUSD", "pearson": 0.68 }
    ]
  }
}
```
**Indexes and Constraints**
- File naming: `fairPriceMP_snapshot_YYYYMMDD_HHMMSS.json` (ASCII only).
- Write location: `%AppData%\MetaQuotes\Terminal\<GUID>\MQL5\Files\fairPriceMP\snapshots`.
- Max file size: rotate once snapshots exceed 50 MB to avoid tester slowdowns.