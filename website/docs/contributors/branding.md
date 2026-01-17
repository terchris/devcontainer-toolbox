---
title: Branding
sidebar_position: 7
---

# DevContainer Toolbox Branding

Brand assets and guidelines for DevContainer Toolbox.

---

## Name & Abbreviation

| Full Name | Abbreviation | Domain |
|-----------|--------------|--------|
| DevContainer Toolbox | **DCT** | [dct.sovereignsky.no](https://dct.sovereignsky.no) |

**Usage:**
- Use "DevContainer Toolbox" for first mention and formal contexts
- Use "DCT" for subsequent mentions, UI elements, and compact spaces
- The DCT logo can be used as a compact brand mark

---

## Logo

The logo is a green cube with code brackets inside, representing containerized development environments.

<div style={{textAlign: 'center', padding: '2rem', background: '#f5f5f5', borderRadius: '8px', marginBottom: '1rem'}}>
  <img src="/devcontainer-toolbox/img/logo.svg" alt="DevContainer Toolbox Logo" style={{width: '200px', height: 'auto'}} />
  <p style={{marginTop: '1rem', color: '#666', fontSize: '0.875rem'}}>logo.svg (light background)</p>
</div>

<div style={{textAlign: 'center', padding: '2rem', background: '#1e3a5f', borderRadius: '8px', marginBottom: '2rem'}}>
  <img src="/devcontainer-toolbox/img/logo.svg" alt="DevContainer Toolbox Logo" style={{width: '200px', height: 'auto'}} />
  <p style={{marginTop: '1rem', color: '#ccc', fontSize: '0.875rem'}}>logo.svg (dark background)</p>
</div>

### DCT Compact Logo

The DCT logo includes the cube-code icon with "DCT" text:

<div style={{textAlign: 'center', padding: '2rem', background: '#1e3a5f', borderRadius: '8px', marginBottom: '1rem'}}>
  <img src="/devcontainer-toolbox/img/brand/cube-dct-green.svg" alt="DCT Logo" style={{height: '60px', width: 'auto'}} />
</div>

---

## Social Card

Used when sharing links on social media (Twitter, LinkedIn, Facebook, etc.).

<div style={{textAlign: 'center', padding: '1rem', background: '#f5f5f5', borderRadius: '8px', marginBottom: '2rem'}}>
  <img src="/devcontainer-toolbox/img/social-card.jpg" alt="Social Card" style={{width: '100%', maxWidth: '600px', height: 'auto', borderRadius: '4px'}} />
  <p style={{marginTop: '1rem', color: '#666', fontSize: '0.875rem'}}>social-card.jpg (1408x752px)</p>
</div>

---

## Brand Assets

All brand source files are in `website/static/img/brand/`.

### Source SVGs

| File | Description |
|------|-------------|
| `cube-code.svg` | Cube with code symbol (black) |
| `cube-code-green.svg` | Cube with code symbol (green) - used for logo |
| `cube-dct.svg` | Cube-code + DCT text (black) |
| `cube-dct-green.svg` | Cube-code + DCT text (green) - used for social cards |

### Background Images

| File | Description |
|------|-------------|
| `social-card-background.png` | Clean background (Gemini watermark removed) |
| `social-card-background-gemini.png` | Original Gemini output (with watermark) |
| `social-card-generated.png` | Latest generated social card |

### Original Icons (MIT Licensed)

Located in `brand/mit-svg/`:

| File | Source | License |
|------|--------|---------|
| `cube.svg` | [Ionicons](https://ionic.io/ionicons) | MIT |
| `code.svg` | [Ionicons](https://ionic.io/ionicons) | MIT |
| `shield.svg` | [Ionicons](https://ionic.io/ionicons) | MIT |
| `cube-no-line.svg` | Modified cube | MIT |
| `shield-cube.svg` | Combined shield + cube (unused) | MIT |

---

## Published Assets

These files are used by Docusaurus (in `website/static/img/`):

| File | Generated From | Usage |
|------|----------------|-------|
| `logo.svg` | `brand/cube-code-green.svg` | Navbar logo |
| `favicon.ico` | `brand/cube-code-green.svg` | Browser favicon |
| `social-card.jpg` | `brand/social-card-generated.png` | Social media sharing |

---

## Colors

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Navy Blue | `#1e3a5f` | Backgrounds, headers |
| Green | `#3a8f5e` | Logo, cubes, accents |
| Docusaurus Green | `#25c2a0` | Links, buttons |

### Secondary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Dark Navy | `#0d1f33` | Dark mode backgrounds |
| White | `#ffffff` | Text on dark backgrounds |

---

## Logo Concept

The logo combines two elements representing the project's purpose:
- **Isometric Cube**: Container/dev environment
- **Code Brackets `</>`**: Development and coding

---

## Usage Guidelines

### Do
- Use the SVG logo when possible for crisp rendering
- Maintain adequate spacing around the logo
- Use on backgrounds with sufficient contrast

### Don't
- Stretch or distort the logo
- Change the logo colors
- Add effects (shadows, gradients) to the logo
- Use low-resolution versions when SVG is available

---

## Mission Alignment

DevContainer Toolbox is part of the [SovereignSky](https://sovereignsky.no) initiative, promoting digital sovereignty for Norway. The branding reflects:

- **Containerization**: Cube represents isolated, portable dev environments
- **Open Development**: Code brackets represent the developer-first approach

---

## Attribution

Icon assets derived from [Ionicons](https://ionic.io/ionicons) (MIT License).
