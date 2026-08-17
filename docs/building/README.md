# Build and Maintain the Image

The repository uses OpenWrt ImageBuilder rather than compiling OpenWrt from source.

## Quick build

From an x86-64 Linux environment:

```bash
./build/build.sh <image-version> [openwrt-version]
```

Example:

```bash
./build/build.sh 1.6.1 24.10.5
```

Generated firmware is copied to `output/`.

## Guides

| Guide | Purpose |
|---|---|
| [ImageBuilder](image-builder.md) | Requirements, build workflow, output, customization, and troubleshooting |
| [Filesystem overlay](filesystem-overlay.md) | How repository files become files on the router |
| [LuCI custom tools](luci-custom-tools.md) | Implementation details for the custom LuCI DHCP control |

## Source directories

| Directory | Purpose |
|---|---|
| [`build/`](../../build/README.md) | Build script and package list |
| [`files/`](../../files/README.md) | Root-filesystem overlay |

Before publishing, complete the [sanitization review](../../SANITIZATION.md) and [publishing checklist](../../PUBLISHING_CHECKLIST.md).
