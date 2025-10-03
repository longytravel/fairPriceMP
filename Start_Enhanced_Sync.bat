@echo off
title MT5 Enhanced File Auto-Sync
color 0B
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     Starting MT5 Enhanced File Auto-Sync...               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Press Ctrl+C to stop the sync at any time.
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0MT5_Enhanced_Sync.ps1"
pause
