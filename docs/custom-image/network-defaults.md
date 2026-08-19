# Network Defaults

The factory configuration is designed for a small, isolated machine network. Provisioning can replace the identity and address values for a specific deployment.

## Default identity and LAN

| Setting | Default |
|---|---|
| Hostname | `Spare1` |
| LAN address | `192.168.1.123` |
| Machine Wi-Fi SSID | `Spare1` |
| Wired interfaces | `lan1`, `lan2`, `lan3`, `lan4` |

The initial DHCP pool is `192.168.1.124` through `192.168.1.128`. See [DHCP behavior](dhcp-behavior.md) for filtering and pool management.

## Isolation model

- Wired LAN ports and machine Wi-Fi serve the local automation network.
- A separate Wi-Fi client interface can obtain Internet time from two explicitly allowed NTP servers.
- The NTP uplink accepts a DHCP default route so it has a usable upstream gateway, does not accept peer DNS, and permits only DHCP plus UDP/123 to those servers.
- Firewall rules prevent the NTP uplink from routing traffic to or from the machine LAN.
- Wired DHCP can be enabled, disabled, or restricted to Cognex devices independently of other traffic.

See [NTP uplink](ntp-uplink.md) for the isolated time source and [DHCP mode](../tools/dhcp-mode.md) for wired-port filtering.

## Changing defaults

Run `provision-router` after flashing. The [provisioning guide](../getting-started/provisioning.md) covers hostname, LAN, DHCP, Wi-Fi, uplink, and root-password changes.
