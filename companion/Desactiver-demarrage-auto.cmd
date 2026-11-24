@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Installer-demarrage.ps1" -Desinstaller
if errorlevel 1 pause
