# Test System Maintenance

How the test framework works internally, for maintainers who need to modify or extend it.

**For running tests and adding tests for scripts, see [testing.md](testing.md).**

---

## Architecture Overview

```
.devcontainer/additions/tests/
├── run-all-tests.sh          # Orchestrator - runs test suites
├── lib/
│   └── test-framework.sh     # Framework - assertions, utilities, reporting
├── static/                   # Level 1 tests (no execution)
│   └── test-*.sh
├── unit/                     # Level 2 tests (safe execution)
│   └── test-*.sh
└── install/                  # Level 3 tests (full cycle)
    └── test-*.sh
```

---

## Key Components

### 1. run-all-tests.sh (Orchestrator)

Entry point that runs test suites by level.

**Responsibilities:**
- Parse command-line arguments (level, filter)
- Source test-framework.sh
- Call `set_test_level()` before each suite
- Source (not execute) test files to share variables
- Call `print_summary()` at end

**How it runs tests:**
```bash
# Sources test files (doesn't execute as subprocess)
for test_script in "$SCRIPT_DIR"/static/test-*.sh; do
    source "$test_script" "$filter"
done
```

**Why source instead of bash?**
- Shares test counters (TESTS_RUN, TESTS_PASSED, etc.)
- Allows cumulative summary across all test files
- Test files can use framework functions directly

### 2. test-framework.sh (Framework)

Provides all test utilities. Sourced by orchestrator and available to all tests.

**Global Variables:**
```bash
TESTS_RUN=0           # Total tests executed
TESTS_PASSED=0        # Passed count
TESTS_FAILED=0        # Failed count
TESTS_SKIPPED=0       # Skipped count
FAILED_TESTS=()       # Array of failed test names
SKIPPED_TESTS=()      # Array of skipped test names
TEST_LEVEL_PREFIX=""  # Current level ("1", "2", "3")
TEST_LEVEL_COUNT=0    # Test count within level
```

**Path Variables:**
```bash
FRAMEWORK_DIR   # .devcontainer/additions/tests/lib
TESTS_DIR       # .devcontainer/additions/tests
ADDITIONS_DIR   # .devcontainer/additions
LOG_DIR         # /tmp/devcontainer-tests
```

---

## Framework Functions

### Assertion Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `assert_equals "expected" "actual"` | Compare two values | 0=match, 1=mismatch |
| `assert_not_empty "$value"` | Check value not empty | 0=not empty, 1=empty |
| `assert_success "command"` | Check command succeeds | 0=success, 1=failure |
| `assert_failure "command"` | Check command fails | 0=failed, 1=succeeded |
| `assert_file_exists "/path"` | Check file exists | 0=exists, 1=missing |
| `assert_contains "$string" "$substring"` | Check substring exists | 0=found, 1=not found |
| `assert_grep "pattern" "file"` | Check pattern in file | 0=found, 1=not found |

### Test Execution Functions

| Function | Purpose |
|----------|---------|
| `run_test "Name" function [filter]` | Execute a test function and track result |
| `skip_test "reason"` | Skip current test (exits with code 77) |
| `set_test_level "1"` | Set level prefix for test numbering |

### Utility Functions

| Function | Purpose |
|----------|---------|
| `get_scripts "pattern" [filter]` | Get scripts matching pattern, excluding templates |
| `source_libs "lib1.sh" "lib2.sh"` | Source production libraries from additions/lib/ |
| `print_header "Title"` | Print section header |
| `print_summary` | Print final test summary |

---

## Test File Pattern

Every test file follows this structure:

```bash
#!/bin/bash
# file: .devcontainer/additions/tests/static/test-example.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-framework.sh"

#------------------------------------------------------------------------------
# TEST FUNCTIONS
#------------------------------------------------------------------------------

test_something() {
    local filter="${1:-}"
    local failed=0

    for script in $(get_scripts "install-*.sh" "$filter"); do
        local name=$(basename "$script")

        if some_check "$script"; then
            echo "  ✓ $name"
        else
            echo "  ✗ $name - reason"
            ((failed++))
        fi
    done

    return $failed
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    local filter="${1:-}"

    run_test "Something works" test_something "$filter"
}

main "$@"
```

**Key patterns:**
- Test function returns count of failures (0 = all passed)
- Use `✓` for pass, `✗` for fail in output
- Accept filter parameter to test specific scripts
- Call `run_test` which handles counting and reporting

---

## How run_test Works

```bash
run_test "Test Name" test_function "$filter"
```

1. Increments `TESTS_RUN` and `TEST_LEVEL_COUNT`
2. Builds test ID (e.g., "1.3" for static test #3)
3. Executes test function, captures output to log file
4. Checks exit code:
   - 0 → PASS, increment `TESTS_PASSED`
   - 77 → SKIP, increment `TESTS_SKIPPED`, add to `SKIPPED_TESTS`
   - other → FAIL, increment `TESTS_FAILED`, add to `FAILED_TESTS`
5. Prints result with pass/fail/skip indicator

---

## Adding a New Test Level

To add a new test level (e.g., "integration"):

1. Create folder: `tests/integration/`

2. Add function in `run-all-tests.sh`:
   ```bash
   run_integration_tests() {
       local filter="${1:-}"
       print_header "Integration Tests (Level 4)"
       set_test_level "4"

       for test_script in "$SCRIPT_DIR"/integration/test-*.sh; do
           [[ ! -f "$test_script" ]] && continue
           source "$test_script" "$filter"
       done
   }
   ```

3. Add case in main:
   ```bash
   integration)
       run_integration_tests "$filter"
       ;;
   ```

4. Create test files in `tests/integration/test-*.sh`

---

## Adding New Assertions

To add a new assertion to `test-framework.sh`:

```bash
# Assert a directory exists
# Usage: assert_dir_exists "/path/to/dir" "description"
assert_dir_exists() {
    local dir="$1"
    local description="${2:-Directory should exist}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "  Directory not found: $dir"
        return 1
    fi
}
```

**Pattern:**
- Return 0 for success, 1 for failure
- Echo error details on failure (indented with 2 spaces)
- Accept optional description parameter

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Test passed |
| 1 | Test failed |
| 77 | Test skipped (special code) |

The skip code (77) is a convention borrowed from Automake. Use `skip_test "reason"` to skip.

---

## Log Files

Test output is captured to `/tmp/devcontainer-tests/`:
- `test-1.log`, `test-2.log`, etc.
- Created fresh each run
- Used to show failure details (grep for `✗`)

---

## Modifying the Framework

When modifying `test-framework.sh`:

1. **Preserve backwards compatibility** - Existing tests should still work
2. **Don't change exit code meanings** - 0=pass, 77=skip, other=fail
3. **Keep global variables** - Tests depend on shared counters
4. **Test your changes** - Run full test suite after modifications

```bash
# Test the framework changes
.devcontainer/additions/tests/run-all-tests.sh
```

---

## Related Documentation

- [testing.md](testing.md) - How to run tests and add tests for scripts
- [CI-CD.md](CI-CD.md) - How tests run in CI
- [creating-install-scripts.md](creating-install-scripts.md) - Script requirements that tests validate
