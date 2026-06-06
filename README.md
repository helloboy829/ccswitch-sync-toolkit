# CCSwitch Sync Toolkit

中文说明：

- 首页说明：`README.md`
- 中文详细手册：`docs/README.zh-CN.md`
- 中文使用手册：`docs/USAGE.zh-CN.md`

English:

- English usage: `docs/USAGE.md`

这是一个用于在多台设备之间同步本地 `ccswitch` 配置的工具包。

它的目标是：

- 双击即可操作
- 配置进入 Git 之前先加密
- 覆盖本地前先自动做回滚备份
- 工具仓库与同步数据仓库分离
- 不同设备允许不同本地路径

## 两仓库模型

建议使用两个仓库：

### 1. 工具仓库

当前这个仓库。

用途：

- 存放脚本
- 存放文档
- 每台设备都 clone 一份

建议仓库名：

- `ccswitch-sync-toolkit`

### 2. 同步数据仓库

单独的私有仓库，用于运行时存放加密快照。

用途：

- 存放加密后的配置备份
- 存放 manifest 元数据

建议仓库名：

- `ccswitch-sync`

说明：

- 像 `D:\code\ccswitch-sync` 这种路径只是某一台机器上的本地 clone 目录
- 如果你还没有在本机正常 Git 环境里 clone 私有仓库进去，那么这个目录为空是正常的
- 本地目录空，不等于 GitHub 私有仓库有问题
- 每台机器都可以把这个本地目录放在不同位置

## 能做什么

- 备份 `cc-switch.db`
- 备份 `settings.json`
- 加密后再进入 Git
- 将本地配置作为源上传到远端
- 将远端配置作为源覆盖本地
- 覆盖前自动创建本地回滚点
- 支持恢复最近一次本地备份
- 支持每台机器独立配置路径

## 备份机制

这套工具有两层备份：

### 1. 远端加密备份

当你执行：

- `Backup-Push-Use-Local-As-Source.cmd`

工具会把以下文件打包并加密后上传到私有同步仓库：

- `cc-switch.db`
- `settings.json`

也就是说，私有仓库 `ccswitch-sync` 本身就是你的远端加密备份仓库。

### 2. 本地回滚备份

当你执行：

- `Pull-Restore-Use-Remote-As-Source.cmd`

工具会先把当前本机正在使用的配置保存到本地回滚目录，再执行覆盖。

默认位置类似：

- `workspace\local-backups\YYYYMMDD-HHMMSS`

如果覆盖后后悔了，可以使用：

- `Rollback-Restore-Previous-Local-Backup.cmd`

恢复最近一次本地备份。

## ccswitch 是如何用上这些配置的

这套工具不是通过 API 把配置“注入”到 `ccswitch` 里，而是直接替换 `ccswitch` 正常读取的本地配置文件。

对于当前机器，`ccswitch` 实际使用的是本机数据目录里的：

- `cc-switch.db`
- `settings.json`

恢复流程本质上是：

1. 从私有同步仓库拉取加密快照
2. 用同步加密密码解密
3. 解出 `cc-switch.db` 和 `settings.json`
4. 覆盖本机 `ccswitch` 正在使用的这两个文件
5. 重新启动 `ccswitch`

因此，`ccswitch` 下次启动时就会自然使用你同步过来的配置。

这也是为什么执行备份或恢复时，不允许 `cc-switch` 正在运行。

## 推荐入口

日常建议直接双击：

- `Open-CCSwitch-Sync-Toolkit.cmd`

它会打开一个统一交互式菜单，在一个窗口里选择：

1. `Initialize Toolkit`
2. `Backup-Push (Use Local As Source)`
3. `Pull-Restore (Use Remote As Source)`
4. `Rollback Previous Local Backup`
5. `Show Status`
0. `Exit`

## 三个核心动作怎么理解

### 1. 本地为准并上传

对应操作：

- `Backup-Push-Use-Local-As-Source.cmd`

含义：

- 当前这台机器上的配置是正确版本
- 会把当前本地配置打包、加密、上传到私有同步仓库
- 远端旧快照会被替换

适合场景：

- 当前机器配置更好
- 你想让别的设备以后拉这份配置

### 2. 远端为准并覆盖本机

对应操作：

- `Pull-Restore-Use-Remote-As-Source.cmd`

含义：

- 远端配置是正确版本
- 当前本地配置会被远端覆盖
- 覆盖前会自动创建本地备份

适合场景：

- 另一台设备已经上传了更好的配置
- 当前机器要同步成远端版本

### 3. 回滚最近一次覆盖前备份

对应操作：

- `Rollback-Restore-Previous-Local-Backup.cmd`

含义：

- 恢复最近一次覆盖前的本地自动备份

## 路径不是写死给所有机器的

这套工具不会把所有设备都固定成同一路径。

实际规则是：

- 工具仓库内容是通用的
- 每台机器第一次运行 `Init-Setup.cmd` 时，会生成自己的 `config.json`
- 每台机器分别记录自己的：
  - toolkit 工作目录
  - `ccswitch` 本地数据目录
  - OpenSSL 路径

因此：

- A 机器可以在 `D:\code\ccswitch-sync-toolkit`
- B 机器可以在 `E:\tools\ccswitch-sync-toolkit`
- 不需要所有机器完全相同
- 私有 sync repo 本地目录也一样，每台机器都可以不同

## 安全说明

- 同步数据在进入私有仓库前会先加密
- `config.json` 不会提交到公开工具仓库
- `workspace/` 不会提交到公开工具仓库
- 明文 API Key 不应出现在公开仓库
- 覆盖本地前会先生成回滚快照

## 快速开始

1. clone 当前工具仓库到本机
2. 准备私有同步数据仓库
3. 双击 `Open-CCSwitch-Sync-Toolkit.cmd`
4. 选择 `Initialize Toolkit`
5. 确认当前机器上的本地路径
6. 根据需要选择：
   - 本地更好时上传
   - 远端更好时覆盖本地

## 另一台机器首次使用最短清单

1. clone `ccswitch-sync-toolkit` 到另一台机器任意目录
2. 双击 `Open-CCSwitch-Sync-Toolkit.cmd`
3. 选择 `1. Initialize Toolkit`
4. 私有仓库地址填：
   - `https://github.com/helloboy829/ccswitch-sync.git`
5. branch 填：
   - `main`
6. 确认当前机器上的 `ccswitch` 本地路径
7. 判断哪一份配置更好：
   - 如果远端更好，选择 `3. Pull-Restore (Use Remote As Source)`
   - 如果当前机器本地更好，选择 `2. Backup-Push (Use Local As Source)`
8. 输入与其他设备相同的同步加密密码

## 许可证

本项目采用 MIT License，详见 `LICENSE`。
