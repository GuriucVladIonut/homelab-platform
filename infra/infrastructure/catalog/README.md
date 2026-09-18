# Catalog

The catalog stores metadata, hashes, paths, tags, and ingest history. The
filesystem under `/srv/homelab/data` remains authoritative for media files.
The initial service is read-only for catalog browsing and stats; physical file
deletion and arbitrary filesystem APIs are intentionally absent.
