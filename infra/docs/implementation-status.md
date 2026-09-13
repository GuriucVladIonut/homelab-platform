# Implementation Status

## Host

The host scripts in `infra/scripts/host/` are READY_FOR_EXECUTION and are intentionally separate from repository changes. Verified host changes already deployed are zram, k3s kernel prerequisites, directory layout, NetworkManager priorities, and SSH hardening. Firewall activation and the reboot persistence gate remain pending. The fixed Ubuntu 22.04.5 baseline is retained.

## Kubernetes and GitOps

`30-install-k3s.sh` installs a pinned official k3s binary using its published checksum, systemd lifecycle, local-path storage, CoreDNS, metrics-server, ServiceLB, and explicit Traefik disablement. `31-install-kubernetes-tools.sh` installs pinned Helm/k9s artifacts with checksums; kubectl remains k3s-provided. `40-install-gitops-tools.sh` installs SOPS, age, and Flux clients without generating keys. k3s, Helm, and k9s are now DEPLOYED and validated by the operator; GitOps clients remain READY_FOR_EXECUTION.

Traefik, cert-manager, and lightweight observability are represented as pinned Flux-compatible Helm resources. The cert-manager issuer is intentionally gated until CF-001 and an encrypted token exist. Grafana, Prometheus, kube-state-metrics, and node-exporter use conservative resources and seven-day retention. Loki/Alloy and OpenSearch are not enabled.

## Applications and storage

`apps/homelab-control` is a standard-library Go loopback service with CSRF, POST-only state changes, confirmation for stop/restart, HTML escaping, security headers, and a fixed sudo helper boundary. `apps/catalog` is OPTIONAL_DISABLED source and schema for PostgreSQL metadata/audit only; media remains on host storage and physical deletion is not implemented in the baseline. Samba is an optional disabled package foundation with no accounts, passwords, or shares.

## DNS and secrets

`infra/config/endpoints.yaml` is the canonical private endpoint registry. No public RFC1918 records are created. `.sops.yaml` and workflow documentation are prepared, but the recipient and Cloudflare secret remain external/manual. Existing Cloudflare resources are untouched.

## Update, rollback, and backup

Version files are the update inputs; installers verify upstream checksums. Host scripts document rollback. Same-disk restic design is operational rollback only, not disaster recovery. No personal media is copied or moved by this pass.
