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
   - 当前机器上的私有 sync repo 本地目录
   - 当前机器上的 `ccswitch` 数据目录

## 关于路径

- 每台机器的路径可以不同
- 工具会优先自动探测当前机器的 `ccswitch` 数据目录
- 自动探测不到时才需要手动输入
- `config.json` 是当前机器本地专属配置，不会共享给其他机器
- 私有 sync repo 的本地 clone 目录也是当前机器独立配置

## 日常操作

建议日常统一双击：

- `Open-CCSwitch-Sync-Toolkit.cmd`

然后在菜单里选择要执行的动作。

### 发布当前机器上的本地配置

双击统一入口后选择：

- `Backup-Push (Use Local As Source)`

效果：

- 以本地为准
- 把当前本地配置打包、加密、提交到私有同步仓库
- 后续别的设备可以拉这份配置

适合：

- 远端是旧配置
- 当前本地更好

### 用远端配置覆盖当前机器

双击统一入口后选择：

- `Pull-Restore (Use Remote As Source)`

效果：

- 以远端为准
- 先备份当前本地文件
- 再把远端加密快照拉下来并覆盖本地

适合：

- 另一台机器已经上传了更好的配置
- 当前机器要与远端保持一致

### 后悔了，恢复最近一次本地备份

双击统一入口后选择：

- `Rollback Previous Local Backup`

效果：

- 恢复最近一次覆盖前自动生成的本地快照

## 另一台机器首次使用最短步骤

1. clone `ccswitch-sync-toolkit` 到当前机器
2. 双击 `Open-CCSwitch-Sync-Toolkit.cmd`
3. 选择 `Initialize Toolkit`
4. 私有同步仓库地址填：
   - `https://github.com/helloboy829/ccswitch-sync.git`
5. branch 填：
   - `main`
6. 确认当前机器上的 `ccswitch` 数据目录
7. 如果远端配置更好：
   - 选择 `Pull-Restore (Use Remote As Source)`
8. 如果当前机器本地配置更好：
   - 选择 `Backup-Push (Use Local As Source)`
9. 输入和其他设备一致的同步加密密码

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

## 备份分为哪两种

### 1. 远端加密备份

执行：

- `Backup-Push-Use-Local-As-Source.cmd`

时，会把本地 `cc-switch.db` 和 `settings.json` 打包并加密后上传到私有同步仓库。

所以你的私有 `ccswitch-sync` 仓库，本身就是远端加密备份。

### 2. 本地回滚备份

执行：

- `Pull-Restore-Use-Remote-As-Source.cmd`

时，会先把当前机器本地正在使用的文件保存到：

- `workspace\local-backups\时间戳`

如果覆盖后后悔，可以使用：

- `Rollback-Restore-Previous-Local-Backup.cmd`

恢复最近一次本地备份。

## ccswitch 是怎么用上同步配置的

原理不是“通知 ccswitch 加载新配置”，而是：

- 直接替换 `ccswitch` 平时本来就会读取的本地文件

核心就是这两个文件：

- `cc-switch.db`
- `settings.json`

恢复时会：

1. 从私有仓库拉下加密快照
2. 用同步加密密码解密
3. 解出 `cc-switch.db` 和 `settings.json`
4. 覆盖当前机器的本地配置文件
5. 再启动 `ccswitch`

因此 `ccswitch` 启动后读取到的自然就是同步后的配置。
