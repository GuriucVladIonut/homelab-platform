# ADR-0003 — Explicitly Managed Traefik Ingress

## Status

Accepted for implementation.

## Decision

Manage Traefik explicitly with pinned Helm artifacts reconciled by Flux. If k3s is installed later, disable the bundled Traefik before GitOps installation.

## Rationale

Ingress must have explicit ownership, predictable configuration, TLS integration, security middleware, health checks, and auditable lifecycle. The dashboard is private and is never publicly exposed.

## Consequences

Traefik becomes a platform dependency. Its version, entrypoints, exposure, resource limits, and rollback path must be documented and validated.
