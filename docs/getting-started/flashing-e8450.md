# Flashing OpenWrt on the Linksys E8450

This guide covers two different starting points. Choose the one that matches the router now:

| Current state | Follow |
|---|---|
| Stock Linksys firmware | [Run the one-time installer, then choose stock OpenWrt or the custom image](#first-time-openwrt-installation) |
| Compatible OpenWrt UBI installation | [Custom image installation](#custom-image-installation) |

> [!IMPORTANT]
> The E8450 installation and migration requirements can change. Before flashing, compare this guide with the current [OpenWrt device page](https://openwrt.org/toh/linksys/e8450) and [official UBI installer documentation](https://github.com/dangowrt/owrt-ubi-installer). Those upstream sources take precedence for installer choice and layout migrations.
  
> [!CAUTION]
> Do not use installer v1.0.3. Select the current installer release recommended by the upstream UBI installer project; do not rely on a version number copied from an older guide. The installer changes the bootloader and flash layout and normally must be run only once per device.
  
# First-time OpenWrt installation

1. Factory Reset the router by holding down the reset button until the Power LED indicator starts blinking. Wait for the device to reset. If the device is brand new, this step is not required.
  
- **IMPORTANT**: If a device running stock 1.1.x firmware rejects the installer image, the recommended work-around is to downgrade the device to version 1.0.x, and then re-attempt uploading the installer image. See "Downgrading Firmware" instructions below.
  
- **IMPORTANT**: Execute these steps on a brand new device running stock firmware ...or... just after performing a factory reset on the device.
  
2. Connect any of the LAN ports of the device directly to the Ethernet port of your computer.
  
3. Set the IP address of your computer as 192.168.1.254 with netmask 255.255.255.0, no gateway, no DNS.
  
4. Power on the device, wait about a minute for it to be ready.
  
5. Open a web browser, navigate to http://192.168.1.1 and wait for the wizard to come up.
  
6. Click exactly inside the radio button to confirm the terms and conditions, then abort the wizard. (Complete the wizard if you are running stock firmware version 1.2.x)
  
    ![Linksys setup wizard terms and conditions](../screenshots/linksys-e8450-stock-setup-terms.png)
  
7. You should then be greeted by the login screen; the stock password is "admin".
  
    ![Linksys stock firmware login](../screenshots/linksys-e8450-stock-login.png)
  
8. If the firmware on the device is >= 1.2.00, then you will have to go through the process of setting to WAN on the device before proceeding.
  
    ![Linksys stock firmware Wi-Fi settings](../screenshots/linksys-e8450-stock-wifi-settings.png)
  
    `Set temporary password`
  
    ![Linksys stock firmware router password](../screenshots/linksys-e8450-stock-router-password.png)
  
    `Next`
  
    ![Linksys stock firmware setup summary](../screenshots/linksys-e8450-stock-setup-summary.png)
  
    `No, I’m done.`
  
    ![Linksys add another node prompt](../screenshots/linksys-e8450-stock-add-node-prompt.png)
  
    `Skip`
  
    ![Linksys product registration](../screenshots/linksys-e8450-stock-product-registration.png)
  
    `Next`
  
    ![Linksys automatic updates setting](../screenshots/linksys-e8450-stock-automatic-updates.png)
  
    `Make note of the factory firmware version. Done.`
  
    ![Linksys setup complete screen](../screenshots/linksys-e8450-stock-setup-complete.png)
  
    `Done`
  
    ![Linksys setup finished](../screenshots/linksys-e8450-stock-setup-finished.png)
  
9. Navigate to `Administration -> Firmware Upgrade`.

    ![Linksys stock firmware upgrade page](../screenshots/linksys-e8450-stock-firmware-upgrade.png)
  
10. Upload the firmware **installer** image. This one-time installer converts the router's NAND flash layout to UBI and starts the OpenWrt recovery environment. It is not the final OpenWrt firmware image.
  
    - If running stock **firmware < 1.2.00.273012**, upload the **unsigned** image: `openwrt-...-mediatek-mt7622-linksys_e8450-ubi-initramfs-recovery-installer.itb`
  
    - Otherwise, when stock **firmware is >= 1.2.00.273012**, upload the **signed** image: `openwrt-...-mediatek-mt7622-linksys_e8450-ubi-initramfs-recovery-installer_signed.itb`
  
        ![Select the OpenWrt installer image](../screenshots/linksys-e8450-select-installer-image.png)

        ![OpenWrt installer upload in progress](../screenshots/linksys-e8450-installer-upload-progress.png)
  
11. Wait for a minute, the OpenWrt recovery image should come up.

    ![OpenWrt recovery login](../screenshots/linksys-e8450-openwrt-recovery-login.png)
  
12. Login as `root` user. By default, there is no password.
  
13. Navigate to `System -> Backup / Flash Firmware`.

    ![OpenWrt Backup and Flash Firmware page](../screenshots/linksys-e8450-openwrt-flash-firmware.png)
  
14. Choose and upload one of the following E8450 UBI sysupgrade images:

    At this stage, the installer has finished its job and the router is ready for its final firmware. If you want the custom image, you may install it directly; installing official OpenWrt first is not required.

    | Choice | Image |
    |---|---|
    | Official OpenWrt | `openwrt-...-mediatek-mt7622-linksys_e8450-ubi-squashfs-sysupgrade.itb` downloaded from OpenWrt |
    | Custom image | The `linksys_e8450-ubi-squashfs-sysupgrade.itb` artifact provided by this project |

    Use only an image built for the Linksys E8450 UBI profile. The screenshots show an official OpenWrt image, but the upload workflow is the same for the custom image.

    ![OpenWrt flash image dialog](../screenshots/linksys-e8450-openwrt-flash-image-dialog.png)

    ![Select the OpenWrt sysupgrade image](../screenshots/linksys-e8450-select-sysupgrade-image.png)

    ![OpenWrt sysupgrade upload in progress](../screenshots/linksys-e8450-sysupgrade-upload-progress.png)

    ![OpenWrt flash image confirmation](../screenshots/linksys-e8450-flash-image-confirmation.png)
  
15. Do not retain any settings.

    ![Disable the keep settings option](../screenshots/linksys-e8450-disable-keep-settings.png)
  
16. The device will reboot. Continue immediately with the stock/vendor bootchain backup below.
  
  
## Back up the stock/vendor bootchain
> [!IMPORTANT]
> **DO NOT SKIP THIS STEP**.
> These files are needed in case you want to restore the original/vendor firmware. More importantly, they can also be used in emergency case for reflashing via JTAG.
>
> The boot backup contains low-level flash data required for booting and recovering the router. It may also contain device-specific factory data, including hardware calibration information and identifiers that cannot simply be recreated by reinstalling OpenWrt.
>
> Unlike the OpenWrt firmware and configuration files, some of this data is unique to the individual router. A backup from another Linksys E8450 should not be considered an equivalent replacement.
>
> This backup may be the only practical means of recovering the router if the bootloader, flash layout, or other critical partitions are damaged during flashing or subsequent maintenance.

### Overview

The first installation of OpenWrt on a Linksys E8450 is different from a normal firmware upgrade. The recommended OpenWrt installation process uses a **UBI installer** that restructures the router's NAND flash, installs an OpenWrt-compatible boot chain, and creates the UBI-based flash layout used by subsequent OpenWrt releases.

Because this conversion replaces portions of the original Linksys boot environment, the installer first preserves the existing vendor boot information in a dedicated backup volume on the router.

This backup is an important **device-specific recovery asset** and should be copied off the router immediately after the initial OpenWrt installation and retained permanently.

---

### What Happens During the Initial OpenWrt Installation

A factory Linksys E8450 uses a Linksys-specific NAND flash layout containing the bootloader, firmware, factory data, configuration information, and other partitions.

The OpenWrt UBI installation uses a substantially different flash layout. The initial installation is therefore performed using the one-time recovery installer image:

```text
linksys_e8450-ubi-initramfs-recovery-installer.itb
```

This image is not a normal OpenWrt firmware upgrade. It performs the initial conversion of the router from the factory Linksys flash layout to the OpenWrt UBI layout.

At a high level, the installer performs the following operations:

1. Boots a temporary OpenWrt recovery/installation environment.
2. Reads the existing contents of the router's NAND flash.
3. Preserves the existing vendor boot chain in a backup.
4. Reorganizes the NAND flash for the OpenWrt UBI layout.
5. Installs the OpenWrt-compatible bootloader infrastructure.
6. Creates the UBI volumes used by OpenWrt.
7. Installs the OpenWrt recovery and system images.

The important point is that the backup is created **before the original boot environment is replaced**.

---

### The `boot_backup` UBI Volume

As part of the UBI conversion, the installer creates a dedicated UBI volume named:

```text
boot_backup
```

A typical OpenWrt UBI layout on the E8450 contains volumes such as:

```text
ubi0
├── fip
├── factory
├── ubootenv
├── ubootenv2
├── recovery
├── fit
├── boot_backup
└── rootfs_data
```

The `boot_backup` volume contains the backup made by the installer before it modifies the router's original boot environment.

For a router being converted directly from the factory Linksys firmware, this backup preserves the original vendor boot-chain information needed to help reconstruct the original flash layout if the router ever needs to be returned to the Linksys firmware.

---

### What Is Actually Being Backed Up?

The `boot_backup` volume should not be thought of as simply a copy of the Linksys firmware image.

The factory E8450 NAND contains multiple partitions associated with the boot process and factory firmware layout, including components such as:

```text
Preloader
ATF
Bootloader
Config
Factory
Kernel1
Kernel2
```

The OpenWrt UBI conversion replaces or reorganizes portions of this original layout. The installer therefore saves the relevant original boot-chain contents before performing the conversion.

This makes the backup fundamentally different from downloading a stock Linksys firmware image from the Internet. A stock firmware image alone does not necessarily contain everything required to reconstruct the original boot environment after the UBI conversion.

---

### Why the Backup Is Important

Installing OpenWrt using the UBI installer fundamentally changes how the E8450's NAND flash is organized.

Returning the router to factory Linksys firmware is therefore more involved than simply uploading a Linksys firmware image through LuCI or another web interface.

The original boot information preserved in `boot_backup` can be required as part of the process of reconstructing the original Linksys flash layout and restoring the vendor firmware.

The backup may also be valuable during advanced recovery procedures if the router's boot environment becomes damaged.

For this reason, the contents of `boot_backup` should be treated as a permanent recovery asset associated with that specific router.

---

### Copy the Backup Off the Router

Leaving the backup only on the router does **not** provide adequate protection.

After the initial OpenWrt installation, mount the `boot_backup` volume:

```sh
mkdir /tmp/boot_backup
mount -t ubifs ubi0:boot_backup /tmp/boot_backup
```

The contents can then be inspected with:

```sh
ls -lh /tmp/boot_backup
```

The files should then be copied to another computer or other protected storage, for example using SCP.

The externally stored copy should be clearly associated with the specific physical router from which it was obtained.

> [!IMPORTANT]
>
> Do not assume that a backup obtained from another Linksys E8450 is an acceptable replacement. Treat each router's backup as device-specific and preserve it accordingly.

---

### Do Not Run the UBI Installer Again Unnecessarily

The initial UBI installer is intended primarily for converting the router from the factory Linksys layout to the OpenWrt UBI layout.

The installation sequence is approximately:

```text
Factory Linksys Router
        │
        ▼
Run UBI Installer
        │
        ├──── Preserve original Linksys boot chain
        │                  │
        │                  ▼
        │            UBI: boot_backup
        │
        ├──── Convert NAND to UBI
        │
        ├──── Install OpenWrt boot chain
        │
        ▼
OpenWrt UBI Layout
```

Running the installer again later can replace the contents of `boot_backup`. If the original backup has not already been copied elsewhere, the original factory boot information may therefore be lost.

Consequently, the UBI installer should **not** be treated as the normal method for upgrading an E8450 that has already been converted to the OpenWrt UBI layout.

---

### Normal OpenWrt Upgrades

After the initial UBI conversion has been completed, normal OpenWrt upgrades should use the appropriate sysupgrade image, such as:

```text
linksys_e8450-ubi-squashfs-sysupgrade.itb
```

The UBI recovery installer should only be run again when there is a specific reason to do so, such as when OpenWrt documentation for a particular upgrade explicitly requires an updated installer because of changes to the bootloader or flash layout.

---

### Recommended Backup Policy

The `boot_backup` should be copied off the router **immediately after the initial UBI installation**.

A good installation workflow is:

1. Install the OpenWrt UBI recovery installer.
2. Allow the router to boot into the new OpenWrt environment.
3. Mount the `boot_backup` UBI volume.
4. Copy the complete contents of `boot_backup` to protected external storage.
5. Clearly identify the backup with the specific router it came from.
6. Verify that the copied files are readable and retained in a location that will not be accidentally deleted.
7. Only then continue with normal router provisioning and configuration.

> [!IMPORTANT]
>
> **The `boot_backup` created during the initial OpenWrt UBI installation is a device-specific recovery asset. It preserves the original vendor boot-chain information before OpenWrt replaces the Linksys boot environment. Copy this backup off the router and retain it permanently. Do not rely on the copy stored on the router as the only backup.**

---
  
1. SSH into the router using Putty or terminal. Make a backup of the bootchain as shown below.

    ![Back up the bootchain over SSH](../screenshots/linksys-e8450-backup-bootchain-ssh.png)
  
2. Copy `MTD` files out using scp and and save them in a secure location, indicating which serial number these files belong to. **NOTE**: Since Installer v1.1.x, the boot backups are stored solely in `mtd0` and `mtd1`, so if those are the only 2 files in the **boot_backup** directory, this is expected. The screenshots below was taken during an installation while using v1.0.2 installer which stored the backup in 4 files (`mtd0`, `mtd1`, `mtd2`, & `mtd3`).

    ![Copy the bootchain backup with SCP](../screenshots/linksys-e8450-copy-bootchain-scp.png)


<div style="page-break-after: always;"></div>
  
  
## Custom image installation
A custom firmware image is a version of OpenWrt that has been pre-built with specific packages, configurations, and features already included. Instead of starting with a generic, default system and manually configuring each setting, the image is tailored ahead of time to meet a particular need or application.

This approach is useful because it shifts the work from repetitive manual setup to a one-time, controlled build process. The result is a ready-to-deploy system that behaves predictably across all devices it is installed on.

For end users, this provides several practical advantages:

- ⚙️ Reduced setup time – devices are ready to use immediately after flashing
- 🔁 Consistency – every device runs the same configuration, eliminating variation
- 🧩 Pre-installed features – required tools and services are already included
- 🛠️ Simplified support – standardized systems are easier to troubleshoot and maintain
- 🔒 Controlled environment – only the necessary components are included, reducing complexity and potential issues

In short, a custom image allows systems to be deployed quickly, reliably, and with confidence that they will operate exactly as intended.

The custom image can be selected immediately after the one-time UBI installer in step 14 above. The steps below cover installing it later on a Linksys E8450 that already runs a compatible OpenWrt UBI image.
  
`System > Backup/Flash Firmware`
  
![OpenWrt Backup and Flash Firmware page](../screenshots/linksys-e8450-openwrt-flash-firmware.png)
  
`Flash new firmware image > Flash image…`
  
![OpenWrt flash image dialog](../screenshots/linksys-e8450-openwrt-flash-image-dialog.png)
  
`Browse…`
  
![Select the OpenWrt sysupgrade image](../screenshots/linksys-e8450-select-sysupgrade-image.png)
  
Select the Calvary custom image, `Calvary-openwrt-24.10.5-mediatek-mt7622-linksys_e8450-ubi-squashfs-sysupgrade.itb`
  
![Select the custom sysupgrade image](../screenshots/linksys-e8450-select-custom-sysupgrade-image.png)
  
`Upload`
  
![OpenWrt flash image confirmation](../screenshots/linksys-e8450-flash-image-confirmation.png)
  
`Do not retain any settings. Continue.`
  
![Disable the keep settings option](../screenshots/linksys-e8450-disable-keep-settings.png)


<div style="page-break-after: always;"></div>

# Related Documentation

- [Router Provisioning](provisioning.md)
- [DHCP Modes](../tools/dhcp-mode.md)
- [DHCP Range Configuration](../tools/set-dhcp-range.md)
- [DHCP Lease Reclamation](../tools/dhcp-lease-reclamation.md)
- [FTP Server](../custom-image/ftp-service.md)
- [NTP](../custom-image/ntp-uplink.md)
- [USB Storage](../custom-image/usb-storage.md)
- [Tool Reference](../tools/README.md)
