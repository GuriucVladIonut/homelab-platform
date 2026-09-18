# Media services — Phase K

Status: `OPTIONAL_DISABLED — BLOCKED UNTIL PHASE J IS LIVE AND RESTORE-VALIDATED`.

Phase K will use private Traefik routes and read-only mounts of the canonical
filesystem. No media application is enabled by this change. Photos remain
explicitly deferred; Immich is not part of the baseline because its PostgreSQL,
thumbnail, and machine-learning footprint is disproportionate for this host.

| Component | Class | Storage | Database | GPU | Decision |
|---|---|---|---|---|---|
| Jellyfin | OPTIONAL | media, cache | optional | optional | disabled |
| Navidrome | OPTIONAL | music | no | no | disabled |
| Kavita / Calibre-Web | OPTIONAL | books | small/optional | no | disabled |
| Immich | HEAVY_ON_DEMAND | photos, thumbnails | PostgreSQL | ML optional | disabled |

Actual files remain under `/srv/homelab/data`; applications must keep media
outside database blobs. Application config and small metadata databases belong
under `/srv/homelab/volumes/apps` and are included in Restic. The same-disk
backup is **NOT DISASTER RECOVERY**; real media recovery requires external or
offsite storage.
