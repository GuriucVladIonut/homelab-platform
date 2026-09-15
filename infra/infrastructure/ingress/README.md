# infrastructure/ingress

Managed homelab infrastructure area.

Traefik is managed explicitly by Flux in `infra/infrastructure/traefik`.
The ingress namespace owns the central staging wildcard Certificate and the
Traefik default TLSStore. Application routes remain private and use the
central store without cross-namespace Secret access.
