# Flux Bootstrap and Infrastructure Reconciliation

Flux bootstrap has been completed and the GitHub repository is the source of
truth for this cluster. The generated Flux manifests live under
`infra/gitops/flux-system/flux-system`.

The root Kustomization creates separate, dependency-ordered Flux
Kustomizations. The base stage creates namespaces, then Traefik and
cert-manager controllers install their CRDs before their dependent resources
are applied. Observability is reconciled after the base stage.

The stages are:

- `infrastructure-base`
- `infrastructure-traefik`
- `infrastructure-traefik-config`
- `infrastructure-cert-manager`
- `infrastructure-cert-manager-config`
- `infrastructure-observability`

This prevents a Traefik Middleware or cert-manager custom resource from being
server-side dry-run before its owning Helm release has installed the CRD.

The cert-manager Cloudflare issuer remains intentionally gated. The current
cert-manager resources contain only the chart and a documentation ConfigMap;
no Cloudflare token or ACME issuer is enabled until the SOPS-encrypted secret
workflow is completed.

Normal operation:

```bash
flux get all -A
flux reconcile kustomization flux-system --with-source -n flux-system
flux reconcile kustomization infrastructure-traefik --with-source -n flux-system
```

Rollback is performed by reverting the wiring commit and pushing it. Flux will
prune resources only according to the resulting desired state; review any
persistent-data deletion before applying a rollback.
