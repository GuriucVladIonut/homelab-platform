# ADR-0008 — Resource Classification

## Status

Accepted.

## Decision

Every component is classified as MANDATORY, RECOMMENDED, OPTIONAL, HEAVY / ON-DEMAND, or REJECTED FOR CURRENT HARDWARE. The classification and resource budget in `docs/architecture/resource-budget.md` govern installation order and dependency design.

## Consequences

Optional and heavy workloads cannot become prerequisites for core boot, GitOps, ingress, DNS/TLS, control, or recovery. Measurements supersede estimates before capacity-expanding changes.
