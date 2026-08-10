# OpenWrt DHCP Lease Reclamation

## Overview

This document describes the DHCP lease reclamation mechanism used to
recover DHCP addresses when very small DHCP pools become exhausted
because dnsmasq retains leases for disconnected clients until they
expire.

## Components

### `watch-dhcp-exhaustion`

Runs continuously under procd, watches `logread -f` for dnsmasq 'no
address available' messages, applies a cooldown, then invokes
`reclaim-dhcp-lease`.

#### File contents

``` sh
#!/bin/sh

TAG="dhcp-reclaim"
COOLDOWN_FILE="/tmp/dhcp-reclaim-last-run"
COOLDOWN_SECONDS=10

logger -t "$TAG" "DHCP exhaustion watcher started"

logread -f | while IFS= read -r line; do
    case "$line" in
        *dnsmasq-dhcp*no\ address\ available*|        *dnsmasq-dhcp*no\ addresses\ available*|        *dnsmasq-dhcp*no\ address\ range\ available*)
            now="$(date +%s)"
            last_run=0
            [ -f "$COOLDOWN_FILE" ] && read -r last_run < "$COOLDOWN_FILE"
            case "$last_run" in ''|*[!0-9]*) last_run=0;; esac
            elapsed=$((now-last_run))
            [ "$elapsed" -lt "$COOLDOWN_SECONDS" ] && continue
            printf '%s\n' "$now" > "$COOLDOWN_FILE"
            logger -t "$TAG" "DHCP pool exhaustion detected"
            /usr/sbin/reclaim-dhcp-lease
            ;;
    esac
done
```

### `reclaim-dhcp-lease`

Worker script responsible for reclaiming leases. **Note:** the attached
copy is a placeholder; the production router contains the actual
implementation.

#### File contents

``` sh
#!/bin/sh
# Placeholder: copy the finalized reclaim-dhcp-lease script from the router.
# This archive preserves the expected overlay structure.
```

### `95-enable-dhcp-reclaim`

One-time UCI-default script that enables the init service during first
boot.

#### File contents

``` sh
#!/bin/sh

/etc/init.d/dhcp-reclaim enable

exit 0
```

### `dhcp-reclaim`

procd init script that starts and supervises the watcher.

#### File contents

``` sh
#!/bin/sh /etc/rc.common

START=95
STOP=10
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/sbin/watch-dhcp-exhaustion
    procd_set_param respawn 5 5 0
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
```

### `set-dhcp-range`

Configures either a contiguous UCI DHCP pool or fragmented dnsmasq
`dhcp-range` entries. The lease reclamation mechanism must remain
compatible with both.

#### File contents

``` sh
#!/bin/sh
# set-dhcp-range
# Sets OpenWrt DHCP pool as either:
#   1) normal UCI consecutive pool, or
#   2) fragmented dnsmasq dhcp-range entries

set -eu

CUSTOM_DIR="/etc/dnsmasq.d"
CUSTOM_FILE="$CUSTOM_DIR/custom-ranges.conf"

die() { echo "ERROR: $*" >&2; exit 1; }

is_ipv4() {
  echo "$1" | awk -F. '
    NF!=4 {exit 1}
    {
      for(i=1;i<=4;i++){
        if($i !~ /^[0-9]+$/) exit 1
        if($i<0 || $i>255) exit 1
      }
    }
    END{exit 0}'
}

ip_to_int() {
  echo "$1" | awk -F. '{print ($1*256*256*256)+($2*256*256)+($3*256)+$4}'
}

int_to_ip() {
  awk -v n="$1" 'BEGIN{
    o1=int(n/(256*256*256)); n-=o1*256*256*256;
    o2=int(n/(256*256));     n-=o2*256*256;
    o3=int(n/256);           n-=o3*256;
    o4=n;
    print o1"."o2"."o3"."o4;
  }'
}

clean_line() {
  printf "%s" "$1" | sed 's/\r//g; s/^[[:space:]]\+//; s/[[:space:]]\+$//'
}

show_current_range() {
  echo ""
  echo "Current DHCP configuration:"

  ignore="$(uci -q get dhcp.lan.ignore || echo 0)"

  if [ "$ignore" = "1" ]; then
    echo "  Standard UCI DHCP pool: disabled"

    if [ -f "$CUSTOM_FILE" ]; then
      echo "  Custom fragmented ranges:"
      grep '^dhcp-range=' "$CUSTOM_FILE" || echo "  No dhcp-range entries found."
    else
      echo "  No custom range file found at $CUSTOM_FILE"
    fi
  else
    lan_ip="$(uci -q get network.lan.ipaddr || true)"
    netmask="$(uci -q get network.lan.netmask || true)"
    start="$(uci -q get dhcp.lan.start || true)"
    limit="$(uci -q get dhcp.lan.limit || true)"
    leasetime="$(uci -q get dhcp.lan.leasetime || echo 12h)"

    if [ -n "$lan_ip" ] && [ -n "$netmask" ] && [ -n "$start" ] && [ -n "$limit" ]; then
      lan_i="$(ip_to_int "$lan_ip")"
      mask_i="$(ip_to_int "$netmask")"
      net_i="$(awk -v a="$lan_i" -v b="$mask_i" 'BEGIN{printf "%.0f", and(a,b)}')"
      start_i="$(awk -v n="$net_i" -v s="$start" 'BEGIN{printf "%.0f", n+s}')"
      end_i="$(awk -v s="$start_i" -v l="$limit" 'BEGIN{printf "%.0f", s+l-1}')"

      echo "  Standard UCI DHCP pool: enabled"
      echo "  Range: $(int_to_ip "$start_i") - $(int_to_ip "$end_i")"
      echo "  Lease time: $leasetime"
    else
      echo "  Standard UCI DHCP pool appears incomplete."
    fi
  fi

  echo ""
}

read_ranges() {
  ranges=""
  count=0

  echo "Enter DHCP ranges."
  echo "Examples:"
  echo "  Consecutive:   192.168.1.191-192.168.1.200"
  echo "  Fragmented:    enter multiple ranges, one at a time"
  echo ""
  echo "Press Enter on a blank line when finished."
  echo ""

  while :; do
    printf "Range %s: " "$((count + 1))"
    IFS= read -r line
    line="$(clean_line "$line")"

    [ -z "$line" ] && break

    case "$line" in
      *-*)
        start_ip="$(echo "$line" | cut -d- -f1)"
        end_ip="$(echo "$line" | cut -d- -f2)"
        ;;
      *)
        echo "Invalid format. Use start-end, for example 192.168.1.191-192.168.1.200"
        continue
        ;;
    esac

    start_ip="$(clean_line "$start_ip")"
    end_ip="$(clean_line "$end_ip")"

    is_ipv4 "$start_ip" || { echo "Invalid start IP."; continue; }
    is_ipv4 "$end_ip" || { echo "Invalid end IP."; continue; }

    start_i="$(ip_to_int "$start_ip")"
    end_i="$(ip_to_int "$end_ip")"

    awk -v a="$start_i" -v b="$end_i" 'BEGIN{exit (a<=b)?0:1}' || {
      echo "Start IP must be less than or equal to end IP."
      continue
    }

    ranges="${ranges}${start_ip},${end_ip}
"
    count=$((count + 1))
  done

  [ "$count" -gt 0 ] || die "no ranges entered"

  echo "$ranges"
}

apply_consecutive_range() {
  start_ip="$1"
  end_ip="$2"

  lan_ip="$(uci -q get network.lan.ipaddr)" || die "could not read LAN IP"
  netmask="$(uci -q get network.lan.netmask)" || die "could not read LAN netmask"

  lan_i="$(ip_to_int "$lan_ip")"
  mask_i="$(ip_to_int "$netmask")"
  net_i="$(awk -v a="$lan_i" -v b="$mask_i" 'BEGIN{printf "%.0f", and(a,b)}')"

  start_i="$(ip_to_int "$start_ip")"
  end_i="$(ip_to_int "$end_ip")"

  start_offset="$(awk -v s="$start_i" -v n="$net_i" 'BEGIN{printf "%.0f", s-n}')"
  limit="$(awk -v s="$start_i" -v e="$end_i" 'BEGIN{printf "%.0f", e-s+1}')"

  echo "Applying standard UCI DHCP pool:"
  echo "  $start_ip - $end_ip"
  echo "  dhcp.lan.start=$start_offset"
  echo "  dhcp.lan.limit=$limit"

  uci -q delete dhcp.lan.ignore || true
  uci set dhcp.lan.start="$start_offset"
  uci set dhcp.lan.limit="$limit"
  uci set dhcp.lan.leasetime='12h'

  rm -f "$CUSTOM_FILE"

  uci commit dhcp
  /etc/init.d/dnsmasq restart
}

apply_fragmented_ranges() {
  ranges="$1"

  echo "Applying fragmented DHCP ranges:"
  printf "%s" "$ranges" | while IFS= read -r r; do
    [ -n "$r" ] && echo "  $r"
  done

  mkdir -p "$CUSTOM_DIR"

  uci set dhcp.lan.ignore='1'

  uci -q del_list dhcp.@dnsmasq[0].confdir="$CUSTOM_DIR" || true
  uci add_list dhcp.@dnsmasq[0].confdir="$CUSTOM_DIR"

  {
    echo "# Custom fragmented DHCP ranges"
    echo "# Generated by set-dhcp-range"
    echo ""
    printf "%s" "$ranges" | while IFS= read -r r; do
      [ -n "$r" ] && echo "dhcp-range=$r,12h"
    done
  } > "$CUSTOM_FILE"

  uci commit dhcp
  /etc/init.d/dnsmasq restart
}

show_current_range

ranges="$(read_ranges)"
range_count="$(printf "%s" "$ranges" | grep -c . || true)"

echo ""
echo "About to apply:"
printf "%s" "$ranges" | while IFS= read -r r; do
  [ -n "$r" ] && echo "  $r"
done

printf "Proceed? [y/N]: "
IFS= read -r confirm

case "$confirm" in
  y|Y|yes|YES)
    ;;
  *)
    echo "Aborted."
    exit 0
    ;;
esac

if [ "$range_count" -eq 1 ]; then
  one_range="$(printf "%s" "$ranges" | grep .)"
  start_ip="$(echo "$one_range" | cut -d, -f1)"
  end_ip="$(echo "$one_range" | cut -d, -f2)"
  apply_consecutive_range "$start_ip" "$end_ip"
else
  apply_fragmented_ranges "$ranges"
fi

echo ""
echo "Done."
show_current_range
```

## Execution Flow

1.  `95-enable-dhcp-reclaim` enables the `dhcp-reclaim` service during
    first boot.
2.  The `dhcp-reclaim` init script launches `watch-dhcp-exhaustion`
    under `procd`.
3.  The watcher continuously follows the system log.
4.  When dnsmasq logs that no DHCP addresses are available, the watcher
    invokes `reclaim-dhcp-lease`.
5.  The reclamation script identifies disconnected clients occupying
    addresses within the active DHCP pool, removes an eligible lease,
    and reloads/restarts dnsmasq as required.

## Interaction with `set-dhcp-range`

The original reclamation logic assumed a contiguous DHCP pool described
by UCI `start` and `limit` values. The current `set-dhcp-range` script
can instead generate fragmented pools using `dhcp-range=` entries.
Therefore, the reclamation logic must discover the active pool by
preferring the generated custom range file when present and falling back
to UCI only when fragmented ranges are not configured.
