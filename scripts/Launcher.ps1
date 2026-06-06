Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

function Invoke-ToolkitScript {
    param([string]$ScriptName)
    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path $scriptPath)) {
        throw "Script not found: $scriptPath"
    }
    & $scriptPath
}

try {
    Clear-Host
    Write-Host "CCSwitch Sync Toolkit" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Initialize Toolkit"
    Write-Host "2. Backup-Push (Use Local As Source)"
    Write-Host "3. Pull-Restore (Use Remote As Source)"
    Write-Host "4. Rollback Previous Local Backup"
    Write-Host "5. Show Status"
    Write-Host "0. Exit"
    Write-Host ""

    $choice = Read-Host "Choose an action"

    switch ($choice) {
        "1" { Invoke-ToolkitScript -ScriptName "Init-Setup.ps1" }
        "2" { Invoke-ToolkitScript -ScriptName "Backup-Push.ps1" }
        "3" { Invoke-ToolkitScript -ScriptName "Pull-Restore.ps1" }
        "4" { Invoke-ToolkitScript -ScriptName "Rollback-LastLocalBackup.ps1" }
        "5" { Invoke-ToolkitScript -ScriptName "Status.ps1" }
        "0" { exit 0 }
        default { throw "Invalid selection: $choice" }
    }
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
