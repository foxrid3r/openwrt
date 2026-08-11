# Router Provisioning

The custom OpenWrt image includes the `provision-router` utility for configuring a router after the image has been installed.

The utility provides an interactive interface for configuring the settings that normally need to be unique for each router, including:

* Hostname
* Root password
* LAN IP address and subnet mask
* DHCP address range
* Machine-network Wi-Fi SSID and password
* Internet/NTP uplink Wi-Fi SSID and password

Settings can be changed individually. Pressing **Enter** at a prompt leaves the existing value unchanged.

---

# Running the Provisioning Utility

Connect to the router through SSH and run:

```sh
provision-router
```

The script displays the current configuration and prompts for any values that should be changed.

The utility is located at:

```text
/usr/sbin/provision-router
```

---

# Default Configuration

A newly installed custom image contains a predefined configuration so the router is usable before provisioning.

| Setting                | Default         |
| ---------------------- | --------------- |
| Hostname               | `Spare1`        |
| LAN IP                 | `192.168.1.123` |
| Machine Wi-Fi SSID     | `Spare1`        |
| Root Password          | `Admin12345!`   |
| Machine Wi-Fi Password | `Admin12345!`   |
| DHCP Start             | `192.168.1.124` |
| DHCP End               | `192.168.1.128` |
| Wired DHCP Mode        | `COGNEX_ON`     |

> [!IMPORTANT]
> The default credentials are included in the custom image and are therefore not unique to an individual router. Change the passwords during provisioning when the router requires unique credentials.

---

# Provisioning Process

The utility walks through each configurable setting.

For most prompts, the current value is displayed.

For example:

```text
Current hostname: Spare1
New hostname (Enter to keep current):
```

Pressing **Enter** without entering a new value preserves the existing setting.

This allows the provisioning utility to be used to change only one or two settings without reconfiguring the entire router.

---

# Hostname

The hostname identifies the router on the network.

The default hostname is:

```text
Spare1
```

A new hostname can be entered during provisioning.

For example:

```text
Spare2
```

The hostname accepts:

```text
A-Z
a-z
0-9
_
-
```

Periods (`.`) are not permitted.

The hostname is also commonly used as the machine-network Wi-Fi SSID, although the two values can be configured independently.

---

# Root Password

The provisioning utility can change the OpenWrt `root` password.

This password is used for administrative access, including SSH and the LuCI web interface.

Press **Enter** without entering a new password to retain the existing root password.

> [!IMPORTANT]
> Changing the root password does not automatically change the machine-network Wi-Fi password. These are separate settings.

---

# LAN Network Configuration

The provisioning utility can configure the router's LAN IP address and subnet mask.

The default LAN IP is:

```text
192.168.1.123
```

The LAN address is the address used to access the router from the machine network.

For example:

```text
http://192.168.1.123/
```

can be used to access LuCI when connected to the LAN network.

The same address can be used for SSH:

```sh
ssh root@192.168.1.123
```

---

## Changing the LAN Address

A router can be assigned a different address during provisioning.

For example:

```text
192.168.1.124
```

The provisioning utility also prompts for the LAN subnet mask.

The LAN IP address and subnet mask determine which addresses belong to the local machine network.

---

# DHCP Configuration

The provisioning utility can configure a standard consecutive DHCP address pool.

The default pool is:

```text
192.168.1.124 - 192.168.1.128
```

The utility prompts for the complete starting and ending IPv4 addresses rather than the OpenWrt `start` and `limit` values.

For example:

```text
DHCP Start: 192.168.1.124
DHCP End:   192.168.1.128
```

The provisioning utility automatically converts these addresses into the configuration format required by OpenWrt.

---

## DHCP Range Validation

When changing the DHCP range, both a starting and ending address must be supplied.

The utility verifies that:

* Both addresses are valid IPv4 addresses.
* The starting address is not greater than the ending address.
* Both addresses belong to the configured LAN subnet.

If both DHCP prompts are left blank, the existing DHCP configuration is preserved.

---

# Fragmented DHCP Ranges

`provision-router` manages a **standard consecutive DHCP pool**.

If the router uses fragmented DHCP ranges configured by `set-dhcp-range`, the provisioning utility detects this configuration and warns that provisioning a new DHCP range will replace it.

For example, a fragmented configuration might provide:

```text
192.168.1.50 - 192.168.1.60

and

192.168.1.178 - 192.168.1.179
```

If a new DHCP range is entered through `provision-router`, the fragmented configuration is removed and replaced with the newly specified consecutive range.

If the existing fragmented DHCP configuration should remain unchanged, leave the DHCP start and end prompts blank.

For more information, see [DHCP Range Configuration](../networking/set-dhcp-range.md).

---

# Machine-Network Wi-Fi

The router provides a Wi-Fi access point for connecting to the isolated machine network.

This access point uses `radio1`.

The provisioning utility allows the following settings to be changed:

* SSID
* Wi-Fi password

The default SSID is:

```text
Spare1
```

The SSID accepts:

```text
A-Z
a-z
0-9
_
-
```

Periods (`.`) are not permitted.

---

## Machine Wi-Fi Password

The machine-network Wi-Fi password can be changed during provisioning.

If the password is changed, the access point is configured to use WPA2-PSK encryption.

Press **Enter** without entering a new password to retain the existing Wi-Fi password.

> [!NOTE]
> Changing the machine-network Wi-Fi settings may temporarily disconnect wireless clients while the wireless interface reloads.

---

# Internet/NTP Uplink Wi-Fi

The router also contains a separate Wi-Fi client connection used to provide limited upstream connectivity.

This connection uses `radio0`.

Its primary purpose is to allow services such as NTP to reach an external network without providing general Internet access to devices on the machine LAN.

The provisioning utility allows the uplink:

* SSID
* Wi-Fi password

to be changed.

Unlike the machine-network SSID, the uplink SSID is accepted as entered so it can match the name of an existing external wireless network.

Changing the uplink credentials preserves the existing wireless encryption configuration.

---

# Applying Changes

The provisioning utility determines which portions of the router configuration were changed and applies the necessary updates.

Depending on the settings changed, this can include:

* Committing UCI configuration changes
* Reloading the network configuration
* Reloading Wi-Fi
* Restarting or reloading DHCP/DNS services
* Updating the root password

Only the services affected by the configuration changes are reloaded.

---

# After Changing the LAN IP

Changing the LAN IP address changes the address used to communicate with the router.

For example, if the router changes from:

```text
192.168.1.123
```

to:

```text
192.168.1.124
```

the existing SSH or LuCI connection may be interrupted.

Reconnect using the new address:

```sh
ssh root@192.168.1.124
```

or open:

```text
http://192.168.1.124/
```

in a web browser.

The computer connected to the router may also need to renew its network configuration if it obtains its address through DHCP.

---

# Re-running Provisioning

`provision-router` is not limited to the initial installation.

It can be run again at any time:

```sh
provision-router
```

Existing values are displayed and can be retained by pressing **Enter**.

This makes the utility useful when:

* Assigning a router to a different machine
* Changing the router hostname
* Changing the LAN network
* Changing the DHCP pool
* Changing Wi-Fi credentials
* Changing the Internet/NTP uplink network
* Changing administrative credentials

---

# Related Tools

Provisioning establishes the router's primary configuration. Additional tools are available for more specialized network configuration.

## DHCP Range Configuration

For consecutive or fragmented DHCP range configuration:

```sh
set-dhcp-range
```

See [DHCP Range Configuration](../networking/set-dhcp-range.md).

## Wired DHCP Mode

To control DHCP availability on the wired Ethernet ports:

```sh
dhcp-mode ON
dhcp-mode OFF
dhcp-mode COGNEX_ON
```

See [DHCP Modes](../networking/dhcp-modes.md).

## Tool Reference

For a summary of the command-line utilities included with the custom image, see [Tool Reference](../tool-reference/tool-reference.md).

---

# Provisioning Summary

For a newly installed router:

1. Flash and boot the custom OpenWrt image.

2. Connect to the router.

3. Log in through SSH.

4. Run:

   ```sh
   provision-router
   ```

5. Change the settings required for that router.

6. Press **Enter** for settings that should remain unchanged.

7. Allow the utility to apply the configuration.

8. If the LAN IP was changed, reconnect using the new address.

9. Verify LAN, DHCP, Wi-Fi, and uplink operation.

The router can be provisioned again at any time without requiring the custom image to be rebuilt or reflashed.
