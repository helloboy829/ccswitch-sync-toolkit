Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    if (-not (Test-ToolkitInitialized)) {
        throw "Toolkit is not initialized. Run Init-Setup.cmd first."
    }

    Write-Info "Toolkit status"
    Write-Host "Toolkit root : $(Get-ToolkitRoot)"
    Write-Host "Config file  : $(Get-ToolkitConfigPath)"
    Write-Host "Source root  : $(Get-SourceRoot)"
    Write-Host "Repo root    : $(Get-RepoRoot)"
    Write-Host "OpenSSL path : $(Get-OpenSslPath)"
    Write-Host "cc-switch up : $(if (Test-CcSwitchRunning) { 'YES' } else { 'NO' })"

    if (Test-Path (Get-MetadataPath)) {
        Write-Host "Manifest     : present"
        $manifest = Get-Content -LiteralPath (Get-MetadataPath) -Raw | ConvertFrom-Json
        Write-Host "Last backup  : $($manifest.generatedAt)"
        Write-Host "Archive hash : $($manifest.archiveSha256)"
    } else {
        Write-Host "Manifest     : missing"
    }

    Push-Location (Get-RepoRoot)
    try {
        $status = & git status --short --branch
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host $status
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
