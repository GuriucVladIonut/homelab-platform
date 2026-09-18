# Metadata catalog

Status: `PREPARED_GATED_ON_POSTGRESQL`.

The catalog is a small Go service at `catalog.homelab.gvlad.dev`, reachable
only through the private Traefik entrypoint. PostgreSQL stores metadata and
ingest history; the filesystem is authoritative for media files. The service
does not expose arbitrary filesystem reads or implicit physical deletion.

The schema covers `media_item`, `file_asset`, `tag`, `media_item_tag`, and
`ingest_event`. Files deliberately placed in `incoming` are the only intended
future ingest input. Discovery must hash and duplicate-check before any atomic
move; a failed database transaction must leave the source file intact.
