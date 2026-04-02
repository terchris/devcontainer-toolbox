#!/bin/bash
# File: .devcontainer/manage/dev-template-ai.sh
# Description: AI workflow template installer. Downloads AI templates from
#              helpers-no/dev-templates and installs them into a project.
#
# Usage: ./dev-template-ai.sh [template-directory-name]
#
# Examples:
#   ./dev-template-ai.sh                         # Show menu
#   ./dev-template-ai.sh plan-based-workflow      # Direct selection
#
# Version: 1.1.0
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
SCRIPT_VERSION="1.1.0"

# Templates subdirectory
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
# Verify template structure (AI templates require template/ subdirectory)
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
    echo "⚠️  CLAUDE.md already exists in your project."
    echo "   A template CLAUDE.md has been placed at docs/ai-developer/CLAUDE-template.md"
    echo ""
    echo "   Ask your AI assistant: \"Merge CLAUDE-template.md into my CLAUDE.md\""
    echo ""
  else
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
  echo ""

  local step=1
  local tools="${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]:-}"
  local readme="${TEMPLATE_README_LIST[$TEMPLATE_INDEX]:-}"

  if [ -n "$tools" ]; then
    echo "   $step. Update your terminal (tools were installed):"
    echo "      source ~/.bashrc"
    echo ""
    step=$((step + 1))
  fi

  if [ -n "$readme" ]; then
    echo "   $step. Read the template instructions:"
    echo "      cat $readme"
    echo ""
    step=$((step + 1))
  else
    echo "   $step. Review docs/ai-developer/README.md for the complete guide"
    echo ""
    step=$((step + 1))
  fi

  echo "   $step. Start your first task: tell your AI assistant what you want to build"
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
  echo "  If the template declares required tools (TEMPLATE_TOOLS),"
  echo "  they are installed automatically in the devcontainer."
  echo ""
  echo "Source: https://github.com/helpers-no/dev-templates/tree/main/ai-templates"
  echo ""
}

#------------------------------------------------------------------------------
# Main execution
#------------------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

SELECTED_TEMPLATE_ARG="${1:-}"

check_template_prerequisites
detect_and_validate_repo_info
clear
display_intro
download_template_repo "$TEMPLATES_SUBDIR"
scan_templates "$TEMPLATES_SUBDIR"
select_template "$SELECTED_TEMPLATE_ARG" "$TEMPLATES_SUBDIR" "AI Workflow Templates"
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
install_template_tools "${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]:-}"
process_template_files
cd "$CALLER_DIR"
cleanup_and_complete
