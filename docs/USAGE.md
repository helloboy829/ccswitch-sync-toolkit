# CCSwitch Sync Toolkit

This toolkit provides an engineered, double-click workflow for syncing local `ccswitch` configuration across devices by using:

- a private GitHub repository
- encrypted backup artifacts
- local restore points before every restore

Recommended architecture:

- one private repository for encrypted sync data
- one separate repository for the toolkit itself

## What It Can Do

- Back up `cc-switch.db` and `settings.json`
- Encrypt the backup before it enters Git
- Push the encrypted artifact to a private GitHub repository
- Pull the latest encrypted artifact on another device
- Restore it back into the local `.cc-switch` directory
- Create a local rollback copy before restore
- Refuse to run while `cc-switch` is open

## What It Syncs

- `C:\Users\<your-user>\.cc-switch\cc-switch.db`
- `C:\Users\<your-user>\.cc-switch\settings.json`

## What It Does Not Sync

- running process state
- logs
- `backups\`
- `crash.log`

## Security Model

- The Git repository stores only encrypted backup data
- The encryption password is requested at runtime and is not saved to disk by the toolkit
- If the repository is leaked, the encrypted artifact is still not directly readable
- Git history still keeps encrypted versions, so use one stable password and protect it well

## Files

- `Open-CCSwitch-Sync-Toolkit.cmd`
  Unified launcher with an interactive menu
- `Init-Setup.cmd`
  Initializes the toolkit and clones the repo
- `Backup-Push.cmd`
  Creates an encrypted backup and pushes it
- `Pull-Restore.cmd`
  Pulls the latest encrypted backup and restores it locally
- `Rollback-LastLocalBackup.cmd`
  Restores the most recent local snapshot created before an overwrite
- `Status.cmd`
  Shows local status and latest manifest information

## First-Time Setup

1. Create a private GitHub repository for sync data, for example `<your-sync-repo>`
2. Create another repository for the toolkit itself, for example `ccswitch-sync-toolkit`
3. Put this toolkit into the toolkit repository
4. Clone the toolkit repository on each device
5. Make sure each machine can `git clone` and `git push` to the private sync repository
6. Double-click `Open-CCSwitch-Sync-Toolkit.cmd`
7. Choose `Initialize Toolkit`
8. Enter:
   - your private repo URL
   - branch name
   - local `.cc-switch` path only if auto-detection is wrong or not found

## Two-Repository Model

- Sync repository
  Example: `<your-sync-repo>`
  Stores encrypted snapshots and `manifest.json` only

- Toolkit repository
  Example: `ccswitch-sync-toolkit`
  Stores scripts, launcher files, and documentation only

- `config.json` is local to each machine
- `workspace/` is local runtime state for each machine
- do not commit either of those into the toolkit repository

## Path Handling Across Devices

- Each device keeps its own local `config.json`
- The toolkit tries to auto-detect the local `ccswitch` data directory on that device
- Different devices can use different local paths
- The Git repository remains the same; only local source paths differ per device

## Daily Use

### Push current local config to cloud

1. Close `cc-switch`
2. Double-click `Open-CCSwitch-Sync-Toolkit.cmd`
3. Choose `Backup-Push (Use Local As Source)`
4. Read the warning carefully
5. Type `YES`
6. Enter the encryption password
7. Wait for push to complete

This mode means:

- local is the source of truth
- remote encrypted snapshot will be replaced by your current local config

### Pull latest config from cloud to this device

1. Close `cc-switch`
2. Double-click `Open-CCSwitch-Sync-Toolkit.cmd`
3. Choose `Pull-Restore (Use Remote As Source)`
4. Read the warning carefully
5. Type `YES`
6. Enter the same encryption password
7. Start `cc-switch` after restore completes

This mode means:

- remote is the source of truth
- your current local config will be overwritten after a local safety backup is created

### Undo the latest overwrite

1. Close `cc-switch`
2. Double-click `Open-CCSwitch-Sync-Toolkit.cmd`
3. Choose `Rollback Previous Local Backup`
4. Start `cc-switch` after rollback completes

## Safety Notes

- Never run backup or restore while `cc-switch` is open
- Use the same encryption password on all devices
- Keep the password outside the repository
- Test the workflow once on a secondary machine before treating it as your only backup

## Local Rollback

Before every restore, the toolkit creates a local snapshot under:

- `workspace\local-backups\YYYYMMDD-HHMMSS`

If a restore result is wrong, you can use `Rollback-LastLocalBackup.cmd` or manually copy those files back.

## Recommended Operating Discipline

- Use `Backup-Push.cmd` only when you intend to publish the latest state
- Use `Pull-Restore.cmd` only when you intend to replace local state with remote state
- Avoid editing `ccswitch` on two devices at the same time without pushing/pulling in order
