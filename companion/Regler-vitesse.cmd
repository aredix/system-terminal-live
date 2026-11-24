@echo off
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Regler-vitesse.ps1"
if errorlevel 1 pause
