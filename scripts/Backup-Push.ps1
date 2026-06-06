Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    Write-Info "Starting encrypted backup and Git push"
    Write-WarnLine "This action uses LOCAL data as the source of truth."
    Write-WarnLine "It will publish your current local ccswitch config to GitHub and replace the remote backup snapshot."
    Ensure-Directories
    Assert-SourceFilesExist
    Assert-CcSwitchStopped

    $confirm = Read-Host "Type YES to continue"
    if ($confirm -ne "YES") {
        throw "Operation cancelled by user."
    }

    $password = Get-SecretFromUser -Prompt "Enter sync encryption password"
    if ([string]::IsNullOrWhiteSpace($password)) {
        throw "Encryption password cannot be empty."
    }

    $zipPath = Compress-SourceFiles
    $archivePath = Encrypt-ZipWithOpenSsl -Password $password

    $dbHash = Get-FileSha256 -Path (Get-DatabasePath)
    $settingsHash = Get-FileSha256 -Path (Get-SettingsPath)
    $archiveHash = Get-FileSha256 -Path $archivePath

    $repoRoot = Get-RepoRoot
    Push-Location $repoRoot
    try {
        Invoke-Git pull --rebase origin (Get-ToolkitConfig).branch
        $manifest = New-ManifestObject -ArchiveHash $archiveHash -DbHash $dbHash -SettingsHash $settingsHash -GitCommit (Get-GitCommitOrPlaceholder)
        Save-Manifest -Manifest $manifest
        Invoke-Git add encrypted/ccswitch-backup.zip.enc metadata/manifest.json .gitignore README.md
        & git diff --cached --quiet
        $hasChanges = ($LASTEXITCODE -ne 0)
        if ($hasChanges) {
            $message = "ccswitch backup $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            Invoke-Git commit -m $message
            Invoke-Git push origin (Get-ToolkitConfig).branch
            Write-Ok "Backup encrypted and pushed"
        } else {
            Write-WarnLine "No changes detected after backup. Nothing pushed."
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
