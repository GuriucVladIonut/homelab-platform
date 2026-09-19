# Media services — Phase K

Status: `IMPLEMENTED_IN_REPO — DEPLOYMENT REQUIRES OPERATOR RECONCILIATION`.

Phase K uses private Traefik routes and read-only mounts of the canonical
filesystem. Flux applies Jellyfin, then Navidrome, then Kavita in dependency
order so each service can be validated independently. Photos remain explicitly
deferred; Immich is not part of the baseline because its PostgreSQL, thumbnail,
and machine-learning footprint is disproportionate for this host.

| Component | Class | Storage | Database | GPU | Decision |
|---|---|---|---|---|---|
| Jellyfin | ENABLED | movies, config | optional | disabled | pinned 10.10.7 |
| Navidrome | ENABLED | music, config | small embedded | no | pinned 0.54.5 |
| Kavita | ENABLED | books, config | small embedded | no | pinned 0.8.4 |
| Immich | HEAVY_ON_DEMAND | photos, thumbnails | PostgreSQL | ML optional | disabled |

Kavita was selected over Calibre-Web for a single low-complexity EPUB/PDF
library service without the LinuxServer image's extra PUID/PGID initialization
layer. Actual files remain under `/srv/homelab/data`; applications must keep media
outside database blobs. Application config and small metadata databases belong
under `/srv/homelab/volumes/apps` and are included in Restic. The same-disk
backup is **NOT DISASTER RECOVERY**; real media recovery requires external or
offsite storage.
