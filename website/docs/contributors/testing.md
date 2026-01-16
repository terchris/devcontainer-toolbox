---
title: Testing
sidebar_position: 3
---

# Testing Guide

Automated tests for validating install scripts, config scripts, and libraries.

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
│   └── test-flags.sh         # --help, --uninstall handlers
├── unit/                     # Level 2: Safe execution
│   ├── test-help.sh          # --help works
│   ├── test-verify.sh        # --verify works (config scripts)
│   └── test-libraries.sh     # Library function tests
└── install/                  # Level 3: Full cycle
    └── test-install-cycle.sh # Install → verify → uninstall
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

## CI Integration

Tests run automatically in CI on every PR:

- **Static tests**: Always run (fast, no side effects)
- **Unit tests**: Always run (safe execution)
- **Install tests**: Run locally only (require devcontainer)

See [CI/CD](ci-cd) for details on GitHub Actions.

---

## Common Test Failures

### Static Tests Failed

- Check script metadata fields
- Verify valid category
- Run `bash -n script.sh` to check syntax

### Unit Tests Failed

- Verify `--help` flag works
- Check `--verify` implementation (config scripts)

### Install Tests Failed

- Check install/uninstall logic
- Verify SCRIPT_CHECK_COMMAND works
