#!/bin/bash
set -euo pipefail

# Remote Linux Desktop Deployment Script
# Deploys: GNOME, xrdp, VS Code, Claude Code, Chromium, OpenRouter
# Target: Ubuntu 20.04/22.04/24.04

SCRIPT_VERSION="1.0.0"
LOG_FILE="/tmp/deploy-desktop-$(date +%Y%m%d-%H%M%S).log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect Ubuntu version
detect_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            log_error "This script only supports Ubuntu, detected: $ID"
            exit 1
        fi
        UBUNTU_VERSION="$VERSION_ID"
        log_info "Detected Ubuntu $UBUNTU_VERSION"

        # Check supported versions
        case "$UBUNTU_VERSION" in
            20.04|22.04|24.04)
                log_info "Ubuntu version $UBUNTU_VERSION is supported"
                ;;
            *)
                log_warn "Ubuntu $UBUNTU_VERSION may not be fully tested"
                ;;
        esac
    else
        log_error "Cannot detect OS version"
        exit 1
    fi
}

# Main function
main() {
    log_info "Starting Remote Desktop Deployment v$SCRIPT_VERSION"
    log_info "Log file: $LOG_FILE"

    check_root
    detect_ubuntu_version

    log_info "System ready for deployment"
}

main "$@"