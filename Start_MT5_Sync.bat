@echo off
echo Starting MT5 File Auto-Sync...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0MT5_File_Sync.ps1"
pause
