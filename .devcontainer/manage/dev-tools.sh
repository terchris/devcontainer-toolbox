#!/bin/bash
# File: .devcontainer/manage/dev-tools.sh
# Purpose: Output machine-readable tool inventory as JSON
# Usage: dev-tools [--generate] [--pretty]
#
# Examples:
#   dev-tools                    # Output JSON (pipe to jq for formatting)
#   dev-tools | jq .             # Pretty print all tools
#   dev-tools | jq '.tools[] | select(.category == "CLOUD_TOOLS") | .name'
#   dev-tools | jq '.tools[] | select(.packages.system[] == "azure-cli") | .id'

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-tools"
SCRIPT_NAME="Tools Inventory"
SCRIPT_DESCRIPTION="Output machine-readable tool inventory as JSON"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Resolve script location
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_SOURCE" ]; do
    _dir="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
    SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
    [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$_dir/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"

# Determine paths
if [[ "$(basename "$SCRIPT_DIR")" == "manage" ]]; then
    DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
    MANAGE_DIR="$SCRIPT_DIR"
else
    DEVCONTAINER_DIR="$SCRIPT_DIR"
    MANAGE_DIR="$SCRIPT_DIR/manage"
fi

TOOLS_JSON="$MANAGE_DIR/tools.json"
GENERATE_SCRIPT="$MANAGE_DIR/generate-tools-json.sh"

#------------------------------------------------------------------------------
# Parse Arguments
#------------------------------------------------------------------------------

GENERATE=false
PRETTY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --generate|-g)
            GENERATE=true
            shift
            ;;
        --pretty|-p)
            PRETTY=true
            shift
            ;;
        --help|-h)
            cat << 'EOF'
Usage: dev-tools [OPTIONS]

Output the complete tool inventory as JSON to stdout.

Options:
  -g, --generate    Regenerate tools.json before output
  -p, --pretty      Pretty print the JSON (requires jq)
  -h, --help        Show this help message

Examples:
  dev-tools                                    # Raw JSON output
  dev-tools --pretty                           # Pretty printed JSON
  dev-tools | jq '.tools | length'             # Count tools
  dev-tools | jq '.tools[] | .id'              # List all tool IDs
  dev-tools | jq '.tools[] | select(.type == "install")'  # Only install scripts
  dev-tools | jq '.tools[] | select(.category == "CLOUD_TOOLS") | .name'
  dev-tools | jq '.tools[] | select(.packages.system[]? == "azure-cli") | .id'
  dev-tools | jq '.tools[] | select(.tags[]? == "kubernetes") | {id, name}'

The JSON includes:
  - Install scripts (type: "install") with packages and extensions
  - Config scripts (type: "config")
  - Service scripts (type: "service")

Each tool entry contains metadata (id, name, description, category, tags)
and for install scripts: packages (system, node, python, etc.) and extensions.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

# Generate if requested or if file doesn't exist
if [ "$GENERATE" = true ] || [ ! -f "$TOOLS_JSON" ]; then
    if [ -f "$GENERATE_SCRIPT" ]; then
        bash "$GENERATE_SCRIPT" >&2
    else
        echo "Error: tools.json not found and generate script missing" >&2
        echo "Expected: $TOOLS_JSON" >&2
        exit 1
    fi
fi

# Check file exists
if [ ! -f "$TOOLS_JSON" ]; then
    echo "Error: tools.json not found at $TOOLS_JSON" >&2
    exit 1
fi

# Output
if [ "$PRETTY" = true ]; then
    if command -v jq &>/dev/null; then
        jq . "$TOOLS_JSON"
    else
        echo "Error: --pretty requires jq to be installed" >&2
        cat "$TOOLS_JSON"
    fi
else
    cat "$TOOLS_JSON"
fi
