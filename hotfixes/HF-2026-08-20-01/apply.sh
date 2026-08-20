#!/bin/sh

set -eu

HOTFIX_ID="HF-2026-08-20-01"
HOTFIX_DESCRIPTION="Restore NTP uplink routing"
SUPPORTED_IMAGE_VERSION="1.6.6"
SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
STATE_ROOT="/etc/custom-hotfixes"
STATE_FILE="$STATE_ROOT/$HOTFIX_ID"
BACKUP_DIR="$STATE_ROOT/backups/$HOTFIX_ID"
NETWORK_BACKUP="$BACKUP_DIR/network.uci"
HOTFIX_METADATA="/etc/custom-hotfixes.json"
LUCI_VIEW="/www/luci-static/resources/view/status/include/10_system.js"
RPCD_ACL="/usr/share/rpcd/acl.d/custom-image.json"
NTP_INTERFACE="ntp_uplink"
NTP_TARGETS="129.6.15.28/32 132.163.96.1/32"

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

command -v uci >/dev/null 2>&1 || fail "uci is not installed"
command -v ifup >/dev/null 2>&1 || fail "ifup is not installed"
command -v jsonfilter >/dev/null 2>&1 || fail "jsonfilter is not installed"
command -v install >/dev/null 2>&1 || fail "install is not installed"

[ -r /etc/custom-image.json ] || fail "/etc/custom-image.json is not readable"
installed_image_version="$(
	jsonfilter -i /etc/custom-image.json -e '@.version' 2>/dev/null || true
)"
[ "$installed_image_version" = "$SUPPORTED_IMAGE_VERSION" ] || \
	fail "$HOTFIX_ID requires custom image $SUPPORTED_IMAGE_VERSION; installed version is ${installed_image_version:-unknown}"

[ "$(uci -q get network.$NTP_INTERFACE)" = "interface" ] || \
	fail "network.$NTP_INTERFACE does not exist"
[ "$(uci -q get network.$NTP_INTERFACE.proto)" = "dhcp" ] || \
	fail "network.$NTP_INTERFACE is not a DHCP interface"

if [ -f "$STATE_FILE" ]; then
	printf '%s is already recorded as applied.\n' "$HOTFIX_ID"
	exit 0
fi

mkdir -p "$BACKUP_DIR"
[ -f "$NETWORK_BACKUP" ] || uci export network >"$NETWORK_BACKUP"

backup_file() {
	path="$1"
	destination="$BACKUP_DIR$path"
	mkdir -p "$(dirname "$destination")"
	if [ -e "$destination" ] || [ -e "$destination.absent" ]; then
		return
	fi
	if [ -e "$path" ]; then
		cp -p "$path" "$destination"
	else
		: >"$destination.absent"
	fi
}

backup_file /etc/banner
backup_file "$HOTFIX_METADATA"
backup_file "$LUCI_VIEW"
backup_file "$RPCD_ACL"

route_sections() {
	uci -q show network | sed -n 's/^network\.\([^.=]*\)=route$/\1/p'
}

remove_matching_route() {
	target="$1"

	# Refresh the section list after each deletion because anonymous UCI indexes
	# are renumbered when an earlier section is removed.
	while :; do
		matched=""
		for section in $(route_sections); do
			interface="$(uci -q get "network.$section.interface" || true)"
			route_target="$(uci -q get "network.$section.target" || true)"
			if [ "$interface" = "$NTP_INTERFACE" ] && [ "$route_target" = "$target" ]; then
				matched="$section"
				break
			fi
		done

		[ -n "$matched" ] || break
		printf 'Removing network.%s (%s via %s)\n' \
			"$matched" "$target" "$NTP_INTERFACE"
		uci delete "network.$matched"
	done
}

for target in $NTP_TARGETS; do
	remove_matching_route "$target"
done

uci set "network.$NTP_INTERFACE.defaultroute=1"
uci commit network

ifdown "$NTP_INTERFACE" >/dev/null 2>&1 || true
if ! ifup "$NTP_INTERFACE"; then
	printf 'ERROR: configuration was committed, but %s did not start.\n' \
		"$NTP_INTERFACE" >&2
	printf 'The pre-hotfix network configuration is saved at %s.\n' \
		"$NETWORK_BACKUP" >&2
	exit 1
fi

[ "$(uci -q get network.$NTP_INTERFACE.defaultroute)" = "1" ] || \
	fail "the default-route setting could not be verified"

applied_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
metadata_tmp="$HOTFIX_METADATA.tmp.$$"
{
	printf '{\n'
	printf '    "hotfixes": [\n'
	printf '        {\n'
	printf '            "id": "%s",\n' "$HOTFIX_ID"
	printf '            "description": "%s",\n' "$HOTFIX_DESCRIPTION"
	printf '            "applied_at": "%s",\n' "$applied_at"
	printf '            "base_version": "%s"\n' "$installed_image_version"
	printf '        }\n'
	printf '    ]\n'
	printf '}\n'
} >"$metadata_tmp"
mv "$metadata_tmp" "$HOTFIX_METADATA"
chmod 0644 "$HOTFIX_METADATA"

if ! grep -Fq "$HOTFIX_ID" /etc/banner; then
	{
		printf '\n'
		printf '*** Applied Hotfix: %s — %s ***\n' \
			"$HOTFIX_ID" "$HOTFIX_DESCRIPTION"
	} >>/etc/banner
fi

install -m 0644 \
	"$SCRIPT_DIR/payload/www/luci-static/resources/view/status/include/10_system.js" \
	"$LUCI_VIEW"
install -m 0644 \
	"$SCRIPT_DIR/payload/usr/share/rpcd/acl.d/custom-image.json" \
	"$RPCD_ACL"

/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

mkdir -p "$STATE_ROOT"
{
	printf 'id=%s\n' "$HOTFIX_ID"
	printf 'description=%s\n' "$HOTFIX_DESCRIPTION"
	printf 'applied_at=%s\n' "$applied_at"
	printf 'base_image_version=%s\n' "$installed_image_version"
	printf 'source_fix=e20632715cd41175faca15d42e7233b9240ff9bb\n'
} >"$STATE_FILE"

printf '%s applied successfully.\n' "$HOTFIX_ID"
printf 'The SSH banner and LuCI Applied Hotfixes field now identify this fix.\n'
printf 'Hard-refresh LuCI if the new field is not immediately visible.\n'
printf 'Verify the route with: ip route get 129.6.15.28\n'
printf 'Check synchronization with: logread | grep -i ntp\n'
