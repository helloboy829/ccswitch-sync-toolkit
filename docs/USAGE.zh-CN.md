# CCSwitch Sync Toolkit 使用手册

## 能做什么

- 备份 `cc-switch.db`
- 备份 `settings.json`
- 在进入 Git 之前先加密
- 把加密快照推到 GitHub 私有仓库
- 从另一台设备拉取并恢复
- 恢复前自动创建本地回滚点
- 在 `cc-switch` 正在运行时拒绝覆盖或备份

## 首次使用

1. 准备两个仓库
2. 工具仓库：
   - 例如 `ccswitch-sync-toolkit`
3. 同步数据仓库：
   - 例如 `ccswitch-sync`
4. 每台机器先 clone 工具仓库
5. 双击 `Init-Setup.cmd`
6. 输入或确认：
   - 私有同步仓库地址
   - 分支名
   - 当前机器上的 toolkit workspace 路径
   - 当前机器上的 `ccswitch` 数据目录

## 关于路径

- 每台机器的路径可以不同
- 工具会优先自动探测当前机器的 `ccswitch` 数据目录
- 自动探测不到时才需要手动输入
- `config.json` 是当前机器本地专属配置，不会共享给其他机器

## 日常操作

### 发布当前机器上的本地配置

双击：

- `Backup-Push-Use-Local-As-Source.cmd`

效果：

- 以本地为准
- 把当前本地配置打包、加密、提交到私有同步仓库
- 后续别的设备可以拉这份配置

适合：

- 远端是旧配置
- 当前本地更好

### 用远端配置覆盖当前机器

双击：

- `Pull-Restore-Use-Remote-As-Source.cmd`

效果：

- 以远端为准
- 先备份当前本地文件
- 再把远端加密快照拉下来并覆盖本地

适合：

- 另一台机器已经上传了更好的配置
- 当前机器要与远端保持一致

### 后悔了，恢复最近一次本地备份

双击：

- `Rollback-Restore-Previous-Local-Backup.cmd`

效果：

- 恢复最近一次覆盖前自动生成的本地快照

## 为什么 `D:\code\ccswitch-sync` 可能是空的

如果你看到本地这个目录是空的，通常是因为：

- 这里只是预留的本地 clone 位置
- 你还没有在本机正常 Git 环境里把私有 `ccswitch-sync` 仓库 clone 到这里

这不代表远端 GitHub 私有仓库也是空的。

## 安全注意事项

- 不要在 `cc-switch` 运行时执行备份或恢复
- 所有设备使用同一个加密密码时，这些设备都应当是可信设备
- 不要把解密后的快照提交进任何 Git 仓库
- 不要把 `config.json` 提交到公开 toolkit 仓库
