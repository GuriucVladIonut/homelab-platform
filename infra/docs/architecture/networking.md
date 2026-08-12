# Networking Architecture

## Supported Physical Uplinks

Priority target:

```text
Ethernet
  -> Household Wi-Fi
  -> Phone hotspot
```

Cluster configuration should not depend on a particular physical DHCP address.

## Kubernetes Defaults

```text
Pod CIDR:      10.42.0.0/16
Service CIDR:  10.43.0.0/16
Cluster DNS:   cluster.local
```

## Remote Access

The ASUS may be located in Botosani while a MacBook management device operates from Iasi.

An authenticated overlay network is intended to provide remote management without ISP port forwarding.

## Household Safety

The cluster must not become the single point of failure for household Internet while the laptop remains an on/off device.
