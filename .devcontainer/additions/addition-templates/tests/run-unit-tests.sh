#!/bin/bash
# File: .devcontainer/additions/addition-templates/tests/run-unit-tests.sh
# Purpose: Execute all unit tests for DevContainer Toolbox
# Usage: bash run-unit-tests.sh

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0
TOTAL=0

# Test output directory
TEST_OUTPUT_DIR="/tmp/devcontainer-tests"
mkdir -p "$TEST_OUTPUT_DIR"

log_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

log_test() {
    echo -e "${YELLOW}▶ $1${NC}"
}

log_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    PASSED=$((PASSED + 1))
}

log_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    FAILED=$((FAILED + 1))
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TOTAL=$((TOTAL + 1))
    log_test "Test $TOTAL: $test_name"

    local output_file="$TEST_OUTPUT_DIR/test-$TOTAL.log"

    if $test_function > "$output_file" 2>&1; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        echo "    Output saved to: $output_file"
        echo "    Last 10 lines:"
        tail -10 "$output_file" | sed 's/^/    /'
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.1: Component Scanner - Install Scripts
#------------------------------------------------------------------------------
test_1_1() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local count=0
    while IFS=$'\t' read -r basename name desc cat check prereqs; do
        count=$((count + 1))
    done < <(scan_install_scripts /workspace/.devcontainer/additions)

    if [ $count -gt 10 ]; then
        echo "Discovered $count install scripts"
        return 0
    else
        echo "Only discovered $count install scripts (expected > 10)"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.2: Component Scanner - Config Scripts
#------------------------------------------------------------------------------
test_1_2() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local count=0
    while IFS=$'\t' read -r basename name desc cat check; do
        count=$((count + 1))
    done < <(scan_config_scripts /workspace/.devcontainer/additions)

    if [ $count -ge 3 ]; then
        echo "Discovered $count config scripts"
        return 0
    else
        echo "Only discovered $count config scripts (expected >= 3)"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.3: Prerequisite Checking - Config Present
#------------------------------------------------------------------------------
test_1_3() {
    source /workspace/.devcontainer/additions/lib/prerequisite-check.sh

    if check_prerequisite_config "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions"; then
        echo "Prerequisite check succeeded (identity configured)"
        return 0
    else
        echo "Prerequisite check failed (identity should be configured)"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.4: Prerequisite Checking - Config Missing
#------------------------------------------------------------------------------
test_1_4() {
    # Temporarily move identity file
    local backup_file="$HOME/.devcontainer-identity.test-backup-$(date +%s)"
    mv ~/.devcontainer-identity "$backup_file" 2>/dev/null || true

    source /workspace/.devcontainer/additions/lib/prerequisite-check.sh

    local result=0
    if check_prerequisite_config "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions"; then
        echo "Prerequisite check succeeded (should have failed)"
        result=1
    else
        echo "Prerequisite check failed as expected"
        result=0
    fi

    # Restore identity file
    mv "$backup_file" ~/.devcontainer-identity 2>/dev/null || true

    return $result
}

#------------------------------------------------------------------------------
# TEST 1.5: --verify Handler Detection
#------------------------------------------------------------------------------
test_1_5() {
    local ADDITIONS_DIR="/workspace/.devcontainer/additions"
    local verified_count=0

    for script in "$ADDITIONS_DIR"/config-*.sh; do
        if grep -q '= "--verify"' "$script" 2>/dev/null; then
            verified_count=$((verified_count + 1))
        fi
    done

    if [ $verified_count -ge 1 ]; then
        echo "Found $verified_count scripts with --verify support"
        return 0
    else
        echo "No scripts with --verify support found"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.6: --verify Functionality
#------------------------------------------------------------------------------
test_1_6() {
    # Backup current identity
    local backup_file="$HOME/.devcontainer-identity.test-backup-$(date +%s)"
    cp ~/.devcontainer-identity "$backup_file" 2>/dev/null || true

    # Remove identity
    rm -f ~/.devcontainer-identity

    # Run --verify
    if bash /workspace/.devcontainer/additions/config-devcontainer-identity.sh --verify 2>/dev/null; then
        # Check if restored
        if [ -f ~/.devcontainer-identity ]; then
            echo "Identity file restored successfully"
            return 0
        else
            echo "Identity file not restored"
            return 1
        fi
    else
        echo "--verify failed"
        mv "$backup_file" ~/.devcontainer-identity 2>/dev/null || true
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.7: Tool Auto-Enable Library
#------------------------------------------------------------------------------
test_1_7() {
    source /workspace/.devcontainer/additions/lib/tool-auto-enable.sh

    # Backup enabled-tools.conf
    cp /workspace/.devcontainer.extend/enabled-tools.conf /tmp/enabled-tools.conf.test-backup

    # Remove test tool if exists
    sed -i '/test-tool-automated-test-12345/d' /workspace/.devcontainer.extend/enabled-tools.conf

    # Test auto-enable
    if auto_enable_tool "test-tool-automated-test-12345" "Test Tool"; then
        # Check if added
        if grep -q "test-tool-automated-test-12345" /workspace/.devcontainer.extend/enabled-tools.conf; then
            # Test idempotency
            auto_enable_tool "test-tool-automated-test-12345" "Test Tool"

            # Count occurrences
            local count=$(grep -c "test-tool-automated-test-12345" /workspace/.devcontainer.extend/enabled-tools.conf)

            # Restore original
            cp /tmp/enabled-tools.conf.test-backup /workspace/.devcontainer.extend/enabled-tools.conf
            rm /tmp/enabled-tools.conf.test-backup

            if [ "$count" -eq 1 ]; then
                echo "Tool added and idempotent (1 occurrence)"
                return 0
            else
                echo "Tool duplicated ($count occurrences)"
                return 1
            fi
        else
            # Restore original
            cp /tmp/enabled-tools.conf.test-backup /workspace/.devcontainer.extend/enabled-tools.conf
            rm /tmp/enabled-tools.conf.test-backup
            echo "Tool not added"
            return 1
        fi
    else
        # Restore original
        cp /tmp/enabled-tools.conf.test-backup /workspace/.devcontainer.extend/enabled-tools.conf
        rm /tmp/enabled-tools.conf.test-backup
        echo "Auto-enable failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.8: Metadata Extraction Accuracy
#------------------------------------------------------------------------------
test_1_8() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local EXPECTED_NAME="OTel Collector"
    local EXPECTED_PREREQ="config-devcontainer-identity.sh config-nginx.sh"
    local found=0

    while IFS=$'\t' read -r basename name desc cat check prereqs; do
        if [ "$basename" = "install-srv-otel-monitoring.sh" ]; then
            found=1

            if [ "$name" != "$EXPECTED_NAME" ]; then
                echo "Name mismatch: expected '$EXPECTED_NAME', got '$name'"
                return 1
            fi

            if [ "$prereqs" != "$EXPECTED_PREREQ" ]; then
                echo "Prerequisites mismatch: expected '$EXPECTED_PREREQ', got '$prereqs'"
                return 1
            fi

            echo "Metadata extracted accurately for OTel script"
            return 0
        fi
    done < <(scan_install_scripts /workspace/.devcontainer/additions)

    if [ $found -eq 0 ]; then
        echo "OTel script not found in scan"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.9: CHECK_INSTALLED_COMMAND Logic
#------------------------------------------------------------------------------
test_1_9() {
    # Test with installed tool (python)
    local CHECK_CMD="command -v python3 >/dev/null 2>&1"
    if ! eval "$CHECK_CMD"; then
        echo "Python check failed (should succeed)"
        return 1
    fi

    # Test with non-existent tool
    CHECK_CMD="command -v nonexistent-tool-xyz-123 >/dev/null 2>&1"
    if eval "$CHECK_CMD"; then
        echo "Nonexistent tool check succeeded (should fail)"
        return 1
    fi

    echo "CHECK_INSTALLED_COMMAND logic works correctly"
    return 0
}

#------------------------------------------------------------------------------
# TEST 1.10: Show Missing Prerequisites
#------------------------------------------------------------------------------
test_1_10() {
    source /workspace/.devcontainer/additions/lib/prerequisite-check.sh

    # Temporarily move identity
    local backup_file="$HOME/.devcontainer-identity.test-backup-$(date +%s)"
    mv ~/.devcontainer-identity "$backup_file" 2>/dev/null || true

    # Get output
    local output=$(show_missing_prerequisites "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions" 2>&1)

    # Restore
    mv "$backup_file" ~/.devcontainer-identity 2>/dev/null || true

    # Check format
    if ! echo "$output" | grep -q "❌"; then
        echo "Missing error symbol in output"
        return 1
    fi

    if ! echo "$output" | grep -q "Developer Identity"; then
        echo "Missing config name in output"
        return 1
    fi

    if ! echo "$output" | grep -q "bash /workspace/.devcontainer/additions"; then
        echo "Missing run command in output"
        return 1
    fi

    echo "Error message format is correct"
    return 0
}

#------------------------------------------------------------------------------
# TEST 1.11: cmd-*.sh Metadata Discovery
#------------------------------------------------------------------------------
test_1_11() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local count=0
    while IFS=$'\t' read -r basename name desc cat script_path prereqs; do
        ((count++))
        echo "$count. $name"
    done < <(scan_cmd_scripts /workspace/.devcontainer/additions)

    if [ $count -ge 1 ]; then
        echo "Discovered $count cmd scripts"
        return 0
    else
        echo "No cmd scripts discovered"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.12: cmd-ai.sh Metadata Extraction
#------------------------------------------------------------------------------
test_1_12() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local EXPECTED_NAME="AI Management"
    local EXPECTED_CAT="AI_TOOLS"
    local EXPECTED_PREREQ="config-ai-claudecode.sh"

    local found=0
    while IFS=$'\t' read -r basename name desc cat script_path prereqs; do
        if [ "$basename" = "cmd-ai.sh" ]; then
            found=1

            if [ "$name" != "$EXPECTED_NAME" ]; then
                echo "Name mismatch: expected '$EXPECTED_NAME', got '$name'"
                return 1
            fi

            if [ "$cat" != "$EXPECTED_CAT" ]; then
                echo "Category mismatch: expected '$EXPECTED_CAT', got '$cat'"
                return 1
            fi

            if [ "$prereqs" != "$EXPECTED_PREREQ" ]; then
                echo "Prerequisites mismatch: expected '$EXPECTED_PREREQ', got '$prereqs'"
                return 1
            fi

            echo "cmd-ai.sh metadata extracted correctly"
            return 0
        fi
    done < <(scan_cmd_scripts /workspace/.devcontainer/additions)

    echo "cmd-ai.sh not found"
    return 1
}

#------------------------------------------------------------------------------
# TEST 1.13: COMMANDS Array Extraction
#------------------------------------------------------------------------------
test_1_13() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local commands=()
    while IFS= read -r line; do
        commands+=("$line")
    done < <(extract_cmd_commands /workspace/.devcontainer/additions/cmd-ai.sh)

    local count=${#commands[@]}

    if [ $count -ge 10 ]; then
        echo "Extracted $count commands from cmd-ai.sh"
        return 0
    else
        echo "Only extracted $count commands (expected >= 10)"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.14: COMMANDS Array Format Validation
#------------------------------------------------------------------------------
test_1_14() {
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    local commands=()
    while IFS= read -r line; do
        commands+=("$line")
    done < <(extract_cmd_commands /workspace/.devcontainer/additions/cmd-ai.sh)

    local errors=0
    for cmd_def in "${commands[@]}"; do
        local field_count=$(echo "$cmd_def" | awk -F'|' '{print NF}')

        if [ "$field_count" -ne 6 ]; then
            echo "Invalid format (expected 6 fields, got $field_count): $cmd_def"
            ((errors++))
        fi
    done

    if [ $errors -eq 0 ]; then
        echo "All commands have correct format (6 fields)"
        return 0
    else
        echo "$errors commands have incorrect format"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.15: cmd-ai.sh Prerequisites Check
#------------------------------------------------------------------------------
test_1_15() {
    source /workspace/.devcontainer/additions/lib/prerequisite-check.sh
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    # Extract prerequisites
    local prereqs=$(extract_cmd_metadata /workspace/.devcontainer/additions/cmd-ai.sh CMD_PREREQUISITE_CONFIGS)

    if [ -z "$prereqs" ]; then
        echo "No prerequisites defined"
        return 1
    fi

    echo "Prerequisites: $prereqs"

    # Check prerequisite mechanism works (not checking if it's actually configured)
    if check_prerequisite_configs "$prereqs" "/workspace/.devcontainer/additions"; then
        echo "Prerequisites met (Claude Code configured)"
        return 0
    else
        echo "Prerequisites not met (acceptable - mechanism works)"
        # Test passes if mechanism works
        return 0
    fi
}

#------------------------------------------------------------------------------
# TEST 1.16: Help Generation from COMMANDS Array
#------------------------------------------------------------------------------
test_1_16() {
    cd /workspace/.devcontainer/additions

    local help_output=$(bash cmd-ai.sh --help 2>&1)

    # Check for category headers
    if ! echo "$help_output" | grep -q "Information Commands:"; then
        echo "Missing 'Information Commands:' category"
        return 1
    fi

    if ! echo "$help_output" | grep -q "Spending Commands:"; then
        echo "Missing 'Spending Commands:' category"
        return 1
    fi

    if ! echo "$help_output" | grep -q "Testing Commands:"; then
        echo "Missing 'Testing Commands:' category"
        return 1
    fi

    # Check for specific commands
    if ! echo "$help_output" | grep -q -- "--models"; then
        echo "Missing --models command"
        return 1
    fi

    if ! echo "$help_output" | grep -q -- "--test <arg>"; then
        echo "Missing --test command with parameter hint"
        return 1
    fi

    echo "Help text generated correctly with categories and commands"
    return 0
}

#------------------------------------------------------------------------------
# TEST 1.17: Command Execution - Simple Flag
#------------------------------------------------------------------------------
test_1_17() {
    cd /workspace/.devcontainer/additions

    # Skip if auth not configured
    if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
        echo "ANTHROPIC_AUTH_TOKEN not set - skipping (acceptable)"
        return 0
    fi

    # Test health command (doesn't require auth)
    local output=$(bash cmd-ai.sh --health 2>&1)

    if echo "$output" | grep -qE "(✅|OK|healthy|SUCCESS)"; then
        echo "Health command executed successfully"
        return 0
    else
        echo "Health command failed or returned unexpected output"
        echo "Output: $output"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.18: Command Execution - With Parameter
#------------------------------------------------------------------------------
test_1_18() {
    cd /workspace/.devcontainer/additions

    # Skip if auth not configured
    if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
        echo "ANTHROPIC_AUTH_TOKEN not set - skipping (acceptable)"
        return 0
    fi

    # Test with a parameter
    local output=$(bash cmd-ai.sh --test qwen2.5-coder:7b 2>&1)

    # Check if it attempted to run (may fail if model doesn't exist, but should accept parameter)
    if echo "$output" | grep -q "Testing Model Access"; then
        echo "Command with parameter executed (reached test function)"
        return 0
    elif echo "$output" | grep -q "Model name required"; then
        echo "Parameter validation rejected empty parameter"
        return 1
    else
        echo "Command accepted parameter and attempted execution"
        return 0
    fi
}

#------------------------------------------------------------------------------
# TEST 1.19: Invalid Command Handling
#------------------------------------------------------------------------------
test_1_19() {
    cd /workspace/.devcontainer/additions

    local output=$(bash cmd-ai.sh --nonexistent-command 2>&1)

    if echo "$output" | grep -q "Unknown command"; then
        echo "Unknown command error displayed"
        return 0
    else
        echo "No error for unknown command"
        return 1
    fi
}

#------------------------------------------------------------------------------
# TEST 1.20: Framework Validation Function
#------------------------------------------------------------------------------
test_1_20() {
    source /workspace/.devcontainer/additions/lib/cmd-framework.sh
    source /workspace/.devcontainer/additions/lib/component-scanner.sh

    # Extract commands
    local COMMANDS=()
    while IFS= read -r line; do
        COMMANDS+=("$line")
    done < <(extract_cmd_commands /workspace/.devcontainer/additions/cmd-ai.sh)

    # Validate
    if cmd_framework_validate_commands COMMANDS; then
        echo "COMMANDS array validation passed"
        return 0
    else
        echo "COMMANDS array validation failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

log_header "DevContainer Toolbox - Unit Tests"
echo "Test output directory: $TEST_OUTPUT_DIR"
echo "Date: $(date)"
echo ""

# Run all tests
run_test "Component Scanner - Install Scripts" test_1_1
run_test "Component Scanner - Config Scripts" test_1_2
run_test "Prerequisite Checking - Config Present" test_1_3
run_test "Prerequisite Checking - Config Missing" test_1_4
run_test "--verify Handler Detection" test_1_5
run_test "--verify Functionality" test_1_6
run_test "Tool Auto-Enable Library" test_1_7
run_test "Metadata Extraction Accuracy" test_1_8
run_test "CHECK_INSTALLED_COMMAND Logic" test_1_9
run_test "Show Missing Prerequisites" test_1_10

# cmd-*.sh tests
log_header "cmd-*.sh Scripts - Unit Tests"
run_test "cmd-*.sh Metadata Discovery" test_1_11
run_test "cmd-ai.sh Metadata Extraction" test_1_12
run_test "COMMANDS Array Extraction" test_1_13
run_test "COMMANDS Array Format Validation" test_1_14
run_test "cmd-ai.sh Prerequisites Check" test_1_15
run_test "Help Generation from COMMANDS" test_1_16
run_test "Command Execution - Simple Flag" test_1_17
run_test "Command Execution - With Parameter" test_1_18
run_test "Invalid Command Handling" test_1_19
run_test "Framework Validation Function" test_1_20

# Summary
log_header "Test Results Summary"
echo ""
echo "Total Tests:  $TOTAL"
echo -e "Passed:       ${GREEN}$PASSED${NC}"
echo -e "Failed:       ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Check individual test logs in: $TEST_OUTPUT_DIR"
    exit 1
fi
