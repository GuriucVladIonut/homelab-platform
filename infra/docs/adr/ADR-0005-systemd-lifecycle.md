# ADR-0005 — Use systemd for Cluster Lifecycle

## Status

Accepted.

## Decision

k3s remains a systemd-managed service. Lifecycle operations use `systemctl` through fixed allowlisted operations. Boot policy is controlled with `enable` and `disable`; no cron-based boot controller is introduced.

## Rationale

systemd provides ordering, dependency handling, exit state, journald integration, restart policy, and a native boot model. A web UI never receives unrestricted systemctl or shell access.
