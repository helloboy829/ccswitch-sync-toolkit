Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    Write-Info "Restoring the most recent local backup snapshot"
    Ensure-Directories
    Assert-CcSwitchStopped
    Assert-SourceFilesExist

    $currentSnapshot = Backup-CurrentLocalState
    Write-Info "Current local files backed up to $currentSnapshot"

    $latest = Get-LatestBackupFolder
    if ($latest -eq $currentSnapshot) {
        $candidates = Get-ChildItem -LiteralPath (Get-BackupRoot) -Directory | Sort-Object Name -Descending
        $latest = ($candidates | Where-Object { $_.FullName -ne $currentSnapshot } | Select-Object -First 1).FullName
    }
    if ([string]::IsNullOrWhiteSpace($latest)) {
        throw "No previous local backup snapshot is available for rollback."
    }

    Restore-LocalBackupFolder -Folder $latest
    Write-Ok "Rolled back local ccswitch files from $latest"
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
