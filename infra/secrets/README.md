# Encrypted Secrets

Secrets are encrypted with SOPS and age before they enter Git. The placeholder
recipient in `.sops.yaml` must be replaced locally with the operator's real age
public key before encrypting any file. Never commit an age private key,
plaintext token, kubeconfig credential, or household password.

The prepared Cloudflare secret is
`infra/infrastructure/cert-manager/staging/cloudflare-api-token.sops.yaml`. Its
Kubernetes name is `cloudflare-api-token` in namespace `cert-manager`, with key
`api-token`. The example input is under `infra/secrets/templates/` and is never
reconciled.

Cloudflare DNS-01 remains gated on manual action CF-001 and the presence of the
encrypted Secret plus the out-of-band `flux-system/sops-age` Secret. The
staging ClusterIssuer and wildcard Certificate are under
`infra/infrastructure/cert-manager/staging/` and are wired into the live Flux
root.
