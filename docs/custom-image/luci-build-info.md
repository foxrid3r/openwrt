# LuCI Build Information

The custom image displays its identity and build information in:

**LuCI → Status → Overview → System**

## Displayed fields

| Field | Description |
|---|---|
| Custom Image | Name of the custom firmware distribution |
| Image Version | Custom image version supplied to `build.sh` |
| Build Date | Date and time when the image was built |
| Applied Hotfixes | Post-build fixes installed on the router, or `None` |

These fields make it easier to identify the installed firmware when troubleshooting, comparing deployed routers, or confirming that an upgrade succeeded.

The standard OpenWrt firmware, kernel, and LuCI versions remain visible in the same System panel.

Applied hotfixes are read from `/etc/custom-hotfixes.json`. This state is kept
separate from `/etc/custom-image.json` so installing a hotfix does not change
the identity or version of the underlying firmware image.

## Missing information

If a custom-image field displays `?`, LuCI could not read a valid value from `/etc/custom-image.json`. This can indicate that:

- The firmware was not produced by this repository's build script.
- A metadata file is missing or invalid.
- The LuCI session does not have permission to read the file.

The metadata describes the installed image; changing `/etc/custom-image.json` does not update or rebuild the firmware itself.

For implementation details, see [LuCI build metadata](../building/image-builder.md#luci-build-metadata).
