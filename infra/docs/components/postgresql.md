# PostgreSQL and catalog database

Status: `PREPARED_GATED_ON_SECRET_AND_IMAGE`.

The design is one PostgreSQL 16.4 StatefulSet with a 20Gi `local-path` PVC.
It is ClusterIP-only, stores catalog metadata only, and accepts traffic only
from the catalog namespace. This is intentionally not HA; the single-node
homelab has no distributed storage requirement.

Credentials are generated locally and encrypted with SOPS/age by
`74-prepare-postgresql-activation.sh`. No plaintext credential belongs in Git.
The catalog image is built locally and imported into k3s because this project
does not yet publish an image registry. The Phase J Flux Kustomizations must
not be enabled until both the encrypted Secret and image are present.

The backup service runs `pg_dump` and `pg_dump --schema-only` inside the
PostgreSQL pod before Restic backs up `/srv/homelab/backups/db`. This is a
logical backup in addition to the k3s/config backup. Same-disk Restic remains
operational protection, **NOT DISASTER RECOVERY**.

Rollback: suspend/remove the catalog Kustomization, then the PostgreSQL
Kustomization. Preserve the PVC unless data deletion is explicitly approved.
