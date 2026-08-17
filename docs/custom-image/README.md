# Custom Image

This image turns a Linksys E8450 / Belkin RT3200 into a portable industrial machine-network router. It combines OpenWrt with project-specific network defaults, services, and maintenance tools.

## Factory defaults

| Setting | Default |
|---|---|
| Hostname | `Spare1` |
| LAN address | `192.168.1.123` |
| DHCP pool | `192.168.1.124`–`192.168.1.128` |
| Wired DHCP mode | `COGNEX_ON` |
| Machine Wi-Fi SSID | `Spare1` |
| SSH / LuCI user | `root` |
| FTP user | `admin` |

Factory passwords are listed in the repository [README](../../README.md#factory-credentials). They are public bootstrap credentials and must not be treated as secrets.

## Features

| Area | What the image provides |
|---|---|
| [Network defaults](network-defaults.md) | LAN, wireless, firewall, and isolation model |
| [DHCP behavior](dhcp-behavior.md) | Address pools, wired DHCP modes, and lease reclamation |
| [NTP uplink](ntp-uplink.md) | Isolated upstream time synchronization and local NTP service |
| [FTP service](ftp-service.md) | Restricted file transfer to USB-backed storage |
| [USB storage](usb-storage.md) | exFAT automount, safe removal, and file organization |

## Included tools

The image includes `provision-router`, `set-dhcp-range`, `dhcp-mode`, `reclaim-dhcp-lease`, `usb-eject`, and `organize-by-date`. See the [tool reference](../tools/README.md) for syntax and detailed documentation.

## Included packages

The authoritative package selection is [`build/packages.txt`](../../build/packages.txt). It includes LuCI, vsftpd, nftables support, USB storage support, exFAT tools, and basic maintenance utilities.

## Deployment

After installing the image, run [router provisioning](../getting-started/provisioning.md). Verify credentials, the LAN subnet, DHCP behavior, NTP uplink, and USB/FTP access before connecting production equipment.
