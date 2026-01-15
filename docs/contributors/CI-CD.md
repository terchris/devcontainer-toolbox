# CI/CD and GitHub Actions

What happens when code is pushed to GitHub, and how changes get released to users.

---

## The Two-Stage Process

```
┌─────────────────────────────────────────────────────────────────┐
│  STAGE 1: Pull Request (Validation)                             │
│                                                                 │
│  You create a PR                                                │
│         ↓                                                       │
│  CI Tests run on your branch                                    │
│         ↓                                                       │
│  ✅ Tests pass = Safe to merge                                  │
│  ❌ Tests fail = Fix issues before merging                      │
│                                                                 │
│  ⚠️  NO release is created. This is just validation.            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                        You click "Merge"
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STAGE 2: After Merge to Main (Release)                         │
│                                                                 │
│  CI Tests run again on main                                     │
│         ↓                                                       │
│  If tests pass → Release workflow runs automatically            │
│         ↓                                                       │
│  Creates dev_containers.zip with new version                    │
│         ↓                                                       │
│  Users can now run `dev-update` to get your changes             │
└─────────────────────────────────────────────────────────────────┘
```

**Key point:** Users only get your changes AFTER you merge the PR. The PR stage is your safety check.

---

## Before Merging to Main

**Always check before merging a PR:**

1. **Version bump needed?**
   - If this is a new feature or bug fix that users should receive, bump the version
   - Edit `version.txt` with new version number
   - Without a version bump, users won't see your changes when running `dev-update`
   - See [RELEASING.md](RELEASING.md) for version numbering guidelines

2. **CI passing?**
   - All tests must pass before merging
   - Documentation is auto-updated by CI after merge (no manual step needed)

---

## GitHub Actions Workflows

Two workflows run automatically:

### 1. CI Tests (`.github/workflows/ci-tests.yml`)

**Triggers:** Push or PR to main that touches `.devcontainer/` files

**What it does:**

| Stage | Name | What it checks |
|-------|------|----------------|
| 0 | Documentation Update | Auto-regenerates and commits docs (main branch only) |
| 1 | Build Container | Builds the devcontainer image |
| 2 | Static Tests | Syntax, metadata, categories, flags |
| 3 | ShellCheck | Linting (warnings only, doesn't fail) |
| 4 | Unit Tests | `--help` execution, `--verify`, library functions |

**If it fails:**
- Static tests failed → Check script metadata and syntax
- Unit tests failed → Check `--help` and `--verify` implementations

### 2. Release Workflow (`.github/workflows/zip_dev_setup.yml`)

**Triggers:** After CI Tests pass on main branch (not on PRs)

**What it does:**

1. Reads version from `version.txt`
2. Creates `.devcontainer/.version` file with version info
3. Updates `devcontainer.json` with version (triggers VS Code rebuild prompt)
4. Packages `.devcontainer/` and `.devcontainer.extend/` into `dev_containers.zip`
5. Creates GitHub release tagged "latest" with the zip file

**Result:** Users can run `dev-update` to get the new version.

---

## Version Numbering

| Change Type | Example | When to Use |
|-------------|---------|-------------|
| PATCH (1.0.x) | 1.0.3 → 1.0.4 | Bug fixes, small improvements, doc updates |
| MINOR (1.x.0) | 1.0.4 → 1.1.0 | New features, new install scripts |
| MAJOR (x.0.0) | 1.1.0 → 2.0.0 | Breaking changes |

---

## Quick Checklist Before Merge

```
[ ] Tests passing on PR?
[ ] Version bumped in version.txt? (if releasing changes to users)
[ ] dev-docs run? (if install scripts changed)
[ ] Changes committed and pushed?
```

---

## Related Documentation

- [RELEASING.md](RELEASING.md) - Full release process details
- [testing.md](testing.md) - How to run tests locally
- [AI Developer Workflow](../ai-developer/WORKFLOW.md) - Plan to implementation workflow
