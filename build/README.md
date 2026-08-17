# Build Tools

This directory contains the files used to build the custom OpenWrt firmware image.

## Files

### `build.sh`

Downloads the requested OpenWrt ImageBuilder, verifies the download, applies the project's filesystem overlay, generates the versioned login banner, and builds the custom Linksys E8450 firmware image.

Run the script from the repository root:

```bash
./build/build.sh <image-version> <openwrt-version>
```

For example:

```bash
./build/build.sh 1.6.1 24.10.5
```

Generated firmware images are copied to:

```text
output/
```

### `packages.txt`

Contains the additional OpenWrt packages included in the custom image.

The build script reads this file when constructing the ImageBuilder `PACKAGES` argument.

## Requirements

The build process requires a Linux environment with the OpenWrt ImageBuilder dependencies installed.

Although WSL is not officially supported by ImageBuilder, it can be used for this workflow. See [Building the Custom Image](../docs/building/image-builder.md) for details.

## Documentation

For complete build instructions, prerequisites, WSL setup, troubleshooting, and an explanation of the build process, see:

* [Building the Custom Image](../docs/building/image-builder.md)
* [Custom OpenWrt Image](../docs/custom-image/README.md)

> [!NOTE]
> This README is intended only as a quick reference for the contents of the `build/` directory. The documentation under `docs/building/` is the authoritative build documentation.
