# Current State — 2026-09-13

## Scope and evidence

This report is the Phase A reconciliation baseline. Evidence sources are the local filesystem, Git metadata, installed command lookup, Debian package database, and read-only host commands executed on 2026-09-13. Privileged systemd, netlink, and firewall queries failed in the execution sandbox with `Operation not permitted`; those values are explicitly unverified.

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

## Phase A conclusion

No deployment should begin until privileged host inspection is re-run outside the sandbox or by an equivalent trusted host context. The next implementation phase is host foundation, beginning with non-destructive verification and backup planning.
