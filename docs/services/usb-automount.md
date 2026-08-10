# OpenWrt USB Auto-Mount Setup (exFAT, hotplug.d)

This document records the complete, working procedure used to configure
automatic USB mounting on OpenWrt using a hotplug script.

The final configuration provides:

- Any USB drive auto-mounts to `/mnt/usb`
- exFAT filesystem support (kernel driver: `kmod-fs-exfat`)
- Stable mount path independent of `/dev/sdX`
- Correct permissions for FTP user access
- Automatic clean unmount on removal events
- Mandatory safe manual removal workflow
- No reliance on OpenWrt automatic mounting
- High FTP performance with Windows compatibility

---

## System Assumptions

- Single physical USB port
- USB drive formatted as exFAT
- Using kernel exFAT driver (`kmod-fs-exfat`)
- FTP user:
  - UID: `1000` (`admin`)
  - GID: `55` (`ftp`)

---

## Disable OpenWrt Automatic Mounting

Edit `/etc/config/fstab`:

```text
config global
    option anon_mount '0'
    option auto_mount '0'
    option anon_swap  '0'
    option auto_swap  '0'
```

Disable the service:

```sh
/etc/init.d/fstab stop
/etc/init.d/fstab disable
```

---

# Hotplug Mount Script

Create:

```sh
nano /etc/hotplug.d/block/99-usb-alias
```

Script contents:

```sh
#!/bin/sh
# Mount exFAT partitions at /mnt/usb on add
# Unmount cleanly on remove/unbind

set -eu

MOUNTPOINT="/mnt/usb"
log() { logger -t hotplug-usb "$*"; }

[ "${DEVTYPE:-}" = "partition" ] || exit 0
DEV="/dev/${DEVNAME:-}"

mkdir -p "$MOUNTPOINT"

mounted_dev() {
  awk -v mp="$MOUNTPOINT" '$2==mp {print $1; exit}' /proc/mounts || true
}

case "${ACTION:-}" in
  add)
    if grep -qs " $MOUNTPOINT " /proc/mounts; then
      log "Already mounted at $MOUNTPOINT ($(mounted_dev))"
      exit 0
    fi

    TYPE="$(block info "$DEV" 2>/dev/null | sed -n 's/.*TYPE="\([^"]*\)".*/\1/p')"
    [ "$TYPE" = "exfat" ] || exit 0

    mount -t exfat -o rw,noatime,uid=1000,gid=55,umask=0007 "$DEV" "$MOUNTPOINT" \
        && log "Mounted $DEV at $MOUNTPOINT"
    ;;

  remove|unbind)
    cur="$(mounted_dev)"
    if [ -n "$cur" ] && [ "$cur" = "$DEV" ]; then
      sync || true
      if umount "$MOUNTPOINT" 2>/dev/null; then
        sync || true
        log "Unmounted $MOUNTPOINT ($DEV)"
      else
        /sbin/block umount "$DEV" 2>/dev/null || true
        sync || true
        log "Removal event processed for $DEV"
      fi
    fi
    ;;
esac

exit 0
```

Make executable:

```sh
chmod +x /etc/hotplug.d/block/99-usb-alias
```

---

# Permission Model

Mount options used:

```text
uid=1000
gid=55
umask=0007
```

Result:

- `admin` → read/write/execute
- `ftp` group → read/write/execute
- all other users → denied

Note: exFAT does not support `chown` or per-directory permissions.
All permissions are controlled at mount time.

---

# Why Deleted Files Can "Come Back"

Linux uses write-back caching for performance.

When deleting files over FTP:

- Directory metadata changes may remain in memory temporarily.
- If the drive is unplugged before `sync` occurs,
  the delete may not yet be committed to disk.
- Upon reinsertion, the old on-disk directory state reappears.

This is normal async filesystem behavior.

For high FTP performance, the drive is mounted asynchronously.
Therefore, safe removal is REQUIRED.

---

# Safe Removal Procedure

The USB drive should never be unplugged directly.

Before removal, always run:

```sh
usb-eject
```

Wait for:

```
Safe to remove USB drive.
```

Only then unplug the drive.

Failure to follow this procedure may result in:
- Deleted files reappearing
- Metadata corruption
- exFAT filesystem warnings

---

# usb-eject Helper Script (Required)

Create:

```sh
nano /usr/bin/usb-eject
```

Script contents:

```sh
#!/bin/sh
# /usr/bin/usb-eject
# Eject flash drive

MP="/mnt/usb"

is_mounted() {
  # Returns 0 if MP is mounted, 1 otherwise
  grep -qs " $MP " /proc/mounts
}

mounted_dev() {
  # Prints the device mounted at MP (blank if not mounted)
  awk -v mp="$MP" '$2==mp {print $1; exit}' /proc/mounts
}

if is_mounted; then
  DEV="$(mounted_dev)"
  echo "Flushing writes to ${DEV:-device}..."
  sync
  sleep 2

  echo "Unmounting $MP..."
  if umount "$MP" 2>/dev/null; then
    sync
    echo "Safe to remove USB drive."
    exit 0
  fi

  # Fallback for OpenWrt block helper (if present)
  if [ -x /sbin/block ]; then
    /sbin/block umount "$DEV" 2>/dev/null || /sbin/block umount 2>/dev/null || true
  fi

  if ! is_mounted; then
    sync
    echo "Safe to remove USB drive."
    exit 0
  fi

  echo "ERROR: Failed to unmount $MP. A process may still be using it."
  echo "Try: lsof +D $MP  (if lsof installed) or: fuser -m $MP (if fuser installed)"
  exit 1
else
  echo "Not mounted at $MP."
  exit 0
fi

```

Make executable:

```sh
chmod +x /usr/bin/usb-eject
```

---

# Performance Notes

- Async mount for maximum FTP speed
- No `sync` mount option (avoids performance penalty)
- No `flush` option (unsupported by kernel exFAT)
- Safe removal guarantees metadata integrity
- exFAT maintained for Windows compatibility

---

# Verification

After reinserting USB drive:

```sh
mount | grep /mnt/usb
ls -ld /mnt/usb
```

Check logs:

```sh
logread -e hotplug-usb
```

Expected entries:

```text
Mounted /dev/sdX1 at /mnt/usb
Unmounted /mnt/usb (/dev/sdX1)
```

---

# Operational Summary

1. Insert USB drive → auto-mounts to `/mnt/usb`
2. Use FTP normally at full speed
3. When finished → run `usb-eject`
4. Wait for confirmation
5. Remove USB drive

This configuration provides:

- Maximum FTP performance
- Windows compatibility
- Predictable mount behavior
- Safe metadata handling
- No file resurrection issues