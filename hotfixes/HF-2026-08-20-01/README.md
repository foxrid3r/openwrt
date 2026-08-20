# HF-2026-08-20-01: Restore NTP Uplink Routing

This hotfix restores the DHCP-provided default route on `ntp_uplink` and
removes the two obsolete static `/32` NTP routes. The NTP-only restriction
continues to be enforced by the firewall.

The fix corresponds to source commit
`e20632715cd41175faca15d42e7233b9240ff9bb` and targets custom image **v1.6.6**.
The application script refuses to run on any other custom-image version. The
target image contains all of the following:

- A DHCP interface named `ntp_uplink`
- `network.ntp_uplink.defaultroute='0'`
- Static routes for `129.6.15.28/32` and `132.163.96.1/32` through `ntp_uplink`

The script validates the interface before making changes. It finds routes by
interface and target instead of assuming that `@route[0]` and `@route[1]` are
the NTP routes, so unrelated routes are not removed. Running the script again
after a successful application does nothing.

It also makes the installed hotfix visible to operators in two places:

- The SSH login banner shows the hotfix ID and description.
- **LuCI → Status → Overview → System** shows an **Applied Hotfixes** row.

Hotfix state is stored separately from the immutable image identity in
`/etc/custom-hotfixes.json`. The displayed image version remains `1.6.6`.

## Install

Download `HF-2026-08-20-01.tar.gz` and
`HF-2026-08-20-01.tar.gz.sha256` from the GitHub release, then copy both to the
router:

```sh
scp -O HF-2026-08-20-01* root@<router-ip>:/tmp/
ssh root@<router-ip>
```

On the router, verify and apply it:

```sh
cd /tmp
sha256sum -c HF-2026-08-20-01.tar.gz.sha256
tar -xzf HF-2026-08-20-01.tar.gz
cd HF-2026-08-20-01
chmod 0755 apply.sh
chmod 0755 rollback.sh
./apply.sh
```

The script saves the original network configuration at:

```text
/etc/custom-hotfixes/backups/HF-2026-08-20-01/network.uci
```

It records successful application at:

```text
/etc/custom-hotfixes/HF-2026-08-20-01
```

Machine-readable display metadata is written to:

```text
/etc/custom-hotfixes.json
```

## Verify

Allow DHCP a few seconds to restore the interface, then run:

```sh
ifstatus ntp_uplink
ip route get 129.6.15.28
ip route get 132.163.96.1
logread | grep -i ntp
```

Both route lookups should select the DHCP gateway on `ntp_uplink`. General
Internet access must remain blocked by the normal NTP-only firewall policy.
Log out and start a new SSH session to check the banner. In LuCI, open
**Status → Overview** and confirm the **Applied Hotfixes** row. Hard-refresh the
page if the browser has cached the previous JavaScript.

## Roll back

Rollback replaces the complete `network` UCI package with the saved pre-hotfix
copy and restores the previous banner, LuCI view, ACL, and hotfix metadata.
Review the network backup first if the router's configuration has changed since
applying the hotfix, then run:

```sh
cd /tmp/HF-2026-08-20-01
./rollback.sh
```