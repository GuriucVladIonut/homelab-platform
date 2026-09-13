# Manual Actions

| ID | Status | Action |
|---|---|---|
| GITHUB-001 | BLOCKED_EXTERNAL | Authenticate the platform Git remote securely; do not place a PAT in Markdown or Git. |
| CF-001 | BLOCKED_EXTERNAL | In Cloudflare Dashboard, open the `gvlad.dev` zone, go to Profile → API Tokens → Create Token → Custom token. Grant only Zone → DNS → Edit and Zone → Zone → Read; set Zone Resources to Include → Specific zone → `gvlad.dev`; do not grant account permissions and never use the Global API Key. Store the token only through the interactive SOPS procedure in `infra/infrastructure/cert-manager/staging/README.md`. |
| CF-002 | BLOCKED_EXTERNAL | Perform a read-only inventory of the three existing Cloudflare deployments/resources. Do not modify them. |
| CF-003 | BLOCKED_EXTERNAL | Approve any desired mapping of existing resources to `gvlad.dev`; no Cloudflare apply is prepared or authorized. |
| SSH-001 | BLOCKED_EXTERNAL | Enroll and test a remote SSH public key before any future change to disable password authentication. |
| REBOOT-001 | READY_FOR_EXECUTION | Run the single reboot gate in `infra/docs/execution-batch-runbook.md` after Batch 1 validation passes. |

No external account action is required for local repository implementation or host scripts. Never paste credentials into chat, Markdown, Git, shell history, or logs.

## Staging DNS-01 activation

After CF-001, create the encrypted Secret locally and review it without
printing decrypted contents. The exact input shape is
`infra/secrets/templates/cloudflare-api-token.secret.yaml.example`; the
encrypted output must be
`infra/secrets/cloudflare-api-token.sops.yaml`.

Only after the encrypted Secret exists should the staging Flux Kustomization be
added to the live root. The staging issuer uses Let's Encrypt's staging ACME
directory and requests `homelab.gvlad.dev` plus
`*.homelab.gvlad.dev`. No public service records are created.
