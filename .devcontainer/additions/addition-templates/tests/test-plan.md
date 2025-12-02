# DevContainer Toolbox - Test Plan

**Last Updated:** 2025-11-20
**Status:** Ready for Execution

---

## Test Categories

### Category 1: Unit Tests (No Rebuild Required)
Tests that can run in current container without rebuilding.

### Category 2: Integration Tests (Rebuild Required)
Tests that require container rebuild to verify full lifecycle.

---

## Category 1: Unit Tests (No Rebuild)

### Test 1.1: Component Scanner - Install Scripts

**Purpose:** Verify install scripts are discovered correctly

**Test:**
```bash
source /workspace/.devcontainer/additions/lib/component-scanner.sh

echo "=== Testing Install Script Discovery ==="
count=0
while IFS=$'\t' read -r basename name desc cat check prereqs; do
    ((count++))
    echo "$count. $name"
    echo "   File: $basename"
    echo "   Category: $cat"
    echo "   Prerequisites: ${prereqs:-none}"
done < <(scan_install_scripts /workspace/.devcontainer/additions)

echo ""
echo "Total discovered: $count"
```

**Expected:**
- ✅ All install-*.sh files discovered
- ✅ Metadata fields extracted correctly
- ✅ PREREQUISITE_CONFIGS field present where defined
- ✅ No duplicate entries

**Pass Criteria:** Count > 10, all fields present

---

### Test 1.2: Component Scanner - Config Scripts

**Purpose:** Verify config scripts are discovered correctly

**Test:**
```bash
source /workspace/.devcontainer/additions/lib/component-scanner.sh

echo "=== Testing Config Script Discovery ==="
count=0
while IFS=$'\t' read -r basename name desc cat check; do
    ((count++))
    echo "$count. $name"
    echo "   File: $basename"
    echo "   Category: $cat"
    echo "   Check: ${check:0:50}..."
done < <(scan_config_scripts /workspace/.devcontainer/additions)

echo ""
echo "Total discovered: $count"
```

**Expected:**
- ✅ All config-*.sh files discovered
- ✅ CHECK_CONFIGURED_COMMAND extracted
- ✅ Templates excluded (contains _template)

**Pass Criteria:** Count >= 3

---

### Test 1.3: Prerequisite Checking - With Config Present

**Purpose:** Verify prerequisite check returns success when config exists

**Test:**
```bash
source /workspace/.devcontainer/additions/lib/prerequisite-check.sh

echo "=== Testing Prerequisite Check (Config Present) ==="
if check_prerequisite_config "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions"; then
    echo "✅ PASS: Prerequisite check succeeded (identity configured)"
    exit 0
else
    echo "❌ FAIL: Prerequisite check failed (identity should be configured)"
    exit 1
fi
```

**Expected:**
- ✅ Returns exit code 0
- ✅ No error output

**Pass Criteria:** Exit code 0

---

### Test 1.4: Prerequisite Checking - With Config Missing

**Purpose:** Verify prerequisite check returns failure when config missing

**Setup:**
```bash
# Temporarily move identity file
mv ~/.devcontainer-identity ~/.devcontainer-identity.backup 2>/dev/null || true
```

**Test:**
```bash
source /workspace/.devcontainer/additions/lib/prerequisite-check.sh

echo "=== Testing Prerequisite Check (Config Missing) ==="
if check_prerequisite_config "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions"; then
    echo "❌ FAIL: Prerequisite check succeeded (should have failed)"
    exit 1
else
    echo "✅ PASS: Prerequisite check failed as expected"
    exit 0
fi
```

**Cleanup:**
```bash
# Restore identity file
mv ~/.devcontainer-identity.backup ~/.devcontainer-identity 2>/dev/null || true
```

**Expected:**
- ✅ Returns exit code 1
- ✅ No error output

**Pass Criteria:** Exit code 1

---

### Test 1.5: Config --verify Handler Detection

**Purpose:** Verify scripts with --verify support are detected correctly

**Test:**
```bash
echo "=== Testing --verify Handler Detection ==="

ADDITIONS_DIR="/workspace/.devcontainer/additions"
verified_count=0
no_verify_count=0

for script in "$ADDITIONS_DIR"/config-*.sh; do
    basename=$(basename "$script")

    # Check if has --verify handler
    if grep -q '= "--verify"' "$script" 2>/dev/null; then
        echo "✅ $basename - has --verify support"
        ((verified_count++))
    else
        echo "⏭️  $basename - no --verify support"
        ((no_verify_count++))
    fi
done

echo ""
echo "With --verify: $verified_count"
echo "Without --verify: $no_verify_count"
```

**Expected:**
- ✅ config-devcontainer-identity.sh has --verify
- ⏭️  config-git.sh may not have --verify (expected)
- ⏭️  config-supervisor.sh should NOT have --verify (it's a generator)

**Pass Criteria:** At least 1 script with --verify

---

### Test 1.6: Config --verify Functionality

**Purpose:** Verify --verify actually restores config

**Test:**
```bash
echo "=== Testing --verify Restoration ==="

# Backup current identity
cp ~/.devcontainer-identity ~/.devcontainer-identity.test-backup 2>/dev/null || true

# Remove identity
rm -f ~/.devcontainer-identity

# Run --verify
if bash /workspace/.devcontainer/additions/config-devcontainer-identity.sh --verify 2>/dev/null; then
    echo "✅ --verify succeeded"

    # Check if restored
    if [ -f ~/.devcontainer-identity ]; then
        echo "✅ Identity file restored"
        cat ~/.devcontainer-identity
        exit 0
    else
        echo "❌ FAIL: Identity file not restored"
        exit 1
    fi
else
    echo "❌ FAIL: --verify failed"
    exit 1
fi
```

**Cleanup:**
```bash
# No cleanup needed - file restored
```

**Expected:**
- ✅ Exit code 0
- ✅ ~/.devcontainer-identity exists
- ✅ Points to .devcontainer.secrets

**Pass Criteria:** File restored, exit code 0

---

### Test 1.7: Tool Auto-Enable Library

**Purpose:** Verify auto-enable library works correctly

**Test:**
```bash
source /workspace/.devcontainer/additions/lib/tool-auto-enable.sh

echo "=== Testing Tool Auto-Enable ==="

# Backup enabled-tools.conf
cp /workspace/.devcontainer.extend/enabled-tools.conf /tmp/enabled-tools.conf.backup

# Remove test tool if exists
sed -i '/test-tool-12345/d' /workspace/.devcontainer.extend/enabled-tools.conf

# Test auto-enable
if auto_enable_tool "test-tool-12345" "Test Tool"; then
    echo "✅ Auto-enable succeeded"

    # Check if added
    if grep -q "test-tool-12345" /workspace/.devcontainer.extend/enabled-tools.conf; then
        echo "✅ Tool added to enabled-tools.conf"

        # Test idempotency (run again)
        if auto_enable_tool "test-tool-12345" "Test Tool"; then
            # Count occurrences
            count=$(grep -c "test-tool-12345" /workspace/.devcontainer.extend/enabled-tools.conf)
            if [ "$count" -eq 1 ]; then
                echo "✅ Idempotent (not duplicated)"
                exit 0
            else
                echo "❌ FAIL: Tool duplicated ($count occurrences)"
                exit 1
            fi
        fi
    else
        echo "❌ FAIL: Tool not added"
        exit 1
    fi
else
    echo "❌ FAIL: Auto-enable failed"
    exit 1
fi
```

**Cleanup:**
```bash
# Restore original
cp /tmp/enabled-tools.conf.backup /workspace/.devcontainer.extend/enabled-tools.conf
rm /tmp/enabled-tools.conf.backup
```

**Expected:**
- ✅ Tool added on first call
- ✅ Not duplicated on second call

**Pass Criteria:** One occurrence, idempotent

---

### Test 1.8: Metadata Extraction Accuracy

**Purpose:** Verify metadata is extracted exactly as defined

**Test:**
```bash
echo "=== Testing Metadata Extraction Accuracy ==="

# Test OTel script
SCRIPT="/workspace/.devcontainer/additions/install-srv-otel-monitoring.sh"

source /workspace/.devcontainer/additions/lib/component-scanner.sh

# Extract manually
EXPECTED_NAME="OTel Collector"
EXPECTED_PREREQ="config-devcontainer-identity.sh"

# Extract via scanner
while IFS=$'\t' read -r basename name desc cat check prereqs; do
    if [ "$basename" = "install-srv-otel-monitoring.sh" ]; then
        echo "Found: $name"
        echo "Prerequisites: $prereqs"

        if [ "$name" = "$EXPECTED_NAME" ]; then
            echo "✅ Name matches"
        else
            echo "❌ Name mismatch: expected '$EXPECTED_NAME', got '$name'"
            exit 1
        fi

        if [ "$prereqs" = "$EXPECTED_PREREQ" ]; then
            echo "✅ Prerequisites match"
            exit 0
        else
            echo "❌ Prerequisites mismatch: expected '$EXPECTED_PREREQ', got '$prereqs'"
            exit 1
        fi
    fi
done < <(scan_install_scripts /workspace/.devcontainer/additions)

echo "❌ FAIL: Script not found in scan"
exit 1
```

**Expected:**
- ✅ SCRIPT_NAME = "OTel Collector"
- ✅ PREREQUISITE_CONFIGS = "config-devcontainer-identity.sh"

**Pass Criteria:** Exact match

---

### Test 1.9: CHECK_INSTALLED_COMMAND Logic

**Purpose:** Verify CHECK_INSTALLED_COMMAND returns correct status

**Test:**
```bash
echo "=== Testing CHECK_INSTALLED_COMMAND ==="

# Test with installed tool (python)
CHECK_CMD="command -v python3 >/dev/null 2>&1"
if eval "$CHECK_CMD"; then
    echo "✅ Python check: installed (correct)"
else
    echo "❌ FAIL: Python check: not installed (incorrect)"
    exit 1
fi

# Test with non-existent tool
CHECK_CMD="command -v nonexistent-tool-xyz-123 >/dev/null 2>&1"
if eval "$CHECK_CMD"; then
    echo "❌ FAIL: Nonexistent tool check: installed (incorrect)"
    exit 1
else
    echo "✅ Nonexistent tool check: not installed (correct)"
fi

echo "✅ PASS: CHECK_INSTALLED_COMMAND logic works"
exit 0
```

**Expected:**
- ✅ Returns true for installed tools
- ✅ Returns false for non-existent tools

**Pass Criteria:** Both checks correct

---

### Test 1.10: Show Missing Prerequisites

**Purpose:** Verify error messages are helpful

**Test:**
```bash
source /workspace/.devcontainer/additions/lib/prerequisite-check.sh

echo "=== Testing Missing Prerequisites Display ==="

# Temporarily move identity
mv ~/.devcontainer-identity ~/.devcontainer-identity.test-backup 2>/dev/null || true

# Test show_missing_prerequisites
echo "Expected output:"
show_missing_prerequisites "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions"

# Check format
output=$(show_missing_prerequisites "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions" 2>&1)

if echo "$output" | grep -q "❌"; then
    echo "✅ Contains error symbol"
else
    echo "❌ FAIL: Missing error symbol"
    mv ~/.devcontainer-identity.test-backup ~/.devcontainer-identity 2>/dev/null || true
    exit 1
fi

if echo "$output" | grep -q "Developer Identity"; then
    echo "✅ Contains config name"
else
    echo "❌ FAIL: Missing config name"
    mv ~/.devcontainer-identity.test-backup ~/.devcontainer-identity 2>/dev/null || true
    exit 1
fi

if echo "$output" | grep -q "bash /workspace/.devcontainer/additions"; then
    echo "✅ Contains run command"
else
    echo "❌ FAIL: Missing run command"
    mv ~/.devcontainer-identity.test-backup ~/.devcontainer-identity 2>/dev/null || true
    exit 1
fi

# Restore
mv ~/.devcontainer-identity.test-backup ~/.devcontainer-identity 2>/dev/null || true

echo "✅ PASS: Error messages are helpful"
exit 0
```

**Expected:**
- ✅ Shows ❌ symbol
- ✅ Shows config name
- ✅ Shows how to fix

**Pass Criteria:** All format checks pass

---

## Category 2: Integration Tests (Rebuild Required)

### Test 2.1: Layer 1 - Silent Config Restoration

**Purpose:** Verify restore_all_configurations() works during container creation

**Setup:**
1. Ensure config exists in .devcontainer.secrets: `/workspace/.devcontainer.secrets/env-vars/devcontainer-identity`
2. Note current container state

**Test Procedure:**
1. Rebuild container (Ctrl+Shift+P → "Rebuild Container")
2. Watch project-installs.sh output during build
3. Look for restoration section

**Expected Output:**
```
🔐 Restoring configurations from .devcontainer.secrets...
📋 Scanning for configuration scripts...
   ✅ Developer Identity restored

📊 Configuration Restoration Summary:
   ✅ Restored: 1
```

**Verification:**
```bash
# After container rebuild completes
ls -la ~/.devcontainer-identity
# Should be symlink to /workspace/.devcontainer.secrets/env-vars/devcontainer-identity

readlink ~/.devcontainer-identity
# Should show: /workspace/.devcontainer.secrets/env-vars/devcontainer-identity
```

**Pass Criteria:**
- ✅ Config restored silently
- ✅ No warnings for missing configs
- ✅ Symlink created correctly

---

### Test 2.2: Layer 1 - Silent for Missing Configs

**Purpose:** Verify no warnings for configs not in .devcontainer.secrets

**Setup:**
1. Remove a non-critical config from .devcontainer.secrets (e.g., kubectl config)
2. Note current state

**Test Procedure:**
1. Rebuild container
2. Watch restoration output

**Expected Output:**
```
🔐 Restoring configurations from .devcontainer.secrets...
📋 Scanning for configuration scripts...
   ✅ Developer Identity restored
   (no warning for kubectl)

📊 Configuration Restoration Summary:
   ✅ Restored: 1
```

**Verification:**
```bash
# Should NOT see:
# ⚠️  kubectl Configuration: not found in .devcontainer.secrets
```

**Pass Criteria:**
- ✅ Only shows successful restorations
- ✅ No warnings for missing configs

---

### Test 2.3: Layer 2 - Prerequisite Blocking

**Purpose:** Verify tool installation blocked when prerequisite missing

**Setup:**
1. Enable OTel in enabled-tools.conf
2. Remove identity from .devcontainer.secrets: `rm -rf /workspace/.devcontainer.secrets/env-vars/devcontainer-identity`
3. Remove identity from home: `rm ~/.devcontainer-identity`

**Test Procedure:**
1. Rebuild container
2. Watch installation section

**Expected Output:**
```
📦 Installing enabled tools...

⚠️  OTel Collector - missing prerequisites
  ❌ Developer Identity (run: bash /workspace/.devcontainer/additions/config-devcontainer-identity.sh)

  💡 To fix:
     1. Run: check-configs
     2. Then re-run: bash /workspace/.devcontainer.extend/project-installs.sh

❌ OTel Collector - installation skipped (prerequisites not met)
```

**Verification:**
```bash
# OTel should NOT be installed
command -v otelcol-contrib && echo "FAIL: Installed anyway" || echo "PASS: Not installed"
```

**Pass Criteria:**
- ✅ Clear error message
- ✅ Installation skipped
- ✅ Fix instructions provided

**Cleanup:**
```bash
# Restore identity
bash /workspace/.devcontainer/additions/config-devcontainer-identity.sh
```

---

### Test 2.4: Layer 2 - Prerequisite Success

**Purpose:** Verify tool installs when prerequisites met

**Setup:**
1. Enable OTel in enabled-tools.conf
2. Ensure identity exists in .devcontainer.secrets

**Test Procedure:**
1. Rebuild container
2. Watch installation section

**Expected Output:**
```
📋 Scanning for configuration scripts...
   ✅ Developer Identity restored

📦 Installing enabled tools...

📦 Installing OTel Collector...
(installation output)
✅ OTel Collector - installed successfully
```

**Verification:**
```bash
# OTel should be installed
command -v otelcol-contrib && echo "PASS: Installed" || echo "FAIL: Not installed"
command -v script_exporter && echo "PASS: Installed" || echo "FAIL: Not installed"
```

**Pass Criteria:**
- ✅ Identity restored (Layer 1)
- ✅ Tool installed (Layer 2)
- ✅ No errors

---

### Test 2.5: Auto-Enable Persistence

**Purpose:** Verify auto-enabled tools persist across rebuilds

**Setup:**
1. Fresh enabled-tools.conf with only one tool
2. Note current state

**Test Procedure:**
1. Install tool manually: `bash /workspace/.devcontainer/additions/install-dev-python.sh`
2. Verify added to enabled-tools.conf: `grep "python" /workspace/.devcontainer.extend/enabled-tools.conf`
3. Rebuild container
4. Verify tool auto-installed

**Expected:**
```bash
# After manual install
$ grep "python" /workspace/.devcontainer.extend/enabled-tools.conf
python-development-tools

# After rebuild
$ command -v python3
/usr/bin/python3
```

**Pass Criteria:**
- ✅ Tool added to config on first install
- ✅ Tool auto-installed on rebuild

---

### Test 2.6: Supervisor Config Generation

**Purpose:** Verify config-supervisor.sh generates configs correctly

**Setup:**
1. Enable some services in enabled-services.conf
2. Note current state

**Test Procedure:**
1. Rebuild container
2. Watch for supervisor config generation

**Expected Output:**
```
🔧 Generating supervisor configuration...

ℹ️  Loading enabled services from enabled-services.conf...
ℹ️    Loaded 3 enabled services

ℹ️  Discovering services in /workspace/.devcontainer/additions...
ℹ️    Found: OTel Script Exporter (priority: 30) ✅ ENABLED
ℹ️    Found: OTel Lifecycle (priority: 31) ✅ ENABLED

✅ Discovered 2 services
```

**Verification:**
```bash
# Check supervisor configs generated
ls -la /etc/supervisor/conf.d/otel-*.conf

# Should see:
# otel-script-exporter.conf
# otel-lifecycle.conf
# otel-metrics.conf
```

**Pass Criteria:**
- ✅ Configs generated for enabled services
- ✅ No configs for disabled services

---

### Test 2.7: Full Lifecycle - New User

**Purpose:** Verify complete flow for new user with nothing configured

**Setup:**
1. Clean slate: `rm -rf /workspace/.devcontainer.secrets/env-vars/`
2. Empty configs: `echo "" > /workspace/.devcontainer.extend/enabled-tools.conf`

**Test Procedure:**
1. Rebuild container
2. Watch complete output

**Expected Output:**
```
🔐 Restoring configurations from .devcontainer.secrets...
📋 Scanning for configuration scripts...

ℹ️  No configurations found in .devcontainer.secrets (this is normal for new users)

📦 Installing enabled tools...

ℹ️  No tools enabled for installation
```

**Verification:**
```bash
# Should complete without errors
echo $?  # Should be 0
```

**Pass Criteria:**
- ✅ Clean output with informational messages
- ✅ No errors
- ✅ Container functional

---

### Test 2.8: Full Lifecycle - Existing User

**Purpose:** Verify complete flow for existing user with everything configured

**Setup:**
1. Identity in .devcontainer.secrets
2. OTel enabled in enabled-tools.conf
3. Services enabled in enabled-services.conf

**Test Procedure:**
1. Rebuild container
2. Watch complete output

**Expected Output:**
```
🔐 Restoring configurations from .devcontainer.secrets...
   ✅ Developer Identity restored

📦 Installing enabled tools...
   ✅ Claude Code - already installed
   📦 Installing OTel Collector...
   ✅ OTel Collector - installed successfully

🔧 Generating supervisor configuration...
   ✅ Generated configs for 3 services
```

**Verification:**
```bash
# Identity restored
test -L ~/.devcontainer-identity && echo "PASS" || echo "FAIL"

# Tools installed
command -v otelcol-contrib && echo "PASS" || echo "FAIL"

# Services configured
test -f /etc/supervisor/conf.d/otel-script-exporter.conf && echo "PASS" || echo "FAIL"
```

**Pass Criteria:**
- ✅ All layers work
- ✅ Complete restoration
- ✅ All tools installed
- ✅ Services configured

---

### Test 2.9: Partial Config Restoration

**Purpose:** Verify system handles partial configs gracefully

**Setup:**
1. Identity in .devcontainer.secrets
2. Other configs missing
3. Tools enabled that don't need missing configs

**Test Procedure:**
1. Rebuild container
2. Watch output

**Expected:**
- ✅ Identity restored
- ✅ Tools without prerequisites install
- ✅ Tools with missing prerequisites blocked
- ✅ Clear error messages

**Pass Criteria:**
- System continues despite partial configs
- Clear distinction between what worked and what didn't

---

### Test 2.10: Config Persistence Across Multiple Rebuilds

**Purpose:** Verify configs truly persist

**Test Procedure:**
1. Configure identity: `bash config-devcontainer-identity.sh`
2. Rebuild container → Verify restored
3. Rebuild again → Verify still restored
4. Rebuild third time → Verify still restored

**Verification:**
```bash
# After each rebuild
readlink ~/.devcontainer-identity
cat ~/.devcontainer-identity
```

**Pass Criteria:**
- ✅ Restored on first rebuild
- ✅ Restored on second rebuild
- ✅ Restored on third rebuild
- ✅ Content unchanged

---

## Test Execution Plan

### Phase 1: Unit Tests (30 minutes)

Run all Category 1 tests in current container:
```bash
bash /workspace/.devcontainer/additions/addition-templates/tests/run-unit-tests.sh
```

**Expected Result:** All 10 unit tests pass

---

### Phase 2: Integration Tests (60 minutes)

Execute Category 2 tests one by one with rebuilds:

**Test 2.1-2.2:** Silent restoration (15 min)
**Test 2.3-2.4:** Prerequisite blocking (15 min)
**Test 2.5:** Auto-enable persistence (10 min)
**Test 2.6:** Supervisor generation (10 min)
**Test 2.7-2.10:** Full lifecycle tests (10 min)

---

## Automated Test Script

See: `/workspace/.devcontainer/additions/addition-templates/tests/run-unit-tests.sh` for automated execution

---

## Test Results Template

```
# DevContainer Test Results

**Date:** YYYY-MM-DD
**Tested By:** Name
**Container Version:** X.Y.Z

## Unit Tests (Category 1)

- [ ] Test 1.1: Component Scanner - Install Scripts
- [ ] Test 1.2: Component Scanner - Config Scripts
- [ ] Test 1.3: Prerequisite Checking - Config Present
- [ ] Test 1.4: Prerequisite Checking - Config Missing
- [ ] Test 1.5: --verify Handler Detection
- [ ] Test 1.6: --verify Functionality
- [ ] Test 1.7: Tool Auto-Enable Library
- [ ] Test 1.8: Metadata Extraction Accuracy
- [ ] Test 1.9: CHECK_INSTALLED_COMMAND Logic
- [ ] Test 1.10: Show Missing Prerequisites

**Result:** X/10 passed

## Integration Tests (Category 2)

- [ ] Test 2.1: Layer 1 - Silent Config Restoration
- [ ] Test 2.2: Layer 1 - Silent for Missing Configs
- [ ] Test 2.3: Layer 2 - Prerequisite Blocking
- [ ] Test 2.4: Layer 2 - Prerequisite Success
- [ ] Test 2.5: Auto-Enable Persistence
- [ ] Test 2.6: Supervisor Config Generation
- [ ] Test 2.7: Full Lifecycle - New User
- [ ] Test 2.8: Full Lifecycle - Existing User
- [ ] Test 2.9: Partial Config Restoration
- [ ] Test 2.10: Config Persistence Across Rebuilds

**Result:** X/10 passed

## Overall Result

**Total:** X/20 tests passed
**Status:** ✅ PASS / ❌ FAIL

## Notes

(Any issues or observations)
```

---

## Next Steps

1. Create automated test script
2. Run unit tests
3. Document results
4. Run integration tests (with rebuilds)
5. Update status document with test results
