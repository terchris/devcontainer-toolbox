#!/bin/bash
# File: .devcontainer/additions/cmd-publish-github.sh
#
# Usage:
#   cmd-publish-github.sh --sync <github-repo-url>    # Sync repo to GitHub
#   cmd-publish-github.sh --diff <github-repo-url>    # Preview changes without pushing
#   cmd-publish-github.sh --status <github-repo-url>  # Check if GitHub is up to date
#   cmd-publish-github.sh --help                       # Show all commands
#
# Purpose:
#   Publish the current repo to a public GitHub mirror with clean git history.
#   First run creates the repo with a single commit. Subsequent runs sync changes.
#   Source repo history is never leaked — GitHub builds its own commit log.
#
# Author: terchris
# Created: February 2026
#
#------------------------------------------------------------------------------
# SCRIPT METADATA - For dev-setup.sh discovery
#------------------------------------------------------------------------------

SCRIPT_ID="cmd-publish-github"
SCRIPT_NAME="GitHub Publisher"
SCRIPT_VER="0.1.0"
SCRIPT_DESCRIPTION="Sync current repo to a public GitHub mirror with clean history"
SCRIPT_CATEGORY="INFRA_CONFIG"
SCRIPT_CHECK_COMMAND="command -v gh"
SCRIPT_PREREQUISITES=""

# --- Extended metadata (for website) ---
SCRIPT_TAGS="github publish mirror sync open-source"
SCRIPT_ABSTRACT="Publish a repo to GitHub with clean history, stripping source commit log."
SCRIPT_LOGO="cmd-publish-github-logo.svg"
SCRIPT_WEBSITE="https://cli.github.com/"
SCRIPT_SUMMARY="Export tracked files from a private repo and push to a public GitHub mirror with clean commit history. Handles first-time publish and incremental syncs. Source history is never leaked. Validates prerequisites including gh CLI authentication and repo reachability."

#------------------------------------------------------------------------------
# COMMAND DEFINITIONS - Single source of truth
#------------------------------------------------------------------------------

# Format: category|flag|description|function|requires_arg|param_prompt
SCRIPT_COMMANDS=(
    "Publish|--sync|Export and push to GitHub (creates or updates)|cmd_sync|true|Enter GitHub repo URL"
    "Publish|--diff|Preview what would change without pushing|cmd_diff|true|Enter GitHub repo URL"
    "Publish|--status|Check if GitHub mirror is up to date|cmd_status|true|Enter GitHub repo URL"
)

#------------------------------------------------------------------------------

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

# Configuration
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORK_DIR="/tmp/publish-github-work"
EXPORT_DIR="/tmp/publish-github-export"
SELF_SCRIPT="$(basename "$0")"
YES_FLAG=false

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

check_prerequisites() {
    local github_url="${1:-}"
    local errors=0

    log_info "Checking prerequisites..."

    # Check git
    if ! command -v git >/dev/null 2>&1; then
        log_error "git is not installed"
        errors=1
    fi

    # Check we are in a git repo
    if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not inside a git repository"
        errors=1
    fi

    # Check gh CLI is available
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is not installed"
        log_info "Install: https://cli.github.com/"
        errors=1
    fi

    # Check GitHub authentication
    if command -v gh >/dev/null 2>&1; then
        if ! gh auth status >/dev/null 2>&1; then
            log_error "Not logged in to GitHub"
            log_info "Run: gh auth login"
            errors=1
        else
            local gh_user
            gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
            log_info "GitHub user: $gh_user"
        fi
    fi

    # Check uncommitted changes in source repo
    cd "$REPO_ROOT"
    if ! git diff --quiet HEAD 2>/dev/null; then
        log_warning "Source repo has uncommitted changes -- they will NOT be included"
        log_info "Only committed files (git archive HEAD) are exported"
    fi

    # Validate GitHub URL format
    if [[ -n "$github_url" ]]; then
        if [[ ! "$github_url" =~ ^(https://github\.com/|git@github\.com:) ]]; then
            log_error "URL does not look like a GitHub repo: $github_url"
            log_info "Expected: https://github.com/user/repo.git or git@github.com:user/repo.git"
            errors=1
        fi
    fi

    # Check GitHub repo is reachable
    if [[ -n "$github_url" && $errors -eq 0 ]]; then
        if ! git ls-remote "$github_url" >/dev/null 2>&1; then
            log_error "Cannot reach $github_url"
            log_info "Make sure the repo exists on GitHub and you have push access."
            log_info "Create it at: https://github.com/new (no README, no license, no .gitignore)"
            errors=1
        fi
    fi

    if [[ $errors -eq 1 ]]; then
        echo ""
        log_error "Prerequisites not met. Fix the issues above and try again."
        return 1
    fi

    log_success "Prerequisites OK"
    echo ""
    return 0
}

confirm_publish() {
    local github_url="$1"

    if [[ "$YES_FLAG" == true ]]; then
        return 0
    fi

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  WARNING: You are about to publish to GitHub"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "  This will export ALL tracked files from:"
    echo "    $REPO_ROOT"
    echo ""
    echo "  And push them to the PUBLIC GitHub repo:"
    echo "    $github_url"
    echo ""
    echo "  All files will be publicly visible on the internet."
    echo "  Source commit history is NOT included (clean export)."
    echo ""
    echo "  Use --diff first to preview what will be pushed."
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo ""
    read -rp "Continue? (yes/no) "
    echo ""

    if [[ ! "$REPLY" =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Aborted."
        return 1
    fi

    return 0
}

export_source_files() {
    rm -rf "$EXPORT_DIR"
    mkdir -p "$EXPORT_DIR"
    cd "$REPO_ROOT"
    git archive HEAD | tar -x -C "$EXPORT_DIR"

    # Remove this publish script from the export (not needed in the public repo)
    find "$EXPORT_DIR" -name "$SELF_SCRIPT" -delete 2>/dev/null || true

    local file_count
    file_count=$(find "$EXPORT_DIR" -type f | wc -l)
    echo "Exported $file_count tracked files from source repo"
}

is_first_time() {
    local github_url="$1"
    # Check if remote repo has any commits
    if git ls-remote "$github_url" 2>/dev/null | grep -q "refs/heads/"; then
        return 1  # has commits = not first time
    else
        return 0  # no commits = first time
    fi
}

cleanup() {
    rm -rf "$EXPORT_DIR"
}

#------------------------------------------------------------------------------
# Command Functions
#------------------------------------------------------------------------------

cmd_sync() {
    local github_url="$1"

    echo "════════════════════════════════════════════════════════"
    echo "🚀 Sync to GitHub"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Source:  $REPO_ROOT"
    echo "Target:  $github_url"
    echo ""

    confirm_publish "$github_url" || return 1

    export_source_files
    echo ""

    if is_first_time "$github_url"; then
        log_info "First-time publish -- creating initial commit"
        echo ""

        rm -rf "$WORK_DIR"
        mkdir -p "$WORK_DIR"
        cp -a "$EXPORT_DIR/." "$WORK_DIR/"

        cd "$WORK_DIR"
        git init
        git add -A
        git commit -m "Initial commit"
        git remote add origin "$github_url"
        git branch -M main
        git push -u origin main

        echo ""
        log_success "First-time publish complete"
    else
        log_info "Updating existing GitHub repo"
        echo ""

        rm -rf "$WORK_DIR"
        git clone "$github_url" "$WORK_DIR"
        cd "$WORK_DIR"

        # Remove all tracked files (keep .git)
        git rm -rf . >/dev/null 2>&1 || true

        # Copy in latest exported files
        cp -a "$EXPORT_DIR/." "$WORK_DIR/"

        # Stage everything
        git add -A

        # Check for changes
        if git diff --cached --quiet; then
            log_success "No changes -- GitHub repo is already up to date"
            cleanup
            return 0
        fi

        echo "Changes:"
        git diff --cached --stat
        echo ""

        local timestamp
        timestamp=$(date +"%Y-%m-%d %H:%M")
        git commit -m "Update $timestamp"
        git push

        echo ""
        log_success "Sync complete"
    fi

    cleanup
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo ""
}

cmd_diff() {
    local github_url="$1"

    echo "════════════════════════════════════════════════════════"
    echo "📋 Preview changes (dry run)"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Source:  $REPO_ROOT"
    echo "Target:  $github_url"
    echo ""

    export_source_files
    echo ""

    if is_first_time "$github_url"; then
        log_info "GitHub repo is empty -- first sync will push all files"
        local file_count
        file_count=$(find "$EXPORT_DIR" -type f | wc -l)
        echo "Files to push: $file_count"
        cleanup
        return 0
    fi

    rm -rf "$WORK_DIR"
    git clone "$github_url" "$WORK_DIR"
    cd "$WORK_DIR"

    git rm -rf . >/dev/null 2>&1 || true
    cp -a "$EXPORT_DIR/." "$WORK_DIR/"
    git add -A

    if git diff --cached --quiet; then
        log_success "No changes -- GitHub repo is already up to date"
    else
        echo "Changes that would be pushed:"
        echo ""
        git diff --cached --stat
        echo ""
        log_info "Run --sync to push these changes"
    fi

    cleanup
    rm -rf "$WORK_DIR"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo ""
}

cmd_status() {
    local github_url="$1"

    echo "════════════════════════════════════════════════════════"
    echo "📊 GitHub mirror status"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Source:  $REPO_ROOT"
    echo "Target:  $github_url"
    echo ""

    if is_first_time "$github_url"; then
        log_warning "GitHub repo exists but has no commits"
        log_info "Run --sync to do the initial publish"
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo ""
        return 0
    fi

    # Quick check: export and compare
    export_source_files
    echo ""

    rm -rf "$WORK_DIR"
    git clone --depth 1 "$github_url" "$WORK_DIR" 2>/dev/null
    cd "$WORK_DIR"

    git rm -rf . >/dev/null 2>&1 || true
    cp -a "$EXPORT_DIR/." "$WORK_DIR/"
    git add -A

    if git diff --cached --quiet; then
        log_success "GitHub mirror is up to date"
    else
        local changed
        changed=$(git diff --cached --stat | tail -1)
        log_warning "GitHub mirror is behind: $changed"
        log_info "Run --sync to update"
    fi

    cleanup
    rm -rf "$WORK_DIR"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo ""
}

#------------------------------------------------------------------------------
# Help and Argument Parsing
#------------------------------------------------------------------------------

show_help() {
    # Source framework if not already loaded
    if ! declare -f cmd_framework_generate_help >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/lib/cmd-framework.sh"
    fi

    # Generate help from SCRIPT_COMMANDS array
    cmd_framework_generate_help SCRIPT_COMMANDS "cmd-publish-github.sh" "$SCRIPT_VER"

    # Add examples and details
    echo ""
    echo "Options:"
    echo "  --yes                                  Skip confirmation prompt"
    echo ""
    echo "Examples:"
    echo "  cmd-publish-github.sh --diff https://github.com/user/repo.git"
    echo "  cmd-publish-github.sh --sync https://github.com/user/repo.git"
    echo "  cmd-publish-github.sh --sync --yes https://github.com/user/repo.git"
    echo ""
    echo "How it works:"
    echo "  First run:  exports all tracked files, creates fresh repo, pushes"
    echo "  Later runs: clones GitHub repo, replaces files, commits diff, pushes"
    echo ""
    echo "  Source commit history is never included. The GitHub repo builds"
    echo "  its own clean history with one commit per sync."
    echo ""
    echo "Prerequisites:"
    echo "  GitHub CLI (gh) installed and authenticated: gh auth login"
    echo "  Target repo must exist on GitHub (create at https://github.com/new)"
    echo ""
}

parse_args() {
    # Source framework if not already loaded
    if ! declare -f cmd_framework_parse_args >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/lib/cmd-framework.sh"
    fi

    # Use framework to parse arguments
    cmd_framework_parse_args SCRIPT_COMMANDS "cmd-publish-github.sh" "$@"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {
    # Show help without checking prerequisites
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_help
        exit 0
    fi

    # Extract --yes flag from anywhere in args before parsing
    local args=()
    for arg in "$@"; do
        if [[ "$arg" == "--yes" || "$arg" == "-y" ]]; then
            YES_FLAG=true
        else
            args+=("$arg")
        fi
    done

    # Need at least a command after extracting --yes
    if [ ${#args[@]} -eq 0 ]; then
        show_help
        exit 0
    fi

    # Extract the GitHub URL for prerequisite checking
    local github_url=""
    if [ ${#args[@]} -ge 2 ]; then
        github_url="${args[1]}"
    fi

    # Check prerequisites
    check_prerequisites "$github_url" || exit 1

    # Parse and execute command
    parse_args "${args[@]}"
}

# Run main function
main "$@"
