# Optional Media Matrix

| Component | Class | Storage | Database | GPU | Decision |
|---|---|---|---|---|---|
| Jellyfin | OPTIONAL | media, cache | optional | optional | disabled |
| Navidrome | OPTIONAL | music | no | no | disabled |
| Kavita / Calibre-Web | OPTIONAL | books | small/optional | no | disabled |
| Immich | HEAVY_ON_DEMAND | photos, thumbnails | PostgreSQL | ML optional | disabled |

Actual files remain under `/srv/homelab/data`; no application is deployed by the baseline. NVIDIA functionality is not a dependency.
