# Host recovery and operator workflow

Status: `READY_FOR_EXECUTION` for the two narrowly scoped repair scripts.

## k3s Traefik ownership

The intended owner is the Flux HelmRelease `ingress/traefik`. The installer
configuration previously persisted only `traefik` disablement, while the
current k3s packaging can also expose a `traefik-crd` HelmChart. The repair
script writes an explicit k3s drop-in disabling both names, restarts k3s, and
removes only matching generated HelmChart objects after verifying Flux owns
Traefik. It does not remove PVCs, namespaces, or application data.

Run `33-repair-k3s-traefik-ownership.sh` as root. Rollback is to remove its
drop-in and restart k3s; do not re-enable bundled Traefik while Flux owns it.

## Operator kubeconfig

`34-install-operator-kubeconfig.sh` copies the generated k3s kubeconfig to
`~/.kube/config-homelab`, changes only the local server endpoint to
`127.0.0.1:6443`, sets mode `0600`, and validates access as the invoking user.
The root kubeconfig is never weakened or modified. Use:

```bash
export KUBECONFIG="$HOME/.kube/config-homelab"
```

If the k3s client continues to emit a permission warning while starting, it is
from the k3s wrapper inspecting its root-only config drop-in directory, not a
permission change made by this workflow. The operator kubeconfig remains the
correct credential boundary; an upstream kubectl client can be evaluated later
if warning-free output is required.

## Post-reboot validation

`21-platform-recovery-validation.sh` is read-only and checks systemd, zram,
UFW, k3s, Flux, Traefik, cert-manager, observability, the demo workload, and
the staging certificate. A reboot is never automated by a configuration
script.
