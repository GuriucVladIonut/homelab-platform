# PostgreSQL

This is one pinned, single-node PostgreSQL 16 instance for metadata only. It
uses the `local-path` StorageClass and a 20Gi PVC; it is not HA and it does not
store media blobs. The service is ClusterIP-only and accepts traffic only from
the catalog namespace.

Activation is gated on the SOPS-encrypted `postgresql-credentials.sops.yaml`
and on loading the locally built catalog image. Run the initializer documented
in `infra/docs/components/postgresql.md`, commit only the encrypted Secret, and
then enable the Phase J Flux Kustomizations.
