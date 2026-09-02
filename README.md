# Linksys E8450 Custom OpenWrt Image

This repository documents and builds a custom OpenWrt image for the Linksys E8450 / Belkin RT3200. It is primarily an end-user guide for flashing and operating the router. It also contains the ImageBuilder inputs needed to reproduce the firmware.

> [!CAUTION]
> Flashing firmware can make a router unbootable. Read the complete installation guide before starting, use an image intended for the Linksys E8450 UBI layout, and preserve the router's device-specific bootchain backup.

## Getting started

| Current setup or goal | Next step |
|---|---|
| New Linksys E8450 or Belkin RT3200 | [Install OpenWrt or the custom image](docs/getting-started/flashing-e8450.md) |
| Custom image already installed | [Provision the router](docs/getting-started/provisioning.md) |
| Stock OpenWrt already installed | [Determine the correct upgrade path](docs/getting-started/flashing-e8450.md#determine-your-upgrade-path) |
| Review image defaults and features | [Read the custom image documentation](docs/custom-image/README.md) |
| Look up included tools and commands | [Browse the tools reference](docs/tools/README.md) |
| Build the custom image | [Follow the ImageBuilder guide](docs/building/image-builder.md) |

> [!NOTE]
> OpenWrt 23.05.x and older layouts require migration before installing a 24.10.x-based image. Routers already using the current UBI layout use a normal sysupgrade.

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

## Building firmware

See the [ImageBuilder guide](docs/building/image-builder.md) for setup and build requirements.

From the repository root, run:

```bash
./build/build.sh <image-version> [openwrt-version]
```

For example:

```bash
./build/build.sh 1.6.1 24.10.5
```

Build inputs are defined by the [package list](build/packages.txt) and [filesystem overlay](files/README.md). Generated firmware is written to `output/`, which is ignored by Git.

## Factory credentials

| Service | Username/SSID | Factory password |
|---|---|---|
| SSH / LuCI | `root` | `Admin12345!` |
| Machine Wi-Fi | Spare1 | `Admin12345!` |
| FTP | `admin` | `admin` |

> [!IMPORTANT]
> These credentials are published in this repository and are not secrets. Run `provision-router` after installation and change deployment credentials as appropriate. The FTP password is separate and can be changed with `passwd admin`.

## Repository map

| Path | Contents |
|---|---|
| [`docs/`](docs/README.md) | Installation, operation, feature, and build documentation |
| [`build/`](build/README.md) | Build script and package selection |
| [`files/`](files/README.md) | Files copied into the image's root filesystem |
| [`hotfixes/`](hotfixes/README.md) | Versioned fixes for already-deployed images |
| `output/` | Locally generated firmware; not committed |

Before publishing, complete the [repository sanitization review](SANITIZATION.md) and [publishing checklist](PUBLISHING_CHECKLIST.md). Tested firmware images should be distributed through GitHub Releases, not committed to the repository.

## Project status

A project license has not yet been selected. Add a license before redistributing the repository or its custom files.
