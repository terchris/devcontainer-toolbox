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

# Source git identity library
source "$ADDITIONS_DIR/lib/git-identity.sh"

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
# Check prerequisites
#------------------------------------------------------------------------------
function check_prerequisites() {
  if ! command -v dialog >/dev/null 2>&1; then
    echo "❌ Error: dialog is not installed"
    echo "   sudo apt-get install dialog"
    exit 2
  fi
  if ! command -v unzip >/dev/null 2>&1; then
    echo "❌ Error: unzip is not installed"
    echo "   sudo apt-get install unzip"
    exit 2
  fi
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
  local template_owner="helpers-no"
  local template_repo="dev-templates"
  local template_branch="main"
  local zip_url="https://github.com/$template_owner/$template_repo/archive/refs/heads/$template_branch.zip"

  TEMP_DIR=$(mktemp -d)
  local zip_file="$TEMP_DIR/templates.zip"

  echo "📥 Fetching latest templates from GitHub..."
  echo "   Source: $zip_url"
  echo ""

  local curl_error
  if ! curl_error=$(curl -fsSL "$zip_url" -o "$zip_file" 2>&1); then
    echo "❌ Failed to download templates"
    echo ""
    echo "   URL: $zip_url"
    echo "   Error: $curl_error"
    echo ""
    echo "   Possible causes:"
    echo "   - No internet connection"
    echo "   - GitHub is unreachable (firewall, proxy, DNS)"
    echo ""
    echo "   To test, run:"
    echo "   curl -fsSL -o /tmp/test.zip \"$zip_url\""
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  if [ ! -s "$zip_file" ]; then
    echo "❌ Downloaded file is empty"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  if ! unzip -q "$zip_file" -d "$TEMP_DIR/" 2>/dev/null; then
    echo "❌ Failed to extract templates zip"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # GitHub archive extracts to <repo>-<branch>/ directory
  TEMPLATE_REPO_NAME="$template_repo-$template_branch"

  cd "$TEMP_DIR"

  if [ ! -d "$TEMPLATE_REPO_NAME/templates" ]; then
    echo "❌ Templates directory not found in downloaded archive"
    echo "   Expected: $TEMPLATE_REPO_NAME/templates/"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Templates fetched successfully"
  echo ""
}

#------------------------------------------------------------------------------
# Read TEMPLATE_INFO from template directory
#------------------------------------------------------------------------------
function read_template_info() {
  local template_dir="$1"
  local info_file="$template_dir/TEMPLATE_INFO"
  
  # Defaults
  INFO_NAME=$(basename "$template_dir")
  INFO_DESCRIPTION="No description"
  INFO_CATEGORY="UNCATEGORIZED"
  INFO_PURPOSE=""
  
  if [ -f "$info_file" ]; then
    # Unset variables to avoid pollution
    unset TEMPLATE_NAME TEMPLATE_DESCRIPTION TEMPLATE_CATEGORY TEMPLATE_PURPOSE
    
    source "$info_file"
    
    INFO_NAME="${TEMPLATE_NAME:-$INFO_NAME}"
    INFO_DESCRIPTION="${TEMPLATE_DESCRIPTION:-$INFO_DESCRIPTION}"
    INFO_CATEGORY="${TEMPLATE_CATEGORY:-$INFO_CATEGORY}"
    INFO_PURPOSE="${TEMPLATE_PURPOSE:-$INFO_PURPOSE}"
    
    # Clean up after sourcing
    unset TEMPLATE_NAME TEMPLATE_DESCRIPTION TEMPLATE_CATEGORY TEMPLATE_PURPOSE
  fi
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

  # Group by category
  declare -g -A CATEGORY_WEB_SERVER
  declare -g -A CATEGORY_WEB_APP
  declare -g -A CATEGORY_OTHER

  echo "📋 Scanning available templates..."
  for dir in "$TEMPLATE_REPO_NAME/templates"/*; do
    if [ -d "$dir" ]; then
      read_template_info "$dir"

      local idx=${#TEMPLATE_DIRS[@]}
      TEMPLATE_DIRS+=("$(basename "$dir")")
      TEMPLATE_NAMES+=("$INFO_NAME")
      TEMPLATE_DESCRIPTIONS+=("$INFO_DESCRIPTION")
      TEMPLATE_CATEGORIES+=("$INFO_CATEGORY")
      TEMPLATE_PURPOSES+=("$INFO_PURPOSE")

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

#------------------------------------------------------------------------------
# Show template details confirmation dialog
#------------------------------------------------------------------------------
function show_template_details() {
  local idx=$1
  local template_name="${TEMPLATE_NAMES[$idx]}"
  local template_desc="${TEMPLATE_DESCRIPTIONS[$idx]}"
  local template_category="${TEMPLATE_CATEGORIES[$idx]}"
  local template_purpose="${TEMPLATE_PURPOSES[$idx]}"
  
  # Build details text
  local details=""
  details+="Name: $template_name\n\n"
  details+="Category: $template_category\n\n"
  details+="Description:\n$template_desc\n\n"
  
  if [ -n "$template_purpose" ]; then
    details+="Purpose:\n$template_purpose\n\n"
  fi
  
  details+="Directory: ${TEMPLATE_DIRS[$idx]}"
  
  # Show confirmation dialog
  dialog --clear \
    --title "Template Details" \
    --yesno "$details\n\nDo you want to use this template?" \
    20 80
  
  return $?
}

#------------------------------------------------------------------------------
# Select template (interactive or from argument)
#------------------------------------------------------------------------------
function select_template() {
  local param_name="$1"
  
  if [ -n "$param_name" ]; then
    # Direct selection by directory name
    TEMPLATE_NAME="$param_name"
    
    if [ ! -d "$TEMPLATE_REPO_NAME/templates/$TEMPLATE_NAME" ]; then
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
  
  TEMPLATE_PATH="$TEMPLATE_REPO_NAME/templates/$TEMPLATE_NAME"
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

#------------------------------------------------------------------------------
# Replace placeholders in a single file
#------------------------------------------------------------------------------
function replace_placeholders() {
  local file=$1
  local temp_file
  temp_file=$(mktemp)

  if [ -f "$file" ]; then
    sed -e "s|{{GITHUB_USERNAME}}|$GIT_ORG|g" \
        -e "s|{{REPO_NAME}}|$GIT_REPO|g" "$file" > "$temp_file"

    if cat "$temp_file" > "$file"; then
      echo "   ✅ Updated $(basename "$file")"
    else
      echo "   ❌ Failed to update $(basename "$file")"
      rm -f "$temp_file"
      return 1
    fi
    rm -f "$temp_file"
  fi
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
# Main execution
#------------------------------------------------------------------------------

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
process_template_files

# Go back to original directory
cd "$CALLER_DIR"

cleanup_and_complete
