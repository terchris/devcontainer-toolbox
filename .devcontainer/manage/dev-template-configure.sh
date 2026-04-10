#!/bin/bash
# File: .devcontainer/manage/dev-template-configure.sh
# Description: Configure services declared in template-info.yaml.
#              Reads params and requires, calls UIS via uis-bridge,
#              writes .env with connection details.
#
# Usage: dev-template configure
#        dev-template configure --param app_name=myapp --param database_name=mydb
#
# Version: 1.0.0
#------------------------------------------------------------------------------
set -e

CALLER_DIR="$PWD"
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
ADDITIONS_DIR="$DEVCONTAINER_DIR/additions"

# Source libraries
source "$SCRIPT_DIR/lib/uis-bridge.sh"
source "$ADDITIONS_DIR/lib/git-identity.sh"

#------------------------------------------------------------------------------
# Script Metadata
#------------------------------------------------------------------------------
SCRIPT_ID="dev-template-configure"
SCRIPT_NAME="Template Configure"
SCRIPT_DESCRIPTION="Configure services for installed template"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"
SCRIPT_VERSION="1.0.0"

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
show_help() {
  echo ""
  echo "🔧 Template Configure v${SCRIPT_VERSION}"
  echo ""
  echo "Usage: dev-template configure [options]"
  echo ""
  echo "  dev-template configure                             Read params from template-info.yaml"
  echo "  dev-template configure --param app_name=myapp      Override params via CLI"
  echo "  TEMPLATE_PARAM_APP_NAME=myapp dev-template configure   Override via env vars"
  echo "  dev-template configure --help                      Show this help"
  echo ""
  echo "Reads template-info.yaml from the current directory, validates"
  echo "params, and calls UIS to create databases, expose services,"
  echo "and write .env with connection details."
  echo ""
  echo "Param priority (highest to lowest):"
  echo "  1. CLI args (--param key=value)"
  echo "  2. Environment variables (TEMPLATE_PARAM_KEY)"
  echo "  3. Values in template-info.yaml"
  echo ""
}

#------------------------------------------------------------------------------
# Read template-info.yaml (simple YAML parser using grep/sed)
# We only need: params, requires, install_type
#------------------------------------------------------------------------------
read_template_info_yaml() {
  local yaml_file="$1"

  if [ ! -f "$yaml_file" ]; then
    echo "❌ template-info.yaml not found in current directory."
    echo ""
    echo "   Run dev-template first to install a template."
    exit 1
  fi

  # Read simple top-level fields
  TEMPLATE_ID=$(grep '^id:' "$yaml_file" | head -1 | sed 's/^id:[[:space:]]*//' | tr -d '"')
  TEMPLATE_INSTALL_TYPE=$(grep '^install_type:' "$yaml_file" | head -1 | sed 's/^install_type:[[:space:]]*//' | tr -d '"')
}

#------------------------------------------------------------------------------
# Parse params from template-info.yaml
# Returns associative array PARAMS[key]=value
#------------------------------------------------------------------------------
parse_params() {
  local yaml_file="$1"
  declare -g -A PARAMS=()
  declare -g -a PARAM_KEYS=()

  local in_params=false
  while IFS= read -r line; do
    # Detect params section
    if [[ "$line" =~ ^params: ]]; then
      in_params=true
      continue
    fi

    # Exit params section on next top-level key
    if $in_params && [[ "$line" =~ ^[a-z] && ! "$line" =~ ^[[:space:]] ]]; then
      break
    fi

    # Parse param line: "  key: value" or "  key: """
    if $in_params && [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*(.*) ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"
      # Strip quotes and comments
      value=$(echo "$value" | sed 's/^"//;s/".*$//' | sed "s/^'//;s/'.*$//")
      PARAMS["$key"]="$value"
      PARAM_KEYS+=("$key")
    fi
  done < "$yaml_file"
}

#------------------------------------------------------------------------------
# Apply CLI args and env vars to params
#------------------------------------------------------------------------------
apply_param_overrides() {
  # Apply env vars (TEMPLATE_PARAM_APP_NAME -> app_name)
  for key in "${PARAM_KEYS[@]}"; do
    local env_key="TEMPLATE_PARAM_$(echo "$key" | tr '[:lower:]' '[:upper:]')"
    if [ -n "${!env_key:-}" ]; then
      PARAMS["$key"]="${!env_key}"
    fi
  done

  # Apply CLI args (highest priority)
  for override in "${CLI_PARAMS[@]}"; do
    local key="${override%%=*}"
    local value="${override#*=}"
    if [[ -n "${PARAMS[$key]+x}" ]]; then
      PARAMS["$key"]="$value"
    else
      echo "⚠️  Unknown param: $key (not in template-info.yaml)"
    fi
  done
}

#------------------------------------------------------------------------------
# Persist CLI-provided params back to template-info.yaml so future re-runs
# use the same values. Only writes back params supplied via --param flags,
# not env vars (env vars are for CI/CD with fresh checkouts).
#------------------------------------------------------------------------------
persist_cli_params_to_yaml() {
  local yaml_file="$1"
  local updated=0

  for override in "${CLI_PARAMS[@]}"; do
    local key="${override%%=*}"
    local value="${override#*=}"
    # Escape sed replacement specials: & and \
    local safe_value
    safe_value=$(printf '%s' "$value" | sed 's/[&\\]/\\&/g')
    # Update the indented "  key: ..." line (inside params: block)
    if grep -qE "^[[:space:]]+${key}:" "$yaml_file"; then
      sed -i "s|^\([[:space:]]\{1,\}\)${key}:[[:space:]]*.*|\1${key}: \"${safe_value}\"|" "$yaml_file"
      updated=$((updated + 1))
    fi
  done

  if [ $updated -gt 0 ]; then
    echo "💾 Persisted $updated CLI param(s) to template-info.yaml"
    echo ""
  fi
}

#------------------------------------------------------------------------------
# Validate all required params are filled
#------------------------------------------------------------------------------
validate_params() {
  local missing=()

  for key in "${PARAM_KEYS[@]}"; do
    if [ -z "${PARAMS[$key]}" ]; then
      missing+=("$key")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "❌ Missing required parameters in template-info.yaml:"
    echo ""
    for key in "${missing[@]}"; do
      echo "   params.$key"
    done
    echo ""
    echo "   Edit template-info.yaml and fill in the empty params,"
    echo "   or pass them via CLI: dev-template configure --param $key=value"
    exit 1
  fi
}

#------------------------------------------------------------------------------
# Substitute {{ params.* }} in a string
#------------------------------------------------------------------------------
substitute_params() {
  local text="$1"
  for key in "${PARAM_KEYS[@]}"; do
    text=$(echo "$text" | sed "s|{{ *params\.$key *}}|${PARAMS[$key]}|g")
  done
  echo "$text"
}

#------------------------------------------------------------------------------
# Parse requires section and configure services
#------------------------------------------------------------------------------
process_requires() {
  local yaml_file="$1"

  # Check if requires section exists
  if ! grep -q '^requires:' "$yaml_file"; then
    echo "ℹ️  No service requirements in template-info.yaml."
    return 0
  fi

  # Count services so we can show "1 service" or "3 services" in the header
  local n_requires
  n_requires=$(grep -c '^[[:space:]]*-[[:space:]]*service:' "$yaml_file")
  local svc_word="service requirement"
  [ "$n_requires" -ne 1 ] && svc_word="service requirements"
  echo "🔧 Configuring $n_requires $svc_word..."
  echo ""

  local configured=0
  local failed=0
  local skipped=0
  local failed_services=()
  local succeeded_services=()

  # Parse requires entries
  local current_service=""
  local current_database=""
  local current_init=""
  local current_env_var=""
  local in_requires=false
  local in_config=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^requires: ]]; then
      in_requires=true
      continue
    fi

    # Exit requires on next top-level key
    if $in_requires && [[ "$line" =~ ^[a-z] && ! "$line" =~ ^[[:space:]] ]]; then
      # Process last service
      if [ -n "$current_service" ]; then
        _configure_service "$current_service" "$current_database" "$current_init" "$current_env_var"
      fi
      break
    fi

    # New service entry: "  - service: postgresql"
    if $in_requires && [[ "$line" =~ ^[[:space:]]+-[[:space:]]+service:[[:space:]]*(.*) ]]; then
      # Process previous service first
      if [ -n "$current_service" ]; then
        _configure_service "$current_service" "$current_database" "$current_init" "$current_env_var"
      fi
      current_service="${BASH_REMATCH[1]}"
      current_database=""
      current_init=""
      current_env_var=""
      in_config=false
      continue
    fi

    # Optional env_var at requires-entry level (e.g., "    env_var: DATABASE_URL")
    if $in_requires && ! $in_config && [[ "$line" =~ ^[[:space:]]+env_var:[[:space:]]*(.*) ]]; then
      current_env_var=$(echo "${BASH_REMATCH[1]}" | tr -d '"' | tr -d "'")
      continue
    fi

    # Config section
    if $in_requires && [[ "$line" =~ ^[[:space:]]+config: ]]; then
      in_config=true
      continue
    fi

    # Config fields
    if $in_requires && $in_config; then
      if [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
        current_database=$(substitute_params "${BASH_REMATCH[1]}" | tr -d '"')
      elif [[ "$line" =~ ^[[:space:]]+init:[[:space:]]*(.*) ]]; then
        current_init=$(substitute_params "${BASH_REMATCH[1]}" | tr -d '"')
      fi
    fi
  done < "$yaml_file"

  # Process last service (if file doesn't end with another top-level key)
  if [ -n "$current_service" ]; then
    _configure_service "$current_service" "$current_database" "$current_init" "$current_env_var"
  fi

  # ─── Summary box ─────────────────────────────────────────────────
  local total_elapsed=$((SECONDS - ${TOTAL_START:-$SECONDS}))
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ $failed -eq 0 ]; then
    echo "✅ Configuration complete ($configured configured, $skipped skipped, $failed failed)"
  else
    echo "❌ Configuration incomplete ($configured configured, $skipped skipped, $failed failed)"
  fi
  echo "   Total time: ${total_elapsed}s"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ $failed -gt 0 ]; then
    echo ""
    for svc in "${failed_services[@]}"; do
      echo "   ❌ $svc"
    done
    echo ""
    echo "   Fix the issue and run: dev-template configure"
    echo ""
    return $failed
  fi

  # ─── Next steps ──────────────────────────────────────────────────
  if [ -n "${LAST_SERVICE:-}" ]; then
    echo ""
    echo "📋 Next steps:"
    if [ -n "${LAST_DATABASE:-}" ]; then
      echo "   • Verify the database:    uis connect $LAST_SERVICE $LAST_DATABASE"
    fi
    if [ -n "${LAST_SECRET_NAME:-}" ] && [ -n "${LAST_SECRET_NAMESPACE:-}" ]; then
      echo "   • Check the K8s secret:   kubectl get secret $LAST_SECRET_NAME -n $LAST_SECRET_NAMESPACE"
    fi
    echo "   • Check port forwards:    uis expose --status"
    echo "   • Run the app:            see README for run instructions"
    echo ""
  fi

  return 0
}

#------------------------------------------------------------------------------
# Internal: configure a single service via uis-bridge
#------------------------------------------------------------------------------
_configure_service() {
  local service="$1"
  local database="$2"
  local init_file="$3"
  local env_var="$4"
  local app_name="${PARAMS[app_name]:-$TEMPLATE_ID}"

  # Default env var name if not specified in template-info.yaml:
  #   data services → DATABASE_URL (conventional for web frameworks)
  #   other services → <SERVICE>_URL
  if [ -z "$env_var" ]; then
    case "$service" in
      postgresql|mysql|mariadb|mongodb)
        env_var="DATABASE_URL"
        ;;
      *)
        env_var=$(echo "${service}_URL" | tr '[:lower:]' '[:upper:]')
        ;;
    esac
  fi

  # ─── Section header ──────────────────────────────────────────────
  printf "   ─── %s " "$service"
  local pad_len=$((60 - ${#service}))
  [ "$pad_len" -lt 0 ] && pad_len=0
  printf '─%.0s' $(seq 1 $pad_len)
  echo ""

  # ─── Resolve config (namespace + secret_name_prefix) ─────────────
  # K8s namespace + secret name prefix (Phase 1, item 1.9).
  # namespace: subdomain → app_name → git repo
  # secret_name_prefix: always git repo (matches deployment.yaml's {{REPO_NAME}}-db)
  local namespace=""
  local secret_prefix=""
  if [ -n "${GIT_REPO:-}" ]; then
    namespace="${PARAMS[subdomain]:-${PARAMS[app_name]:-$GIT_REPO}}"
    secret_prefix="$GIT_REPO"
  fi

  echo "   Database:           ${database:-<none>}"
  echo "   K8s namespace:      ${namespace:-<none — legacy mode>}"
  echo "   K8s secret prefix:  ${secret_prefix:-<none — legacy mode>}"
  echo "   Env var:            $env_var"
  echo ""

  # Build the actual args array passed to uis_bridge_configure
  local extra_args=()
  [ -n "$database" ] && extra_args+=("--database" "$database")
  if [ -n "$namespace" ] && [ -n "$secret_prefix" ]; then
    extra_args+=("--namespace" "$namespace" "--secret-name-prefix" "$secret_prefix")
  fi

  # ─── Init file ───────────────────────────────────────────────────
  local temp_init=""
  if [ -n "$init_file" ]; then
    local init_path="$CALLER_DIR/$init_file"
    echo "   📄 Reading init file..."
    if [ ! -f "$init_path" ]; then
      echo "   ❌ Init file not found: $init_file"
      failed=$((failed + 1))
      failed_services+=("$service — init file not found: $init_file")
      return
    fi
    local size_bytes lines size_human
    size_bytes=$(wc -c < "$init_path" | tr -d ' ')
    lines=$(wc -l < "$init_path" | tr -d ' ')
    if [ "$size_bytes" -ge 1024 ]; then
      size_human=$(awk "BEGIN {printf \"%.1f KB\", $size_bytes/1024}")
    else
      size_human="$size_bytes bytes"
    fi
    echo "   ✓ Path: $init_file"
    echo "   ✓ Size: $size_human ($lines lines)"
    echo ""

    # Substitute params and write to a temp file
    temp_init=$(mktemp)
    substitute_params "$(cat "$init_path")" > "$temp_init"
    extra_args+=("--init-file" "-")
  fi

  # ─── Show the UIS command being called (copy-pasteable) ──────────
  echo "   📡 Calling UIS (you can copy-paste this to debug):"
  local cmd_line="docker exec -i uis-provision-host uis configure $service $app_name"
  # Group extra_args into flag/value pairs for pretty printing
  local i=0
  while [ $i -lt ${#extra_args[@]} ]; do
    local flag="${extra_args[$i]}"
    local value=""
    # Most of our flags take a value; --init-file - is also a flag+value pair
    if [ $((i + 1)) -lt ${#extra_args[@]} ]; then
      value="${extra_args[$((i + 1))]}"
      cmd_line+=" \\
        $flag $value"
      i=$((i + 2))
    else
      cmd_line+=" \\
        $flag"
      i=$((i + 1))
    fi
  done
  cmd_line+=" \\
        --json"
  if [ -n "$init_file" ]; then
    cmd_line+=" \\
        < $init_file"
  fi
  echo "      $cmd_line"
  echo ""

  # ─── Call UIS ────────────────────────────────────────────────────
  echo "   Waiting for UIS response..."
  local call_start=$SECONDS
  local call_result=0
  if [ -n "$temp_init" ]; then
    uis_bridge_configure "$service" "$app_name" "${extra_args[@]}" < "$temp_init" || call_result=$?
    rm -f "$temp_init"
  else
    uis_bridge_configure "$service" "$app_name" "${extra_args[@]}" || call_result=$?
  fi
  local call_elapsed=$((SECONDS - call_start))

  if [ "$call_result" -ne 0 ]; then
    echo "   ❌ Failed (took ${call_elapsed}s)"
    if [ -n "$UIS_ERROR_DETAIL" ]; then
      echo ""
      [ -n "$init_file" ] && echo "   Init file applied: $init_file"
      echo "   Error: $UIS_ERROR_DETAIL"
    fi
    failed=$((failed + 1))
    failed_services+=("$service — ${UIS_ERROR_DETAIL:-unknown error}")
    echo ""
    return
  fi
  echo "   ✓ Status: $UIS_STATUS (took ${call_elapsed}s)"
  echo ""

  # ─── Show what UIS created ───────────────────────────────────────
  echo "   📦 UIS created:"
  echo "      Database: ${UIS_DATABASE:-<unknown>}"
  echo "      Username: ${UIS_USERNAME:-<unknown>}"
  if [ -n "$UIS_PASSWORD" ]; then
    echo "      Password: *** (hidden)"
  fi
  echo ""

  # ─── Port-forward verification + diagram ─────────────────────────
  # UIS's JSON response says it created a port-forward, but we verify it
  # independently. We use TWO checks because each catches different failures:
  #   1. pgrep inside uis-provision-host — authoritative (process actually exists)
  #   2. TCP probe from DCT to host.docker.internal:port — what users actually care about
  # On Docker Desktop / Mac vpnkit gives false-positive TCP successes when the
  # port-forward process is dead, so the TCP check alone is insufficient.
  if [ -n "$UIS_LOCAL_HOST" ] && [ -n "$UIS_LOCAL_PORT" ]; then
    local pf_process_found=false
    local pf_tcp_open=false

    if docker exec uis-provision-host pgrep -f "kubectl.*port-forward.*${UIS_LOCAL_PORT}" >/dev/null 2>&1; then
      pf_process_found=true
    fi
    if timeout 2 bash -c "</dev/tcp/${UIS_LOCAL_HOST}/${UIS_LOCAL_PORT}" 2>/dev/null; then
      pf_tcp_open=true
    fi

    if $pf_process_found && $pf_tcp_open; then
      echo "   🔌 Port forward (verified reachable from DCT):"
    elif $pf_process_found && ! $pf_tcp_open; then
      echo "   ⚠ Port forward process exists but DCT can't reach it!"
      echo "      kubectl port-forward is running inside uis-provision-host,"
      echo "      but TCP to ${UIS_LOCAL_HOST}:${UIS_LOCAL_PORT} from DCT failed."
      echo "      Likely a Docker bridge/network issue."
      echo ""
    elif ! $pf_process_found && $pf_tcp_open; then
      echo "   ⚠ Port forward MISSING (Docker proxy false positive)"
      echo "      No kubectl port-forward process found inside uis-provision-host,"
      echo "      but Docker Desktop's vpnkit is accepting TCP handshakes anyway."
      echo "      DCT will appear to connect but get no data — your app will hang."
      echo "      Likely cause: UIS auto-expose silently failed."
      echo "      Fix: uis expose ${service}"
      echo ""
    else
      echo "   ⚠ Port forward NOT reachable!"
      echo "      No kubectl port-forward process found, no TCP listener."
      echo "      Likely cause: UIS auto-expose silently failed."
      echo "      Fix: uis expose ${service}"
      echo ""
    fi
    echo ""
    echo "      ┌─────────────────────────────────────────────────┐"
    printf  "      │  DCT  →  %-39s│  ← your app connects here\n" "${UIS_LOCAL_HOST}:${UIS_LOCAL_PORT}"
    echo "      └─────────────────────────────────────────────────┘"
    echo "                       ↕"
    echo "      ┌─────────────────────────────────────────────────┐"
    printf  "      │  Mac/Linux host  →  port %-23s│  ← Docker port-publish\n" "${UIS_LOCAL_PORT}"
    echo "      └─────────────────────────────────────────────────┘"
    echo "                       ↕"
    echo "      ┌─────────────────────────────────────────────────┐"
    printf  "      │  uis-provision-host container  →  port %-9s│  ← kubectl port-forward\n" "${UIS_LOCAL_PORT}"
    echo "      └─────────────────────────────────────────────────┘    lives inside this container"
    if [ -n "$UIS_CLUSTER_HOST" ] && [ -n "$UIS_CLUSTER_PORT" ]; then
      echo "                       ↕"
      echo "      ┌─────────────────────────────────────────────────┐"
      printf  "      │  K8s: %-42s│  ← actual ${service} pod\n" "${UIS_CLUSTER_HOST}:${UIS_CLUSTER_PORT}"
      echo "      └─────────────────────────────────────────────────┘"
    fi
    echo ""
    if $pf_process_found && $pf_tcp_open; then
      echo "      Survives DCT rebuilds. Dies if you restart uis-provision-host."
      echo "      Manage:  uis expose --status                (list all forwards)"
      echo "               uis expose ${service} --stop       (tear down this one)"
    fi
    echo ""
  fi

  # ─── Write .env ──────────────────────────────────────────────────
  if [ -n "$UIS_LOCAL_URL" ]; then
    echo "   💾 Writing local URL to .env..."
    local env_file="$CALLER_DIR/.env"
    if [ -f "$env_file" ] && grep -q "^${env_var}=" "$env_file"; then
      sed -i "s|^${env_var}=.*|${env_var}=${UIS_LOCAL_URL}|" "$env_file"
    else
      echo "${env_var}=${UIS_LOCAL_URL}" >> "$env_file"
    fi
    echo "   ✓ File:  $env_file"
    echo "   ✓ Key:   $env_var"
    # Mask password in display
    local masked_url
    masked_url=$(echo "$UIS_LOCAL_URL" | sed 's|://\([^:]*\):[^@]*@|://\1:***@|')
    echo "   ✓ Value: $masked_url"
    echo ""
  fi

  # ─── K8s Secret report ───────────────────────────────────────────
  if [ -n "${UIS_SECRET_NAME:-}" ] && [ -n "${UIS_SECRET_NAMESPACE:-}" ]; then
    echo "   🔐 K8s Secret (created by UIS for ArgoCD/in-cluster pods):"
    echo "      Name:      $UIS_SECRET_NAME"
    echo "      Namespace: $UIS_SECRET_NAMESPACE"
    echo "      Key:       ${UIS_SECRET_ENV_VAR:-$env_var}"
    echo "      Verify:    kubectl get secret $UIS_SECRET_NAME -n $UIS_SECRET_NAMESPACE"
  elif [ -n "$UIS_CLUSTER_URL" ]; then
    # Legacy fallback: no secret created (older UIS or no GIT_REPO).
    # Write to .env.cluster so callers that read it still work.
    local cluster_file="$CALLER_DIR/.env.cluster"
    if [ -f "$cluster_file" ] && grep -q "^${env_var}=" "$cluster_file"; then
      sed -i "s|^${env_var}=.*|${env_var}=${UIS_CLUSTER_URL}|" "$cluster_file"
    else
      echo "${env_var}=${UIS_CLUSTER_URL}" >> "$cluster_file"
    fi
    echo "   ⚠ Legacy mode: cluster URL written to $cluster_file (no K8s secret)"
  fi

  # Bookkeeping for the summary
  if [ "$UIS_STATUS" = "already_configured" ]; then
    skipped=$((skipped + 1))
  else
    configured=$((configured + 1))
  fi
  succeeded_services+=("$service")

  # Remember last successful service for the "Next steps" section
  LAST_SERVICE="$service"
  LAST_DATABASE="$UIS_DATABASE"
  LAST_SECRET_NAME="$UIS_SECRET_NAME"
  LAST_SECRET_NAMESPACE="$UIS_SECRET_NAMESPACE"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

# Parse CLI args
CLI_PARAMS=()

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --param)
      if [[ -n "$2" && "$2" == *=* ]]; then
        CLI_PARAMS+=("$2")
        shift 2
      else
        echo "Error: --param requires key=value format" >&2
        exit 1
      fi
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      echo "Usage: dev-template configure [--param key=value ...]" >&2
      exit 1
      ;;
  esac
done

echo ""
echo "🔧 Template Configure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_START=$SECONDS

# ─── Check UIS bridge ────────────────────────────────────────────────────────
echo "🔌 Checking UIS bridge..."
if ! uis_bridge_check; then
  exit 1
fi
echo "   ✓ uis-provision-host container is running"
echo ""

# ─── Detect git identity ─────────────────────────────────────────────────────
# Best-effort: if there's no git remote, GIT_REPO will be empty and we fall
# back to legacy mode (no K8s secret created).
echo "🔍 Detecting git identity..."
detect_git_identity "$CALLER_DIR" 2>/dev/null || true
if [ -n "${GIT_REPO_FULL:-}" ]; then
  echo "   ✓ Repo:   $GIT_REPO_FULL"
  echo "   ✓ Branch: ${GIT_BRANCH:-unknown}"
else
  echo "   ⚠ No git remote — will use legacy mode (no K8s secret)"
fi
echo ""

# ─── Read template-info.yaml ─────────────────────────────────────────────────
echo "📄 Reading template-info.yaml..."
YAML_FILE="$CALLER_DIR/template-info.yaml"
read_template_info_yaml "$YAML_FILE"
echo "   ✓ File: $YAML_FILE"
echo "   ✓ ID:   $TEMPLATE_ID"
echo "   ✓ Type: $TEMPLATE_INSTALL_TYPE"
echo ""

# ─── Parse params ────────────────────────────────────────────────────────────
parse_params "$YAML_FILE"

if [ ${#PARAM_KEYS[@]} -gt 0 ]; then
  apply_param_overrides
  validate_params

  # Persist CLI args to YAML so re-runs don't need them again
  if [ ${#CLI_PARAMS[@]} -gt 0 ]; then
    persist_cli_params_to_yaml "$YAML_FILE"
  fi

  echo "📝 Parameters:"
  # Compute longest key for alignment
  _max_key_width=0
  for key in "${PARAM_KEYS[@]}"; do
    [ ${#key} -gt $_max_key_width ] && _max_key_width=${#key}
  done
  for key in "${PARAM_KEYS[@]}"; do
    printf "   %-${_max_key_width}s = %s\n" "$key" "${PARAMS[$key]}"
  done
  echo ""
fi

# ─── Process requires ────────────────────────────────────────────────────────
# TOTAL_START is read by process_requires for the summary box
process_requires "$YAML_FILE"
exit $?
