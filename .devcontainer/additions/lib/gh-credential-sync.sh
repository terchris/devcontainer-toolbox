#!/bin/bash
# file: .devcontainer/additions/lib/gh-credential-sync.sh
#
# Purpose: Ensure GitHub CLI credentials symlink is properly set up
# Persists ~/.config/gh across container rebuilds by symlinking to
# .devcontainer.secrets/.gh-config/ (issue #59)

ensure_gh_credentials() {
    local target_dir="/workspace/.devcontainer.secrets/.gh-config"
    local link_path="/home/vscode/.config/gh"

    # Ensure target directory exists
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    # Ensure parent ~/.config exists as a real directory
    mkdir -p "$(dirname "$link_path")"

    # Check current state of ~/.config/gh
    if [ -L "$link_path" ]; then
        # It's a symlink - verify it points to the right place
        local current_target
        current_target=$(readlink -f "$link_path")
        if [ "$current_target" != "$target_dir" ]; then
            echo "⚠️  gh symlink points to wrong location: $current_target"
            echo "   Fixing to point to: $target_dir"
            rm "$link_path"
            ln -sf "$target_dir" "$link_path"
        fi
    elif [ -d "$link_path" ]; then
        # It's a directory - need to convert to symlink
        echo "⚠️  ~/.config/gh is a directory instead of symlink"
        echo "   Converting to symlink for credential persistence..."

        # If there are any files in the directory, copy them to persistent location
        if [ -n "$(ls -A "$link_path" 2>/dev/null)" ]; then
            echo "   Copying existing files to persistent location..."
            cp -a "$link_path"/* "$target_dir/" 2>/dev/null || true
            cp -a "$link_path"/.[!.]* "$target_dir/" 2>/dev/null || true
        fi

        # Remove directory and create symlink
        rm -rf "$link_path"
        ln -sf "$target_dir" "$link_path"
        echo "   ✅ Converted to symlink"
    elif [ -e "$link_path" ]; then
        # It exists but is neither directory nor symlink (file?)
        echo "⚠️  ~/.config/gh exists as unexpected type"
        echo "   Removing and creating symlink..."
        rm -f "$link_path"
        ln -sf "$target_dir" "$link_path"
    else
        # Doesn't exist - create symlink
        ln -sf "$target_dir" "$link_path"
    fi

    # Verify symlink is working
    if [ -L "$link_path" ] && [ -d "$target_dir" ]; then
        return 0
    else
        echo "❌ Failed to set up GitHub CLI credentials symlink"
        return 1
    fi
}

# Run the check when sourced (matches claude-credential-sync.sh pattern)
ensure_gh_credentials
