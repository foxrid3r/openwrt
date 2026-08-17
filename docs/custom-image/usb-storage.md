
# USB Storage

The custom image provides automatic mounting, safe removal, and basic file-management tools for removable USB storage.

USB storage is primarily used by the router's FTP service.

## Overview

When a supported USB partition is inserted, OpenWrt generates a block-device hotplug event.

The custom handler:

```text
/etc/hotplug.d/block/99-usb-alias
```

mounts supported exFAT partitions at the stable path:

```text
/mnt/usb
```

This keeps the FTP path consistent regardless of whether Linux names the device `/dev/sda1`, `/dev/sdb1`, or another `/dev/sdX` partition.

The normal workflow is:

```text
Insert USB drive
      │
      ▼
99-usb-alias
      │
      ▼
/mnt/usb
      │
      ▼
Use FTP / local tools
      │
      ▼
usb-eject
      │
      ▼
Safe to remove
```

## Requirements

The current configuration assumes:

- One USB storage device at a time.
- An exFAT-formatted partition.
- Kernel exFAT support.
- FTP user UID `1000`.
- FTP group GID `55`.

The image includes the required USB-storage and exFAT packages.

## Standard OpenWrt Automount Is Disabled

The image disables the normal anonymous OpenWrt automount behavior in:

```text
/etc/config/fstab
```

The expected global configuration is:

```text
config global
        option anon_swap '0'
        option anon_mount '0'
        option auto_swap '0'
        option auto_mount '0'
        option check_fs '0'
```

The custom hotplug handler therefore owns the `/mnt/usb` mount process.

## Automatic Mounting

The hotplug script only handles partition events:

```text
DEVTYPE=partition
```

On an `add` event it:

1. Verifies that `/mnt/usb` is not already occupied.
2. Uses `block info` to determine the filesystem type.
3. Ignores non-exFAT partitions.
4. Mounts the exFAT partition at `/mnt/usb`.

The mount options are:

```text
rw,noatime,uid=1000,gid=55,umask=0007
```

### Permission Model

| Setting | Purpose |
|---|---|
| `uid=1000` | Files appear owned by the FTP `admin` user |
| `gid=55` | Files appear owned by the FTP group |
| `umask=0007` | Owner/group receive access; other users are denied |
| `noatime` | Avoid unnecessary access-time writes |
| `rw` | Mount read/write |

exFAT does not provide normal per-file Unix ownership and mode storage, so these permissions are assigned at mount time.

## Safe Removal

Do not physically unplug a mounted USB drive.

Run:

```sh
usb-eject
```

The command:

1. Determines the device mounted at `/mnt/usb`.
2. Runs `sync`.
3. Waits briefly.
4. Attempts to unmount `/mnt/usb`.
5. Uses the OpenWrt `block` helper as a fallback.
6. Reports when the drive is safe to remove.

A successful operation ends with:

```text
Safe to remove USB drive.
```

Only unplug the drive after seeing that message.

## Why Safe Removal Matters

The filesystem is mounted asynchronously for normal performance.

Linux may cache file and directory changes before committing them to the physical device. Pulling the drive before those writes complete can cause:

- Deleted files to reappear.
- Lost file changes.
- Filesystem metadata damage.
- exFAT consistency warnings.

`usb-eject` forces pending writes to storage before unmounting.

## Failed Unmount

If a process still has the filesystem open, `usb-eject` may report:

```text
ERROR: Failed to unmount /mnt/usb. A process may still be using it.
```

Do not remove the device.

If available, inspect users of the mount with:

```sh
fuser -m /mnt/usb
```

or:

```sh
lsof +D /mnt/usb
```

Then close the process and run `usb-eject` again.

## Automatic Removal Handling

The hotplug script also handles `remove` and `unbind` events.

If the disappearing device is the one mounted at `/mnt/usb`, the handler attempts to synchronize and unmount it.

This is cleanup behavior only.

> [!WARNING]
> A removal hotplug event happens after physical removal has begun. It is not a replacement for running `usb-eject` first.

## `organize-by-date`

The image includes:

```text
/usr/bin/organize-by-date
```

It moves regular files into `YYYY-MM-DD` folders based on each file's modification time.

Example:

```sh
organize-by-date /mnt/usb/FTP
```

Before:

```text
/mnt/usb/FTP/
├── image1.jpg
├── image2.jpg
└── image3.jpg
```

After:

```text
/mnt/usb/FTP/
├── 2026-08-10/
│   ├── image1.jpg
│   └── image2.jpg
└── 2026-08-11/
    └── image3.jpg
```

### Safety Restrictions

The tool only accepts directories at or below:

```text
/mnt/usb/FTP
/mnt/sda1/FTP
/mnt/sdb1/FTP
```

This prevents an accidental invocation from reorganizing unrelated parts of the router filesystem.

## Files

| File | Purpose |
|---|---|
| `/etc/config/fstab` | Disables the competing standard automount behavior |
| `/etc/hotplug.d/block/99-usb-alias` | Mounts exFAT storage at `/mnt/usb` |
| `/usr/bin/usb-eject` | Safely flushes and unmounts USB storage |
| `/usr/bin/organize-by-date` | Sorts FTP files into date folders |

## Verification

Check the mount:

```sh
mount | grep /mnt/usb
```

Inspect block devices:

```sh
block info
```

View hotplug logs:

```sh
logread -e hotplug-usb
```

Typical messages include:

```text
Mounted /dev/sdX1 at /mnt/usb (uid=1000 gid=55 umask=0007)
Unmounted /mnt/usb (/dev/sdX1)
```

## Troubleshooting

### Drive Is Detected but Does Not Mount

Run:

```sh
block info
```

The partition must report:

```text
TYPE="exfat"
```

The custom handler intentionally ignores other filesystem types.

### `/mnt/usb` Is Already Occupied

Only one device can use the standard mount point at a time.

Check:

```sh
mount | grep /mnt/usb
```

Safely eject the existing device before inserting another.

### FTP Cannot Write

Verify the mount options:

```sh
mount | grep /mnt/usb
```

Confirm the expected UID/GID remain correct for the FTP account.

## Related Documentation

- [FTP Server](ftp-service.md)
- [Tool Reference](../tools/README.md)
