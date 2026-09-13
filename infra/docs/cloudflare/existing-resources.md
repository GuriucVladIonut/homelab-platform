# Cloudflare Existing Resources

## Status

Inventory pending. The user reports three Cloudflare deployments/resources unrelated to `gvlad.dev`; they must not be modified or deleted.

## Required read-only inventory

For each resource record:

| Field | Value |
|---|---|
| Name | Pending |
| Type | Pages, Worker, Tunnel, or other |
| Current hostname | Pending |
| Purpose | Infer only from read-only metadata |
| Associated zone | Pending |
| Safe to map to `gvlad.dev` | No determination yet |
| Recommended subdomain | Pending |
| Required action | Inventory only; approval required for changes |

## Safety boundary

Do not attach `gvlad.dev`, alter DNS, delete deployments, create tunnels, or change routes in this phase. Use a scoped API token only; never use a Global API Key. If no local credential is available, see `docs/manual-actions.md`.
