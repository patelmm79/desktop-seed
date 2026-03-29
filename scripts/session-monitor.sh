#!/bin/bash
# Session Monitoring Daemon
# Monitors active RDP/X11 sessions for memory leaks, crashes, and performance issues
# Install as systemd service for continuous monitoring
# Usage: sudo bash scripts/session-monitor.sh [--enable|--disable|--test]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

MONITOR_LOG="/var/log/xrdp/session-monitor.log"
ALERT_LOG="/var/log/xrdp/session-alerts.log"
MEMORY_THRESHOLD=80      # Alert if process uses > 80% of available memory
CPU_THRESHOLD=75         # Alert if process uses > 75% CPU
SESSION_TIMEOUT=3600     # Alert if session runs > 1 hour without activity

# === Monitoring Functions ===

init_logs() {
    mkdir -p /var/log/xrdp
    touch "$MONITOR_LOG" "$ALERT_LOG"
    chmod 644 "$MONITOR_LOG" "$ALERT_LOG"
}

monitor_active_sessions() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo "[$timestamp] === Session Monitor Check ==="

        # Find all Xvnc processes (RDP display servers)
        local xvnc_pids=$(pgrep -f "Xvnc" || true)

        if [ -z "$xvnc_pids" ]; then
            echo "[$timestamp] No active Xvnc sessions"
            return 0
        fi

        while IFS= read -r pid; do
            check_process_health "$pid" "$timestamp"
        done <<< "$xvnc_pids"

    } >> "$MONITOR_LOG" 2>&1
}

check_process_health() {
    local pid=$1
    local timestamp=$2
    local process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
    local display=$(ps -p "$pid" -o args= 2>/dev/null | grep -oE ':[0-9]+' | head -1 || echo "unknown")

    # Get memory stats
    local mem_info=$(ps -p "$pid" -o %mem=,rss= 2>/dev/null || echo "0 0")
    local mem_percent=$(echo "$mem_info" | awk '{print $1}')
    local mem_kb=$(echo "$mem_info" | awk '{print $2}')
    local mem_mb=$((mem_kb / 1024))

    # Get CPU usage
    local cpu_percent=$(ps -p "$pid" -o %cpu= 2>/dev/null || echo "0")

    # Get session runtime
    local start_time=$(ps -p "$pid" -o lstart= 2>/dev/null || echo "")

    {
        echo "  [$timestamp] Display $display (PID $pid)"
        echo "    Memory: ${mem_percent}% (${mem_mb}MB), CPU: ${cpu_percent}%"
        echo "    Started: $start_time"
    } >> "$MONITOR_LOG" 2>&1

    # Check memory threshold
    if (( $(echo "$mem_percent > $MEMORY_THRESHOLD" | bc -l) )); then
        alert "HIGH_MEMORY" "Session $display (PID $pid) using ${mem_percent}% memory (${mem_mb}MB)" "$timestamp"
    fi

    # Check CPU threshold
    if (( $(echo "$cpu_percent > $CPU_THRESHOLD" | bc -l) )); then
        alert "HIGH_CPU" "Session $display (PID $pid) using ${cpu_percent}% CPU" "$timestamp"
    fi
}

alert() {
    local alert_type=$1
    local message=$2
    local timestamp=$3

    {
        echo "[$timestamp] [$alert_type] $message"
    } >> "$ALERT_LOG" 2>&1

    # Optional: Send to syslog
    logger -t "xrdp-session-monitor" -p warning "$alert_type: $message"
}

monitor_crash_logs() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check for recent crash indicators in xrdp logs
    if [ -f /var/log/xrdp/xrdp-sesman.log ]; then
        local recent_errors=$(grep -i "error\|crashed\|exit" /var/log/xrdp/xrdp-sesman.log | tail -5 || true)

        if [ -n "$recent_errors" ]; then
            {
                echo "[$timestamp] === Recent xrdp-sesman Errors ==="
                echo "$recent_errors"
            } >> "$ALERT_LOG" 2>&1
        fi
    fi
}

generate_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo ""
        echo "=== Session Monitor Report - $timestamp ==="
        echo ""

        echo "Active Xvnc Sessions:"
        ps aux | grep "[X]vnc" | awk '{print $2, $3"% CPU", $4"% MEM", $11}'

        echo ""
        echo "Memory Usage Summary:"
        free -h

        echo ""
        echo "Disk Usage:"
        df -h /

        echo ""
        echo "Recent Alerts:"
        tail -10 "$ALERT_LOG" 2>/dev/null || echo "  (none)"

    } >> "$MONITOR_LOG" 2>&1
}

# === Systemd Service Installation ===

install_service() {
    log_info "Installing session monitor service..."

    # Ensure directory exists
    mkdir -p /var/lib/xrdp

    # Create monitoring script in a system location
    cat > /usr/local/bin/xrdp-session-monitor << 'SCRIPT_EOF'
#!/bin/bash
set -euo pipefail
source /var/lib/xrdp/session-monitor-config.sh
init_logs
while true; do
    monitor_active_sessions
    monitor_crash_logs
    generate_report
    sleep 30
done
SCRIPT_EOF

    chmod +x /usr/local/bin/xrdp-session-monitor

    # Create systemd service
    cat > /etc/systemd/system/xrdp-session-monitor.service << 'SERVICE_EOF'
[Unit]
Description=XRDP Session Monitor
After=xrdp.service
Requires=xrdp.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/xrdp-session-monitor
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    # Copy monitor config to system location
    cat > /var/lib/xrdp/session-monitor-config.sh << 'CONFIG_EOF'
MONITOR_LOG="/var/log/xrdp/session-monitor.log"
ALERT_LOG="/var/log/xrdp/session-alerts.log"
MEMORY_THRESHOLD=80
CPU_THRESHOLD=75

log_info() { echo "[INFO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_error() { echo "[ERROR] $1"; }

init_logs() {
    mkdir -p /var/log/xrdp
    touch "$MONITOR_LOG" "$ALERT_LOG"
    chmod 644 "$MONITOR_LOG" "$ALERT_LOG"
}

monitor_active_sessions() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    {
        echo "[$timestamp] === Session Monitor Check ==="
        local xvnc_pids=$(pgrep -f "Xvnc" || true)
        if [ -z "$xvnc_pids" ]; then
            echo "[$timestamp] No active Xvnc sessions"
            return 0
        fi
        while IFS= read -r pid; do
            local mem_info=$(ps -p "$pid" -o %mem=,rss= 2>/dev/null || echo "0 0")
            local mem_percent=$(echo "$mem_info" | awk '{print $1}')
            local mem_kb=$(echo "$mem_info" | awk '{print $2}')
            local mem_mb=$((mem_kb / 1024))
            local cpu_percent=$(ps -p "$pid" -o %cpu= 2>/dev/null || echo "0")
            echo "  [PID $pid] Memory: ${mem_percent}%, ${mem_mb}MB | CPU: ${cpu_percent}%"
        done <<< "$xvnc_pids"
    } >> "$MONITOR_LOG" 2>&1
}

monitor_crash_logs() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ -f /var/log/xrdp/xrdp-sesman.log ]; then
        local recent_errors=$(grep -i "error\|crashed\|exit" /var/log/xrdp/xrdp-sesman.log 2>/dev/null | tail -5 || true)
        if [ -n "$recent_errors" ]; then
            {
                echo "[$timestamp] === Recent Errors ==="
                echo "$recent_errors"
            } >> "$ALERT_LOG" 2>&1
        fi
    fi
}

generate_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    {
        echo ""
        echo "=== Session Report - $timestamp ==="
        echo "Active sessions:"
        ps aux | grep "[X]vnc" | wc -l
        echo "Memory: $(free -h | awk 'NR==2 {print $3 " / " $2}')"
    } >> "$MONITOR_LOG" 2>&1
}
CONFIG_EOF

    systemctl daemon-reload
    systemctl enable xrdp-session-monitor.service
    systemctl start xrdp-session-monitor.service

    log_info "Session monitor service installed and started"
    echo "  Service: xrdp-session-monitor.service"
    echo "  Monitor log: $MONITOR_LOG"
    echo "  Alert log: $ALERT_LOG"
}

uninstall_service() {
    log_info "Removing session monitor service..."

    systemctl stop xrdp-session-monitor.service 2>/dev/null || true
    systemctl disable xrdp-session-monitor.service 2>/dev/null || true

    rm -f /etc/systemd/system/xrdp-session-monitor.service
    rm -f /usr/local/bin/xrdp-session-monitor
    rm -f /var/lib/xrdp/session-monitor-config.sh

    systemctl daemon-reload

    log_info "Session monitor service removed"
}

run_test() {
    log_info "Running session monitor test..."
    init_logs
    monitor_active_sessions
    monitor_crash_logs
    generate_report

    echo ""
    echo "Monitor log (last 20 lines):"
    tail -20 "$MONITOR_LOG"

    echo ""
    echo "Alert log (last 20 lines):"
    tail -20 "$ALERT_LOG"
}

# === Main ===

case "${1:-}" in
    --enable)
        install_service
        ;;
    --disable)
        uninstall_service
        ;;
    --test)
        run_test
        ;;
    *)
        echo "Usage: sudo bash scripts/session-monitor.sh [--enable|--disable|--test]"
        echo ""
        echo "  --enable   Install and start continuous monitoring service"
        echo "  --disable  Remove monitoring service"
        echo "  --test     Run one-time monitoring check"
        exit 1
        ;;
esac
