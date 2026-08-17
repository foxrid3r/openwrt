
# FTP Server

The custom image includes `vsftpd` for file access to the router's removable USB storage.

## Overview

The factory configuration provides:

- A single permitted FTP user: `admin`
- No anonymous FTP access
- No interactive shell access for `admin`
- A jailed FTP root at `/mnt/usb/FTP`
- Read/write FTP access
- FTP protocol and transfer logging

The FTP server depends on the USB-storage system documented in [USB Storage](usb-storage.md).

## Factory FTP Account

The first-boot script:

```text
/etc/uci-defaults/20-create-ftp-admin
```

creates the FTP account if required.

Factory credentials are:

```text
Username: admin
Password: admin
```

The account is created with:

```text
Home:  /mnt/usb/FTP
Shell: /bin/false
```

> [!IMPORTANT]
> The factory FTP password is a public shared bootstrap credential. Change it when unique credentials are required.

Change the FTP password with:

```sh
passwd admin
```

`provision-router` does not currently change the FTP password.

## FTP Storage Location

The FTP root is:

```text
/mnt/usb/FTP
```

The USB hotplug handler mounts the removable exFAT filesystem at `/mnt/usb`.

The FTP directory is created by the first-boot account script if it does not already exist.

## vsftpd Configuration

The server configuration is stored at:

```text
/etc/vsftpd.conf
```

Important settings include:

```ini
listen=YES
listen_ipv6=NO
background=YES

anonymous_enable=NO
local_enable=YES
write_enable=YES

chroot_local_user=NO
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot
allow_writeable_chroot=YES

user_config_dir=/etc/vsftpd.users

userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

xferlog_enable=YES
log_ftp_protocol=YES
```

## Access Control

Only users listed in:

```text
/etc/vsftpd.userlist
```

are permitted to authenticate.

The image permits:

```text
admin
```

The `admin` user is also listed in:

```text
/etc/vsftpd.chroot
```

so the FTP session is restricted to the configured FTP root.

## Per-User Root

The per-user configuration file is:

```text
/etc/vsftpd.users/admin
```

and points the account at:

```text
/mnt/usb/FTP
```

## `/bin/false`

The FTP account is intentionally non-interactive:

```text
/bin/false
```

This prevents the `admin` account from being used as a normal shell login.

vsftpd must be able to accept that shell according to the image's authentication configuration.

## USB Permission Model

The exFAT USB filesystem is mounted with:

```text
uid=1000,gid=55,umask=0007
```

This is intended to give the FTP account and FTP group read/write access to the removable storage.

See [USB Storage](usb-storage.md) for details.

## Service Management

Check status:

```sh
/etc/init.d/vsftpd status
```

Restart:

```sh
/etc/init.d/vsftpd restart
```

Enable at boot:

```sh
/etc/init.d/vsftpd enable
```

## Verification

Confirm the USB filesystem is mounted:

```sh
mount | grep /mnt/usb
```

Confirm the FTP directory exists:

```sh
ls -ld /mnt/usb/FTP
```

Check the FTP account:

```sh
id admin
```

Inspect logs while connecting:

```sh
logread -f
```

## Troubleshooting

### FTP Login Fails

Verify:

- The `admin` account exists.
- Its password is correct.
- `admin` is present in `/etc/vsftpd.userlist`.
- `/bin/false` is accepted by the authentication setup.
- vsftpd is running.

### Upload/Delete Fails

Verify the USB filesystem is mounted read/write and has the expected UID/GID:

```sh
mount | grep /mnt/usb
```

### FTP Root Is Empty or Missing

Verify the USB drive is mounted at:

```text
/mnt/usb
```

and that:

```text
/mnt/usb/FTP
```

exists.

## Related Documentation

- [USB Storage](usb-storage.md)
- [Router Provisioning](../getting-started/provisioning.md)
- [Tool Reference](../tools/README.md)
