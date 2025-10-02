# MT5 File Auto-Sync Script
# This script monitors a source folder and automatically copies .mq5 files to your MT5 terminal

# Configuration
$sourceFolder = "C:\Users\User\Desktop\fairPriceMP"
$destinationFolder = "C:\Users\User\AppData\Roaming\MetaQuotes\Terminal\010E047102812FC0C18890992854220E\MQL5"
$backupFolder = "C:\Users\User\Desktop\fairPriceMP\Backups"

# Create backup folder if it doesn't exist
if (-not (Test-Path -Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Create a FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourceFolder
$watcher.Filter = "*.mq5"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define what to do when a file is created or changed
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Get the relative path from source folder
    $relativePath = $path.Substring($sourceFolder.Length).TrimStart('\')
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $relativePath
    
    # Create destination directory if it doesn't exist
    $destinationDir = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    
    # Wait longer to ensure file is fully written and not locked
    Start-Sleep -Milliseconds 1000
    
    # Check if source file is accessible (not locked)
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
            Start-Sleep -Milliseconds 500
        }
    }
    
    if (-not $fileReady) {
        Write-Host "[$timestamp] WARNING: File is locked, skipping: '$relativePath'" -ForegroundColor Yellow
        return
    }
    
    try {
        # Create backup if destination file already exists
        if (Test-Path -Path $destinationPath) {
            $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($destinationPath)
            $fileExt = [System.IO.Path]::GetExtension($destinationPath)
            $backupFileName = "${fileName}_backup_${backupTimestamp}${fileExt}"
            $backupPath = Join-Path -Path $backupFolder -ChildPath $backupFileName
            
            Copy-Item -Path $destinationPath -Destination $backupPath -Force
            Write-Host "[$timestamp] BACKUP: Created backup '$backupFileName'" -ForegroundColor Cyan
        }
        
        # Copy the file with retry logic for locked destination files
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
                    Write-Host "[$timestamp] File locked in MT5, retrying ($copyRetries/$maxCopyRetries)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
                else {
                    throw
                }
            }
        }
        
        Write-Host "[$timestamp] ${changeType}: Copied '$relativePath' to MT5 terminal" -ForegroundColor Green
        Write-Host "                ** REMEMBER TO RECOMPILE (F7) IN METAEDITOR **" -ForegroundColor Yellow -BackgroundColor DarkRed
        
        # Try to show a Windows notification
        Add-Type -AssemblyName System.Windows.Forms
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Information
        $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $notification.BalloonTipText = "File synced: $relativePath`nRemember to RECOMPILE (F7)!"
        $notification.BalloonTipTitle = "MT5 File Updated"
        $notification.Visible = $true
        $notification.ShowBalloonTip(5000)
        
        Start-Sleep -Seconds 1
        $notification.Dispose()
    }
    catch {
        Write-Host "[$timestamp] ERROR: Failed to copy '$relativePath' - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "                TIP: Close the file in MetaEditor and try saving the source file again" -ForegroundColor Yellow
    }
}

# Register event handlers
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action | Out-Null

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "MT5 File Auto-Sync Started (SAFE MODE)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Source:      $sourceFolder" -ForegroundColor Yellow
Write-Host "Destination: $destinationFolder" -ForegroundColor Yellow
Write-Host "Backups:     $backupFolder" -ForegroundColor Yellow
Write-Host ""
Write-Host "SAFETY FEATURES ENABLED:" -ForegroundColor Green
Write-Host "  ✓ Automatic backups before overwriting" -ForegroundColor Gray
Write-Host "  ✓ File lock detection and retry logic" -ForegroundColor Gray
Write-Host "  ✓ Desktop notifications on file sync" -ForegroundColor Gray
Write-Host "  ✓ Visual reminders to recompile" -ForegroundColor Gray
Write-Host ""
Write-Host "Monitoring for .mq5 files..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Initial sync - copy all existing files
Write-Host "Performing initial sync..." -ForegroundColor Cyan
Get-ChildItem -Path $sourceFolder -Filter "*.mq5" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceFolder.Length).TrimStart('\')
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $relativePath
    
    $destinationDir = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    
    Copy-Item -Path $_.FullName -Destination $destinationPath -Force
    Write-Host "  Synced: $relativePath" -ForegroundColor Green
}
Write-Host "Initial sync complete!" -ForegroundColor Green
Write-Host ""

# Keep the script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Cleanup
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Get-EventSubscriber | Unregister-Event
    Write-Host "`nFile sync stopped." -ForegroundColor Yellow
}