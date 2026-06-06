# CCSwitch Sync Toolkit

Double-click toolkit for syncing local `ccswitch` configuration across devices through an encrypted backup stored in GitHub.

Language:

- English: `README.md`, `docs/USAGE.md`
- 中文: `docs/README.zh-CN.md`, `docs/USAGE.zh-CN.md`

This project is designed for users who want:

- one-click backup and upload
- one-click pull and full restore
- local rollback before overwrite
- different local paths on different devices
- encrypted sync data in a separate repository

## Repository Model

This project is intended to be used with two repositories:

### 1. Toolkit Repository

This repository.

Purpose:

- stores scripts
- stores documentation
- is cloned on every device

Suggested name:

- `ccswitch-sync-toolkit`

### 2. Sync Data Repository

Separate repository used by the toolkit at runtime.

Purpose:

- stores encrypted backup snapshots only
- stores manifest metadata only

Suggested name:

- `ccswitch-sync`

Note:

- a local folder such as `D:\code\ccswitch-sync` is only the local clone location
- that folder may be empty until you clone the private sync repository there in your normal Git environment

## Features

- Full snapshot backup of `cc-switch.db` and `settings.json`
- Encryption before sync data enters Git
- Manual source-of-truth workflow
- Local-first publish mode
- Remote-first restore mode
- Automatic local rollback snapshot before overwrite
- Per-device local path auto-detection
- Machine-specific config excluded from the public toolkit repository

## How It Works

There are two main user actions:

### Use Local As Source

Launcher:

- `Backup-Push-Use-Local-As-Source.cmd`

Meaning:

- your current local config is treated as the correct version
- the remote encrypted snapshot will be replaced

Use this when:

- GitHub already has older data
- your current device has the better config
- you want other devices to pull your current version later

### Use Remote As Source

Launcher:

- `Pull-Restore-Use-Remote-As-Source.cmd`

Meaning:

- the remote encrypted snapshot is treated as the correct version
- your current local config will be overwritten

Use this when:

- another device already published the correct config
- you want this device to match that published version

### Roll Back Local Overwrite

Launcher:

- `Rollback-Restore-Previous-Local-Backup.cmd`

Meaning:

- restore the latest local snapshot created before an overwrite

## Files

### Launchers

- `Init-Setup.cmd`
- `Backup-Push-Use-Local-As-Source.cmd`
- `Pull-Restore-Use-Remote-As-Source.cmd`
- `Rollback-Restore-Previous-Local-Backup.cmd`
- `Status.cmd`

### Documentation

- `docs/USAGE.md`
- `docs/USAGE.zh-CN.md`
- `docs/README.zh-CN.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`

### Configuration

- `config.example.json`

## Safety Model

- sync data is encrypted before being committed to the sync repository
- local rollback snapshots are created before restore
- scripts refuse backup/restore while `cc-switch` is running
- `config.json` is local to each machine and not committed
- `workspace/` is local runtime state and not committed

## Quick Start

1. Clone this toolkit repository on each device
2. Create or use a separate sync data repository
3. Run `Init-Setup.cmd`
4. Confirm the detected local `ccswitch` path on that machine
5. Use:
   - `Backup-Push-Use-Local-As-Source.cmd` to publish local config
   - `Pull-Restore-Use-Remote-As-Source.cmd` to overwrite local config from remote

## Path Handling

Different devices may store `ccswitch` data in different locations.

The toolkit handles this by:

- auto-detecting common local paths on each device
- storing local path configuration per machine
- keeping the shared sync repository independent from local filesystem layout

## Public Repository Notes

This public repository does not store:

- your local `config.json`
- your encrypted runtime workspace
- your actual synced `ccswitch` private data
- your API keys in plaintext

Those belong either to:

- the per-device local machine
- or the separate encrypted sync data repository

## License

This project is released under the MIT License. See `LICENSE`.
