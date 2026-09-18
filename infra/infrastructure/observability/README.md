# infrastructure/observability

Managed homelab infrastructure area.

Status: `DEPLOYED` for the pinned kube-prometheus-stack baseline and
`IMPLEMENTED_IN_REPO` for the alert rules. The stack is intentionally small:
Prometheus, Grafana, kube-state-metrics, node-exporter, and local Prometheus
rules. Alertmanager, Loki/Alloy, and OpenSearch remain disabled. Retention is
seven days with explicit resource limits for the single-node host.

Validation requires all mandatory pods to be Ready, node-exporter and
kube-state-metrics targets to be UP, and no sustained firing baseline alert.
Rollback is a Git revert of the HelmRelease or PrometheusRule commit followed
by Flux reconciliation; no persistent user data is removed.
