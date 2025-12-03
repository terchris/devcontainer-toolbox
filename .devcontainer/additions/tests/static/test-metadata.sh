#!/bin/bash
# file: .devcontainer/additions/tests/static/test-metadata.sh
#
# DESCRIPTION: Validates that all scripts have required metadata fields
# PURPOSE: Ensures scripts follow the template contracts for automatic discovery
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-framework.sh"

#------------------------------------------------------------------------------
# TEST FUNCTIONS
#------------------------------------------------------------------------------

test_install_scripts_metadata() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "install-*.sh" "$filter"); do
        local name=$(basename "$script")
        local missing=""

        # Check required fields
        local script_id=$(grep -m 1 "^SCRIPT_ID=" "$script" 2>/dev/null | cut -d'"' -f2)
        local script_name=$(grep -m 1 "^SCRIPT_NAME=" "$script" 2>/dev/null | cut -d'"' -f2)
        local script_desc=$(grep -m 1 "^SCRIPT_DESCRIPTION=" "$script" 2>/dev/null | cut -d'"' -f2)
        local script_cat=$(grep -m 1 "^SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)
        local check_cmd=$(grep -m 1 "^CHECK_INSTALLED_COMMAND=" "$script" 2>/dev/null | cut -d'"' -f2)

        [[ -z "$script_id" ]] && missing+="SCRIPT_ID "
        [[ -z "$script_name" ]] && missing+="SCRIPT_NAME "
        [[ -z "$script_desc" ]] && missing+="SCRIPT_DESCRIPTION "
        [[ -z "$script_cat" ]] && missing+="SCRIPT_CATEGORY "
        [[ -z "$check_cmd" ]] && missing+="CHECK_INSTALLED_COMMAND "

        if [[ -n "$missing" ]]; then
            echo "  ✗ $name - missing: $missing"
            ((failed++))
        else
            echo "  ✓ $name"
        fi
    done

    return $failed
}

test_config_scripts_metadata() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "config-*.sh" "$filter"); do
        local name=$(basename "$script")
        local missing=""

        # Check required fields
        local config_name=$(grep -m 1 "^CONFIG_NAME=" "$script" 2>/dev/null | cut -d'"' -f2)
        local config_desc=$(grep -m 1 "^CONFIG_DESCRIPTION=" "$script" 2>/dev/null | cut -d'"' -f2)
        local config_cat=$(grep -m 1 "^CONFIG_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)
        local check_cmd=$(grep -m 1 "^CHECK_CONFIGURED_COMMAND=" "$script" 2>/dev/null | cut -d'"' -f2)

        [[ -z "$config_name" ]] && missing+="CONFIG_NAME "
        [[ -z "$config_desc" ]] && missing+="CONFIG_DESCRIPTION "
        [[ -z "$config_cat" ]] && missing+="CONFIG_CATEGORY "
        [[ -z "$check_cmd" ]] && missing+="CHECK_CONFIGURED_COMMAND "

        if [[ -n "$missing" ]]; then
            echo "  ✗ $name - missing: $missing"
            ((failed++))
        else
            echo "  ✓ $name"
        fi
    done

    return $failed
}

test_service_scripts_metadata() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "service-*.sh" "$filter"); do
        local name=$(basename "$script")
        local missing=""

        # Check required fields
        local svc_name=$(grep -m 1 "^SERVICE_SCRIPT_NAME=" "$script" 2>/dev/null | cut -d'"' -f2)
        local svc_desc=$(grep -m 1 "^SERVICE_SCRIPT_DESCRIPTION=" "$script" 2>/dev/null | cut -d'"' -f2)
        local svc_cat=$(grep -m 1 "^SERVICE_SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)

        [[ -z "$svc_name" ]] && missing+="SERVICE_SCRIPT_NAME "
        [[ -z "$svc_desc" ]] && missing+="SERVICE_SCRIPT_DESCRIPTION "
        [[ -z "$svc_cat" ]] && missing+="SERVICE_SCRIPT_CATEGORY "

        # Check COMMANDS array exists
        if ! grep -q "^COMMANDS=(" "$script" 2>/dev/null; then
            missing+="COMMANDS "
        fi

        if [[ -n "$missing" ]]; then
            echo "  ✗ $name - missing: $missing"
            ((failed++))
        else
            echo "  ✓ $name"
        fi
    done

    return $failed
}

test_cmd_scripts_metadata() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "cmd-*.sh" "$filter"); do
        local name=$(basename "$script")
        local missing=""

        # Check required fields
        local cmd_name=$(grep -m 1 "^CMD_SCRIPT_NAME=" "$script" 2>/dev/null | cut -d'"' -f2)
        local cmd_desc=$(grep -m 1 "^CMD_SCRIPT_DESCRIPTION=" "$script" 2>/dev/null | cut -d'"' -f2)
        local cmd_cat=$(grep -m 1 "^CMD_SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)

        [[ -z "$cmd_name" ]] && missing+="CMD_SCRIPT_NAME "
        [[ -z "$cmd_desc" ]] && missing+="CMD_SCRIPT_DESCRIPTION "
        [[ -z "$cmd_cat" ]] && missing+="CMD_SCRIPT_CATEGORY "

        # Check COMMANDS array exists
        if ! grep -q "^COMMANDS=(" "$script" 2>/dev/null; then
            missing+="COMMANDS "
        fi

        if [[ -n "$missing" ]]; then
            echo "  ✗ $name - missing: $missing"
            ((failed++))
        else
            echo "  ✓ $name"
        fi
    done

    return $failed
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    local filter="${1:-}"

    run_test "Install scripts have required metadata" test_install_scripts_metadata "$filter"
    run_test "Config scripts have required metadata" test_config_scripts_metadata "$filter"
    run_test "Service scripts have required metadata" test_service_scripts_metadata "$filter"
    run_test "Cmd scripts have required metadata" test_cmd_scripts_metadata "$filter"
}

main "$@"
