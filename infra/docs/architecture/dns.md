# DNS Architecture

`homelab.gvlad.dev` is a private service namespace. The canonical endpoint registry is `infra/config/endpoints.yaml`; all entries are private and disabled until their backing service is deployed. No public record points at RFC1918 addresses. Cloudflare DNS-01 is gated by CF-001 and uses a SOPS-encrypted token, never plaintext Git data. Existing Cloudflare resources remain untouched.
