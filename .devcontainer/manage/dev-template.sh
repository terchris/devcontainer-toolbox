#!/bin/bash
# File: .devcontainer/manage/dev-template.sh
# Description: Template initializer for the Urbalurba Developer Platform with dialog menu.
#              Reads TEMPLATE_INFO from each template for display names and descriptions.
#
# Usage: ./dev-template.sh [template-directory-name]
#
# Examples:
#   ./dev-template.sh                      # Show menu
#   ./dev-template.sh typescript-basic-webserver  # Direct selection
#
# Version: 1.6.0
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
SCRIPT_VERSION="1.6.0"

#------------------------------------------------------------------------------
# Check prerequisites (uses shared library)
#------------------------------------------------------------------------------
function check_prerequisites() {
  check_template_prerequisites
}

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
# Download templates repository as zip
#------------------------------------------------------------------------------
function download_templates() {
  download_template_repo "templates"
}

# read_template_info() — provided by lib/template-common.sh

#------------------------------------------------------------------------------
# Scan templates and build arrays
#------------------------------------------------------------------------------
function scan_templates() {
  TEMPLATE_DIRS=()
  TEMPLATE_NAMES=()
  TEMPLATE_DESCRIPTIONS=()
  TEMPLATE_CATEGORIES=()
  TEMPLATE_PURPOSES=()
  TEMPLATE_TOOLS_LIST=()

  # Group by category
  declare -g -A CATEGORY_WEB_SERVER
  declare -g -A CATEGORY_WEB_APP
  declare -g -A CATEGORY_OTHER

  echo "📋 Scanning available templates..."
  for dir in "$TEMPLATE_REPO_DIR/templates"/*; do
    if [ -d "$dir" ]; then
      read_template_info "$dir"

      local idx=${#TEMPLATE_DIRS[@]}
      TEMPLATE_DIRS+=("$(basename "$dir")")
      TEMPLATE_NAMES+=("$INFO_NAME")
      TEMPLATE_DESCRIPTIONS+=("$INFO_DESCRIPTION")
      TEMPLATE_CATEGORIES+=("$INFO_CATEGORY")
      TEMPLATE_PURPOSES+=("$INFO_PURPOSE")
      TEMPLATE_TOOLS_LIST+=("$INFO_TOOLS")

      # Group by category for menu display
      case "$INFO_CATEGORY" in
        WEB_SERVER)
          CATEGORY_WEB_SERVER["$(basename "$dir")"]=$idx
          ;;
        WEB_APP)
          CATEGORY_WEB_APP["$(basename "$dir")"]=$idx
          ;;
        *)
          CATEGORY_OTHER["$(basename "$dir")"]=$idx
          ;;
      esac
    fi
  done

  if [ ${#TEMPLATE_DIRS[@]} -eq 0 ]; then
    echo "❌ No templates found"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Found ${#TEMPLATE_DIRS[@]} template(s)"
  echo ""

  # Build menu options and menu-to-index mapping here (not in subshell)
  # This must be done in the main shell so MENU_TO_INDEX persists
  MENU_OPTIONS=()
  declare -g -A MENU_TO_INDEX
  local option_num=1

  if [ ${#CATEGORY_WEB_SERVER[@]} -gt 0 ]; then
    for dir_name in $(printf '%s\n' "${!CATEGORY_WEB_SERVER[@]}" | sort); do
      local idx=${CATEGORY_WEB_SERVER[$dir_name]}
      MENU_OPTIONS+=("$option_num" "🌐 ${TEMPLATE_NAMES[$idx]}" "${TEMPLATE_DESCRIPTIONS[$idx]}")
      MENU_TO_INDEX[$option_num]=$idx
      ((option_num++))
    done
  fi

  if [ ${#CATEGORY_WEB_APP[@]} -gt 0 ]; then
    for dir_name in $(printf '%s\n' "${!CATEGORY_WEB_APP[@]}" | sort); do
      local idx=${CATEGORY_WEB_APP[$dir_name]}
      MENU_OPTIONS+=("$option_num" "📱 ${TEMPLATE_NAMES[$idx]}" "${TEMPLATE_DESCRIPTIONS[$idx]}")
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
# Show dialog menu grouped by category and get selection
#------------------------------------------------------------------------------
function show_template_menu() {
  local choice
  choice=$(dialog --clear \
    --item-help \
    --title "Project Templates" \
    --menu "Choose a template (ESC to cancel):\n\n🌐=Web Server  📱=Web App  📦=Other" \
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

function show_template_details() {
  show_template_details_dialog "$1"
}

#------------------------------------------------------------------------------
# Select template (interactive or from argument)
#------------------------------------------------------------------------------
function select_template() {
  local param_name="$1"
  
  if [ -n "$param_name" ]; then
    # Direct selection by directory name
    TEMPLATE_NAME="$param_name"
    
    if [ ! -d "$TEMPLATE_REPO_DIR/templates/$TEMPLATE_NAME" ]; then
      echo "❌ Template '$TEMPLATE_NAME' not found"
      rm -rf "$TEMP_DIR"
      exit 2
    fi
    
    # Find index for display
    for i in "${!TEMPLATE_DIRS[@]}"; do
      if [ "${TEMPLATE_DIRS[$i]}" == "$TEMPLATE_NAME" ]; then
        TEMPLATE_INDEX=$i
        break
      fi
    done
  else
    # Interactive menu selection with confirmation
    while true; do
      local choice
      choice=$(show_template_menu)
      TEMPLATE_INDEX=${MENU_TO_INDEX[$choice]}
      
      # Show details and get confirmation
      if show_template_details $TEMPLATE_INDEX; then
        TEMPLATE_NAME="${TEMPLATE_DIRS[$TEMPLATE_INDEX]}"
        break
      fi
      # If user said no, loop back to menu
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
  
  TEMPLATE_PATH="$TEMPLATE_REPO_DIR/templates/$TEMPLATE_NAME"
}

#------------------------------------------------------------------------------
# Verify template structure
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
      echo "# Added from template $TEMPLATE_NAME" >> "$TEMP_MERGED"
      
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

function replace_placeholders() {
  replace_template_placeholder "$1" \
    "s|{{GITHUB_USERNAME}}|$GIT_ORG|g" \
    "s|{{REPO_NAME}}|$GIT_REPO|g"
}

#------------------------------------------------------------------------------
# Process template files that need placeholder substitution
#------------------------------------------------------------------------------
function process_template_files() {
  echo "🔄 Replacing template placeholders..."
  echo "   Using: $GIT_ORG/$GIT_REPO"

  # Process manifest files
  if [ -d "$CALLER_DIR/manifests" ]; then
    for file in "$CALLER_DIR"/manifests/*.yaml "$CALLER_DIR"/manifests/*.yml; do
      if [ -f "$file" ]; then
        replace_placeholders "$file"
      fi
    done
  fi

  # Process GitHub workflow files
  if [ -d "$CALLER_DIR/.github/workflows" ]; then
    for file in "$CALLER_DIR"/.github/workflows/*.yaml "$CALLER_DIR"/.github/workflows/*.yml; do
      if [ -f "$file" ]; then
        replace_placeholders "$file"
      fi
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
  echo "   Removing: $TEMP_DIR"
  rm -rf "$TEMP_DIR"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Template setup complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📝 Next steps:"
  echo "   1. Review the files that were created"
  echo "   2. Run any setup commands in the template's README"
  echo "   3. Commit and push your project to GitHub"
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

# Check for --help before anything else (no prerequisites needed)
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

# Get template name from command line (optional)
TEMPLATE_NAME="${1:-}"

# Check prerequisites
check_prerequisites

# Detect and validate repo info before downloading anything
detect_and_validate_repo_info

# Show intro
clear
display_intro

# Run the process
download_templates
scan_templates
select_template "$TEMPLATE_NAME"
verify_template
copy_template_files
setup_github_workflows
merge_gitignore
install_template_tools "${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]:-}"
process_template_files

# Go back to original directory
cd "$CALLER_DIR"

cleanup_and_complete
