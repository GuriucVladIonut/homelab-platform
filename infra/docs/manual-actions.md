# Manual Actions

| ID | Status | Reason | User action | Verification after completion |
|---|---|---|---|---|
| CF-001 | BLOCKED | No Cloudflare credential was provided and API access was not verifiable locally | Create a scoped Cloudflare API token limited to the `gvlad.dev` zone with only the minimum DNS permissions required for cert-manager DNS-01. Do not create a Global API Key. Do not paste the token into chat, Markdown, Git, or shell history. | Codex validates access with a non-secret zone read, then places the token into the SOPS + age workflow |
| HOST-001 | BLOCKED | Privileged systemd, netlink, and firewall state is unavailable in the current sandbox | Run the repository preflight from a trusted host shell with required sudo access, or provide equivalent command output without secrets | Codex reconciles service, route, firewall, socket, SMART, and thermal state |
| DATA-001 | NOT STARTED | Backup destination and personal-data scope are not determinable from Git | Choose an external backup medium/destination before data-bearing services are deployed | Codex tests backup and restore; no existing personal data is moved or deleted |

## Cloudflare dashboard path

`Cloudflare → My Profile → API Tokens → Create Token → Custom token`

Restrict the token to the `gvlad.dev` zone and the minimum DNS permissions required by the selected cert-manager integration. Store it locally through the documented SOPS workflow. The token value must never be committed or pasted into Markdown.
