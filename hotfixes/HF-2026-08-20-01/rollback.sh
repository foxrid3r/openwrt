#!/bin/sh

set -eu

HOTFIX_ID="HF-2026-08-20-01"
STATE_ROOT="/etc/custom-hotfixes"
STATE_FILE="$STATE_ROOT/$HOTFIX_ID"
BACKUP_DIR="$STATE_ROOT/backups/$HOTFIX_ID"
NETWORK_BACKUP="$BACKUP_DIR/network.uci"
NTP_INTERFACE="ntp_uplink"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

[ -f "$NETWORK_BACKUP" ] || fail "network backup is missing"

restore_file() {
	path="$1"
	source="$BACKUP_DIR$path"
	if [ -f "$source.absent" ]; then
		rm -f "$path"
	elif [ -f "$source" ]; then
		cp -p "$source" "$path"
	else
		fail "backup is missing for $path"
	fi
}

uci import network <"$NETWORK_BACKUP"
uci commit network

restore_file /etc/banner
restore_file /etc/custom-hotfixes.json
restore_file /www/luci-static/resources/view/status/include/10_system.js
restore_file /usr/share/rpcd/acl.d/custom-image.json

rm -f "$STATE_FILE"

ifdown "$NTP_INTERFACE" >/dev/null 2>&1 || true
ifup "$NTP_INTERFACE"
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

printf '%s rolled back successfully.\n' "$HOTFIX_ID"
