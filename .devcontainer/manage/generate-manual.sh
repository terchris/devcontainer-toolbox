#!/bin/bash
# file: .devcontainer/manage/generate-manual.sh
#
# Generates comprehensive documentation by running all install scripts with --help
# Output: docs/tools.md (overview), docs/tools-details.md (detailed), README.md (updated)
#
# Usage:
#   ./generate-manual.sh              # Generate full manual
#   ./generate-manual.sh --help       # Show this help
#   ./generate-manual.sh --dry-run    # Preview without writing
#   ./generate-manual.sh --category LANGUAGE_DEV  # Only specific category
#   ./generate-manual.sh --verbose    # Show detailed progress

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly SCRIPT_DIR
readonly ADDITIONS_DIR="${SCRIPT_DIR}/../additions"
readonly WORKSPACE_ROOT="${SCRIPT_DIR}/../.."
readonly OUTPUT_FILE="${WORKSPACE_ROOT}/docs/tools.md"
readonly OUTPUT_FILE_DETAILS="${WORKSPACE_ROOT}/docs/tools-details.md"
readonly README_FILE="${WORKSPACE_ROOT}/README.md"

# Source logging library
# shellcheck source=/dev/null
source "${ADDITIONS_DIR}/lib/logging.sh"

# Source categories library
# shellcheck source=/dev/null
source "${ADDITIONS_DIR}/lib/categories.sh"

# Options
DRY_RUN=0
VERBOSE=0
FILTER_CATEGORY=""

# Category script lists (populated by discover_scripts)
SCRIPTS_LANGUAGE_DEV=""
SCRIPTS_AI_TOOLS=""
SCRIPTS_CLOUD_TOOLS=""
SCRIPTS_DATA_ANALYTICS=""
SCRIPTS_INFRA_CONFIG=""

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

show_help() {
    cat << EOF
Generate Manual - Create comprehensive documentation from install scripts

Usage:
  ./generate-manual.sh              # Generate full manual
  ./generate-manual.sh --help       # Show this help
  ./generate-manual.sh --dry-run    # Preview without writing file
  ./generate-manual.sh --category LANGUAGE_DEV  # Only specific category
  ./generate-manual.sh --verbose    # Show detailed progress

Output:
  docs/tools.md         - Overview table with links
  docs/tools-details.md - Detailed help for each tool
  README.md             - Tools summary (between markers)

Categories:
  LANGUAGE_DEV    - $(get_category_short_description "LANGUAGE_DEV")
  AI_TOOLS        - $(get_category_short_description "AI_TOOLS")
  CLOUD_TOOLS     - $(get_category_short_description "CLOUD_TOOLS")
  DATA_ANALYTICS  - $(get_category_short_description "DATA_ANALYTICS")
  INFRA_CONFIG    - $(get_category_short_description "INFRA_CONFIG")

Examples:
  # Generate full manual
  ./generate-manual.sh

  # Preview what would be generated
  ./generate-manual.sh --dry-run

  # Only generate development tools section
  ./generate-manual.sh --category LANGUAGE_DEV --verbose

EOF
}

# Add script to appropriate category variable
add_to_category() {
    local category=$1
    local script_path=$2

    case "$category" in
        LANGUAGE_DEV)
            SCRIPTS_LANGUAGE_DEV="${SCRIPTS_LANGUAGE_DEV}${script_path} "
            ;;
        AI_TOOLS)
            SCRIPTS_AI_TOOLS="${SCRIPTS_AI_TOOLS}${script_path} "
            ;;
        CLOUD_TOOLS)
            SCRIPTS_CLOUD_TOOLS="${SCRIPTS_CLOUD_TOOLS}${script_path} "
            ;;
        DATA_ANALYTICS)
            SCRIPTS_DATA_ANALYTICS="${SCRIPTS_DATA_ANALYTICS}${script_path} "
            ;;
        INFRA_CONFIG)
            SCRIPTS_INFRA_CONFIG="${SCRIPTS_INFRA_CONFIG}${script_path} "
            ;;
    esac
}

# Get scripts for a category
get_category_scripts() {
    local category=$1

    case "$category" in
        LANGUAGE_DEV) echo "$SCRIPTS_LANGUAGE_DEV" ;;
        AI_TOOLS) echo "$SCRIPTS_AI_TOOLS" ;;
        CLOUD_TOOLS) echo "$SCRIPTS_CLOUD_TOOLS" ;;
        DATA_ANALYTICS) echo "$SCRIPTS_DATA_ANALYTICS" ;;
        INFRA_CONFIG) echo "$SCRIPTS_INFRA_CONFIG" ;;
        *) echo "" ;;
    esac
}

# Discover and categorize all install scripts
discover_scripts() {
    log_info "Discovering install scripts..."

    # Find all install-*.sh scripts (excluding template)
    while IFS= read -r script_path; do
        local script_name=$(basename "$script_path")

        # Skip template and tailscale (different structure)
        if [[ "$script_name" == *"template"* ]] || [[ "$script_name" == "install-tailscale.sh" ]]; then
            continue
        fi

        # Extract SCRIPT_CATEGORY and SCRIPT_ID
        local category=$(grep "^SCRIPT_CATEGORY=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
        local script_id=$(grep "^SCRIPT_ID=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)

        if [[ -n "$category" ]] && [[ -n "$script_id" ]]; then
            # Apply category filter if specified
            if [[ -n "$FILTER_CATEGORY" ]] && [[ "$category" != "$FILTER_CATEGORY" ]]; then
                continue
            fi

            add_to_category "$category" "$script_path"
            [[ $VERBOSE -eq 1 ]] && log_info "  Found: $script_name (category: $category, id: $script_id)"
        else
            log_warn "  Skipping $script_name: missing metadata"
        fi
    done < <(find "$ADDITIONS_DIR" -maxdepth 1 -name "install-*.sh" -type f | sort)
}

# Count total scripts across all categories
count_total_scripts() {
    local total=0
    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            total=$((total + $(echo "$scripts" | wc -w)))
        fi
    done
    echo "$total"
}

# Count categories with scripts
count_categories() {
    local count=0
    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# Generate table of contents
generate_toc() {
    local toc=""

    toc+="## Table of Contents\n\n"

    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            local category_name=$(get_category_display_name "$category")
            local anchor=$(echo "$category_name" | tr '[:upper:]' '[:lower:]' | tr ' &' '--' | tr -d ',')
            toc+="- [$category_name](#$anchor)\n"
        fi
    done

    toc+="\n---\n"
    echo -e "$toc"
}

# Generate categories overview
generate_categories_overview() {
    local overview=""

    overview+="## Categories\n\n"
    overview+="This manual is organized into the following categories:\n\n"

    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            local category_name=$(get_category_display_name "$category")
            local category_desc=$(get_category_description "$category")
            local script_count=$(echo "$scripts" | wc -w)

            overview+="### $category_name\n\n"
            overview+="$category_desc\n\n"
            overview+="**Scripts in this category:** $script_count\n\n"
        fi
    done

    overview+="---\n\n"
    echo -e "$overview"
}

# Generate tools summary table
generate_tools_summary() {
    local summary=""

    summary+="| Name | ID | Category | Description |\n"
    summary+="|------|----|---------|--------------|\n"

    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            local category_name=$(get_category_display_name "$category")

            for script_path in $scripts; do
                local script_name=$(grep "^SCRIPT_NAME=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
                local script_id=$(grep "^SCRIPT_ID=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
                local script_desc=$(grep "^SCRIPT_DESCRIPTION=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)

                # Create anchor link to tools-details.md
                local anchor=$(echo "$script_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

                summary+="| [$script_name](tools-details.md#$anchor) | \`$script_id\` | $category_name | $script_desc |\n"
            done
        fi
    done

    summary+="\n"
    echo -e "$summary"
}

# Generate README tools summary (category-based overview)
generate_readme_tools_content() {
    local content=""
    local total_scripts=$(count_total_scripts)

    content+="**${total_scripts}+ development tools** ready to install with one click:\n\n"
    content+="| Category | Tools |\n"
    content+="|----------|-------|\n"

    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            local category_name=$(get_category_display_name "$category")
            local tool_names=""

            for script_path in $scripts; do
                local script_name=$(grep "^SCRIPT_NAME=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
                # Shorten name for README (remove common suffixes - order matters!)
                script_name=$(echo "$script_name" | \
                    sed 's/ Runtime & Development Tools//g' | \
                    sed 's/ Development Tools//g' | \
                    sed 's/ Tools$//g' | \
                    sed 's/Data & Analytics/Data Analytics/g' | \
                    sed 's/API Development/API/g' | \
                    sed 's/Infrastructure as Code/Terraform, Ansible/g' | \
                    sed 's/Development Utilities/Dev Utilities/g' | \
                    sed 's/Okta Identity Management/Okta/g' | \
                    sed 's/Microsoft Power Platform/Power Platform/g' | \
                    sed 's/Azure Application Development/Azure Dev/g' | \
                    sed 's/Azure Operations & Infrastructure Management/Azure Ops/g')
                if [[ -n "$tool_names" ]]; then
                    tool_names+=", "
                fi
                tool_names+="$script_name"
            done

            content+="| **$category_name** | $tool_names |\n"
        fi
    done

    echo -e "$content"
}

# Update README.md with tools content between markers
update_readme() {
    log_info "Updating README.md..."

    if [[ ! -f "$README_FILE" ]]; then
        log_warn "README.md not found, skipping update"
        return 0
    fi

    # Check for markers
    if ! grep -q "<!-- TOOLS_START" "$README_FILE"; then
        log_warn "TOOLS_START marker not found in README.md, skipping update"
        return 0
    fi

    if ! grep -q "<!-- TOOLS_END -->" "$README_FILE"; then
        log_warn "TOOLS_END marker not found in README.md, skipping update"
        return 0
    fi

    # Generate the new content to a temp file
    local content_file
    content_file=$(mktemp)
    generate_readme_tools_content > "$content_file"

    # Create output file
    local temp_file
    temp_file=$(mktemp)

    # Extract before, insert new content, extract after
    # 1. Get everything up to and including TOOLS_START marker
    sed -n '1,/<!-- TOOLS_START/p' "$README_FILE" > "$temp_file"

    # 2. Add the new content
    cat "$content_file" >> "$temp_file"

    # 3. Get everything from TOOLS_END marker onwards
    sed -n '/<!-- TOOLS_END/,$p' "$README_FILE" >> "$temp_file"

    # Replace original file
    mv "$temp_file" "$README_FILE"
    rm -f "$content_file"

    log_info "Updated: $README_FILE"
}

# Format help output from a script
format_help_output() {
    local script_path=$1
    local script_name=$(basename "$script_path")

    [[ $VERBOSE -eq 1 ]] && log_info "    Running $script_name --help..."

    # Run script with --help and capture output
    local help_output
    if ! help_output=$(bash "$script_path" --help 2>&1); then
        log_error "    Failed to run $script_name --help"
        return 1
    fi

    # Filter out associative array errors and other bash errors
    help_output=$(echo "$help_output" | grep -v "declare: -A: invalid option" | grep -v "declare: usage:" | grep -v "syntax error: invalid arithmetic operator")

    # Extract just the main help section (skip the logging header)
    # The help output starts with a separator line and script info
    help_output=$(echo "$help_output" | awk '/^━{50,}/,0' | tail -n +2)

    # Format as markdown code block
    echo '```'
    echo "$help_output"
    echo '```'
    echo ""
}

# Generate section for a category
generate_category_section() {
    local category=$1
    local section=""

    local scripts=$(get_category_scripts "$category")
    if [[ -z "$scripts" ]]; then
        return 0
    fi

    local category_name=$(get_category_display_name "$category")

    log_info "  Generating section: $category_name"

    section+="\n\n## $category_name\n\n"

    # Process each script in this category
    local script_count=0
    for script_path in $scripts; do
        local script_name=$(grep "^SCRIPT_NAME=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
        local script_id=$(grep "^SCRIPT_ID=" "$script_path" | head -1 | cut -d'"' -f2 | cut -d"'" -f2)
        local script_basename=$(basename "$script_path")

        section+="### $script_name\n\n"
        section+="**Script ID:** \`$script_id\`  \n"
        section+="**Script:** \`$script_basename\`  \n"
        section+="**Command:** \`.devcontainer/additions/$script_basename --help\`\n\n"

        # Add help output
        local help_content
        help_content=$(format_help_output "$script_path")
        section+="$help_content\n"

        section+="---\n\n"
        ((script_count++))
    done

    log_info "    Processed $script_count scripts in category"

    echo -e "$section"
}

#------------------------------------------------------------------------------
# Main Generation Logic
#------------------------------------------------------------------------------

generate_manual() {
    local output=""

    # Discover all scripts
    discover_scripts

    # Count total scripts
    local total_scripts=$(count_total_scripts)
    local total_categories=$(count_categories)

    log_info "Found $total_scripts install scripts across $total_categories categories"

    if [[ $total_scripts -eq 0 ]]; then
        log_error "No install scripts found!"
        return 1
    fi

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # ===== Generate tools.md (overview) =====
    log_info "Generating tools.md (overview)..."
    output+="# Available Tools\n\n"
    output+="> **Auto-generated** | Last updated: $timestamp  \n"
    output+="> Regenerate with: \`.devcontainer/manage/generate-manual.sh\`\n\n"
    output+="All tools can be installed via \`dev-setup\` or by running the install script directly.\n\n"

    # Generate categories list
    log_info "Generating categories list..."
    output+="## Categories\n\n"
    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            local category_name=$(get_category_display_name "$category")
            local script_count=$(echo $scripts | wc -w | tr -d ' ')
            local tool_word="tools"
            [[ "$script_count" -eq 1 ]] && tool_word="tool"
            output+="- **$category_name** ($script_count $tool_word)\n"
        fi
    done
    output+="\n"

    # Generate tools summary table
    output+="## All Tools\n\n"
    output+="Click on a tool name to see detailed installation options.\n\n"
    log_info "Generating tools summary table..."
    output+="$(generate_tools_summary)"

    # ===== Generate tools-details.md (detailed help) =====
    local details=""
    log_info "Generating tools-details.md (detailed help)..."
    details+="# Tool Details\n\n"
    details+="> **Auto-generated** | Last updated: $timestamp  \n"
    details+="> Regenerate with: \`.devcontainer/manage/generate-manual.sh\`\n\n"
    details+="Detailed installation options for each tool. See [tools.md](tools.md) for the overview.\n\n"
    details+="---\n\n"

    # Generate table of contents for details
    log_info "Generating table of contents..."
    details+="$(generate_toc)"

    # Generate sections for each category
    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -n "$scripts" ]]; then
            details+="$(generate_category_section "$category")"
        fi
    done

    # Output result
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN - tools.md preview:"
        echo -e "$output" | head -50
        echo "..."
        log_info "DRY RUN - tools-details.md preview:"
        echo -e "$details" | head -50
        echo "..."
        log_info "Total length: tools.md=$(echo -e "$output" | wc -l) lines, tools-details.md=$(echo -e "$details" | wc -l) lines"
    else
        # Ensure docs directory exists
        mkdir -p "$(dirname "$OUTPUT_FILE")"

        # Write tools.md
        echo -e "$output" > "$OUTPUT_FILE"
        log_info "Written: $OUTPUT_FILE ($(wc -l < "$OUTPUT_FILE") lines)"

        # Write tools-details.md
        echo -e "$details" > "$OUTPUT_FILE_DETAILS"
        log_info "Written: $OUTPUT_FILE_DETAILS ($(wc -l < "$OUTPUT_FILE_DETAILS") lines)"

        # Update README.md
        update_readme
    fi

    return 0
}

#------------------------------------------------------------------------------
# Argument Parsing
#------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --category)
            if [[ -n "${2:-}" && "$2" != --* ]]; then
                FILTER_CATEGORY="$2"
                shift 2
            else
                log_error "Error: --category requires a value"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

#------------------------------------------------------------------------------
# Main Execution
#------------------------------------------------------------------------------

log_info "Starting manual generation..."

if [[ -n "$FILTER_CATEGORY" ]]; then
    log_info "Filtering to category: $FILTER_CATEGORY"
fi

if ! generate_manual; then
    log_error "Failed to generate manual"
    exit 1
fi

log_info "Manual generation complete!"

if [[ $DRY_RUN -eq 0 ]]; then
    log_info "You can view the manual at: $OUTPUT_FILE"
fi

exit 0
