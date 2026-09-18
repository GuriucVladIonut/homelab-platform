# Catalog Application

`apps/catalog` is a small metadata-only service. PostgreSQL stores metadata and ingest history; media remains under `/srv/homelab/data`. The service has no arbitrary filesystem endpoint and does not delete physical files. Ingestion is deliberately explicit and retry-safe; a separate worker will discover only files placed in `incoming`, hash them, check duplicates, then perform an atomic move and transaction.

The container is built from `apps/catalog/Dockerfile` and uses `/app/schema.sql` for idempotent bootstrap migrations. A production deployment must provide `DATABASE_URL` through the SOPS-managed Kubernetes Secret.
