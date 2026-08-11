# Tool Reference

This page provides a quick reference for the command-line tools included with the custom OpenWrt image.

These tools provide convenient access to common router configuration, DHCP management, USB storage, and maintenance functions.

For detailed explanations of how each feature works, see the linked documentation for that feature.

---

## `provision-router`

Interactively configures the primary settings of a newly installed router.

### Usage

```sh
provision-router
```

The utility prompts for configuration values such as:

* Router hostname
* LAN IP address
* LAN subnet mask
* DHCP configuration
* Wi-Fi SSID
* Wi-Fi password
* Root password

The tool is intended to be run after installing the custom OpenWrt image to configure the router for its intended deployment.

### Location

```text
/usr/sbin/provision-router
```

### Related Documentation

See [Router Provisioning](../installation/provisioning.md).

---

## `set-dhcp-range`

Configures the DHCP address ranges provided by the router.

The tool supports both a normal consecutive DHCP pool and multiple fragmented DHCP ranges.

### Usage

```sh
set-dhcp-range
```

The tool runs interactively and prompts for the desired DHCP ranges.

### Consecutive Range Example

A single range such as:

```text
192.168.1.100 - 192.168.1.150
```

creates a conventional continuous DHCP pool.

### Fragmented Range Example

Multiple ranges can be configured when only specific portions of the subnet should be available for DHCP:

```text
192.168.1.50 - 192.168.1.60
192.168.1.178 - 192.168.1.179
```

The corresponding dnsmasq configuration contains separate `dhcp-range` entries.

### Location

```text
/usr/sbin/set-dhcp-range
```

### Related Documentation

See [DHCP Range Configuration](../networking/set-dhcp-range.md).

---

## `dhcp-mode`

Controls whether DHCP service is available through the router's wired Ethernet ports.

### Usage

```sh
dhcp-mode ON
dhcp-mode OFF
dhcp-mode COGNEX_ON
```

### Modes

| Mode        | Description                                                          |
| ----------- | -------------------------------------------------------------------- |
| `ON`        | Allows DHCP traffic on all wired LAN ports.                          |
| `OFF`       | Blocks DHCP traffic on all wired LAN ports.                          |
| `COGNEX_ON` | Allows DHCP only for devices matching the Cognex MAC address prefix. |

### Check Current Mode

Run the command without a valid mode to display its usage information:

```sh
dhcp-mode
```

### Location

```text
/usr/bin/dhcp-mode
```

The tool manages the nftables rules stored in:

```text
/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

### Related Documentation

See [DHCP Modes](../networking/dhcp-modes.md).

---

## `reclaim-dhcp-lease`

Attempts to reclaim an inactive DHCP lease when the configured DHCP address pool has been exhausted.

This utility is normally called automatically by the DHCP exhaustion monitoring service and does not normally need to be run manually.

### Manual Usage

```sh
reclaim-dhcp-lease
```

Manual execution can be useful when testing or troubleshooting DHCP lease reclamation.

### Location

```text
/usr/sbin/reclaim-dhcp-lease
```

### Automatic Operation

Automatic lease reclamation is provided by several cooperating components:

```text
dnsmasq
   │
   │ DHCP pool exhaustion
   ▼
watch-dhcp-exhaustion
   │
   ▼
reclaim-dhcp-lease
   │
   ▼
Inactive lease removed
```

The monitoring process is managed by the `dhcp-reclaim` OpenWrt service.

### Related Components

```text
/etc/init.d/dhcp-reclaim
/etc/uci-defaults/95-enable-dhcp-reclaim
/usr/sbin/watch-dhcp-exhaustion
/usr/sbin/reclaim-dhcp-lease
```

### Related Documentation

See [DHCP Lease Reclamation](../networking/dhcp-lease-reclamation.md).

---

## `usb-eject`

Safely unmounts the USB storage device used by the router.

This command should be used before physically removing a USB drive.

### Usage

```sh
usb-eject
```

The tool synchronizes pending filesystem writes before attempting to unmount the USB storage device.

The primary USB mount point is:

```text
/mnt/usb
```

### Location

```text
/usr/bin/usb-eject
```

### Related Documentation

See [USB Storage](../services/usb-storage.md).

---

## `organize-by-date`

Organizes files in an FTP directory into date-based subdirectories according to each file's modification date.

### Usage

```sh
organize-by-date <directory>
```

For example:

```sh
organize-by-date /mnt/usb/FTP
```

Files such as:

```text
/mnt/usb/FTP/
├── image1.jpg
├── image2.jpg
└── image3.jpg
```

are moved into date-based directories:

```text
/mnt/usb/FTP/
├── 2026-08-10/
│   ├── image1.jpg
│   └── image2.jpg
└── 2026-08-11/
    └── image3.jpg
```

For safety, the utility only operates within approved FTP storage locations.

### Location

```text
/usr/bin/organize-by-date
```

### Related Documentation

See [USB Storage](../services/usb-storage.md).

---

# Supporting Components

The custom image also contains several scripts and configuration files that operate automatically. These are not normally invoked directly by the user.

## DHCP Exhaustion Monitor

```text
/usr/sbin/watch-dhcp-exhaustion
```

Monitors the OpenWrt system log for DHCP pool exhaustion messages generated by `dnsmasq`.

When exhaustion is detected, it invokes:

```text
/usr/sbin/reclaim-dhcp-lease
```

The monitor is supervised by the `dhcp-reclaim` service.

See [DHCP Lease Reclamation](../networking/dhcp-lease-reclamation.md).

---

## DHCP Reclamation Service

```text
/etc/init.d/dhcp-reclaim
```

OpenWrt `procd` service responsible for starting and supervising the DHCP exhaustion monitor.

The service can be inspected using standard OpenWrt service commands:

```sh
/etc/init.d/dhcp-reclaim status
```

It can also be manually restarted:

```sh
/etc/init.d/dhcp-reclaim restart
```

See [DHCP Lease Reclamation](../networking/dhcp-lease-reclamation.md).

---

## DHCP Reclamation First-Boot Configuration

```text
/etc/uci-defaults/95-enable-dhcp-reclaim
```

Enables the DHCP reclamation service during initial router configuration.

This script is intended to run automatically as part of OpenWrt's `uci-defaults` first-boot process.

See [DHCP Lease Reclamation](../networking/dhcp-lease-reclamation.md).

---

## Wired DHCP nftables Rules

```text
/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

Contains the nftables rules used by `dhcp-mode` to control DHCP traffic on the wired Ethernet interfaces.

The contents of this file are managed automatically by:

```text
/usr/bin/dhcp-mode
```

Manual modification is generally unnecessary because changing the DHCP mode regenerates the file.

See [DHCP Modes](../networking/dhcp-modes.md).

---

## USB Hotplug Handler

```text
/etc/hotplug.d/block/99-usb-alias
```

Handles supported USB storage devices when they are connected to the router.

The script creates and manages the standard USB storage mount point:

```text
/mnt/usb
```

This allows other tools and services to use a consistent path regardless of the underlying block device name.

See [USB Storage](../services/usb-storage.md).

---

# Quick Reference

| Command                        | Purpose                                            |
| ------------------------------ | -------------------------------------------------- |
| `provision-router`             | Configure a newly installed router                 |
| `set-dhcp-range`               | Configure consecutive or fragmented DHCP ranges    |
| `dhcp-mode ON`                 | Enable DHCP on wired LAN ports                     |
| `dhcp-mode OFF`                | Disable DHCP on wired LAN ports                    |
| `dhcp-mode COGNEX_ON`          | Enable wired DHCP only for Cognex devices          |
| `reclaim-dhcp-lease`           | Manually attempt to reclaim an inactive DHCP lease |
| `usb-eject`                    | Safely unmount USB storage                         |
| `organize-by-date <directory>` | Organize FTP files into date-based directories     |

## Service Commands

| Command                            | Purpose                            |
| ---------------------------------- | ---------------------------------- |
| `/etc/init.d/dhcp-reclaim status`  | Check the DHCP reclamation service |
| `/etc/init.d/dhcp-reclaim start`   | Start DHCP exhaustion monitoring   |
| `/etc/init.d/dhcp-reclaim stop`    | Stop DHCP exhaustion monitoring    |
| `/etc/init.d/dhcp-reclaim restart` | Restart DHCP exhaustion monitoring |

---

> [!NOTE] Most supporting scripts and configuration files should not need to be executed or modified manually. The user-facing commands listed in the **Quick Reference** section should be used whenever possible.