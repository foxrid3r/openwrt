# OpenWrt DHCP Mode Control Script (nftables / firewall4)

This document describes how to add and use a **DHCP control mode** on OpenWrt
using `nftables` and `firewall4`, including an optional shortcut command
for quick mode switching.

The script dynamically writes rules into:

```
/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

and reloads the firewall to apply the change.

---

## Purpose

The script supports three operating modes:

| Mode        | Behavior |
|-------------|----------|
| `ON`        | No DHCP filtering (wired ports behave normally) |
| `OFF`       | DHCP completely blocked on wired ports |
| `COGNEX_ON` | Only Cognex devices are allowed to use DHCP on wired ports |

This is useful in industrial or machine-vision networks where DHCP must be
tightly controlled on wired interfaces.

---

## Assumptions

- OpenWrt using `firewall4` (nftables)
- Wired ports are named: `lan1`, `lan2`, `lan3`, `lan4`
- Cognex OUI: `00:d0:24`
- Script executed as `root`

---

## Install the Script

Create the script file:

```sh
nano /usr/bin/dhcp-mode
```

Paste the following contents exactly:

```sh
#!/bin/sh
set -eu

TARGET="/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft"

usage() {
    echo "Usage: $0 {OFF|ON|COGNEX_ON}" >&2
    exit 2
}

MODE="${1:-}"
[ -n "$MODE" ] || usage

# Must be root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must run as root" >&2
    exit 1
fi

# Ensure directory exists
DIR="$(dirname "$TARGET")"
[ -d "$DIR" ] || { echo "ERROR: missing directory: $DIR" >&2; exit 1; }

# Write to a temp file then atomically move into place
TMP="$(mktemp "${DIR}/.1-dhcp-drop-wired.nft.XXXXXX")"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

case "$MODE" in
    ON)
        # NOTE: This empties the file, effectively disabling the wired-DHCP drop rules.
        : > "$TMP"
        ;;
    OFF)
        cat > "$TMP" <<'EOF'
table bridge filter
flush table bridge filter

table bridge filter {
    chain input {
        type filter hook input priority -200; policy accept;

        # Drop all DHCP client->server on wired ports
        iifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp dport 67 counter drop
    }

    chain output {
        type filter hook output priority 100; policy accept;

        # Drop all DHCP server->client on wired ports
        oifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp sport 67 counter drop
    }
}
EOF
        ;;
    COGNEX_ON)
        cat > "$TMP" <<'EOF'
table bridge filter
flush table bridge filter

table bridge filter {
    chain input {
        type filter hook input priority -200; policy accept;

        # Allow DHCP DISCOVER/REQUEST from Cognex devices on wired ports
        iifname { "lan1", "lan2", "lan3", "lan4" } \
        ether saddr & ff:ff:ff:00:00:00 == 00:d0:24:00:00:00 \
        ip protocol udp udp dport 67 counter accept

        # Drop all other DHCP client->server on wired ports
        iifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp dport 67 counter drop
    }

    chain output {
        type filter hook output priority 100; policy accept;

        # Allow DHCP OFFER/ACK to Cognex devices on wired ports
        oifname { "lan1", "lan2", "lan3", "lan4" } \
        ether daddr & ff:ff:ff:00:00:00 == 00:d0:24:00:00:00 \
        ip protocol udp udp sport 67 counter accept

        # Drop all other DHCP server->client on wired ports
        oifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp sport 67 counter drop
    }
}
EOF
        ;;
    *)
        usage
        ;;
esac

# Preserve file mode/owner if the target exists (best effort on BusyBox)
if [ -e "$TARGET" ]; then
    # If BusyBox lacks --reference, just force a sane default
    chmod 0644 "$TMP" 2>/dev/null || true
    chown root:root "$TMP" 2>/dev/null || true
else
    chmod 0644 "$TMP" 2>/dev/null || true
    chown root:root "$TMP" 2>/dev/null || true
fi

# Atomic replace
mv -f "$TMP" "$TARGET"
trap - EXIT

# Reload firewall (preferred over restart)
if /etc/init.d/firewall reload; then
    echo "OK: wrote $TARGET for mode '$MODE' and reloaded firewall."
else
    echo "WARN: wrote $TARGET for mode '$MODE' but firewall reload failed." >&2
    exit 3
fi
```

Make it executable:

```sh
chmod +x /usr/bin/dhcp-mode
```

---

## Usage

```sh
dhcp-mode ON
dhcp-mode OFF
dhcp-mode COGNEX_ON
```

---

## Adding a Shortcut Command (Recommended)

To make the script easier to run, create a shell alias so you don’t have to
type the full path or script name.

Create symlink

```sh
ln -s /usr/bin/dhcp-mode /usr/bin/dhcpwired
```

The shortcut will now be available:
- After logout/login
- After reboot
- In all interactive shells

---

## Usage

```sh
dhcpwired ON
dhcpwired OFF
dhcpwired COGNEX_ON
```

---

## Verification

After switching modes:

```sh
nft list table bridge filter
```

Confirm that DHCP traffic on `lan1`–`lan4` matches the selected mode.