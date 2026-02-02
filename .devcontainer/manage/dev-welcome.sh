#!/bin/bash
# File: .devcontainer/manage/dev-welcome.sh
# Purpose: Display welcome message when opening a new terminal
# Installed to: /etc/profile.d/dev-welcome.sh by postCreateCommand.sh
#
# This script runs every time a new terminal is opened.
# Keep it minimal to avoid slowing down terminal startup.

# Only show in interactive shells
[[ $- == *i* ]] || return 0

# Only show once per shell (not for nested sources within the same shell).
# Use a non-exported variable so each new terminal gets its own copy.
[[ -z "${__dct_welcome_done:-}" ]] || return 0
__dct_welcome_done=1

# Source version utilities
# Check $DCT_HOME first (image mode), then fall back to workspace path (copy mode)
VERSION_UTILS=""
if [ -n "$DCT_HOME" ] && [ -f "$DCT_HOME/manage/lib/version-utils.sh" ]; then
    VERSION_UTILS="$DCT_HOME/manage/lib/version-utils.sh"
elif [ -f "/workspace/.devcontainer/manage/lib/version-utils.sh" ]; then
    VERSION_UTILS="/workspace/.devcontainer/manage/lib/version-utils.sh"
fi

if [ -n "$VERSION_UTILS" ]; then
    source "$VERSION_UTILS"
    echo ""
    show_version_info short
else
    # Fallback if library not found
    echo ""
    echo "  DevContainer Toolbox - Type 'dev-help' for available commands"
fi

# Check if git identity is configured
_dct_git_name=$(git config --global user.name 2>/dev/null || echo "")
_dct_git_email=$(git config --global user.email 2>/dev/null || echo "")
if [ -z "$_dct_git_name" ] || [ -z "$_dct_git_email" ] || [[ "$_dct_git_email" == *@localhost ]]; then
    echo "  Git identity not configured - run 'dev-setup' to set your name and email"
fi
echo ""
