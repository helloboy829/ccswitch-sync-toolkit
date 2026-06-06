# 常见问题（FAQ）

## 一般问题

### Q: 需要两个 GitHub 仓库吗？

**A: 是的，建议使用两个仓库：**

1. **工具仓库**（公开）：`ccswitch-sync-toolkit`
   - 存放脚本和文档
   - 每台设备都克隆这个仓库

2. **同步数据仓库**（私有）：`ccswitch-sync`
   - 存放加密的配置备份
   - 包含 `encrypted/` 和 `metadata/` 目录

---

### Q: 同步仓库必须是私有的吗？

**A: 强烈建议私有。**

虽然数据已加密，但私有仓库提供额外的安全层：
- 防止他人看到你的备份频率和模式
- 避免暴露机器名称（在 manifest.json 中）
- 减少被针对性攻击的风险

---

### Q: 忘记加密密码怎么办？

**A: 无法恢复。**

加密密码只在你输入时使用，不会存储在任何地方。如果忘记：
- 无法解密 GitHub 上的备份
- 需要在某台有配置的机器上重新执行 Backup-Push
- 设置新密码，创建新的加密备份

**建议：使用密码管理器（1Password、Bitwarden）保存密码。**

---

### Q: 多台设备必须使用相同密码吗？

**A: 是的。**

所有设备共享同一个加密备份，因此必须使用相同的密码才能解密。

---

### Q: 为什么执行前必须关闭 ccswitch？

**A: 防止文件锁定和数据不一致。**

- ccswitch 运行时会锁定 `cc-switch.db`
- 备份或恢复时需要读写这个文件
- 如果不关闭可能导致文件损坏

---

## 初始化问题

### Q: 初始化时提示 "Workspace repo directory already exists"

**A: 旧的 workspace/repo 目录存在冲突。**

解决方法：
1. 删除 `workspace/repo` 目录
2. 或者选择 `6. Edit Configuration` 修改 `syncRepoRoot` 路径

---

### Q: 自动检测不到 ccswitch 数据目录

**A: 手动输入路径。**

常见位置：
- Windows: `C:\Users\用户名\.cc-switch`
- 确保目录下有 `cc-switch.db` 和 `settings.json`

---

### Q: OpenSSL 路径检测失败

**A: 需要安装 OpenSSL。**

选项：
1. 安装 Git for Windows（自带 OpenSSL）
2. 从 https://slproweb.com/products/Win32OpenSSL.html 下载
3. 手动指定路径（如：`C:\Program Files\Git\usr\bin\openssl.exe`）

---

## 备份和恢复问题

### Q: Backup-Push 时提示 "git pull --rebase" 失败

**A: 这个问题已在最新版本修复。**

如果仍遇到：
```bash
cd D:\code\ccswitch-sync
git status
# 如果有未提交的更改
git add .
git commit -m "manual commit"
git pull --rebase
```

---

### Q: Pull-Restore 后配置没有变化

**A: 检查以下几点：**

1. 密码是否正确（密码错误会导致解密失败）
2. 查看 `workspace/local-backups/` 是否创建了备份
3. 检查 C 盘下文件的修改时间是否更新

---

### Q: 恢复后 ccswitch 启动报错

**A: 可能的原因：**

1. **数据库版本不兼容**
   - 确保所有设备的 ccswitch 版本一致
   
2. **文件损坏**
   - 使用 `4. Rollback Previous Backup` 恢复

---

### Q: 本地备份保存在哪里？

**A: `workspace/local-backups/时间戳/`**

完整路径示例：
```
D:\code\ccswitch-sync-toolkit\workspace\local-backups\20260606-144039\
├── cc-switch.db
└── settings.json
```

每次 Pull-Restore 前会自动创建。

---

## Git 相关问题

### Q: 提示 "remote mismatch"

**A: 同步仓库配置不匹配。**

解决方法：
1. 打开 `config.json`
2. 检查 `syncRepoRoot` 路径
3. 确认该目录下 `git remote -v` 的 URL 与 `repoUrl` 一致

---

### Q: 推送时需要输入 GitHub 密码

**A: 配置 Git 凭据管理。**

```bash
# 使用 credential helper
git config --global credential.helper wincred

# 或者使用 SSH
# 将仓库 URL 改为 git@github.com:用户名/仓库名.git
```

---

### Q: 同步仓库本地目录为空是正常的吗？

**A: 可能正常。**

如果你：
1. 刚创建私有仓库，还没有首次备份 → 正常
2. 还没克隆私有仓库到本地 → 需要先 `git clone`
3. 已初始化工具 → 应该在 `syncRepoRoot` 路径下有内容

---

## 多设备同步问题

### Q: 两台设备同时修改配置怎么办？

**A: 手动协调。**

这个工具使用 "手动选择源" 模式：
- 决定哪台设备的配置是正确的
- 在那台设备上执行 Backup-Push
- 在其他设备上执行 Pull-Restore

**不支持自动合并冲突。**

---

### Q: B 机器路径可以和 A 机器不同吗？

**A: 可以，完全支持。**

每台机器的 `config.json` 是独立的：
- A 机器：`D:\code\ccswitch-sync-toolkit`
- B 机器：`E:\tools\ccswitch-sync-toolkit`
- 同步仓库本地路径也可以不同

---

### Q: 一个账号可以同步几台设备？

**A: 没有限制。**

只要所有设备：
- 能访问私有 GitHub 仓库
- 使用相同的加密密码
- ccswitch 版本兼容

---

## 安全问题

### Q: 加密算法是什么？

**A: AES-256-CBC**

使用 OpenSSL 的 `aes-256-cbc` 算法，密钥由你设置的密码派生。

---

### Q: GitHub 上的备份安全吗？

**A: 相对安全，但依赖密码强度。**

- 文件在上传前已加密
- GitHub 无法看到明文内容
- 但如果密码太弱（如 `123456`），仍可能被暴力破解

**建议使用强密码：至少 16 字符，包含大小写、数字、符号。**

---

### Q: config.json 会上传到 GitHub 吗？

**A: 不会。**

- `config.json` 在 `.gitignore` 中
- 只存在于本地
- 包含本机专属路径配置

---

## 性能问题

### Q: 备份需要多长时间？

**A: 通常 10-30 秒。**

取决于：
- 数据库大小（一般 1-5 MB）
- 网络速度（上传到 GitHub）
- 机器性能（加密速度）

---

### Q: 会占用多少 GitHub 空间？

**A: 每个备份约 1-3 MB。**

- 加密文件: `encrypted/ccswitch-backup.zip.enc`
- 元数据: `metadata/manifest.json`（几百字节）
- Git 历史会记录每次备份

**如果担心空间，定期清理旧的 commit。**

---

## 故障排除

### Q: 提示 "cc-switch is currently running"

**A: 关闭 ccswitch 应用。**

1. 打开任务管理器（Ctrl+Shift+Esc）
2. 找到 `cc-switch.exe` 进程
3. 结束进程
4. 重新运行工具

---

### Q: 解密失败但密码确认正确

**A: 可能的原因：**

1. **备份文件损坏**
   - 检查 GitHub 上的文件是否完整
   
2. **密码输入错误**
   - 注意大小写和特殊字符
   - 避免复制粘贴时带入空格

3. **OpenSSL 版本问题**
   - 确保 OpenSSL 版本 1.1.1 或更高

---

### Q: 回滚后问题没解决

**A: 本地备份也可能有问题。**

选项：
1. 检查 `workspace/local-backups/` 其他时间戳的备份
2. 从另一台正常设备重新同步
3. 手动从 ccswitch 的自带备份恢复

---

### Q: 中文显示乱码

**A: 已在最新版本修复。**

如果仍有问题：
1. 确保使用最新版本工具
2. 检查 PowerShell 编码：`chcp 65001`
3. 更新到最新版 `scripts/Launcher.ps1`

---

## 更多帮助

### 获取详细帮助

运行工具后按 `7` 查看中文帮助文档。

### 查看日志

如果遇到问题，检查：
- PowerShell 窗口的错误信息
- `workspace/staging/` 临时文件

### 报告问题

如果以上方法都无法解决，请在 GitHub Issues 提交问题：
- 详细描述问题
- 附上错误信息（隐藏敏感信息）
- 说明操作系统和工具版本
