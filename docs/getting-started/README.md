# Getting Started

Start here when installing or deploying the custom image on a Linksys E8450 / Belkin RT3200.

## New router or stock Linksys firmware

Follow [Flashing the Linksys E8450](flashing-e8450.md). The first-time process converts the router to the OpenWrt UBI layout and includes a required backup of its device-specific vendor bootchain.

## Router running OpenWrt 23.05.x or an older snapshot

Do not flash an OpenWrt 24.10.x-based image directly. Start with [Determine your upgrade path](flashing-e8450.md#determine-your-upgrade-path), preserve the vendor bootchain backup, and follow the current upstream layout-migration instructions.

## Router running OpenWrt 24.10.x or the current UBI layout

Go directly to [Install the final firmware](flashing-e8450.md#install-the-final-firmware). Do not run the UBI installer again unless current upstream migration instructions explicitly require it.

## After flashing

Run the interactive provisioning utility:

```sh
provision-router
```

The [provisioning guide](provisioning.md) explains each prompt and the factory defaults. Next, review the [custom image overview](../custom-image/README.md) and [tool reference](../tools/README.md).
