#!/bin/bash
# File: .devcontainer/additions/config-git.sh
# Purpose: Configure Git user identity (name and email)
# Usage: bash config-git.sh

#------------------------------------------------------------------------------
# CONFIG METADATA - For dev-setup.sh integration
#------------------------------------------------------------------------------

SCRIPT_ID="config-git"
SCRIPT_NAME="Git Identity"
SCRIPT_VER="0.0.1"
SCRIPT_DESCRIPTION="Set your global Git username and email for commits"
SCRIPT_CATEGORY="INFRA_CONFIG"
SCRIPT_CHECK_COMMAND="git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Configure Git identity||false|"
    "Action|--show|Display current Git configuration||false|"
    "Action|--verify|Restore from .devcontainer.secrets||false|"
    "Info|--help|Show help information||false|"
)

#------------------------------------------------------------------------------

set -e

# Source logging library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Persistent storage paths
PERSISTENT_DIR="/workspace/.devcontainer.secrets/env-vars"
PERSISTENT_FILE="$PERSISTENT_DIR/.git-identity"

#------------------------------------------------------------------------------
# PERSISTENT STORAGE FUNCTIONS
#------------------------------------------------------------------------------

setup_persistent_storage() {
    # Ensure persistent directory exists
    mkdir -p "$PERSISTENT_DIR"
}

load_from_persistent_storage() {
    # Load saved identity if it exists
    if [ -f "$PERSISTENT_FILE" ]; then
        # shellcheck source=/dev/null
        source "$PERSISTENT_FILE" 2>/dev/null || true
        return 0
    fi
    return 1
}

save_to_persistent_storage() {
    local name="$1"
    local email="$2"

    # Ensure directory exists
    mkdir -p "$PERSISTENT_DIR"

    # Write identity to persistent file
    cat > "$PERSISTENT_FILE" <<EOF
# Git identity - managed by config-git.sh
# This file persists across container rebuilds
export GIT_USER_NAME="$name"
export GIT_USER_EMAIL="$email"
EOF

    # Set permissions (readable only by user)
    chmod 600 "$PERSISTENT_FILE"
}

#------------------------------------------------------------------------------
# SHOW CONFIG - Display current configuration
#------------------------------------------------------------------------------

show_config() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Current Configuration: $SCRIPT_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local user_name=$(git config --global user.name 2>/dev/null)
    local user_email=$(git config --global user.email 2>/dev/null)

    if [ -z "$user_name" ] && [ -z "$user_email" ]; then
        echo "❌ Not configured"
        echo ""
        echo "Run: bash $0"
        return 1
    fi

    echo "Git Global Config:"
    echo "  user.name:   ${user_name:-<not set>}"
    echo "  user.email:  ${user_email:-<not set>}"
    echo ""

    # Show persistent storage status
    if [ -f "$PERSISTENT_FILE" ]; then
        echo "Persistent Storage: ✅ Survives container rebuild"
        echo "  Location: $PERSISTENT_FILE"
    else
        echo "Persistent Storage: ❌ Not saved (won't survive container rebuild)"
        echo "  Run this script to save: bash $0"
    fi
    echo ""

    return 0
}

#------------------------------------------------------------------------------
# VERIFY MODE - Non-interactive validation for container rebuild
#------------------------------------------------------------------------------

verify_git_identity() {
    # Silent mode - no prompts, just validate and restore if needed

    # Setup persistent storage directory
    setup_persistent_storage

    # Load from persistent storage if exists
    if load_from_persistent_storage; then
        # Apply saved identity to git config
        git config --global user.name "${GIT_USER_NAME}"
        git config --global user.email "${GIT_USER_EMAIL}"
        echo "✅ Git identity restored: ${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
        return 0
    fi

    # No saved identity - check if git is already configured
    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        # Git is configured but not saved to persistent storage
        # This can happen after initial setup - save current config
        local current_name=$(git config --global user.name)
        local current_email=$(git config --global user.email)
        save_to_persistent_storage "$current_name" "$current_email"
        echo "✅ Git identity saved: ${current_name} <${current_email}>"
        return 0
    fi

    # No identity configured - this is expected on first container creation
    # Exit silently without error (user will configure via check-configs)
    return 0
}

#------------------------------------------------------------------------------
# INTERACTIVE CONFIGURATION
#------------------------------------------------------------------------------

configure_git_identity() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Git Identity Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Setup persistent storage
    setup_persistent_storage

    # Try to load from persistent storage first
    if load_from_persistent_storage; then
        log_info "Found saved identity:"
        echo "  Name:  $GIT_USER_NAME"
        echo "  Email: $GIT_USER_EMAIL"
        echo ""

        # Apply to git config if not already set
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
    fi

    # Show current configuration if exists
    log_info "Current Git configuration:"
    CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "Not set")
    CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "Not set")

    echo "  Name:  $CURRENT_NAME"
    echo "  Email: $CURRENT_EMAIL"
    echo ""

    # Prompt for name
    local GIT_NAME
    if [[ "$CURRENT_NAME" == "Not set" ]]; then
        read -p "Enter your full name (e.g., John Doe): " GIT_NAME
    else
        read -p "Enter your full name (press Enter to keep '$CURRENT_NAME'): " GIT_NAME
    fi

    if [[ -z "$GIT_NAME" ]]; then
        if [[ "$CURRENT_NAME" == "Not set" ]]; then
            log_warn "Name cannot be empty. Using default."
            GIT_NAME="VSCode User"
        else
            log_info "Keeping current name: $CURRENT_NAME"
            GIT_NAME="$CURRENT_NAME"
        fi
    fi

    # Prompt for email
    local GIT_EMAIL
    if [[ "$CURRENT_EMAIL" == "Not set" ]]; then
        read -p "Enter your email (e.g., john.doe@organization.no): " GIT_EMAIL
    else
        read -p "Enter your email (press Enter to keep '$CURRENT_EMAIL'): " GIT_EMAIL
    fi

    if [[ -z "$GIT_EMAIL" ]]; then
        if [[ "$CURRENT_EMAIL" == "Not set" ]]; then
            log_warn "Email cannot be empty. Using default."
            GIT_EMAIL="user@example.com"
        else
            log_info "Keeping current email: $CURRENT_EMAIL"
            GIT_EMAIL="$CURRENT_EMAIL"
        fi
    fi

    echo ""
    log_info "Setting Git identity..."

    # Set Git configuration
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    # Save to persistent storage
    save_to_persistent_storage "$GIT_NAME" "$GIT_EMAIL"
    log_success "Identity saved to persistent storage"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Git Identity Configured"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Your Git Configuration:"
    echo "  Name:  $(git config --global user.name)"
    echo "  Email: $(git config --global user.email)"
    echo ""
    echo "💡 This will be used for all your Git commits in this container."
    echo "   Your identity is saved and will persist across container rebuilds."
    echo ""
    echo "📝 Identity stored in: $PERSISTENT_FILE"
    echo ""
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    # Handle flags
    case "${1:-}" in
        --show)
            show_config
            exit $?
            ;;
        --verify)
            verify_git_identity
            exit $?
            ;;
        --help)
            echo "Usage: $0 [--show|--verify|--help]"
            echo ""
            echo "  (no args)  Configure Git identity interactively"
            echo "  --show     Display current Git configuration"
            echo "  --verify   Restore from .devcontainer.secrets (non-interactive)"
            echo "  --help     Show this help"
            exit 0
            ;;
    esac

    # Interactive configuration
    configure_git_identity
}

# Run main
main "$@"
