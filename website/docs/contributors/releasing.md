---
title: Releasing
sidebar_position: 5
---

# Releasing New Versions

How to create and publish new versions of devcontainer-toolbox.

## Version File

The version is stored in `version.txt` at the repository root:

```
1.3.1
```

This file is the single source of truth for the version number.

---

## Release Process

### 1. Update the Version

Edit `version.txt` with the new version number:

```bash
echo "1.3.2" > version.txt
```

### 2. Commit and Push

```bash
git add version.txt
git commit -m "chore: bump version to 1.3.2"
git push
```

### 3. Automatic Release

When you merge a PR to `main`, GitHub Actions automatically:

1. Runs CI tests
2. Auto-updates documentation if needed
3. If tests pass, creates a release:
   - Reads version from `version.txt`
   - Creates `.devcontainer/.version` file
   - Updates `devcontainer.json` with the version
   - Packages everything into `dev_containers.zip`
   - Creates GitHub release tagged "latest"

---

## Version Numbering

Use semantic versioning: `MAJOR.MINOR.PATCH`

| Change Type | Example | When to Use |
|-------------|---------|-------------|
| PATCH (1.0.x) | 1.3.1 → 1.3.2 | Bug fixes, small improvements |
| MINOR (1.x.0) | 1.3.2 → 1.4.0 | New features, backward compatible |
| MAJOR (x.0.0) | 1.4.0 → 2.0.0 | Breaking changes |

---

## How Updates Reach Users

```
You merge PR to main
       ↓
CI Tests run → If pass → Release workflow runs
       ↓
GitHub creates release with dev_containers.zip
       ↓
User runs `dev-update` in their container
       ↓
dev-update fetches version.txt from GitHub
       ↓
Compares with local .devcontainer/.version
       ↓
If newer: downloads and installs update
```

---

## Files Involved

| File | Role |
|------|------|
| `version.txt` | Source of truth for version number |
| `.devcontainer/.version` | Created during release |
| `.devcontainer/devcontainer.json` | Contains `_toolboxVersion` field |
| `.github/workflows/ci-tests.yml` | Runs tests on push |
| `.github/workflows/zip_dev_setup.yml` | Creates release |

---

## Checking Current Version

**In repository:**
```bash
cat version.txt
```

**In a devcontainer:**
```bash
dev-help
```

---

## Troubleshooting

### Release not created?

1. Check if CI tests passed: Go to Actions tab on GitHub
2. The zip workflow only runs after CI tests succeed

### Users not seeing update?

1. Verify the release was created on GitHub
2. User needs to run `dev-update` to check for updates
3. After update, VS Code should prompt to rebuild

### Wrong version in release?

The version comes from `version.txt` at the time of the push. Make sure you committed the updated `version.txt` before pushing.
