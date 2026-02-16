#!/bin/bash
# dev-sync.sh - Sync toolbox scripts without rebuilding the container
# Usage: dev-sync [--check|--force|--quiet|--rollback|--help]

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-sync"
SCRIPT_NAME="Sync Scripts"
SCRIPT_DESCRIPTION="Update toolbox scripts without rebuilding the container"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"

set -e

DCT_HOME="${DCT_HOME:-/opt/devcontainer-toolbox}"
MANAGE_DIR="$DCT_HOME/manage"
REPO="terchris/devcontainer-toolbox"
BACKUP_DIR="$DCT_HOME/.backup"

# Source version-utils for centralized version checking
if [ -f "$MANAGE_DIR/lib/version-utils.sh" ]; then
    source "$MANAGE_DIR/lib/version-utils.sh"
fi

# ─── Helper functions ───────────────────────────────────────────────────────

# Print unless --quiet
_log() {
    if [ "$QUIET" = false ]; then
        echo "$@"
    fi
}

# Read SCRIPTS_VERSION from a scripts-version.txt file
_read_scripts_ver() {
    grep "^SCRIPTS_VERSION=" "$1" 2>/dev/null | cut -d= -f2
}

# Update symlinks in /usr/local/bin/ for all dev-*.sh in manage/
_update_symlinks() {
    # Remove old dev-* symlinks that point into DCT_HOME/manage
    for link in /usr/local/bin/dev-*; do
        if [ -L "$link" ]; then
            local target=$(readlink "$link" 2>/dev/null || true)
            if [[ "$target" == "$DCT_HOME/manage/"* ]]; then
                rm -f "$link"
            fi
        fi
    done

    # Create symlinks for all current dev-*.sh scripts
    for script in "$DCT_HOME"/manage/dev-*.sh; do
        if [ -f "$script" ]; then
            local cmd_name=$(basename "$script" .sh)
            ln -sf "$script" "/usr/local/bin/$cmd_name"
        fi
    done
}

# Compare old and new tools.json and report changes
_report_changes() {
    local old_json="$1"
    local new_json="$2"

    if [ ! -f "$old_json" ] || [ ! -f "$new_json" ]; then
        return
    fi

    # Count tools in each
    local old_count=$(grep -c '"SCRIPT_ID"' "$old_json" 2>/dev/null || echo "0")
    local new_count=$(grep -c '"SCRIPT_ID"' "$new_json" 2>/dev/null || echo "0")

    if [ "$old_count" != "$new_count" ]; then
        local diff=$((new_count - old_count))
        if [ "$diff" -gt 0 ]; then
            _log "  $diff new tool(s) added"
        elif [ "$diff" -lt 0 ]; then
            _log "  $((-diff)) tool(s) removed"
        fi
    fi
}

# ─── CLI flags ──────────────────────────────────────────────────────────────

MODE="sync"
FORCE=false
QUIET=false

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            echo "Usage: dev-sync [OPTIONS]"
            echo ""
            echo "Update toolbox scripts without rebuilding the container."
            echo "Downloads the latest scripts from GitHub and replaces them atomically."
            echo ""
            echo "Options:"
            echo "  --check      Check if an update is available (don't download)"
            echo "  --force      Sync even if version matches"
            echo "  --quiet      Minimal output (for auto-sync on startup)"
            echo "  --rollback   Restore scripts from the last backup"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "For container-level updates (Dockerfile, OS packages, runtimes),"
            echo "use 'dev-update' instead."
            exit 0
            ;;
        --check)    MODE="check" ;;
        --force)    FORCE=true ;;
        --quiet)    QUIET=true ;;
        --rollback) MODE="rollback" ;;
        *)
            echo "Unknown option: $1"
            echo "Run 'dev-sync --help' for usage."
            exit 1
            ;;
    esac
    shift
done

# ─── Rollback ───────────────────────────────────────────────────────────────

if [ "$MODE" = "rollback" ]; then
    if [ ! -d "$BACKUP_DIR/manage" ] || [ ! -d "$BACKUP_DIR/additions" ]; then
        echo "Error: No backup found at $BACKUP_DIR"
        echo "A backup is created each time dev-sync updates scripts."
        exit 1
    fi

    echo "Restoring scripts from backup..."

    # Save current scripts-version for reporting
    local_ver="unknown"
    if [ -f "$DCT_HOME/scripts-version.txt" ]; then
        local_ver=$(_read_scripts_ver "$DCT_HOME/scripts-version.txt")
    fi
    backup_ver="unknown"
    if [ -f "$BACKUP_DIR/scripts-version.txt" ]; then
        backup_ver=$(_read_scripts_ver "$BACKUP_DIR/scripts-version.txt")
    fi

    # Restore
    rm -rf "$DCT_HOME/additions" "$DCT_HOME/manage"
    cp -a "$BACKUP_DIR/additions" "$DCT_HOME/"
    cp -a "$BACKUP_DIR/manage" "$DCT_HOME/"
    if [ -f "$BACKUP_DIR/scripts-version.txt" ]; then
        cp "$BACKUP_DIR/scripts-version.txt" "$DCT_HOME/"
    fi

    # Update symlinks
    _update_symlinks

    echo "Rolled back: $local_ver → $backup_ver"
    echo "Run 'dev-sync' to re-apply the latest update."
    exit 0
fi

# ─── Sync cache (skip if checked recently) ─────────────────────────────────

SYNC_CACHE="/tmp/.dct-last-sync"
CACHE_MAX_AGE=86400  # 24 hours in seconds

if [ "$FORCE" = false ] && [ -f "$SYNC_CACHE" ]; then
    last_sync=$(cat "$SYNC_CACHE" 2>/dev/null || echo "0")
    now=$(date +%s)
    age=$((now - last_sync))
    if [ "$age" -lt "$CACHE_MAX_AGE" ]; then
        _log "Scripts checked recently ($(( age / 3600 ))h ago). Use --force to check now."
        exit 0
    fi
fi

# ─── Version check ──────────────────────────────────────────────────────────

_log "Checking for script updates..."

# Load both version systems
_load_version_info
_load_scripts_version_info
_check_for_scripts_updates

# Update sync cache timestamp (we checked, regardless of result)
date +%s > "$SYNC_CACHE" 2>/dev/null || true

_log ""
_log "Container version: v$TOOLBOX_VERSION"
_log "Scripts version:   $SCRIPTS_VERSION"

if [ -n "$SCRIPTS_REMOTE_VERSION" ]; then
    _log "Remote scripts:    $SCRIPTS_REMOTE_VERSION"
elif [ "$FORCE" = false ]; then
    _log ""
    _log "Scripts are up to date."
    exit 0
fi

if [ "$MODE" = "check" ]; then
    if [ -n "$SCRIPTS_REMOTE_VERSION" ]; then
        _log ""
        _log "Scripts update available: $SCRIPTS_VERSION → $SCRIPTS_REMOTE_VERSION"
        _log "Run 'dev-sync' to update."
    else
        _log ""
        _log "Scripts are up to date ($SCRIPTS_VERSION)."
    fi
    exit 0
fi

if [ "$FORCE" = true ] && [ -z "$SCRIPTS_REMOTE_VERSION" ]; then
    _log ""
    _log "Forcing sync (same version: $SCRIPTS_VERSION)..."
fi

# ─── Download ───────────────────────────────────────────────────────────────

_log ""
_log "Downloading latest scripts..."

TEMP_DIR=$(mktemp -d /tmp/dct-sync-XXXXX)
ZIP_FILE="$TEMP_DIR/dev_containers.zip"

# Cleanup on exit (success or failure)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Download the zip from the latest GitHub release
if ! curl -fsSL "https://github.com/$REPO/releases/download/latest/dev_containers.zip" -o "$ZIP_FILE" 2>/dev/null; then
    echo "Error: Failed to download dev_containers.zip from GitHub."
    echo "Check your network connection and try again."
    exit 1
fi

# Verify download
if [ ! -s "$ZIP_FILE" ]; then
    echo "Error: Downloaded file is empty."
    exit 1
fi

_log "Downloaded $(du -h "$ZIP_FILE" | cut -f1) zip file."

# ─── Extract ────────────────────────────────────────────────────────────────

if ! unzip -q "$ZIP_FILE" -d "$TEMP_DIR/" 2>/dev/null; then
    echo "Error: Failed to extract zip file."
    exit 1
fi

# Verify extracted directories exist
if [ ! -d "$TEMP_DIR/.devcontainer/manage" ] || [ ! -d "$TEMP_DIR/.devcontainer/additions" ]; then
    echo "Error: Zip file doesn't contain expected directories."
    exit 1
fi

# ─── Backup ─────────────────────────────────────────────────────────────────

_log "Backing up current scripts..."

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$DCT_HOME/additions" "$BACKUP_DIR/"
cp -a "$DCT_HOME/manage" "$BACKUP_DIR/"
if [ -f "$DCT_HOME/scripts-version.txt" ]; then
    cp "$DCT_HOME/scripts-version.txt" "$BACKUP_DIR/"
fi

# Save path to old tools.json for reporting
OLD_TOOLS_JSON=""
if [ -f "$BACKUP_DIR/manage/tools.json" ]; then
    OLD_TOOLS_JSON="$BACKUP_DIR/manage/tools.json"
fi

# ─── Atomic swap ────────────────────────────────────────────────────────────

_log "Updating scripts..."

rm -rf "$DCT_HOME/additions" "$DCT_HOME/manage"
mv "$TEMP_DIR/.devcontainer/additions" "$DCT_HOME/"
mv "$TEMP_DIR/.devcontainer/manage" "$DCT_HOME/"

# Update scripts-version.txt
if [ -f "$TEMP_DIR/scripts-version.txt" ]; then
    cp "$TEMP_DIR/scripts-version.txt" "$DCT_HOME/"
fi

# Make all scripts executable
chmod +x "$DCT_HOME/manage/"*.sh 2>/dev/null || true
chmod +x "$DCT_HOME/additions/"*.sh 2>/dev/null || true
chmod +x "$DCT_HOME/additions/lib/"*.sh 2>/dev/null || true

# ─── Regenerate tools.json ──────────────────────────────────────────────────

if [ -f "$DCT_HOME/manage/generate-tools-json.sh" ]; then
    bash "$DCT_HOME/manage/generate-tools-json.sh" >/dev/null 2>&1 || true
fi

# ─── Update symlinks ───────────────────────────────────────────────────────

_update_symlinks

# ─── Report ─────────────────────────────────────────────────────────────────

_log ""
_log "Sync complete!"

# Read new version
new_ver="$SCRIPTS_VERSION"
if [ -f "$DCT_HOME/scripts-version.txt" ]; then
    new_ver=$(_read_scripts_ver "$DCT_HOME/scripts-version.txt")
fi
_log "Scripts updated: $SCRIPTS_VERSION → $new_ver"

# Show per-tool changes if we have both old and new tools.json
if [ -n "$OLD_TOOLS_JSON" ] && [ -f "$DCT_HOME/manage/tools.json" ]; then
    _report_changes "$OLD_TOOLS_JSON" "$DCT_HOME/manage/tools.json"
fi

_log ""
_log "Run 'dev-sync --rollback' to restore the previous version."
