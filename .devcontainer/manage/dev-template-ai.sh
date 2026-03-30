#!/bin/bash
# File: .devcontainer/manage/dev-template-ai.sh
# Description: AI workflow template installer. Downloads AI templates from
#              helpers-no/dev-templates and installs them into a project.
#              Follows the same UX pattern as dev-template.sh.
#
# Usage: ./dev-template-ai.sh [template-directory-name]
#
# Examples:
#   ./dev-template-ai.sh                         # Show menu
#   ./dev-template-ai.sh plan-based-workflow      # Direct selection
#
# Version: 1.0.0
#------------------------------------------------------------------------------
set -e

# Capture caller's directory before any cd commands
CALLER_DIR="$PWD"

# Path resolution for sourcing libraries
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
ADDITIONS_DIR="$DEVCONTAINER_DIR/additions"

# Source libraries
source "$ADDITIONS_DIR/lib/git-identity.sh"
source "$SCRIPT_DIR/lib/template-common.sh"

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-template-ai"
SCRIPT_NAME="AI Templates"
SCRIPT_DESCRIPTION="Install AI workflow templates into your project"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"
SCRIPT_VERSION="1.0.0"

# Which subdirectory in dev-templates repo to scan
TEMPLATES_SUBDIR="ai-templates"

#------------------------------------------------------------------------------
# Detect and validate repository information
#------------------------------------------------------------------------------
function detect_and_validate_repo_info() {
  echo "🔍 Detecting repository information..."

  detect_git_identity "$CALLER_DIR"

  if [ -z "$GIT_REPO" ]; then
    echo "❌ Error: Could not detect repository name"
    echo ""
    echo "   The template needs the repository name for placeholder"
    echo "   substitution in documentation files."
    echo ""
    echo "   To fix this, set up a git remote:"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    exit 1
  fi

  echo "   Repo name: $GIT_REPO"
  echo "✅ Repository info verified"
  echo ""
}

#------------------------------------------------------------------------------
# Display banner
#------------------------------------------------------------------------------
function display_intro() {
  echo ""
  echo "🤖 AI Workflow Template Installer"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

#------------------------------------------------------------------------------
# Scan templates and build arrays
#------------------------------------------------------------------------------
function scan_templates() {
  TEMPLATE_DIRS=()
  TEMPLATE_NAMES=()
  TEMPLATE_DESCRIPTIONS=()
  TEMPLATE_CATEGORIES=()
  TEMPLATE_PURPOSES=()

  # Group by category — AI templates use WORKFLOW category
  declare -g -A CATEGORY_WORKFLOW
  declare -g -A CATEGORY_OTHER

  echo "📋 Scanning available AI templates..."
  for dir in "$TEMPLATE_REPO_DIR/$TEMPLATES_SUBDIR"/*; do
    if [ -d "$dir" ]; then
      read_template_info "$dir"

      local idx=${#TEMPLATE_DIRS[@]}
      TEMPLATE_DIRS+=("$(basename "$dir")")
      TEMPLATE_NAMES+=("$INFO_NAME")
      TEMPLATE_DESCRIPTIONS+=("$INFO_DESCRIPTION")
      TEMPLATE_CATEGORIES+=("$INFO_CATEGORY")
      TEMPLATE_PURPOSES+=("$INFO_PURPOSE")

      case "$INFO_CATEGORY" in
        WORKFLOW)
          CATEGORY_WORKFLOW["$(basename "$dir")"]=$idx
          ;;
        *)
          CATEGORY_OTHER["$(basename "$dir")"]=$idx
          ;;
      esac
    fi
  done

  if [ ${#TEMPLATE_DIRS[@]} -eq 0 ]; then
    echo "❌ No AI templates found"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Found ${#TEMPLATE_DIRS[@]} AI template(s)"
  echo ""

  # Build menu options
  MENU_OPTIONS=()
  declare -g -A MENU_TO_INDEX
  local option_num=1

  if [ ${#CATEGORY_WORKFLOW[@]} -gt 0 ]; then
    for dir_name in $(printf '%s\n' "${!CATEGORY_WORKFLOW[@]}" | sort); do
      local idx=${CATEGORY_WORKFLOW[$dir_name]}
      MENU_OPTIONS+=("$option_num" "📋 ${TEMPLATE_NAMES[$idx]}" "${TEMPLATE_DESCRIPTIONS[$idx]}")
      MENU_TO_INDEX[$option_num]=$idx
      ((option_num++))
    done
  fi

  if [ ${#CATEGORY_OTHER[@]} -gt 0 ]; then
    for dir_name in $(printf '%s\n' "${!CATEGORY_OTHER[@]}" | sort); do
      local idx=${CATEGORY_OTHER[$dir_name]}
      MENU_OPTIONS+=("$option_num" "📦 ${TEMPLATE_NAMES[$idx]}" "${TEMPLATE_DESCRIPTIONS[$idx]}")
      MENU_TO_INDEX[$option_num]=$idx
      ((option_num++))
    done
  fi
}

#------------------------------------------------------------------------------
# Show dialog menu and get selection
#------------------------------------------------------------------------------
function show_template_menu() {
  local choice
  choice=$(dialog --clear \
    --item-help \
    --title "AI Workflow Templates" \
    --menu "Choose an AI template (ESC to cancel):\n\n📋=Workflow  📦=Other" \
    20 80 12 \
    "${MENU_OPTIONS[@]}" \
    2>&1 >/dev/tty)

  if [[ $? -ne 0 ]]; then
    clear
    echo "ℹ️  Selection cancelled"
    rm -rf "$TEMP_DIR"
    exit 3
  fi

  echo "$choice"
}

#------------------------------------------------------------------------------
# Select template (interactive or from argument)
#------------------------------------------------------------------------------
function select_template() {
  local param_name="$1"

  if [ -n "$param_name" ]; then
    SELECTED_TEMPLATE="$param_name"

    if [ ! -d "$TEMPLATE_REPO_DIR/$TEMPLATES_SUBDIR/$SELECTED_TEMPLATE" ]; then
      echo "❌ AI template '$SELECTED_TEMPLATE' not found"
      rm -rf "$TEMP_DIR"
      exit 2
    fi

    for i in "${!TEMPLATE_DIRS[@]}"; do
      if [ "${TEMPLATE_DIRS[$i]}" == "$SELECTED_TEMPLATE" ]; then
        TEMPLATE_INDEX=$i
        break
      fi
    done
  else
    while true; do
      local choice
      choice=$(show_template_menu)
      TEMPLATE_INDEX=${MENU_TO_INDEX[$choice]}

      if show_template_details_dialog $TEMPLATE_INDEX; then
        SELECTED_TEMPLATE="${TEMPLATE_DIRS[$TEMPLATE_INDEX]}"
        break
      fi
    done
  fi

  clear
  display_intro
  echo "✅ Selected: ${TEMPLATE_NAMES[$TEMPLATE_INDEX]}"

  if [ -n "${TEMPLATE_PURPOSES[$TEMPLATE_INDEX]}" ]; then
    echo ""
    echo "📝 About this template:"
    echo "   ${TEMPLATE_PURPOSES[$TEMPLATE_INDEX]}"
  fi
  echo ""

  TEMPLATE_PATH="$TEMPLATE_REPO_DIR/$TEMPLATES_SUBDIR/$SELECTED_TEMPLATE"
}

#------------------------------------------------------------------------------
# Verify template structure
#------------------------------------------------------------------------------
function verify_template() {
  echo "🔍 Verifying template structure..."

  if [ ! -d "$TEMPLATE_PATH/template" ]; then
    echo "❌ Required 'template/' subdirectory not found in $SELECTED_TEMPLATE"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Template structure verified"
  echo ""
}

#------------------------------------------------------------------------------
# Copy template files with safe re-run logic
#------------------------------------------------------------------------------
function copy_template_files() {
  echo "📦 Installing AI workflow files..."

  local template_source="$TEMPLATE_PATH/template"

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$template_source/}"
    local dest_file="$CALLER_DIR/$rel_path"
    local dest_dir
    dest_dir=$(dirname "$dest_file")

    # Skip .gitkeep files if the directory already has content
    if [ "$(basename "$src_file")" = ".gitkeep" ]; then
      mkdir -p "$dest_dir"
      if [ -z "$(ls -A "$dest_dir" 2>/dev/null)" ]; then
        cp "$src_file" "$dest_file"
      fi
      continue
    fi

    # Never overwrite user plans
    if [[ "$rel_path" == *"/plans/backlog/"* || "$rel_path" == *"/plans/active/"* || "$rel_path" == *"/plans/completed/"* ]]; then
      mkdir -p "$dest_dir"
      if [ ! -f "$dest_file" ]; then
        cp "$src_file" "$dest_file"
        echo "   ✅ Created $rel_path"
      else
        echo "   ⏭️  Skipped $rel_path (user file exists)"
      fi
      continue
    fi

    # Never overwrite user-renamed project-*.md files
    if [[ "$(basename "$src_file")" == "project-"* && "$(basename "$src_file")" != "project-TEMPLATE.md" ]]; then
      if [ -f "$dest_file" ]; then
        echo "   ⏭️  Skipped $rel_path (user file exists)"
        continue
      fi
    fi

    # Default: copy (overwrite template-owned files)
    mkdir -p "$dest_dir"
    cp "$src_file" "$dest_file"
    echo "   ✅ Installed $rel_path"
  done < <(find "$template_source" -type f -print0)

  echo ""
}

#------------------------------------------------------------------------------
# Handle CLAUDE.md conflict
#------------------------------------------------------------------------------
function handle_claude_md() {
  local template_ref="$CALLER_DIR/docs/ai-developer/CLAUDE-template.md"

  if $CLAUDE_EXISTED; then
    # User had CLAUDE.md before — original was restored, keep template reference
    echo "⚠️  CLAUDE.md already exists in your project."
    echo "   A template CLAUDE.md has been placed at docs/ai-developer/CLAUDE-template.md"
    echo ""
    echo "   Ask your AI assistant: \"Merge CLAUDE-template.md into my CLAUDE.md\""
    echo ""
  else
    # No pre-existing CLAUDE.md — template CLAUDE.md was installed, remove reference copy
    rm -f "$template_ref"
  fi
}

#------------------------------------------------------------------------------
# Rename project-TEMPLATE.md to project-{repo-name}.md
#------------------------------------------------------------------------------
function rename_project_template() {
  local template_file="$CALLER_DIR/docs/ai-developer/project-TEMPLATE.md"
  local target_file="$CALLER_DIR/docs/ai-developer/project-${GIT_REPO}.md"

  if [ -f "$template_file" ]; then
    if [ -f "$target_file" ]; then
      echo "⏭️  Skipped renaming project-TEMPLATE.md (project-${GIT_REPO}.md already exists)"
    else
      mv "$template_file" "$target_file"
      echo "✅ Renamed project-TEMPLATE.md → project-${GIT_REPO}.md"
    fi
    echo ""
  fi
}

#------------------------------------------------------------------------------
# Process template files — replace {{REPO_NAME}} in .md files
#------------------------------------------------------------------------------
function process_template_files() {
  echo "🔄 Replacing template placeholders..."
  echo "   Using repo name: $GIT_REPO"

  if [ -d "$CALLER_DIR/docs/ai-developer" ]; then
    while IFS= read -r -d '' file; do
      replace_template_placeholder "$file" "s|{{REPO_NAME}}|$GIT_REPO|g"
    done < <(find "$CALLER_DIR/docs/ai-developer" -name "*.md" -type f -print0)
  fi

  if [ -f "$CALLER_DIR/CLAUDE.md" ]; then
    replace_template_placeholder "$CALLER_DIR/CLAUDE.md" "s|{{REPO_NAME}}|$GIT_REPO|g"
  fi

  echo "✅ Placeholders replaced"
  echo ""
}

#------------------------------------------------------------------------------
# Cleanup and show completion
#------------------------------------------------------------------------------
function cleanup_and_complete() {
  echo "🧹 Cleaning up..."
  rm -rf "$TEMP_DIR"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ AI workflow template installed!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📝 What was installed:"
  echo "   docs/ai-developer/     — AI workflow documentation"
  echo "   docs/ai-developer/plans/ — Plan tracking (backlog, active, completed)"
  if [ -f "$CALLER_DIR/CLAUDE.md" ]; then
    echo "   CLAUDE.md              — AI assistant configuration"
  fi
  echo ""
  echo "📝 Next steps:"
  echo "   1. Review docs/ai-developer/README.md for the complete guide"
  echo "   2. Review CLAUDE.md and customize for your project"
  echo "   3. Start your first task: tell your AI assistant what you want to build"
  echo ""
}

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
function show_help() {
  echo ""
  echo "🤖 AI Workflow Template Installer v${SCRIPT_VERSION}"
  echo ""
  echo "Usage: dev-template-ai.sh [template-name]"
  echo ""
  echo "  dev-template-ai.sh                      Show interactive menu"
  echo "  dev-template-ai.sh plan-based-workflow   Install specific template"
  echo "  dev-template-ai.sh --help               Show this help"
  echo ""
  echo "Installs AI workflow templates from helpers-no/dev-templates into your"
  echo "project. Templates include CLAUDE.md, plan structure, and workflow docs."
  echo ""
  echo "How it works:"
  echo "  Uses git sparse-checkout to download only the ai-templates/ folder"
  echo "  from helpers-no/dev-templates to a temp directory. The selected"
  echo "  template is then copied into your project. Temp files are cleaned"
  echo "  up automatically. No git authentication required (public repo)."
  echo ""
  echo "Source: https://github.com/helpers-no/dev-templates/tree/main/ai-templates"
  echo ""
}

#------------------------------------------------------------------------------
# Main execution
#------------------------------------------------------------------------------

# Check for --help before anything else (no prerequisites needed)
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

# Get template name from command line (optional)
SELECTED_TEMPLATE="${1:-}"

check_template_prerequisites
detect_and_validate_repo_info
clear
display_intro
download_template_repo "$TEMPLATES_SUBDIR"
scan_templates
select_template "$SELECTED_TEMPLATE"
verify_template

# Save CLAUDE.md state before copy overwrites it
CLAUDE_EXISTED=false
if [ -f "$CALLER_DIR/CLAUDE.md" ]; then
  CLAUDE_EXISTED=true
  cp "$CALLER_DIR/CLAUDE.md" "$CALLER_DIR/CLAUDE.md.bak"
fi

copy_template_files

# Restore original CLAUDE.md if it existed before copy
if $CLAUDE_EXISTED; then
  mv "$CALLER_DIR/CLAUDE.md.bak" "$CALLER_DIR/CLAUDE.md"
fi

handle_claude_md
rename_project_template
process_template_files
cd "$CALLER_DIR"
cleanup_and_complete
