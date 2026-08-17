
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
    ├── metric 50
    └── host routes to NIST NTP servers
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
        option metric '50'
```

`peerdns '0'` prevents the upstream network from supplying DNS servers to the router.

## NTP Host Routes

The factory network configuration includes explicit routes to:

```text
129.6.15.28
132.163.96.1
```

through `ntp_uplink`.

These are also the NTP servers configured in `/etc/config/system`.

Using literal IP addresses avoids needing DNS resolution for the NTP service.

## Firewall Isolation

The `ntp_uplink` firewall zone uses:

```text
Input:   REJECT
Output:  ACCEPT
Forward: REJECT
```

The zone is attached only to:

```text
ntp_uplink
```

There are no forwarding rules between the machine LAN and the NTP uplink.

This means:

- The router itself can send permitted outbound traffic through the uplink.
- The uplink cannot initiate access to the router.
- Machine-LAN clients are not forwarded to the uplink.
- The uplink is not used as an Internet gateway for machine devices.

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

The NIST server routes should use the `ntp_uplink` interface.

Check the configured NTP servers:

```sh
uci show system.ntp
```

Check time-synchronization logs:

```sh
logread | grep -i ntp
```

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

Also inspect firewall and NTP logs.

### Machine Clients Can Reach the Internet

That is not the intended design.

Verify there are no forwarding rules between `lan` and `ntp_uplink`, and confirm the `ntp_uplink` zone has forwarding set to `REJECT`.

## Related Documentation

- [Router Provisioning](../getting-started/provisioning.md)
- [Custom OpenWrt Image](README.md)
