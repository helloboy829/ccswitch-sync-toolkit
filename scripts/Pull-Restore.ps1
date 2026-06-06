Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    Write-Info "Pulling encrypted backup from Git and restoring locally"
    Write-WarnLine "This action uses REMOTE data as the source of truth."
    Write-WarnLine "It will replace your current local ccswitch config with the remote backup snapshot."
    Ensure-Directories -IncludeRepo
    Assert-WorkspaceRepoMatchesConfig
    Assert-CcSwitchStopped

    $confirm = Read-Host "Type YES to continue"
    if ($confirm -ne "YES") {
        throw "Operation cancelled by user."
    }

    $repoRoot = Get-RepoRoot
    Push-Location $repoRoot
    try {
        Invoke-Git pull --rebase origin (Get-ToolkitConfig).branch
    } finally {
        Pop-Location
    }

    $password = Get-SecretFromUser -Prompt "Enter sync encryption password"
    if ([string]::IsNullOrWhiteSpace($password)) {
        throw "Encryption password cannot be empty."
    }

    $backupFolder = Backup-CurrentLocalState
    Write-Info "Current local files backed up to $backupFolder"

    Decrypt-ArchiveWithOpenSsl -Password $password | Out-Null
    Expand-BackupZip | Out-Null
    Restore-BackupToSource

    Write-Ok "Backup restored to local ccswitch directory"
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
