
# DHCP Modes

The custom image provides the `dhcp-mode` command for controlling whether DHCP traffic is permitted on the router's wired LAN ports.

The feature is implemented with OpenWrt `firewall4` and nftables.

## Purpose

Industrial machine networks often contain equipment with fixed IP addresses. Allowing an arbitrary laptop or other temporary device to obtain a DHCP address can be undesirable.

`dhcp-mode` provides three runtime modes:

| Mode | Behavior |
|---|---|
| `ON` | Normal wired DHCP; no custom DHCP filtering |
| `OFF` | Block DHCP on all wired LAN ports |
| `COGNEX_ON` | Allow DHCP only for Cognex devices identified by OUI `00:d0:24` |

The factory image ships in:

```text
COGNEX_ON
```

## Usage

Run as `root`:

```sh
dhcp-mode ON
```

```sh
dhcp-mode OFF
```

```sh
dhcp-mode COGNEX_ON
```

The command is installed at:

```text
/usr/bin/dhcp-mode
```

## Affected Interfaces

The current rules apply to:

```text
lan1
lan2
lan3
lan4
```

The Wi-Fi interfaces are not filtered by this mechanism.

## How It Works

`dhcp-mode` generates the nftables include file:

```text
/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

After replacing the file, it reloads the OpenWrt firewall:

```sh
/etc/init.d/firewall reload
```

The file is written through a temporary file and atomically moved into place so the active rules file is not left partially written.

## `ON`

`ON` means DHCP is enabled normally on the wired ports.

The managed nftables include file is emptied, so no custom wired-DHCP filtering rules are applied.

```sh
dhcp-mode ON
```

## `OFF`

`OFF` blocks both directions of DHCP on `lan1` through `lan4`:

- Client-to-server DHCP requests using UDP destination port 67.
- Server-to-client DHCP responses using UDP source port 67.

```sh
dhcp-mode OFF
```

Other non-DHCP Ethernet traffic is unaffected by these custom rules.

## `COGNEX_ON`

`COGNEX_ON` allows DHCP only when the Ethernet MAC address matches the Cognex OUI:

```text
00:d0:24
```

The nftables mask:

```text
ff:ff:ff:00:00:00
```

compares only the first three bytes of the MAC address.

For client-to-server traffic, the source MAC is checked. For server-to-client traffic, the destination MAC is checked.

All other wired DHCP traffic is dropped.

## Factory Rule File

The image overlay contains a pre-populated:

```text
/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

with the `COGNEX_ON` rules.

This makes `COGNEX_ON` the effective factory behavior before `dhcp-mode` is run for the first time.

## Verification

Display the custom bridge filter table:

```sh
nft list table bridge filter
```

You can also inspect the generated include file:

```sh
cat /usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

For `ON`, the file should be empty.

For `OFF` or `COGNEX_ON`, it should contain the corresponding bridge-filter rules.

## Troubleshooting

### Command Must Run as Root

If run without root privileges, the command exits with:

```text
ERROR: must run as root
```

### Firewall Reload Fails

The command may successfully replace the rule file but fail while reloading the firewall.

Inspect firewall configuration and logs:

```sh
/etc/init.d/firewall restart
logread -e firewall
```

### Verify Interface Names

The current rules explicitly reference:

```text
lan1
lan2
lan3
lan4
```

If the hardware configuration changes, update both `dhcp-mode` and the factory nftables include file so the interface names remain consistent.

## Files

| File | Purpose |
|---|---|
| `/usr/bin/dhcp-mode` | User-facing mode-selection command |
| `/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft` | Active generated nftables rules |

## Related Documentation

- [DHCP Range Configuration](set-dhcp-range.md)
- [DHCP Lease Reclamation](dhcp-lease-reclamation.md)
- [Tool Reference](README.md)
