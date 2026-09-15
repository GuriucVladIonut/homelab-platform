# Ingress/TLS validation workload

Status: `OPTIONAL_DISABLED` outside validation windows.

The `validation` namespace contains one disposable `traefik/whoami:v1.10.3`
workload used only to verify private Traefik routing, the central TLSStore, and
HTTP-to-HTTPS behavior. It is not a platform dependency and no production
application should copy its namespace or deployment pattern.

The workload uses an explicit non-root UID, non-root group, RuntimeDefault
seccomp, no service-account token, no capabilities, no privilege escalation,
read-only root filesystem, probes, resource limits, and a ClusterIP service.
It has no persistent data, public DNS, NodePort, or LoadBalancer. Its route is
`validation.homelab.gvlad.dev`; test it only on a trusted private path.

The central wildcard Certificate remains owned by cert-manager in `ingress`.
Applications use the Traefik default TLSStore and do not request duplicate
wildcard certificates in their own namespaces.
