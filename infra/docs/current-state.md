# Current State — 2026-09-13

## Scope and evidence

This report is the Phase A reconciliation baseline. Evidence sources are the local filesystem, Git metadata, installed command lookup, Debian package database, and read-only host commands executed on 2026-09-13. Privileged systemd, netlink, and firewall queries failed in the execution sandbox with `Operation not permitted`; those values are explicitly unverified.

The Phase B execution attempt on 2026-09-13 was blocked again. The container rejects `sudo` because `no_new_privileges` is set and `/etc/sudo.conf` is not root-owned. Host-level escalation reached a sudo password prompt, but this execution interface cannot provide interactive credentials. No host mutation or reboot was performed.

## Repository boundary

`git -C /home/jamal/Documents/homelab/homelab-platform rev-parse --show-toplevel` returns `/home/jamal/Documents/homelab/homelab-platform`.

Nested Git repositories detected:

- `/home/jamal/Documents/homelab/.git` — workspace-level repository.
- `/home/jamal/Documents/homelab/homelab-platform/.git` — platform repository; authoritative executable repository.
- `/home/jamal/Documents/homelab/Obsidian/moreBrain/.git` — documentation/knowledge repository.

The platform repository tracks one initial commit, `5c76180 first commit`, and has remote `origin` configured. Its current pre-existing worktree state is an untracked `infra/scripts/inventory/phase-00-preflight.sh`. No existing tracked work was overwritten.

## Repository contents

The platform repository currently contains documentation, empty directory contracts, and shell validation/inventory scripts. It contains no Kubernetes YAML, Helm values, Flux resources, OpenTofu, systemd units, Go source, application source, CI workflow, or encrypted secret document.

The Obsidian homelab area contains architecture, roadmap, ADR, runbook, component, troubleshooting, learning, template, and inventory notes. Its existing user edits to `HL-Roadmap.md` and `.obsidian/workspace.json` were preserved.

## Live host

Verified:

| Area | Evidence |
|---|---|
| OS | Ubuntu 22.04.5 LTS, `VERSION_ID=22.04` |
| Kernel | `6.8.0-65-generic`, x86_64 |
| Memory | 15 GiB visible; 11 GiB available at inspection time |
| Swap | None active; `0B` |
| Root filesystem | `/dev/sda6`, ext4, 196G total, 139G available, 26% used |
| Physical disk | `/dev/sda`, 894.3G, ADATA SU650; Windows NTFS partitions remain present |
| k3s binary | Not found |
| Kubernetes paths | `/etc/rancher`, `/var/lib/rancher`, `/etc/kubernetes`, `/var/lib/kubelet` absent |
| Diagnostics installed | `iw`, `lm-sensors`, `smartmontools` packages present |
| Kubernetes/GitOps tooling | `kubectl`, `helm`, `k9s`, `flux`, `sops`, `age`, `restic` not found |
| VM tooling | `virsh`, `qemu-system-x86_64` not found |
| Quality/security tooling | `shellcheck`, `shfmt`, `yamllint`, `kubeconform`, `trivy`, `gitleaks` not found |
| Host packages observed | NetworkManager, OpenSSH server, UFW, smartmontools, lm-sensors, iw |

Not verifiable from this sandbox:

- active/enabled systemd services;
- current failed units;
- NetworkManager device/profile state and default route;
- UFW ruleset;
- listening sockets;
- SMART data and temperatures;
- Docker, containerd, MySQL, RabbitMQ, and SSH runtime state.

The historical 2026-08-11 inventory remains useful context but is not treated as live evidence.

## Privileged verification — 2026-09-13

### Systemd and legacy services

- `systemctl --failed`: 0 loaded failed units.
- `ssh.service`: enabled and active/running.
- `NetworkManager.service`: enabled and active/running.
- `logrotate.service`: loaded/static and inactive, which is expected for a timer-triggered service; it is not failed.
- Docker, containerd, MySQL, and RabbitMQ unit files were not found and are inactive/not installed as systemd services.

### Listening sockets

- SSH listens on TCP port 22 on all IPv4 and IPv6 addresses.
- systemd-resolved stub DNS listens on loopback only.
- CUPS listens on loopback only.
- UDP listeners include mDNS and an additional non-identified listener; ownership requires a follow-up process-aware inspection.

### Firewall

UFW, nftables, iptables, and ip6tables rulesets could not be read because the trusted shell still requires an interactive sudo password. Firewall state is therefore **UNVERIFIED**, not assumed inactive or secure.

### NetworkManager, routes, and DNS

- NetworkManager: connected with full reported connectivity; Wi-Fi hardware and Wi-Fi are enabled.
- Active interface: `wlp3s0` over Wi-Fi; Ethernet `enp2s0` is unavailable.
- Multiple saved Wi-Fi profiles are set to autoconnect with default priority `0`.
- Wired profile `Wired connection 1` is set to autoconnect priority `-999`, which does not implement the intended Ethernet-first policy.
- A WireGuard profile `eduVPN` exists but is not set to autoconnect.
- The active route is DHCP IPv4 with metric `600` and an IPv6 router-advertised default route over Wi-Fi.
- DNS is provided by the current LAN router through systemd-resolved; resolved uses a loopback stub and does not enable DNSSEC or DNS-over-TLS.
- Raw addresses, SSIDs, UUIDs, and machine identifiers are intentionally excluded from committed documentation.

### Memory, swap, and zram

- No swap devices are active.
- `/proc/swaps` is empty.
- `systemd-zram-setup@zram0.service` does not exist.
- `vm.swappiness` is `60`.

### Storage and SMART

- `/dev/sda`: ADATA SU650, approximately 894 GiB, non-rotational SATA SSD.
- Ubuntu root: `/dev/sda6`, ext4, approximately 196 GiB total, 139 GiB available, 24–26% used.
- EFI system partition: approximately 96 MiB.
- Two large NTFS partitions and one NTFS recovery partition remain on the same disk.
- An optical medium is mounted under `/media`; it is full by design and is not homelab storage.
- SMART health/attributes could not be read because `smartctl` requires root and sudo authentication was unavailable.

### Temperatures

Current sensor readout is within normal idle range: CPU package approximately 57°C, cores approximately 45–57°C, ACPI approximately 43°C, platform sensors approximately 36°C, and CPU fan approximately 2600 RPM. Two JC42 sensors report placeholder `0°C` high/critical thresholds and `ALARM`; these thresholds are sensor metadata anomalies, not measured over-temperature events.

### Kernel modules and sysctls

- `overlay`, `br_netfilter`, `vxlan`, and `nf_conntrack` are available as modules but not loaded.
- `ip_tables` is loaded; `ip6_tables` is not loaded.
- `net.ipv4.ip_forward=0` and `net.ipv6.conf.all.forwarding=0`.
- Bridge netfilter and conntrack sysctls are absent because the corresponding modules are not loaded.
- `vm.swappiness=60`.
- `fs.inotify.max_user_instances=128` and `fs.inotify.max_user_watches=65536`.

This is acceptable before k3s installation but not yet a validated k3s prerequisite state.

### SSH

- `sshd_config` includes `/etc/ssh/sshd_config.d/*.conf`; no drop-in files currently exist.
- The base configuration leaves several security settings at package defaults, including password authentication, root-login policy, X11 forwarding, and TCP forwarding; effective `sshd -T` output could not be obtained in this context.
- Runtime exposure is confirmed on `0.0.0.0:22` and `[::]:22`.

### Packages and Ubuntu release readiness

- `dpkg --audit` returned clean.
- No package holds were reported by `apt-mark showhold`.
- `apt-get check` could not run because it requires the dpkg frontend lock and sudo authentication.
- A third-party eduVPN Jammy repository is enabled and must be reviewed for upgrade compatibility.
- `do-release-upgrade -c` reports Ubuntu `24.04.5 LTS` available.

Supported host baseline is explicitly fixed at Ubuntu 22.04.5 LTS with the 6.8.x kernel line. Ubuntu 24.04 migration is removed from the active implementation path and must not be run. The user explicitly accepts the risk that no external backup device or second physical disk is available in this phase. Same-disk copies are not disaster recovery and do not protect against physical disk failure. Future backup capability remains recommended, but lack of external backup is not a Phase B blocker.

## Finding classification

| Finding | Classification | Required disposition |
|---|---|---|
| No failed systemd units | Safe | Preserve as a pre-change baseline |
| SSH and NetworkManager enabled/running | Safe | Keep; harden SSH before upgrade |
| Legacy Docker/containerd/MySQL/RabbitMQ units absent | Safe | Confirm no user workloads depend on them |
| SSH exposed on all IPv4/IPv6 addresses | Needs remediation; upgrade blocker | Restrict authentication and firewall exposure |
| Loopback-only resolved/CUPS listeners | Safe | Recheck after firewall changes |
| Spotify listeners on wildcard ports | Needs remediation | Confirm desktop-only scope; prevent unwanted LAN exposure |
| Wi-Fi active; Ethernet unavailable | Safe | Use for audit only; test priority changes later |
| Wired profile priority `-999` | Needs remediation | Set explicit uplink priorities |
| No swap/zram | Needs remediation | Add zram or swap before memory-sensitive platform work |
| Root ext4 has approximately 139 GiB free | Safe | Reserve capacity; do not use Windows partitions |
| SMART health unavailable | Needs remediation | Obtain authenticated SMART report |
| k3s modules available but unloaded | Safe before k3s | Load/configure during k3s host preparation |
| Forwarding and bridge sysctls not enabled | Safe before k3s | Configure only with k3s implementation |
| `dpkg --audit` clean; no holds | Safe | Recheck after authenticated apt check |
| `apt-get check` unavailable | Needs remediation | Run authenticated check |
| eduVPN third-party Jammy source enabled | Needs remediation | Review purpose; do not remove without approval |
| Ubuntu 24.04.5 offered | Safe but out of scope | Do not run `do-release-upgrade` |
| Firewall rules unavailable | Needs remediation | Obtain authenticated UFW/nftables/iptables reports |

## Swap/zram decision

Use zram initially, sized at approximately 25–50% of RAM, with a low-priority backing swapfile only if later workload measurements justify it. For this 16 GiB laptop, zram reduces SSD write pressure while protecting against short memory spikes. It is not additional capacity or a substitute for Kubernetes requests/limits.

## Proposed SSH policy — not applied

- Keep SSH reachable only on the private LAN and authenticated overlay; no public exposure.
- Keep `Port 22` initially to avoid unnecessary access risk during migration.
- `PermitRootLogin no`.
- `PasswordAuthentication no`.
- `KbdInteractiveAuthentication no`.
- `PubkeyAuthentication yes`.
- `AuthenticationMethods publickey`.
- `PermitEmptyPasswords no`.
- `X11Forwarding no`.
- `AllowTcpForwarding no` by default; document narrow exceptions.
- `GatewayPorts no`.
- `PermitTunnel no`.
- `AllowAgentForwarding no` unless required.
- `MaxAuthTries 3`, `LoginGraceTime 20s`, `MaxSessions 10`.
- `ClientAliveInterval 300`, `ClientAliveCountMax 2`.
- Use `AllowGroups ssh-admin` only after membership and recovery access are verified.
- Validate with `sshd -t` and `sshd -T` before restart; retain an existing session during testing.

## Proposed NetworkManager priorities — not applied

```text
Ethernet profile:          600
Household Wi-Fi profiles:  400
Phone hotspot profile:     200
Other/temporary profiles:    0 or lower
eduVPN WireGuard:            0, autoconnect disabled
```

Exact profile names must be confirmed before applying changes. All household Wi-Fi profiles receive the same class priority; the hotspot profile must be identified explicitly.

## Upgrade safety without external backup

The user has accepted the following risk for the current phase:

- No external backup device, new SSD/HDD, network storage, repartitioning, or personal-data relocation will be introduced.
- The current physical disk, partition table, Windows/NTFS partitions, and filesystem layout remain unchanged.
- Same-disk copies do not protect against physical disk failure, theft, or total filesystem loss.
- This is **not disaster recovery**.
- Future external or network-backed backup capability remains recommended, but is not a Phase B blocker.

Ubuntu release migration is not an active operation. Local safety measures are limited to configuration/evidence capture and repository commits. Do not create archives of large personal media/data merely to duplicate them on the same disk.

Required local capture:

- Commit and push intended repository changes.
- Snapshot safe configuration into the technical repository without secrets.
- Record installed packages, apt sources, enabled services, NetworkManager metadata, SSH configuration, mounts/fstab, kernel/boot configuration, partition layout, and SMART summary.
- Preserve user-created configuration files where appropriate.
- Verify at least 30 GiB free on the Ubuntu filesystem; current observed free space is approximately 140 GiB.
- Ensure no Windows/NTFS partition is modified.

## Recommended host-change order

1. Commit and push intended repository changes; capture safe local configuration and evidence.
2. Complete privileged package, firewall, SMART, and SSH effective-state verification.
3. Inventory and decide the fate of the eduVPN repository/profile and any non-package listeners.
4. Review current Ubuntu release notes and third-party software compatibility.
5. Apply all available Jammy updates and resolve any package inconsistency.
6. Configure swap or zram with a documented memory policy.
7. Harden SSH and restrict its exposure through the host firewall.
8. Configure NetworkManager priorities: Ethernet first, household Wi-Fi second, hotspot third.
9. Reboot and validate clean systemd state, networking, SSH, storage, and recovery access.
10. Keep Ubuntu on the supported 22.04.5 LTS / 6.8.x baseline.
11. Re-run the full audit before installing k3s.

## Reconciled status

```text
Host OS:                 Ubuntu 22.04.5 LTS; remediation not verified complete
Kubernetes:              not installed/detected
GitOps:                  not installed/detected
Ingress/TLS/DNS:        design only
Observability:           design only
Backups:                 not implemented
Remote overlay:          proposed only
Control UI:              not implemented
Data catalog/PostgreSQL: not implemented
Cyber range:             not implemented
```

The Obsidian roadmap marks several discovery activities complete, while the dashboard and phase timeline still describe Phase 0 as active. The authoritative interpretation is that discovery artifacts exist but host foundation completion has not been proven by current evidence.

## Stale documentation reconciled

- `homelab-platform` is now documented as the Git root.
- `homelab-platform/infra` is documented as the current implementation subtree.
- “Future infrastructure repository” wording is obsolete; the repository exists.
- Planned components are not represented as installed components.
- The historical inventory date is retained as historical, not current host state.

## Phase B execution status

**BLOCKED — not complete.** The requested authenticated verification and all host mutations remain outstanding. Do not report the host foundation as ready and do not install k3s until the commands in `docs/manual-actions.md`, the Phase B changes, reboot, and post-reboot validation have completed in a trusted host terminal.

## Phase A conclusion

No deployment should begin until privileged host inspection is re-run outside the sandbox or by an equivalent trusted host context. The next implementation phase is host foundation, beginning with non-destructive verification and backup planning.
