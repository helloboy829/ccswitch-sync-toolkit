Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-WarnLine {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[ OK ] $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Get-ToolkitRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Get-ToolkitConfigPath {
    return (Join-Path (Get-ToolkitRoot) "config.json")
}

function Test-ToolkitInitialized {
    return (Test-Path (Get-ToolkitConfigPath))
}

function Get-ToolkitConfig {
    $path = Get-ToolkitConfigPath
    if (-not (Test-Path $path)) {
        throw "Toolkit is not initialized. Run Init-Setup.cmd first."
    }
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}

function Get-DefaultSourceCandidates {
    $candidates = @()
    if ($env:USERPROFILE) {
        $candidates += (Join-Path $env:USERPROFILE ".cc-switch")
    }
    if ($env:APPDATA) {
        $candidates += (Join-Path $env:APPDATA "com.ccswitch.desktop")
    }
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA "com.ccswitch.desktop")
    }
    return ($candidates | Select-Object -Unique)
}

function Test-ValidSourceRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }
    $db = Join-Path $Path "cc-switch.db"
    $settings = Join-Path $Path "settings.json"
    return ((Test-Path $Path) -and (Test-Path $db) -and (Test-Path $settings))
}

function Find-SourceRoot {
    param([string]$PreferredPath)
    if (Test-ValidSourceRoot -Path $PreferredPath) {
        return $PreferredPath
    }
    foreach ($candidate in (Get-DefaultSourceCandidates)) {
        if (Test-ValidSourceRoot -Path $candidate) {
            return $candidate
        }
    }
    return $null
}

function Save-ToolkitConfig {
    param([psobject]$Config)
    $path = Get-ToolkitConfigPath
    $json = $Config | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $path -Value $json -Encoding UTF8
}

function Get-WorkspaceRoot {
    $config = Get-ToolkitConfig
    return $config.workspaceRoot
}

function Get-RepoRoot {
    return (Join-Path (Get-WorkspaceRoot) "repo")
}

function Get-StagingRoot {
    return (Join-Path (Get-WorkspaceRoot) "staging")
}

function Get-RestoreRoot {
    return (Join-Path (Get-WorkspaceRoot) "restore")
}

function Get-BackupRoot {
    return (Join-Path (Get-WorkspaceRoot) "local-backups")
}

function Get-LatestBackupFolder {
    $backupRoot = Get-BackupRoot
    if (-not (Test-Path $backupRoot)) {
        throw "No local backup directory exists yet."
    }
    $latest = Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($null -eq $latest) {
        throw "No local backup snapshot is available."
    }
    return $latest.FullName
}

function Get-SourceRoot {
    $config = Get-ToolkitConfig
    $resolved = Find-SourceRoot -PreferredPath $config.sourceRoot
    if ($resolved) {
        return $resolved
    }
    return $config.sourceRoot
}

function Get-DatabasePath {
    return (Join-Path (Get-SourceRoot) "cc-switch.db")
}

function Get-SettingsPath {
    return (Join-Path (Get-SourceRoot) "settings.json")
}

function Get-MetadataPath {
    return (Join-Path (Get-RepoRoot) "metadata\manifest.json")
}

function Get-ArchivePath {
    return (Join-Path (Get-RepoRoot) "encrypted\ccswitch-backup.zip.enc")
}

function Get-ZipPath {
    return (Join-Path (Get-StagingRoot) "ccswitch-backup.zip")
}

function Get-OpenSslPath {
    $config = Get-ToolkitConfig
    return $config.opensslPath
}

function Ensure-Directories {
    $paths = @(
        (Get-WorkspaceRoot),
        (Get-RepoRoot),
        (Get-StagingRoot),
        (Get-RestoreRoot),
        (Get-BackupRoot),
        (Join-Path (Get-RepoRoot) "encrypted"),
        (Join-Path (Get-RepoRoot) "metadata")
    )
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
        }
    }
}

function Assert-CommandExists {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

function Assert-OpenSslExists {
    $openssl = Get-OpenSslPath
    if (-not (Test-Path $openssl)) {
        throw "OpenSSL not found at: $openssl"
    }
}

function Assert-SourceFilesExist {
    $db = Get-DatabasePath
    $settings = Get-SettingsPath
    if (-not (Test-Path $db)) {
        throw "Database file not found: $db"
    }
    if (-not (Test-Path $settings)) {
        throw "Settings file not found: $settings"
    }
}

function Test-CcSwitchRunning {
    $proc = Get-Process -Name "cc-switch" -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

function Assert-CcSwitchStopped {
    if (Test-CcSwitchRunning) {
        throw "cc-switch is currently running. Close it before backup or restore."
    }
}

function Get-SecretFromUser {
    param([string]$Prompt)
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Clear-Directory {
    param([string]$Path)
    if (Test-Path $Path) {
        Get-ChildItem -LiteralPath $Path -Force | Remove-Item -Recurse -Force
    } else {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function New-Timestamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

function New-ManifestObject {
    param(
        [string]$ArchiveHash,
        [string]$DbHash,
        [string]$SettingsHash,
        [string]$GitCommit
    )
    $config = Get-ToolkitConfig
    return [ordered]@{
        formatVersion = 1
        app = "ccswitch"
        generatedAt = (Get-Date).ToString("o")
        machineName = $env:COMPUTERNAME
        sourceRoot = $config.sourceRoot
        archiveFile = "encrypted/ccswitch-backup.zip.enc"
        archiveSha256 = $ArchiveHash
        databaseSha256 = $DbHash
        settingsSha256 = $SettingsHash
        gitCommit = $GitCommit
        notes = "Encrypted ccswitch configuration backup"
    }
}

function Save-Manifest {
    param([hashtable]$Manifest)
    $path = Get-MetadataPath
    $json = $Manifest | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $path -Value $json -Encoding UTF8
}

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    Assert-CommandExists "git"
    $repo = Get-RepoRoot
    & git @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Args -join ' ')"
    }
}

function Compress-SourceFiles {
    $staging = Get-StagingRoot
    Clear-Directory -Path $staging
    $payloadRoot = Join-Path $staging "payload"
    New-Item -ItemType Directory -Force -Path $payloadRoot | Out-Null

    Copy-Item -LiteralPath (Get-DatabasePath) -Destination (Join-Path $payloadRoot "cc-switch.db")
    Copy-Item -LiteralPath (Get-SettingsPath) -Destination (Join-Path $payloadRoot "settings.json")

    $zipPath = Get-ZipPath
    if (Test-Path $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -Path (Join-Path $payloadRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal
    return $zipPath
}

function Encrypt-ZipWithOpenSsl {
    param([string]$Password)
    Assert-OpenSslExists
    $zipPath = Get-ZipPath
    $archivePath = Get-ArchivePath
    if (Test-Path $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
    $openssl = Get-OpenSslPath
    & $openssl enc -aes-256-cbc -pbkdf2 -salt -in $zipPath -out $archivePath -pass "pass:$Password"
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL encryption failed."
    }
    return $archivePath
}

function Decrypt-ArchiveWithOpenSsl {
    param([string]$Password)
    Assert-OpenSslExists
    $archivePath = Get-ArchivePath
    if (-not (Test-Path $archivePath)) {
        throw "Encrypted archive not found: $archivePath"
    }
    $zipPath = Get-ZipPath
    if (Test-Path $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    $openssl = Get-OpenSslPath
    & $openssl enc -d -aes-256-cbc -pbkdf2 -in $archivePath -out $zipPath -pass "pass:$Password"
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL decryption failed. The password may be incorrect."
    }
    return $zipPath
}

function Expand-BackupZip {
    $restore = Get-RestoreRoot
    Clear-Directory -Path $restore
    Expand-Archive -LiteralPath (Get-ZipPath) -DestinationPath $restore -Force
    return $restore
}

function Backup-CurrentLocalState {
    $backupRoot = Get-BackupRoot
    if (-not (Test-Path $backupRoot)) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    }
    $stamp = New-Timestamp
    $folder = Join-Path $backupRoot $stamp
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    Copy-Item -LiteralPath (Get-DatabasePath) -Destination (Join-Path $folder "cc-switch.db")
    Copy-Item -LiteralPath (Get-SettingsPath) -Destination (Join-Path $folder "settings.json")
    return $folder
}

function Restore-BackupToSource {
    $restore = Get-RestoreRoot
    $db = Join-Path $restore "cc-switch.db"
    $settings = Join-Path $restore "settings.json"
    if (-not (Test-Path $db)) {
        throw "Restored database file missing: $db"
    }
    if (-not (Test-Path $settings)) {
        throw "Restored settings file missing: $settings"
    }
    Copy-Item -LiteralPath $db -Destination (Get-DatabasePath) -Force
    Copy-Item -LiteralPath $settings -Destination (Get-SettingsPath) -Force
}

function Restore-LocalBackupFolder {
    param([string]$Folder)
    $db = Join-Path $Folder "cc-switch.db"
    $settings = Join-Path $Folder "settings.json"
    if (-not (Test-Path $db)) {
        throw "Backup database file missing: $db"
    }
    if (-not (Test-Path $settings)) {
        throw "Backup settings file missing: $settings"
    }
    Copy-Item -LiteralPath $db -Destination (Get-DatabasePath) -Force
    Copy-Item -LiteralPath $settings -Destination (Get-SettingsPath) -Force
}

function Get-GitCommitOrPlaceholder {
    try {
        $output = & git rev-parse HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return ($output | Select-Object -First 1)
        }
    } catch {
    }
    return "uncommitted"
}
