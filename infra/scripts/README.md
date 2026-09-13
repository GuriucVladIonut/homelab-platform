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

The Phase 00 preflight inventory script is `scripts/inventory/phase-00-preflight.sh`. It is read-only, writes its report under the invoking user's home directory, and must not be used to commit raw identifiers or secrets.

## Bash Standard

Prefer:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

A script that modifies the system should document prerequisites, files modified, services restarted, expected result, validation, rollback, and destructive behavior.

Secrets must be supplied externally.
