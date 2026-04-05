#!/bin/bash
# File: .devcontainer/manage/dev-template.sh
# Description: Unified template installer. Fetches template-registry.json,
#              shows two-level menu, downloads only the selected template,
#              routes installation by install_type (app/overlay).
#
# Usage: ./dev-template.sh [template-id]
#
# Examples:
#   ./dev-template.sh                           # Show interactive menu
#   ./dev-template.sh python-basic-webserver    # Direct selection (app)
#   ./dev-template.sh plan-based-workflow       # Direct selection (overlay)
#
# Version: 2.0.0
#------------------------------------------------------------------------------
set -e

CALLER_DIR="$PWD"
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
ADDITIONS_DIR="$DEVCONTAINER_DIR/additions"

source "$ADDITIONS_DIR/lib/git-identity.sh"
source "$SCRIPT_DIR/lib/template-common.sh"

#------------------------------------------------------------------------------
# Script Metadata
#------------------------------------------------------------------------------
SCRIPT_ID="dev-template"
SCRIPT_NAME="Templates"
SCRIPT_DESCRIPTION="Create project from template"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"
SCRIPT_VERSION="2.0.0"

#------------------------------------------------------------------------------
# Detect and validate repository information
#------------------------------------------------------------------------------
function detect_and_validate_repo_info() {
  echo "🔍 Detecting repository information..."
  detect_git_identity "$CALLER_DIR"

  if [ -z "$GIT_REPO" ]; then
    echo "❌ Error: Could not detect repository name"
    echo ""
    echo "   To fix this, set up a git remote:"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    exit 1
  fi

  # GIT_ORG is needed for app templates but optional for overlay
  echo "   Repo name: $GIT_REPO"
  if [ -n "$GIT_ORG" ]; then
    echo "   GitHub user: $GIT_ORG"
  fi
  echo "✅ Repository info verified"
  echo ""
}

#------------------------------------------------------------------------------
# install_type: app — copy to root, replace placeholders, workflows, gitignore
#------------------------------------------------------------------------------
function install_app_template() {
  # Verify app template structure
  echo "🔍 Verifying template structure..."
  if [ ! -d "$TEMPLATE_PATH/manifests" ]; then
    echo "❌ Required directory 'manifests' not found"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  if [ ! -f "$TEMPLATE_PATH/manifests/deployment.yaml" ]; then
    echo "❌ Required file 'manifests/deployment.yaml' not found"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  echo "✅ Template structure verified"
  echo ""

  # Validate GIT_ORG for app templates (needed for placeholders)
  if [ -z "$GIT_ORG" ]; then
    echo "❌ Error: Could not detect GitHub username/organization"
    echo "   App templates need this for container image paths and manifests."
    echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # Copy files
  echo "📦 Extracting template files..."
  cp -r "$TEMPLATE_PATH/"* "$CALLER_DIR/"
  echo ""

  # Copy template-info.yaml to project root (Decision #12)
  if [ -f "$TEMPLATE_PATH/template-info.yaml" ]; then
    cp "$TEMPLATE_PATH/template-info.yaml" "$CALLER_DIR/"
  fi

  # Setup GitHub workflows
  if [ -d "$TEMPLATE_PATH/.github" ]; then
    echo "⚙️  Setting up GitHub workflows..."
    mkdir -p "$CALLER_DIR/.github/workflows"
    cp -r "$TEMPLATE_PATH/.github"/* "$CALLER_DIR/.github/"
    echo "   ✅ Added GitHub workflows"
    echo ""
  fi

  # Merge .gitignore
  if [ -f "$TEMPLATE_PATH/.gitignore" ]; then
    echo "🔀 Merging .gitignore files..."
    if [ -f "$CALLER_DIR/.gitignore" ]; then
      local temp_merged
      temp_merged=$(mktemp)
      cat "$CALLER_DIR/.gitignore" > "$temp_merged"
      echo "" >> "$temp_merged"
      echo "# Added from template ${TEMPLATE_IDS[$TEMPLATE_INDEX]}" >> "$temp_merged"
      while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
          if ! grep -Fxq "$line" "$CALLER_DIR/.gitignore"; then
            echo "$line" >> "$temp_merged"
          fi
        fi
      done < "$TEMPLATE_PATH/.gitignore"
      cat "$temp_merged" > "$CALLER_DIR/.gitignore"
      rm -f "$temp_merged"
      echo "   ✅ Merged .gitignore files"
    else
      cp "$TEMPLATE_PATH/.gitignore" "$CALLER_DIR/"
      echo "   ✅ Copied .gitignore"
    fi
    echo ""
  fi

  # Replace placeholders in manifests and workflows
  echo "🔄 Replacing template placeholders..."
  echo "   Using: $GIT_ORG/$GIT_REPO"

  if [ -d "$CALLER_DIR/manifests" ]; then
    for file in "$CALLER_DIR"/manifests/*.yaml "$CALLER_DIR"/manifests/*.yml; do
      [ -f "$file" ] && replace_template_placeholder "$file" \
        "s|{{GITHUB_USERNAME}}|$GIT_ORG|g" \
        "s|{{REPO_NAME}}|$GIT_REPO|g"
    done
  fi

  if [ -d "$CALLER_DIR/.github/workflows" ]; then
    for file in "$CALLER_DIR"/.github/workflows/*.yaml "$CALLER_DIR"/.github/workflows/*.yml; do
      [ -f "$file" ] && replace_template_placeholder "$file" \
        "s|{{GITHUB_USERNAME}}|$GIT_ORG|g" \
        "s|{{REPO_NAME}}|$GIT_REPO|g"
    done
  fi

  echo "✅ Placeholders replaced"
  echo ""
}

#------------------------------------------------------------------------------
# install_type: overlay — copy template/ preserving paths, handle conflicts
#------------------------------------------------------------------------------
function install_overlay_template() {
  # Verify overlay template structure
  echo "🔍 Verifying template structure..."
  if [ ! -d "$TEMPLATE_PATH/template" ]; then
    echo "❌ Required 'template/' subdirectory not found"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  echo "✅ Template structure verified"
  echo ""

  # Copy template-info.yaml to project root (Decision #12 — explicit for overlay)
  if [ -f "$TEMPLATE_PATH/template-info.yaml" ]; then
    cp "$TEMPLATE_PATH/template-info.yaml" "$CALLER_DIR/"
  fi

  # Save CLAUDE.md state before copy
  CLAUDE_EXISTED=false
  if [ -f "$CALLER_DIR/CLAUDE.md" ]; then
    CLAUDE_EXISTED=true
    cp "$CALLER_DIR/CLAUDE.md" "$CALLER_DIR/CLAUDE.md.bak"
  fi

  # Copy template/ contents preserving directory structure
  echo "📦 Installing template files..."
  local template_source="$TEMPLATE_PATH/template"

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$template_source/}"
    local dest_file="$CALLER_DIR/$rel_path"
    local dest_dir
    dest_dir=$(dirname "$dest_file")

    # Skip .gitkeep if directory has content
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

    # Never overwrite user-renamed project-*.md
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

  # Restore CLAUDE.md if it existed
  if $CLAUDE_EXISTED; then
    mv "$CALLER_DIR/CLAUDE.md.bak" "$CALLER_DIR/CLAUDE.md"
  fi

  # Handle CLAUDE.md conflict
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

  # Rename project-TEMPLATE.md
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

  # Replace placeholders in .md files
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

  local install_type="${TEMPLATE_INSTALL_TYPES[$TEMPLATE_INDEX]}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ "$install_type" = "overlay" ]; then
    echo "✅ Template installed!"
  else
    echo "✅ Template setup complete!"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
  fi

  # Check if template has requires (needs dev-template configure)
  if [ -f "$CALLER_DIR/template-info.yaml" ] && grep -q '^requires:' "$CALLER_DIR/template-info.yaml" 2>/dev/null; then
    echo "   $step. Configure services (database, auth, etc.):"
    echo "      Edit template-info.yaml params, then run:"
    echo "      dev-template configure"
    echo ""
    step=$((step + 1))
  fi

  echo "   $step. Start building your project"
  echo ""
}

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
function show_help() {
  echo ""
  echo "🛠️  Template Installer v${SCRIPT_VERSION}"
  echo ""
  echo "Usage: dev-template [template-id | configure]"
  echo ""
  echo "  dev-template                           Show interactive menu"
  echo "  dev-template python-basic-webserver    Install app template"
  echo "  dev-template plan-based-workflow       Install AI workflow template"
  echo "  dev-template configure                 Configure services (after install)"
  echo "  dev-template configure --param k=v     Configure with CLI params"
  echo "  dev-template --help                    Show this help"
  echo ""
  echo "Installs project templates from helpers-no/dev-templates."
  echo "Supports app templates, AI workflow templates, documentation"
  echo "templates, and more — all from one command."
  echo ""
  echo "How it works:"
  echo "  Fetches a template registry (small JSON) to show available"
  echo "  templates instantly. After you pick one, only that template's"
  echo "  folder is downloaded via git sparse-checkout. Tools declared"
  echo "  in the template are installed automatically."
  echo ""
  echo "  If the template requires services (e.g., PostgreSQL), run"
  echo "  dev-template configure after install to create databases"
  echo "  and wire connections into .env."
  echo ""
  echo "Source: https://github.com/helpers-no/dev-templates"
  echo ""
}

#------------------------------------------------------------------------------
# Main execution
#------------------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

# Route 'configure' subcommand to separate script
if [[ "${1:-}" == "configure" ]]; then
  shift
  exec bash "$SCRIPT_DIR/dev-template-configure.sh" "$@"
fi

SELECTED_TEMPLATE_ARG="${1:-}"

check_template_prerequisites
detect_and_validate_repo_info
clear 2>/dev/null || true
echo ""
echo "🛠️  Template Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

fetch_registry
parse_registry "dct"
select_template "$SELECTED_TEMPLATE_ARG" "Templates"
download_selected_template

# Route by install_type
local_install_type="${TEMPLATE_INSTALL_TYPES[$TEMPLATE_INDEX]}"

case "$local_install_type" in
  app)
    install_app_template
    ;;
  overlay)
    install_overlay_template
    ;;
  *)
    echo "❌ Unknown install_type: $local_install_type"
    rm -rf "$TEMP_DIR"
    exit 1
    ;;
esac

# Install tools
install_template_tools "${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]:-}"

cd "$CALLER_DIR"
cleanup_and_complete
