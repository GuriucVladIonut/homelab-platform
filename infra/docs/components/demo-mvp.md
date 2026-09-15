# Demo MVP

Status: `IMPLEMENTED_IN_REPO`, pending Flux reconciliation and live validation.

The first application is a single-replica `traefik/whoami:v1.10.3` deployment
in namespace `demo`. It is disposable: no database, PVC, NodePort, LoadBalancer,
or public DNS record is used. The service is ClusterIP only and is routed by
Flux-managed Traefik through the staging wildcard certificate.

## Security and resources

The pod runs as non-root with RuntimeDefault seccomp, no service-account token,
no Linux capabilities, no privilege escalation, a read-only root filesystem,
health probes, and explicit 10m/50m CPU and 16Mi/64Mi memory request/limit
bounds. A NetworkPolicy permits ingress only from the `ingress` namespace.

## Validation

```bash
kubectl -n demo get deploy,pod,svc,ingressroute,networkpolicy
kubectl -n ingress get certificate homelab-wildcard-staging
curl -k --resolve demo.homelab.gvlad.dev:443:127.0.0.1 \
  https://demo.homelab.gvlad.dev/
```

The staging certificate is not trusted by normal browsers. Do not create public
DNS records. HTTP-to-HTTPS redirect is provided by Traefik's web entrypoint.

## Removal and rollback

The `apps-demo` Flux Kustomization owns all resources. Remove that Kustomization
from Git, reconcile, and verify only the disposable `demo` resources are
removed. No personal data or persistent storage is involved.
