# Catalog Application

`apps/catalog` is source-only and `OPTIONAL_DISABLED` until k3s and GitOps are validated. PostgreSQL stores metadata and audit history only; media remains under `/srv/homelab/data`. The planned API must enforce the path boundary, reject duplicate SHA-256 values, separate metadata deletion from physical-file deletion, and use trash/soft-delete semantics for any future file deletion. The current standard-library validation API demonstrates input validation but is not a production deployment.
