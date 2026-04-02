#!/bin/bash
# Aggressive Session Cleanup Script
# Kills orphaned processes from old sessions while preserving the active session
# Usage: sudo bash scripts/cleanup-sessions.sh [--dry-run]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_kill() { echo -e "${RED}[KILL]${NC} $1"; }

DRY_RUN=false
# Always run for real when called from desktop launcher (user won't see output anyway)
# Use --dry-run flag for testing
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    log_info "Dry run mode - no processes will be killed"
fi

echo "=== Session Cleanup - $(date) ==="

# Get all Xvnc sessions with their start times
ALL_XVNC=$(ps aux | grep '[X]vnc' | grep -v grep)

echo "All Xvnc sessions:"
echo "$ALL_XVNC" | awk '{print $2, $11, $9}'
echo ""

# Find the MOST RECENT session (highest PID = most recently started)
LATEST_XVNC=$(echo "$ALL_XVNC" | awk '{print $2}' | sort -n | tail -1)
echo "Preserving latest session: PID $LATEST_XVNC"
echo ""

# Get session ID from the most recent Xvnc process
SESSION_ID=$(ps -o sid= -p "$LATEST_XVNC" 2>/dev/null | tr -d ' ')
ACTIVE_PIDS=""

if [ -n "$SESSION_ID" ]; then
    # Get all PIDs in this session
    ACTIVE_PIDS=$(ps -e -o pid= -o sid= 2>/dev/null | awk -v sid="$SESSION_ID" '$2 == sid {print $1}')
fi

log_info "Active session PIDs count: $(echo $ACTIVE_PIDS | wc -w)"
echo ""

# Count kills
KILL_COUNT=0
SKIP_COUNT=0

# Target process patterns (these are always orphaned when not in active session)
ORPHAN_PATTERNS=(
    "xrdp-chansrv"
    "pw-cli.*xrdp"
    "gnome-shell"
    "code"
    "chrome"
    "Xvnc"
)

for pattern in "${ORPHAN_PATTERNS[@]}"; do
    for pid in $(pgrep -f "$pattern" 2>/dev/null || true); do
        # Check if this PID is in our active session
        if echo "$ACTIVE_PIDS" | grep -qw "$pid"; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi

        # Get process info
        PROC_INFO=$(ps -o comm= -p "$pid" 2>/dev/null || echo "unknown")
        START_TIME=$(ps -o lstart= -p "$pid" 2>/dev/null | cut -d' ' -f1-4 || echo "unknown")

        log_kill "Killing $PROC_INFO (PID $pid, started $START_TIME)"

        if [ "$DRY_RUN" = false ]; then
            kill "$pid" 2>/dev/null || true
        fi

        KILL_COUNT=$((KILL_COUNT + 1))
    done
done

echo ""
echo "=== Summary ==="
log_info "Processes preserved (in active session): $SKIP_COUNT"
log_info "Processes killed: $KILL_COUNT"

if [ "$DRY_RUN" = true ]; then
    echo ""
    log_warn "Dry run complete - run without --dry-run to apply changes"
fi

# Show memory after
echo ""
echo "Memory after cleanup:"
free -h
