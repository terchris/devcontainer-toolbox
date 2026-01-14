#!/bin/bash
# File: .devcontainer/manage/dev-welcome.sh
# Purpose: Display welcome message when opening a new terminal
# Installed to: /etc/profile.d/dev-welcome.sh by postCreateCommand.sh
#
# This script runs every time a new terminal is opened.
# Keep it minimal to avoid slowing down terminal startup.

# Only show in interactive shells
[[ $- == *i* ]] || return 0

# Only show once per terminal session (not for subshells)
[[ -z "$DEV_WELCOME_SHOWN" ]] || return 0
export DEV_WELCOME_SHOWN=1

# Brief hint about available commands
echo ""
echo "  DevContainer Toolbox - Type 'dev-help' for available commands"
echo ""
