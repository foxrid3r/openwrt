# Tool Reference

These commands are included in the custom image. Run administrative commands as `root`.

| Command | Purpose | Details |
|---|---|---|
| `provision-router` | Configure a newly installed router | [`provision-router`](provision-router.md) |
| `set-dhcp-range` | Configure consecutive or fragmented DHCP pools | [`set-dhcp-range`](set-dhcp-range.md) |
| `dhcp-mode ON` | Allow normal wired DHCP | [`dhcp-mode`](dhcp-mode.md) |
| `dhcp-mode OFF` | Block DHCP on wired ports | [`dhcp-mode`](dhcp-mode.md) |
| `dhcp-mode COGNEX_ON` | Restrict wired DHCP to Cognex devices | [`dhcp-mode`](dhcp-mode.md) |
| `reclaim-dhcp-lease` | Manually attempt to reclaim one inactive lease | [Lease reclamation](dhcp-lease-reclamation.md) |
| `usb-eject` | Flush and safely unmount USB storage | [USB tools](usb-tools.md) |
| `organize-by-date <directory>` | Sort FTP files into date directories | [USB tools](usb-tools.md) |

## Supporting components

The image also contains services and scripts that normally run automatically:

| Component | Purpose |
|---|---|
| `watch-dhcp-exhaustion` | Watches dnsmasq logs for pool exhaustion |
| `/etc/init.d/dhcp-reclaim` | Supervises the exhaustion monitor |
| `95-enable-dhcp-reclaim` | Enables reclamation during first boot |
| `99-usb-alias` | Mounts supported USB storage at `/mnt/usb` |

See the [custom image overview](../custom-image/README.md) for feature-oriented documentation.
