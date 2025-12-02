#!/bin/bash
# file: .devcontainer/additions/lib/categories.sh
#
# Central definition of script categories using a table structure
# Source this file to get category constants and helper functions
#
# Usage:
#   source "${SCRIPT_DIR}/lib/categories.sh"
#   display_name=$(get_category_display_name "LANGUAGE_DEV")
#   description=$(get_category_description "LANGUAGE_DEV")

#------------------------------------------------------------------------------
# Category Table
#------------------------------------------------------------------------------
# Format: SORT_ORDER|CATEGORY_ID|DISPLAY_NAME|SHORT_DESCRIPTION|LONG_DESCRIPTION
#
# To add a new category:
# 1. Add a new line to the table below
# 2. Set SORT_ORDER to control display order (lower numbers first)
# 3. Use UPPERCASE_UNDERSCORE format for CATEGORY_ID
# 4. Keep SHORT_DESCRIPTION under 60 characters (for help text)
# 5. LONG_DESCRIPTION can be more detailed (for documentation)

# Only declare if not already set (prevents errors when sourced multiple times)
if [[ -z "${CATEGORY_TABLE+x}" ]]; then
    readonly CATEGORY_TABLE="
1|LANGUAGE_DEV|Development Tools|Development tools (Python, TypeScript, Go, etc.)|Programming language development environments and tools (Python, TypeScript, Go, Rust, C#, Java, PHP)
2|AI_TOOLS|AI & Machine Learning Tools|AI and ML tools (Claude Code, etc.)|AI and machine learning development tools (Claude Code, etc.)
3|CLOUD_TOOLS|Cloud & Infrastructure Tools|Cloud infrastructure (Azure, etc.)|Cloud platform tools and SDKs (Azure, AWS, GCP)
4|DATA_ANALYTICS|Data & Analytics Tools|Data analysis and platforms|Data analysis, visualization, data engineering tools, and data platforms (Jupyter, pandas, DBT, Databricks, Snowflake)
5|BACKGROUND_SERVICES|Background Services & Daemons|Background services (nginx, OTEL, etc.)|Background services and daemons (nginx reverse proxy, OTEL collector, monitoring services)
6|INFRA_CONFIG|Infrastructure & Configuration|Infrastructure and configuration tools|Infrastructure as Code, configuration management, and DevOps tools (Ansible, Kubernetes, Terraform)
"
fi

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Parse category table and return specific field for a category
# Args: $1=category_id, $2=field_number (1=sort, 2=id, 3=display, 4=short_desc, 5=long_desc)
_get_category_field() {
    local category_id=$1
    local field_num=$2

    echo "$CATEGORY_TABLE" | grep -v "^$" | while IFS='|' read -r sort_order cat_id display_name short_desc long_desc; do
        if [[ "$cat_id" == "$category_id" ]]; then
            case $field_num in
                1) echo "$sort_order" ;;
                2) echo "$cat_id" ;;
                3) echo "$display_name" ;;
                4) echo "$short_desc" ;;
                5) echo "$long_desc" ;;
            esac
            return 0
        fi
    done
    return 1
}

# Get display name for a category
get_category_display_name() {
    local category=$1
    local result=$(_get_category_field "$category" 3)
    if [[ -n "$result" ]]; then
        echo "$result"
    else
        echo "$category"
    fi
}

# Get long description for a category
get_category_description() {
    local category=$1
    _get_category_field "$category" 5
}

# Get short description for a category (for help text)
get_category_short_description() {
    local category=$1
    _get_category_field "$category" 4
}

# Get sort order for a category
get_category_sort_order() {
    local category=$1
    _get_category_field "$category" 1
}

# Get all category IDs in sort order
get_all_category_ids() {
    echo "$CATEGORY_TABLE" | grep -v "^$" | sort -t'|' -k1 -n | cut -d'|' -f2
}

# Validate that a category ID is valid
is_valid_category() {
    local category=$1
    echo "$CATEGORY_TABLE" | grep -v "^$" | cut -d'|' -f2 | grep -q "^${category}$"
}

# List all categories in table format (machine-readable)
# Output format: SORT_ORDER|CATEGORY_ID|DISPLAY_NAME|SHORT_DESC|LONG_DESC
list_categories() {
    echo "$CATEGORY_TABLE" | grep -v "^$" | sort -t'|' -k1 -n
}

# List all categories with just ID and display name
list_categories_simple() {
    echo "$CATEGORY_TABLE" | grep -v "^$" | sort -t'|' -k1 -n | while IFS='|' read -r sort_order cat_id display_name rest; do
        printf "%-20s %s\n" "$cat_id" "$display_name"
    done
}

#------------------------------------------------------------------------------
# Display Functions
#------------------------------------------------------------------------------

# Show all categories and their descriptions (human-readable)
show_all_categories() {
    echo "Available Script Categories:"
    echo ""
    echo "$CATEGORY_TABLE" | grep -v "^$" | sort -t'|' -k1 -n | while IFS='|' read -r sort_order cat_id display_name short_desc long_desc; do
        printf "  %-20s %-30s\n" "$cat_id" "$display_name"
        printf "  %-20s %s\n" "" "$long_desc"
        echo ""
    done
}

# Show categories as a table
show_categories_table() {
    echo "Category Table:"
    echo ""
    printf "%-5s %-20s %-30s %-60s\n" "SORT" "ID" "DISPLAY NAME" "SHORT DESCRIPTION"
    printf "%-5s %-20s %-30s %-60s\n" "----" "--" "------------" "-----------------"
    echo "$CATEGORY_TABLE" | grep -v "^$" | sort -t'|' -k1 -n | while IFS='|' read -r sort_order cat_id display_name short_desc long_desc; do
        printf "%-5s %-20s %-30s %-60s\n" "$sort_order" "$cat_id" "$display_name" "$short_desc"
    done
}

#------------------------------------------------------------------------------
# Category Constants (for convenience)
#------------------------------------------------------------------------------
# These are generated from the table and can be used in scripts for validation

# Only declare if not already set (prevents errors when sourced multiple times)
if [[ -z "${CATEGORY_LANGUAGE_DEV+x}" ]]; then
    readonly CATEGORY_LANGUAGE_DEV="LANGUAGE_DEV"
    readonly CATEGORY_AI_TOOLS="AI_TOOLS"
    readonly CATEGORY_CLOUD_TOOLS="CLOUD_TOOLS"
    readonly CATEGORY_DATA_ANALYTICS="DATA_ANALYTICS"
    readonly CATEGORY_BACKGROUND_SERVICES="BACKGROUND_SERVICES"
    readonly CATEGORY_INFRA_CONFIG="INFRA_CONFIG"
fi

# Array of all category IDs in sort order (for iteration)
# Populated dynamically from the table
_populate_category_order() {
    CATEGORY_ORDER=()
    while IFS= read -r cat_id; do
        CATEGORY_ORDER+=("$cat_id")
    done < <(get_all_category_ids)
}

# Populate the array when sourced
_populate_category_order
