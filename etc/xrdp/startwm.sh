#!/bin/bash
# xrdp GNOME session script with Xvnc display server and crash recovery
# This script is called by sesman to start the desktop session

set -euo pipefail

# === Session Information Logging ===
log_session_info() {
    {
        echo "=== Starting GNOME session ==="
        echo "DISPLAY: $DISPLAY"
        echo "PID: $$"
        echo "UID: $(id -u)"
        echo "USER: $(whoami)"
        echo "GDK_BACKEND: ${GDK_BACKEND:-unset}"
        echo "QT_QPA_PLATFORM: ${QT_QPA_PLATFORM:-unset}"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Memory available: $(free -h | awk 'NR==2 {print $7}')"
        echo "CPU count: $(nproc)"
        echo "---"
    } >> ~/.xsession-errors 2>&1
}

# === Crash Logging ===
log_crash_info() {
    {
        echo "[ERROR] Session crashed on $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Exit status: $1"
        echo "Memory snapshot:"
        free -h >> ~/.xsession-errors 2>&1
        echo "Top processes by memory:"
        ps aux --sort=-%mem | head -5 >> ~/.xsession-errors 2>&1
        echo "---"
    } >> ~/.xsession-errors 2>&1
}

trap 'log_crash_info $?' EXIT

# Load user environment
if [ -r /etc/profile ]; then
    . /etc/profile
fi
if [ -r $HOME/.profile ]; then
    . $HOME/.profile
fi

# Wait for X server (Xvnc) to be ready and socket to be available
for i in {1..30}; do
    if [ -S /tmp/.X11-unix/X${DISPLAY#:*.} ]; then
        break
    fi
    sleep 0.5
done

# Ensure DISPLAY is set - sesman should have set it but verify
if [ -z "$DISPLAY" ]; then
    echo "ERROR: DISPLAY not set" >&2
    exit 1
fi

# === Memory Management ===
# Set conservative memory limits to prevent OOM kill
# Prevents GNOME from consuming unlimited memory
ulimit -v 2097152  # ~2GB virtual memory limit per process

# Set up proper environment for GNOME under xrdp
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=GNOME
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# CRITICAL: Force GNOME to use X11 instead of Wayland
# Xvnc only supports X11, not Wayland. These variables must be set BEFORE
# starting gnome-session, otherwise GNOME will try Wayland and fail
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export GNOME_SHELL_WAYLANDRESTART=false

# Disable debug logging by default for performance (enable with G_MESSAGES_DEBUG env var)
export G_MESSAGES_DEBUG="${G_MESSAGES_DEBUG:-}"

# Ensure X authority file exists and is readable
if [ -n "$XAUTHORITY" ] && [ ! -f "$XAUTHORITY" ]; then
    touch "$XAUTHORITY" 2>/dev/null || true
fi

log_session_info

# === D-Bus and Keyring Initialization ===
# dbus-launch will start a new D-Bus session and exec gnome-session into it
# We need to initialize keyring INSIDE that session context
exec dbus-launch --exit-with-session bash -c '
    # At this point, D-Bus session is ready and DBUS_SESSION_BUS_ADDRESS is set

    # Start gnome-keyring-daemon if not already running
    if ! pgrep -u "$UID" gnome-keyring-daemon > /dev/null 2>&1; then
        eval "$(gnome-keyring-daemon --start --components=secrets,pkcs11 2>/dev/null)" || true
    fi

    # Log environment for debugging
    {
        echo "=== D-Bus Session Initialized ==="
        echo "DBUS_SESSION_BUS_ADDRESS: ${DBUS_SESSION_BUS_ADDRESS}"
        echo "GNOME_KEYRING_CONTROL: ${GNOME_KEYRING_CONTROL:-not set}"
        echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-not set}"
    } >> ~/.xsession-errors 2>&1

    # Start GNOME session - it will inherit all environment variables
    exec /usr/bin/gnome-session --session=ubuntu
' 2>> ~/.xsession-errors
