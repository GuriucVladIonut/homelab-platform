# GitOps

Flux-compatible HelmRepository and HelmRelease resources are prepared under `infra/infrastructure`. SOPS, age, and Flux client installation is pinned and checksum-verified by `40-install-gitops-tools.sh`; no private key is generated. Flux bootstrap is BLOCKED_EXTERNAL until GitHub authentication (GITHUB-001) and repository ownership are resolved. No bootstrap success is claimed.
