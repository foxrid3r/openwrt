# 📦 Linksys E8450 (UBI) – Custom Firmware Configuration

This document describes the default configuration and installed components for the custom OpenWrt firmware running on the **Linksys E8450**.

---

## 🖥️ Device Identity

| Setting | Value |
|--------|-------|
| **Hostname** | `Spare1` |
| **LAN IP Address** | `192.168.1.123` |

---

## 🔐 System Access
| Service | Username | Password |
|---------|----------|----------|
| **SSH / LuCI (root)** | `root` | `Admin12345!` |

> ⚠️ **Important:** Change default credentials before deploying on a live network.

---

## 📶 Wireless Configuration

| Setting | Value |
|--------|-------|
| **SSID** | `Spare1` |
| **WiFi Password** | `Admin12345!` |

---

## 🌐 Network & DHCP Configuration

| Setting | Value |
|--------|-------|
| **DHCP Range** | `192.168.1.124 – 192.168.1.128` |

### 🚫 Wired Port DHCP Restrictions

DHCP behavior on the wired LAN ports is controlled using custom nftables rules that are injected *before* the standard OpenWrt firewall rules. This allows DHCP to be explicitly enabled, disabled, or restricted to approved devices without rebooting the router.

**Rule file location:**
```
/usr/share/nftables.d/ruleset-pre/1-dhcp-drop-wired.nft
```

**Affected interfaces:** `lan1`, `lan2`, `lan3`, `lan4`

This design prevents unauthorized or unintended devices from obtaining IP addresses over wired Ethernet ports.

### 🔀 Custom DHCP Operating Modes

The router supports **three custom DHCP operating modes** on wired LAN ports.  
These modes can be switched **dynamically at runtime** without rebooting the router.

> **Default mode:** `COGNEX_ON`

| Mode | Description |
|------|-------------|
| **ON** | **Normal operation.** No DHCP filtering is applied to wired ports. |
| **OFF** | **DHCP fully disabled** on all wired ports. Both client → server (UDP 67) and server → client DHCP traffic is dropped. |
| **COGNEX_ON *(default)*** | **Restricted DHCP mode.** DHCP is allowed **only** for Cognex devices, identified by MAC OUI `00:d0:24`. All other DHCP traffic on wired ports is blocked. |

This allows precise control of wired DHCP behavior for commissioning, debugging,
and secure production operation.

### 🛠 Changing the DHCP Mode

The DHCP mode can be changed using:
```
dhcp-mode ON
dhcp-mode OFF
dhcp-mode COGNEX_ON
```


### 🔧 DHCP Range Configuration

The firmware includes a custom utility named **`set-dhcp-range`** for configuring the DHCP address pool. Unlike the standard OpenWrt configuration, this tool supports both traditional **consecutive** address pools and **fragmented** pools consisting of multiple independent ranges.

Using the utility automatically updates the underlying `dnsmasq` configuration and applies the required changes without manually editing UCI configuration files.

#### Consecutive DHCP Pool

A consecutive pool allocates addresses from one continuous block.

```sh
set-dhcp-range 192.168.1.100-192.168.1.150
```

Result:

```
192.168.1.100
          │
          ├──────────── DHCP Pool ────────────┤
                                              │
                                   192.168.1.150
```

#### Fragmented DHCP Pool

Multiple ranges may be specified to create fragmented address pools.

```sh
set-dhcp-range \
    192.168.1.59-192.168.1.60 \
    192.168.1.178-192.168.1.179
```

This allows static IP devices to occupy the unused portions of the subnet while still making the remaining addresses available through DHCP.

This capability is particularly useful on industrial automation networks where PLCs, HMIs, cameras, robots, and infrastructure devices frequently require fixed IP addresses while temporary devices such as laptops or replacement hardware still require dynamic addressing.


---

## 🕒 Time Synchronization (NTP)

The router maintains accurate system time and also serves as the **local time source** for devices on the automation network.

---

### 🌍 Upstream Time Source (NTP Client)

To keep the production LAN isolated from the internet, the router synchronizes time using a **separate wireless connection**.

| Setting | Value |
|--------|-------|
| **NTP Client** | Enabled |
| **Internet Source** | WiFi via `radio0` |
| **Connected Network** | Isolated **guest** WiFi network |
| **Purpose** | Obtain accurate time from internet NTP servers |

#### 🔒 Network Isolation

- The `radio0` interface connects to a **guest WiFi network with internet access**
- This interface is placed in an **isolated firewall zone**
- **No routing is allowed between the guest network and the LAN**
- The connection exists **only to allow time synchronization**

This ensures accurate system time without exposing the automation LAN to external traffic.

---

### 🏠 Local Time Distribution (NTP Server)

The router also acts as an **NTP server** for devices on the local network.

| Setting | Value |
|--------|-------|
| **NTP Server** | Enabled |
| **Serves Time To** | LAN devices (PLCs, cameras, PCs, etc.) |
| **Time Source** | Router system clock (kept accurate via upstream NTP client) |

#### 📡 Why This Matters

- Industrial devices often require a **stable local time source**
- Ensures **consistent timestamps** across logs, images, inspections, and PLC events
- Allows all equipment to stay synchronized **even if the guest WiFi loses internet access temporarily**

During the Debug phase, devices on the LAN can be configured to use:

```
192.168.1.123
```

as their primary NTP server, where `192.168.1.123` is the router's IP address.

---

## 📁 FTP Server Configuration

An FTP server is enabled for file transfer via USB storage.

| Setting | Value |
|--------|-------|
| **FTP Service** | Enabled |
| **Username** | `admin` |
| **Password** | `admin` |
| **User Access** | Jailed (restricted) to USB storage |

### 💾 USB Drive Requirements

The FTP user is restricted to a directory on the USB drive:

```
/FTP
```

- The folder **must be named `FTP`**  
- It must exist at the **root of the USB drive**

If the folder is missing, FTP access will not function correctly.

---

## 📦 Installed Packages

The following OpenWrt packages are preinstalled:

### 🧠 Core Utilities
- `nano` – Text editor  
- `gdisk` – Disk partitioning tool  
- `usbutils` – USB device utilities  
- `libblkid` – Block device identification library  

### 💾 Storage & Filesystems
- `block-mount` – Mounting block devices  
- `exfat-fsck` – exFAT filesystem repair utility  
- `kmod-fs-exfat` – exFAT filesystem support  
- `kmod-usb-storage` – USB mass storage support  
- `kmod-usb-storage-uas` – USB Attached SCSI support  
- `kmod-usb3` – USB 3.0 support  

### 🌐 Networking & Firewall
- `nftables` – Modern firewall framework  
- `kmod-nft-bridge` – Bridge filtering support for nftables  

### 📡 Services
- `vsftpd` – FTP server  
- `luci` – Web-based OpenWrt management interface  

---

## 🛠️ Custom Utilities 
- `provision-router` – Interactive tool to configure project-specific router settings
- `dhcp-mode` – Change wired DHCP operating mode (ON / OFF / COGNEX_ON)
- `usb-eject` - Safely unmount and eject a USB drive 
- `set-dhcp-range` - Set consecutive or fragmented DHCP pool 

---

## 📝 Notes

- This firmware is tailored for **controlled industrial or lab environments**  
- Wired DHCP restrictions are designed to limit network access to **specific vision devices**
- Time synchronization is intentionally isolated from the production LAN
- Always verify USB storage is connected and properly formatted before using FTP

---
