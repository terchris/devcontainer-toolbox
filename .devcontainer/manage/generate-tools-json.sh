#!/bin/bash
# File: .devcontainer/manage/generate-tools-json.sh
# Purpose: Generate tools.json and categories.json — single source of truth for tool metadata
# Usage: Called at container build time, by dev-docs, or manually via: generate-tools-json.sh
#
# Outputs:
#   tools.json      - Complete tool inventory with versions, packages, extensions
#   categories.json - Category metadata for website and runtime
#
# Output location: /opt/devcontainer-toolbox/manage/ (image mode)
#                  or .devcontainer/manage/ (copy mode)

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

# Output locations
OUTPUT_FILE="$MANAGE_DIR/tools.json"
CATEGORIES_FILE="$MANAGE_DIR/categories.json"

# Source categories library for categories.json generation
# shellcheck source=/dev/null
source "$ADDITIONS_DIR/lib/categories.sh"

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

# Top-level version for the tools inventory
# This will be auto-bumped by CI/CD when any tool version changes (future Phase 2)
TOOLS_VERSION="1.0.0"

# Start JSON
echo "{" > "$OUTPUT_FILE"
echo "  \"version\": \"$TOOLS_VERSION\"," >> "$OUTPUT_FILE"
echo '  "generated": "'$(date -Iseconds)'",' >> "$OUTPUT_FILE"
echo '  "tools": [' >> "$OUTPUT_FILE"

first=true

# Process all install scripts
for script_path in "$ADDITIONS_DIR"/install-*.sh; do
    [ -f "$script_path" ] || continue

    script_basename=$(basename "$script_path")

    # Extract metadata
    id=$(extract_var "$script_path" "SCRIPT_ID")
    version=$(extract_var "$script_path" "SCRIPT_VER")
    name=$(extract_var "$script_path" "SCRIPT_NAME")
    description=$(extract_var "$script_path" "SCRIPT_DESCRIPTION")
    category=$(extract_var "$script_path" "SCRIPT_CATEGORY")
    tags=$(extract_var "$script_path" "SCRIPT_TAGS")
    abstract=$(extract_var "$script_path" "SCRIPT_ABSTRACT")
    logo=$(extract_var "$script_path" "SCRIPT_LOGO")
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

    # Build optional fields
    local_optional=""
    if [ -n "$logo" ]; then
        local_optional="$local_optional
      \"logo\": \"$(json_escape "$logo")\","
    fi

    # Write JSON entry
    cat >> "$OUTPUT_FILE" << EOF
    {
      "id": "$(json_escape "$id")",
      "version": "$(json_escape "$version")",
      "type": "install",
      "file": "$script_basename",
      "name": "$(json_escape "$name")",
      "description": "$(json_escape "$description")",
      "category": "$(json_escape "$category")",
      "tags": $(to_json_array "$tags"),
      "abstract": "$(json_escape "$abstract")",${local_optional}
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
    version=$(extract_var "$script_path" "SCRIPT_VER")
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
      "version": "$(json_escape "$version")",
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
    version=$(extract_var "$script_path" "SCRIPT_VER")
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
      "version": "$(json_escape "$version")",
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

# Close tools JSON
echo "" >> "$OUTPUT_FILE"
echo "  ]" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"

#------------------------------------------------------------------------------
# Generate categories.json
#------------------------------------------------------------------------------

echo "Generating categories.json..."

echo "{" > "$CATEGORIES_FILE"
echo '  "categories": [' >> "$CATEGORIES_FILE"

first_cat=true
for category_id in "${CATEGORY_ORDER[@]}"; do
    cat_name=$(get_category_name "$category_id" || true)
    cat_order=$(get_category_order "$category_id" || true)
    cat_abstract=$(get_category_abstract "$category_id" || true)
    cat_summary=$(get_category_summary "$category_id" || true)
    cat_tags=$(get_category_tags "$category_id" || true)
    cat_logo=$(get_category_logo "$category_id" || true)

    # Add comma before all but first
    if [ "$first_cat" = true ]; then
        first_cat=false
    else
        echo "," >> "$CATEGORIES_FILE"
    fi

    # Write JSON entry
    cat >> "$CATEGORIES_FILE" << EOF
    {
      "id": "$category_id",
      "name": "$(json_escape "$cat_name")",
      "order": $cat_order,
      "tags": $(to_json_array "$cat_tags"),
      "abstract": "$(json_escape "$cat_abstract")",
      "summary": "$(json_escape "$cat_summary")",
      "logo": "$(json_escape "$cat_logo")"
    }
EOF
done

echo "  ]" >> "$CATEGORIES_FILE"
echo "}" >> "$CATEGORIES_FILE"

echo "Generated: $CATEGORIES_FILE"
