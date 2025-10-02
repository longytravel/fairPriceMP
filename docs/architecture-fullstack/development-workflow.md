# Development Workflow

### Local Development Setup
**Prerequisites**
```bash
# Install Git for Windows
choco install git

# Install MetaTrader 5 terminal (broker distribution)
# Ensure MetaEditor or mql.exe accessible via PATH or known location

# Optional: install VS Code plus MQL5 syntax extension for editing
```

**Initial Setup**
```bash
# Clone repo
git clone https://<repo>/fairPriceMP.git
cd fairPriceMP

# Configure MT5 data path (replace GUID with your terminal ID)
setx MT5_DATA_PATH "%APPDATA%\MetaQuotes\Terminal\<GUID>"

# Optional: set up PowerShell execution policy for sync scripts
powershell -ExecutionPolicy Bypass -File .\scripts\Start_MT5_Sync.bat
```

**Development Commands**
```bash
# Compile EA from MetaEditor or command line
"C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:src\MT5\Experts\fairPriceMP\CoreOrchestrator.mq5

# Run unit harness (if added)
powershell -File scripts\Run_Local_Tests.ps1

# Launch MT5 tester with latest EX5
"C:\Program Files\MetaTrader 5\terminal64.exe" /portable
```

### Environment Configuration
```bash
MT5_DATA_PATH=%APPDATA%\MetaQuotes\Terminal\<GUID>
FAIRPRICE_SNAPSHOT_DIR=%MT5_DATA_PATH%\MQL5\Files\fairPriceMP\snapshots
FAIRPRICE_LOG_DIR=%MT5_DATA_PATH%\MQL5\Files\fairPriceMP\logs
```