# Phase B — Host Directory Layout

The host foundation creates these directories:

```text
/srv/homelab/volumes/{databases,apps,media,observability}
/srv/homelab/{backups,lab,cache}
/opt/homelab/{bootstrap,scripts}
```

[`configure-homelab-dirs.sh`](../scripts/host/configure-homelab-dirs.sh) creates missing directories and applies conservative root ownership. `/srv/homelab` and `/opt/homelab` are `0755`; subordinate directories are `0750`; backups are `0700`. It does not recursively chown, modify, or delete existing content.

## Rollback / removal

Review contents first, then remove only empty directories in reverse order:

```bash
sudo rmdir /opt/homelab/scripts /opt/homelab/bootstrap /opt/homelab \
  /srv/homelab/cache /srv/homelab/lab /srv/homelab/backups \
  /srv/homelab/volumes/observability /srv/homelab/volumes/media \
  /srv/homelab/volumes/apps /srv/homelab/volumes/databases \
  /srv/homelab/volumes /srv/homelab
```

`rmdir` refuses to remove non-empty directories, so it does not delete data.
