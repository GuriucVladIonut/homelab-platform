# Manual Actions

| ID | Status | Action |
|---|---|---|
| GITHUB-001 | BLOCKED_EXTERNAL | Authenticate the platform Git remote securely; do not place a PAT in Markdown or Git. |
| CF-001 | BLOCKED_EXTERNAL | Create a least-privilege Cloudflare API token restricted to the `gvlad.dev` zone and DNS edit permissions required for DNS-01. Never use the Global API Key. |
| CF-002 | BLOCKED_EXTERNAL | Perform a read-only inventory of the three existing Cloudflare deployments/resources. Do not modify them. |
| CF-003 | BLOCKED_EXTERNAL | Approve any desired mapping of existing resources to `gvlad.dev`; no Cloudflare apply is prepared or authorized. |
| SSH-001 | BLOCKED_EXTERNAL | Enroll and test a remote SSH public key before any future change to disable password authentication. |
| REBOOT-001 | READY_FOR_EXECUTION | Run the single reboot gate in `infra/docs/execution-batch-runbook.md` after Batch 1 validation passes. |

No external account action is required for local repository implementation or host scripts. Never paste credentials into chat, Markdown, Git, shell history, or logs.
