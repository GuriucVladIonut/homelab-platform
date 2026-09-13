#!/usr/bin/env bash
set -Eeuo pipefail
# Installs loopback-only control UI plus a fixed root helper.
# Rollback: disable service, remove service/sudoers/helper/binary, then delete the account.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../../" && pwd)"
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
for command_name in go systemctl visudo useradd groupadd getent id install ss; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
[[ -f "$ROOT_DIR/apps/homelab-control/go.mod" ]] || fail 'control source missing'
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
step 'Build application'
(cd "$ROOT_DIR/apps/homelab-control" && go build -trimpath -o "$tmpdir/homelab-control" .)
step 'Create locked account and binary'
getent group homelab-control >/dev/null || groupadd --system homelab-control
id homelab-control >/dev/null 2>&1 || useradd --system --gid homelab-control --home-dir /nonexistent --shell /usr/sbin/nologin homelab-control
install -d -o root -g root -m 0755 /opt/homelab/control
install -m 0755 -o root -g root "$tmpdir/homelab-control" /opt/homelab/control/homelab-control
step 'Install fixed helper and exact sudo policy'
install -m 0755 -o root -g root /dev/stdin /usr/local/sbin/homelab-control-helper <<'HELPER'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$(id -u)" -eq 0 ]] || exit 1
case "${1:-}" in
 status) systemctl status --no-pager k3s ;; start) systemctl start k3s ;; stop) systemctl stop k3s ;; restart) systemctl restart k3s ;; autostart-enable) systemctl enable k3s ;; autostart-disable) systemctl disable k3s ;; *) exit 64 ;;
esac
HELPER
install -m 0440 -o root -g root /dev/stdin /etc/sudoers.d/homelab-control <<'SUDOERS'
Cmnd_Alias HOMELAB_CONTROL = /usr/local/sbin/homelab-control-helper status, /usr/local/sbin/homelab-control-helper start, /usr/local/sbin/homelab-control-helper stop, /usr/local/sbin/homelab-control-helper restart, /usr/local/sbin/homelab-control-helper autostart-enable, /usr/local/sbin/homelab-control-helper autostart-disable
homelab-control ALL=(root) NOPASSWD: HOMELAB_CONTROL
SUDOERS
visudo -cf /etc/sudoers.d/homelab-control
step 'Install service'
install -m 0644 -o root -g root /dev/stdin /etc/systemd/system/homelab-control.service <<'UNIT'
[Unit]
Description=Homelab host control UI
After=network-online.target
[Service]
User=homelab-control
Group=homelab-control
ExecStart=/opt/homelab/control/homelab-control -listen 127.0.0.1:8090 -endpoints /opt/homelab/control/endpoints.yaml
Restart=on-failure
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/homelab-control
[Install]
WantedBy=multi-user.target
UNIT
install -d -o homelab-control -g homelab-control -m 0750 /var/lib/homelab-control
install -m 0640 -o root -g homelab-control "$ROOT_DIR/infra/config/endpoints.yaml" /opt/homelab/control/endpoints.yaml
systemctl daemon-reload
systemctl enable --now homelab-control
step 'Validate'
systemctl is-active --quiet homelab-control || fail 'service inactive'
ss -lnt | grep -Eq '127\.0\.0\.1:8090' || fail 'service is not loopback-bound'
printf '%s\n' 'Control service installed outside Kubernetes and bound to loopback.'
