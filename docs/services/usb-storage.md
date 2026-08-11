# USB Storage

The custom OpenWrt image provides automatic mounting and safe removal of USB storage devices.

USB storage is primarily intended for use with the router's FTP server, providing removable storage that can also be accessed directly from a Windows computer when necessary.

The system provides:

* Automatic mounting of supported USB drives
* A consistent `/mnt/usb` mount point
* exFAT filesystem support
* Permissions compatible with the FTP service
* Safe removal using the `usb-eject` command
* Automatic cleanup when a USB removal event is detected
* A utility for organizing FTP files into date-based directories

---

## Overview

When a supported USB drive is inserted, OpenWrt's hotplug system detects the new block device.

The custom hotplug handler:

```text
/etc/hotplug.d/block/99-usb-alias
```

identifies exFAT partitions and mounts the drive at:

```text
/mnt/usb
```

This provides a stable path regardless of whether Linux identifies the physical device as `/dev/sda1`, `/dev/sdb1`, or another device name.

The basic process is:

```text
USB drive inserted
        │
        ▼
OpenWrt block hotplug event
        │
        ▼
99-usb-alias
        │
        ├── Verify device is a partition
        ├── Verify filesystem is exFAT
        └── Mount filesystem
                │
                ▼
            /mnt/usb
                │
                ▼
          Available to FTP
```

When the drive needs to be physically removed, the `usb-eject` utility safely flushes pending filesystem writes and unmounts the drive.

---

# Requirements

The USB storage configuration assumes:

* A single physical USB storage device
* An exFAT-formatted partition
* OpenWrt kernel exFAT support
* FTP user UID `1000`
* FTP group GID `55`

The relevant exFAT package is:

```text
kmod-fs-exfat
```

The custom image also includes the required USB storage and block-device support packages.

---

# Automatic Mounting

USB storage is handled by:

```text
/etc/hotplug.d/block/99-usb-alias
```

The script is invoked automatically by OpenWrt when block-device events occur.

It should not normally be executed manually.

## Mount Conditions

The hotplug handler only attempts to mount devices when:

1. The hotplug event represents a partition.
2. The partition contains an exFAT filesystem.
3. `/mnt/usb` is not already occupied by another mounted device.

Non-exFAT partitions are ignored.

---

## Mount Point

Supported USB storage is always mounted at:

```text
/mnt/usb
```

This provides a predictable storage location independent of the Linux block-device name.

For example, any of the following devices:

```text
/dev/sda1
/dev/sdb1
/dev/sdc1
```

would be exposed to the rest of the system as:

```text
/mnt/usb
```

---

## Mount Options

The filesystem is mounted using:

```text
rw,noatime,uid=1000,gid=55,umask=0007
```

These options configure both performance and access permissions.

### `rw`

Mounts the filesystem with read/write access.

### `noatime`

Prevents Linux from updating a file's access timestamp every time the file is read.

This reduces unnecessary writes to the USB device.

### `uid=1000`

Assigns ownership of files on the exFAT filesystem to UID `1000`, corresponding to the FTP `admin` user.

### `gid=55`

Assigns group ownership to GID `55`, corresponding to the `ftp` group.

### `umask=0007`

Provides full access to the owner and FTP group while denying access to other users.

The resulting access model is:

| User        | Access                 |
| ----------- | ---------------------- |
| `admin`     | Read / Write / Execute |
| `ftp` group | Read / Write / Execute |
| Other users | No access              |

> [!NOTE]
> exFAT does not support normal Linux ownership and permission metadata such as `chown` or individual Unix file modes. Permissions are therefore assigned to the entire filesystem when it is mounted.

---

# OpenWrt Automatic Mounting

OpenWrt's normal automatic filesystem mounting is disabled because USB mounting is handled directly by the custom hotplug script.

The expected `/etc/config/fstab` global configuration is:

```text
config global
    option anon_mount '0'
    option auto_mount '0'
    option anon_swap  '0'
    option auto_swap  '0'
```

This prevents the standard OpenWrt automount system from competing with `99-usb-alias` for the same device.

---

# Safe USB Removal

USB drives should not be physically disconnected while mounted.

Before removing the drive, run:

```sh
usb-eject
```

The command flushes pending filesystem writes and safely unmounts `/mnt/usb`.

A successful operation displays:

```text
Safe to remove USB drive.
```

The USB drive can then be physically removed.

---

## Why Safe Removal Is Required

The USB filesystem is intentionally mounted asynchronously for better FTP performance.

Linux may temporarily cache filesystem changes in memory rather than immediately writing every operation to the physical USB device.

For example, after deleting a file through FTP:

```text
FTP delete
    │
    ▼
Linux filesystem cache
    │
    ▼
USB filesystem
```

There may be a short period during which the deletion has occurred in memory but has not yet been completely committed to the USB device.

Disconnecting the drive during this period can result in:

* Deleted files reappearing
* Lost filesystem changes
* Filesystem metadata corruption
* exFAT filesystem warnings

The `usb-eject` utility prevents this by synchronizing pending writes before unmounting the filesystem.

---

# `usb-eject`

`usb-eject` is the user-facing utility for safely removing USB storage.

## Location

```text
/usr/bin/usb-eject
```

## Usage

```sh
usb-eject
```

The utility:

1. Determines whether `/mnt/usb` is currently mounted.
2. Determines which physical device is mounted there.
3. Executes `sync` to flush pending writes.
4. Attempts to unmount `/mnt/usb`.
5. Executes another `sync`.
6. Reports when the device can safely be removed.

If the normal `umount` operation fails, the utility attempts to use OpenWrt's `block` utility as a fallback.

---

## Failed Unmount

If a process is still using the USB filesystem, `usb-eject` may report:

```text
ERROR: Failed to unmount /mnt/usb. A process may still be using it.
```

Do **not** physically remove the USB drive when this occurs.

Determine which process is using the filesystem before attempting the eject operation again.

If available, useful diagnostic commands include:

```sh
fuser -m /mnt/usb
```

or:

```sh
lsof +D /mnt/usb
```

---

# Automatic Removal Handling

The `99-usb-alias` hotplug handler also responds to block-device `remove` and `unbind` events.

When one of these events occurs, the handler attempts to:

1. Determine whether the removed device was mounted at `/mnt/usb`.
2. Execute `sync`.
3. Unmount the filesystem.
4. Perform a final synchronization.

This provides cleanup when the operating system detects that a USB device has been removed.

> [!WARNING]
> Automatic removal handling is not a substitute for `usb-eject`.
>
> The device has already begun disappearing from the system by the time a removal event is generated. Always use `usb-eject` before physically disconnecting the USB drive.

---

# Organizing Files by Date

The custom image also includes:

```text
/usr/bin/organize-by-date
```

This utility organizes files within the FTP storage directory into directories based on each file's modification date.

## Usage

```sh
organize-by-date <directory>
```

For example:

```sh
organize-by-date /mnt/usb/FTP
```

Given:

```text
/mnt/usb/FTP/
├── image1.jpg
├── image2.jpg
└── image3.jpg
```

the utility may reorganize the files as:

```text
/mnt/usb/FTP/
├── 2026-08-10/
│   ├── image1.jpg
│   └── image2.jpg
└── 2026-08-11/
    └── image3.jpg
```

The date directories are created from the files' modification dates.

---

## Safety Restrictions

`organize-by-date` intentionally restricts the directories in which it is allowed to operate.

Supported FTP storage locations include:

```text
/mnt/usb/FTP
/mnt/sda1/FTP
/mnt/sdb1/FTP
```

This restriction prevents an incorrect command from reorganizing files elsewhere on the router's filesystem.

---

# Files

The USB storage system consists of the following components:

| File                                | Purpose                                                 |
| ----------------------------------- | ------------------------------------------------------- |
| `/etc/hotplug.d/block/99-usb-alias` | Automatically mounts and handles removal of USB storage |
| `/usr/bin/usb-eject`                | Safely synchronizes and unmounts USB storage            |
| `/usr/bin/organize-by-date`         | Organizes FTP files into date-based directories         |
| `/etc/config/fstab`                 | Disables OpenWrt's standard automatic mounting          |

---

# Verification

## Check the Mounted Device

After inserting a USB drive:

```sh
mount | grep /mnt/usb
```

A successful mount should show the USB partition mounted at:

```text
/mnt/usb
```

---

## Check the Mount Point

```sh
ls -ld /mnt/usb
```

---

## Check Hotplug Logs

The USB hotplug handler writes messages using the `hotplug-usb` log tag.

View them with:

```sh
logread -e hotplug-usb
```

Typical entries include:

```text
Mounted /dev/sdX1 at /mnt/usb
Unmounted /mnt/usb (/dev/sdX1)
```

---

## Check the Filesystem

The underlying block device and filesystem can be inspected with:

```sh
block info
```

The USB partition should report:

```text
TYPE="exfat"
```

---

# Troubleshooting

## USB Drive Does Not Mount

First verify that OpenWrt detected the device:

```sh
block info
```

Then check the hotplug log:

```sh
logread -e hotplug-usb
```

Verify that the partition is formatted as exFAT.

The automatic mount handler intentionally ignores other filesystem types.

---

## `/mnt/usb` Is Already Mounted

Only one device can occupy `/mnt/usb`.

Check the currently mounted device:

```sh
mount | grep /mnt/usb
```

Safely eject the existing device before inserting another:

```sh
usb-eject
```

---

## FTP Cannot Write to the Drive

Verify the mount options:

```sh
mount | grep /mnt/usb
```

The mount should include the expected ownership and permission options:

```text
uid=1000,gid=55,umask=0007
```

Also verify that the FTP user and group IDs still correspond to:

```text
admin = UID 1000
ftp   = GID 55
```

---

## Deleted Files Reappear

This normally indicates that the USB drive was removed without first safely unmounting it.

Always run:

```sh
usb-eject
```

and wait for:

```text
Safe to remove USB drive.
```

before physically disconnecting the drive.

---

# Operational Summary

Normal USB operation is:

```text
Insert USB drive
       │
       ▼
Automatically mounted at /mnt/usb
       │
       ▼
Use FTP normally
       │
       ▼
Run usb-eject
       │
       ▼
Wait for "Safe to remove USB drive."
       │
       ▼
Physically remove USB drive
```

For normal operation:

1. Insert the USB drive.
2. Allow it to mount automatically at `/mnt/usb`.
3. Use the FTP server normally.
4. Run `usb-eject` when finished.
5. Wait for the safe-removal confirmation.
6. Physically remove the USB drive.

The underlying hotplug and mount scripts operate automatically and should not normally require manual intervention.