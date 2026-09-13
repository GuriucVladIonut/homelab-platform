# ADR-0006 — Separate Private and Public DNS Exposure

## Status

Accepted for implementation.

## Decision

`homelab.gvlad.dev` is private by default. Internal/split DNS resolves private service names to private ingress or overlay-reachable addresses. Public DNS records are created only for explicitly approved services and must not point to changing RFC1918 addresses.

cert-manager owns temporary ACME DNS-01 records. Static public Cloudflare configuration may be managed declaratively later. ExternalDNS is not introduced initially.

## Consequences

DNS names do not imply Internet reachability. SSH, Kubernetes API, databases, monitoring, and control APIs remain private.
