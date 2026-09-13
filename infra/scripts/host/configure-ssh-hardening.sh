#!/usr/bin/env bash
set -Eeuo pipefail

# Safely harden the existing SSH service while retaining password login.
# Port 22 and password authentication remain enabled because authorized_keys
# recovery is not yet configured. The script validates before reload and never
# disconnects existing sessions. Safe to rerun. Rollback is documented below.
#
# Rollback:
#   sudo rm -f /etc/ssh/sshd_config.d/99-homelab-hardening.conf
#   sudo systemctl reload ssh
# If a pre-existing file was backed up by this script, restore it first from
# `/etc/ssh/sshd_config.d/99-homelab-hardening.conf.pre-change`.

readonly DROPIN=/etc/ssh/sshd_config.d/99-homelab-hardening.conf
readonly BACKUP=/etc/ssh/sshd_config.d/99-homelab-hardening.conf.pre-change
readonly TMP_CONFIG=$(mktemp)
trap 'rm -f "$TMP_CONFIG"' EXIT

step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run through sudo from a trusted host terminal'
for command_name in sshd systemctl install cp mktemp; do
    command -v "$command_name" >/dev/null || fail "missing command: $command_name"
done
[[ -f /etc/ssh/sshd_config ]] || fail 'main sshd_config is missing'
systemctl is-active --quiet ssh || fail 'ssh service is not active; refusing to change its configuration'

step 'Prepare SSH hardening drop-in'
if [[ -e "$DROPIN" && ! -e "$BACKUP" ]]; then
    cp -a "$DROPIN" "$BACKUP"
    printf 'Backed up existing drop-in to %s\n' "$BACKUP"
fi
cat >"$TMP_CONFIG" <<'CONFIG'
# Managed by homelab-platform Phase B. Password authentication remains enabled
# until authorized_keys recovery has been configured and tested.
Port 22
PermitRootLogin no
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
AllowAgentForwarding no
MaxAuthTries 3
LoginGraceTime 20
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
CONFIG
install -m 0644 "$TMP_CONFIG" "$DROPIN"

step 'Validate SSH configuration before reload'
sshd -t || fail 'sshd -t rejected the new configuration'
effective="$(sshd -T)"
for expected in \
    'port 22' \
    'permitrootlogin no' \
    'passwordauthentication yes' \
    'kbdinteractiveauthentication yes' \
    'pubkeyauthentication yes' \
    'x11forwarding no' \
    'allowtcpforwarding no' \
    'gatewayports no' \
    'permittunnel no' \
    'allowagentforwarding no' \
    'maxauthtries 3' \
    'logingracetime 20' \
    'maxsessions 10' \
    'clientaliveinterval 300' \
    'clientalivecountmax 2'; do
    grep -Fxq "$expected" <<<"$effective" || fail "effective sshd setting missing: $expected"
done

step 'Reload SSH without dropping sessions'
systemctl reload ssh
systemctl is-active --quiet ssh || fail 'ssh service is not active after reload'
sshd -t
printf '%s\n' 'SSH hardening applied; password authentication remains enabled; existing sessions were not disconnected.'
