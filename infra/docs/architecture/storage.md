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
└── cache/
```

## Important Limitation

A backup stored only on the same physical SSD does not protect against physical SSD failure.

## Windows Storage

Existing Windows partitions are excluded from the initial cluster design. Any repartitioning must be a separate backed-up migration.
