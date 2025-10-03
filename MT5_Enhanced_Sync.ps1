# MT5 Enhanced File Auto-Sync Script
# Monitors ALL file types and syncs everything to MT5 terminal

#Requires -Version 5.1

# Configuration
$sourceFolder = "C:\Users\User\Desktop\fairPriceMP"
$destinationFolder = "C:\Users\User\AppData\Roaming\MetaQuotes\Terminal\010E047102812FC0C18890992854220E\MQL5"
$backupFolder = "C:\Users\User\Desktop\fairPriceMP\Backups"

# Folders to sync (relative paths from source)
$foldersToSync = @(
    "Experts",
    "Include",
    "Scripts",
    "Files",
    "Indicators",
    "Libraries"
)

# File types to monitor (ALL files - use * for everything)
$fileTypes = @("*")  # Monitor ALL file types

# Create backup folder if it doesn't exist
if (-not (Test-Path -Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Helper function to check if file is in sync scope
function Test-FileInScope {
    param([string]$FilePath)

    $relativePath = $FilePath.Substring($sourceFolder.Length).TrimStart('\')

    foreach ($folder in $foldersToSync) {
        if ($relativePath.StartsWith($folder, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

# Helper function to get file extension description
function Get-FileTypeDescription {
    param([string]$Extension)

    $descriptions = @{
        ".mq5" = "MQL5 Source"
        ".mqh" = "MQL5 Include"
        ".ex5" = "MQL5 Compiled"
        ".csv" = "CSV Data"
        ".json" = "JSON Config"
        ".txt" = "Text File"
        ".log" = "Log File"
    }

    if ($descriptions.ContainsKey($Extension)) {
        return $descriptions[$Extension]
    }
    return "File"
}

# Sync action for file changes
$syncAction = {
    param($SourcePath)

    $path = $SourcePath
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Check if file is in scope
    if (-not (Test-FileInScope -FilePath $path)) {
        return
    }

    # Get relative path and file info
    $relativePath = $path.Substring($sourceFolder.Length).TrimStart('\')
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $relativePath
    $fileExt = [System.IO.Path]::GetExtension($path)
    $fileType = Get-FileTypeDescription -Extension $fileExt

    # Create destination directory if needed
    $destinationDir = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    # Wait for file to be fully written
    Start-Sleep -Milliseconds 500

    # Check if source file is accessible
    $maxRetries = 5
    $retryCount = 0
    $fileReady = $false

    while (-not $fileReady -and $retryCount -lt $maxRetries) {
        try {
            $stream = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
            $stream.Close()
            $fileReady = $true
        }
        catch {
            $retryCount++
            Start-Sleep -Milliseconds 300
        }
    }

    if (-not $fileReady) {
        Write-Host "[$timestamp] WARNING: File locked, skipping: '$relativePath'" -ForegroundColor Yellow
        return
    }

    try {
        # Backup existing file
        if (Test-Path -Path $destinationPath) {
            $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($destinationPath)
            $fileExtension = [System.IO.Path]::GetExtension($destinationPath)
            $backupFileName = "${fileName}_${backupTimestamp}${fileExtension}"
            $backupPath = Join-Path -Path $backupFolder -ChildPath $backupFileName

            Copy-Item -Path $destinationPath -Destination $backupPath -Force
            Write-Host "[$timestamp] BACKUP: $backupFileName" -ForegroundColor Cyan
        }

        # Copy with retry logic
        $copySuccess = $false
        $copyRetries = 0
        $maxCopyRetries = 3

        while (-not $copySuccess -and $copyRetries -lt $maxCopyRetries) {
            try {
                Copy-Item -Path $path -Destination $destinationPath -Force -ErrorAction Stop
                $copySuccess = $true
            }
            catch {
                $copyRetries++
                if ($copyRetries -lt $maxCopyRetries) {
                    Write-Host "[$timestamp] RETRY: Attempt $copyRetries of $maxCopyRetries..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
                else {
                    throw
                }
            }
        }

        # Success message with file type
        Write-Host "[$timestamp] SYNCED [$fileType]: $relativePath" -ForegroundColor Green

        # Special reminder for source files
        if ($fileExt -eq ".mq5" -or $fileExt -eq ".mqh") {
            Write-Host "                REMINDER: Press F7 in MetaEditor to compile" -ForegroundColor Yellow
        }

        # Desktop notification
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $notification = New-Object System.Windows.Forms.NotifyIcon
            $notification.Icon = [System.Drawing.SystemIcons]::Information
            $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $notification.BalloonTipText = "Synced: $relativePath"
            $notification.BalloonTipTitle = "MT5 File Updated"
            $notification.Visible = $true
            $notification.ShowBalloonTip(3000)
            Start-Sleep -Seconds 1
            $notification.Dispose()
        }
        catch {
            # Silently ignore notification errors
        }
    }
    catch {
        Write-Host "[$timestamp] ERROR: Failed to sync '$relativePath'" -ForegroundColor Red
        Write-Host "                $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create file system watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourceFolder
$watcher.Filter = "*.*"  # Watch ALL files
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite

# Event handler wrapper
$eventAction = {
    $path = $Event.SourceEventArgs.FullPath
    & $syncAction -SourcePath $path
}

# Register event handlers
$created = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $eventAction
$changed = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $eventAction

# Display startup banner
Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "     MT5 ENHANCED FILE AUTO-SYNC - FULL SYNC MODE              " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source:      $sourceFolder" -ForegroundColor Yellow
Write-Host "Destination: $destinationFolder" -ForegroundColor Yellow
Write-Host "Backups:     $backupFolder" -ForegroundColor Yellow
Write-Host ""
Write-Host "Syncing Folders:" -ForegroundColor Green
foreach ($folder in $foldersToSync) {
    Write-Host "   * $folder" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Monitoring: ALL file types (*.*)" -ForegroundColor Green
Write-Host "Mode: One-way sync (Dev -> MT5)" -ForegroundColor Green
Write-Host "Auto-backup: Enabled" -ForegroundColor Green
Write-Host "Manual compile: You control F7" -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Perform initial sync
Write-Host "Performing initial sync..." -ForegroundColor Cyan
Write-Host ""

$syncCount = 0
foreach ($folder in $foldersToSync) {
    $sourcePath = Join-Path -Path $sourceFolder -ChildPath $folder

    if (Test-Path -Path $sourcePath) {
        Get-ChildItem -Path $sourcePath -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceFolder.Length).TrimStart('\')
            $destinationPath = Join-Path -Path $destinationFolder -ChildPath $relativePath

            $destinationDir = Split-Path -Path $destinationPath -Parent
            if (-not (Test-Path -Path $destinationDir)) {
                New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }

            Copy-Item -Path $_.FullName -Destination $destinationPath -Force -ErrorAction SilentlyContinue

            $fileType = Get-FileTypeDescription -Extension $_.Extension
            Write-Host "  SYNCED [$fileType] $relativePath" -ForegroundColor Green
            $syncCount++
        }
    }
}

Write-Host ""
Write-Host "Initial sync complete! Synced $syncCount files" -ForegroundColor Green
Write-Host ""
Write-Host "Watching for changes... (Press Ctrl+C to stop)" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Keep script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Cleanup
    Write-Host ""
    Write-Host "Stopping file sync..." -ForegroundColor Yellow
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Unregister-Event -SourceIdentifier $created.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $changed.Name -ErrorAction SilentlyContinue
    Write-Host "File sync stopped successfully" -ForegroundColor Green
}
