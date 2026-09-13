# Homelab Platform

This repository is the executable source of truth for the personal single-node homelab.

## Repository boundary

The Git root is `homelab-platform/`. The current implementation subtree is `infra/`; no filesystem move is performed by the reconciliation phase. New executable platform work belongs under `infra/` until a separately reviewed repository-layout migration is approved.

The separate Obsidian repository at `Obsidian/moreBrain/` contains architecture reasoning, planning, implementation history, learning, incidents, and human-facing process documentation.

## Current phase

Phase A — repository and host reconciliation. The host is Ubuntu 22.04.5 LTS. No k3s installation or Kubernetes state was detected during the 2026-09-13 read-only inspection.

## Main implementation areas

```text
infra/bootstrap/       host, k3s, and GitOps bootstrap
infra/cluster/         cluster composition
infra/infrastructure/  shared platform services
infra/apps/            user-facing workloads
infra/labs/            isolated/experimental workloads
infra/policies/        security and access policies
infra/scripts/         operational automation and validation
infra/docs/            technical documentation and ADRs
infra/secrets/         encrypted secret documents only
```

See `infra/docs/current-state.md` for evidence and `infra/docs/manual-actions.md` for external or physical prerequisites.
