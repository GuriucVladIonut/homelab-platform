# Phase B — Host Remediation Checklist

This prepares the laptop on the fixed Ubuntu 22.04.5 LTS / 6.8.x baseline for later k3s installation. Ubuntu release migration is out of scope. It is not permission to execute the changes. Manual items require authenticated sudo or an explicit decision.

## Gate 1 — evidence and access

- [x] Capture live systemd, service, network, storage, package, and release evidence.
- [x] Confirm no k3s state exists.
- [ ] Run authenticated commands in `docs/manual-actions.md`.
- [ ] Identify every wildcard listener and confirm whether it is desktop-only.
- [ ] Confirm SSH key-based recovery from a second local/overlay path.

## Gate 2 — accepted same-disk/no-external-backup risk

- [x] Record explicit user acceptance: no external backup device, new disk, network storage, repartitioning, or personal-data relocation in this phase.
- [ ] Commit and push intended changes in both repositories.
- [ ] Capture safe local configuration/evidence; do not capture plaintext secrets.
- [ ] Do not create large same-disk personal-media archives for redundancy.
- [x] Verify at least 30 GiB free on the Ubuntu filesystem; approximately 140 GiB is currently available.
- [ ] Record recovery access and preserve user-created configuration files where appropriate.

This is not disaster recovery. Same-disk copies do not protect against physical disk failure. Future external backup remains recommended but is not a Phase B blocker.

## Gate 3 — host baseline changes

- [ ] Apply Jammy updates after package consistency is confirmed.
- [ ] Run `infra/scripts/host/configure-zram.sh` to configure persistent 5 GiB zram; no disk-backed swapfile is planned.
- [x] Run `infra/scripts/host/configure-k3s-prereqs.sh` for the required modules and sysctls only.
- [ ] Run `infra/scripts/host/configure-homelab-dirs.sh` to create the approved host directory hierarchy.
- [ ] Run `infra/scripts/host/configure-network-priorities.sh` with Ethernet 600, household Wi-Fi 400, and hotspot 200.
- [ ] Run `infra/scripts/host/configure-ssh-hardening.sh`; retain password authentication until authorized_keys recovery is configured.
- [ ] Define UFW policy and confirm nftables/iptables interaction before enabling.
- [ ] Harden SSH according to the documented policy; validate and retain recovery access.
- [ ] Set NetworkManager priorities: Ethernet `600`, household Wi-Fi `400`, hotspot `200`.
- [ ] Configure power behavior, time synchronization, and `/srv/homelab` only after ownership review.

## Gate 4 — host foundation readiness

- [ ] Re-run failed-unit, firewall, socket, SMART, and thermal checks.
- [ ] Run `apt-get check`; confirm no holds or broken packages.
- [ ] Review/disable third-party repositories according to an explicit decision.
- [x] Record accepted supported baseline: Ubuntu 22.04.5 LTS / kernel 6.8.x; do not run `do-release-upgrade`.
- [ ] Confirm local safety capture and recovery access.

## Gate 5 — after upgrade

- [ ] Re-run the complete host audit.
- [ ] Confirm networking, SSH, firewall, storage, thermals, and systemd.
- [ ] Only then begin k3s prerequisites.
