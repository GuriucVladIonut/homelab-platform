# ADR-0004 — Host-Level Homelab Control Service

## Status

Accepted for implementation.

## Decision

Implement `apps/homelab-control` as a small Go binary using server-side HTML templates and a systemd service. Install under `/opt/homelab/control/`, configure under `/etc/homelab-control/`, and run as locked user `homelab-control`.

The service may invoke only fixed, audited cluster lifecycle actions through a narrow privileged helper or narrowly scoped sudoers rules. It must not accept arbitrary commands or arguments and must remain available while k3s is stopped.

## Consequences

The host control plane is independent of Kubernetes. Authentication, CSRF protection, secure cookies, audit logging, rate limiting, and security headers are mandatory before remote use.
