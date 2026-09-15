# DNS Architecture

`homelab.gvlad.dev` is a private service namespace. The canonical endpoint registry is `infra/config/endpoints.yaml`; entries are private and disabled until their backing service is deployed. No public record points at RFC1918 addresses. Cloudflare DNS-01 uses a SOPS-encrypted token, never plaintext Git data. The central staging wildcard certificate is owned by cert-manager in `ingress` and consumed by Traefik's default TLSStore. Existing Cloudflare resources remain untouched.
