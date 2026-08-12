# Architecture Overview

## Physical Architecture

```mermaid
flowchart TD
  Internet[Internet]
  Hotspot[Phone Hotspot]
  Wifi[Household Wi-Fi]
  Ethernet[Ethernet]
  ASUS[ASUS Homelab<br/>Ubuntu]
  K3S[k3s]
  KVM[KVM/libvirt]
  Core[Platform Services]
  Apps[Applications]
  Obs[Observability]
  Lab[Security Lab]
  Mac[MacBook]
  Overlay[Private Overlay Network]

  Internet --> Hotspot
  Internet --> Wifi
  Internet --> Ethernet
  Hotspot --> ASUS
  Wifi --> ASUS
  Ethernet --> ASUS
  ASUS --> K3S
  ASUS --> KVM
  K3S --> Core
  K3S --> Apps
  K3S --> Obs
  KVM --> Lab
  Mac --> Overlay
  ASUS --> Overlay
```

## Availability

This is intentionally a single-node cluster, so there is no compute, storage, or network HA.

## Startup Goal

```text
power on
  -> Ubuntu
  -> network
  -> k3s
  -> GitOps
  -> services healthy
```

## Shutdown Goal

A normal `sudo shutdown now` must remain safe.
