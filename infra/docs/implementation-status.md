# Implementation Status

## Host

The host foundation is DEPLOYED and was verified by the operator: zram, k3s
kernel prerequisites, directory layout, NetworkManager priorities, SSH
hardening, firewall, and reboot persistence. The fixed Ubuntu 22.04.5 baseline
is retained. The new recovery scripts are READY_FOR_EXECUTION because Codex
cannot access root-only host paths.

## Kubernetes and GitOps

`30-install-k3s.sh` installs a pinned official k3s binary using its published checksum, systemd lifecycle, local-path storage, CoreDNS, metrics-server, ServiceLB, and explicit disablement for both bundled Traefik chart names. `31-install-kubernetes-tools.sh` installs pinned Helm/k9s artifacts with checksums; kubectl remains k3s-provided. `40-install-gitops-tools.sh` installs SOPS, age, and Flux clients without generating keys. k3s, Helm, k9s, SOPS, age, and Flux clients are DEPLOYED and validated by the operator. Flux bootstrap and GitHub SSH authentication are complete.

Traefik, cert-manager, and lightweight observability are deployed as pinned
Flux-managed Helm resources. The staging Cloudflare issuer and wildcard
certificate are VALIDATED; production ACME and public DNS remain disabled.
Grafana, Prometheus, kube-state-metrics, and node-exporter use conservative
resources and seven-day retention. Loki/Alloy and OpenSearch are not enabled.

## Applications and storage

`apps/homelab-control` is DEPLOYED outside Kubernetes as a standard-library Go loopback service under the non-root `homelab-control` account. It has CSRF, POST-only state changes, confirmation for stop/restart, HTML escaping, security headers, and a fixed sudo helper boundary; the operator verified it active on `127.0.0.1:8090`. `apps/catalog` is OPTIONAL_DISABLED source and schema for PostgreSQL metadata/audit only; media remains on host storage and physical deletion is not implemented in the baseline. Samba is an optional disabled package foundation with no accounts, passwords, or shares.

## DNS and secrets

`infra/config/endpoints.yaml` is the canonical private endpoint registry. No
public RFC1918 records are created. `.sops.yaml` and the Cloudflare token are
SOPS/age encrypted; the age private key remains out-of-band. Existing
Cloudflare resources are untouched.

## Update, rollback, and backup

Version files are the update inputs; installers verify upstream checksums. Host scripts document rollback. Same-disk restic design is operational rollback only, not disaster recovery. No personal media is copied or moved by this pass.

## Current recovery pass

The platform is `IMPLEMENTED_IN_REPO` for the remaining recovery work. A
GitOps node-exporter bind/resource fix and a disposable private HTTPS demo MVP
are prepared. Host-side Traefik ownership cleanup and the operator kubeconfig
copy are `READY_FOR_EXECUTION` through narrowly scoped scripts. Live validation
is pending those manual root commands because Codex cannot access the host
sudo/API credential boundary.
