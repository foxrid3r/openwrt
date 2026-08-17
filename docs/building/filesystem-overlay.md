# Filesystem Overlay

The `files/` directory is the filesystem overlay passed to OpenWrt ImageBuilder. Its paths mirror the finished router's root filesystem.

For example:

```text
files/usr/sbin/provision-router  ->  /usr/sbin/provision-router
files/etc/config/network         ->  /etc/config/network
```

## What belongs in the overlay

- OpenWrt UCI configuration defaults
- User-facing scripts and supporting services
- `uci-defaults` first-boot scripts
- Hotplug handlers
- nftables includes
- LuCI application files
- The login-banner template

## Safety boundary

Everything under `files/` may be embedded in a published firmware image. Never add router backups, private keys, calibration data, real external-network credentials, or other deployment secrets.

## Executable files

The build script marks files under `files/usr/bin` and `files/usr/sbin` executable in its temporary ImageBuilder tree. It also sets permissions on the known hotplug, init, and `uci-defaults` scripts.

## Making changes

Overlay edits affect newly built images, not routers that have already been flashed. Rebuild and reinstall the image, or make the equivalent change directly on a development router.

See the [`files/` directory reference](../../files/README.md) for a path-by-path overview and the [ImageBuilder guide](image-builder.md) for the complete build workflow.
