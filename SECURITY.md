# Security Policy

## Scope

This repository contains the toolkit only.

It should not contain:

- real `config.json` from a personal machine
- runtime `workspace/`
- plaintext API keys
- plaintext `ccswitch` database backups

## Security Design

- actual sync data is expected to live in a separate repository
- sync data is encrypted before Git commit
- local overwrite operations create local rollback snapshots first
- machine-specific settings are intentionally excluded from this repository

## Operational Advice

- use a strong encryption password
- keep the same password across devices only if those devices are all trusted
- do not commit decrypted backups
- do not use this repository as the sync data repository

## Reporting

If you discover a security issue in the toolkit logic, review local script behavior before public disclosure and validate whether the issue concerns:

- encryption flow
- rollback flow
- path handling
- accidental plaintext persistence
