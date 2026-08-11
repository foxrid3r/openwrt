# Filesystem Overlay

This directory contains the filesystem overlay applied to the custom OpenWrt image during the ImageBuilder build process.

## How It Works

The directory structure under `files/` mirrors the root filesystem of the finished OpenWrt image.

For example:

```text
files/etc/config/network
```

becomes:

```text
/etc/config/network
```

on the router.

Similarly:

```text
files/usr/sbin/provision-router
```

becomes:

```text
/usr/sbin/provision-router
```

The build script passes this directory to OpenWrt ImageBuilder using the `FILES` option.

## Directory Structure

The overlay contains configuration files, scripts, services, first-boot configuration, firewall rules, and LuCI customizations used by the custom image.

```text
files/
├── etc/
│   ├── config/
│   ├── hotplug.d/
│   ├── init.d/
│   └── uci-defaults/
├── usr/
│   ├── bin/
│   ├── lib/
│   ├── sbin/
│   └── share/
└── www/
```

The exact contents may change as features are added or removed.

## `etc/config`

Contains OpenWrt UCI configuration included in the factory image.

Examples include configuration for:

* Network interfaces
* DHCP and dnsmasq
* Firewall
* Wireless interfaces
* System settings
* Filesystem mounting

These files establish the initial configuration present after flashing the custom image.

## `etc/uci-defaults`

Contains scripts that OpenWrt executes during first boot.

These scripts are used for initialization tasks that should occur once rather than every time the router starts.

After a `uci-defaults` script completes successfully, OpenWrt removes it from the running filesystem.

## `etc/init.d`

Contains OpenWrt service definitions included with the image.

These scripts integrate custom services with OpenWrt's `procd` service-management system.

## `etc/hotplug.d`

Contains scripts invoked automatically by OpenWrt in response to hardware or system events.

For example, USB storage handling is implemented through a block-device hotplug script.

## `usr/bin` and `usr/sbin`

Contain command-line utilities included with the image.

Examples include:

```text
provision-router
set-dhcp-range
dhcp-mode
usb-eject
organize-by-date
reclaim-dhcp-lease
watch-dhcp-exhaustion
```

See the [Tool Reference](../docs/tool-reference/tool-reference.md) for descriptions and usage.

## `usr/share`

Contains supporting files used by OpenWrt and the custom tools, including firewall/nftables configuration.

## `www`

Contains files used by the LuCI web interface and other web-accessible resources included with the image.

## Important

Files in this directory become part of the generated firmware image.

Changes made here therefore affect newly built images, not routers that have already been flashed.

To apply an overlay change to an existing router, either:

1. Make the equivalent change directly on the router, or
2. Build a new custom image and flash it.

> [!IMPORTANT]
> Do not place device-specific backups, SSH private keys, bootchain/MTD backups, or other private deployment data in this directory. Everything under `files/` is eligible to be included in the generated firmware image and committed to the repository.

## Documentation

For information about building the image, see:

* [Building the Custom Image](../docs/image-builder/building-custom-image.md)
* [Custom OpenWrt Image](../docs/image-builder/custom-image.md)

For information about the tools contained in the overlay, see:

* [Tool Reference](../docs/tool-reference/tool-reference.md)
