Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    Write-Info "Initializing ccswitch sync toolkit"
    Assert-CommandExists "git"

    $toolkitRoot = Get-ToolkitRoot
    $defaultWorkspace = Join-Path $toolkitRoot "workspace"
    $defaultSyncRepoRoot = Join-Path (Split-Path -Parent $toolkitRoot) "ccswitch-sync"
    $autoDetectedSource = Find-SourceRoot -PreferredPath (Join-Path $env:USERPROFILE ".cc-switch")
    if ([string]::IsNullOrWhiteSpace($autoDetectedSource)) {
        $defaultSource = Join-Path $env:USERPROFILE ".cc-switch"
    } else {
        $defaultSource = $autoDetectedSource
    }
    $defaultRepoUrl = "https://github.com/helloboy829/ccswitch-sync.git"

    $opensslCandidates = @(
        "D:\software\conda\Library\bin\openssl.exe",
        "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
        "C:\Program Files\Git\usr\bin\openssl.exe"
    )
    $detectedOpenSsl = $null
    foreach ($candidate in $opensslCandidates) {
        if (Test-Path $candidate) {
            $detectedOpenSsl = $candidate
            break
        }
    }
    if (-not $detectedOpenSsl) {
        throw "OpenSSL executable was not found automatically. Install OpenSSL first or edit Init-Setup.ps1."
    }

    $repoUrlInput = Read-Host "GitHub private repo URL [$defaultRepoUrl]"
    if ([string]::IsNullOrWhiteSpace($repoUrlInput)) {
        $repoUrlInput = $defaultRepoUrl
    }

    $branchInput = Read-Host "Git branch [main]"
    if ([string]::IsNullOrWhiteSpace($branchInput)) {
        $branchInput = "main"
    }

    $workspaceInput = Read-Host "Toolkit workspace [$defaultWorkspace]"
    if ([string]::IsNullOrWhiteSpace($workspaceInput)) {
        $workspaceInput = $defaultWorkspace
    }

    $syncRepoInput = Read-Host "Local sync repo directory [$defaultSyncRepoRoot]"
    if ([string]::IsNullOrWhiteSpace($syncRepoInput)) {
        $syncRepoInput = $defaultSyncRepoRoot
    }

    if (Test-ValidSourceRoot -Path $defaultSource) {
        Write-Info "Auto-detected ccswitch local data directory: $defaultSource"
        $sourceInput = Read-Host "ccswitch local data directory [$defaultSource]"
        if ([string]::IsNullOrWhiteSpace($sourceInput)) {
            $sourceInput = $defaultSource
        }
    } else {
        Write-WarnLine "Auto-detection did not find a valid ccswitch data directory."
        Write-Host "Checked candidates:"
        foreach ($candidate in (Get-DefaultSourceCandidates)) {
            Write-Host " - $candidate"
        }
        $sourceInput = Read-Host "Enter ccswitch local data directory"
        if ([string]::IsNullOrWhiteSpace($sourceInput)) {
            throw "A valid ccswitch local data directory is required."
        }
    }

    if (-not (Test-ValidSourceRoot -Path $sourceInput)) {
        throw "The selected ccswitch data directory is invalid: $sourceInput"
    }

    $config = [ordered]@{
        repoUrl = $repoUrlInput
        branch = $branchInput
        workspaceRoot = $workspaceInput
        syncRepoRoot = $syncRepoInput
        sourceRoot = $sourceInput
        opensslPath = $detectedOpenSsl
        initializedAt = (Get-Date).ToString("o")
    }
    Save-ToolkitConfig -Config $config
    Ensure-Directories

    if (-not (Test-Path (Get-RepoRoot))) {
        New-Item -ItemType Directory -Force -Path (Get-RepoRoot) | Out-Null
    }

    $repoRoot = Get-RepoRoot
    $gitDir = Join-Path $repoRoot ".git"
    if ((Test-Path $repoRoot) -and -not (Test-Path $gitDir) -and ((Get-ChildItem -LiteralPath $repoRoot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)) {
        throw "Sync repo directory already exists and is not empty: $repoRoot . Initialize that repo manually or choose another local sync repo directory."
    }
    if (-not (Test-Path $gitDir)) {
        Write-Info "Cloning repository"
        Remove-Item -LiteralPath $repoRoot -Recurse -Force -ErrorAction SilentlyContinue
        & git clone --branch $branchInput $repoUrlInput $repoRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone repository. Check repo URL and SSH/credential setup."
        }
    } else {
        $actualRemote = Get-GitRemoteUrl -RepoPath $repoRoot
        if ($actualRemote -ne $repoUrlInput) {
            throw "Sync repo remote mismatch. Expected: $repoUrlInput ; Actual: $actualRemote . Fix the local sync repo directory or re-run Init-Setup.cmd."
        }
        Write-Info "Repository already exists locally and matches configured remote, skipping clone"
    }

    Ensure-Directories -IncludeRepo

    $gitignorePath = Join-Path $repoRoot ".gitignore"
    if (-not (Test-Path $gitignorePath)) {
        Set-Content -LiteralPath $gitignorePath -Encoding UTF8 -Value @"
*
!.gitignore
!encrypted/
!encrypted/ccswitch-backup.zip.enc
!metadata/
!metadata/manifest.json
"@
    }

    $readmePath = Join-Path $repoRoot "README.md"
    if (-not (Test-Path $readmePath)) {
        Set-Content -LiteralPath $readmePath -Encoding UTF8 -Value @"
# ccswitch-sync

This repository stores only encrypted ccswitch backups and manifest metadata.
"@
    }

    Write-Ok "Toolkit initialized"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Edit config if needed: $(Get-ToolkitConfigPath)"
    Write-Host "2. Local sync repo: $(Get-RepoRoot)"
    Write-Host "3. Run Backup-Push.cmd to create the first encrypted backup"
    Write-Host "4. On another device, clone this toolkit and run Init-Setup.cmd with the same remote repo"
} catch {
    Write-Fail $_.Exception.Message
    exit 1
}
