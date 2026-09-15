# Observability

The GitOps baseline deploys Prometheus, Grafana, kube-state-metrics, and
node-exporter with pinned chart metadata, seven-day retention, and explicit
resource limits. Loki/Alloy is optional and disabled. Node-exporter uses the
`prometheus-node-exporter` subchart values key. Its native
`service.listenOnAllInterfaces: true` behavior is retained, producing the
chart's single listener argument; no custom `--web.listen-address` is added.
The previous duplicate override caused `bind: address already in use`. Confirm
the DaemonSet is Ready and its Prometheus target is UP after reconciliation.

The baseline also includes low-noise alerts for node-exporter loss, root
filesystem space below 15 percent, and sustained pod CrashLoopBackOff. The
Alertmanager deployment remains disabled, so these rules are visible in
Prometheus but do not send notifications until a notification path is chosen.
