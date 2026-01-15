#!/bin/bash
# file: .devcontainer/manage/dev-test.sh
#
# Run devcontainer-toolbox tests
# Wrapper for run-all-tests.sh test orchestrator
#
# Usage:
#   dev-test                      # Run all tests
#   dev-test static               # Run static tests only
#   dev-test unit                 # Run unit tests only
#   dev-test install              # Run install cycle tests only
#   dev-test static script.sh     # Run static tests for specific script
#   dev-test --help               # Show this help

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-test"
SCRIPT_NAME="Run Tests"
SCRIPT_DESCRIPTION="Run static, unit, and install tests"
SCRIPT_CATEGORY="CONTRIBUTOR_TOOLS"
SCRIPT_CHECK_COMMAND="true"

#------------------------------------------------------------------------------
# Script Setup
#------------------------------------------------------------------------------
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
show_help() {
    cat << 'EOF'
dev-test - Run devcontainer-toolbox tests

Usage:
  dev-test                      # Run all tests
  dev-test static               # Run static tests only
  dev-test unit                 # Run unit tests only
  dev-test install              # Run install cycle tests only
  dev-test static script.sh     # Run static tests for specific script
  dev-test --help               # Show this help

Test Levels:
  static   - Level 1: Syntax, metadata, categories, flags
  unit     - Level 2: --help, --verify, library functions
  install  - Level 3: Full install/uninstall cycles

Examples:
  # Run all tests
  dev-test

  # Run only static analysis
  dev-test static

  # Run static tests for a specific script
  dev-test static install-python.sh

EOF
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

# Handle --help locally
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Pass all arguments to run-all-tests.sh
exec "$SCRIPT_DIR/../additions/tests/run-all-tests.sh" "$@"
