# Out-of-band Management Troubleshooting

**Category:** Hardware

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Cannot reach iDRAC/iLO/IPMI | Wrong IP, management port not plugged, VLAN mismatch | Check management NIC link, IP config, switch VLAN |
| Login fails | Default credentials changed, account locked, LDAP down | Reset via host, use local account, check LDAP/AD |
| Cannot launch virtual console | Java/HTML5 viewer blocked, port blocked (5900/5901/443) | Open firewall, update browser/JRE, use integrated viewer |
| Cannot mount virtual media | Virtual media service disabled, license missing | Enable virtual media in BMC, check license, correct user privs |
| BMC unresponsive / hung | BMC firmware stuck, watchdog failed | BMC cold reset (power cycle BMC only, host stays on), firmware update |
| Cannot power on/off host | BMC host power control broken, host in deep sleep | BMC chassis power cycle, check PSU, physical power button |
| Sensor readings missing/stale | BMC sensor poll issue, firmware bug | BMC firmware update, `ipmitool sensor rearm` |
| Cannot access after firmware upgrade | Incompatible viewer/credentials, certificate mismatch | Clear browser cache, accept self-signed cert, reset BMC to factory |

## Diagnosis

```bash
# Check if ipmitool available
which ipmitool || echo "ipmitool not installed"

# BMC info (local, via /dev/ipmi0 or /dev/ipmi/0)
ipmitool mc info
ipmitool mc watchdog status

# Sensor readings
ipmitool sensor
ipmitool sensor list | grep -iE 'temp|fan|psu|voltage'

# SEL (System Event Log)
ipmitool sel list
ipmitool sel clear   # destructive, only after reviewing

# Chassis power status
ipmitool chassis status
ipmitool chassis power status

# BMC network config
ipmitool lan print 1
ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr <ip>
ipmitool lan set 1 netmask <mask>
ipmitool lan set 1 defgw ipaddr <gw>

# User management
ipmitool user list 1
ipmitool user set name 2 <username>
ipmitool user set password 2 <password>
ipmitool user priv 2 4 1     # admin privilege on channel 1

# BMC reset (cold reset - host stays powered on)
ipmitool mc reset cold
```

## Vendor-specific

| Vendor | Tool | Web UI port | Notes |
|--------|------|-------------|-------|
| Dell iDRAC | `racadm` (or `omconfig`) | 443 | `racadm config`, `racadm reset` |
| HPE iLO | `hponcfg`, `hpilo` | 443 | iLO 4/5; XML config via hponcfg |
| Supermicro IPMI | `ipmitool` | 443/80 | Standard IPMI 2.0 |
| Lenovo XClarity | `lxca` | 443 | XClarity Controller |

## Dell iDRAC deep dive

```bash
racadm config -g cfgServerInfo -o cfgServerFirstBootDevice 1    # boot once to CD
racadm config -g cfgServerInfo -o cfgServerPowerCycle 1          # power cycle
racadm getsensorinfo
racadm getconfig -g cfgServerInfo
racadm reset -d 1        # cold reset iDRAC
racadm racreset          # warm reset iDRAC
racadm factoryreset      # factory default iDRAC (careful)
```

## HPE iLO deep dive

```bash
hponcfg -g                    # get config
hponcfg -f iloconfig.xml      # set config via XML
hponcfg -w iloconfig.xml      # write config to file
```

## Verification

```bash
#!/bin/bash
set -u
echo "== ipmitool =="; which ipmitool >/dev/null 2>&1 && echo installed || echo not-installed
echo "== bmc =="; ipmitool mc info 2>&1 | head -5 || true
echo "== chassis =="; ipmitool chassis power status 2>&1 || true
echo "== sensors =="; ipmitool sensor 2>&1 | grep -iE 'crit|fail|unc|nr' | head -5 || true
echo OK
```

## Safety

- BMC cold reset (`ipmitool mc reset cold`) does NOT power off the host; only restarts the management controller.
- `ipmitool sel clear` deletes the event log; review first with `ipmitool sel list`.
- Changing BMC network/IP can lock you out remotely; have physical access or KVM ready.
- Factory reset erases users, certs, network config; reconfigure after.

---
<ponytail: Scope ceiling — iDRAC/iLO/IPMI out-of-band only; add XClarity, OpenBMC, and Redfish API when those are used.</ponytail>