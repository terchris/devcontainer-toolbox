#!/bin/bash
# file: .devcontainer/manage/dev-docs.sh
#
# Generates comprehensive documentation by running all install scripts with --help
# Output: docs/tools.md (overview), docs/tools-details.md (detailed), README.md (updated)
#
# Usage:
#   dev-docs                          # Generate full manual
#   dev-docs --help                   # Show this help
#   dev-docs --dry-run                # Preview without writing
#   dev-docs --category LANGUAGE_DEV  # Only specific category
#   dev-docs --verbose                # Show detailed progress

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-docs"
SCRIPT_NAME="Generate Docs"
SCRIPT_DESCRIPTION="Generate documentation (tools.md, commands.md)"
SCRIPT_CATEGORY="CONTRIBUTOR_TOOLS"
SCRIPT_CHECK_COMMAND="true"

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly SCRIPT_DIR
readonly MANAGE_DIR="${SCRIPT_DIR}"
readonly ADDITIONS_DIR="${SCRIPT_DIR}/../additions"
readonly WORKSPACE_ROOT="${SCRIPT_DIR}/../.."
readonly OUTPUT_FILE="${WORKSPACE_ROOT}/docs/tools.md"
readonly OUTPUT_FILE_DETAILS="${WORKSPACE_ROOT}/docs/tools-details.md"
readonly OUTPUT_FILE_COMMANDS="${WORKSPACE_ROOT}/docs/commands.md"
readonly README_FILE="${WORKSPACE_ROOT}/README.md"

# Source logging library
# shellcheck source=/dev/null
source "${ADDITIONS_DIR}/lib/logging.sh"

# Source categories library
# shellcheck source=/dev/null
source "${ADDITIONS_DIR}/lib/categories.sh"

# Source component scanner library (for scan_manage_scripts)
# shellcheck source=/dev/null
source "${ADDITIONS_DIR}/lib/component-scanner.sh"

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
dev-docs - Generate comprehensive documentation

Usage:
  dev-docs                          # Generate full documentation
  dev-docs --help                   # Show this help
  dev-docs --dry-run                # Preview without writing files
  dev-docs --category LANGUAGE_DEV  # Only specific category
  dev-docs --verbose                # Show detailed progress

Output:
  docs/tools.md         - Overview table with links to tool details
  docs/tools-details.md - Detailed help for each install tool
  docs/commands.md      - Command reference (dev-* commands)
  README.md             - Tools summary (between markers)

Categories:
  LANGUAGE_DEV    - $(get_category_short_description "LANGUAGE_DEV")
  AI_TOOLS        - $(get_category_short_description "AI_TOOLS")
  CLOUD_TOOLS     - $(get_category_short_description "CLOUD_TOOLS")
  DATA_ANALYTICS  - $(get_category_short_description "DATA_ANALYTICS")
  INFRA_CONFIG    - $(get_category_short_description "INFRA_CONFIG")

Examples:
  # Generate full documentation
  dev-docs

  # Preview what would be generated
  dev-docs --dry-run

  # Only generate development tools section
  dev-docs --category LANGUAGE_DEV --verbose

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
    help_output=$(echo "$help_output" | grep -v "declare: -A: invalid option" | grep -v "declare: usage:" | grep -v "syntax error: invalid arithmetic operator" | grep -v "Logging to:")

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
# Commands.md Generation (manage scripts)
#------------------------------------------------------------------------------

# Generate commands.md content from manage script metadata
generate_commands_md() {
    local content=""

    log_info "Generating commands.md..."

    content+="# Commands Reference\n\n"
    content+="> **Auto-generated** - Do not edit manually  \n"
    content+="> Regenerate with: \`dev-docs\`\n\n"
    content+="All commands available inside the devcontainer. Type \`dev-\` and press Tab to see them.\n\n"

    # Build arrays from scan_manage_scripts output
    declare -a cmd_names=()
    declare -a cmd_ids=()
    declare -a cmd_descriptions=()
    declare -a cmd_categories=()
    declare -a cmd_basenames=()

    while IFS=$'\t' read -r basename script_id name desc category check; do
        cmd_basenames+=("$basename")
        cmd_ids+=("$script_id")
        cmd_names+=("$name")
        cmd_descriptions+=("$desc")
        cmd_categories+=("$category")
    done < <(scan_manage_scripts "$MANAGE_DIR")

    # Add dev-setup manually (excluded from scanner to avoid recursion)
    cmd_basenames+=("dev-setup.sh")
    cmd_ids+=("dev-setup")
    cmd_names+=("Setup Menu")
    cmd_descriptions+=("Interactive menu for installing tools and managing services")
    cmd_categories+=("SYSTEM_COMMANDS")

    log_info "  Found ${#cmd_ids[@]} manage commands"

    # Quick Reference table
    content+="## Quick Reference\n\n"
    content+="| Command | Description |\n"
    content+="|---------|-------------|\n"

    # Sort by category, then by name within category
    # First SYSTEM_COMMANDS, then CONTRIBUTOR_TOOLS
    for cat in "SYSTEM_COMMANDS" "CONTRIBUTOR_TOOLS"; do
        for i in "${!cmd_ids[@]}"; do
            if [[ "${cmd_categories[$i]}" == "$cat" ]]; then
                local cmd_id="${cmd_ids[$i]}"
                local desc="${cmd_descriptions[$i]}"
                # Create anchor from command id
                local anchor=$(echo "$cmd_id" | tr -d '[:space:]')
                content+="| [\`$cmd_id\`](#$anchor) | $desc |\n"
            fi
        done
    done
    content+="\n---\n\n"

    # Detailed sections by category
    for cat in "SYSTEM_COMMANDS" "CONTRIBUTOR_TOOLS"; do
        local cat_name=$(get_category_display_name "$cat")
        local has_commands=0

        # Check if category has any commands
        for i in "${!cmd_ids[@]}"; do
            if [[ "${cmd_categories[$i]}" == "$cat" ]]; then
                has_commands=1
                break
            fi
        done

        [[ $has_commands -eq 0 ]] && continue

        content+="## $cat_name\n\n"

        for i in "${!cmd_ids[@]}"; do
            if [[ "${cmd_categories[$i]}" == "$cat" ]]; then
                local cmd_id="${cmd_ids[$i]}"
                local cmd_name="${cmd_names[$i]}"
                local desc="${cmd_descriptions[$i]}"
                local basename="${cmd_basenames[$i]}"

                content+="### $cmd_id\n\n"
                content+="$desc\n\n"
                content+="\`\`\`bash\n"
                content+="$cmd_id\n"

                # Add common flags if applicable
                case "$cmd_id" in
                    dev-update)
                        content+="$cmd_id --force   # Force update even if same version\n"
                        ;;
                    dev-services)
                        content+="$cmd_id status          # Show status of all services\n"
                        content+="$cmd_id start <name>    # Start a service\n"
                        content+="$cmd_id stop <name>     # Stop a service\n"
                        content+="$cmd_id logs <name>     # View service logs\n"
                        ;;
                    dev-check)
                        content+="$cmd_id --show    # Show current configuration\n"
                        ;;
                esac

                content+="\`\`\`\n\n"
            fi
        done

        content+="---\n\n"
    done

    # Add section about running install scripts directly
    content+="## Running Install Scripts Directly\n\n"
    content+="All install scripts can also be run directly:\n\n"
    content+="\`\`\`bash\n"
    content+="# Show help for a script\n"
    content+=".devcontainer/additions/install-dev-python.sh --help\n\n"
    content+="# Install with specific version\n"
    content+=".devcontainer/additions/install-dev-golang.sh --version 1.22.0\n\n"
    content+="# Uninstall\n"
    content+=".devcontainer/additions/install-dev-golang.sh --uninstall\n"
    content+="\`\`\`\n\n"
    content+="Use \`dev-setup\` for the interactive menu, or run scripts directly for automation.\n"

    echo -e "$content"
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

    # ===== Generate tools.md (overview) =====
    log_info "Generating tools.md (overview)..."
    output+="# Available Tools\n\n"
    output+="> **Auto-generated** - Do not edit manually  \n"
    output+="> Regenerate with: \`dev-docs\`\n\n"
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
    details+="> **Auto-generated** - Do not edit manually  \n"
    details+="> Regenerate with: \`dev-docs\`\n\n"
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

    # ===== Generate commands.md (manage scripts) =====
    local commands
    commands=$(generate_commands_md)

    # Output result
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN - tools.md preview:"
        echo -e "$output" | head -50
        echo "..."
        log_info "DRY RUN - tools-details.md preview:"
        echo -e "$details" | head -50
        echo "..."
        log_info "DRY RUN - commands.md preview:"
        echo -e "$commands" | head -50
        echo "..."
        log_info "Total length: tools.md=$(echo -e "$output" | wc -l) lines, tools-details.md=$(echo -e "$details" | wc -l) lines, commands.md=$(echo -e "$commands" | wc -l) lines"
    else
        # Ensure docs directory exists
        mkdir -p "$(dirname "$OUTPUT_FILE")"

        # Write tools.md
        echo -e "$output" > "$OUTPUT_FILE"
        log_info "Written: $OUTPUT_FILE ($(wc -l < "$OUTPUT_FILE") lines)"

        # Write tools-details.md
        echo -e "$details" > "$OUTPUT_FILE_DETAILS"
        log_info "Written: $OUTPUT_FILE_DETAILS ($(wc -l < "$OUTPUT_FILE_DETAILS") lines)"

        # Write commands.md
        echo -e "$commands" > "$OUTPUT_FILE_COMMANDS"
        log_info "Written: $OUTPUT_FILE_COMMANDS ($(wc -l < "$OUTPUT_FILE_COMMANDS") lines)"

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
