# DHCP Behavior

The custom image adds three capabilities on top of the normal OpenWrt DHCP service.

## Address-pool configuration

`set-dhcp-range` configures either one consecutive pool or several fragmented ranges. Fragmented ranges are useful when fixed-address industrial devices occupy gaps in the subnet.

See [`set-dhcp-range`](../tools/set-dhcp-range.md).

## Wired-port filtering

`dhcp-mode` controls DHCP on `lan1` through `lan4` without disabling other Ethernet traffic.

| Mode | Behavior |
|---|---|
| `ON` | Allow normal wired DHCP |
| `OFF` | Block wired DHCP requests and responses |
| `COGNEX_ON` | Allow wired DHCP only for MAC addresses with Cognex OUI `00:d0:24` |

The factory mode is `COGNEX_ON`. See [`dhcp-mode`](../tools/dhcp-mode.md).

## Lease reclamation

The `dhcp-reclaim` service watches for pool-exhaustion messages. When the pool is full, it conservatively tests candidate leases and removes at most one inactive lease before restarting dnsmasq.

See [DHCP lease reclamation](../tools/dhcp-lease-reclamation.md).

## Related files

| Router path | Purpose |
|---|---|
| `/usr/sbin/set-dhcp-range` | Pool configuration utility |
| `/usr/bin/dhcp-mode` | Wired filtering utility |
| `/usr/sbin/watch-dhcp-exhaustion` | Exhaustion monitor |
| `/usr/sbin/reclaim-dhcp-lease` | Conservative lease removal |
| `/etc/init.d/dhcp-reclaim` | OpenWrt service definition |
| `/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft` | Generated filtering rules |
