# 🕒 OpenWRT NTP Setup Using a Secondary WiFi Radio  
### (Internet Time Sync While Keeping the Machine Network Isolated)

This guide walks through configuring an OpenWRT router to obtain accurate internet time (NTP) using a **second WiFi radio**, while keeping your primary machine/PLC network fully isolated.

This is ideal for production networks that must remain air-gapped but still require accurate timestamps for logging, vision systems, or PLC diagnostics.

---

# 📡 Step 1 — Connect the Second Radio to an Internet WiFi Network

1. Navigate to **Network → Wireless**
2. On the unused radio, click **Scan**
3. Select a WiFi network that has internet access
4. Click **Join Network**
5. Set:
   - **Mode:** `Client`
6. When prompted for an interface:
   - Choose **Create new interface**
   - Name it: `wwan_guest`
7. Click **Save & Apply**

At this point, the router can associate to the internet WiFi network.

---

# 🌐 Step 2 — Configure the Guest WiFi Interface

1. Go to **Network → Interfaces**
2. Click **Edit** on `wwan_guest`
3. Open the **Advanced Settings** tab
4. Configure:

   - ✅ **Use default gateway**
   - ❌ **Use DNS servers advertised by peer**
   - **Gateway metric:** `50`

5. Click **Save & Apply**

### Why this matters
The gateway metric ensures this interface is **not preferred over your primary network**, but still usable for outbound traffic like NTP.

---

# 🔥 Step 3 — Firewall Isolation (Critical)

We must ensure zero crossover between networks.

1. Go to **Network → Firewall**
2. Click **Add** to create a new zone
3. Configure:

   - **Name:** `guestwan`
   - **Input:** `REJECT`
   - **Output:** `ACCEPT`
   - **Forward:** `REJECT`
   - ❌ **Masquerading:** unchecked
   - ❌ **MSS Clamping:** unchecked

4. Add network:
   - `wwan_guest`

5. Click **Save & Apply**

⚠ **Important:**  
Do NOT create forwarding rules between `lan` and `guestwan` in either direction.

This guarantees:

- No machine → internet access
- No internet → machine access
- Complete network isolation

---

# 🕒 Step 4 — Configure Time Synchronization (NTP)

1. Go to **System → System**
2. Open the **Time Synchronization** tab
3. Enable:

   - ✅ **Enable NTP client**
   - ✅ **Provide NTP server**

4. Add these NTP servers (IP addresses only):

```
129.6.15.28   (NIST – Maryland)
132.163.96.1  (NIST – Colorado)
```

5. Click **Save & Apply**

### Why use IP addresses?
This avoids requiring DNS access on the guest interface.

---

# 🛣 Step 5 — Add Static Routes for NTP Traffic Only

We now restrict traffic on `wwan_guest` to only the NTP servers.

1. Go to **Network → Routing**
2. Select the **Static IPv4 Routes** tab
3. Click **Add** and create:

| Target | Interface | Gateway |
|--------|-----------|----------|
| `129.6.15.28/32` | `wwan_guest` | (leave blank) |
| `132.163.96.1/32` | `wwan_guest` | (leave blank) |

4. Click **Save & Apply**

This forces only those two NTP destinations out the secondary radio.

---

# ✅ Final Result

Your system now behaves as follows:

- ✔ Router receives accurate internet time  
- ✔ Machine / PLC network remains completely isolated  
- ✔ No traffic passes between guest WiFi and LAN  
- ✔ Only NTP traffic uses the secondary WiFi  

---

# 🧪 Optional Verification (CLI)

You can verify routing and NTP operation:

```bash
ip route
logread | grep ntp
ntpq -p
```

You should see:

- Routes to the two NTP IPs via `wwan_guest`
- Successful NTP sync messages in logs
