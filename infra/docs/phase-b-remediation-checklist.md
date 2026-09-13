# Phase B — Host Remediation Checklist

This prepares the laptop for Ubuntu 24.04 and later k3s installation. It is not permission to execute the changes. Manual items require authenticated sudo or an explicit decision.

## Gate 1 — evidence and access

- [x] Capture live systemd, service, network, storage, package, and release evidence.
- [x] Confirm no k3s state exists.
- [ ] Run authenticated commands in `docs/manual-actions.md`.
- [ ] Identify every wildcard listener and confirm whether it is desktop-only.
- [ ] Confirm SSH key-based recovery from a second local/overlay path.

## Gate 2 — backup

- [ ] Select an external backup target; it must not be `/dev/sda`.
- [ ] Back up personal data, both repositories, SSH access, `/etc`, package inventory, mounts, and recovery metadata.
- [ ] Verify restoration of representative files and repository history.

## Gate 3 — host baseline changes

- [ ] Apply Jammy updates after package consistency is confirmed.
- [ ] Configure zram; add low-priority swapfile only if measurements require it.
- [ ] Define UFW policy and confirm nftables/iptables interaction before enabling.
- [ ] Harden SSH according to the documented policy; validate and retain recovery access.
- [ ] Set NetworkManager priorities: Ethernet `600`, household Wi-Fi `400`, hotspot `200`.
- [ ] Configure power behavior, time synchronization, and `/srv/homelab` only after ownership review.

## Gate 4 — upgrade readiness

- [ ] Re-run failed-unit, firewall, socket, SMART, and thermal checks.
- [ ] Run `apt-get check`; confirm no holds or broken packages.
- [ ] Review/disable third-party repositories according to an explicit decision.
- [ ] Confirm `do-release-upgrade -c`, backup status, and recovery access.

## Gate 5 — after upgrade

- [ ] Re-run the complete host audit.
- [ ] Confirm networking, SSH, firewall, storage, thermals, and systemd.
- [ ] Only then begin k3s prerequisites.
