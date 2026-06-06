# CCSwitch Sync Toolkit 中文说明

这是一个用于在多台设备之间同步本地 `ccswitch` 配置的工具包。

它的目标是：

- 双击即可操作
- 同步前先加密
- 覆盖前先做本地备份
- 路径允许每台机器不同
- 工具仓库和同步数据仓库分离

## 两仓库模型

建议使用两个仓库：

### 1. 工具仓库

例如：

- `ccswitch-sync-toolkit`

用途：

- 存放脚本
- 存放文档
- 每台机器都 clone 一份

### 2. 同步数据仓库

例如：

- `ccswitch-sync`

用途：

- 存放加密后的配置快照
- 存放 manifest 元数据

说明：

- `D:\code\ccswitch-sync` 这种路径只是本地 clone 目录
- 如果你还没有在本机正常 Git 环境里 clone 私有仓库进去，那么这个目录为空是正常的
- 远端 GitHub 私有仓库和本地空目录不是一回事

## 核心操作模式

### 1. 本地为准

启动脚本：

- `Backup-Push-Use-Local-As-Source.cmd`

含义：

- 当前本地配置是正确版本
- 会把当前本地配置加密后推送到远端
- 远端旧快照会被新的本地快照替代

适用场景：

- 远端是旧配置
- 你当前这台机器上的配置更好
- 你想让其他设备以后拉取这份配置

### 2. 远端为准

启动脚本：

- `Pull-Restore-Use-Remote-As-Source.cmd`

含义：

- 远端配置是正确版本
- 本地当前配置会被远端覆盖
- 覆盖前会自动做本地回滚备份

适用场景：

- 另一台设备已经上传了最新配置
- 你希望当前机器和远端保持一致

### 3. 回滚最近一次本地覆盖前备份

启动脚本：

- `Rollback-Restore-Previous-Local-Backup.cmd`

含义：

- 恢复最近一次覆盖前自动创建的本地快照

## 每台机器路径可以不同

这套工具不会把所有机器都写死成同一路径。

实际规则是：

- toolkit 仓库内容是通用的
- 每台机器第一次运行 `Init-Setup.cmd` 时，会生成自己的 `config.json`
- 每台机器会记录自己的：
  - toolkit 工作目录
  - 本地 `ccswitch` 数据目录
  - OpenSSL 路径

因此：

- 你的 A 机器可以放在 `D:\code\ccswitch-sync-toolkit`
- 你的 B 机器可以放在 `E:\tools\ccswitch-sync-toolkit`
- 不需要所有机器完全相同

## 本地私有配置不会进公开仓库

以下内容不会提交到公开 toolkit 仓库：

- `config.json`
- `workspace/`
- 实际同步出来的私有配置快照
- 明文 API Key

## 入口脚本

- `Open-CCSwitch-Sync-Toolkit.cmd`
- `Init-Setup.cmd`
- `Backup-Push-Use-Local-As-Source.cmd`
- `Pull-Restore-Use-Remote-As-Source.cmd`
- `Rollback-Restore-Previous-Local-Backup.cmd`
- `Status.cmd`

建议日常直接双击：

- `Open-CCSwitch-Sync-Toolkit.cmd`

然后在一个统一窗口里选择你要执行的操作。
