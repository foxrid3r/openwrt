# DHCP Pool Configuration Utility

## Overview

The custom image provides the `set-dhcp-range` tool which is an interactive shell utility used to configure DHCP
address pools on OpenWrt routers.

The script supports two operating modes:

1.  **Standard Consecutive DHCP Pool**
    -   Uses OpenWrt's native UCI DHCP configuration.
    -   Fully compatible with LuCI.
    -   Recommended for most installations.
2.  **Fragmented DHCP Pools**
    -   Uses native `dnsmasq` `dhcp-range=` directives.
    -   Supports multiple non-contiguous DHCP address ranges.
    -   Intended for industrial and automation networks where static
        devices occupy portions of the subnet.

The script automatically selects the appropriate configuration method
based on the number of DHCP ranges entered.

------------------------------------------------------------------------

# Why This Script Exists

Many industrial networks contain PLCs, robots, vision systems, cameras,
HMIs and other devices that require fixed IP addresses. Rather than
forcing all DHCP clients into one continuous address block, this utility
allows DHCP to be assigned from multiple independent ranges while still
supporting the standard OpenWrt configuration when only a single range
is needed.

------------------------------------------------------------------------

# Operating Modes

## Standard Consecutive Pool

If exactly one DHCP range is entered, the script configures OpenWrt
using the normal UCI settings:

``` text
option start
option limit
option leasetime
```

Example:

``` text
192.168.1.191-192.168.1.200
```

The script removes any previously generated fragmented configuration,
commits the UCI changes and restarts `dnsmasq`.

This mode remains fully compatible with LuCI.

------------------------------------------------------------------------

## Fragmented DHCP Pools

If multiple ranges are entered, the script generates native `dnsmasq`
configuration instead of trying to represent the configuration using
UCI's `start` and `limit` options.

Example input:

``` text
192.168.1.21-192.168.1.30
192.168.1.50-192.168.1.60
192.168.1.90-192.168.1.99
```

Produces:

``` text
dhcp-range=192.168.1.21,192.168.1.30,12h
dhcp-range=192.168.1.50,192.168.1.60,12h
dhcp-range=192.168.1.90,192.168.1.99,12h
```

Each entered range is written exactly as supplied.

------------------------------------------------------------------------

# Major Change in Version 5

Earlier versions reserved a single UCI-managed DHCP address so that LuCI
would continue displaying a DHCP pool. This complicated the
implementation by requiring one address to be removed from the generated
fragmented ranges.

Version 5 removes that behavior entirely.

Instead, fragmented mode:

-   disables only the built-in UCI DHCP server using:

``` text
dhcp.lan.dhcpv4='disabled'
```

-   leaves the remainder of the DHCP configuration active
-   allows `dnsmasq` to manage all DHCP leases using generated
    `dhcp-range=` entries

This significantly simplifies the configuration while preserving the
rest of OpenWrt's DHCP functionality.

------------------------------------------------------------------------

# Hostname Preservation

A major benefit of the Version 5 implementation is that router and
client hostname handling continues to function correctly.

Previous implementations disabled the entire LAN DHCP section,
preventing dnsmasq from processing other useful information stored in
`/etc/config/dhcp`.

By disabling only the UCI DHCP server (`dhcpv4='disabled'`), dnsmasq
continues to process the remainder of the configuration, including
hostname and static-host information, while DHCP address assignment is
handled entirely by the generated `dhcp-range=` entries.

------------------------------------------------------------------------


# Example Usage

## Example 1 — Configure a Consecutive DHCP Pool

Run the script:

```text
set-dhcp-range
```

The script first displays the current DHCP configuration, then prompts for DHCP ranges.

Example interaction:

```text
Current DHCP configuration:
  Standard UCI DHCP pool: enabled
  Range: 192.168.1.100 - 192.168.1.150
  Lease time: 12h

Enter DHCP ranges using full IP addresses.
Example: 192.168.1.100-192.168.1.150
Press Enter on a blank line when finished.

Range 1: 192.168.1.191-192.168.1.200
Range 2:
```

Because only one range was entered, the script selects standard consecutive mode.

The resulting UCI configuration is equivalent to:

```text
config dhcp 'lan'
        option start '191'
        option limit '10'
        option leasetime '12h'
```

The script also:

- removes `/etc/dnsmasq.d/custom-ranges.conf` if it exists
- re-enables UCI-managed IPv4 DHCP if fragmented mode was previously active
- commits the DHCP configuration
- restarts `dnsmasq`

The active DHCP pool is:

```text
192.168.1.191 - 192.168.1.200
```

---

## Example 2 — Configure Fragmented DHCP Pools

Run the script:

```text
set-dhcp-range
```

Example interaction:

```text
Current DHCP configuration:
  Standard UCI DHCP pool: enabled
  Range: 192.168.1.191 - 192.168.1.200
  Lease time: 12h

Enter DHCP ranges using full IP addresses.
Example: 192.168.1.100-192.168.1.150
Press Enter on a blank line when finished.

Range 1: 192.168.1.21-192.168.1.30
Range 2: 192.168.1.50-192.168.1.60
Range 3: 192.168.1.90-192.168.1.99
Range 4:
```

Because more than one range was entered, the script selects fragmented mode.

The script sets:

```text
dhcp.lan.dhcpv4='disabled'
```

and creates:

```text
/etc/dnsmasq.d/custom-ranges.conf
```

with the following contents:

```text
# Auto-generated by set-dhcp-range
# Do not manually edit unless you understand dnsmasq dhcp-range syntax.
dhcp-range=192.168.1.21,192.168.1.30,12h
dhcp-range=192.168.1.50,192.168.1.60,12h
dhcp-range=192.168.1.90,192.168.1.99,12h
```

The script also ensures that `dnsmasq` loads custom configuration files from:

```text
/etc/dnsmasq.d
```

using:

```text
dhcp.@dnsmasq[0].confdir='/etc/dnsmasq.d'
```

It then commits the DHCP configuration and restarts `dnsmasq`.

The active DHCP addresses are therefore:

```text
192.168.1.21 - 192.168.1.30
192.168.1.50 - 192.168.1.60
192.168.1.90 - 192.168.1.99
```

Addresses between these ranges are not offered by DHCP and remain available for static devices.

---

## Switching Back from Fragmented to Consecutive Mode

To return to a normal consecutive pool, run the script again and enter only one range:

```text
Range 1: 192.168.1.100-192.168.1.150
Range 2:
```

The script will:

- re-enable UCI-managed IPv4 DHCP
- configure the new `start` and `limit` values
- remove `/etc/dnsmasq.d/custom-ranges.conf`
- restart `dnsmasq`

No manual cleanup is required.

---

# Configuration Files

## Standard Mode

``` text
/etc/config/dhcp
```

Used for:

-   option start
-   option limit
-   option leasetime

------------------------------------------------------------------------

## Fragmented Mode

Generated file:

``` text
/etc/dnsmasq.d/custom-ranges.conf
```

The script also ensures dnsmasq loads this directory using:

``` text
dhcp.@dnsmasq[0].confdir=/etc/dnsmasq.d
```

------------------------------------------------------------------------

# Internal Operation

## Consecutive Mode

1.  Read the LAN subnet.
2.  Calculate the DHCP start offset.
3.  Calculate the pool size.
4.  Update `/etc/config/dhcp`.
5.  Remove any generated fragmented configuration.
6.  Restart `dnsmasq`.

## Fragmented Mode

1.  Create `/etc/dnsmasq.d` if required.
2.  Enable the dnsmasq configuration directory.
3.  Set:

``` text
dhcp.lan.dhcpv4='disabled'
```

4.  Generate one `dhcp-range=` entry for every user-specified range.
5.  Write `/etc/dnsmasq.d/custom-ranges.conf`.
6.  Restart `dnsmasq`.

------------------------------------------------------------------------

# Viewing the Current Configuration

Before making changes the script displays the active configuration.

In fragmented mode it detects that the UCI DHCP server is disabled and
displays the contents of:

``` text
/etc/dnsmasq.d/custom-ranges.conf
```

rather than attempting to reconstruct a UCI-managed DHCP pool.

------------------------------------------------------------------------

# LuCI Behavior

## Consecutive Mode

LuCI accurately displays and edits the DHCP pool.

## Fragmented Mode

LuCI does not understand fragmented DHCP ranges and therefore does not
display the generated `dhcp-range=` entries.

This is expected. DHCP continues to operate correctly because `dnsmasq`
reads the generated configuration directly.

------------------------------------------------------------------------

# Troubleshooting

Validate the dnsmasq configuration:

``` text
dnsmasq --test
```

View active leases:

``` text
cat /tmp/dhcp.leases
```

Watch DHCP activity:

``` text
logread -f | grep dnsmasq
```

Verify the configuration directory is loaded:

``` text
grep conf-dir /var/etc/dnsmasq.conf*
```

Expected output:

``` text
conf-dir=/etc/dnsmasq.d
```

------------------------------------------------------------------------

# Summary

Version 5 simplifies fragmented DHCP configuration by eliminating the
reserved UCI lease mechanism and allowing dnsmasq to manage every
fragmented range directly. Standard UCI configuration is retained for
consecutive pools, while fragmented deployments benefit from simpler
configuration, preserved hostname functionality, and a cleaner
implementation.
