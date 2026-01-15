# Testing Guide

Automated tests for validating install scripts, config scripts, and libraries.

**For maintaining the test framework itself, see [testing-maintenance.md](testing-maintenance.md).**

---

## Quick Start

```bash
# Run all tests (static + unit + lint)
dev-test

# Run specific test level
dev-test static    # Fast, no execution
dev-test unit      # Safe execution (--help, --verify)
dev-test install   # Full install/uninstall cycle (slow)
dev-test lint      # ShellCheck linting

# Test a specific script
dev-test static install-dev-python.sh
dev-test install install-dev-python.sh
```

---

## Test Levels

| Level | Folder | What it tests | Speed | System changes |
|-------|--------|---------------|-------|----------------|
| 1 | static/ | Syntax, metadata, categories, flags | Fast | None |
| 2 | unit/ | --help, --verify, library functions | Fast | None |
| 3 | install/ | Full install/uninstall cycle | Slow | Temporary |

---

## Test Structure

```
.devcontainer/additions/tests/
├── run-all-tests.sh          # Test orchestrator
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
└── install/                  # Level 3: Full cycle
    └── test-install-cycle.sh # Install → verify → uninstall → verify
```

---

## Testing New Scripts

When creating new scripts, run tests to validate:

```bash
# 1. Create script following template
# 2. Run static tests
dev-test static install-dev-newlang.sh

# 3. Run unit tests
dev-test unit install-dev-newlang.sh

# 4. Run install cycle test
dev-test install install-dev-newlang.sh
```

---

## Test Output

- Exit code 0 = all tests passed
- Exit code 1 = some tests failed
- Logs saved to `/tmp/devcontainer-tests/`

---

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

---

## Using Production Libraries

Tests use the production libraries from `.devcontainer/additions/lib/`:

```bash
source_libs "component-scanner.sh" "categories.sh"

# Now use production functions
is_valid_category "LANGUAGE_DEV"
scan_install_scripts "$ADDITIONS_DIR"
```

---

## Integration Tests

Integration tests require container rebuilds and are run manually.

### Test Scenarios

#### 1. Fresh Container Build
- Build container with no prior configs
- Verify postCreateCommand runs
- Verify no errors in logs

#### 2. Container Rebuild with Configs
- Configure identity: `config-devcontainer-identity.sh`
- Install a tool: `install-dev-python.sh`
- Rebuild container
- Verify config restored via --verify
- Verify tool auto-installed from enabled-tools.conf

#### 3. Prerequisite Blocking
- Try to install tool with missing prerequisite
- Verify clear error message shown
- Configure prerequisite
- Verify install succeeds

### Running Integration Tests

These tests cannot be automated easily as they require:
1. Container rebuild (destroys test environment)
2. Manual observation of behavior
3. State verification between rebuilds

---

## CI Integration

Tests run automatically in CI on every PR:

- **Static tests**: Always run (fast, no side effects)
- **Unit tests**: Always run (safe execution)
- **Install tests**: Run locally only (require devcontainer)

See [CI-CD.md](CI-CD.md) for details on GitHub Actions and what CI checks.

---

## Related Documentation

- [testing-maintenance.md](testing-maintenance.md) - How to maintain the test framework
- [CI-CD.md](CI-CD.md) - GitHub Actions and CI pipeline
- [Creating Install Scripts](creating-install-scripts.md) - How to create scripts
- [Libraries Reference](libraries.md) - Library functions to test
- [Architecture](architecture.md) - System overview
