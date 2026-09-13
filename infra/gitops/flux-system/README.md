# Flux Bootstrap and Infrastructure Reconciliation

Flux bootstrap has been completed and the GitHub repository is the source of
truth for this cluster. The generated Flux manifests live under
`infra/gitops/flux-system/flux-system`.

`infrastructure.yaml` creates a second Flux Kustomization for
`./infra/cluster`, after the bootstrap Kustomization is ready. That composition
installs the prepared namespaces, explicit Traefik, cert-manager controller,
and the lightweight observability baseline.

The cert-manager Cloudflare issuer remains intentionally gated. The current
cert-manager resources contain only the chart and a documentation ConfigMap;
no Cloudflare token or ACME issuer is enabled until the SOPS-encrypted secret
workflow is completed.

Normal operation:

```bash
flux get all -A
flux reconcile kustomization infrastructure --with-source -n flux-system
```

Rollback is performed by reverting the wiring commit and pushing it. Flux will
prune resources only according to the resulting desired state; review any
persistent-data deletion before applying a rollback.
