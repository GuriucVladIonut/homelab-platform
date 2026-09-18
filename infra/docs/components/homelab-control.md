# Homelab Control

`apps/homelab-control` is a Go standard-library host service, intentionally outside Kubernetes so cluster lifecycle controls remain available while k3s is stopped. It binds to loopback, uses HTML escaping, security headers, a per-process CSRF token, POST-only state changes, confirmation for stop/restart, and an audit log. A locked `homelab-control` account may invoke only a fixed root helper allowlist through a narrowly scoped sudoers entry.

The service is DEPLOYED through `50-install-homelab-control.sh`; the service remains loopback-only and continues to work while k3s is stopped. The dashboard reads host state from `/proc`, `statfs`, and bounded system commands, reads Kubernetes state through a dedicated get/list/watch-only ServiceAccount, and queries Prometheus through its private ClusterIP when available. It never reads Secrets, uses exec, port-forward, nodes/proxy, or cluster-admin credentials. `51-install-homelab-control-reader.sh` installs the mode-0640 root-owned reader kubeconfig after Flux creates the RBAC token Secret. Remote access is disabled until an authenticated private overlay is intentionally configured. Rollback removes the service, helper, sudoers file, reader kubeconfig, and account after review.

The UI health model is `OK`, `DEGRADED`, `ERROR`, `OFFLINE`, `UNKNOWN`, or
`DISABLED`. Kubernetes and Prometheus failures degrade those sections while the
host section and cluster controls remain available. Endpoint probes are limited
to enabled registry entries, use short timeouts, and never accept URLs from
requests. UFW and SMART summaries use two additional fixed, read-only helper
actions. The service's `NoNewPrivileges` exception is narrowly scoped to the
root-owned helper command list; the web process still has no arbitrary root
execution path. Backups show timer/repository status and prominently say
`NOT DISASTER RECOVERY` once the backup baseline is installed.
