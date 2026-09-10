@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-HUNCH-Pack.ps1" -WithShotSignal
if errorlevel 1 pause
