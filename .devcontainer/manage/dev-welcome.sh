#!/bin/bash
# File: .devcontainer/manage/dev-welcome.sh
# Purpose: Display welcome message when opening a new terminal
# Installed to: /etc/profile.d/dev-welcome.sh by Dockerfile / postCreateCommand.sh
#
# This script runs every time a new terminal is opened.
# On the FIRST terminal after container start, it also streams the
# entrypoint's startup log so the user sees setup progress in real-time.

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

# Show startup log on the first terminal after container start.
# The entrypoint writes output to /tmp/.dct-startup.log. A permanent copy
# is saved at .log.saved for dev-log. We display it here on first terminal.
#
# VS Code spawns several internal (invisible) interactive shells before
# the user's terminal. Each increments a counter. We allow up to 5 displays
# so the user's terminal (typically 3rd-5th shell) still shows the log.
_dct_startup_log="/tmp/.dct-startup.log"
_dct_welcome_counter="/tmp/.dct-startup-welcome-count"
if [ -f "$_dct_startup_log" ]; then
    _dct_count=0
    [ -f "$_dct_welcome_counter" ] && _dct_count=$(cat "$_dct_welcome_counter" 2>/dev/null || echo 0)
    if [ "$_dct_count" -lt 5 ]; then
        echo ""
        if grep -q 'Startup complete' "$_dct_startup_log" 2>/dev/null; then
            # Entrypoint already finished — just display the log
            cat "$_dct_startup_log"
        else
            # Entrypoint still running — stream in real-time until done
            tail -f -n +1 "$_dct_startup_log" 2>/dev/null | while IFS= read -r line; do
                echo "$line"
                [[ "$line" == *"Startup complete"* ]] && break
            done
        fi
        echo $((_dct_count + 1)) > "$_dct_welcome_counter" 2>/dev/null || true
    fi
fi
echo ""
