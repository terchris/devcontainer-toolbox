# DevContainer Toolbox - Test Suite

Automated tests for validating install scripts, config scripts, and libraries.

## Quick Start

```bash
# Run all tests (static + unit)
./run-all-tests.sh

# Run specific test level
./run-all-tests.sh static    # Fast, no execution
./run-all-tests.sh unit      # Safe execution (--help, --verify)
./run-all-tests.sh install   # Full install/uninstall cycle (slow)

# Test a specific script
./run-all-tests.sh static install-dev-python.sh
./run-all-tests.sh install install-dev-python.sh
```

## Test Levels

| Level | Folder | What it tests | Speed | System changes |
|-------|--------|---------------|-------|----------------|
| 1 | static/ | Syntax, metadata, categories, flags | Fast | None |
| 2 | unit/ | --help, --verify, library functions | Fast | None |
| 3 | install/ | Full install/uninstall cycle | Slow | Temporary |

## Test Structure

```
tests/
├── run-all-tests.sh          # Test orchestrator
├── README.md                 # This file
├── lib/
│   └── test-framework.sh     # Shared test utilities
├── static/                   # Level 1: No execution
│   ├── test-syntax.sh        # bash -n on all scripts
│   ├── test-metadata.sh      # Required metadata fields
│   ├── test-categories.sh    # Valid categories
│   └── test-flags.sh         # --help, --uninstall, --verify handlers
├── unit/                     # Level 2: Safe execution
│   ├── test-help.sh          # --help works
│   ├── test-verify.sh        # --verify works (config scripts)
│   └── test-libraries.sh     # Library function tests
├── install/                  # Level 3: Full cycle
│   └── test-install-cycle.sh # Install → verify → uninstall → verify
└── integration/
    └── README.md             # Manual integration tests
```

## AI-Assisted Development

When creating new scripts, run tests to validate:

```bash
# 1. Create script following template
# 2. Run static tests
./run-all-tests.sh static install-dev-newlang.sh

# 3. Run unit tests
./run-all-tests.sh unit install-dev-newlang.sh

# 4. Run install cycle test
./run-all-tests.sh install install-dev-newlang.sh
```

## Test Output

- Exit code 0 = all tests passed
- Exit code 1 = some tests failed
- Logs saved to `/tmp/devcontainer-tests/`

## Adding New Tests

1. Create test file in appropriate folder (static/, unit/, install/)
2. Source the test framework:
   ```bash
   source "$SCRIPT_DIR/../lib/test-framework.sh"
   ```
3. Write test functions
4. Use `run_test "Name" test_function` to execute

Example:
```bash
test_my_feature() {
    # Test logic here
    return 0  # Pass
    return 1  # Fail
}

run_test "My feature works" test_my_feature
```

## Using Production Libraries

Tests use the production libraries from `../lib/`:

```bash
source_libs "component-scanner.sh" "categories.sh"

# Now use production functions
is_valid_category "LANGUAGE_DEV"
scan_install_scripts "$ADDITIONS_DIR"
```
