# Deployment Architecture
**Frontend Deployment**
- Platform: MT5 terminal (Windows VPS)
- Build Command: `metaeditor64.exe /compile:src\MT5\Experts\fairPriceMP\CoreOrchestrator.mq5`
- Output Directory: `%MT5_DATA_PATH%\MQL5\Experts\fairPriceMP\CoreOrchestrator.ex5`
- CDN or Edge: N/A

**Backend Deployment**
- Platform: same MT5 terminal
- Build Command: same compile step (single artefact)
- Deployment Method: `scripts\MT5_File_Sync.ps1` copies `src\MT5\Experts`, `Include`, and `Files` into terminal folders (ASCII filenames only)

**CI or CD Pipeline (optional skeleton)**
```yaml
name: build-fairPriceMP
on: [push]
jobs:
  compile:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install MetaEditor
        run: choco install metatrader5 --no-progress
      - name: Compile EA
        run: metaeditor64.exe /compile:src\MT5\Experts\fairPriceMP\CoreOrchestrator.mq5 /log:build.log
      - name: Archive Artefacts
        uses: actions/upload-artifact@v3
        with:
          name: fairPriceMP-ex5
          path: |
            src\MT5\Experts\fairPriceMP\CoreOrchestrator.ex5
            build.log
```

**Environments**

| Environment | Frontend URL | Backend URL | Purpose |
|-------------|--------------|-------------|---------|
| Development | N/A          | N/A         | Local development and tester runs |
| Staging     | N/A          | N/A         | Optional secondary VPS clone for soak tests |
| Production  | N/A          | N/A         | Live VPS terminal trading |
### Maintenance & Rollback Runbook
- **Cadence:** Apply OS and MT5 terminal updates on the first Sunday of each month, or sooner if a security bulletin is issued.
- **Ownership:** Trading operations lead (or delegate) coordinates the window, with the developer on-call to validate EA health.

**Pre-maintenance Checklist**
1. Schedule a 2-hour maintenance window outside active trading sessions and notify stakeholders.
2. Stop live trading and export the latest snapshots/logs to off-box storage (%FAIRPRICE_SNAPSHOT_DIR% and %FAIRPRICE_LOG_DIR%).
3. Clone the VPS (cloud snapshot or Hyper-V checkpoint) and copy the current CoreOrchestrator.ex5, configuration files, and PowerShell sync scripts.
4. Confirm strategy tester baseline run passes on the backup build so rollback artefacts are trusted.

**Patch & Verification Steps**
1. Apply Windows updates, reboot, and confirm system time/locale remain unchanged.
2. Launch MT5 and allow terminal updates; decline optional beta builds.
3. Recompile the EA (metaeditor64.exe /compile:src\MT5\Experts\fairPriceMP\CoreOrchestrator.mq5) and run a smoke backtest.
4. Execute the sync script to ensure the updated EX5, Include files, and persistence folders are in sync.
5. Start live terminal, enable the EA on the sandbox account, and monitor logs for 15 minutes (tick processing, correlation, snapshots).

**Rollback Plan**
1. If validation fails, disable trading immediately and restore the VPS snapshot taken before maintenance.
2. Reapply the backed-up EX5 and configuration via the sync script, then verify the EA loads without warnings.
3. Review structured logs to confirm correlation service and snapshot writer resume cleanly.
4. Document the incident, root cause, and follow-up actions before scheduling a new maintenance window.

