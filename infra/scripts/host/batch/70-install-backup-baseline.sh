#!/usr/bin/env bash
set -Eeuo pipefail

# Same-disk operational backups. THIS IS NOT DISASTER RECOVERY.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
for command_name in apt-get systemctl install mkdir getent; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
command -v restic >/dev/null || apt-get install --yes restic
command -v sqlite3 >/dev/null || apt-get install --yes sqlite3
getent group homelab-control >/dev/null || fail 'homelab-control group is required'
install -d -o root -g root -m 0700 /etc/homelab /srv/homelab/backups/restic /srv/homelab/backups/k3s /srv/homelab/backups/db /srv/homelab/backups/logs
install -d -o root -g homelab-control -m 0750 /var/lib/homelab-backup
if [[ ! -r /etc/homelab/restic.env ]]; then
  printf '%s\n' 'No /etc/homelab/restic.env found; create it manually before the first backup.'
else
  source /etc/homelab/restic.env
  [[ -n ${RESTIC_REPOSITORY:-} && -n ${RESTIC_PASSWORD_FILE:-} ]] || fail 'restic.env is missing required variables'
  [[ -r $RESTIC_PASSWORD_FILE ]] || fail 'RESTIC_PASSWORD_FILE is not readable'
  export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE
  if ! restic snapshots >/dev/null 2>&1; then restic init; fi
fi
install -m 0750 -o root -g root /dev/stdin /usr/local/sbin/homelab-k3s-snapshot <<'SNAPSHOT'
#!/usr/bin/env bash
set -Eeuo pipefail
out_dir=/srv/homelab/backups/k3s
install -d -o root -g root -m 0700 "$out_dir"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
if [[ -f /var/lib/rancher/k3s/server/db/state.db ]]; then
  output="$out_dir/k3s-sqlite-$timestamp.db"
  sqlite3 /var/lib/rancher/k3s/server/db/state.db ".backup '$output'"
elif [[ -x /usr/local/bin/k3s && -d /var/lib/rancher/k3s/server/db/etcd ]]; then
  /usr/local/bin/k3s etcd-snapshot save --etcd-snapshot-dir "$out_dir" --name "k3s-etcd-$timestamp"
  output=$(find "$out_dir" -maxdepth 1 -type f -name "*k3s-etcd-$timestamp*" -print -quit)
else
  printf '%s\n' 'No supported k3s datastore found.' >&2
  exit 1
fi
[[ -s "$output" ]] || { printf '%s\n' 'k3s snapshot is empty.' >&2; exit 1; }
ln -sfn "$output" "$out_dir/latest"
printf '%s\n' "$output"
SNAPSHOT
install -m 0750 -o root -g root /dev/stdin /usr/local/sbin/homelab-backup <<'BACKUP'
#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
status=/var/lib/homelab-backup/status.env
write_status() { install -d -o root -g homelab-control -m 0750 /var/lib/homelab-backup; { printf 'STATE=%s\n' "$1"; printf 'LAST_BACKUP=%s\n' "${2:-}"; printf 'LAST_VERIFICATION=%s\n' "${3:-}"; printf 'LATEST_K3S_SNAPSHOT=%s\n' "${4:-}"; printf 'REPOSITORY=%s\n' "${RESTIC_REPOSITORY:-NOT_CONFIGURED}"; printf 'LAST_ERROR=%s\n' "${5:-NONE}"; printf 'NEXT_RUN=systemd timer\n'; } >"$status"; chown root:homelab-control "$status"; chmod 0640 "$status"; }
if [[ ! -r /etc/homelab/restic.env ]]; then write_status NOT_CONFIGURED '' '' '' 'missing restic.env'; exit 1; fi
source /etc/homelab/restic.env
[[ -n ${RESTIC_REPOSITORY:-} && -n ${RESTIC_PASSWORD_FILE:-} ]] || { write_status NOT_CONFIGURED '' '' '' 'missing restic variables'; exit 1; }
[[ -r $RESTIC_PASSWORD_FILE ]] || { write_status NOT_CONFIGURED '' '' '' 'missing restic password file'; exit 1; }
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE
db_dump=/srv/homelab/backups/db
if command -v kubectl >/dev/null && KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n database get statefulset postgresql >/dev/null 2>&1; then
  pod=$(KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n database get pod -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')
  [[ -n $pod ]] || { write_status FAILED '' '' '' 'postgresql pod not available for dump'; exit 1; }
  stamp=$(date -u +%Y%m%dT%H%M%SZ)
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n database exec "$pod" -- sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=plain --no-owner --no-privileges' >"$db_dump/homelab-$stamp.sql"
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n database exec "$pod" -- sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --schema-only --no-owner --no-privileges' >"$db_dump/homelab-schema-$stamp.sql"
  chmod 0600 "$db_dump"/*.sql
fi
snapshot=$(/usr/local/sbin/homelab-k3s-snapshot)
sources=(/etc/rancher/k3s/config.yaml /etc/rancher/k3s/config.yaml.d /opt/homelab /srv/homelab/volumes/apps /srv/homelab/volumes/observability /srv/homelab/backups/k3s /srv/homelab/backups/db)
last=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if ! restic backup --tag homelab-config --exclude='*.cache*' --exclude='/srv/homelab/backups/restic' "${sources[@]}"; then write_status FAILED "$last" '' "$snapshot" 'restic backup failed'; exit 1; fi
restic forget --tag homelab-config --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
write_status OK "$last" '' "$snapshot" NONE
BACKUP
install -m 0750 -o root -g root /dev/stdin /usr/local/sbin/homelab-backup-verify <<'VERIFY'
#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/homelab/restic.env
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE
restic check --read-data-subset=1/20
status=/var/lib/homelab-backup/status.env
if [[ -r $status ]]; then sed -i "s/^LAST_VERIFICATION=.*/LAST_VERIFICATION=$(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$status"; fi
VERIFY
install -m 0644 -o root -g root /dev/stdin /etc/systemd/system/homelab-backup.service <<'UNIT'
[Unit]
Description=Homelab same-disk operational backup
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/homelab-backup
UNIT
install -m 0644 -o root -g root /dev/stdin /etc/systemd/system/homelab-backup.timer <<'UNIT'
[Unit]
Description=Daily homelab operational backup
[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
RandomizedDelaySec=15m
[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable homelab-backup.timer
systemctl start homelab-backup.timer
systemctl is-enabled --quiet homelab-backup.timer || fail 'backup timer is not enabled'
systemctl is-active --quiet homelab-backup.timer || fail 'backup timer is not active'
printf '%s\n' 'Backup baseline installed. THIS IS NOT DISASTER RECOVERY.'
