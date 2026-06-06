# ccswitch-sync-toolkit

Double-click toolkit for syncing local `ccswitch` config across devices through an encrypted backup stored in a private Git repository.

Recommended repository split:

- `ccswitch-sync`
  Private sync data repository for encrypted backup snapshots
- `ccswitch-sync-toolkit`
  Toolkit repository for scripts, docs, and launchers

Start with:

- `Init-Setup.cmd`
- `Backup-Push.cmd`
- `Pull-Restore.cmd`
- `Rollback-LastLocalBackup.cmd`
- then read [docs/USAGE.md](C:/Users/hasee/ccswitch-sync-toolkit/docs/USAGE.md)

Meaning:

- `Backup-Push.cmd`: use local config as source, publish to remote
- `Pull-Restore.cmd`: use remote config as source, overwrite local

Repository notes:

- `config.json` is machine-specific and should not be committed
- `workspace/` is runtime data and should not be committed
- `config.example.json` is the reference template for new devices
