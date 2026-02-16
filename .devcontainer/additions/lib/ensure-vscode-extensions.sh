#!/bin/bash
# file: .devcontainer/additions/lib/ensure-vscode-extensions.sh
# Purpose: Ensure .vscode/extensions.json recommends the Dev Containers extension (issue #49)
# This script should be sourced by other scripts - it runs the check when sourced.

_ensure_vscode_extensions() {
    local workspace="${DCT_WORKSPACE:-/workspace}"
    local vscode_dir="$workspace/.vscode"
    local extensions_file="$vscode_dir/extensions.json"
    local extension="ms-vscode-remote.remote-containers"

    # Only run if workspace exists
    [ -d "$workspace" ] || return 0

    # Create .vscode/ directory if needed
    [ -d "$vscode_dir" ] || mkdir -p "$vscode_dir"

    if [ ! -f "$extensions_file" ]; then
        # Case 1: File doesn't exist — create it
        cat > "$extensions_file" <<EOF
{
  "recommendations": [
    "$extension"
  ]
}
EOF
    elif grep -q "$extension" "$extensions_file" 2>/dev/null; then
        # Case 3: Already present — do nothing
        return 0
    elif grep -q '"recommendations"' "$extensions_file" 2>/dev/null; then
        # Case 2a: File exists with recommendations array, missing extension — insert
        local tmp_file
        tmp_file=$(mktemp)
        while IFS= read -r line; do
            echo "$line" >> "$tmp_file"
            if [[ "$line" == *'"recommendations"'*'['* ]]; then
                echo "    \"$extension\"," >> "$tmp_file"
            fi
        done < "$extensions_file"
        mv "$tmp_file" "$extensions_file"
    else
        # Case 2b: File exists but no recommendations array — overwrite
        cat > "$extensions_file" <<EOF
{
  "recommendations": [
    "$extension"
  ]
}
EOF
    fi
}

_ensure_vscode_gitignore() {
    local workspace="${DCT_WORKSPACE:-/workspace}"
    local gitignore_file="$workspace/.gitignore"

    # Only run if .gitignore exists
    [ -f "$gitignore_file" ] || return 0

    # If .gitignore already has the negation pattern, nothing to do
    if grep -q '!\.vscode/extensions\.json' "$gitignore_file" 2>/dev/null; then
        return 0
    fi

    # If .gitignore has blanket .vscode/ ignore, replace with .vscode/* + negation
    if grep -q '^\.vscode/' "$gitignore_file" 2>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" == ".vscode/" ]]; then
                echo ".vscode/*" >> "$tmp_file"
                echo "!.vscode/extensions.json" >> "$tmp_file"
            else
                echo "$line" >> "$tmp_file"
            fi
        done < "$gitignore_file"
        mv "$tmp_file" "$gitignore_file"
    fi
}

# Run the checks when sourced
_ensure_vscode_extensions
_ensure_vscode_gitignore
