# Phase B — SSH Hardening

[`configure-ssh-hardening.sh`](../scripts/host/configure-ssh-hardening.sh) installs `/etc/ssh/sshd_config.d/99-homelab-hardening.conf`, validates with `sshd -t` and `sshd -T`, then reloads the active SSH service.

Password authentication and keyboard-interactive authentication intentionally remain enabled until `authorized_keys` recovery is configured and tested. Port 22 is retained. Root login, X11 forwarding, agent forwarding, TCP forwarding, gateway ports, and tunnels are disabled; connection/session limits are conservative.

## Rollback

```bash
sudo rm -f /etc/ssh/sshd_config.d/99-homelab-hardening.conf
sudo mv /etc/ssh/sshd_config.d/99-homelab-hardening.conf.pre-change \
  /etc/ssh/sshd_config.d/99-homelab-hardening.conf 2>/dev/null || true
sudo sshd -t
sudo systemctl reload ssh
```

Do not close the existing recovery session until `sshd -t` and the reload succeed.
