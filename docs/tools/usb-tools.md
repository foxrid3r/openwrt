# USB Tools

The image includes two commands for USB-backed FTP storage.

## `usb-eject`

Flushes pending writes and safely unmounts `/mnt/usb`:

```sh
usb-eject
```

Do not physically remove the drive until the command reports that it is safe.

## `organize-by-date`

Moves files below an approved FTP directory into `YYYY-MM-DD` directories based on modification time:

```sh
organize-by-date /mnt/usb/FTP
```

See [USB Storage](../custom-image/usb-storage.md) for mount requirements, safety restrictions, verification, and troubleshooting.
