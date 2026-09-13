# Phase B — zram Policy

The host foundation uses one persistent zram swap device sized at 5 GiB, within the approved 4–6 GiB range. No disk-backed swapfile is created or enabled.

The implementation is [`infra/scripts/host/configure-zram.sh`](../scripts/host/configure-zram.sh). It installs a narrowly scoped `homelab-zram.service`, refuses to alter unrelated active swap, and validates size and persistence after startup.

The script loads the available `zram` kernel module before checking `/sys/class/zram-control`; on a clean boot that sysfs directory does not exist until the module is loaded. It uses the Ubuntu-compatible `zramctl --find` form without combining it with the mutually exclusive `--output` option.

## Inspect

```bash
swapon --show
zramctl
systemctl status homelab-zram.service --no-pager
```

## Disable temporarily

```bash
sudo systemctl disable --now homelab-zram.service
```

Re-enable with `sudo systemctl enable --now homelab-zram.service`.

## Resize

Edit `SIZE` in `/usr/local/sbin/homelab-zram-setup` to a value between 4 and 6 GiB, then rerun the configuration script. It recreates only `/dev/zram0`.

## Remove / rollback

```bash
sudo systemctl disable --now homelab-zram.service
sudo rm -f /etc/systemd/system/homelab-zram.service \
  /usr/local/sbin/homelab-zram-setup
sudo systemctl daemon-reload
swapon --show
zramctl
```

These commands affect only the files and zram device owned by this Phase B change.
