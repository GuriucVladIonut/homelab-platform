# Execution Batch Runbook

All commands below are run from `~/Documents/homelab/homelab-platform`, in order. Stop on the first failure and preserve its output. These scripts are reviewed but not executed by Codex. No script performs an Ubuntu release upgrade, repartitioning, public exposure, or deletion of personal data.

## Batch 1 — finish host foundation

```bash
sudo ./infra/scripts/host/batch/00-preflight.sh
sudo ./infra/scripts/host/batch/10-configure-firewall.sh
sudo ./infra/scripts/host/batch/20-phase-b-validation.sh
sudo reboot
```

The reboot is a separate manual gate. After login, confirm SSH and networking before continuing.

## Batch 2 — after reboot

```bash
sudo ./infra/scripts/host/batch/00-preflight.sh
sudo ./infra/scripts/host/batch/20-phase-b-validation.sh
sudo ./infra/scripts/host/batch/30-install-k3s.sh
sudo ./infra/scripts/host/batch/31-install-kubernetes-tools.sh
sudo ./infra/scripts/host/batch/32-validate-k3s.sh
```

This makes k3s, CoreDNS, metrics-server, local-path storage, Helm, and k9s live. Traefik is explicitly disabled in k3s and is not live until Flux applies its HelmRelease.

## Batch 3 — GitOps and control application

```bash
sudo ./infra/scripts/host/batch/40-install-gitops-tools.sh
sudo ./infra/scripts/host/batch/50-install-homelab-control.sh
```

Flux clients and the loopback-only host control service become available. Flux bootstrap itself remains manual until GitHub authentication is complete.

## POC/MVP test gates

The host and Kubernetes POC is already testable: the operator has verified the k3s node, CoreDNS, metrics-server, local-path PVC provisioning, cluster DNS, lifecycle restart, and loopback control service. The next platform MVP gate is Flux bootstrap followed by reconciliation of private Traefik and lightweight observability. Test it with `flux get all -A`, `kubectl get pods -A`, private endpoint checks, Grafana health, and host-control actions while keeping the service loopback/private.

The first household-data MVP should remain disabled until the platform MVP is stable. It consists of one catalog workflow plus one selected media application, with files under `/srv/homelab/data`, metadata-only PostgreSQL, a tested restore path, and no public exposure. Do not deploy Jellyfin, Immich, Samba shares, or the full application matrix simultaneously.

## Batch 4 — optional file-share foundation

Run only after explicit approval:

```bash
ENABLE_SAMBA=1 sudo ./infra/scripts/host/batch/60-install-fileshare-foundation.sh
```

This installs packages only, leaves Samba services disabled, and creates no shares or credentials.
