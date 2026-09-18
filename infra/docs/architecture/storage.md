# Storage Architecture

## Initial Model

One physical SATA SSD. Initial Kubernetes storage therefore uses local storage.

## Intended Layout

```text
/srv/homelab/
├── k3s/
├── volumes/
├── backups/
├── lab/
├── cache/
└── data/
    ├── incoming/
    ├── music/
    ├── books/
    ├── movies/
    └── photos/
```

## Important Limitation

A backup stored only on the same physical SSD does not protect against physical SSD failure.

The data tree is created by `72-prepare-data-layout.sh` with `root:homelab-data`
and mode `2770`. The operator account may be added to that group; no directory
is world-writable. `incoming` is staging, while the other directories are
canonical filesystem paths. Files remain outside PostgreSQL; future databases
store metadata and hashes only. Samba remains `OPTIONAL_DISABLED`, with no
guest access, accounts, passwords, or shares.

## Windows Storage

Existing Windows partitions are excluded from the initial cluster design. Any repartitioning must be a separate backed-up migration.
