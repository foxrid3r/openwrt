# Repository Sanitization

Review this repository before publishing changes or firmware. Files in the ImageBuilder overlay may become part of every generated image.

## Never commit or embed

- SSH private keys or private host keys
- Router bootchain, MTD, EEPROM, or calibration backups
- Configuration archives copied from deployed routers
- Real Wi-Fi, VPN, API, or external-service credentials
- Customer names, site names, serial numbers, or routable production addresses
- Firmware artifacts from `output/`

## Expected public values

The factory SSH/LuCI, Wi-Fi, and FTP credentials documented in this repository are shared bootstrap values. Treat them as public and change them during deployment.

## Review commands

From the repository root, inspect tracked and untracked files before publishing:

```bash
git status --short
git diff --check
git diff --cached
```

Also search changes for passwords, private-key headers, tokens, and device-specific identifiers. Automated secret scanning helps, but does not replace a manual review of `files/` and generated documentation.
