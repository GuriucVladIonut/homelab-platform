# Remote Access Architecture

## Requirement

Securely manage the ASUS homelab from another network without requiring ISP port forwarding.

## Initial Candidate

Tailscale.

The MacBook initially acts as a management client rather than a Kubernetes worker.

## Failure Model

Loss of remote overlay access must not prevent local cluster operation.

## Open Design Questions

- ACL model
- key expiration
- device revocation
- Headscale evaluation
- Kubernetes API exposure
- remote DNS resolution
