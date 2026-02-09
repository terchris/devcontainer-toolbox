#!/bin/bash
# File: .devcontainer/additions/config-azure-devops.sh
# Purpose: Configure Azure DevOps authentication (PAT) and project defaults
# Usage: bash config-azure-devops.sh

#------------------------------------------------------------------------------
# CONFIG METADATA - For dev-setup.sh integration
#------------------------------------------------------------------------------

SCRIPT_ID="config-azure-devops"
SCRIPT_NAME="Azure DevOps Identity"
SCRIPT_VER="0.0.1"
SCRIPT_DESCRIPTION="Configure Azure DevOps authentication (PAT) and project defaults"
SCRIPT_CATEGORY="INFRA_CONFIG"
SCRIPT_CHECK_COMMAND="command -v az >/dev/null 2>&1 && [ -f /workspace/.devcontainer.secrets/env-vars/azure-devops-pat ]"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="azure devops pat authentication identity config"
SCRIPT_ABSTRACT="Configure Azure DevOps PAT authentication and default organization/project."
SCRIPT_LOGO="config-azure-devops-logo.webp"
SCRIPT_WEBSITE="https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate"
SCRIPT_SUMMARY="Interactive configuration script for setting up Azure DevOps authentication using Personal Access Tokens (PAT). Requires Azure DevOps CLI (tool-azure-devops) to be installed first. Stores configuration persistently in .devcontainer.secrets for reuse across container rebuilds."
SCRIPT_RELATED="config-git tool-azure-devops"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Configure Azure DevOps identity||false|"
    "Action|--show|Display current Azure DevOps configuration||false|"
    "Action|--verify|Restore from .devcontainer.secrets (non-interactive)||false|"
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
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Persistent storage paths
PERSISTENT_DIR="/workspace/.devcontainer.secrets/env-vars"
PAT_FILE="$PERSISTENT_DIR/azure-devops-pat"
CONFIG_FILE="$PERSISTENT_DIR/.azure-devops-config"

#------------------------------------------------------------------------------
# PERSISTENT STORAGE FUNCTIONS
#------------------------------------------------------------------------------

setup_persistent_storage() {
    # Ensure persistent directory exists
    mkdir -p "$PERSISTENT_DIR"
}

load_from_persistent_storage() {
    # Load saved configuration if it exists
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE" 2>/dev/null || true
    fi

    # Load PAT if it exists
    if [ -f "$PAT_FILE" ]; then
        AZURE_DEVOPS_PAT=$(cat "$PAT_FILE" 2>/dev/null | tr -d '\n\r')
        export AZURE_DEVOPS_EXT_PAT="$AZURE_DEVOPS_PAT"
        return 0
    fi
    return 1
}

save_to_persistent_storage() {
    local org_url="$1"
    local project="$2"
    local pat="$3"
    local repo="$4"

    # Ensure directory exists
    mkdir -p "$PERSISTENT_DIR"

    # Write config to persistent file
    cat > "$CONFIG_FILE" <<EOF
# Azure DevOps config - managed by config-azure-devops.sh
# This file persists across container rebuilds
export AZURE_DEVOPS_ORG="$org_url"
export AZURE_DEVOPS_PROJECT="$project"
export AZURE_DEVOPS_REPO="$repo"
EOF

    # Write PAT to separate file (more secure)
    echo -n "$pat" > "$PAT_FILE"

    # Set permissions (readable only by user)
    chmod 600 "$CONFIG_FILE"
    chmod 600 "$PAT_FILE"
}

#------------------------------------------------------------------------------
# PREREQUISITE CHECK
#------------------------------------------------------------------------------

check_az_cli() {
    if ! command -v az &>/dev/null; then
        log_error "Azure CLI (az) is not installed"
        echo ""
        echo "Install it first using:"
        echo "  dev-setup → Cloud Tools → Azure DevOps CLI"
        echo ""
        echo "Or run directly:"
        echo "  bash .devcontainer/additions/install-tool-azure-devops.sh"
        return 1
    fi

    # Check if azure-devops extension is installed
    if ! az extension show --name azure-devops &>/dev/null; then
        log_warn "azure-devops extension not installed, installing now..."
        az extension add --name azure-devops --yes 2>/dev/null || \
            az extension add --name azure-devops 2>/dev/null || {
            log_error "Failed to install azure-devops extension"
            return 1
        }
        log_success "azure-devops extension installed"
    fi

    return 0
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

    # Check if az CLI is available
    if ! command -v az &>/dev/null; then
        log_warn "Azure CLI (az) is not installed"
        echo ""
        echo "Install with: dev-setup → Cloud Tools → Azure DevOps CLI"
        echo ""
    fi

    # Load from persistent storage
    load_from_persistent_storage 2>/dev/null || true

    # Show organization
    local org="${AZURE_DEVOPS_ORG:-}"
    if [ -z "$org" ]; then
        org=$(az devops configure --list 2>/dev/null | grep "organization" | awk '{print $3}' || echo "")
    fi

    # Show project
    local project="${AZURE_DEVOPS_PROJECT:-}"
    if [ -z "$project" ]; then
        project=$(az devops configure --list 2>/dev/null | grep "project" | awk '{print $3}' || echo "")
    fi

    # Show PAT status
    local pat_status="❌ Not configured"
    if [ -n "${AZURE_DEVOPS_EXT_PAT:-}" ] || [ -f "$PAT_FILE" ]; then
        pat_status="✅ Configured (stored securely)"
    fi

    # Show repo
    local repo="${AZURE_DEVOPS_REPO:-}"

    echo "Azure DevOps Configuration:"
    echo "  Organization:  ${org:-<not set>}"
    echo "  Project:       ${project:-<not set>}"
    if [ -n "$repo" ]; then
        echo "  Repository:    $repo"
    fi
    echo "  PAT Token:     $pat_status"
    echo ""

    # Show persistent storage status
    if [ -f "$CONFIG_FILE" ] && [ -f "$PAT_FILE" ]; then
        echo "Persistent Storage: ✅ Survives container rebuild"
        echo "  Config: $CONFIG_FILE"
        echo "  PAT:    $PAT_FILE"
    else
        echo "Persistent Storage: ❌ Not saved (won't survive container rebuild)"
        echo "  Run this script to save: bash $0"
    fi
    echo ""

    return 0
}

#------------------------------------------------------------------------------
# VERIFY MODE - Restore from persistent storage (non-interactive)
#------------------------------------------------------------------------------

verify_azure_devops() {
    # Non-interactive restore from .devcontainer.secrets
    # Called on container start via entrypoint

    setup_persistent_storage

    # Check if we have saved configuration
    if [ ! -f "$PAT_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
        # No saved config, nothing to restore (silent exit)
        return 0
    fi

    # Load configuration
    if ! load_from_persistent_storage; then
        return 0
    fi

    # Export PAT to environment
    if [ -n "$AZURE_DEVOPS_PAT" ]; then
        export AZURE_DEVOPS_EXT_PAT="$AZURE_DEVOPS_PAT"

        # Also write to bashrc for persistence in new shells
        local bashrc="/home/vscode/.bashrc"
        if [ -f "$bashrc" ]; then
            # Remove old entry if exists
            sed -i '/AZURE_DEVOPS_EXT_PAT/d' "$bashrc" 2>/dev/null || true
            # Add new entry
            echo "export AZURE_DEVOPS_EXT_PAT=\"$AZURE_DEVOPS_PAT\"" >> "$bashrc"
        fi
    fi

    # Configure az devops defaults if az CLI is available
    if command -v az &>/dev/null; then
        if [ -n "${AZURE_DEVOPS_ORG:-}" ]; then
            az devops configure --defaults organization="$AZURE_DEVOPS_ORG" 2>/dev/null || true
        fi
        if [ -n "${AZURE_DEVOPS_PROJECT:-}" ]; then
            az devops configure --defaults project="$AZURE_DEVOPS_PROJECT" 2>/dev/null || true
        fi
    fi

    echo "✅ Azure DevOps identity restored:"
    echo "   Organization: ${AZURE_DEVOPS_ORG:-<not set>}"
    echo "   Project:      ${AZURE_DEVOPS_PROJECT:-<not set>}"
    if [ -n "${AZURE_DEVOPS_REPO:-}" ]; then
        echo "   Repository:   ${AZURE_DEVOPS_REPO}"
    fi
    echo "   PAT:          configured"

    return 0
}

#------------------------------------------------------------------------------
# INTERACTIVE CONFIGURATION
#------------------------------------------------------------------------------

configure_azure_devops() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Azure DevOps Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check prerequisites
    if ! check_az_cli; then
        return 1
    fi

    # Setup persistent storage
    setup_persistent_storage

    # Try to load from persistent storage first
    load_from_persistent_storage 2>/dev/null || true

    # Show current configuration if exists
    log_info "Current Azure DevOps configuration:"
    local current_org="${AZURE_DEVOPS_ORG:-}"
    local current_project="${AZURE_DEVOPS_PROJECT:-}"
    local current_repo="${AZURE_DEVOPS_REPO:-}"
    local current_pat_status="Not set"

    if [ -z "$current_org" ]; then
        current_org=$(az devops configure --list 2>/dev/null | grep "organization" | awk '{print $3}' || echo "Not set")
    fi
    if [ -z "$current_project" ]; then
        current_project=$(az devops configure --list 2>/dev/null | grep "project" | awk '{print $3}' || echo "Not set")
    fi
    if [ -n "${AZURE_DEVOPS_EXT_PAT:-}" ] || [ -f "$PAT_FILE" ]; then
        current_pat_status="Configured"
    fi

    echo "  Organization: $current_org"
    echo "  Project:      $current_project"
    if [ -n "$current_repo" ]; then
        echo "  Repository:   $current_repo"
    fi
    echo "  PAT Token:    $current_pat_status"
    echo ""

    # Prompt for Azure DevOps URL (we'll parse org, project, and repo from it)
    local org_url=""
    local project=""
    local repo_name=""

    if [[ "$current_org" != "Not set" ]] && [[ -n "$current_org" ]] && [[ -n "$current_repo" ]]; then
        # Full config exists - allow keeping it
        echo "Current: $current_org / $current_project / $current_repo"
        read -p "Paste Azure DevOps URL from browser (or press Enter to keep current): " browser_url
        if [[ -z "$browser_url" ]]; then
            org_url="$current_org"
            project="$current_project"
            repo_name="$current_repo"
            log_info "Keeping current configuration"
        fi
    else
        # Missing repo - need full URL
        if [[ "$current_org" != "Not set" ]] && [[ -n "$current_org" ]]; then
            echo "Current: $current_org / $current_project (no repository configured)"
            echo ""
        fi
        echo "Open your Azure DevOps repository in a browser and copy the URL."
        echo "Example: https://dev.azure.com/MyCompany/MyProject/_git/MyRepo"
        echo ""
        read -p "Paste the URL here: " browser_url
    fi

    # Parse the URL if provided
    if [[ -n "$browser_url" ]]; then
        # Handle https://dev.azure.com/org/project/_git/repo format
        if [[ "$browser_url" =~ dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/\?#]+) ]]; then
            org_url="https://dev.azure.com/${BASH_REMATCH[1]}"
            project="${BASH_REMATCH[2]}"
            repo_name="${BASH_REMATCH[3]}"
        # Handle https://dev.azure.com/org/project format (no repo)
        elif [[ "$browser_url" =~ dev\.azure\.com/([^/]+)/([^/]+) ]]; then
            org_url="https://dev.azure.com/${BASH_REMATCH[1]}"
            project="${BASH_REMATCH[2]}"
            project="${project%%\?*}"
            project="${project%%\#*}"
            project="${project%%/*}"
        # Handle https://org.visualstudio.com/project/_git/repo format
        elif [[ "$browser_url" =~ ([^/]+)\.visualstudio\.com/([^/]+)/_git/([^/\?#]+) ]]; then
            org_url="https://${BASH_REMATCH[1]}.visualstudio.com"
            project="${BASH_REMATCH[2]}"
            repo_name="${BASH_REMATCH[3]}"
        # Handle https://org.visualstudio.com/project format (no repo)
        elif [[ "$browser_url" =~ ([^/]+)\.visualstudio\.com/([^/]+) ]]; then
            org_url="https://${BASH_REMATCH[1]}.visualstudio.com"
            project="${BASH_REMATCH[2]}"
            project="${project%%\?*}"
            project="${project%%\#*}"
            project="${project%%/*}"
        else
            log_error "Could not parse URL. Expected format:"
            echo "  https://dev.azure.com/YourOrg/YourProject/_git/YourRepo"
            return 1
        fi

        echo ""
        log_info "Parsed from URL:"
        echo "  Organization: $org_url"
        echo "  Project:      $project"
        if [[ -n "$repo_name" ]]; then
            echo "  Repository:   $repo_name"
        fi
        echo ""
        read -p "Is this correct? (Y/n): " confirm
        if [[ "$confirm" =~ ^[Nn] ]]; then
            log_error "Cancelled. Please try again with the correct URL."
            return 1
        fi
    fi

    if [[ -z "$org_url" ]]; then
        log_error "Organization URL is required"
        return 1
    fi

    # Prompt for PAT
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Personal Access Token (PAT) is required for authentication"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "If you already have a PAT, paste it below."
    echo ""
    echo "To create a new PAT:"
    echo "  1. Open: ${org_url}/_usersSettings/tokens"
    echo "  2. Click '+ New Token'"
    echo "  3. Name: devcontainer-toolbox"
    echo "  4. Expiration: 90 days (or longer)"
    echo "  5. Scopes: Select 'Full access'"
    echo "  6. Click 'Create' and copy the token immediately"
    echo ""
    echo "⚠️  Important:"
    echo "   - Copy the token NOW - you won't be able to see it again!"
    echo "   - The token will expire after the date you selected"
    echo "   - When it expires, run this configuration again to create a new one"
    echo ""
    echo "💾 We will store your PAT securely in:"
    echo "   .devcontainer.secrets/env-vars/azure-devops-pat"
    echo "   (This folder is gitignored and persists across container rebuilds)"
    echo ""

    local pat
    if [[ "$current_pat_status" == "Configured" ]]; then
        read -p "Enter PAT (press Enter to keep existing, or enter new): " pat
    else
        read -p "Enter PAT: " pat
    fi

    if [[ -z "$pat" ]]; then
        if [[ "$current_pat_status" != "Configured" ]]; then
            log_error "PAT is required"
            return 1
        fi
        # Keep existing PAT
        pat=$(cat "$PAT_FILE" 2>/dev/null | tr -d '\n\r')
        log_info "Keeping existing PAT"
    fi

    echo ""
    log_info "Configuring Azure DevOps..."

    # Export PAT to environment
    export AZURE_DEVOPS_EXT_PAT="$pat"

    # Configure az devops defaults
    az devops configure --defaults organization="$org_url" 2>/dev/null || true
    if [ -n "$project" ]; then
        az devops configure --defaults project="$project" 2>/dev/null || true
    fi

    # Validate PAT by making a test API call
    log_info "Validating PAT..."
    local validation_output
    if ! validation_output=$(az devops project show --organization "$org_url" --project "$project" 2>&1); then
        echo ""
        log_error "PAT validation failed:"
        echo "$validation_output"
        echo ""
        echo "Please check that:"
        echo "  - The PAT is correct (copy it again from Azure DevOps)"
        echo "  - The PAT has not expired"
        echo "  - The PAT has 'Code (Read)' or 'Full access' scope"
        echo ""
        # Clear the invalid PAT from environment
        unset AZURE_DEVOPS_EXT_PAT
        return 1
    fi
    log_success "PAT validated successfully"

    # Save to persistent storage
    save_to_persistent_storage "$org_url" "$project" "$pat" "$repo_name"
    log_success "Configuration saved to persistent storage"

    # Also write to bashrc for persistence in new shells
    local bashrc="/home/vscode/.bashrc"
    if [ -f "$bashrc" ]; then
        # Remove old entry if exists
        sed -i '/AZURE_DEVOPS_EXT_PAT/d' "$bashrc" 2>/dev/null || true
        # Add new entry
        echo "export AZURE_DEVOPS_EXT_PAT=\"$pat\"" >> "$bashrc"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Azure DevOps Configured"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Your Azure DevOps Configuration:"
    echo "  Organization: $org_url"
    echo "  Project:      ${project:-<not set>}"
    echo "  PAT:          configured"
    echo ""
    echo "💾 Configuration stored in:"
    echo "   .devcontainer.secrets/env-vars/"
    echo "   (persists across container rebuilds)"
    echo ""

    # Check if there's already a repo in workspace
    local workspace_git=$(git -C "${DCT_WORKSPACE:-/workspace}" config --get remote.origin.url 2>/dev/null || echo "")

    if [ -z "$workspace_git" ]; then
        # No repo in workspace - offer to clone
        # Build the clone URL
        local clone_url="$org_url/$project/_git/$repo_name"
        local workspace="${DCT_WORKSPACE:-/workspace}"
        local temp_clone="/tmp/repo-clone-$$"

        if [[ -n "$repo_name" ]]; then
            echo "🚀 Next step - clone the repository:"
            echo ""
            read -p "Do you want to clone '$repo_name' now? (Y/n): " clone_confirm
            if [[ ! "$clone_confirm" =~ ^[Nn] ]]; then
                echo ""
                log_info "Cloning repository '$repo_name'..."
                echo ""

                # Clone to temp folder
                local clone_output
                if ! clone_output=$(git clone "$clone_url" "$temp_clone" 2>&1); then
                    log_error "Clone failed:"
                    echo "$clone_output"
                    echo ""
                    echo "You can try manually:"
                    echo "   git clone $clone_url"
                    rm -rf "$temp_clone" 2>/dev/null || true
                else
                    # Move .git folder to workspace
                    log_info "Moving repository to workspace root..."

                    # Remove any existing .git in workspace (shouldn't exist if workspace is empty)
                    if [ -d "$workspace/.git" ]; then
                        log_warning "Workspace already has a .git folder - backing up to .git.backup"
                        mv "$workspace/.git" "$workspace/.git.backup"
                    fi

                    # Move .git
                    mv "$temp_clone/.git" "$workspace/.git"

                    # Move all files from temp clone to workspace
                    # Use rsync to handle overwrites properly, but preserve .devcontainer.secrets
                    for item in "$temp_clone"/*  "$temp_clone"/.[!.]* "$temp_clone"/..?*; do
                        [ -e "$item" ] || continue
                        local basename=$(basename "$item")

                        # Always preserve .devcontainer.secrets (has credentials)
                        if [ "$basename" = ".devcontainer.secrets" ]; then
                            continue
                        fi

                        # Move/overwrite everything else (including .devcontainer, .devcontainer.extend)
                        if [ -e "$workspace/$basename" ]; then
                            rm -rf "$workspace/$basename"
                        fi
                        mv "$item" "$workspace/"
                    done

                    # Clean up temp folder
                    rm -rf "$temp_clone"

                    # Reset git to clean state (in case of any issues)
                    cd "$workspace"
                    git reset --hard HEAD 2>/dev/null || true

                    # Ensure .devcontainer.secrets is in .gitignore (contains credentials)
                    if [ -f "${SCRIPT_DIR}/lib/ensure-gitignore.sh" ]; then
                        source "${SCRIPT_DIR}/lib/ensure-gitignore.sh"
                    fi

                    log_success "Repository cloned successfully!"
                    echo ""
                    echo "📁 Your repo is now at: $workspace"
                    echo ""
                    echo "🚀 Ready to work! Try:"
                    echo "   git status"
                    echo "   az repos pr create --title \"My PR\" --source-branch <branch>"
                fi
            else
                echo ""
                echo "To clone later, run:"
                echo "   git clone $clone_url"
            fi
        else
            echo "🚀 Next step - clone your repository:"
            echo ""
            echo "   To see available repositories:"
            echo "   az repos list --output table"
            echo ""
            echo "   To clone a repository:"
            echo "   git clone $org_url/$project/_git/<repo-name>"
        fi
        echo ""
    else
        # Repo exists - check if it matches the URL they provided
        # Extract repo name from workspace URL (handles both HTTPS and SSH formats)
        local workspace_repo=""
        if [[ "$workspace_git" =~ /_git/([^/?#]+) ]]; then
            workspace_repo="${BASH_REMATCH[1]}"
        elif [[ "$workspace_git" =~ :v3/[^/]+/[^/]+/([^/?#]+) ]]; then
            # SSH format: git@ssh.dev.azure.com:v3/Org/Project/Repo
            workspace_repo="${BASH_REMATCH[1]}"
        fi

        if [[ -n "$repo_name" ]] && [[ "$workspace_repo" == "$repo_name" ]]; then
            # Same repo - ready to go!
            echo "✅ You're already in the '$repo_name' repository. Ready to go!"
            echo ""
            echo "🚀 Quick start - create a pull request:"
            echo ""
            echo "   az repos pr create --title \"My PR\" --source-branch <your-branch>"
            echo "   az repos pr list"
            echo ""
        elif [[ -n "$repo_name" ]]; then
            # Different repo
            echo "⚠️  This workspace already contains a different repository:"
            echo "   Current: $workspace_git"
            echo "   You configured: $repo_name"
            echo ""
            echo "Your Azure DevOps authentication is configured and will work for both."
            echo ""
            echo "To clone '$repo_name' in a different location:"
            echo "   cd ~ && git clone $org_url/$project/_git/$repo_name"
            echo ""
        else
            # No repo name provided, just show PR commands
            echo "🚀 Quick start - create a pull request:"
            echo ""
            echo "   az repos pr create --title \"My PR\" --source-branch <your-branch>"
            echo "   az repos pr list"
            echo ""
        fi
    fi
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
            verify_azure_devops
            exit $?
            ;;
        --help)
            echo "Usage: $0 [--show|--verify|--help]"
            echo ""
            echo "  (no args)  Configure Azure DevOps interactively"
            echo "  --show     Display current Azure DevOps configuration"
            echo "  --verify   Restore from .devcontainer.secrets (non-interactive)"
            echo "  --help     Show this help"
            echo ""
            echo "Prerequisite: Azure CLI with azure-devops extension"
            echo "  Install with: dev-setup → Cloud Tools → Azure DevOps CLI"
            exit 0
            ;;
    esac

    # Interactive configuration
    configure_azure_devops
}

# Run main
main "$@"
