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
        cat > "$gitignore_file" <<'EOF'
# DevContainer Toolbox - credentials folder (NEVER commit)
.devcontainer.secrets/
EOF
    elif ! grep -q "^\.devcontainer\.secrets" "$gitignore_file" 2>/dev/null; then
        # Append to existing .gitignore
        echo "" >> "$gitignore_file"
        echo "# DevContainer Toolbox - credentials folder (NEVER commit)" >> "$gitignore_file"
        echo ".devcontainer.secrets/" >> "$gitignore_file"
    fi
}

# Run the check when sourced
_ensure_gitignore
