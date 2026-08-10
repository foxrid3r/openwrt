# INVIO OpenWrt Machine Router

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
- `tools/` — development/documentation utilities not installed on the router
- `output/` — generated firmware (ignored by Git)

## Build

On a Linux system with the OpenWrt ImageBuilder dependencies installed:

```bash
./build/build.sh 1.6.1 24.10.5
```

The script downloads and verifies the requested ImageBuilder, applies the `files/` overlay, generates the version banner, builds the Linksys E8450 UBI image, and copies generated firmware into `output/`.

See [docs/image-builder/custom-image.md](docs/image-builder/custom-image.md) for background and setup notes.

## First-boot security

This public repository intentionally contains **no root password hashes, FTP password hashes, SSH host private keys, or real Wi-Fi passwords**. The sample wireless configuration uses `CHANGE_ME_*` values. Set deployment-specific credentials before use.

The FTP-only `admin` account is created with a locked password. Set it after first boot with:

```sh
passwd admin
```

The router provisioning utility can be run with:

```sh
provision-router
```

## Documentation

Start with [docs/README.md](docs/README.md).

## Releases

Do not commit generated firmware images to the repository. Attach tested images to GitHub Releases instead.

## License

A project license has not been selected yet. Choose and add an appropriate license before publishing publicly.
