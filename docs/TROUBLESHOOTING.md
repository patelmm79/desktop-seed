# Troubleshooting Guide

This document captures issues encountered during deployment and how they were resolved.

## Tested On

| Component | Details |
|-----------|---------|
| **Provider** | Hetzner Cloud |
| **Virtualization** | QEMU/KVM |
| **Server Type** | <!-- TODO: Add exact model (e.g., CPX21, CAX21) --> |
| **OS** | Ubuntu 24.04.4 LTS |
| **RAM** | 8 GB |
| **CPU** | 4 vCPU |
| **Test IP** | 204.168.182.32 |
| **Other Providers** | <!-- TODO: Add other providers if tested --> |

## Issues Addressed

### 1. RDP Black Screen (gnome-session crash)

**Symptom:** Connect via RDP, see black screen with movable cursor, then instant disconnect

**Root Cause:** `gnome-session` has compatibility issues with xrdp on Ubuntu 24.04. The session manager crashes silently when invoked via xrdp-sesman.

**Solution:** Start `gnome-shell` directly instead of through `gnome-session`:

```bash
# Instead of: exec /usr/bin/gnome-session --session=ubuntu
exec nohup gnome-shell
```

**File:** `etc/xrdp/startwm.sh`

---

### 2. D-Bus Session Not Initialized

**Symptom:** Desktop components don't communicate, blank blue screen

**Root Cause:** D-Bus session bus not started before GNOME components

**Solution:** Use `dbus-launch` to initialize D-Bus:

```bash
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    eval $(dbus-launch --sh-syntax)
fi
```

---

### 3. Keyring "OS keyring is not available" Errors

**Symptom:** VS Code shows "OS keyring is not available for encryption" errors

**Root Cause:** GNOME keyring daemon needs to start inside D-Bus session context, not before

**Solution:** Start keyring after D-Bus is initialized:

```bash
eval $(gnome-keyring-daemon --start --components=secrets,pkcs11)
```

---

### 4. Profile Script Unbound Variable Errors

**Symptom:** Session exits immediately with code 1, no desktop appears

**Root Cause:** Some Ubuntu profile scripts use `set -u` and reference unbound variables. When combined with `set -euo pipefail` in startwm.sh, the script exits on any unbound variable.

**Solution:** Load profiles with defensive error handling:

```bash
set +u
[ -r /etc/profile ] && . /etc/profile 2>/dev/null || true
[ -r "$HOME/.profile" ] && . "$HOME/.profile" 2>/dev/null || true
set -u
```

---

### 5. GNOME Tries to Use Wayland (Xvnc doesn't support Wayland)

**Symptom:** Session fails to start, X errors in logs

**Root Cause:** By default, GNOME tries to use Wayland display server, but Xvnc only supports X11

**Solution:** Force X11 backend:

```bash
export GDK_BACKEND=x11
export XDG_SESSION_TYPE=x11
export GNOME_SHELL_WAYLANDRESTART=false
```

---

### 6. Profile Not Reapplied After Script Fixes

**Symptom:** Issues persist even after script updates

**Root Cause:** VM wasn't redeployed after script fixes were committed to the repository

**Solution:** Always redeploy after updating deployment scripts:

```bash
scp deploy-desktop.sh user@vm:/tmp/
ssh user@vm
sudo bash /tmp/deploy-desktop.sh
```

---

## Recovery Commands

If RDP breaks after a deployment:

```bash
# Check xrdp status
ssh user@vm "systemctl status xrdp"

# Check session errors
ssh user@vm "tail -30 ~/.xsession-errors"

# Check sesman logs
ssh user@vm "tail -30 /var/log/xrdp-sesman.log"

# Restart xrdp
ssh user@vm "sudo systemctl restart xrdp"

# Quick fix - copy working startwm.sh:
scp etc/xrdp/startwm.sh user@vm:/etc/xrdp/
ssh user@vm "chmod +x /etc/xrdp/startwm.sh && systemctl restart xrdp"
```

---

## Prevention

The deployment script now includes `validate_deployment()` which checks:

- xrdp service is running
- startwm.sh is executable
- GDK_BACKEND=x11 is configured
- dbus-launch is available
- gnome-shell is installed

---

## Known Limitations

- **Wayland not supported** - Uses Xvnc (X11 only), GNOME forced to X11 mode
- **Single-user only** - Designed for desktopuser account
- **No RDP audio** - Sound forwarding not configured
- **Console conflict** - Physical session may conflict with RDP

Run post-deployment validation:

```bash
bash tests/validate-install.sh
```
