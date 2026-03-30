# Remote Linux Desktop Deployment

A complete automation script for deploying a full Linux desktop environment on a remote Ubuntu server. Includes RDP access, VS Code, Claude Code, and comprehensive crash recovery and monitoring.

**Status:** Production-ready with automatic crash detection, secure credential storage, and continuous monitoring.

## What This Does

Deploys a complete development environment with:

- **GNOME Desktop** - Touch-friendly, tablet-optimized interface
- **RDP Server (xrdp)** - Remote Desktop access from Windows/Android
- **VS Code** - Code editor with extensions
- **Claude Code** - AI assistant integrated in terminal
- **OpenRouter CLI** - Access to multiple AI models
- **Chromium Browser** - Full-featured web browser
- **Cascade Windows Extension** - Window arrangement tool
- **GNOME Keyring** - Secure credential storage
- **Session Monitoring** - Automatic crash detection (30 sec response time)
- **Memory Management** - Per-process limits prevent OOM crashes

## Quick Start

### Prerequisites

- Ubuntu server 20.04+ (2+ CPU, 4+ GB RAM recommended)
- SSH access to your server
- Your server's IP address

### Deploy in 3 Steps

```bash
# 1. Clone this repository
git clone https://github.com/patelmm79/desktop-seed.git
cd desktop-seed

# 2. Upload script to server
scp deploy-desktop.sh user@your-server-ip:/tmp/

# 3. Run on server
ssh user@your-server-ip
sudo bash /tmp/deploy-desktop.sh

# 4. Set API key (needed for Claude Code)
export OPENROUTER_API_KEY="your_api_key_here"
```

Wait 5-15 minutes for installation to complete.

## Post-Installation

### Connect via RDP

1. Open **Microsoft Remote Desktop** on Windows/Android
2. Enter your server's IP address and port **3389**
3. Login with your Ubuntu username/password
4. Desktop loads with all tools pre-configured

### First Run

```bash
# Check that everything is running
systemctl status xrdp-session-monitor.service
ps aux | grep gnome-keyring

# View crash logs (if any)
bash scripts/analyze-session-logs.sh --summary
```

## Documentation

Complete guides organized by topic:

### User Guides
- **[Quick Deploy](docs/QUICK-DEPLOY.md)** - 5-minute deployment walkthrough
- **[Usage Guide](docs/usage-guide.md)** - Using VS Code, Claude Code, and tools
- **[SSH Setup](docs/ssh-setup-guide.md)** - Configure SSH from Windows

### Technical Guides
- **[Crash Recovery](docs/crash-recovery-guide.md)** - How crash detection works
- **[Keyring Setup](docs/keyring-guide.md)** - Secure credential storage
- **[Monitoring Reference](docs/README_MONITORING.md)** - Session monitoring details

### Implementation Details
- **[Deployment Summary](docs/DEPLOYMENT_SUMMARY.md)** - What gets installed where
- **[Integration Guide](docs/INTEGRATION_GUIDE.md)** - How components work together
- **[Implementation Details](docs/FINAL_SUMMARY.md)** - Complete technical overview

## Features

### Automatic Crash Detection

```bash
# Check monitor status
systemctl status xrdp-session-monitor.service

# View recent crashes
bash scripts/analyze-session-logs.sh --crashes

# Real-time monitoring
tail -f /var/log/xrdp/session-monitor.log
```

**Performance:**
- Detection time: < 30 seconds
- Full forensic data capture on crash
- Memory and CPU threshold alerts

### Secure Credential Storage

```bash
# Store a credential
secret-tool store --label="MyPassword" app myapp user myuser

# Retrieve it
secret-tool lookup app myapp user myuser

# Python usage
from gi.repository import Secret
Secret.password_store_sync(
    Secret.SCHEMA_COMPAT_NETWORK,
    {"user": "name", "server": "host"},
    Secret.COLLECTION_DEFAULT,
    "label",
    "password"
)
```

### Health Checks

```bash
# One-line health check
bash scripts/analyze-session-logs.sh --summary

# Memory analysis
bash scripts/analyze-session-logs.sh --memory

# Session timeline
bash scripts/analyze-session-logs.sh --timeline
```

## Architecture

### Deployment Components

| Component | Purpose | Version |
|-----------|---------|---------|
| GNOME Desktop | Desktop environment | 3.x+ |
| xrdp | RDP server | 0.9+ |
| VS Code | Code editor | Latest |
| Claude Code | AI assistant | Latest |
| OpenRouter | AI API access | Latest |
| gnome-keyring | Credential storage | 46.1+ |
| Cascade Windows | Window tool | Latest |

### Monitoring Stack

```
startwm.sh (crash logging)
    ↓
xrdp-session-monitor.service (continuous checks)
    ↓
/var/log/xrdp/session-monitor.log (alerts)
    ↓
analyze-session-logs.sh (analysis tools)
```

### Session Flow

```
User connects via RDP
    ↓
startwm.sh initializes session
    ↓
dbus-launch starts D-Bus session
    ↓
gnome-keyring-daemon starts (credentials)
    ↓
gnome-session starts (desktop)
    ↓
Monitor service watches continuously
    ↓
Crash detected → context logged → operator alerted
```

## Configuration

### Memory Limits

Edit `/etc/xrdp/startwm.sh` (line 64):
```bash
ulimit -v 2097152  # Change this value (in KB)
```

### Monitor Thresholds

Edit `/var/lib/xrdp/session-monitor-config.sh`:
```bash
MEMORY_THRESHOLD=80      # Alert when memory reaches 80%
CPU_THRESHOLD=75         # Alert when CPU reaches 75%
```

### Keyring Settings

Located in `~/.local/share/gnome-online-accounts/`
- Auto-unlock on login (via PAM)
- SSH key management
- X.509 certificate support

## Troubleshooting

### Can't Connect via RDP

```bash
# Check xrdp is running
systemctl status xrdp
systemctl status xrdp-sesman

# Check firewall allows port 3389
sudo ufw status
sudo ufw allow 3389

# Restart services
sudo systemctl restart xrdp
```

### Keyring Not Available

```bash
# Check daemon is running
pgrep -af gnome-keyring-daemon

# Check D-Bus session
echo $DBUS_SESSION_BUS_ADDRESS

# Restart keyring
pkill gnome-keyring-daemon
# It will auto-restart on next operation
```

### Monitor Not Running

```bash
# Check status
systemctl status xrdp-session-monitor.service

# View logs
journalctl -u xrdp-session-monitor.service -n 50

# Restart
sudo systemctl restart xrdp-session-monitor.service
```

### High Memory Usage

```bash
# Find memory hogs
ps aux --sort=-%mem | head -10

# View memory trends
bash scripts/analyze-session-logs.sh --memory

# Check monitor logs
tail -100 /var/log/xrdp/session-monitor.log
```

## Common Commands

### Health & Monitoring

```bash
# Quick health check
bash scripts/analyze-session-logs.sh --summary

# Real-time monitor log
tail -f /var/log/xrdp/session-monitor.log

# Real-time alerts
tail -f /var/log/xrdp/session-alerts.log

# Full crash analysis
bash scripts/analyze-session-logs.sh --crashes
```

### Service Management

```bash
# Check RDP service
systemctl status xrdp

# Check monitor service
systemctl status xrdp-session-monitor.service

# Restart xrdp
sudo systemctl restart xrdp

# Restart monitor
sudo systemctl restart xrdp-session-monitor.service

# Enable at boot (usually automatic)
sudo systemctl enable xrdp-session-monitor.service
```

### Session Analysis

```bash
# View last 20 lines of session log
tail -20 /var/log/xrdp-sesman.log

# View crash timestamps
grep "crashed\|EXIT\|signal" /var/log/xrdp-sesman.log

# View complete session history
bash scripts/analyze-session-logs.sh --timeline
```

## Performance Metrics

Typical resource usage after deployment:

- **Idle memory:** 2-3 GB
- **Monitor overhead:** < 1% CPU
- **Storage:** 25-30 GB (depends on installed packages)
- **Network:** ~100 KB/sec over RDP

Crash detection: **< 30 seconds** (automatic)

## Project Structure

```
.
├── deploy-desktop.sh           # Main deployment script
├── config.sh                   # Component configuration
├── tests/
│   └── validate-install.sh     # Post-deployment validation
├── scripts/
│   ├── session-monitor.sh      # Monitoring service
│   └── analyze-session-logs.sh # Analysis tools
├── etc/xrdp/
│   └── startwm.sh              # Enhanced session startup
├── docs/                       # Complete documentation
│   ├── QUICK-DEPLOY.md
│   ├── crash-recovery-guide.md
│   ├── keyring-guide.md
│   ├── usage-guide.md
│   ├── ssh-setup-guide.md
│   ├── DEPLOYMENT_SUMMARY.md
│   ├── INTEGRATION_GUIDE.md
│   ├── FINAL_SUMMARY.md
│   ├── README_MONITORING.md
│   └── DEPLOYMENT-GUIDE.md
├── README.md                   # This file
└── CLAUDE.md                   # Developer instructions
```

## Development

### Running Validation Tests

After deployment, verify everything works:

```bash
sudo bash tests/validate-install.sh
```

This checks:
- All required components installed
- Services running
- Configuration correct
- Network connectivity
- Storage space available

### Contributing

Improvements welcome! Areas for enhancement:
- Additional GNOME extensions
- Performance optimizations
- Security hardening
- Documentation improvements

Follow existing patterns:
- Use bash for scripts
- Add error handling with `set -euo pipefail`
- Document new functions
- Update CLAUDE.md with changes

## Support & Resources

### Documentation

- **Quick questions?** Start with [QUICK-DEPLOY.md](docs/QUICK-DEPLOY.md)
- **Setup issues?** See [Troubleshooting](#troubleshooting)
- **Technical details?** Read [INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md)
- **Crash problems?** Check [crash-recovery-guide.md](docs/crash-recovery-guide.md)

### Important Files

- **Deployment log:** `/tmp/deploy-desktop-*.log`
- **Session log:** `/var/log/xrdp-sesman.log`
- **Monitor log:** `/var/log/xrdp/session-monitor.log`
- **Alerts:** `/var/log/xrdp/session-alerts.log`
- **Session errors:** `~/.xsession-errors`

## Git History

Major milestones:

```
d6d6e06 feat: add Cascade Windows GNOME extension
04f48c9 fix: ensure keyring daemon inherits dbus-launch context
c5a7ca9 feat: add enhanced debugging to startwm.sh
... (see git log for complete history)
```

## License

This project is provided as-is for deployment and development use.

## Status

✅ **Production Ready**
- Tested on Ubuntu 20.04, 22.04, 24.04
- Automatic crash detection confirmed working
- All components deployed and verified
- Continuous monitoring active
- Secure credential storage operational

**Latest Update:** March 30, 2026
- Added Cascade Windows GNOME extension
- Fixed keyring daemon initialization
- Organized documentation
- Comprehensive README
