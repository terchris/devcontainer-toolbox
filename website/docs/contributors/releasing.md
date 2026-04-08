---
title: Releasing
sidebar_position: 5
---

# Releasing New Versions

How to create and publish new versions of devcontainer-toolbox.

## Version System

The toolbox has a single version tracked in `version.txt`:

```
1.7.17
```

This is bumped manually before releases. Changes to `version.txt` trigger:
- A Docker image build and push to `ghcr.io/helpers-no/devcontainer-toolbox`
- CI auto-updates `DCT_IMAGE_VERSION` in `devcontainer-user-template.json`

Users update via `dev-update` which pulls the new image and triggers a VS Code rebuild.

---

## Release Process

### 1. Update the Version

Edit `version.txt` with the new version number:

```bash
echo "1.7.18" > version.txt
```

### 2. Commit and Push

```bash
git add version.txt
git commit -m "chore: bump version to 1.7.18"
git push
```

### 3. Automatic Release

When you merge a PR to `main`, GitHub Actions automatically:

1. Runs CI tests
2. Auto-updates documentation if needed
3. If tests pass:
   - Builds and pushes Docker image (tagged with version + `latest`)
   - Auto-commits the new `DCT_IMAGE_VERSION` to `devcontainer-user-template.json`
   - Deploys the website to GitHub Pages

---

## Version Numbering

Use semantic versioning: `MAJOR.MINOR.PATCH`

| Change Type | Example | When to Use |
|-------------|---------|-------------|
| PATCH (1.0.x) | 1.7.17 → 1.7.18 | Bug fixes, small improvements |
| MINOR (1.x.0) | 1.7.18 → 1.8.0 | New features, backward compatible |
| MAJOR (x.0.0) | 1.8.0 → 2.0.0 | Breaking changes |

---

## How Updates Reach Users

```
You bump version.txt and merge to main
       ↓
CI Tests run → Image build workflow runs
       ↓
New Docker image pushed to ghcr.io (tagged :latest + :1.7.18)
       ↓
User runs `dev-update` in their container
       ↓
dev-update pulls new image + updates DCT_IMAGE_VERSION in devcontainer.json
       ↓
VS Code prompts "Rebuild?" → user clicks Rebuild
       ↓
New container starts with updated image
```

On container startup, the entrypoint checks for updates and shows a notification in the welcome message if a newer version is available.

---

## Files Involved

| File | Role |
|------|------|
| `version.txt` | Version number (manual bump triggers release) |
| `devcontainer-user-template.json` | Template for user projects (includes `DCT_IMAGE_VERSION`) |
| `.devcontainer/devcontainer.json` | Build-mode config (toolbox development only) |
| `.github/workflows/ci-tests.yml` | Runs tests on push |
| `.github/workflows/build-image.yml` | Builds Docker image + updates `DCT_IMAGE_VERSION` (on version.txt change) |
| `.github/workflows/deploy-docs.yml` | Deploys Docusaurus website to GitHub Pages |

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

### Image not built?

1. Check if CI tests passed: Go to Actions tab on GitHub
2. The image build workflow runs in parallel with CI tests
3. Verify `version.txt` was updated — image build only runs when version.txt or scripts change

### Users not seeing update?

1. Verify the image was built: check Actions tab → "Build and Push Container Image"
2. User runs `dev-update` — this pulls the image and triggers rebuild prompt
3. If `dev-update` shows "Already up to date" but user expects an update, check that `version.txt` was actually bumped

### Wrong version in release?

The version comes from `version.txt` at the time of the push. Make sure you committed the updated `version.txt` before pushing.
