#!/bin/bash
# Deploy GitHub repository to VM and notify Discord
# Usage: ./deploy-repo-to-vm.sh <repo> [branch]
# Example: ./deploy-repo-to-vm.sh patelmm79/dev-nexus-action-agent main

set -euo pipefail

REPO="${1:-}"
BRANCH="${2:-main}"
DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID:-1491175562348331209}"

# Logging
log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

# Validate input
if [[ -z "$REPO" ]]; then
    log_error "Usage: $0 <repo> [branch]"
    exit 1
fi

# Parse owner/repo from various formats
parse_repo() {
    local input="$1"
    # Remove .git suffix if present
    input="${input%.git}"
    # Extract owner/repo from URLs or plain format
    if [[ "$input" =~ github\.com[:/]([^/]+/[^/]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$input" =~ ^([^/]+/[^/]+)$ ]]; then
        echo "$input"
    else
        echo ""
    fi
}

# Send Discord notification via OpenCLAW
send_discord() {
    local message="$1"

    if ! command -v openclaw &> /dev/null; then
        log_warn "OpenCLAW not installed, skipping Discord notification"
        log_info "Message: $message"
        return 0
    fi

    # Default Discord channel from skill
    local discord_channel="${DISCORD_CHANNEL_ID:-1491175562348331209}"

    if openclaw message send --channel discord --target "$discord_channel" --message "$message" 2>&1; then
        log_info "Discord notification sent"
    else
        log_warn "Failed to send Discord notification via OpenCLAW"
    fi
}

# Main deployment logic
main() {
    local owner repo

    # Parse and validate repo
    local parsed
    parsed=$(parse_repo "$REPO")
    if [[ -z "$parsed" ]]; then
        send_discord "❌ Invalid repository format: $REPO. Use owner/repo or full GitHub URL"
        log_error "Invalid repository format: $REPO"
        exit 1
    fi

    owner=$(echo "$parsed" | cut -d'/' -f1)
    repo=$(echo "$parsed" | cut -d'/' -f2)

    # Validate branch name to prevent shell injection
    if [[ ! "$BRANCH" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "Invalid branch name: $BRANCH"
        exit 1
    fi

    local target_dir="$HOME/repos/$owner/$repo"

    # Check if already exists (idempotency)
    if [[ -d "$target_dir" ]]; then
        local message="ℹ️ Repository already deployed: $owner/$repo\nLocation: $target_dir"
        send_discord "ℹ️ Repository already deployed: $owner/$repo - Location: $target_dir"
        log_info "$message"
        exit 0
    fi

    # Create parent directory
    mkdir -p "$HOME/repos/$owner"

    # Clone repository
    log_info "Cloning $owner/$repo (branch: $BRANCH) to $target_dir..."
    if git clone --depth 1 -b "$BRANCH" "https://github.com/$owner/$repo.git" "$target_dir" 2>&1; then
        local message="✅ Repository deployed to VM: $owner/$repo ($BRANCH)\nLocation: $target_dir"
        send_discord "✅ Repository deployed to VM: $owner/$repo ($BRANCH) - Location: $target_dir"
        log_info "$message"
    else
        local message="❌ Failed to deploy $owner/$repo: Clone failed"
        send_discord "❌ Failed to deploy $owner/$repo: Clone failed"
        log_error "$message"
        exit 1
    fi
}

main "$@"