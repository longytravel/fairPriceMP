# MT5 Enhanced File Auto-Sync Guide

## Overview
The MT5 Enhanced File Auto-Sync system automatically monitors your development folder and syncs ALL file changes to your MT5 terminal in real-time.

## Features
✅ **Monitors ALL file types** - .mq5, .mqh, .csv, .json, .txt, .log, everything!
✅ **Syncs all folders** - Experts, Include, Scripts, Files, Indicators, Libraries
✅ **One-way sync** - Dev folder → MT5 (you control the source)
✅ **Auto-backup** - Creates timestamped backups before overwriting
✅ **Desktop notifications** - Popup alerts when files sync
✅ **Smart retry logic** - Handles file locks and MetaEditor conflicts
✅ **Compile reminders** - Visual reminder to hit F7 for .mq5/.mqh files
✅ **Initial bulk sync** - Syncs all existing files on startup

---

## Quick Start

### 1. Start the Sync (Easiest Method)
Double-click: `Start_Enhanced_Sync.bat`

That's it! The sync is now running.

### 2. What Happens
- Initial sync runs immediately (all files copied to MT5)
- File watcher starts monitoring for changes
- Any file you save in dev folder → instantly copies to MT5
- Desktop notification appears
- Console shows what was synced

### 3. Stop the Sync
Press `Ctrl+C` in the PowerShell window

---

## How It Works

### File Flow
```
Your Dev Folder (fairPriceMP/)
    │
    ├── Experts/fairPriceMP/SymbolEngine.mqh
    ├── Include/fairPriceMP/DTO/
    ├── Scripts/Test_*.mq5
    └── Files/config.csv
            │
            │ (Auto-sync on save)
            ↓
MT5 Terminal (MQL5/)
    │
    ├── Experts/fairPriceMP/SymbolEngine.mqh  ✅ Synced
    ├── Include/fairPriceMP/DTO/              ✅ Synced
    ├── Scripts/Test_*.mq5                    ✅ Synced
    └── Files/config.csv                      ✅ Synced
```

### Backup System
Before overwriting any file in MT5, a backup is created:
```
Backups/
  ├── SymbolEngine_20251003_193045.mqh
  ├── TradeProxy_20251003_193112.mqh
  └── config_20251003_193210.csv
```

Backups are timestamped: `filename_YYYYMMDD_HHMMSS.ext`

---

## Monitored Folders

The sync watches these folders in your dev directory:

| Folder | Purpose | Synced |
|--------|---------|--------|
| `Experts/` | Expert Advisors (.mq5) | ✅ Yes |
| `Include/` | Include files (.mqh) | ✅ Yes |
| `Scripts/` | Test scripts | ✅ Yes |
| `Files/` | Config/data files | ✅ Yes |
| `Indicators/` | Custom indicators | ✅ Yes |
| `Libraries/` | MQL5 libraries | ✅ Yes |

**Everything inside these folders syncs automatically!**

---

## Monitored File Types

The enhanced sync monitors **ALL file types** by default:

### Source Code
- `.mq5` - MQL5 Expert Advisors
- `.mqh` - MQL5 Include files
- `.ex5` - Compiled executables

### Data & Config
- `.csv` - CSV data files
- `.json` - JSON configuration
- `.txt` - Text files
- `.log` - Log files

### And More
- **Literally any file type** - The sync uses `*.*` to catch everything

---

## Important Workflow

### For .mq5 and .mqh Files (Source Code)

1. **Edit file** in your dev folder (VS Code, Notepad++, etc.)
2. **Save file** (Ctrl+S)
3. **See sync notification** → "Synced: Experts/fairPriceMP/SymbolEngine.mqh"
4. **Open MetaEditor** in MT5
5. **Navigate to the file**
6. **Press F7** to compile

⚠️ **IMPORTANT**: The sync does NOT auto-compile. You must manually press F7 in MetaEditor.

### For Data Files (.csv, .json, .txt)

1. **Edit file** in your dev folder
2. **Save file**
3. **Done!** File is instantly available in MT5

No compilation needed for data files.

---

## Console Output Examples

### Successful Sync
```
[2025-10-03 19:35:12] ✅ Synced [MQL5 Source]: Experts/fairPriceMP/SymbolEngine.mqh
                      💡 Remember to RECOMPILE (F7) in MetaEditor
```

### With Backup
```
[2025-10-03 19:35:12] 💾 Backup: SymbolEngine_20251003_193512.mqh
[2025-10-03 19:35:12] ✅ Synced [MQL5 Source]: Experts/fairPriceMP/SymbolEngine.mqh
```

### File Locked (Retry)
```
[2025-10-03 19:35:12] 🔄 Retrying (1/3)...
[2025-10-03 19:35:13] ✅ Synced [MQL5 Source]: Experts/fairPriceMP/SymbolEngine.mqh
```

### Initial Sync
```
🚀 Performing initial sync...

  ✅ [MQL5 Source] Experts/fairPriceMP/SymbolEngine.mqh
  ✅ [MQL5 Include] Include/fairPriceMP/DTO/SymbolRuntimeState.mqh
  ✅ [CSV Data] Files/fairPriceMP/config.csv
  ✅ [MQL5 Source] Scripts/Test_SymbolEngine_Risk.mq5

✨ Initial sync complete! Synced 47 files
```

---

## Configuration

### Config File Location
`sync-config.json`

### Customizable Settings

```json
{
  "settings": {
    "syncMode": "one-way",           // one-way or bidirectional
    "autoCompile": false,            // Auto F7 (requires MetaEditor CLI)
    "autoCommit": false,             // Auto git commit
    "createBackups": true            // Backup before overwrite
  },
  "folders": [
    "Experts",
    "Include",
    "Scripts",
    "Files",
    "Indicators",
    "Libraries"
  ],
  "notifications": {
    "enabled": true,
    "showFileType": true,
    "compileReminder": true
  }
}
```

### How to Modify

1. Open `sync-config.json` in any text editor
2. Change values as needed
3. Restart the sync script for changes to take effect

**Current Setup (Your Preferences):**
- ✅ One-way sync (Dev → MT5)
- ✅ Manual compile (you press F7)
- ✅ Manual git commits
- ✅ All file types monitored
- ✅ All folders synced

---

## Troubleshooting

### Issue: File not syncing

**Cause**: File is outside monitored folders
**Fix**: Ensure file is in Experts/, Include/, Scripts/, Files/, Indicators/, or Libraries/

**Cause**: Sync script not running
**Fix**: Run `Start_Enhanced_Sync.bat`

### Issue: File is locked error

**Cause**: MetaEditor has the file open
**Fix**: Close file in MetaEditor, save again in dev folder. Sync will retry automatically.

### Issue: Compile fails after sync

**Cause**: Include paths changed
**Fix**: Check #include statements in your .mq5 files

### Issue: No desktop notification

**Cause**: Windows notification settings
**Fix**: Check Windows notification permissions for PowerShell

### Issue: Want to stop sync temporarily

**Fix**: Press `Ctrl+C` in the PowerShell window

---

## Best Practices

### ✅ DO
- Keep sync running while developing
- Save files in dev folder (fairPriceMP/)
- Press F7 in MetaEditor after syncing source files
- Check console for sync confirmations
- Use backups if you need to restore

### ❌ DON'T
- Don't edit files directly in MT5 terminal folders
- Don't manually copy files (let sync handle it)
- Don't close MetaEditor while files are compiling
- Don't delete backup folder (it's your safety net)

---

## Advanced Usage

### Run Sync on Windows Startup

1. Press `Win+R`
2. Type: `shell:startup`
3. Create shortcut to `Start_Enhanced_Sync.bat`
4. Sync starts automatically when you login

### View Sync Logs

All sync activity appears in the PowerShell console in real-time.

### Restore from Backup

1. Go to `Backups/` folder
2. Find the backup file with timestamp
3. Copy to MT5 terminal folder
4. Recompile if needed

---

## Comparison: Old vs Enhanced Sync

| Feature | Old Sync | Enhanced Sync |
|---------|----------|---------------|
| File types | .mq5 only | ALL files (*.*) |
| Folders | Manual config | All MQL5 folders |
| Initial sync | No | Yes (on startup) |
| File type display | No | Yes (shows type) |
| Notifications | Basic | Enhanced with type |
| Retry logic | Basic | Smart with delays |
| Backup system | Yes | Yes (improved) |
| Console UI | Plain text | Emoji & colors |

---

## Support & Feedback

### Getting Help
- Check this guide first
- Review console error messages
- Check Windows Event Viewer for PowerShell errors

### Reporting Issues
- Note the exact error message
- Check which file was syncing
- Check if file exists in both locations
- Try manual copy to diagnose

---

## Summary

**The MT5 Enhanced Sync makes development seamless:**

1. **Start sync once**: Double-click `Start_Enhanced_Sync.bat`
2. **Edit files** in your dev folder
3. **Save** (Ctrl+S)
4. **Files auto-sync** to MT5 instantly
5. **Compile** (F7) if it's source code
6. **Done!**

No more manual copying. No more outdated files. Everything stays in perfect sync! 🚀
