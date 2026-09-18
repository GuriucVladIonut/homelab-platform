# Backup Boundary

Restic configuration-backup baseline is prepared through `70-install-backup-baseline.sh` and `71-validate-backups.sh`.

**THIS IS NOT DISASTER RECOVERY.** The repository is on the same SSD and host;
an SSD failure, theft, filesystem loss, or host compromise can destroy both
source and backup. Personal media is deliberately excluded. The baseline
retains seven daily, four weekly, and three monthly configuration snapshots.

The backup scope includes k3s configuration, the k3s datastore snapshot,
`/opt/homelab`, application and observability configuration, backup metadata,
and future database-dump directories. It excludes media, caches, container
images, transient Kubernetes runtime data, and unapproved personal files.

The password is never stored in Git. The operator creates a root-only
`/etc/homelab/restic-password` and an environment file containing only
`RESTIC_REPOSITORY=/srv/homelab/backups/restic` and
`RESTIC_PASSWORD_FILE=/etc/homelab/restic-password`. The systemd timer runs
daily; verification uses `restic check --read-data-subset=1/20` and a restore
into a temporary directory. Restore never overwrites live state.
