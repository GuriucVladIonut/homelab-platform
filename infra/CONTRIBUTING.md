# Contributing

## Change Workflow

```text
pre-check
   |
change
   |
validate
   |
document
   |
review diff
   |
commit
   |
deploy/reconcile
   |
verify
```

## Rules

- Never commit secrets.
- Prefer declarative configuration.
- Pin meaningful versions.
- Do not use `latest` for managed container images.
- Document destructive operations.
- Keep scripts idempotent where practical.
- Use `set -Eeuo pipefail` in Bash scripts where appropriate.
- Persistent configuration belongs in Git.
- Temporary experiments belong in `labs/`.

## Commit Convention

Examples:

```text
feat(k3s): add cluster bootstrap configuration
feat(dns): add internal DNS configuration
docs(k9s): add operational guide
fix(network): correct hotspot route handling
chore(host): add preflight validation
security(rbac): restrict operator permissions
```
