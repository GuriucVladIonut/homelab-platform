# k3s

The single-node k3s design uses pinned official release `v1.36.4+k3s1`, normal embedded datastore, local-path storage, CoreDNS, metrics-server, ServiceLB, `cluster.local`, pod CIDR `10.42.0.0/16`, and service CIDR `10.43.0.0/16`. Bundled Traefik is disabled because Traefik is managed explicitly through Flux. The installer verifies the official checksum artifact and creates a systemd service; it does not delete cluster data on rollback.

Installation is READY_FOR_EXECUTION via `30-install-k3s.sh`. The CIDRs are checked against existing routes before changes. The cluster remains private behind the host firewall.
