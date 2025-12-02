# DevContainer Toolbox - Test Suite

This directory contains automated tests to validate the core systems that addition scripts depend on.

## Purpose

These tests verify that:
- Component scanning and metadata extraction work correctly
- Prerequisite checking functions as expected
- Auto-enable system operates properly
- Configuration restoration (--verify) functions correctly

**When to run these tests:**
1. Before creating new addition scripts (verify system works)
2. After modifying core libraries in `lib/`
3. After updating templates
4. Before submitting contributions

## Quick Start

### Run All Unit Tests

```bash
bash /workspace/.devcontainer/additions/addition-templates/tests/run-unit-tests.sh
```

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DevContainer Toolbox - Unit Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Test 1: Component Scanner - Install Scripts
✅ Test 2: Component Scanner - Config Scripts
✅ Test 3: Prerequisite Checking - Config Present
✅ Test 4: Prerequisite Checking - Config Missing
✅ Test 5: --verify Handler Detection
✅ Test 6: --verify Functionality
✅ Test 7: Tool Auto-Enable Library
✅ Test 8: Metadata Extraction Accuracy
✅ Test 9: CHECK_INSTALLED_COMMAND Logic
✅ Test 10: Show Missing Prerequisites

Total Tests:  10
Passed:       10
Failed:       0

✅ ALL TESTS PASSED
```

## Test Categories

### Category 1: Unit Tests (No Rebuild Required)

These 10 tests run quickly and don't require container rebuild:

1. **Component Scanner - Install Scripts**: Verifies install script discovery
2. **Component Scanner - Config Scripts**: Verifies config script discovery
3. **Prerequisite Checking - Config Present**: Tests prerequisite validation when config exists
4. **Prerequisite Checking - Config Missing**: Tests prerequisite validation when config missing
5. **--verify Handler Detection**: Verifies detection of --verify support
6. **--verify Functionality**: Tests non-interactive config restoration
7. **Tool Auto-Enable Library**: Validates auto-enable system and idempotency
8. **Metadata Extraction Accuracy**: Confirms correct metadata parsing
9. **CHECK_INSTALLED_COMMAND Logic**: Tests installation detection commands
10. **Show Missing Prerequisites**: Validates error message formatting

### Category 2: Integration Tests (Rebuild Required)

See [test-plan.md](./test-plan.md) for 10 integration tests that require container rebuild.

## Test Output

Test logs are saved to `/tmp/devcontainer-tests/`:
```bash
ls -la /tmp/devcontainer-tests/
# test-1.log, test-2.log, test-3.log, etc.
```

If a test fails, the last 10 lines are displayed automatically, or view the full log:
```bash
cat /tmp/devcontainer-tests/test-N.log
```

## Interpreting Results

### All Tests Pass
✅ **System is healthy** - Safe to create new addition scripts

### Some Tests Fail
❌ **System has issues** - Investigate failed tests before creating new scripts

**Common failure reasons:**
- Missing library files in `lib/`
- Metadata format changes
- Prerequisites not properly configured
- File permission issues

## Adding New Tests

When adding functionality to the core system, add corresponding tests:

1. **Add test function** to `run-unit-tests.sh`:
   ```bash
   test_X_Y() {
       # Test implementation
       if [ condition ]; then
           echo "Success message"
           return 0
       else
           echo "Failure message"
           return 1
       fi
   }
   ```

2. **Call test in main section**:
   ```bash
   run_test "Test Description" test_X_Y
   ```

3. **Document in test-plan.md**: Add description, procedure, expected output

## Test Framework

The test runner (`run-unit-tests.sh`) provides:

- **Colored output**: Green (pass), red (fail), yellow (running)
- **Individual logs**: Each test output saved separately
- **Summary reporting**: Total, passed, failed counts
- **Proper exit codes**: 0 (all pass), 1 (some fail)
- **Error isolation**: Failed test logs automatically displayed

## Files

- **README-tests.md** (this file) - Test suite documentation
- **run-unit-tests.sh** - Automated test runner (Category 1 tests)
- **test-plan.md** - Complete test plan (Categories 1 & 2)

## See Also

- [Addition Templates Guide](../README-additions-template.md) - How to create new scripts
- [Addition Scripts README](../../README-additions.md) - How to use existing scripts
- [Component Scanner Library](../../lib/component-scanner.sh) - Metadata extraction
- [Prerequisite Check Library](../../lib/prerequisite-check.sh) - Prerequisite validation
- [Tool Auto-Enable Library](../../lib/tool-auto-enable.sh) - Auto-enable system

## Contributing

When contributing changes to core libraries:

1. Run existing tests to ensure no regressions
2. Add new tests for new functionality
3. Update test-plan.md with test descriptions
4. Ensure all tests pass before submitting PR

---

**Quick Test Command:**
```bash
bash /workspace/.devcontainer/additions/addition-templates/tests/run-unit-tests.sh
```
