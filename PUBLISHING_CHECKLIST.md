# Publishing Checklist

Use this checklist before publishing repository changes or a firmware release.

## Repository

- [ ] Documentation links and image references resolve.
- [ ] `git diff --check` passes.
- [ ] The [sanitization review](SANITIZATION.md) is complete.
- [ ] No generated firmware is staged for commit.
- [ ] The project license and redistribution terms have been reviewed.

## Firmware

- [ ] The intended custom-image and OpenWrt versions appear in the filename and login banner.
- [ ] LuCI displays the expected custom-image name, image version, and build date under **Status → Overview → System**.
- [ ] The image was produced from a known commit with a clean or documented worktree.
- [ ] A SHA-256 checksum was recorded.
- [ ] The sysupgrade image was tested on the intended E8450 UBI upgrade path.
- [ ] First boot, provisioning, LuCI, SSH, DHCP modes, NTP, FTP, and USB handling were tested as applicable.
- [ ] Factory-reset and recovery behavior were considered.

## Release notes

- [ ] State the required starting firmware/layout and whether settings must be retained.
- [ ] Link to the [flashing guide](docs/getting-started/flashing-e8450.md).
- [ ] List important default behavior and any breaking configuration changes.
- [ ] Attach checksums and tested firmware artifacts to the release rather than committing them.
