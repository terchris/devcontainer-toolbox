# Integration Tests

Integration tests require container rebuilds and are run manually.

## Test Scenarios

### 1. Fresh Container Build
- Build container with no prior configs
- Verify postCreateCommand runs
- Verify no errors in logs

### 2. Container Rebuild with Configs
- Configure identity: `config-devcontainer-identity.sh`
- Install a tool: `install-dev-python.sh`
- Rebuild container
- Verify config restored via --verify
- Verify tool auto-installed from enabled-tools.conf

### 3. Prerequisite Blocking
- Try to install tool with missing prerequisite
- Verify clear error message shown
- Configure prerequisite
- Verify install succeeds

## Running Integration Tests

These tests cannot be automated easily as they require:
1. Container rebuild (destroys test environment)
2. Manual observation of behavior
3. State verification between rebuilds

See `terchris/refactoring/ci-test-refactor-plan.md` for full test procedures.
