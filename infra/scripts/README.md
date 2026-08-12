# Scripts

## Categories

```text
inventory/      read-only discovery
bootstrap/      installation/bootstrap
maintenance/    controlled maintenance
backup/         backup/restore helpers
validation/     tests/preflight checks
cleanup/        removal/cleanup helpers
```

## Bash Standard

Prefer:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

A script that modifies the system should document prerequisites, files modified, services restarted, expected result, validation, rollback, and destructive behavior.

Secrets must be supplied externally.
