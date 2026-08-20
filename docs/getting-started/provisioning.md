
# Router Provisioning

The custom OpenWrt image includes the `provision-router` utility for configuring settings that commonly need to be unique for each deployed router.

The utility can configure:

- Hostname
- Root password
- LAN IP address and subnet mask
- Standard consecutive DHCP pool
- Machine-network Wi-Fi SSID and password
- NTP-uplink Wi-Fi SSID and password

Pressing **Enter** at any prompt leaves that setting unchanged.

## Running the Provisioning Utility

Connect to the router through SSH and run:

```sh
provision-router
```

The utility is installed at:

```text
/usr/sbin/provision-router
```

It displays the current configuration, prompts for changes, shows a summary, and asks for confirmation before applying anything.

## Factory Image Defaults

A newly flashed image uses the following defaults:

| Setting | Factory Default |
|---|---|
| Hostname | `Spare1` |
| LAN IP | `192.168.1.123` |
| LAN netmask | `255.255.255.0` |
| DHCP start | `192.168.1.124` |
| DHCP end | `192.168.1.128` |
| Machine Wi-Fi SSID | `Spare1` |
| Machine Wi-Fi password | `Admin12345!` |
| Root username | `root` |
| Root password | `Admin12345!` |
| FTP username | `admin` |
| FTP password | `admin` |
| Wired DHCP mode | `COGNEX_ON` |
| NTP uplink SSID | `CHANGE_ME_INTERNET_NETWORK` |
| NTP uplink password | `CHANGE_ME_PASSWORD` |

> [!IMPORTANT]
> The factory passwords are shared bootstrap credentials and are visible in the public repository. Change them when unique deployment credentials are required.

`provision-router` changes the root password and Wi-Fi credentials, but it does **not** change the FTP `admin` password. Change the FTP password separately with:

```sh
passwd admin
```

## Provisioning Process

The utility walks through each setting and displays the current value when appropriate.

Example:

```text
Hostname [Spare1] (blank = unchanged):
```

Press **Enter** to keep `Spare1`, or enter a new value.

Before applying changes, the utility prints a summary showing which values will change and asks:

```text
Proceed? [y/N]:
```

No changes are made unless the operation is confirmed.

## Hostname

The hostname identifies the router on the local network.

The machine-router hostname accepts:

```text
A-Z
a-z
0-9
_
-
```

Periods are not permitted.

Example:

```text
Spare2
```

The hostname and machine Wi-Fi SSID are independent settings and may be different.

## Root Password

The OpenWrt `root` password is used for administrative access through SSH and LuCI.

Enter a new password when prompted, or press **Enter** to retain the current password.

Changing the root password does not change the machine Wi-Fi or FTP passwords.

## LAN Network Configuration

The default LAN configuration is:

```text
IP address: 192.168.1.123
Netmask:    255.255.255.0
```

The LAN address is used to access both SSH and LuCI.

For example:

```sh
ssh root@192.168.1.123
```

and:

```text
http://192.168.1.123/
```

The utility validates IPv4 addresses and only accepts contiguous IPv4 netmasks.

## DHCP Configuration

`provision-router` manages a standard consecutive OpenWrt/UCI DHCP pool.

The factory pool is:

```text
192.168.1.124 - 192.168.1.128
```

The utility prompts for complete start and end addresses:

```text
DHCP pool start address [192.168.1.124] (blank = unchanged):
DHCP pool end address [192.168.1.128] (blank = unchanged):
```

Internally, OpenWrt stores the pool using a subnet-relative `start` value and a `limit`.

For the factory `/24` network:

```text
Start address: 192.168.1.124
UCI start:     124
Limit:         5
```

The utility verifies that:

- Both addresses are valid IPv4 addresses.
- Both addresses are within the configured LAN subnet.
- The start address is less than or equal to the end address.
- The router's own LAN IP is not inside the DHCP pool.
- Both DHCP fields are entered together or both are left blank.

## Fragmented DHCP Ranges

Fragmented DHCP ranges are managed by the separate `set-dhcp-range` utility.

In fragmented mode, the active ranges are stored in:

```text
/etc/dnsmasq.d/custom-ranges.conf
```

and the normal UCI DHCPv4 server is disabled.

If fragmented mode is active, `provision-router` should report that condition before prompting for DHCP addresses.

To preserve the fragmented pool, leave both DHCP prompts blank.

Entering a new DHCP start and end range intentionally switches the router back to the standard consecutive UCI DHCP mode by:

1. Removing any old `dhcp.lan.ignore` flag.
2. Setting `dhcp.lan.dhcpv4='server'`.
3. Writing the new UCI `start` and `limit`.
4. Removing `/etc/dnsmasq.d/custom-ranges.conf`.
5. Restarting `dnsmasq`.

For fragmented or specialized pool configuration, see [DHCP Range Configuration](../tools/set-dhcp-range.md).

## Machine-Network Wi-Fi

The machine-network access point runs on `radio1`.

`provision-router` automatically locates the `radio1` AP interface and can change its:

- SSID
- WPA2-PSK passphrase

The factory SSID is:

```text
Spare1
```

The factory password is:

```text
Admin12345!
```

The machine SSID uses the same character restrictions as the hostname: letters, numbers, underscores, and hyphens; periods are not permitted.

Changing the machine-network Wi-Fi settings causes Wi-Fi to reload and may disconnect wireless clients.

## NTP Uplink Wi-Fi

The separate NTP uplink uses a station interface on `radio0` attached to:

```text
ntp_uplink
```

The factory image contains placeholder credentials:

```text
SSID:     CHANGE_ME_INTERNET_NETWORK
Password: CHANGE_ME_PASSWORD
```

The uplink SSID is accepted as entered because it must match an external network and may contain spaces, periods, or other printable characters.

When changing only the uplink password, the utility preserves the interface's existing encryption mode.

The NTP uplink is intentionally isolated from the machine LAN and permits only DHCP plus NTP traffic to the configured upstream servers. It accepts a DHCP default route for gateway reachability but does not accept peer DNS or permit general Internet traffic unless [temporary maintenance access](../custom-image/ntp-uplink.md#temporary-maintenance-access) is enabled. See [NTP](../custom-image/ntp-uplink.md) for the complete policy.

## Applying Changes

Depending on what was changed, the utility may:

- Commit `system` configuration changes.
- Commit `network` configuration changes.
- Commit `dhcp` configuration changes.
- Commit `wireless` configuration changes.
- Reload Wi-Fi.
- Restart `dnsmasq` after a hostname or DHCP change.
- Restart the network service.
- Change the root password.

If the LAN IP or netmask changes, the SSH connection may be interrupted.

After a hostname change, dnsmasq is restarted so clients can resolve the new
`<hostname>.lan` name. Bare-hostname resolution depends on the client's DHCP
search-domain behavior.

## After Changing the LAN IP

If the router is changed from:

```text
192.168.1.123
```

to:

```text
192.168.1.124
```

reconnect using the new address:

```sh
ssh root@192.168.1.124
```

A DHCP-connected computer may also need to renew its address.

## Re-running Provisioning

`provision-router` can be run again at any time.

This is useful when:

- Reassigning a router to another machine.
- Changing the hostname.
- Changing the LAN subnet.
- Changing a normal consecutive DHCP pool.
- Changing machine Wi-Fi credentials.
- Changing NTP uplink credentials.
- Changing the root password.

## Related Tools

For consecutive or fragmented DHCP ranges:

```sh
set-dhcp-range
```

See [DHCP Range Configuration](../tools/set-dhcp-range.md).

To control DHCP availability on wired ports:

```sh
dhcp-mode ON
dhcp-mode OFF
dhcp-mode COGNEX_ON
```

See [DHCP Modes](../tools/dhcp-mode.md).

For a complete command summary, see the [Tool Reference](../tools/README.md).

## Provisioning Summary

For a newly installed router:

1. Flash and boot the custom image.
2. Connect to the router.
3. SSH to the factory LAN IP.
4. Run `provision-router`.
5. Change the required settings.
6. Leave unwanted changes blank.
7. Review the summary and confirm.
8. Reconnect if the LAN address changed.
9. Change the FTP password separately if required.
10. Verify LAN, DHCP, Wi-Fi, and NTP-uplink operation.
