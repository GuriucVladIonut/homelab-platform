# Implementation Status

## Host

The host foundation is DEPLOYED and was verified by the operator: zram, k3s
kernel prerequisites, directory layout, NetworkManager priorities, SSH
hardening, firewall, and reboot persistence. The fixed Ubuntu 22.04.5 baseline
is retained. The new recovery scripts are READY_FOR_EXECUTION because Codex
cannot access root-only host paths.

## Kubernetes and GitOps

`30-install-k3s.sh` installs a pinned official k3s binary using its published checksum, systemd lifecycle, local-path storage, CoreDNS, metrics-server, ServiceLB, and explicit disablement for both bundled Traefik chart names. `31-install-kubernetes-tools.sh` installs pinned Helm/k9s artifacts with checksums; `35-install-standalone-kubectl.sh` prepares a matching upstream kubectl with checksum verification and leaves k3s untouched. `40-install-gitops-tools.sh` installs SOPS, age, and Flux clients without generating keys. k3s, Helm, k9s, SOPS, age, and Flux clients are DEPLOYED and validated by the operator; standalone kubectl is READY_FOR_EXECUTION. Flux bootstrap and GitHub SSH authentication are complete.

Traefik, cert-manager, and lightweight observability are deployed as pinned
Flux-managed Helm resources. The staging Cloudflare issuer and wildcard
certificate are VALIDATED; production ACME and public DNS remain disabled.
Grafana, Prometheus, kube-state-metrics, and node-exporter use conservative
resources and seven-day retention. Phase G adds bounded platform alert rules,
private Grafana and Prometheus routes, and no external notification channel.
Loki/Alloy and OpenSearch are not enabled.

## Applications and storage

`apps/homelab-control` is DEPLOYED outside Kubernetes as a standard-library Go loopback service under the non-root `homelab-control` account. Phase F dashboard code now exposes host telemetry, k3s controls, bounded Kubernetes summaries, private endpoint state, Prometheus target/alert summaries, storage, and an explicit backup-not-configured state. It has CSRF, POST-only state changes, confirmation for stop/restart, HTML escaping, security headers, and a fixed sudo helper boundary. Kubernetes reads use Git-managed get/list/watch-only RBAC and a root-owned mode-0640 reader kubeconfig. `apps/catalog` is OPTIONAL_DISABLED source and schema for PostgreSQL metadata/audit only; media remains on host storage and physical deletion is not implemented in the baseline. Samba is an optional disabled package foundation with no accounts, passwords, or shares.

## DNS and secrets

`infra/config/endpoints.yaml` is the canonical private endpoint registry. No
public RFC1918 records are created. `.sops.yaml` and the Cloudflare token are
SOPS/age encrypted; the age private key remains out-of-band. Existing
Cloudflare resources are untouched.

## Update, rollback, and backup

Version files are the update inputs; installers verify upstream checksums. Host scripts document rollback. Same-disk restic design is operational rollback only, not disaster recovery. No personal media is copied or moved by this pass.

## Phase F/G completion pass

The platform is `IMPLEMENTED_IN_REPO` for the host-control dashboard,
read-only Kubernetes adapter, private observability routes, alert baseline, and
stricter recovery validator. The reader kubeconfig installation is
`READY_FOR_EXECUTION` through `51-install-homelab-control-reader.sh`. Live UI,
Prometheus API, Flux, and alert validation requires the operator host because
Codex cannot access the host sudo/API credential boundary.

## Phase H/I preparation

The restic baseline is `READY_FOR_EXECUTION`; it is same-disk operational
rollback and **NOT DISASTER RECOVERY**. It excludes media and transient runtime
data, uses seven daily/four weekly/three monthly retention, and provides a
temporary restore validator. The password remains outside Git in a root-only
file. The canonical `/srv/homelab/data` tree is prepared by a separate script;
Samba remains `OPTIONAL_DISABLED`. PostgreSQL/catalog remains disabled until
backup installation and temporary restore validation are complete.
