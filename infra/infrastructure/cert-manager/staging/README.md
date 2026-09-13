# Staging DNS-01 activation

Status: `READY_FOR_EXECUTION`, wired into the live Flux root and gated by the
out-of-band `flux-system/sops-age` decryption Secret.

The staging resources use cert-manager's Let's Encrypt staging directory and
Cloudflare DNS-01. They request both `homelab.gvlad.dev` and
`*.homelab.gvlad.dev`. No public A or AAAA records are created by these
resources. DNS-01 only creates temporary `_acme-challenge` TXT records while a
certificate is being issued.

Required Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: <encrypted by SOPS in the committed manifest>
```

The committed encrypted file must be:

`infra/infrastructure/cert-manager/staging/cloudflare-api-token.sops.yaml`

Only the encrypted file belongs in Git; the plaintext input must never be
committed.

Prepare the age identity and replace the placeholder recipient in `.sops.yaml`
with the resulting public recipient. Keep the private identity outside Git:

```bash
install -d -m 700 "$HOME/.config/sops/age"
age-keygen -o "$HOME/.config/sops/age/keys.txt"
chmod 600 "$HOME/.config/sops/age/keys.txt"
age-keygen -y "$HOME/.config/sops/age/keys.txt"
```

Then encrypt and edit the placeholder interactively. The token is never passed
as a command-line argument or printed to the terminal:

```bash
cp infra/secrets/templates/cloudflare-api-token.secret.yaml.example \
  infra/infrastructure/cert-manager/staging/cloudflare-api-token.sops.yaml
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \
  sops --encrypt --in-place \
  infra/infrastructure/cert-manager/staging/cloudflare-api-token.sops.yaml
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \
  sops infra/infrastructure/cert-manager/staging/cloudflare-api-token.sops.yaml
```

In the editor, replace only
`REPLACE_INTERACTIVELY_BEFORE_ENCRYPTION` with the token, save, and exit.
Review only the encrypted file structure; do not run `sops -d` into a file or
commit the age private key.

The staging Kustomization already references the encrypted file and is active
in the live Flux root.
That Kustomization uses Flux SOPS decryption with an out-of-band `sops-age`
Secret in `flux-system`; neither the private age key nor the Cloudflare token
belongs in Git.

The staging certificate is not trusted by browsers. It must succeed before a
production issuer and certificate are prepared.
