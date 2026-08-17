# LuCI Custom DHCP Mode Control
This document explains how to build a fully functional LuCI page that
controls custom DHCP filtering modes on OpenWrt.

The page allows you to:

-   Toggle DHCP filtering modes: `ON`, `OFF`, `COGNEX_ON`
-   Display the current active mode
-   Use proper OpenWrt architecture (LuCI → rpcd → ubus → shell →
    nftables)

This guide explains **what each component does**, **why it exists**, and
**how they connect together**.

------------------------------------------------------------------------

# Architecture Overview

    LuCI (custom_tools.js)
            ↓
    rpcd (ACL enforced)
            ↓
    ucode plugin (custom_tools.uc)
            ↓
    ubus object: custom_tools
            ↓
    /usr/bin/dhcp-mode
            ↓
    /usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft

## Why This Architecture?

OpenWrt separates:

-   **UI layer (LuCI)**
-   **RPC layer (rpcd + ubus)**
-   **System logic (shell scripts)**
-   **Firewall logic (nftables)**

This ensures:

-   Security (ACL-controlled RPC access)
-   Clean separation of concerns
-   Upgrade-safe design
-   Maintainability

------------------------------------------------------------------------

# 1️⃣ Required Packages

> [!NOTE]
> The custom image's NTP-only uplink blocks general Internet access by default. Before running `opkg`, follow [Temporary maintenance access](../custom-image/ntp-uplink.md#temporary-maintenance-access), and restore the restricted settings when finished.

``` sh
opkg update
opkg install rpcd-mod-ucode ucode ucode-mod-fs
/etc/init.d/rpcd restart
```

## What This Does

-   `rpcd-mod-ucode` allows rpcd to load `.uc` plugins.
-   `ucode` provides the runtime for writing ubus handlers.
-   `ucode-mod-fs` allows reading files from inside ucode.
-   Restarting rpcd reloads plugin support.

## Why It's Required

Without `rpcd-mod-ucode`, your custom ubus object cannot exist. LuCI
communicates through ubus --- so this layer is mandatory.

------------------------------------------------------------------------

# 2️⃣ Install the dhcp-mode Script

Create:

    /usr/bin/dhcp-mode

Make executable:

``` sh
chmod +x /usr/bin/dhcp-mode
```

## What This Script Does

-   Writes nftables rules to enable or disable DHCP filtering
-   Supports 3 modes:
    -   `ON` → No DHCP filtering
    -   `OFF` → Block DHCP on wired ports
    -   `COGNEX_ON` → Allow DHCP only for Cognex OUI
-   Supports `STATUS` so other components can query the current state

## Why STATUS Is Important

LuCI must display the current mode. Rather than guessing state, we use a
**single source of truth**: the script itself.

------------------------------------------------------------------------

## Full Working Script

``` sh
#!/bin/sh
set -eu

TARGET="/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft"

usage() {
    echo "Usage: $0 {OFF|ON|COGNEX_ON|STATUS}" >&2
    exit 2
}

MODE="${1:-}"
[ -n "$MODE" ] || usage

# STATUS does not require root
if [ "$MODE" = "STATUS" ] || [ "$MODE" = "--status" ] || [ "$MODE" = "-s" ]; then
    if [ ! -s "$TARGET" ]; then
        echo "ON"
        exit 0
    fi

    if grep -qi '00:d0:24' "$TARGET"; then
        echo "COGNEX_ON"
        exit 0
    fi

    if grep -qiE 'udp (dport|sport) 67' "$TARGET"; then
        echo "OFF"
        exit 0
    fi

    echo "UNKNOWN"
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must run as root" >&2
    exit 1
fi

DIR="$(dirname "$TARGET")"
[ -d "$DIR" ] || { echo "ERROR: missing directory: $DIR" >&2; exit 1; }

TMP="$(mktemp "${DIR}/.1-dhcp-drop-wired.nft.XXXXXX")"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

case "$MODE" in
    ON)
        : > "$TMP"
        ;;
    OFF)
        cat > "$TMP" <<'EOF2'
table bridge filter
flush table bridge filter

table bridge filter {
    chain input {
        type filter hook input priority -200; policy accept;
        iifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp dport 67 counter drop
    }

    chain output {
        type filter hook output priority 100; policy accept;
        oifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp sport 67 counter drop
    }
}
EOF2
        ;;
    COGNEX_ON)
        cat > "$TMP" <<'EOF2'
table bridge filter
flush table bridge filter

table bridge filter {
    chain input {
        type filter hook input priority -200; policy accept;

        iifname { "lan1", "lan2", "lan3", "lan4" } \
        ether saddr & ff:ff:ff:00:00:00 == 00:d0:24:00:00:00 \
        ip protocol udp udp dport 67 counter accept

        iifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp dport 67 counter drop
    }

    chain output {
        type filter hook output priority 100; policy accept;

        oifname { "lan1", "lan2", "lan3", "lan4" } \
        ether daddr & ff:ff:ff:00:00:00 == 00:d0:24:00:00:00 \
        ip protocol udp udp sport 67 counter accept

        oifname { "lan1", "lan2", "lan3", "lan4" } ip protocol udp udp sport 67 counter drop
    }
}
EOF2
        ;;
    *)
        usage
        ;;
esac

chmod 0644 "$TMP" 2>/dev/null || true
chown root:root "$TMP" 2>/dev/null || true
mv -f "$TMP" "$TARGET"
trap - EXIT

/etc/init.d/firewall reload
```

------------------------------------------------------------------------

# 3️⃣ Create rpcd ucode Plugin

Create:

    /usr/share/rpcd/ucode/custom_tools.uc

## What This Does

This file defines a **custom ubus object** named `custom_tools`.

It provides:

-   `get_mode` → calls `dhcp-mode STATUS`
-   `set_mode` → calls `dhcp-mode <MODE>`

rpcd exposes this to LuCI securely via ACL.

------------------------------------------------------------------------

``` js
'use strict';

import * as fs from 'fs';

const TMP = '/tmp/custom_tools_mode';

function is_valid_mode(s) {
  return s == 'ON' || s == 'OFF' || s == 'COGNEX_ON';
}

return {
  custom_tools: {
    get_mode: {
      call: function() {
        system("sh -c '/usr/bin/dhcp-mode STATUS | tr -d \"\\r\\n\" > " + TMP + " 2>/dev/null'");
        let raw = fs.readfile(TMP);
        if (raw == null) raw = '';
        let mode = is_valid_mode(raw) ? raw : 'UNKNOWN';
        return { mode: mode };
      }
    },

    set_mode: {
      args: { mode: "ON" },
      call: function(req) {
        let mode = req.args.mode;
        if (!is_valid_mode(mode))
          exit(UBUS_STATUS_INVALID_ARGUMENT);

        let rc = system('/usr/bin/dhcp-mode ' + mode);
        if (rc !== 0)
          exit(UBUS_STATUS_UNKNOWN_ERROR);

        return { ok: true, mode: mode };
      }
    }
  }
};
```

Restart rpcd:

``` sh
/etc/init.d/rpcd restart
```

------------------------------------------------------------------------

# 4️⃣ Create ACL File

Create:

    /usr/share/rpcd/acl.d/luci-app-custom-tools.json

## Why This Is Required

LuCI runs in a restricted context. ACL files explicitly grant permission
for UI pages to call ubus methods.

Without this file: - The menu will not appear - RPC calls will fail
silently

------------------------------------------------------------------------

``` json
{
  "luci-app-custom-tools": {
    "description": "Custom Tools",
    "read": {
      "luci": [ "ui" ],
      "ubus": { "custom_tools": [ "get_mode" ] }
    },
    "write": {
      "ubus": { "custom_tools": [ "set_mode" ] }
    }
  }
}
```

Restart rpcd again:

``` sh
/etc/init.d/rpcd restart
```

------------------------------------------------------------------------

# 5️⃣ Add LuCI Menu Entry

Create:

    /usr/share/luci/menu.d/custom-tools.json

## What This Does

This registers your page in the LuCI navigation tree.

The `"depends": { "acl": [...] }` ensures: - The menu only appears if
ACL permissions exist.

------------------------------------------------------------------------

``` json
{
  "admin/system/custom_tools": {
    "title": "Custom Tools",
    "order": 60,
    "depends": {
      "acl": [ "luci-app-custom-tools" ]
    },
    "action": {
      "type": "view",
      "path": "custom_tools"
    }
  }
}
```

------------------------------------------------------------------------

# 6️⃣ Create LuCI Frontend Page

Create:

    /www/luci-static/resources/view/custom_tools.js

## What This Does

-   Calls `get_mode` when page loads
-   Displays current mode
-   Sends RPC calls to `set_mode`
-   Shows modal feedback
-   Updates status dynamically

------------------------------------------------------------------------

``` js
'use strict';
'require view';
'require ui';
'require rpc';

var callGetMode = rpc.declare({
  object: 'custom_tools',
  method: 'get_mode'
});

var callSetMode = rpc.declare({
  object: 'custom_tools',
  method: 'set_mode',
  params: [ 'mode' ]
});

return view.extend({
  load: function() {
    return callGetMode();
  },

  render: function(data) {
    var modeSpan = E('span', { style: 'font-weight:bold;' },
      (data && data.mode) ? data.mode : 'UNKNOWN');

    function refreshMode() {
      return callGetMode().then(function(res) {
        modeSpan.textContent = res.mode;
      });
    }

    function doSet(mode) {
      ui.showModal('Running...', [ E('p', {}, 'Switching to ' + mode) ]);
      return callSetMode(mode).then(function() {
        return refreshMode();
      }).finally(function() {
        ui.hideModal();
      });
    }

    return E('div', { class: 'cbi-map' }, [
      E('h2', {}, 'Custom Tools'),
      E('p', {}, [ 'Current DHCP mode: ', modeSpan ]),
      E('button', { click: function() { return doSet('ON'); } }, 'ON'),
      E('button', { click: function() { return doSet('OFF'); } }, 'OFF'),
      E('button', { click: function() { return doSet('COGNEX_ON'); } }, 'COGNEX_ON')
    ]);
  }
});
```

Restart web server:

``` sh
/etc/init.d/uhttpd restart
```

Hard refresh browser (Ctrl+F5).

------------------------------------------------------------------------

# Final Verification

Backend:

``` sh
ubus call custom_tools get_mode
```

Frontend:

LuCI → System → Custom Tools

Buttons should update mode correctly.
