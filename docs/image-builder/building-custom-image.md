# 🛠️ Building a Custom OpenWrt Image with Image Builder Using WSL

This guide walks through using the **OpenWrt Image Builder** inside **WSL (Ubuntu/Debian/Mint)** to create a custom firmware image with your own packages and configuration.

---

## 1️⃣ Install WSL + Linux Distro

Install a Linux distro (Ubuntu v24.04 recommended) via WSL.

Open **PowerShell** and run:

```powershell
wsl --install -d Ubuntu-24.04
```

## 2️⃣ Edit Config File

The `/etc/wsl.config` should look like this to get rid of the mixing of Windows paths with your linux environment:

```bash
cd /
sudo nano etc/wsl.conf
```

```bash
[boot]
systemd=true
[interop]
appendWindowsPath=false
[automount]
enabled=false
[user]
default=yourwslusernamehere
```

```bash
wsl --shutdown
wsl -d Ubuntu-24.04
```

Verify whether no Windows path elements appear in the PATH environment variable, by the following command in WSL:

`echo ${PATH}` now gives:
```bash
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib
```

## 3️⃣ Install Required Build Dependencies

Inside your Linux terminal:

```bash
sudo apt update
sudo apt dist-upgrade
sudo apt install build-essential file libncurses-dev zlib1g-dev gawk git \
gettext libssl-dev xsltproc rsync wget unzip python3 python3-setuptools zstd
```

## 4️⃣ Run WSL (Linux distro already installed and build environment setup)

Open **PowerShell** and run:

```powershell
wsl -d Ubuntu-24.04
```


## 5️⃣ Download the ImageBuilder Archive for the Device
Find the appropriate OpenWRT ImageBuilder for the device. For example, v24.10.5 for a Linksys E8450 which has already been flashed with OpenWRT v24.10.X or later can be found here:

https://downloads.openwrt.org/releases/24.10.5/targets/mediatek/mt7622/openwrt-imagebuilder-24.10.5-mediatek-mt7622.Linux-x86_64.tar.zst

### ⚠️ **WARNING**  
If the device has not previously been flashed with OpenWRT, first follow the appropriate guide for flashing OpenWRT to the device.

### ⚠️ **WARNING (Linksys E8450)**  
Before upgrading to a snapshot after 2024-02-15 or any newer release, if you're running OpenWrt 23.05.x or older, or a snapshot before 2024-02-15, you will need to run a new installer. If you're simply upgrading to 23.05.4, or if you're upgrading from 24.10.X to a newer release, you do not need to flash an **`installer`** firmware.

https://openwrt.org/toh/linksys/e8450

## 6️⃣ Create a Working Directory
The Image Builder needs to build images within a case-sensitive filesystem. The default working directory for WSL is a directory within the Windows filesystem (e.g. /mnt/c/Users/User$) which is not case-sensitive. Switch to the home directory within WSL, then create a temporary directory to build within. You can drag and drop files into this directory from Windows File Explorer.

```bash
cd /
mkdir -p /tmp/owrt
cd /tmp/owrt
```

In Windows File Explorer, this location can be found here:

```bash
\\wsl.localhost\Ubuntu-24.04\tmp\owrt
````

Copy your downloaded **Image Builder archive** (`*.tar.zst`) into this folder:

```bash
\\wsl.localhost\Ubuntu-24.04\tmp\owrt\openwrt-imagebuilder-24.10.5-mediatek-mt7622.Linux-x86_64.tar.zst
````

## 7️⃣ Extract the Image Builder

Extract the compressed ImageBuilder archive into a new directory, then `cd` into the newly created directory.

```bash
tar --zstd -xvf openwrt-imagebuilder-*.tar.zst
cd openwrt-imagebuilder*/
```


## 8️⃣ Customizing the Firmware

Customization can be done manually by placing files into:

```bash
/tmp/owrt/openwrt-imagebuilder-24.10.5-mediatek-mt7622.Linux-x86_64/files/
```

But it’s much easier to the copy configuration files from an already-configured router.

### 📥 Copy Existing Router Config

Create a config backup from a device that's already been configured and place it into the temporary working directory:

```bash
/tmp/owrt/backup-Spare1-2026-02-17.tar.gz
```

Navigate to the directory where the archive was copied to:

```bash
cd /tmp/owrt
```

Extract the archive:

```bash
tar -xvzf backup-*.tar.gz
```

You should now see the extracted `etc` directory:

```bash
ls /tmp/owrt/etc
```

Copy the unpacked `etc` directory into the ImageBuilder `files` directory:

```bash
cp -r etc openwrt=imagebuilder-*/files/
```

### ➕ Additional Configuration
Copy any additional custom scripts or configuration files into the appropriate locations inside the ImageBuilder `files` directory. For example:

```bash
/files/usr/bin/dhcp-mode
/files/usr/bin/organize-by-date
/files/usr/bin/usb-eject
/files/usr/sbin/provision-router
/files/usr/sbin/reclaim-dhcp-lease
/files/usr/sbin/set-dhcp-range
/files/usr/sbin/watch-dhcp-exhaustion
/files/etc/hotplug.d/block/99-usb-alias
/files/etc/init.d/dhcp-reclaim
/files/etc/uci-defaults/95-enable-dhcp-reclaim
/files/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
/files/etc/banner
```

Change into the `files` directory before modifying permissions:

```bash
cd openwrt-imagebuilder-*/files
```

You should now be in:
```bash
/tmp/owrt/openwrt-imagebuilder-*/files
```
#### ⚠️ Set Executable Permissions
Mark any scripts that must be executable:

```bash
chmod +x usr/bin/dhcp-mode
chmod +x usr/bin/organize-by-date
chmod +x usr/bin/usb-eject
chmod +x usr/sbin/provision-router
chmod +x usr/sbin/reclaim-dhcp-lease
chmod +x usr/sbin/set-dhcp-range
chmod +x usr/sbin/watch-dhcp-exhaustion
chmod +x etc/hotplug.d/block/99-usb-alias
```

#### ⚠️ Important
Run `chmod` from inside the `files` directory and use relative paths.

If you run a command like:

```bash
chmod +x /usr/bin/dhcp-mode
```

it will attempt to modify `/usr/bin` on your host system, **not** inside the ImageBuilder filesystem overlay.

### 🏳 Welcome Banner
Edit the banner file to include the image version, OpenWrt  version and build date.

```bash
sudo nano ./files/etc/banner
```

```bash
╔═════════════════════════════════════════════════════════╗
║               ___ _   ___     _____ ___                 ║
║              |_ _| \ | \ \   / /_ _/ _ \                ║
║               | ||  \| |\ \ / / | | | | |               ║
║               | || |\  | \ V /  | | |_| |               ║
║              |___|_| \_|  \_/  |___\___/                ║
║    _  _   _ _____ ___  __  __   _ _____ ___ ___  _  _   ║
║   /_\| | | |_   _/ _ \|  \/  | /_\_   _|_ _/ _ \| \| |  ║
║  / _ \ |_| | | || (_) | |\/| |/ _ \| |  | | (_) | .` |  ║
║ /_/ \_\___/  |_| \___/|_|  |_/_/ \_\_| |___\___/|_|\_|  ║
║                                                         ║
║ Custom E8450 Router Image                               ║
║ Version: 1.6.1                                          ║
║ OpenWrt: 24.10.5                                        ║
║ Build: 2026-08-10 08:49                                 ║
╚═════════════════════════════════════════════════════════╝
```


## 9️⃣ Cleaning Build Files
`make clean` removes files that were generated during the build process so you can rebuild from a clean state.

When you run:

```bash
make clean
```

You are telling `make` to execute the `clean` target defined inside a `Makefile`.

It usually:

- 🗑 Deletes compiled object files (*.o)
- 🗑 Deletes executables (a.out, program.exe, etc.)
- 🗑 Removes intermediate build artifacts
- 🗑 Clears temporary build directories

It does not remove your source code (.c, .cpp, .h, etc.).


## 🔟 Building the Image

```bash
make image \
PROFILE="profile-name" \
PACKAGES="pkg1 pkg2 pkg3 -pkg4 -pkg5" \
FILES="files" \
DISABLED_SERVICES="svc1 svc2 svc3"
```

### 💡 Build Example — Linksys E8450

```bash
make image \
PROFILE="linksys_e8450-ubi" \
PACKAGES="block-mount gdisk nano \
vsftpd kmod-fs-exfat kmod-usb-storage \
kmod-usb3 kmod-usb-storage-uas usbutils \
libblkid kmod-nft-bridge nftables \
luci exfat-fsck" \
FILES="files" \
EXTRA_IMAGE_NAME="invio_v1.6.1"
```

### 📂 Output Location

Built images are stored in:

```bash
./bin/targets/<target>/<subtarget>/
```

Common files:

- `*-squashfs-sysupgrade.itb`
- `*-preloader.bin`
- `*-bl31-uboot.fip`

---


# ✅ Summary

You now know how to:

✔ Use WSL for OpenWrt builds  
✔ Import router configs into firmware  
✔ Add/remove packages safely  
✔ Embed custom files  
✔ Build device-specific firmware images

---
# 📎 Appendix

## 🧩 Image Builder Variables

| Variable | Description |
|----------|-------------|
| `PROFILE` | Target device profile |
| `PACKAGES` | Packages to include or exclude |
| `FILES` | Directory containing custom files |
| `BIN_DIR` | Alternative output directory |
| `EXTRA_IMAGE_NAME` | Custom suffix for output filename |
| `DISABLED_SERVICES` | Services to disable |
| `ROOTFS_PARTSIZE` | Root partition size (MB) |

Run for full help:

```bash
make help
```

### 🎯 Selecting a Device Profile

```bash
PROFILE="profile-name"
```

List available profiles:

```bash
make info
```


### 📦 Selecting Packages

Include packages normally, exclude with `-`:

```bash
PACKAGES="pkg1 pkg2 pkg3 -pkg4 -pkg5"
```

#### Notes

- Dependencies are resolved automatically  
- Too many packages can brick the device (storage limits!)  
- Use your current installed package list as a guide:

```bash
echo $(opkg list-installed | sed -e "s/\s.*$//")
```

#### ⚠️ ABI-Versioned Packages

Do **not** include packages like:

```
libubus20191227
```

These can break builds. Let dependencies install correct versions.

You can normalize a list with:

```bash
--strip-abi
```

### 📦 Adding Custom `.ipk` Packages

Create a folder:

```bash
mkdir packages
```

Place your custom `.ipk` files inside. The Image Builder will use them automatically.

### 📁 Including Custom Files

```bash
FILES="files"
```

The `files/` directory should be in the Image Builder root.

#### Best Practice: Use `uci-defaults`

Instead of copying full configs, use scripts in:

```
files/etc/uci-defaults/
```

This avoids conflicts with system-generated settings across versions.