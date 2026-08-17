# Building the Custom Image with OpenWrt ImageBuilder

This guide reproduces the repository's Linksys E8450 UBI firmware. The build script downloads and verifies OpenWrt ImageBuilder, applies the repository's package list and filesystem overlay, generates the login banner, and copies firmware artifacts to `output/`.

## Requirements

- An x86-64 Linux environment (native Linux or WSL 2)
- Internet access to `downloads.openwrt.org`
- Enough free space for ImageBuilder and its temporary output
- The repository checked out on a case-sensitive Linux filesystem

> [!NOTE]
> OpenWrt does not officially support building under WSL. If using WSL, keep the repository in the distro's Linux filesystem, such as `~/src/openwrt`, rather than `/mnt/c/...`.

## 1. Prepare Linux

On Ubuntu 24.04 or a similar Debian-based distribution:

```bash
sudo apt update
sudo apt install build-essential file libncurses-dev zlib1g-dev gawk git \
  gettext libssl-dev xsltproc rsync wget unzip python3 python3-setuptools zstd
```

### WSL setup

From PowerShell, install and start Ubuntu if needed:

```powershell
wsl --install -d Ubuntu-24.04
wsl -d Ubuntu-24.04
```

Clone or copy this repository into the WSL filesystem:

```bash
mkdir -p ~/src
cd ~/src
git clone <repository-url> openwrt
cd openwrt
```

## 2. Review the build inputs

The build is controlled by three inputs:

| Input | Purpose |
|---|---|
| [`build/build.sh`](../../build/build.sh) | Selects the E8450 UBI target, downloads ImageBuilder, and runs the build |
| [`build/packages.txt`](../../build/packages.txt) | Lists additional packages included in the image |
| [`files/`](../../files/README.md) | Filesystem overlay copied into the finished image |

Do not add router backups, private keys, calibration data, or deployment secrets to `files/`. Its contents can be embedded in firmware and committed publicly.

## 3. Build

Run the script from the repository root:

```bash
./build/build.sh <image-version> [openwrt-version]
```

Example:

```bash
./build/build.sh 1.6.1 24.10.5
```

- `image-version` is required and identifies this custom image.
- `openwrt-version` is optional; the script currently defaults to `24.10.5`.
- The device profile is fixed to `linksys_e8450-ubi`.

The script uses `${TMPDIR:-/tmp}/openwrt-build` as disposable workspace. It recreates that directory on each run.

### LuCI build metadata

During the build, `build.sh` generates `/etc/custom-image.json` in the temporary filesystem overlay. The file records the custom image name, the version passed to the script, and the build date:

```json
{
    "name": "INVIO Automation OpenWrt",
    "version": "1.6.1",
    "build_date": "2026-08-17 10:30 EDT"
}
```

The metadata flows through the image as follows:

```text
build/build.sh
      |
      v
/etc/custom-image.json
      |
      v
LuCI System status component
      |
      v
Status -> Overview -> System
```

| Repository path | Purpose |
|---|---|
| `build/build.sh` | Generates the metadata file for each build |
| `files/www/luci-static/resources/view/status/include/10_system.js` | Reads the file and adds the custom fields to LuCI's System panel |
| `files/usr/share/rpcd/acl.d/custom-image.json` | Grants authenticated LuCI sessions read access to the metadata file |

The LuCI component displays `?` when a field is absent or the metadata cannot be read or parsed. See [LuCI Build Information](../custom-image/luci-build-info.md) for the user-facing behavior.

## 4. Find and verify the result

Successful builds are copied to:

```text
output/
```

For a normal upgrade of an E8450 that already uses the compatible UBI layout, the relevant artifact is the file ending in:

```text
linksys_e8450-ubi-squashfs-sysupgrade.itb
```

Before distributing an image:

1. Confirm the filename, login banner, and LuCI build information contain the intended versions.
2. Record a checksum, for example with `sha256sum output/<filename>`.
3. Test the image on the intended hardware and upgrade path.
4. Publish the tested artifact through a release; do not commit it.

Follow the [final firmware installation instructions](../getting-started/flashing-e8450.md#install-the-final-firmware) when flashing it.

## Changing the image

### Add or remove packages

Edit [`build/packages.txt`](../../build/packages.txt), one package per line. Prefixing a package with `-` asks ImageBuilder to exclude it. Let ImageBuilder resolve ABI-versioned libraries rather than listing version-suffixed library packages directly.

### Add or change files

Edit the matching path below `files/`. For example, `files/usr/sbin/provision-router` becomes `/usr/sbin/provision-router` on the router. See the [overlay reference](../../files/README.md) for layout and safety notes.

The build script marks files in `files/usr/bin` and `files/usr/sbin`, plus the known service and first-boot scripts, executable in the temporary build tree.

### Change the default OpenWrt version or target

The default version, target, subtarget, and profile are near the top of `build/build.sh`. Verify that the matching ImageBuilder and device profile exist before changing them. OpenWrt upgrades can require device-specific migration steps, so also review the current [OpenWrt E8450 device page](https://openwrt.org/toh/linksys/e8450) and [UBI installer documentation](https://github.com/dangowrt/owrt-ubi-installer).

## Troubleshooting

### A required command is missing

The script checks for `wget`, `tar`, `sha256sum`, `awk`, `grep`, `sed`, and `make`. Install the missing command using your distribution's package manager.

### ImageBuilder cannot find a package

Confirm the package exists for the selected OpenWrt release and `mediatek/mt7622` target. Package names and availability can change between releases.

### Files are missing or have the wrong case

Build from a case-sensitive Linux filesystem. Windows-mounted paths under `/mnt/c` can cause subtle ImageBuilder failures.

### The image is too large

Remove nonessential packages from `build/packages.txt`. Do not flash an image that exceeds the device/profile size constraints reported by ImageBuilder.

## Manual ImageBuilder reference

The automated script is the supported workflow for this repository. For experimentation, ImageBuilder's core invocation is:

```bash
make image \
  PROFILE="linksys_e8450-ubi" \
  PACKAGES="<space-separated-package-list>" \
  FILES="files" \
  EXTRA_IMAGE_NAME="<custom-name>"
```

Run `make info` in an extracted ImageBuilder directory to list profiles and `make help` to see supported variables.
