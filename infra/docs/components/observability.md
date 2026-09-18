# Observability

The GitOps baseline deploys Prometheus, Grafana, kube-state-metrics, and
node-exporter with pinned chart metadata, seven-day retention, and explicit
resource limits. Loki/Alloy is optional and disabled. Node-exporter uses the
`prometheus-node-exporter` subchart values key. Its native
`service.listenOnAllInterfaces: true` behavior is retained, producing the
chart's single listener argument; no custom `--web.listen-address` is added.
The previous duplicate override caused `bind: address already in use`. Confirm
the DaemonSet is Ready and its Prometheus target is UP after reconciliation.

The baseline includes low-noise alerts for node availability, Kubernetes node
readiness, root and `/srv/homelab` capacity, sustained memory pressure,
CrashLoopBackOff, stuck Pending pods, unavailable DaemonSets and StatefulSets,
certificate expiry, Prometheus target loss, and node-exporter absence. The
Alertmanager deployment remains disabled, so these rules are visible in
Prometheus but do not send notifications until a notification path is chosen.

The control UI reads Prometheus through the private service ClusterIP and shows
target counts, node-exporter and kube-state-metrics state, firing alerts, and
host resource summaries. Grafana remains private and is linked only from the
canonical endpoint registry; no dashboard pack or public route is installed.
