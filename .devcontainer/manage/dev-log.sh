#!/bin/bash
# File: .devcontainer/manage/dev-log.sh
# Purpose: Display the container startup log
# Usage: dev-log

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-log"
SCRIPT_NAME="Startup Log"
SCRIPT_DESCRIPTION="Display the container startup log"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"

#------------------------------------------------------------------------------

STARTUP_LOG="/tmp/.dct-startup.log.saved"

case "${1:-}" in
    --help|-h)
        echo "Usage: dev-log"
        echo ""
        echo "Display the container startup log from the most recent boot."
        echo "Shows what the entrypoint did: git identity, services, tool installs."
        exit 0
        ;;
esac

if [ -f "$STARTUP_LOG" ]; then
    cat "$STARTUP_LOG"
else
    echo "No startup log found."
    echo "The log is created when the container starts."
fi
