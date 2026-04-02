#!/bin/bash
# File: .devcontainer/manage/lib/template-common.sh
# Description: Shared functions for template installer scripts
#              (dev-template.sh and dev-template-ai.sh).
#
# Usage: source "$SCRIPT_DIR/lib/template-common.sh"
#
# Required variables (must be set before sourcing):
#   CALLER_DIR     — caller's original working directory
#   ADDITIONS_DIR  — path to .devcontainer/additions/ (for tool install)
#
# Provided functions:
#   check_template_prerequisites   — verify dialog and git are installed
#   download_template_repo         — sparse-checkout only the needed folder
#   read_template_info             — read TEMPLATE_INFO from a template dir
#   scan_templates                 — scan templates and build arrays
#   select_template                — interactive (two-level menu) or direct selection
#   show_template_details_dialog   — show template details confirmation dialog
#   install_template_tools         — install devcontainer tools declared in TEMPLATE_TOOLS
#   replace_template_placeholder   — replace a placeholder in a single file
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Check prerequisites (dialog and git)
#------------------------------------------------------------------------------
check_template_prerequisites() {
  if ! command -v dialog >/dev/null 2>&1; then
    echo "❌ Error: dialog is not installed"
    echo "   sudo apt-get install dialog"
    exit 2
  fi
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ Error: git is not installed"
    exit 2
  fi
}

#------------------------------------------------------------------------------
# Download a specific folder from helpers-no/dev-templates using sparse-checkout
#
# Arguments:
#   $1 — templates subdirectory (e.g., "templates" or "ai-templates")
#
# Sets globals:
#   TEMP_DIR, TEMPLATE_REPO_DIR
#------------------------------------------------------------------------------
download_template_repo() {
  local templates_subdir="$1"
  local repo_url="https://github.com/helpers-no/dev-templates.git"

  TEMP_DIR=$(mktemp -d)
  TEMPLATE_REPO_DIR="$TEMP_DIR/repo"

  echo "📥 Fetching latest templates from GitHub..."
  echo "   Downloading: $templates_subdir/"
  echo ""

  if ! git clone --no-checkout --depth 1 "$repo_url" "$TEMPLATE_REPO_DIR" 2>/dev/null; then
    echo "❌ Failed to download templates"
    echo ""
    echo "   Repository: $repo_url"
    echo ""
    echo "   Possible causes:"
    echo "   - No internet connection"
    echo "   - GitHub is unreachable (firewall, proxy, DNS)"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  cd "$TEMPLATE_REPO_DIR"
  git sparse-checkout init --cone 2>/dev/null
  git sparse-checkout set "$templates_subdir" 2>/dev/null
  git checkout 2>/dev/null

  if [ ! -d "$TEMPLATE_REPO_DIR/$templates_subdir" ]; then
    echo "❌ Directory not found in repository"
    echo "   Expected: $templates_subdir/"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Templates fetched successfully"
  echo ""
}

#------------------------------------------------------------------------------
# Read TEMPLATE_INFO from a template directory
#
# Sets globals: INFO_NAME, INFO_DESCRIPTION, INFO_CATEGORY, INFO_ABSTRACT,
#               INFO_TOOLS, INFO_README
#------------------------------------------------------------------------------
read_template_info() {
  local template_dir="$1"
  local info_file="$template_dir/TEMPLATE_INFO"

  INFO_NAME=$(basename "$template_dir")
  INFO_DESCRIPTION="No description"
  INFO_CATEGORY="UNCATEGORIZED"
  INFO_ABSTRACT=""
  INFO_TOOLS=""
  INFO_README=""

  if [ -f "$info_file" ]; then
    unset TEMPLATE_NAME TEMPLATE_DESCRIPTION TEMPLATE_CATEGORY TEMPLATE_ABSTRACT TEMPLATE_TOOLS TEMPLATE_README
    source "$info_file"
    INFO_NAME="${TEMPLATE_NAME:-$INFO_NAME}"
    INFO_DESCRIPTION="${TEMPLATE_DESCRIPTION:-$INFO_DESCRIPTION}"
    INFO_CATEGORY="${TEMPLATE_CATEGORY:-$INFO_CATEGORY}"
    INFO_ABSTRACT="${TEMPLATE_ABSTRACT:-$INFO_ABSTRACT}"
    INFO_TOOLS="${TEMPLATE_TOOLS:-$INFO_TOOLS}"
    INFO_README="${TEMPLATE_README:-$INFO_README}"
    unset TEMPLATE_NAME TEMPLATE_DESCRIPTION TEMPLATE_CATEGORY TEMPLATE_ABSTRACT TEMPLATE_TOOLS TEMPLATE_README
  fi
}

#------------------------------------------------------------------------------
# Load category definitions from TEMPLATE_CATEGORIES file
#
# Arguments:
#   $1 — path to TEMPLATE_CATEGORIES file
#
# Sets globals:
#   CAT_IDS[]     — category IDs in display order
#   CAT_NAMES[]   — associative: ID → display name
#   CAT_EMOJIS[]  — associative: ID → emoji
#   CAT_COUNTS[]  — associative: ID → template count (initialized to 0)
#   CAT_TEMPLATES[] — associative: ID → space-separated template indices
#------------------------------------------------------------------------------
load_template_categories() {
  local cat_file="$1"

  declare -g -a CAT_IDS=()
  declare -g -A CAT_NAMES=()
  declare -g -A CAT_EMOJIS=()
  declare -g -A CAT_COUNTS=()
  declare -g -A CAT_TEMPLATES=()

  # Source the file to get TEMPLATE_CATEGORY_TABLE
  unset TEMPLATE_CATEGORY_TABLE
  source "$cat_file"

  while IFS='|' read -r order id name desc tags logo emoji; do
    [[ -z "$id" ]] && continue
    CAT_IDS+=("$id")
    CAT_NAMES["$id"]="$name"
    CAT_EMOJIS["$id"]="${emoji}"
    CAT_COUNTS["$id"]=0
    CAT_TEMPLATES["$id"]=""
  done <<< "$(echo "$TEMPLATE_CATEGORY_TABLE" | grep -v "^$")"
}

#------------------------------------------------------------------------------
# Scan templates and build arrays
#
# Arguments:
#   $1 — templates subdirectory (e.g., "templates" or "ai-templates")
#
# Sets globals:
#   TEMPLATE_DIRS[], TEMPLATE_NAMES[], TEMPLATE_DESCRIPTIONS[],
#   TEMPLATE_CATEGORIES[], TEMPLATE_ABSTRACTS[], TEMPLATE_TOOLS_LIST[],
#   TEMPLATE_README_LIST[]
#   Also populates CAT_COUNTS[] and CAT_TEMPLATES[]
#------------------------------------------------------------------------------
scan_templates() {
  local templates_subdir="$1"

  TEMPLATE_DIRS=()
  TEMPLATE_NAMES=()
  TEMPLATE_DESCRIPTIONS=()
  TEMPLATE_CATEGORIES=()
  TEMPLATE_ABSTRACTS=()
  TEMPLATE_TOOLS_LIST=()
  TEMPLATE_README_LIST=()

  # Load category definitions
  local cat_file="$TEMPLATE_REPO_DIR/$templates_subdir/TEMPLATE_CATEGORIES"
  load_template_categories "$cat_file"

  echo "📋 Scanning available templates..."
  for dir in "$TEMPLATE_REPO_DIR/$templates_subdir"/*; do
    [ -d "$dir" ] || continue
    # Skip TEMPLATE_CATEGORIES file (it's not a template directory)
    [ -f "$dir/TEMPLATE_INFO" ] || continue

    read_template_info "$dir"

    local idx=${#TEMPLATE_DIRS[@]}
    TEMPLATE_DIRS+=("$(basename "$dir")")
    TEMPLATE_NAMES+=("$INFO_NAME")
    TEMPLATE_DESCRIPTIONS+=("$INFO_DESCRIPTION")
    TEMPLATE_CATEGORIES+=("$INFO_CATEGORY")
    TEMPLATE_ABSTRACTS+=("$INFO_ABSTRACT")
    TEMPLATE_TOOLS_LIST+=("$INFO_TOOLS")
    TEMPLATE_README_LIST+=("$INFO_README")

    # Group by category
    local cat="$INFO_CATEGORY"
    if [[ -n "${CAT_COUNTS[$cat]+x}" ]]; then
      CAT_COUNTS["$cat"]=$((${CAT_COUNTS["$cat"]} + 1))
      CAT_TEMPLATES["$cat"]="${CAT_TEMPLATES["$cat"]} $idx"
    fi
  done

  if [ ${#TEMPLATE_DIRS[@]} -eq 0 ]; then
    echo "❌ No templates found"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Found ${#TEMPLATE_DIRS[@]} template(s)"
  echo ""
}

#------------------------------------------------------------------------------
# Show template category menu (first level)
#
# Arguments:
#   $1 — dialog title (e.g., "Project Templates")
#
# Returns: selected category ID via stdout
# Exit: non-zero if ESC/cancel
#------------------------------------------------------------------------------
show_template_category_menu() {
  local title="$1"
  local menu_options=()
  local option_num=1
  local displayed_categories=()

  for cat_id in "${CAT_IDS[@]}"; do
    local count=${CAT_COUNTS[$cat_id]:-0}
    [ "$count" -eq 0 ] && continue

    local emoji="${CAT_EMOJIS[$cat_id]}"
    local name="${CAT_NAMES[$cat_id]}"
    menu_options+=("$option_num" "$emoji $name" "$count template(s) available")
    displayed_categories+=("$cat_id")
    option_num=$((option_num + 1))
  done

  if [ ${#menu_options[@]} -eq 0 ]; then
    echo "❌ No template categories found" >&2
    return 1
  fi

  local choice
  choice=$(dialog --clear \
    --item-help \
    --title "$title" \
    --menu "Choose a category (ESC to cancel):" \
    20 80 12 \
    "${menu_options[@]}" \
    2>&1 >/dev/tty)

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  echo "${displayed_categories[$((choice - 1))]}"
}

#------------------------------------------------------------------------------
# Show templates in a category (second level)
#
# Arguments:
#   $1 — category ID
#   $2 — dialog title
#
# Sets globals on success: TEMPLATE_INDEX, SELECTED_TEMPLATE
# Returns: 0 if template selected and confirmed, 1 if ESC/back
#------------------------------------------------------------------------------
show_templates_in_category() {
  local category_id="$1"
  local title="$2"
  local cat_name="${CAT_NAMES[$category_id]}"

  while true; do
    # Build menu from templates in this category
    local menu_options=()
    local index_map=()
    local option_num=1

    for idx in ${CAT_TEMPLATES[$category_id]}; do
      menu_options+=("$option_num" "${TEMPLATE_NAMES[$idx]}" "${TEMPLATE_DESCRIPTIONS[$idx]}")
      index_map+=("$idx")
      option_num=$((option_num + 1))
    done

    local choice
    choice=$(dialog --clear \
      --item-help \
      --title "$title — $cat_name" \
      --menu "Choose a template (ESC to go back):" \
      20 80 12 \
      "${menu_options[@]}" \
      2>&1 >/dev/tty)

    if [[ $? -ne 0 ]]; then
      # ESC — go back to category menu
      return 1
    fi

    local selected_idx="${index_map[$((choice - 1))]}"

    # Show details and confirm
    if show_template_details_dialog "$selected_idx"; then
      TEMPLATE_INDEX=$selected_idx
      SELECTED_TEMPLATE="${TEMPLATE_DIRS[$selected_idx]}"
      return 0
    fi
    # "No" at details — loop back to template list
  done
}

#------------------------------------------------------------------------------
# Show template details confirmation dialog
#
# Arguments:
#   $1 — index into TEMPLATE_NAMES/etc. arrays
#
# Returns: dialog exit code (0 = yes, 1 = no)
#------------------------------------------------------------------------------
show_template_details_dialog() {
  local idx=$1
  local template_name="${TEMPLATE_NAMES[$idx]}"
  local template_desc="${TEMPLATE_DESCRIPTIONS[$idx]}"
  local template_category="${TEMPLATE_CATEGORIES[$idx]}"
  local template_abstract="${TEMPLATE_ABSTRACTS[$idx]:-}"

  local details=""
  details+="Name: $template_name\n\n"
  details+="Category: $template_category\n\n"
  details+="Description:\n$template_desc\n\n"

  if [ -n "$template_abstract" ]; then
    details+="About:\n$template_abstract\n\n"
  fi

  local template_tools="${TEMPLATE_TOOLS_LIST[$idx]:-}"
  if [ -n "$template_tools" ]; then
    details+="Tools to install:\n$template_tools\n\n"
  fi

  details+="Directory: ${TEMPLATE_DIRS[$idx]}"

  dialog --clear \
    --title "Template Details" \
    --yesno "$details\n\nDo you want to use this template?" \
    20 80

  return $?
}

#------------------------------------------------------------------------------
# Select template — interactive (two-level menu) or direct by name
#
# Arguments:
#   $1 — template name (empty for interactive)
#   $2 — templates subdirectory ("templates" or "ai-templates")
#   $3 — dialog title ("Project Templates" or "AI Workflow Templates")
#
# Sets globals: TEMPLATE_INDEX, SELECTED_TEMPLATE, TEMPLATE_PATH
#------------------------------------------------------------------------------
select_template() {
  local param_name="$1"
  local templates_subdir="$2"
  local title="$3"

  if [ -n "$param_name" ]; then
    # Direct selection by directory name
    SELECTED_TEMPLATE="$param_name"

    if [ ! -d "$TEMPLATE_REPO_DIR/$templates_subdir/$SELECTED_TEMPLATE" ]; then
      echo "❌ Template '$SELECTED_TEMPLATE' not found"
      echo ""
      echo "   Available templates:"
      for i in "${!TEMPLATE_DIRS[@]}"; do
        echo "   - ${TEMPLATE_DIRS[$i]}  (${TEMPLATE_NAMES[$i]})"
      done
      echo ""
      rm -rf "$TEMP_DIR"
      exit 2
    fi

    # Find index
    for i in "${!TEMPLATE_DIRS[@]}"; do
      if [ "${TEMPLATE_DIRS[$i]}" == "$SELECTED_TEMPLATE" ]; then
        TEMPLATE_INDEX=$i
        break
      fi
    done
  else
    # Interactive two-level menu
    while true; do
      local category
      if ! category=$(show_template_category_menu "$title"); then
        clear
        echo "ℹ️  Selection cancelled"
        rm -rf "$TEMP_DIR"
        exit 3
      fi

      if show_templates_in_category "$category" "$title"; then
        # TEMPLATE_INDEX and SELECTED_TEMPLATE set by show_templates_in_category
        break
      fi
      # ESC at template level — loop back to category menu
    done
  fi

  clear
  echo ""
  echo "✅ Selected: ${TEMPLATE_NAMES[$TEMPLATE_INDEX]}"

  if [ -n "${TEMPLATE_ABSTRACTS[$TEMPLATE_INDEX]:-}" ]; then
    echo ""
    echo "📝 About this template:"
    echo "   ${TEMPLATE_ABSTRACTS[$TEMPLATE_INDEX]}"
  fi
  echo ""

  TEMPLATE_PATH="$TEMPLATE_REPO_DIR/$templates_subdir/$SELECTED_TEMPLATE"
}

#------------------------------------------------------------------------------
# Install devcontainer tools declared in TEMPLATE_TOOLS
#------------------------------------------------------------------------------
install_template_tools() {
  local tools="$1"

  if [ -z "$tools" ]; then
    return 0
  fi

  echo "🔧 Installing required development tools..."
  echo ""

  local installed=0
  local failed=0
  local skipped=0

  for tool_id in $tools; do
    local script="install-${tool_id}.sh"
    local script_path="$ADDITIONS_DIR/$script"

    if [ ! -f "$script_path" ]; then
      echo "   ⚠️  Tool '$tool_id' not found ($script)"
      skipped=$((skipped + 1))
      continue
    fi

    echo "   📦 Installing $tool_id..."
    if bash "$script_path"; then
      installed=$((installed + 1))
    else
      echo "   ⚠️  Failed to install $tool_id — you can install it later with dev-setup"
      failed=$((failed + 1))
    fi
    echo ""
  done

  echo "🔧 Tool installation summary: $installed installed, $failed failed, $skipped not found"
  echo ""
}

#------------------------------------------------------------------------------
# Replace a placeholder pattern in a single file
#------------------------------------------------------------------------------
replace_template_placeholder() {
  local file="$1"
  shift
  local sed_args=()
  for expr in "$@"; do
    sed_args+=(-e "$expr")
  done

  if [ ! -f "$file" ]; then
    return 0
  fi

  local temp_file
  temp_file=$(mktemp)

  if sed "${sed_args[@]}" "$file" > "$temp_file"; then
    if cat "$temp_file" > "$file"; then
      echo "   ✅ Updated $(basename "$file")"
      rm -f "$temp_file"
      return 0
    fi
  fi

  echo "   ❌ Failed to update $(basename "$file")"
  rm -f "$temp_file"
  return 1
}
