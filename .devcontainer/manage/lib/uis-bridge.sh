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
#   uis_bridge_run        — run a command in UIS container (no TTY, no stdin)
#   uis_bridge_run_stdin  — run a command piping stdin (for init files)
#   uis_bridge_run_tty    — run a command with TTY (for interactive commands)
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
  # Check Docker CLI (provided by docker-outside-of-docker devcontainer feature)
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker CLI is not available."
    echo ""
    echo "   This devcontainer should have it via the docker-outside-of-docker"
    echo "   feature. Check .devcontainer/devcontainer.json includes:"
    echo '   "features": { "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {} }'
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
# Run a command in UIS container with a TTY allocated (for interactive commands
# like `uis connect`, `uis status`, etc. that produce formatted/coloured output)
#
# Arguments:
#   $@ — command and arguments
#
# Returns: exit code from docker exec
#------------------------------------------------------------------------------
uis_bridge_run_tty() {
  docker exec -it "$UIS_CONTAINER" uis "$@"
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
#   UIS_RESPONSE         — full JSON response
#   UIS_STATUS           — "ok", "already_configured", or "error"
#   UIS_LOCAL_URL        — local connection URL (e.g., DATABASE_URL for local dev)
#   UIS_LOCAL_HOST       — local host (e.g., "host.docker.internal")
#   UIS_LOCAL_PORT       — local port (e.g., 35432, the auto-exposed port-forward)
#   UIS_CLUSTER_URL      — cluster connection URL
#   UIS_CLUSTER_HOST     — in-cluster host (e.g., "postgresql.default.svc.cluster.local")
#   UIS_CLUSTER_PORT     — in-cluster port (e.g., 5432)
#   UIS_DATABASE         — database name UIS created
#   UIS_USERNAME         — username UIS created
#   UIS_PASSWORD         — password UIS generated (handle with care; do not log)
#   UIS_SECRET_NAME      — K8s secret name (set when --namespace + --secret-name-prefix passed)
#   UIS_SECRET_NAMESPACE — K8s namespace where the secret lives
#   UIS_SECRET_ENV_VAR   — env var name in the K8s secret (e.g., DATABASE_URL)
#   UIS_ERROR_PHASE      — error phase if failed
#   UIS_ERROR_DETAIL     — error detail if failed
#------------------------------------------------------------------------------
uis_bridge_configure() {
  local service="$1"
  local app_name="$2"
  shift 2

  # Reset all output fields so callers never read stale values from a previous call
  UIS_RESPONSE=""
  UIS_STATUS=""
  UIS_LOCAL_URL=""
  UIS_LOCAL_HOST=""
  UIS_LOCAL_PORT=""
  UIS_CLUSTER_URL=""
  UIS_CLUSTER_HOST=""
  UIS_CLUSTER_PORT=""
  UIS_DATABASE=""
  UIS_USERNAME=""
  UIS_PASSWORD=""
  UIS_SECRET_NAME=""
  UIS_SECRET_NAMESPACE=""
  UIS_SECRET_ENV_VAR=""
  UIS_ERROR_PHASE=""
  UIS_ERROR_DETAIL=""

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
          UIS_LOCAL_HOST=$(echo "$response" | jq -r '.local.host // ""')
          UIS_LOCAL_PORT=$(echo "$response" | jq -r '.local.port // ""')
          UIS_CLUSTER_URL=$(echo "$response" | jq -r '.cluster.database_url // .cluster.url // ""')
          UIS_CLUSTER_HOST=$(echo "$response" | jq -r '.cluster.host // ""')
          UIS_CLUSTER_PORT=$(echo "$response" | jq -r '.cluster.port // ""')
          UIS_DATABASE=$(echo "$response" | jq -r '.database // ""')
          UIS_USERNAME=$(echo "$response" | jq -r '.username // ""')
          UIS_PASSWORD=$(echo "$response" | jq -r '.password // ""')
          # K8s Secret fields (set when --namespace + --secret-name-prefix passed)
          UIS_SECRET_NAME=$(echo "$response" | jq -r '.secret_name // ""')
          UIS_SECRET_NAMESPACE=$(echo "$response" | jq -r '.secret_namespace // ""')
          UIS_SECRET_ENV_VAR=$(echo "$response" | jq -r '.env_var // ""')
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
