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

If the k3s client emits a permission warning while starting, it is from the
k3s multicall wrapper inspecting its root-only config drop-in directory, not a
permission change made by this workflow. The standalone upstream kubectl
script below is the normal operator client and leaves `/usr/local/bin/k3s`
untouched.

`35-install-standalone-kubectl.sh` installs the pinned upstream Kubernetes
`v1.36.4` client after checksum verification. It replaces only the
`/usr/local/bin/kubectl` symlink when that symlink resolves to k3s; the k3s
binary and root-only configuration remain untouched. Helm, Flux, and k9s use
the same private operator kubeconfig. The script is `READY_FOR_EXECUTION` until
run by the operator; afterward verify that kubectl no longer resolves to k3s
and that normal-user commands produce no root-config warning.

## Post-reboot validation

`21-platform-recovery-validation.sh` is read-only and checks systemd, zram,
UFW, k3s, Flux, Traefik, cert-manager, observability, the central staging
certificate, and the disposable validation workload. A reboot is never
automated by a configuration script.
