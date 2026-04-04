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

  echo "🔧 Configuring services..."
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
        _configure_service "$current_service" "$current_database" "$current_init"
      fi
      break
    fi

    # New service entry: "  - service: postgresql"
    if $in_requires && [[ "$line" =~ ^[[:space:]]+-[[:space:]]+service:[[:space:]]*(.*) ]]; then
      # Process previous service first
      if [ -n "$current_service" ]; then
        _configure_service "$current_service" "$current_database" "$current_init"
      fi
      current_service="${BASH_REMATCH[1]}"
      current_database=""
      current_init=""
      in_config=false
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
    _configure_service "$current_service" "$current_database" "$current_init"
  fi

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ $failed -eq 0 ]; then
    echo "✅ Configuration complete!"
  else
    echo "❌ Configuration incomplete:"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  for svc in "${succeeded_services[@]}"; do
    echo "   ✅ $svc"
  done
  for svc in "${failed_services[@]}"; do
    echo "   ❌ $svc"
  done

  if [ $failed -gt 0 ]; then
    echo ""
    echo "   Fix the issue and run: dev-template configure"
  fi
  echo ""

  return $failed
}

#------------------------------------------------------------------------------
# Internal: configure a single service via uis-bridge
#------------------------------------------------------------------------------
_configure_service() {
  local service="$1"
  local database="$2"
  local init_file="$3"
  local app_name="${PARAMS[app_name]:-$TEMPLATE_ID}"

  echo "   📦 Configuring $service..."

  # Build args
  local extra_args=()
  [ -n "$database" ] && extra_args+=("--database" "$database")

  # Handle init file
  if [ -n "$init_file" ]; then
    local init_path="$CALLER_DIR/$init_file"
    if [ ! -f "$init_path" ]; then
      echo "   ⚠️  Init file not found: $init_file"
      failed=$((failed + 1))
      failed_services+=("$service — init file not found: $init_file")
      return
    fi

    # Substitute params in init file and pipe via stdin
    local temp_init
    temp_init=$(mktemp)
    substitute_params "$(cat "$init_path")" > "$temp_init"

    extra_args+=("--init-file" "-")
    if uis_bridge_configure "$service" "$app_name" "${extra_args[@]}" < "$temp_init"; then
      rm -f "$temp_init"
    else
      rm -f "$temp_init"
      echo "   ❌ Failed to configure $service"
      if [ -n "$UIS_ERROR_DETAIL" ]; then
        echo ""
        echo "   Init file failed: $init_file (applied to $service)"
        echo "   $UIS_ERROR_DETAIL"
      fi
      failed=$((failed + 1))
      failed_services+=("$service — $UIS_ERROR_DETAIL")
      return
    fi
  else
    if ! uis_bridge_configure "$service" "$app_name" "${extra_args[@]}"; then
      echo "   ❌ Failed to configure $service"
      if [ -n "$UIS_ERROR_DETAIL" ]; then
        echo "   $UIS_ERROR_DETAIL"
      fi
      failed=$((failed + 1))
      failed_services+=("$service — ${UIS_ERROR_DETAIL:-unknown error}")
      return
    fi
  fi

  # Success
  if [ "$UIS_STATUS" = "already_configured" ]; then
    echo "   ⏭️  $service — already configured"
    skipped=$((skipped + 1))
  else
    echo "   ✅ $service — configured"
    configured=$((configured + 1))
  fi
  succeeded_services+=("$service")

  # Write connection details to .env
  if [ -n "$UIS_LOCAL_URL" ]; then
    local env_key
    env_key=$(echo "${service}_URL" | tr '[:lower:]' '[:upper:]')
    # Append to .env (create if doesn't exist)
    if [ -f "$CALLER_DIR/.env" ] && grep -q "^${env_key}=" "$CALLER_DIR/.env"; then
      # Update existing
      sed -i "s|^${env_key}=.*|${env_key}=${UIS_LOCAL_URL}|" "$CALLER_DIR/.env"
    else
      echo "${env_key}=${UIS_LOCAL_URL}" >> "$CALLER_DIR/.env"
    fi
    echo "   → .env: ${env_key}=${UIS_LOCAL_URL}"
  fi

  if [ -n "$UIS_CLUSTER_URL" ]; then
    local env_key
    env_key=$(echo "${service}_URL" | tr '[:lower:]' '[:upper:]')
    if [ -f "$CALLER_DIR/.env.cluster" ] && grep -q "^${env_key}=" "$CALLER_DIR/.env.cluster"; then
      sed -i "s|^${env_key}=.*|${env_key}=${UIS_CLUSTER_URL}|" "$CALLER_DIR/.env.cluster"
    else
      echo "${env_key}=${UIS_CLUSTER_URL}" >> "$CALLER_DIR/.env.cluster"
    fi
  fi

  echo ""
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

# Check UIS bridge prerequisites
if ! uis_bridge_check; then
  exit 1
fi

# Read template-info.yaml
YAML_FILE="$CALLER_DIR/template-info.yaml"
read_template_info_yaml "$YAML_FILE"

echo "📋 Template: $TEMPLATE_ID (install_type: $TEMPLATE_INSTALL_TYPE)"
echo ""

# Parse and validate params
parse_params "$YAML_FILE"

if [ ${#PARAM_KEYS[@]} -gt 0 ]; then
  apply_param_overrides
  validate_params

  echo "📝 Parameters:"
  for key in "${PARAM_KEYS[@]}"; do
    echo "   $key = ${PARAMS[$key]}"
  done
  echo ""
fi

# Process requires
process_requires "$YAML_FILE"
