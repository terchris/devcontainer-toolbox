#!/bin/bash
# File: .devcontainer/manage/lib/template-common.sh
# Description: Shared functions for template installer scripts
#              (dev-template.sh and dev-template-ai.sh).
#
# Usage: source "$SCRIPT_DIR/lib/template-common.sh"
#
# Required variables (must be set before sourcing):
#   CALLER_DIR   — caller's original working directory
#
# Provided functions:
#   check_template_prerequisites  — verify dialog and git are installed
#   download_template_repo        — sparse-checkout only the needed folder
#   read_template_info            — read TEMPLATE_INFO from a template dir
#   show_template_details_dialog  — show template details confirmation dialog
#   replace_template_placeholder  — replace a placeholder in a single file
#   install_template_tools        — install devcontainer tools declared in TEMPLATE_TOOLS
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Check prerequisites (dialog and git)
#
# Exit code: 2 if missing
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
#   $1 — templates subdirectory to download (e.g., "templates" or "ai-templates")
#
# Sets globals:
#   TEMP_DIR          — temporary directory containing the clone
#   TEMPLATE_REPO_DIR — path to the cloned repo root (e.g., "$TEMP_DIR/repo")
#
# Exit code: 1 on failure
#------------------------------------------------------------------------------
download_template_repo() {
  local templates_subdir="$1"
  local repo_url="https://github.com/helpers-no/dev-templates.git"

  TEMP_DIR=$(mktemp -d)
  TEMPLATE_REPO_DIR="$TEMP_DIR/repo"

  echo "📥 Fetching latest templates from GitHub..."
  echo "   Downloading: $templates_subdir/"
  echo ""

  # Shallow clone without checking out files
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

  # Sparse-checkout only the needed folder
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
# Arguments:
#   $1 — path to template directory containing TEMPLATE_INFO
#
# Sets globals:
#   INFO_NAME, INFO_DESCRIPTION, INFO_CATEGORY, INFO_ABSTRACT, INFO_TOOLS, INFO_README
#------------------------------------------------------------------------------
read_template_info() {
  local template_dir="$1"
  local info_file="$template_dir/TEMPLATE_INFO"

  # Defaults
  INFO_NAME=$(basename "$template_dir")
  INFO_DESCRIPTION="No description"
  INFO_CATEGORY="UNCATEGORIZED"
  INFO_ABSTRACT=""
  INFO_TOOLS=""
  INFO_README=""

  if [ -f "$info_file" ]; then
    # Unset variables to avoid pollution (prevents leaking between templates)
    unset TEMPLATE_NAME TEMPLATE_DESCRIPTION TEMPLATE_CATEGORY TEMPLATE_ABSTRACT TEMPLATE_TOOLS TEMPLATE_README

    source "$info_file"

    INFO_NAME="${TEMPLATE_NAME:-$INFO_NAME}"
    INFO_DESCRIPTION="${TEMPLATE_DESCRIPTION:-$INFO_DESCRIPTION}"
    INFO_CATEGORY="${TEMPLATE_CATEGORY:-$INFO_CATEGORY}"
    INFO_ABSTRACT="${TEMPLATE_ABSTRACT:-$INFO_ABSTRACT}"
    INFO_TOOLS="${TEMPLATE_TOOLS:-$INFO_TOOLS}"
    INFO_README="${TEMPLATE_README:-$INFO_README}"

    # Clean up after sourcing
    unset TEMPLATE_NAME TEMPLATE_DESCRIPTION TEMPLATE_CATEGORY TEMPLATE_ABSTRACT TEMPLATE_TOOLS TEMPLATE_README
  fi
}

#------------------------------------------------------------------------------
# Show template details confirmation dialog
#
# Arguments:
#   $1 — index into TEMPLATE_NAMES/TEMPLATE_DESCRIPTIONS/etc. arrays
#
# Requires globals:
#   TEMPLATE_NAMES[], TEMPLATE_DESCRIPTIONS[], TEMPLATE_CATEGORIES[],
#   TEMPLATE_ABSTRACTS[], TEMPLATE_DIRS[], TEMPLATE_TOOLS_LIST[] (optional)
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
# Install devcontainer tools declared in TEMPLATE_TOOLS
#
# Arguments:
#   $1 — space-separated SCRIPT_IDs (e.g., "dev-php-laravel dev-typescript")
#
# Requires globals:
#   $ADDITIONS_DIR — path to .devcontainer/additions/ (set by calling script)
#
# Each tool ID maps to install-{ID}.sh in $ADDITIONS_DIR.
# Failed installs are caught and reported — they don't abort the template install.
#------------------------------------------------------------------------------
install_template_tools() {
  local tools="$1"

  # No-op if empty
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
#
# Arguments:
#   $1 — file path
#   $@ — sed expressions (e.g., "s|{{REPO_NAME}}|myrepo|g")
#
# Returns: 0 on success, 1 on failure
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
