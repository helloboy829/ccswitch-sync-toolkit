@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Rollback-LastLocalBackup.ps1"
pause
