#!/bin/bash
# file: .devcontainer/manage/dev-docs.sh
#
# Generates comprehensive documentation by running all install scripts with --help
# Output: website/docs/tools/index.md (overview), website/docs/tools-details.md (detailed), README.md (updated)
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
readonly OUTPUT_FILE="${WORKSPACE_ROOT}/website/docs/tools/index.md"
readonly OUTPUT_FILE_DETAILS="${WORKSPACE_ROOT}/website/docs/tools-details.md"
readonly OUTPUT_FILE_COMMANDS="${WORKSPACE_ROOT}/website/docs/commands.md"
readonly README_FILE="${WORKSPACE_ROOT}/README.md"
readonly TOOLS_JSON="${WORKSPACE_ROOT}/website/src/data/tools.json"
readonly CATEGORIES_JSON="${WORKSPACE_ROOT}/website/src/data/categories.json"

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
  website/docs/tools/index.md  - Overview table with links to tool details
  website/docs/tools-details.md - Detailed help for each install tool
  website/docs/commands.md     - Command reference (dev-* commands)
  website/src/data/tools.json  - Tool metadata for React components
  website/src/data/categories.json - Category metadata for React components
  README.md                    - Tools summary (between markers)

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

# Detect script type from filename prefix
# Args: $1=script_path
# Returns: install, config, service, or unknown
detect_script_type() {
    local script_path=$1
    local basename=$(basename "$script_path")

    if [[ "$basename" == install-* ]]; then
        echo "install"
    elif [[ "$basename" == config-* ]]; then
        echo "config"
    elif [[ "$basename" == service-* ]] || [[ "$basename" == install-srv-* ]]; then
        echo "service"
    else
        echo "unknown"
    fi
}

# Extract a metadata field from a script file
# Args: $1=script_path, $2=field_name
# Returns: field value or empty string
extract_script_field() {
    local script_path=$1
    local field_name=$2

    # Extract value between quotes (handles both " and ')
    local value=$(grep "^${field_name}=" "$script_path" | head -1 | sed 's/^[^=]*=["'"'"']\{0,1\}//' | sed 's/["'"'"']\{0,1\}$//')
    echo "$value"
}

# Extract all extended metadata from a script
# Args: $1=script_path
# Sets global variables: _SCRIPT_TAGS, _SCRIPT_ABSTRACT, _SCRIPT_LOGO, _SCRIPT_WEBSITE, _SCRIPT_SUMMARY, _SCRIPT_RELATED
extract_extended_metadata() {
    local script_path=$1

    _SCRIPT_TAGS=$(extract_script_field "$script_path" "SCRIPT_TAGS")
    _SCRIPT_ABSTRACT=$(extract_script_field "$script_path" "SCRIPT_ABSTRACT")
    _SCRIPT_LOGO=$(extract_script_field "$script_path" "SCRIPT_LOGO")
    _SCRIPT_WEBSITE=$(extract_script_field "$script_path" "SCRIPT_WEBSITE")
    _SCRIPT_SUMMARY=$(extract_script_field "$script_path" "SCRIPT_SUMMARY")
    _SCRIPT_RELATED=$(extract_script_field "$script_path" "SCRIPT_RELATED")
}

# Escape string for JSON output
json_escape() {
    local str=$1
    # Escape backslashes, double quotes, and control characters
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Convert space-separated string to JSON array
# Args: $1=space-separated string
# Returns: JSON array string like ["item1","item2"]
to_json_array() {
    local input=$1
    if [[ -z "$input" ]]; then
        echo "[]"
        return
    fi

    local result="["
    local first=1
    for item in $input; do
        if [[ $first -eq 1 ]]; then
            first=0
        else
            result+=","
        fi
        result+="\"$(json_escape "$item")\""
    done
    result+="]"
    echo "$result"
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
            local anchor=$(echo "$category_name" | tr '[:upper:]' '[:lower:]' | tr -d '&,' | tr -s ' ' | tr ' ' '-')
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

#------------------------------------------------------------------------------
# JSON Generation Functions
#------------------------------------------------------------------------------

# Generate tools.json with all tool metadata
generate_tools_json() {
    log_info "Generating tools.json..."

    local json="{\n  \"tools\": ["
    local first_tool=1

    for category in "${CATEGORY_ORDER[@]}"; do
        local scripts=$(get_category_scripts "$category")
        if [[ -z "$scripts" ]]; then
            continue
        fi

        for script_path in $scripts; do
            # Extract core metadata
            local script_id=$(extract_script_field "$script_path" "SCRIPT_ID")
            local script_name=$(extract_script_field "$script_path" "SCRIPT_NAME")
            local script_desc=$(extract_script_field "$script_path" "SCRIPT_DESCRIPTION")
            local script_category=$(extract_script_field "$script_path" "SCRIPT_CATEGORY")

            # Extract extended metadata
            extract_extended_metadata "$script_path"

            # Detect script type
            local script_type=$(detect_script_type "$script_path")

            # Add comma before tool (except first)
            if [[ $first_tool -eq 1 ]]; then
                first_tool=0
            else
                json+=","
            fi

            # Build JSON object for this tool
            json+="\n    {"
            json+="\n      \"id\": \"$(json_escape "$script_id")\","
            json+="\n      \"type\": \"$script_type\","
            json+="\n      \"name\": \"$(json_escape "$script_name")\","
            json+="\n      \"description\": \"$(json_escape "$script_desc")\","
            json+="\n      \"category\": \"$script_category\","
            json+="\n      \"tags\": $(to_json_array "$_SCRIPT_TAGS"),"
            json+="\n      \"abstract\": \"$(json_escape "$_SCRIPT_ABSTRACT")\""

            # Add optional fields only if they have values
            if [[ -n "$_SCRIPT_LOGO" ]]; then
                json+=",\n      \"logo\": \"$(json_escape "$_SCRIPT_LOGO")\""
            fi
            if [[ -n "$_SCRIPT_WEBSITE" ]]; then
                json+=",\n      \"website\": \"$(json_escape "$_SCRIPT_WEBSITE")\""
            fi
            if [[ -n "$_SCRIPT_SUMMARY" ]]; then
                json+=",\n      \"summary\": \"$(json_escape "$_SCRIPT_SUMMARY")\""
            fi
            if [[ -n "$_SCRIPT_RELATED" ]]; then
                json+=",\n      \"related\": $(to_json_array "$_SCRIPT_RELATED")"
            fi

            json+="\n    }"
        done
    done

    json+="\n  ]\n}"

    echo -e "$json"
}

# Generate categories.json with all category metadata
generate_categories_json() {
    log_info "Generating categories.json..."

    local json="{\n  \"categories\": ["
    local first_cat=1

    for category_id in "${CATEGORY_ORDER[@]}"; do
        # Get category metadata using helper functions from categories.sh
        local cat_name=$(get_category_name "$category_id")
        local cat_order=$(get_category_order "$category_id")
        local cat_abstract=$(get_category_abstract "$category_id")
        local cat_summary=$(get_category_summary "$category_id")
        local cat_tags=$(get_category_tags "$category_id")
        local cat_logo=$(get_category_logo "$category_id")

        # Add comma before category (except first)
        if [[ $first_cat -eq 1 ]]; then
            first_cat=0
        else
            json+=","
        fi

        # Build JSON object for this category
        json+="\n    {"
        json+="\n      \"id\": \"$category_id\","
        json+="\n      \"name\": \"$(json_escape "$cat_name")\","
        json+="\n      \"order\": $cat_order,"
        json+="\n      \"tags\": $(to_json_array "$cat_tags"),"
        json+="\n      \"abstract\": \"$(json_escape "$cat_abstract")\","
        json+="\n      \"summary\": \"$(json_escape "$cat_summary")\""

        # Add optional logo field only if it has a value
        if [[ -n "$cat_logo" ]]; then
            json+=",\n      \"logo\": \"$(json_escape "$cat_logo")\""
        fi

        json+="\n    }"
    done

    json+="\n  ]\n}"

    echo -e "$json"
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
    # Skip lines until we find the second separator line (after the logging header)
    # The help output starts with a separator line containing the script name
    help_output=$(echo "$help_output" | awk '/^━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━/{count++; if(count==2){found=1; next}} found')

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

        # Extract extended metadata
        extract_extended_metadata "$script_path"

        # Show abstract as lead paragraph if available
        if [[ -n "$_SCRIPT_ABSTRACT" ]]; then
            section+="*$_SCRIPT_ABSTRACT*\n\n"
        fi

        section+="**Script ID:** \`$script_id\`  \n"
        section+="**Script:** \`$script_basename\`  \n"

        # Add website link if available
        if [[ -n "$_SCRIPT_WEBSITE" ]]; then
            section+="**Website:** [$_SCRIPT_WEBSITE]($_SCRIPT_WEBSITE)  \n"
        fi

        section+="**Command:** \`.devcontainer/additions/$script_basename --help\`\n\n"

        # Add summary if available (more detailed than abstract)
        if [[ -n "$_SCRIPT_SUMMARY" ]]; then
            section+="$_SCRIPT_SUMMARY\n\n"
        fi

        # Add tags if available
        if [[ -n "$_SCRIPT_TAGS" ]]; then
            local tags_formatted=$(echo "$_SCRIPT_TAGS" | tr ' ' ', ')
            section+="**Tags:** $tags_formatted\n\n"
        fi

        # Add related tools if available
        if [[ -n "$_SCRIPT_RELATED" ]]; then
            local related_links=""
            for rel_id in $_SCRIPT_RELATED; do
                if [[ -n "$related_links" ]]; then
                    related_links+=", "
                fi
                related_links+="\`$rel_id\`"
            done
            section+="**Related:** $related_links\n\n"
        fi

        # Add help output in collapsible section
        local help_content
        help_content=$(format_help_output "$script_path")
        section+="<details>\n<summary>Installation details (click to expand)</summary>\n\n"
        section+="$help_content\n"
        section+="</details>\n\n"

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

    content+="---\n"
    content+="sidebar_position: 4\n"
    content+="---\n\n"
    content+="# Commands Reference\n\n"
    content+=":::note Auto-generated\n"
    content+="This page is auto-generated. Regenerate with: \`dev-docs\`\n"
    content+=":::\n\n"
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
    log_info "Generating tools/index.md (overview)..."
    output+="---\n"
    output+="sidebar_position: 7\n"
    output+="sidebar_label: Tools\n"
    output+="---\n\n"
    output+="# Available Tools\n\n"
    output+=":::note Auto-generated\n"
    output+="This page is auto-generated. Regenerate with: \`dev-docs\`\n"
    output+=":::\n\n"
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
    details+="---\n"
    details+="sidebar_position: 8\n"
    details+="sidebar_label: Tool Details\n"
    details+="---\n\n"
    details+="# Tool Details\n\n"
    details+=":::note Auto-generated\n"
    details+="This page is auto-generated. Regenerate with: \`dev-docs\`\n"
    details+=":::\n\n"
    details+="Detailed installation options for each tool. See [Available Tools](tools) for the overview.\n\n"
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

    # ===== Generate JSON files for React components =====
    local tools_json
    tools_json=$(generate_tools_json)

    local categories_json
    categories_json=$(generate_categories_json)

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
        log_info "DRY RUN - tools.json preview:"
        echo -e "$tools_json" | head -30
        echo "..."
        log_info "DRY RUN - categories.json preview:"
        echo -e "$categories_json" | head -30
        echo "..."
        log_info "Total length: tools.md=$(echo -e "$output" | wc -l) lines, tools-details.md=$(echo -e "$details" | wc -l) lines, commands.md=$(echo -e "$commands" | wc -l) lines"
    else
        # Ensure docs directory exists
        mkdir -p "$(dirname "$OUTPUT_FILE")"

        # Ensure data directory exists for JSON files
        mkdir -p "$(dirname "$TOOLS_JSON")"

        # Write tools.md
        echo -e "$output" > "$OUTPUT_FILE"
        log_info "Written: $OUTPUT_FILE ($(wc -l < "$OUTPUT_FILE") lines)"

        # Write tools-details.md
        echo -e "$details" > "$OUTPUT_FILE_DETAILS"
        log_info "Written: $OUTPUT_FILE_DETAILS ($(wc -l < "$OUTPUT_FILE_DETAILS") lines)"

        # Write commands.md
        echo -e "$commands" > "$OUTPUT_FILE_COMMANDS"
        log_info "Written: $OUTPUT_FILE_COMMANDS ($(wc -l < "$OUTPUT_FILE_COMMANDS") lines)"

        # Write tools.json
        echo -e "$tools_json" > "$TOOLS_JSON"
        log_info "Written: $TOOLS_JSON"

        # Write categories.json
        echo -e "$categories_json" > "$CATEGORIES_JSON"
        log_info "Written: $CATEGORIES_JSON"

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
