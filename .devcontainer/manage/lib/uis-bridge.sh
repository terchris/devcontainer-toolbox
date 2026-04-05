#!/bin/bash
# File: .devcontainer/manage/lib/uis-bridge.sh
# Description: Abstraction layer for DCT → UIS communication.
#              All UIS commands go through this bridge so the
#              communication method can change without rewriting callers.
#
# Usage: source "$SCRIPT_DIR/lib/uis-bridge.sh"
#
# Functions:
#   uis_bridge_check      — verify Docker CLI and UIS container are available
#   uis_bridge_run        — run a command in UIS container
#   uis_bridge_run_stdin  — run a command piping stdin (for init files)
#   uis_bridge_configure  — call uis configure, parse JSON response
#------------------------------------------------------------------------------

# Fixed container name (Decision per 8UIS in INVESTIGATE-unified-template-system.md)
UIS_CONTAINER="uis-provision-host"

#------------------------------------------------------------------------------
# Check prerequisites for UIS bridge
#
# Returns: 0 if ready, 1 if not (with error message)
#------------------------------------------------------------------------------
uis_bridge_check() {
  # Check Docker CLI
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker CLI is not installed."
    echo ""
    echo "   Install it with: dev-setup"
    echo "   (Select 'Docker CLI' from Infrastructure & Configuration)"
    echo ""
    echo "   Or directly: bash .devcontainer/additions/install-tool-docker-cli.sh"
    return 1
  fi

  # Check UIS container is running
  local status
  status=$(docker ps --filter "name=$UIS_CONTAINER" --format '{{.Status}}' 2>/dev/null)

  if [ -z "$status" ]; then
    echo "❌ UIS container '$UIS_CONTAINER' is not running."
    echo ""
    echo "   Start UIS on your host machine:"
    echo "   cd <uis-directory> && ./uis start"
    echo ""
    echo "   More info: https://uis.sovereignsky.no"
    return 1
  fi

  return 0
}

#------------------------------------------------------------------------------
# Run a command in the UIS container
#
# Arguments:
#   $@ — command and arguments (e.g., "configure postgresql --app myapp --json")
#
# Returns: exit code from docker exec
# Output: stdout/stderr from UIS command
#------------------------------------------------------------------------------
uis_bridge_run() {
  docker exec "$UIS_CONTAINER" uis "$@"
}

#------------------------------------------------------------------------------
# Run a command in UIS container with stdin piped (for init files)
#
# Arguments:
#   $@ — command and arguments
#
# Stdin: data to pipe to the command
# Returns: exit code from docker exec
#------------------------------------------------------------------------------
uis_bridge_run_stdin() {
  docker exec -i "$UIS_CONTAINER" uis "$@"
}

#------------------------------------------------------------------------------
# Call uis configure and parse the JSON response
#
# Arguments:
#   $1 — service name (e.g., "postgresql")
#   $2 — app name
#   $@ — additional args (--database, etc.)
#
# Optional stdin: init file content (if --init-file - is in args)
#
# Returns: 0 on success, 1 on error
# Sets globals:
#   UIS_RESPONSE       — full JSON response
#   UIS_STATUS         — "ok" or "error"
#   UIS_LOCAL_URL      — local connection URL (e.g., DATABASE_URL for local dev)
#   UIS_CLUSTER_URL    — cluster connection URL (for K8s deployment)
#   UIS_ERROR_PHASE    — error phase if failed
#   UIS_ERROR_DETAIL   — error detail if failed
#------------------------------------------------------------------------------
uis_bridge_configure() {
  local service="$1"
  local app_name="$2"
  shift 2

  local has_stdin=false
  local args=("configure" "$service" "--app" "$app_name" "--json")

  # Collect remaining args, detect --init-file -
  for arg in "$@"; do
    args+=("$arg")
    if [ "$arg" = "--init-file" ]; then
      has_stdin=true
    fi
  done

  # Run command, capturing stdout and stderr separately so we can surface
  # stderr as detail when UIS (or docker exec) doesn't emit a JSON envelope.
  local stdout_file stderr_file
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  if $has_stdin; then
    uis_bridge_run_stdin "${args[@]}" >"$stdout_file" 2>"$stderr_file"
  else
    uis_bridge_run "${args[@]}" >"$stdout_file" 2>"$stderr_file"
  fi
  local exit_code=$?

  local response stderr_content
  response=$(cat "$stdout_file")
  stderr_content=$(cat "$stderr_file")
  rm -f "$stdout_file" "$stderr_file"

  UIS_RESPONSE="$response"

  # Try JSON parse even when exit != 0 — UIS emits structured JSON error
  # envelopes on stdout with non-zero exit codes.
  if [ -n "$response" ]; then
    local parsed_status
    parsed_status=$(echo "$response" | jq -r '.status // empty' 2>/dev/null)
    if [ -n "$parsed_status" ]; then
      UIS_STATUS="$parsed_status"
      case "$UIS_STATUS" in
        ok|already_configured)
          UIS_LOCAL_URL=$(echo "$response" | jq -r '.local.database_url // .local.url // ""')
          UIS_CLUSTER_URL=$(echo "$response" | jq -r '.cluster.database_url // .cluster.url // ""')
          return 0
          ;;
        *)
          UIS_ERROR_PHASE=$(echo "$response" | jq -r '.phase // "unknown"')
          UIS_ERROR_DETAIL=$(echo "$response" | jq -r '.detail // "Unknown error"')
          return 1
          ;;
      esac
    fi
  fi

  # No parseable JSON — distinguish container-down from other failures.
  UIS_STATUS="error"
  if echo "$stderr_content" | grep -q "is not running\|No such container"; then
    UIS_ERROR_PHASE="connection"
    UIS_ERROR_DETAIL="UIS container '${UIS_CONTAINER}' is not running"
  else
    UIS_ERROR_PHASE="unknown"
    if [ -n "$stderr_content" ]; then
      UIS_ERROR_DETAIL="$stderr_content"
    else
      UIS_ERROR_DETAIL="uis configure failed (exit $exit_code) with no output"
    fi
  fi
  return 1
}
