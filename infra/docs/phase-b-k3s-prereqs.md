# Phase B — k3s Kernel Prerequisites

The k3s prerequisite change is limited to the `overlay` and `br_netfilter` modules and these sysctls:

```text
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
```

The implementation is [`infra/scripts/host/configure-k3s-prereqs.sh`](../scripts/host/configure-k3s-prereqs.sh). It verifies each module with `modinfo`, loads it only when `/sys/module/<name>` is absent, persists modules in `/etc/modules-load.d/homelab-k8s.conf`, persists sysctls in `/etc/sysctl.d/90-homelab-k8s.conf`, applies them with `sysctl --load`, and validates the resulting state. It does not install k3s.

## Rollback

After confirming no workload depends on forwarding, remove the persistence files and apply the prior forwarding state:

```bash
sudo rm -f /etc/modules-load.d/homelab-k8s.conf
sudo rm -f /etc/sysctl.d/90-homelab-k8s.conf
sudo sysctl net.ipv4.ip_forward=0
sudo sysctl net.bridge.bridge-nf-call-iptables=0
sudo sysctl net.bridge.bridge-nf-call-ip6tables=0
sudo modprobe -r br_netfilter overlay
```

Module removal may be refused while another service uses them; reboot after removing the persistence files and verify the resulting state.
