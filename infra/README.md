# Homelab Infrastructure

Current executable implementation subtree of the `homelab-platform` Git repository for the `gvlad.dev` homelab.

The Git root is the parent directory, `homelab-platform/`. This subtree is retained in its current location during reconciliation; paths below are relative to `infra/`.

## Scope

This repository contains executable infrastructure configuration and technical operational documentation.

The separate Obsidian repository contains architecture reasoning, learning, planning, brainstorming, incidents, runbooks, and chronological implementation history.

## Target Platform

```text
ASUS VivoBook X542UF
├── Intel Core i5-8250U
├── 16 GiB RAM
├── ADATA SU650 SSD
├── Ubuntu
├── k3s
├── kubectl
├── Helm
├── k9s
├── Flux
└── KVM/libvirt
```

## Domain

Reserved namespace: `homelab.gvlad.dev`

Examples:

- `grafana.homelab.gvlad.dev`
- `git.homelab.gvlad.dev`
- `dns.homelab.gvlad.dev`
- `media.homelab.gvlad.dev`
- `siem.homelab.gvlad.dev`

Services are private by default.

## Repository Principles

1. Git is the desired-state source of truth.
2. No plaintext secrets.
3. No unpinned `latest` images in managed workloads.
4. Manual changes must eventually be represented in Git.
5. Infrastructure changes require validation.
6. Destructive actions require documented impact and recovery.
7. Every significant component requires technical documentation.
8. Heavy/security labs remain optional and isolated.
9. Household connectivity must not depend on this host being online.
10. Remote access must not require ISP port forwarding.

## Structure

```text
bootstrap/       Host and cluster bootstrapping
cluster/         Cluster composition
infrastructure/  Shared platform services
apps/            User-facing workloads
labs/            Experimental/security workloads
policies/        RBAC/network/security policies
scripts/         Operational automation
docs/            Technical documentation
secrets/         Encrypted secrets only
.github/         CI workflows
```

Current status: host execution scripts, pinned k3s/tooling installers, GitOps scaffolding, endpoint/component registries, application source, and validation tooling are implemented in-repo. Deployment remains split-control and requires manual sudo; Cloudflare/GitHub actions remain externally gated.
