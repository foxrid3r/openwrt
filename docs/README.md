# Documentation

Choose the path that matches what you are doing.

## Install and operate

| Start here | Use it for |
|---|---|
| [Getting started](getting-started/README.md) | Choosing the correct installation path and completing first setup |
| [Flash the Linksys E8450](getting-started/flashing-e8450.md) | Stock-to-OpenWrt conversion, bootchain backup, and custom-image upgrades |
| [Provision the router](getting-started/provisioning.md) | Changing factory identity, networking, Wi-Fi, DHCP, and credentials |
| [Custom image](custom-image/README.md) | Defaults, architecture, services, and behavior |
| [Tool reference](tools/README.md) | Commands included in the image |

## Build and maintain

| Start here | Use it for |
|---|---|
| [Building overview](building/README.md) | The shortest path to a build and links to maintainer guides |
| [ImageBuilder guide](building/image-builder.md) | Complete build workflow and troubleshooting |
| [Filesystem overlay](building/filesystem-overlay.md) | How files are embedded into the image |
| [LuCI custom tools](building/luci-custom-tools.md) | LuCI implementation details |

## Common tasks

| Task | Documentation |
|---|---|
| Install OpenWrt on a stock E8450 | [First-time installation](getting-started/flashing-e8450.md#first-time-openwrt-installation) |
| Install this image on a compatible OpenWrt E8450 | [Install the final firmware](getting-started/flashing-e8450.md#install-the-final-firmware) |
| Change deployment settings | [Router provisioning](getting-started/provisioning.md) |
| Allow or block wired DHCP | [`dhcp-mode`](tools/dhcp-mode.md) |
| Change the DHCP pool | [`set-dhcp-range`](tools/set-dhcp-range.md) |
| Safely remove a USB drive | [USB tools](tools/usb-tools.md) |
| Produce a firmware image | [ImageBuilder guide](building/image-builder.md) |
