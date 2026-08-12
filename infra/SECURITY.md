# Security Policy

## Never Commit

- passwords
- API tokens
- authentication cookies
- private SSH keys
- age private keys
- kubeconfigs containing credentials
- DNS-provider tokens
- Tailscale auth keys
- database credentials
- recovery codes
- private TLS keys

## Placeholders

Use placeholders only, for example:

- `<CLOUDFLARE_API_TOKEN>`
- `<TAILSCALE_AUTH_KEY>`
- `<DATABASE_PASSWORD>`
- `<AGE_PRIVATE_KEY>`
- `<KUBECONFIG_PATH>`

## Intended Secret Architecture

Future GitOps secrets will use SOPS + age. Plaintext secret material must remain outside Git.

## Exposure Policy

```text
Internet -> cluster               DENY
Household -> selected services    EXPLICIT ALLOW
Remote overlay -> management      EXPLICIT ALLOW
Security lab -> personal network  DENY
```
