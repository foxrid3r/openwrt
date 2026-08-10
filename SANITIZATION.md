# Archive sanitization notes

This repository was reorganized from a larger engineering archive. The following material was intentionally excluded from the GitHub-ready copy:

- Device-specific boot/MTD backups
- Router configuration backup archives
- Prebuilt custom firmware images
- Downloaded OpenWrt ImageBuilder archives
- Linksys/OpenWrt installer and recovery binaries
- Third-party executables, drivers, ZIP/IPK recovery utilities
- Generated PDF copies of Markdown documentation
- Duplicate copies of router scripts stored beside documentation
- Root/FTP password hashes and `/etc/shadow`
- Dropbear SSH host private keys
- Real Wi-Fi passwords
- Device label/template office document

Generated firmware belongs in GitHub Releases; upstream and third-party tools should be linked from documentation rather than vendored into this repository.
