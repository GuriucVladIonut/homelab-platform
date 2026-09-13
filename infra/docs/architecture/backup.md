# Backup Boundary

Restic and configuration-backup design is repository-ready but not disaster recovery. Same-disk backups under `/srv/homelab/backups` protect against operational mistakes only; they do not protect against SSD failure, theft, or total filesystem loss. Personal media is never duplicated merely to create a same-disk archive. Future k3s datastore, PostgreSQL metadata, application configuration, and SOPS recovery material require an external or network-backed destination before they can be called disaster recovery.
