# ADR-0002 - Use Flux for GitOps

## Status

Accepted in principle.

## Decision

Use Git as desired state and Flux as the Kubernetes reconciliation engine.

## Consequences

Advantages:

- reproducibility
- drift correction
- auditable change history
- Git rollback

Trade-offs:

- bootstrap flow requires careful design
- manual changes must be treated as temporary
