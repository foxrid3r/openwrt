
# NTP Uplink

The custom image uses the router's 2.4 GHz radio as an isolated upstream Wi-Fi client so the router can obtain accurate network time without providing general Internet access to the machine LAN.

## Overview

The design uses:

```text
radio0
    │
    ▼
Wi-Fi station
    │
    ▼
network: ntp_uplink
    │
    ├── DHCP client
    ├── no peer DNS
    ├── no default route
    ├── metric 50
    ├── host routes to NIST NTP servers
    └── firewall allows only DHCP and selected NTP traffic
```

The 5 GHz `radio1` remains the machine-network access point.

## Factory Uplink Configuration

The factory wireless configuration contains a `radio0` station interface attached to:

```text
ntp_uplink
```

with placeholder credentials:

```text
SSID:     CHANGE_ME_INTERNET_NETWORK
Password: CHANGE_ME_PASSWORD
```

Configure the real upstream SSID and password with:

```sh
provision-router
```

See [Router Provisioning](../getting-started/provisioning.md).

## Network Interface

The `ntp_uplink` interface uses DHCP:

```text
config interface 'ntp_uplink'
        option proto 'dhcp'
        option peerdns '0'
        option defaultroute '0'
        option metric '50'
```

- `peerdns '0'` prevents the upstream network from supplying DNS servers to the router.
- `defaultroute '0'` prevents DHCP from installing a general Internet route.

## NTP Host Routes

The factory network configuration includes explicit routes to:

```text
129.6.15.28
132.163.96.1
```

through `ntp_uplink`.

These are also the NTP servers configured in `/etc/config/system`.

Using literal IP addresses avoids needing DNS resolution for the NTP service. Because the interface does not install a default route, these `/32` routes also limit the reachable external destinations to the selected NTP servers.

## Firewall Isolation

The `ntp_uplink` firewall zone uses:

```text
Input:   REJECT
Output:  REJECT
Forward: REJECT
```

The zone is attached only to:

```text
ntp_uplink
```

There are no forwarding rules between the machine LAN and the NTP uplink. Explicit traffic rules allow only the traffic required to acquire an IPv4 address and contact the configured NTP servers:

| Rule | Allowed traffic |
|---|---|
| `Allow-DHCP-Client-Output` | Router UDP 68 → DHCP server UDP 67 |
| `Allow-DHCP-Client-Reply` | DHCP server UDP 67 → router UDP 68 |
| `Allow-NTP-Output` | Router → `129.6.15.28` or `132.163.96.1` on UDP 123 |

This means:

- The router can use the uplink only for DHCP and NTP to the selected servers.
- The uplink cannot initiate access to the router.
- Machine-LAN clients are not forwarded to the uplink.
- The uplink is not used as an Internet gateway for machine devices.
- DNS, package downloads, and other general Internet traffic are blocked by default.

## NTP Server Configuration

The router's system configuration uses:

```text
129.6.15.28
132.163.96.1
```

as time servers and enables the router's NTP server function for local clients.

The machine LAN can therefore obtain time from the router while remaining isolated from the external Wi-Fi network.

## Configure the Uplink

Run:

```sh
provision-router
```

Enter the external Wi-Fi SSID when prompted:

```text
NTP uplink WiFi SSID (radio0 station)
```

and the corresponding password when prompted.

The upstream SSID is accepted as entered and may contain spaces or punctuation.

## Verification

Check the Wi-Fi station:

```sh
wifi status
```

Check the interface:

```sh
ifstatus ntp_uplink
```

The interface should report:

```text
"up": true
```

Check routing:

```sh
ip route
```

The NIST server routes should use the `ntp_uplink` interface. There should not be a default route through `ntp_uplink`.

Inspect the generated firewall rules:

```sh
fw4 print
```

Check the configured NTP servers:

```sh
uci show system.ntp
```

Check time-synchronization logs:

```sh
logread | grep -i ntp
```

Confirm that general Internet access is unavailable:

```sh
wget https://downloads.openwrt.org/
```

The request should fail under the normal NTP-only policy.

## Temporary maintenance access

Package-list updates and downloads are intentionally unavailable under the normal policy. Temporarily relax the uplink only during supervised maintenance, then restore the NTP-only configuration.

### LuCI

1. Go to **Network → Interfaces → ntp_uplink → Edit → Advanced Settings**.
2. Enable **Use default gateway** and **Use DNS servers advertised by peer**.
3. Go to **Network → Firewall → General Settings** and edit the `ntp_uplink` zone.
4. Temporarily change **Output** from **reject** to **accept**.
5. Select **Save & Apply**, perform the package maintenance, and then restore all three settings:
   - Disable **Use default gateway**.
   - Disable **Use DNS servers advertised by peer**.
   - Change the zone's **Output** policy back to **reject**.

### Command line

Save the normal values, enable temporary access, and restart the interface and firewall:

```sh
uci set network.ntp_uplink.defaultroute='1'
uci set network.ntp_uplink.peerdns='1'
uci set firewall.@zone[1].output='ACCEPT'
uci commit network
uci commit firewall
ifup ntp_uplink
/etc/init.d/firewall restart
```

After maintenance, restore the restricted policy:

```sh
uci set network.ntp_uplink.defaultroute='0'
uci set network.ntp_uplink.peerdns='0'
uci set firewall.@zone[1].output='REJECT'
uci commit network
uci commit firewall
ifup ntp_uplink
/etc/init.d/firewall restart
```

> [!IMPORTANT]
> `firewall.@zone[1]` matches the factory configuration in this repository, but anonymous UCI indexes can change. Before using these commands on a modified router, confirm the section with `uci show firewall | grep "\.name='ntp_uplink'"`. In LuCI, selecting the named `ntp_uplink` zone avoids this ambiguity.

## Troubleshooting

### `ntp_uplink` Is Down

Verify the configured SSID and password:

```sh
uci show wireless
```

Then reload Wi-Fi:

```sh
wifi reload
```

### NTP Uplink Has an Address but Time Does Not Synchronize

Check:

```sh
ip route
```

Confirm routes to both configured NTP server IPs exist through `ntp_uplink`.

Confirm the DHCP and NTP allow rules are present, then inspect firewall and NTP logs.

### General Internet Access Works

That is not the intended normal policy. Confirm:

- `network.ntp_uplink.defaultroute` is `0`.
- `network.ntp_uplink.peerdns` is `0`.
- The `ntp_uplink` zone output policy is `REJECT`.
- No additional routes or firewall rules allow external traffic.

### Machine Clients Can Reach the Internet

That is not the intended design.

Verify there are no forwarding rules between `lan` and `ntp_uplink`, and confirm the `ntp_uplink` zone has forwarding set to `REJECT`.

## Related Documentation

- [Router Provisioning](../getting-started/provisioning.md)
- [Custom OpenWrt Image](README.md)
