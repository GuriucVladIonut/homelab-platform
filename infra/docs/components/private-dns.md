# Private DNS — Phase L

Status: `IMPLEMENTED_IN_REPO — INSTALLER REQUIRES OPERATOR SUDO`.

The private resolver is a small host-level `dnsmasq` service. It serves only
the `homelab.gvlad.dev` overrides and forwards all other names to the existing
upstream resolver. A timer discovers the current RFC1918 source address from
the default route, regenerates records, and reloads dnsmasq. This avoids
hardcoding a DHCP address and continues to work while Kubernetes is stopped.

It is deliberately opt-in: router DHCP and household DNS are unchanged, so
the laptop cannot become an Internet/DNS single point of failure. A client may
temporarily use the host's current private address as its DNS server, or a
future Tailscale split-DNS configuration can route only this zone.

Records are catalog, Grafana, Prometheus, media, music, books, and validation.
They point only to the current private ingress address; no Cloudflare public
records or RFC1918 public DNS records are created. dnsmasq binds loopback and
the current private interface. No recursion is exposed publicly, zone
transfers are not enabled, and dynamic updates are not accepted.

TLS remains Let's Encrypt staging. DNS success does not make the staging CA
trusted by browsers; use the existing staging trust warning or `curl -k`.

Install as root with `sudo ./infra/scripts/host/batch/76-install-private-dns.sh
"$PWD"`. Verify with `dig @127.0.0.1 catalog.homelab.gvlad.dev` and
`systemctl status homelab-private-dns-update.timer`. On a MacBook, opt in via
the active network's manual DNS server setting using the host's current private
IP; do not change router DHCP.
