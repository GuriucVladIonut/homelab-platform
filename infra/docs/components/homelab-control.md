# Homelab Control

`apps/homelab-control` is a Go standard-library host service, intentionally outside Kubernetes so cluster lifecycle controls remain available while k3s is stopped. It binds to loopback, uses HTML escaping, security headers, a per-process CSRF token, POST-only state changes, confirmation for stop/restart, and an audit log. A locked `homelab-control` account may invoke only a fixed root helper allowlist through a narrowly scoped sudoers entry.

The service is DEPLOYED through `50-install-homelab-control.sh`; the operator verified the process and loopback socket, but the health endpoint exposed a Go 1.18 routing compatibility defect. The source now uses path-only standard-library routes and the installer verifies `/healthz` after rebuilding. Remote access is disabled until an authenticated private overlay is intentionally configured. Rollback removes the service, helper, sudoers file, and account after review.
