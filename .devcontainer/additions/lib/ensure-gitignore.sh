#!/bin/bash
# file: .devcontainer/additions/lib/ensure-gitignore.sh
# Purpose: Ensure .devcontainer.secrets is in .gitignore (issue #40)
# This script should be sourced by other scripts - it runs the check when sourced.

_ensure_gitignore() {
    local workspace="${DCT_WORKSPACE:-/workspace}"
    local gitignore_file="$workspace/.gitignore"

    # Only run if workspace exists
    [ -d "$workspace" ] || return 0

    if [ ! -f "$gitignore_file" ]; then
        # Create .gitignore with .devcontainer.secrets
        cat > "$gitignore_file" 2>/dev/null <<'EOF' || true
# DevContainer Toolbox - credentials folder (NEVER commit)
.devcontainer.secrets/
EOF
    elif ! grep -q "^\.devcontainer\.secrets" "$gitignore_file" 2>/dev/null; then
        # Append to existing .gitignore
        {
            echo ""
            echo "# DevContainer Toolbox - credentials folder (NEVER commit)"
            echo ".devcontainer.secrets/"
        } >> "$gitignore_file" 2>/dev/null || true
    fi

    # Ensure .devcontainer/backup/ is gitignored (dev-update backups)
    if [ -f "$gitignore_file" ] && ! grep -q "^\.devcontainer/backup" "$gitignore_file" 2>/dev/null; then
        {
            echo ""
            echo "# DevContainer Toolbox - devcontainer.json backups from dev-update"
            echo ".devcontainer/backup/"
        } >> "$gitignore_file" 2>/dev/null || true
    fi
}

# Run the check when sourced
_ensure_gitignore
