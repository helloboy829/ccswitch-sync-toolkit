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

function Show-Help {
    Clear-Host
    Write-Host "CCSwitch Sync Toolkit - 帮助文档" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Initialize Toolkit（初始化工具）" -ForegroundColor Yellow
    Write-Host "   - 首次设置：生成 config.json"
    Write-Host "   - 自动检测 ccswitch 数据目录"
    Write-Host "   - 配置同步仓库位置"
    Write-Host "   - 每台设备只需运行一次"
    Write-Host ""
    Write-Host "2. Backup-Push（备份推送 - 本地为准）" -ForegroundColor Yellow
    Write-Host "   - 加密本地 ccswitch 配置"
    Write-Host "   - 推送加密备份到 GitHub"
    Write-Host "   - 使用场景：当前设备有最新配置"
    Write-Host "   - 要求：必须关闭 ccswitch 应用"
    Write-Host ""
    Write-Host "3. Pull-Restore（拉取恢复 - 远端为准）" -ForegroundColor Yellow
    Write-Host "   - 从 GitHub 拉取加密备份"
    Write-Host "   - 解密并覆盖本地配置"
    Write-Host "   - 覆盖前自动创建本地备份"
    Write-Host "   - 使用场景：其他设备有最新配置"
    Write-Host "   - 要求：必须关闭 ccswitch 应用"
    Write-Host ""
    Write-Host "4. Rollback Previous Local Backup（回滚本地备份）" -ForegroundColor Yellow
    Write-Host "   - 恢复最近一次本地备份"
    Write-Host "   - 使用场景：拉取恢复后发现不对"
    Write-Host "   - 只能恢复最新的本地快照"
    Write-Host ""
    Write-Host "5. Show Status（显示状态）" -ForegroundColor Yellow
    Write-Host "   - 显示当前配置信息"
    Write-Host "   - 显示初始化状态"
    Write-Host "   - 检查路径和设置"
    Write-Host ""
    Write-Host "6. Edit Configuration（编辑配置）" -ForegroundColor Yellow
    Write-Host "   - 交互式修改 config.json"
    Write-Host "   - 更新同步仓库路径"
    Write-Host "   - 修改 ccswitch 数据目录"
    Write-Host "   - 修改 OpenSSL 路径等"
    Write-Host ""
    Write-Host "7. Help（帮助）- 显示此帮助信息" -ForegroundColor Yellow
    Write-Host ""
}

function Edit-Configuration {
    Clear-Host
    Write-Host "Edit Configuration" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-ToolkitInitialized)) {
        Write-WarnLine "Toolkit is not initialized yet. Run 'Initialize Toolkit' first."
        return
    }

    $config = Get-ToolkitConfig

    Write-Host "Current Configuration:" -ForegroundColor Yellow
    Write-Host "1. GitHub Repo URL: $($config.repoUrl)"
    Write-Host "2. Branch: $($config.branch)"
    Write-Host "3. Workspace Root: $($config.workspaceRoot)"
    Write-Host "4. Sync Repo Root: $($config.syncRepoRoot)"
    Write-Host "5. CCSwitch Data Directory: $($config.sourceRoot)"
    Write-Host "6. OpenSSL Path: $($config.opensslPath)"
    Write-Host "0. Cancel"
    Write-Host ""

    $choice = Read-Host "Which setting do you want to edit? (0-6)"
    Write-Host ""

    switch ($choice) {
        "1" {
            $newValue = Read-Host "Enter new GitHub Repo URL [$($config.repoUrl)]"
            if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                $config.repoUrl = $newValue
                Write-Ok "GitHub Repo URL updated"
            }
        }
        "2" {
            $newValue = Read-Host "Enter new branch [$($config.branch)]"
            if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                $config.branch = $newValue
                Write-Ok "Branch updated"
            }
        }
        "3" {
            $newValue = Read-Host "Enter new workspace root [$($config.workspaceRoot)]"
            if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                $config.workspaceRoot = $newValue
                Write-Ok "Workspace root updated"
            }
        }
        "4" {
            $newValue = Read-Host "Enter new sync repo root [$($config.syncRepoRoot)]"
            if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                $config.syncRepoRoot = $newValue
                Write-Ok "Sync repo root updated"
            }
        }
        "5" {
            $newValue = Read-Host "Enter new ccswitch data directory [$($config.sourceRoot)]"
            if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                if (Test-ValidSourceRoot -Path $newValue) {
                    $config.sourceRoot = $newValue
                    Write-Ok "CCSwitch data directory updated"
                } else {
                    Write-WarnLine "Invalid ccswitch data directory (missing cc-switch.db or settings.json)"
                }
            }
        }
        "6" {
            $newValue = Read-Host "Enter new OpenSSL path [$($config.opensslPath)]"
            if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                if (Test-Path $newValue) {
                    $config.opensslPath = $newValue
                    Write-Ok "OpenSSL path updated"
                } else {
                    Write-WarnLine "OpenSSL executable not found at: $newValue"
                }
            }
        }
        "0" {
            Write-Info "Edit cancelled"
            return
        }
        default {
            Write-Fail "Invalid selection"
            return
        }
    }

    if ($choice -ne "0") {
        Save-ToolkitConfig -Config $config
        Write-Ok "Configuration saved to config.json"
    }
}

try {
    while ($true) {
        Clear-Host
        Write-Host "CCSwitch Sync Toolkit" -ForegroundColor Cyan
        Write-Host ""

        # Check initialization status
        $isInitialized = Test-ToolkitInitialized
        if ($isInitialized) {
            Write-Host "[" -NoNewline
            Write-Host "Initialized" -ForegroundColor Green -NoNewline
            Write-Host "]" -NoNewline
            Write-Host " Ready to use"
        } else {
            Write-Host "[" -NoNewline
            Write-Host "Not Initialized" -ForegroundColor Yellow -NoNewline
            Write-Host "]" -NoNewline
            Write-Host " Run option 1 first"
        }
        Write-Host ""

        Write-Host "1. Initialize Toolkit"
        Write-Host "2. Backup-Push (Use Local As Source)"
        Write-Host "3. Pull-Restore (Use Remote As Source)"
        Write-Host "4. Rollback Previous Local Backup"
        Write-Host "5. Show Status"
        Write-Host "6. Edit Configuration"
        Write-Host "7. Help"
        Write-Host "0. Exit"
        Write-Host ""

        $choice = Read-Host "Choose an action"
        Write-Host ""

        switch ($choice) {
            "1" { Invoke-ToolkitScript -ScriptName "Init-Setup.ps1" }
            "2" { Invoke-ToolkitScript -ScriptName "Backup-Push.ps1" }
            "3" { Invoke-ToolkitScript -ScriptName "Pull-Restore.ps1" }
            "4" { Invoke-ToolkitScript -ScriptName "Rollback-LastLocalBackup.ps1" }
            "5" { Invoke-ToolkitScript -ScriptName "Status.ps1" }
            "6" { Edit-Configuration }
            "7" { Show-Help }
            "0" { exit 0 }
            default { Write-Host "[FAIL] Invalid selection: $choice" -ForegroundColor Red }
        }

        Write-Host ""
        Read-Host "Press Enter to return to the main menu" | Out-Null
    }
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
