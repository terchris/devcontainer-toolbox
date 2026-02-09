#!/bin/bash
# File: .devcontainer/manage/generate-tools-json.sh
# Purpose: Generate tools.json with complete tool inventory
# Usage: Called at container build time or manually via: generate-tools-json.sh
#
# Outputs tools.json to /opt/devcontainer-toolbox/manage/tools.json (image mode)
# or .devcontainer/manage/tools.json (copy mode)

set -e

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
ADDITIONS_DIR="$DEVCONTAINER_DIR/additions"

# Output location
OUTPUT_FILE="$MANAGE_DIR/tools.json"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Extract a simple variable from a script
extract_var() {
    local script_path=$1
    local var_name=$2
    grep "^${var_name}=" "$script_path" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'"
}

# Extract a package array from a script file
extract_package_array() {
    local script_path=$1
    local array_name=$2

    awk -v arr="${array_name}" '
        $0 ~ "^"arr"=\\(" {
            capturing = 1
            sub("^"arr"=\\(", "")
            if (/)$/) {
                sub(/\)$/, "")
                if (length($0) > 0 && $0 !~ /^[[:space:]]*$/) print
                capturing = 0
                next
            }
            if (length($0) > 0 && $0 !~ /^[[:space:]]*$/) print
            next
        }
        capturing {
            if (/^[[:space:]]*\)/ || /\)$/) {
                sub(/\)$/, "")
                sub(/^[[:space:]]*\)/, "")
                if (length($0) > 0 && $0 !~ /^[[:space:]]*$/) print
                capturing = 0
                next
            }
            print
        }
    ' "$script_path" 2>/dev/null | \
        grep -v '^[[:space:]]*$' | \
        grep -v '^[[:space:]]*#' | \
        sed 's/^[[:space:]]*//' | \
        sed 's/[[:space:]]*$//' | \
        sed 's/"//g' | \
        sed "s/'//g"
}

# Convert newline-separated list to JSON array
to_json_array() {
    local input="$1"
    if [ -z "$input" ]; then
        echo "[]"
        return
    fi
    echo "$input" | awk '
        BEGIN { printf "[" }
        NR > 1 { printf ", " }
        {
            # Clean the line - remove comments after the value
            gsub(/[[:space:]]*#.*$/, "")
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            if (length($0) > 0) printf "\"%s\"", $0
        }
        END { printf "]" }
    '
}

# Extract extension ID from full string like "Name (id) - Description"
extract_extension_ids() {
    local input="$1"
    echo "$input" | while read -r line; do
        # Extract content between parentheses using sed
        local ext_id
        ext_id=$(echo "$line" | sed -n 's/.*(\([^)]*\)).*/\1/p')
        if [ -n "$ext_id" ]; then
            echo "$ext_id"
        fi
    done
}

# Escape string for JSON
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

echo "Generating tools.json..."

# Start JSON
echo "{" > "$OUTPUT_FILE"
echo '  "generated": "'$(date -Iseconds)'",' >> "$OUTPUT_FILE"
echo '  "tools": [' >> "$OUTPUT_FILE"

first=true

# Process all install scripts
for script_path in "$ADDITIONS_DIR"/install-*.sh; do
    [ -f "$script_path" ] || continue

    script_basename=$(basename "$script_path")

    # Extract metadata
    id=$(extract_var "$script_path" "SCRIPT_ID")
    name=$(extract_var "$script_path" "SCRIPT_NAME")
    description=$(extract_var "$script_path" "SCRIPT_DESCRIPTION")
    category=$(extract_var "$script_path" "SCRIPT_CATEGORY")
    tags=$(extract_var "$script_path" "SCRIPT_TAGS")
    abstract=$(extract_var "$script_path" "SCRIPT_ABSTRACT")
    website=$(extract_var "$script_path" "SCRIPT_WEBSITE")
    summary=$(extract_var "$script_path" "SCRIPT_SUMMARY")
    related=$(extract_var "$script_path" "SCRIPT_RELATED")
    check_cmd=$(extract_var "$script_path" "SCRIPT_CHECK_COMMAND")

    # Skip if no ID
    [ -z "$id" ] && continue

    # Extract packages
    pkg_system=$(extract_package_array "$script_path" "PACKAGES_SYSTEM")
    pkg_node=$(extract_package_array "$script_path" "PACKAGES_NODE")
    pkg_python=$(extract_package_array "$script_path" "PACKAGES_PYTHON")
    pkg_cargo=$(extract_package_array "$script_path" "PACKAGES_CARGO")
    pkg_go=$(extract_package_array "$script_path" "PACKAGES_GO")
    pkg_pwsh=$(extract_package_array "$script_path" "PACKAGES_PWSH")
    pkg_dotnet=$(extract_package_array "$script_path" "PACKAGES_DOTNET")
    extensions_raw=$(extract_package_array "$script_path" "EXTENSIONS")
    extensions=$(extract_extension_ids "$extensions_raw")

    # Add comma before all but first
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$OUTPUT_FILE"
    fi

    # Write JSON entry
    cat >> "$OUTPUT_FILE" << EOF
    {
      "id": "$(json_escape "$id")",
      "type": "install",
      "file": "$script_basename",
      "name": "$(json_escape "$name")",
      "description": "$(json_escape "$description")",
      "category": "$(json_escape "$category")",
      "tags": $(to_json_array "$tags"),
      "abstract": "$(json_escape "$abstract")",
      "website": "$(json_escape "$website")",
      "summary": "$(json_escape "$summary")",
      "related": $(to_json_array "$related"),
      "checkCommand": "$(json_escape "$check_cmd")",
      "packages": {
        "system": $(to_json_array "$pkg_system"),
        "node": $(to_json_array "$pkg_node"),
        "python": $(to_json_array "$pkg_python"),
        "cargo": $(to_json_array "$pkg_cargo"),
        "go": $(to_json_array "$pkg_go"),
        "powershell": $(to_json_array "$pkg_pwsh"),
        "dotnet": $(to_json_array "$pkg_dotnet")
      },
      "extensions": $(to_json_array "$extensions")
    }
EOF
done

# Process config scripts
for script_path in "$ADDITIONS_DIR"/config-*.sh; do
    [ -f "$script_path" ] || continue

    script_basename=$(basename "$script_path")

    # Extract metadata
    id=$(extract_var "$script_path" "SCRIPT_ID")
    name=$(extract_var "$script_path" "SCRIPT_NAME")
    description=$(extract_var "$script_path" "SCRIPT_DESCRIPTION")
    category=$(extract_var "$script_path" "SCRIPT_CATEGORY")
    tags=$(extract_var "$script_path" "SCRIPT_TAGS")
    abstract=$(extract_var "$script_path" "SCRIPT_ABSTRACT")
    summary=$(extract_var "$script_path" "SCRIPT_SUMMARY")
    related=$(extract_var "$script_path" "SCRIPT_RELATED")
    check_cmd=$(extract_var "$script_path" "SCRIPT_CHECK_COMMAND")

    # Skip if no ID
    [ -z "$id" ] && continue

    echo "," >> "$OUTPUT_FILE"

    # Write JSON entry
    cat >> "$OUTPUT_FILE" << EOF
    {
      "id": "$(json_escape "$id")",
      "type": "config",
      "file": "$script_basename",
      "name": "$(json_escape "$name")",
      "description": "$(json_escape "$description")",
      "category": "$(json_escape "$category")",
      "tags": $(to_json_array "$tags"),
      "abstract": "$(json_escape "$abstract")",
      "summary": "$(json_escape "$summary")",
      "related": $(to_json_array "$related"),
      "checkCommand": "$(json_escape "$check_cmd")"
    }
EOF
done

# Process service scripts
for script_path in "$ADDITIONS_DIR"/service-*.sh; do
    [ -f "$script_path" ] || continue

    script_basename=$(basename "$script_path")

    # Extract metadata
    id=$(extract_var "$script_path" "SCRIPT_ID")
    name=$(extract_var "$script_path" "SCRIPT_NAME")
    description=$(extract_var "$script_path" "SCRIPT_DESCRIPTION")
    category=$(extract_var "$script_path" "SCRIPT_CATEGORY")
    tags=$(extract_var "$script_path" "SCRIPT_TAGS")
    abstract=$(extract_var "$script_path" "SCRIPT_ABSTRACT")
    summary=$(extract_var "$script_path" "SCRIPT_SUMMARY")
    related=$(extract_var "$script_path" "SCRIPT_RELATED")

    # Skip if no ID
    [ -z "$id" ] && continue

    echo "," >> "$OUTPUT_FILE"

    # Write JSON entry
    cat >> "$OUTPUT_FILE" << EOF
    {
      "id": "$(json_escape "$id")",
      "type": "service",
      "file": "$script_basename",
      "name": "$(json_escape "$name")",
      "description": "$(json_escape "$description")",
      "category": "$(json_escape "$category")",
      "tags": $(to_json_array "$tags"),
      "abstract": "$(json_escape "$abstract")",
      "summary": "$(json_escape "$summary")",
      "related": $(to_json_array "$related")
    }
EOF
done

# Close JSON
echo "" >> "$OUTPUT_FILE"
echo "  ]" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"
