# Crash Recovery & Session Monitoring Guide

## Overview

This guide explains the enhanced crash recovery and monitoring systems implemented to prevent and diagnose RDP session crashes.

## What Changed

### 1. Enhanced startwm.sh (Session Startup Script)

**Location:** `/etc/xrdp/startwm.sh`

**Improvements:**

- **Memory Limits**: Sets per-process virtual memory limit (~2GB) to prevent GNOME from consuming unlimited memory
- **Crash Logging**: Traps exit signals to log detailed crash information including:
  - Exit code and signal
  - Memory snapshot at time of crash
  - Top 5 memory-consuming processes
  - Timestamp for correlation with system logs

- **Session Logging**: Enhanced startup logging with:
  - Session metadata (DISPLAY, UID, USER)
  - Available system memory
  - CPU count
  - Session initialization status

- **Error Handling**: Uses `set -euo pipefail` for strict error checking

### 2. Session Monitor Service

**Location:** `/usr/local/bin/xrdp-session-monitor` (systemd service)

**How It Works:**

The monitor runs continuously as a background service and checks every 30 seconds for:

- **Memory Usage**: Alerts if any session exceeds 80% of available memory
- **CPU Usage**: Alerts if any session exceeds 75% CPU utilization
- **Crash Detection**: Scans xrdp-sesman logs for recent errors
- **Performance Reports**: Generates periodic snapshots of system state

**Log Files:**

- `/var/log/xrdp/session-monitor.log` — Detailed monitoring checks and reports
- `/var/log/xrdp/session-alerts.log` — Alerts triggered by threshold violations

## Viewing Monitoring Data

### Check Current Status

```bash
# View service status
systemctl status xrdp-session-monitor.service

# View recent monitoring data (real-time)
tail -f /var/log/xrdp/session-monitor.log

# View alerts only
tail -f /var/log/xrdp/session-alerts.log
```

### Generate a Report

```bash
# One-time monitoring check
sudo bash /tmp/session-monitor.sh --test
```

### View Session Crash Information

```bash
# Check .xsession-errors for session start/crash details
sudo -u desktopuser cat ~/.xsession-errors | tail -50

# Check xrdp-sesman log for window manager crashes
tail -100 /var/log/xrdp/xrdp-sesman.log
```

## Understanding the Previous Crash

**When:** 2026-03-29 07:50:04 UTC
**Duration:** ~3 hours
**Exit Signal:** SIGKILL (signal 9)
**Exit Code:** 255

**What Happened:**

1. Session started normally at 04:45:24
2. GNOME session ran for ~3 hours
3. System forcibly terminated the window manager (gnome-session)
4. Possible causes:
   - Memory exhaustion despite available RAM
   - GNOME Shell crash due to a bug
   - Third-party extension/plugin conflict
   - System resource pressure

**Evidence:** The system still had ~3.7GB free memory when it crashed, suggesting the crash was likely due to a memory leak within GNOME itself or a triggering bug rather than system-wide memory exhaustion.

## Prevention Strategies

### Memory Management

The new `ulimit -v 2097152` (2GB per-process limit) in startwm.sh helps by:

- Preventing runaway memory allocation
- Catching memory leaks early before they crash the system
- Allowing other services to remain stable

### Monitoring

The session monitor service helps by:

- **Early Detection**: Catches memory/CPU issues before they cause crashes
- **Historical Records**: Logs all resource usage for post-mortem analysis
- **Alerting**: Notifies through syslog and log files when thresholds are exceeded

## Troubleshooting

### Monitor Service Not Running

```bash
# Check status
systemctl status xrdp-session-monitor.service

# View service logs
journalctl -u xrdp-session-monitor.service -n 50

# Restart service
systemctl restart xrdp-session-monitor.service
```

### No Monitoring Data

```bash
# Check log files exist and are writable
ls -la /var/log/xrdp/

# Run diagnostic test
sudo bash /tmp/session-monitor.sh --test

# Check for xrdp sessions
ps aux | grep Xvnc
```

### High Memory Alerts

If you see frequent high memory alerts:

1. Check what's consuming memory:
   ```bash
   ps aux --sort=-%mem | head -10
   ```

2. Identify the process:
   - GNOME Shell (`gnome-shell`)
   - Window manager (`mutter`)
   - Desktop daemon (`gnome-session`)

3. Possible solutions:
   - Reduce desktop extensions/plugins
   - Disable animations (Settings > Appearance > Animation)
   - Use a lighter desktop environment (XFCE instead of GNOME)
   - Increase server RAM

## Next Steps

To further improve stability:

1. **Monitor for 24-48 hours** and collect baseline memory/CPU data
2. **Identify problematic applications** from monitoring logs
3. **Adjust thresholds** based on your typical workload:
   ```bash
   # Edit these in /var/lib/xrdp/session-monitor-config.sh
   MEMORY_THRESHOLD=80      # Current: 80%
   CPU_THRESHOLD=75         # Current: 75%
   ```

4. **Consider lighter alternatives** if GNOME is consistently high-memory:
   - XFCE Desktop (lighter, still fully featured)
   - Cinnamon Desktop (GNOME-based, lighter)

## Disabling Monitoring

If you need to disable the monitoring service:

```bash
sudo bash /tmp/session-monitor.sh --disable
```

This will:
- Stop the background service
- Remove systemd service files
- Keep historical logs intact

## References

- xrdp Documentation: http://www.xrdp.org/
- GNOME Session Management: https://wiki.gnome.org/Projects/GnomeSession
- Linux ulimit: `man bash` (search for "ulimit")
