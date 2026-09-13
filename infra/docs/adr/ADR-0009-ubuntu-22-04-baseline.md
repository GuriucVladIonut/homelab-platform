# ADR-0009 — Retain Ubuntu 22.04.5 LTS Baseline

## Status

Accepted.

## Decision

The supported host baseline is Ubuntu 22.04.5 LTS with the 6.8.x kernel line. Ubuntu 24.04 migration is removed from the active implementation path. `do-release-upgrade` must not be run as part of this project unless a later decision supersedes this ADR.

## Rationale

The homelab is a mobile, single-node laptop with limited recovery options and an explicitly accepted same-disk/no-external-backup risk. Holding the distribution baseline reduces migration variables while host foundation and k3s are established.

## Consequences

- Host work targets Jammy-compatible packages and configuration.
- Security updates for the supported baseline remain required.
- No release migration is a Phase B gate.
- A future release change requires a new decision, recovery review, and a separate change plan.
