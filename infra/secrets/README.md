# Encrypted Secrets

Secrets are encrypted with SOPS and age before they enter Git. The placeholder recipient in `.sops.yaml` must be replaced locally with the operator's real age public key before encrypting any file. Never commit an age private key, plaintext token, kubeconfig credential, or household password.

Cloudflare DNS-01 remains gated on manual action CF-001. Flux bootstrap remains gated on GitHub authentication and is not claimed successful by this repository.
