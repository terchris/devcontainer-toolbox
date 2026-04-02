#!/bin/bash
# File: .devcontainer/manage/dev-template.sh
# Description: Template initializer for the Urbalurba Developer Platform.
#              Downloads templates from helpers-no/dev-templates and installs them.
#
# Usage: ./dev-template.sh [template-directory-name]
#
# Examples:
#   ./dev-template.sh                      # Show menu
#   ./dev-template.sh typescript-basic-webserver  # Direct selection
#
# Version: 1.7.0
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
SCRIPT_ID="dev-template"
SCRIPT_NAME="Templates"
SCRIPT_DESCRIPTION="Create project files from templates"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"
SCRIPT_VERSION="1.7.0"

# Templates subdirectory
TEMPLATES_SUBDIR="templates"

#------------------------------------------------------------------------------
# Detect and validate repository information
#------------------------------------------------------------------------------
function detect_and_validate_repo_info() {
  echo "🔍 Detecting repository information..."

  detect_git_identity "$CALLER_DIR"

  if [ -z "$GIT_ORG" ]; then
    echo "❌ Error: Could not detect GitHub username/organization"
    echo ""
    echo "   The template needs to know your GitHub username to configure"
    echo "   container image paths and Kubernetes manifests."
    echo ""
    echo "   To fix this, set up a GitHub remote:"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/$(basename "$CALLER_DIR").git"
    exit 1
  fi

  if [ -z "$GIT_REPO" ]; then
    echo "❌ Error: Could not detect repository name"
    echo ""
    echo "   The template needs the repository name to configure"
    echo "   Kubernetes deployment names and labels."
    echo ""
    echo "   To fix this, set up a GitHub remote:"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    exit 1
  fi

  if [ "$GIT_PROVIDER" != "github" ]; then
    echo "⚠️  Warning: Detected provider '$GIT_PROVIDER' (not GitHub)"
    echo "   Templates use ghcr.io container registry paths which are GitHub-specific."
    echo "   You may need to update image paths in manifests/ after setup."
    echo ""
  fi

  echo "   GitHub user: $GIT_ORG"
  echo "   Repo name:   $GIT_REPO"
  echo "✅ Repository info verified"
  echo ""
}

#------------------------------------------------------------------------------
# Display banner
#------------------------------------------------------------------------------
function display_intro() {
  echo ""
  echo "🛠️  Urbalurba Developer Platform - Project Template Initializer"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

#------------------------------------------------------------------------------
# Verify template structure (project templates require manifests)
#------------------------------------------------------------------------------
function verify_template() {
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
}

#------------------------------------------------------------------------------
# Copy template files
#------------------------------------------------------------------------------
function copy_template_files() {
  echo "📦 Extracting template files..."
  cp -r "$TEMPLATE_PATH/"* "$CALLER_DIR/"
  echo ""
}

#------------------------------------------------------------------------------
# Setup GitHub workflows
#------------------------------------------------------------------------------
function setup_github_workflows() {
  if [ -d "$TEMPLATE_PATH/.github" ]; then
    echo "⚙️  Setting up GitHub workflows..."
    mkdir -p "$CALLER_DIR/.github/workflows"
    cp -r "$TEMPLATE_PATH/.github"/* "$CALLER_DIR/.github/"
    echo "   ✅ Added GitHub workflows"
    echo ""
  fi
}

#------------------------------------------------------------------------------
# Merge .gitignore files
#------------------------------------------------------------------------------
function merge_gitignore() {
  if [ -f "$TEMPLATE_PATH/.gitignore" ]; then
    echo "🔀 Merging .gitignore files..."

    if [ -f "$CALLER_DIR/.gitignore" ]; then
      TEMP_MERGED=$(mktemp)
      cat "$CALLER_DIR/.gitignore" > "$TEMP_MERGED"
      echo "" >> "$TEMP_MERGED"
      echo "# Added from template $SELECTED_TEMPLATE" >> "$TEMP_MERGED"

      while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
          if ! grep -Fxq "$line" "$CALLER_DIR/.gitignore"; then
            echo "$line" >> "$TEMP_MERGED"
          fi
        fi
      done < "$TEMPLATE_PATH/.gitignore"

      if cat "$TEMP_MERGED" > "$CALLER_DIR/.gitignore"; then
        echo "   ✅ Merged .gitignore files"
        rm -f "$TEMP_MERGED"
      else
        echo "   ❌ Failed to merge .gitignore"
        rm -f "$TEMP_MERGED"
        exit 1
      fi
    else
      cp "$TEMPLATE_PATH/.gitignore" "$CALLER_DIR/"
      echo "   ✅ Copied .gitignore"
    fi
    echo ""
  fi
}

#------------------------------------------------------------------------------
# Replace placeholders in template files
#------------------------------------------------------------------------------
function replace_placeholders() {
  replace_template_placeholder "$1" \
    "s|{{GITHUB_USERNAME}}|$GIT_ORG|g" \
    "s|{{REPO_NAME}}|$GIT_REPO|g"
}

function process_template_files() {
  echo "🔄 Replacing template placeholders..."
  echo "   Using: $GIT_ORG/$GIT_REPO"

  if [ -d "$CALLER_DIR/manifests" ]; then
    for file in "$CALLER_DIR"/manifests/*.yaml "$CALLER_DIR"/manifests/*.yml; do
      [ -f "$file" ] && replace_placeholders "$file"
    done
  fi

  if [ -d "$CALLER_DIR/.github/workflows" ]; then
    for file in "$CALLER_DIR"/.github/workflows/*.yaml "$CALLER_DIR"/.github/workflows/*.yml; do
      [ -f "$file" ] && replace_placeholders "$file"
    done
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
  echo "✅ Template setup complete!"
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

  echo "   $step. Commit and push your project to GitHub"
  echo ""
}

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
function show_help() {
  echo ""
  echo "🛠️  Project Template Initializer v${SCRIPT_VERSION}"
  echo ""
  echo "Usage: dev-template.sh [template-name]"
  echo ""
  echo "  dev-template.sh                              Show interactive menu"
  echo "  dev-template.sh typescript-basic-webserver   Install specific template"
  echo "  dev-template.sh --help                       Show this help"
  echo ""
  echo "Installs project templates from helpers-no/dev-templates into your"
  echo "project. Templates include app scaffolding, Kubernetes manifests,"
  echo "and GitHub Actions workflows."
  echo ""
  echo "How it works:"
  echo "  Uses git sparse-checkout to download only the templates/ folder"
  echo "  from helpers-no/dev-templates to a temp directory. The selected"
  echo "  template is then copied into your project with placeholder"
  echo "  substitution. Temp files are cleaned up automatically."
  echo "  No git authentication required (public repo)."
  echo ""
  echo "  If the template declares required tools (TEMPLATE_TOOLS),"
  echo "  they are installed automatically in the devcontainer."
  echo ""
  echo "Source: https://github.com/helpers-no/dev-templates/tree/main/templates"
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
select_template "$SELECTED_TEMPLATE_ARG" "$TEMPLATES_SUBDIR" "Project Templates"
verify_template
copy_template_files
setup_github_workflows
merge_gitignore
install_template_tools "${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]:-}"
process_template_files
cd "$CALLER_DIR"
cleanup_and_complete
