# OpenWrt Machine Router

Custom OpenWrt firmware configuration for the Linksys E8450 / Belkin RT3200 used as a portable industrial machine-network router.

## Features

- Reproducible ImageBuilder-based firmware build
- Interactive router provisioning
- Consecutive and fragmented DHCP pool configuration
- Automatic DHCP lease reclamation
- Wired DHCP filtering modes
- USB storage auto-mount/eject tools
- vsftpd-based FTP service
- NTP/uplink configuration
- Custom LuCI tooling
- Versioned login banner

## Repository layout

- `build/` — reproducible firmware build script and package list
- `files/` — OpenWrt ImageBuilder filesystem overlay
- `docs/` — GitHub-native Markdown documentation
- `output/` — generated firmware (ignored by Git)

## Build

On a Linux system with the OpenWrt ImageBuilder dependencies installed:

```bash
./build/build.sh 1.6.1 24.10.5
```

The script downloads and verifies the requested ImageBuilder, applies the `files/` overlay, generates the version banner, builds the Linksys E8450 UBI image, and copies generated firmware into `output/`.

See [docs/image-builder/custom-image.md](docs/image-builder/custom-image.md) for background and setup notes.

## First-boot credentials

The custom image includes shared factory credentials so a newly flashed router can be accessed and provisioned immediately.

| Service | Username | Factory password |
|---|---|---|
| SSH / LuCI | `root` | `Admin12345!` |
| Machine Wi-Fi | — | `Admin12345!` |
| FTP | `admin` | `admin` |

The NTP uplink intentionally uses placeholder values (`CHANGE_ME_INTERNET_NETWORK` and `CHANGE_ME_PASSWORD`) rather than credentials for a real external Wi-Fi network.

> [!IMPORTANT]
> These factory credentials are stored in this public repository and must be treated as public, shared bootstrap credentials. Change deployment-specific credentials when unique credentials are required.

The router provisioning utility can be run with:

```sh
provision-router
```

See [Router Provisioning](docs/installation/provisioning.md).

The FTP password is managed separately from `provision-router` and can be changed with:

```sh
passwd admin
```

## Documentation

Start with [docs/README.md](docs/README.md).

For a quick command summary, see the [Tool Reference](docs/tool-reference/tool-reference.md).

## Releases

Do not commit generated firmware images to the repository. Attach tested images to GitHub Releases instead.

## License

A project license has not been selected yet. Choose and add an appropriate license before publishing publicly.
