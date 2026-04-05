#!/bin/bash
# File: .devcontainer/manage/lib/template-common.sh
# Description: Shared functions for the unified dev-template installer.
#              Fetches template-registry.json, builds menus with jq,
#              downloads only the selected template via sparse-checkout.
#
# Usage: source "$SCRIPT_DIR/lib/template-common.sh"
#
# Required variables (must be set before sourcing):
#   CALLER_DIR     — caller's original working directory
#   ADDITIONS_DIR  — path to .devcontainer/additions/ (for tool install)
#------------------------------------------------------------------------------

# Registry URLs
REGISTRY_PRIMARY="https://tmp.sovereignsky.no/data/template-registry.json"
REGISTRY_FALLBACK="https://raw.githubusercontent.com/helpers-no/dev-templates/main/website/src/data/template-registry.json"
REPO_URL="https://github.com/helpers-no/dev-templates.git"

#------------------------------------------------------------------------------
# Check prerequisites (dialog, git, jq)
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
  if ! command -v jq >/dev/null 2>&1; then
    echo "❌ Error: jq is not installed"
    exit 2
  fi
}

#------------------------------------------------------------------------------
# Fetch template-registry.json
#
# Sets globals:
#   REGISTRY_FILE — path to downloaded registry JSON
#   TEMP_DIR      — temp directory (created here)
#------------------------------------------------------------------------------
fetch_registry() {
  TEMP_DIR=$(mktemp -d)
  REGISTRY_FILE="$TEMP_DIR/registry.json"

  echo "📥 Fetching template registry..."

  if curl -sfL "$REGISTRY_PRIMARY" -o "$REGISTRY_FILE" 2>/dev/null && [ -s "$REGISTRY_FILE" ] && jq empty "$REGISTRY_FILE" 2>/dev/null; then
    echo "   Source: $REGISTRY_PRIMARY"
  elif curl -sfL "$REGISTRY_FALLBACK" -o "$REGISTRY_FILE" 2>/dev/null && [ -s "$REGISTRY_FILE" ] && jq empty "$REGISTRY_FILE" 2>/dev/null; then
    echo "   Source: $REGISTRY_FALLBACK (fallback)"
  else
    echo "❌ Failed to fetch template registry"
    echo ""
    echo "   Tried:"
    echo "   - $REGISTRY_PRIMARY"
    echo "   - $REGISTRY_FALLBACK"
    echo ""
    echo "   Possible causes:"
    echo "   - No internet connection"
    echo "   - GitHub is unreachable"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Registry fetched"
  echo ""
}

#------------------------------------------------------------------------------
# Parse registry — build arrays for categories and templates
#
# Arguments:
#   $1 — context filter ("dct" or "uis")
#
# Sets globals:
#   CAT_IDS[], CAT_NAMES[], CAT_EMOJIS[], CAT_COUNTS[], CAT_TEMPLATES[]
#   TEMPLATE_IDS[], TEMPLATE_NAMES[], TEMPLATE_DESCRIPTIONS[],
#   TEMPLATE_CATEGORIES[], TEMPLATE_ABSTRACTS[], TEMPLATE_TOOLS_LIST[],
#   TEMPLATE_README_LIST[], TEMPLATE_FOLDERS[], TEMPLATE_INSTALL_TYPES[]
#------------------------------------------------------------------------------
parse_registry() {
  local context="$1"

  # Category arrays
  declare -g -a CAT_IDS=()
  declare -g -A CAT_NAMES=()
  declare -g -A CAT_EMOJIS=()
  declare -g -A CAT_COUNTS=()
  declare -g -A CAT_TEMPLATES=()

  # Template arrays
  TEMPLATE_IDS=()
  TEMPLATE_NAMES=()
  TEMPLATE_DESCRIPTIONS=()
  TEMPLATE_CATEGORIES=()
  TEMPLATE_ABSTRACTS=()
  TEMPLATE_TOOLS_LIST=()
  TEMPLATE_README_LIST=()
  TEMPLATE_FOLDERS=()
  TEMPLATE_INSTALL_TYPES=()

  echo "📋 Loading templates..."

  # Parse categories (sorted by order)
  while IFS=$'\t' read -r cat_id cat_name cat_emoji; do
    CAT_IDS+=("$cat_id")
    CAT_NAMES["$cat_id"]="$cat_name"
    CAT_EMOJIS["$cat_id"]="$cat_emoji"
    CAT_COUNTS["$cat_id"]=0
    CAT_TEMPLATES["$cat_id"]=""
  done < <(jq -r --arg ctx "$context" \
    '.categories[] | select(.context == $ctx) | [.id, .name, .emoji] | @tsv' \
    "$REGISTRY_FILE" | sort -t$'\t' -k1,1)

  # Parse templates
  # Note: use "//" as empty-field replacement to prevent bash read from collapsing empty tab fields
  while IFS=$'\t' read -r t_id t_name t_desc t_cat t_abstract t_tools t_readme t_folder t_install_type; do
    # Replace sentinel back to empty
    [ "$t_tools" = "-" ] && t_tools=""
    [ "$t_readme" = "-" ] && t_readme=""
    [ "$t_abstract" = "-" ] && t_abstract=""

    local idx=${#TEMPLATE_IDS[@]}
    TEMPLATE_IDS+=("$t_id")
    TEMPLATE_NAMES+=("$t_name")
    TEMPLATE_DESCRIPTIONS+=("$t_desc")
    TEMPLATE_CATEGORIES+=("$t_cat")
    TEMPLATE_ABSTRACTS+=("$t_abstract")
    TEMPLATE_TOOLS_LIST+=("$t_tools")
    TEMPLATE_README_LIST+=("$t_readme")
    TEMPLATE_FOLDERS+=("$t_folder")
    TEMPLATE_INSTALL_TYPES+=("$t_install_type")

    # Group by category
    if [[ -n "${CAT_COUNTS[$t_cat]+x}" ]]; then
      CAT_COUNTS["$t_cat"]=$((${CAT_COUNTS["$t_cat"]} + 1))
      CAT_TEMPLATES["$t_cat"]="${CAT_TEMPLATES["$t_cat"]} $idx"
    fi
  done < <(jq -r --arg ctx "$context" \
    'def nonempty: if . == "" or . == null then "-" else . end;
     .templates[] | select(.context == $ctx) | [.id, .name, .description, .category, (.abstract | nonempty), (.tools | nonempty), (.readme | nonempty), .folder, .install_type] | @tsv' \
    "$REGISTRY_FILE")

  if [ ${#TEMPLATE_IDS[@]} -eq 0 ]; then
    echo "❌ No templates found for context '$context'"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Found ${#TEMPLATE_IDS[@]} template(s) in ${#CAT_IDS[@]} categories"
  echo ""
}

#------------------------------------------------------------------------------
# Show template category menu (first level)
#
# Arguments:
#   $1 — dialog title
#
# Returns: selected category ID via stdout
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
# Sets globals on success: TEMPLATE_INDEX
# Returns: 0 if confirmed, 1 if ESC/back
#------------------------------------------------------------------------------
show_templates_in_category() {
  local category_id="$1"
  local title="$2"
  local cat_name="${CAT_NAMES[$category_id]}"

  while true; do
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
      return 1
    fi

    local selected_idx="${index_map[$((choice - 1))]}"

    if show_template_details_dialog "$selected_idx"; then
      TEMPLATE_INDEX=$selected_idx
      return 0
    fi
  done
}

#------------------------------------------------------------------------------
# Show template details confirmation dialog
#------------------------------------------------------------------------------
show_template_details_dialog() {
  local idx=$1
  local details=""
  details+="Name: ${TEMPLATE_NAMES[$idx]}\n\n"
  details+="Category: ${TEMPLATE_CATEGORIES[$idx]}\n\n"
  details+="Description:\n${TEMPLATE_DESCRIPTIONS[$idx]}\n\n"

  if [ -n "${TEMPLATE_ABSTRACTS[$idx]:-}" ]; then
    details+="About:\n${TEMPLATE_ABSTRACTS[$idx]}\n\n"
  fi

  local tools="${TEMPLATE_TOOLS_LIST[$idx]:-}"
  if [ -n "$tools" ]; then
    details+="Tools to install:\n$tools\n\n"
  fi

  details+="Install type: ${TEMPLATE_INSTALL_TYPES[$idx]}"

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
#   $1 — template ID (empty for interactive)
#   $2 — dialog title
#
# Sets globals: TEMPLATE_INDEX, TEMPLATE_PATH
#------------------------------------------------------------------------------
select_template() {
  local param_name="$1"
  local title="$2"

  if [ -n "$param_name" ]; then
    # Direct selection by ID
    local found=false
    for i in "${!TEMPLATE_IDS[@]}"; do
      if [ "${TEMPLATE_IDS[$i]}" == "$param_name" ]; then
        TEMPLATE_INDEX=$i
        found=true
        break
      fi
    done

    if ! $found; then
      echo "❌ Template '$param_name' not found"
      echo ""
      echo "   Available templates:"
      for i in "${!TEMPLATE_IDS[@]}"; do
        echo "   - ${TEMPLATE_IDS[$i]}  (${TEMPLATE_NAMES[$i]})"
      done
      echo ""
      rm -rf "$TEMP_DIR"
      exit 2
    fi
  else
    # Interactive two-level menu
    while true; do
      local category
      if ! category=$(show_template_category_menu "$title"); then
        clear 2>/dev/null || true
        echo "ℹ️  Selection cancelled"
        rm -rf "$TEMP_DIR"
        exit 3
      fi

      if show_templates_in_category "$category" "$title"; then
        break
      fi
    done
  fi

  clear 2>/dev/null || true
  echo ""
  echo "✅ Selected: ${TEMPLATE_NAMES[$TEMPLATE_INDEX]}"

  if [ -n "${TEMPLATE_ABSTRACTS[$TEMPLATE_INDEX]:-}" ]; then
    echo ""
    echo "📝 About this template:"
    echo "   ${TEMPLATE_ABSTRACTS[$TEMPLATE_INDEX]}"
  fi
  echo ""
}

#------------------------------------------------------------------------------
# Download only the selected template via sparse-checkout
#
# Sets globals: TEMPLATE_PATH
#------------------------------------------------------------------------------
download_selected_template() {
  local folder="${TEMPLATE_FOLDERS[$TEMPLATE_INDEX]}"
  local repo_dir="$TEMP_DIR/repo"

  echo "📥 Downloading template: $folder/"

  if ! git clone --no-checkout --depth 1 "$REPO_URL" "$repo_dir" 2>/dev/null; then
    echo "❌ Failed to download template"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  cd "$repo_dir"
  git sparse-checkout init --cone 2>/dev/null
  git sparse-checkout set "$folder" 2>/dev/null
  git checkout 2>/dev/null

  if [ ! -d "$repo_dir/$folder" ]; then
    echo "❌ Template folder not found after download: $folder/"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  TEMPLATE_PATH="$repo_dir/$folder"
  echo "✅ Template downloaded"
  echo ""
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
