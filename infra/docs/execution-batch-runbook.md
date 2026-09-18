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

## Recovery and validation workload batch

After a reboot or host repair, run these commands from the repository root:

```bash
sudo ./infra/scripts/host/batch/33-repair-k3s-traefik-ownership.sh
sudo ./infra/scripts/host/batch/34-install-operator-kubeconfig.sh
export KUBECONFIG="$HOME/.kube/config-homelab"
flux reconcile source git flux-system
flux reconcile kustomization flux-system --with-source
sudo ./infra/scripts/host/batch/21-platform-recovery-validation.sh
```

The `33` script is the only script that restarts k3s. The `34` script creates
only a mode-0600 operator kubeconfig. Flux then applies the node-exporter fix
and the disposable ingress/TLS validation workload. No public DNS or production ACME resource is created.

## Batch 3 — GitOps and control application

```bash
sudo ./infra/scripts/host/batch/40-install-gitops-tools.sh
sudo ./infra/scripts/host/batch/50-install-homelab-control.sh
export KUBECONFIG="$HOME/.kube/config-homelab"
flux reconcile kustomization infrastructure-base --with-source
sudo ./infra/scripts/host/batch/51-install-homelab-control-reader.sh
```

Flux clients and the loopback-only host control service become available. The
reader script installs only the host UI's generated read-only kubeconfig; it
does not weaken `/etc/rancher/k3s` permissions. Flux bootstrap itself remains
manual until GitHub authentication is complete.

## Platform test gates

The host and Kubernetes platform is testable: the operator has verified the k3s node, CoreDNS, metrics-server, local-path PVC provisioning, cluster DNS, lifecycle restart, and loopback control service. Validate it with `flux get all -A`, `kubectl get pods -A`, private endpoint checks, Grafana health, and host-control actions while keeping services private.

Household-data applications remain disabled until platform health and backups are stable. Add catalog, media, and file-sharing components individually with no public exposure.

## Batch 4 — optional file-share foundation

Run only after explicit approval:

```bash
ENABLE_SAMBA=1 sudo ./infra/scripts/host/batch/60-install-fileshare-foundation.sh
```

This installs packages only, leaves Samba services disabled, and creates no shares or credentials.

## Batch 5 — Flux bootstrap and platform validation

After authenticating the HTTPS GitHub remote securely, run from the repository root:

```bash
flux check --pre
flux bootstrap github \
  --owner=GuriucVladIonut \
  --repository=homelab-platform \
  --branch=main \
  --path=infra/gitops/flux-system \
  --personal
flux check
flux get all -A
kubectl get pods -A
```

Flux bootstrap writes sync manifests and commits them to GitHub. Review that diff before accepting it. It does not require or authorize Cloudflare changes. After reconciliation is healthy, verify private Traefik and observability HelmReleases; cert-manager remains gated until CF-001 is complete.
