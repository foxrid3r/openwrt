# Linksys E8450 Custom OpenWrt Image

This repository documents and builds a custom OpenWrt image for the Linksys E8450 / Belkin RT3200. It is primarily an end-user guide for flashing and operating the router. It also contains the ImageBuilder inputs needed to reproduce the firmware.

> [!CAUTION]
> Flashing firmware can make a router unbootable. Read the complete installation guide before starting, use an image intended for the Linksys E8450 UBI layout, and preserve the router's device-specific bootchain backup.

## Choose your path

### I want to install or use the image

1. [Flash OpenWrt or upgrade to the custom image](docs/getting-started/flashing-e8450.md)
2. [Provision the router after flashing](docs/getting-started/provisioning.md)
3. [Review the custom image's defaults and features](docs/custom-image/README.md)
4. [Look up a built-in command](docs/tools/README.md)

Already running OpenWrt? Use [Determine your upgrade path](docs/getting-started/flashing-e8450.md#determine-your-upgrade-path) before flashing. OpenWrt 23.05.x and older layouts require migration before a 24.10.x-based image; routers already using the current UBI layout use a normal sysupgrade.

### I want to build the image

1. [Set up Linux or WSL and run the build](docs/building/image-builder.md)
2. Review the package list in [`build/packages.txt`](build/packages.txt)
3. Review the filesystem overlay in [`files/`](files/README.md)

The normal build command, run from the repository root, is:

```bash
./build/build.sh <image-version> [openwrt-version]
```

For example:

```bash
./build/build.sh 1.6.1 24.10.5
```

Generated firmware is copied to `output/`, which is ignored by Git.

## What the custom image includes

- Interactive first-run provisioning
- Consecutive or fragmented DHCP pools
- Wired-port DHCP filtering modes
- Automatic DHCP lease reclamation
- USB storage mounting and safe-eject tools
- A vsftpd FTP service
- A strictly filtered NTP-only uplink
- Custom LuCI controls and a versioned login banner

See [Custom Image Defaults and Features](docs/custom-image/README.md) for the configuration details.

## Factory credentials

| Service | Username | Factory password |
|---|---|---|
| SSH / LuCI | `root` | `Admin12345!` |
| Machine Wi-Fi | — | `Admin12345!` |
| FTP | `admin` | `admin` |

> [!IMPORTANT]
> These credentials are published in this repository and are not secrets. Run `provision-router` after installation and change deployment credentials as appropriate. The FTP password is separate and can be changed with `passwd admin`.

## Repository map

| Path | Contents |
|---|---|
| [`docs/`](docs/README.md) | Installation, operation, feature, and build documentation |
| [`build/`](build/README.md) | Build script and package selection |
| [`files/`](files/README.md) | Files copied into the image's root filesystem |
| `output/` | Locally generated firmware; not committed |

Before publishing, complete the [repository sanitization review](SANITIZATION.md) and [publishing checklist](PUBLISHING_CHECKLIST.md). Tested firmware images should be distributed through GitHub Releases, not committed to the repository.

## Project status

A project license has not yet been selected. Add a license before redistributing the repository or its custom files.
