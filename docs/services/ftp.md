# OpenWrt FTP Server Setup (vsftpd)

This document records the complete, working procedure used to configure an FTP server
on OpenWrt using `vsftpd`.

The final configuration provides:
- FTP access for a single user (`admin`)
- Only `admin` is jailed (chrooted)
- `admin` has no SSH or shell access
- FTP root directory is `/mnt/usb/FTP`
- Authentication uses system users
- Compatible with USB-backed storage

---

## Prerequisites

- Logged in as `root` via SSH
- USB storage already mounted at `/mnt/usb`
- FTP directory exists at `/mnt/usb/FTP`

---

## Install vsftpd

```sh
opkg update
opkg install vsftpd
/etc/init.d/vsftpd enable
```

---

## Create / Configure FTP User

Edit `/etc/passwd` so the user is non-interactive and not tied to removable media:

```text
admin:<hashed_password>:1000:55::/tmp:/bin/false
```

User details:
- Username: `admin`
- UID: `1000`
- GID: `55` (group `ftp`)
- Shell: `/bin/false` (FTP-only account)

Set or reset the password:

```sh
passwd admin
```

---

## Allow /bin/false for FTP Authentication

vsftpd validates the login shell against `/etc/shells`.
If `/bin/false` is missing, FTP login fails with `530 Login incorrect`.

Fix:

```sh
echo /bin/false >> /etc/shells
```

---

## Configure vsftpd

Edit `/etc/vsftpd.conf`:

```ini
# -----------------------------------------------------------------------------
# Basic server mode
# -----------------------------------------------------------------------------

listen=YES
# Run vsftpd in standalone mode, listening on IPv4 sockets.
# (Required when not using inetd/systemd socket activation.)

listen_ipv6=NO
# Disable IPv6 listening. Only IPv4 connections will be accepted.

background=YES
# Run vsftpd as a background daemon instead of blocking the terminal.


# -----------------------------------------------------------------------------
# Authentication & user access
# -----------------------------------------------------------------------------

anonymous_enable=NO
# Disable anonymous FTP access.
# All users must authenticate with a valid local system account.

local_enable=YES
# Allow local system users (from /etc/passwd) to log in via FTP.

write_enable=YES
# Enable write operations (upload, delete, rename files/directories).
# Required for any user who needs to modify files.


# -----------------------------------------------------------------------------
# Chroot (filesystem isolation)
# -----------------------------------------------------------------------------

chroot_local_user=NO
# Do NOT chroot all local users by default.
# Chroot behavior will instead be controlled using a chroot list.

chroot_list_enable=YES
# Enable selective chrooting using a list file.

chroot_list_file=/etc/vsftpd.chroot
# File containing usernames that SHOULD be chrooted
# (i.e., restricted to their home directory).
# One username per line.

allow_writeable_chroot=YES
# Allow users to be chrooted into directories that are writable.
# This is often required for embedded systems (like OpenWRT),
# but should be enabled only when you trust the users.


# -----------------------------------------------------------------------------
# Per-user configuration
# -----------------------------------------------------------------------------

user_config_dir=/etc/vsftpd.users
# Directory containing optional per-user configuration files.
# If a file named after the username exists here, its settings
# will override global settings for that user.


# -----------------------------------------------------------------------------
# User allow/deny list
# -----------------------------------------------------------------------------

userlist_enable=YES
# Enable user access control using a user list file.

userlist_file=/etc/vsftpd.userlist
# File containing usernames that are allowed or denied FTP access,
# depending on the userlist_deny setting.

userlist_deny=NO
# Treat the userlist as an ALLOW list.
# Only users listed in /etc/vsftpd.userlist are permitted to log in.


# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

xferlog_enable=YES
# Enable logging of file transfers (uploads/downloads).

log_ftp_protocol=YES
# Enable verbose logging of all FTP protocol commands and responses.
# Useful for debugging authentication, permissions, and client behavior.
```

---

## Jail Only the admin User

Create `/etc/vsftpd.chroot`:

```text
admin
```

Create `/etc/vsftpd.userlist`:

```text
admin
```

---

## Set FTP Jail Directory for admin

Create per-user config directory and file:

```sh
mkdir -p /etc/vsftpd.users
```

Create `/etc/vsftpd.users/admin`:

```ini
local_root=/mnt/usb/FTP
```

## 🏗 Why It’s Designed This Way

`vsftpd` separates configuration into distinct files to enforce security through separation of concerns. Each file controls a different layer of behavior.

This design prevents accidental misconfiguration and supports scalable, secure multi-user setups.

| File | Controls |
|------|----------|
| `vsftpd.conf` | Global server defaults and core behavior |
| `/etc/vsftpd.userlist` | Which users are allowed (or denied) login access |
| `/etc/vsftpd.chroot` | Which users are jailed (restricted to their home directory) |
| `/etc/vsftpd.users/<username>` | Per-user configuration overrides |

### Why This Separation Matters

- 🔐 **Authentication control** is separate from filesystem access.
- 🚪 **Login permission** is separate from directory isolation.
- 🧩 **Per-user behavior** can override global defaults safely.
- 🛡️ Prevents privilege escalation or unintended directory access.
- 📈 Makes it easy to scale from a single-user setup to multiple users.

This layered approach is intentional and aligns with `vsftpd`’s security-focused design philosophy.

---

## Restart FTP Server

```sh
/etc/init.d/vsftpd restart
```

---

## Verification

- FTP login as `admin` succeeds
- `admin` is jailed to `/mnt/usb/FTP`
- `cd ..` is denied
- File uploads succeed
- SSH login as `admin` fails
