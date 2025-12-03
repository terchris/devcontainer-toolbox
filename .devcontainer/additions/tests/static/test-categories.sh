#!/bin/bash
# file: .devcontainer/additions/tests/static/test-categories.sh
#
# DESCRIPTION: Validates that all scripts use valid categories from lib/categories.sh
# PURPOSE: Ensures category consistency across all scripts
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-framework.sh"

# Source production library for category validation
source_libs "categories.sh"

#------------------------------------------------------------------------------
# TEST FUNCTIONS
#------------------------------------------------------------------------------

test_install_scripts_categories() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "install-*.sh" "$filter"); do
        local name=$(basename "$script")
        local script_cat=$(grep -m 1 "^SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)

        if [[ -n "$script_cat" ]]; then
            if ! is_valid_category "$script_cat"; then
                echo "  ✗ $name - invalid category '$script_cat'"
                echo "    Valid: $(get_all_category_ids | tr '\n' ' ')"
                ((failed++))
            else
                echo "  ✓ $name"
            fi
        else
            echo "  ✓ $name (no category set)"
        fi
    done

    return $failed
}

test_config_scripts_categories() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "config-*.sh" "$filter"); do
        local name=$(basename "$script")
        local script_cat=$(grep -m 1 "^SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)

        if [[ -n "$script_cat" ]]; then
            if ! is_valid_category "$script_cat"; then
                echo "  ✗ $name - invalid category '$script_cat'"
                echo "    Valid: $(get_all_category_ids | tr '\n' ' ')"
                ((failed++))
            else
                echo "  ✓ $name"
            fi
        else
            echo "  ✓ $name (no category set)"
        fi
    done

    return $failed
}

test_service_scripts_categories() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "service-*.sh" "$filter"); do
        local name=$(basename "$script")
        local script_cat=$(grep -m 1 "^SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)

        if [[ -n "$script_cat" ]]; then
            if ! is_valid_category "$script_cat"; then
                echo "  ✗ $name - invalid category '$script_cat'"
                echo "    Valid: $(get_all_category_ids | tr '\n' ' ')"
                ((failed++))
            else
                echo "  ✓ $name"
            fi
        else
            echo "  ✓ $name (no category set)"
        fi
    done

    return $failed
}

test_cmd_scripts_categories() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "cmd-*.sh" "$filter"); do
        local name=$(basename "$script")
        local script_cat=$(grep -m 1 "^SCRIPT_CATEGORY=" "$script" 2>/dev/null | cut -d'"' -f2)

        if [[ -n "$script_cat" ]]; then
            if ! is_valid_category "$script_cat"; then
                echo "  ✗ $name - invalid category '$script_cat'"
                echo "    Valid: $(get_all_category_ids | tr '\n' ' ')"
                ((failed++))
            else
                echo "  ✓ $name"
            fi
        else
            echo "  ✓ $name (no category set)"
        fi
    done

    return $failed
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    local filter="${1:-}"

    run_test "Install scripts use valid categories" test_install_scripts_categories "$filter"
    run_test "Config scripts use valid categories" test_config_scripts_categories "$filter"
    run_test "Service scripts use valid categories" test_service_scripts_categories "$filter"
    run_test "Cmd scripts use valid categories" test_cmd_scripts_categories "$filter"
}

main "$@"
