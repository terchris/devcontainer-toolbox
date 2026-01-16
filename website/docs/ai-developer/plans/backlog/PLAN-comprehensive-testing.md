# Plan: Comprehensive Testing for Scripts and Menu

## Status: Backlog

**Goal**: Expand test coverage to include all install scripts, the dev-setup menu system, and library functions.

**Priority**: Medium

**Last Updated**: 2026-01-14

---

## Problem

Current tests cover:
- Static analysis (syntax, metadata, categories, flags)
- Unit tests (--help, --verify, library loading)
- Install cycle (install → verify → uninstall)

Gaps:
- No tests for dev-setup.sh menu rendering
- No tests for library function behavior (only loading)
- No tests for tool-auto-enable / service-auto-enable logic
- No tests for prerequisite-check blocking

---

## Phase 1: Expand Library Function Tests

Add tests to verify library functions work correctly, not just that they load.

### Tasks

- [ ] 1.1 Add tests for `tool-auto-enable.sh`:
  - `auto_enable_tool` adds to enabled-tools.conf
  - `auto_disable_tool` removes from enabled-tools.conf
  - `is_tool_auto_enabled` returns correct status

- [ ] 1.2 Add tests for `service-auto-enable.sh`:
  - `enable_service_autostart` adds to enabled-services.conf
  - `disable_service_autostart` removes from enabled-services.conf
  - `is_auto_enabled` returns correct status

- [ ] 1.3 Add tests for `prerequisite-check.sh`:
  - `check_prerequisite_configs` returns correct status

- [ ] 1.4 Add tests for `categories.sh`:
  - `get_category_display_name` returns correct names
  - `is_valid_category` validates correctly

### Validation

```bash
.devcontainer/additions/tests/run-all-tests.sh unit
```

User confirms all tests pass.

---

## Phase 2: Add Menu System Tests

Create new test file for dev-setup.sh menu validation.

### Tasks

- [ ] 2.1 Create `tests/unit/test-menu.sh`

- [ ] 2.2 Test script discovery:
  - Menu finds all install-*.sh scripts
  - Menu finds all config-*.sh scripts
  - Menu finds all service-*.sh scripts

- [ ] 2.3 Test category grouping:
  - Scripts are grouped in correct categories
  - No uncategorized scripts

- [ ] 2.4 Add test-menu.sh to run-all-tests.sh

### Validation

```bash
.devcontainer/additions/tests/run-all-tests.sh unit
```

User confirms menu tests pass.

---

## Phase 3: Validate All Install Scripts

Run all test levels and fix any failures.

### Tasks

- [ ] 3.1 Run static tests, fix any failures

- [ ] 3.2 Run unit tests, fix any failures

- [ ] 3.3 Review install cycle skip list - document why each is skipped

- [ ] 3.4 Run install cycle tests (in devcontainer), fix any failures

### Validation

```bash
.devcontainer/additions/tests/run-all-tests.sh static
.devcontainer/additions/tests/run-all-tests.sh unit
.devcontainer/additions/tests/run-all-tests.sh install  # in devcontainer
```

User confirms all tests pass.

---

## Phase 4: Verify CI Integration

Ensure CI runs the new tests.

### Tasks

- [ ] 4.1 Verify static tests run in CI

- [ ] 4.2 Verify unit tests run in CI (including new test-menu.sh)

- [ ] 4.3 Document that install cycle tests are local-only

### Validation

User confirms CI passes after push to GitHub.

---

## Acceptance Criteria

- [ ] Library function tests added and passing
- [ ] Menu system tests added and passing
- [ ] All static tests passing
- [ ] All unit tests passing
- [ ] Install cycle tests documented and passing locally
- [ ] CI runs static + unit tests on every PR

---

## Files to Create

- `.devcontainer/additions/tests/unit/test-menu.sh`

## Files to Modify

- `.devcontainer/additions/tests/unit/test-libraries.sh`
- `.devcontainer/additions/tests/run-all-tests.sh`
