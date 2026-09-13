# Resource Budget and Component Classification

## Hardware envelope

- 4 cores / 8 threads.
- Approximately 16 GiB RAM; 15 GiB visible to the current OS context.
- One approximately 894 GiB physical SSD, with a 200 GiB Ubuntu partition.
- Single node and single disk; no HA claims.

## Policy

Normal steady-state workloads must leave substantial RAM headroom for Ubuntu, k3s, filesystem cache, and operational recovery. Heavy workloads are mutually exclusive and on-demand. Every implementation must record measured idle/load memory after deployment; estimates below are planning bands, not capacity guarantees.

| Classification | Components | Planning behavior |
|---|---|---|
| MANDATORY | systemd, NetworkManager, SSH, firewall, k3s, kubectl, Helm, SOPS, age, CoreDNS, local storage, Flux, explicitly managed Traefik, metrics-server, cert-manager | Establish and secure the platform before applications |
| RECOMMENDED | Prometheus, kube-state-metrics, node-exporter, Grafana, private overlay, restic | Add incrementally after the baseline is stable |
| OPTIONAL | Forgejo, AdGuard Home/Pi-hole, Jellyfin, Navidrome, books application, photo application, automation, Samba, catalog | Install only against an explicit use case and capacity check |
| HEAVY / ON-DEMAND | OpenSearch, SIEM, Immich ML, Whisper, AI/RAG, SonarQube, multiple VMs, large PCAP workflows | Start manually; never make core services depend on them |
| REJECTED FOR CURRENT HARDWARE | Distributed storage, multi-node HA simulation, always-on heavy SIEM, public control plane, GPU-dependent baseline | Conflicts with one disk, one node, limited RAM, or security requirements |

## Initial operating targets

| Budget | Target |
|---|---:|
| Ubuntu/host reserve | 3–4 GiB |
| k3s/runtime/core platform | 2–3 GiB |
| mandatory observability | 2–3 GiB |
| application allowance | 2–3 GiB |
| recovery/headroom | at least 3 GiB |

These are aggregate targets. They must be revised from measurements before adding optional or heavy workloads.
