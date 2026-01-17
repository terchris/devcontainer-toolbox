---
title: Working with Images
sidebar_position: 8
---

# Working with Images

The devcontainer includes ImageMagick and rsvg-convert for image manipulation tasks.

---

## Brand Scripts

The `website/static/img/brand/` folder contains scripts to generate and publish brand assets. All scripts must be run inside the devcontainer.

### Create Social Card

Generate a social card with custom title and tagline:

```bash
cd /workspace/website/static/img/brand

# Generate with defaults
./create-social-card.sh $'DevContainer\nToolbox' $'One command.\nFull dev environment.'

# Custom output file
./create-social-card.sh $'My Title' $'My tagline.' cube-dct-green.svg my-card.png
```

**Output:** `social-card-generated.png`

### Publish Social Card

Copy the generated social card to the website location and create optimized JPG:

```bash
./publish-social-card.sh
```

**Output:** `../social-card.jpg` (used by Docusaurus)

### Publish Logo

Copy cube-code-green.svg as the site logo:

```bash
./publish-logo.sh
```

**Output:** `../logo.svg`

### Publish Favicon

Create multi-size favicon from the logo SVG:

```bash
./publish-favicon.sh
```

**Output:** `../favicon.ico` (16x16, 32x32, 48x48)

### Remove Gemini Watermark

Remove the Gemini sparkle watermark from AI-generated images:

```bash
# Remove watermark in place
./remove-gemini-watermark.sh image.png

# Save to new file
./remove-gemini-watermark.sh image.png clean.png

# Custom size and color
./remove-gemini-watermark.sh image.png clean.png 150 "#ffffff"
```

**Default:** Removes 100x100 pixels from lower right corner with navy blue (#1e3a5f).

---

## ImageMagick Basics

All commands run inside the devcontainer at `/workspace/`.

### Get Image Information

```bash
identify image.png
# Output: image.png PNG 1408x752 1408x752+0+0 8-bit sRGB 1.24MB
```

### Paint Over a Region

Fill a rectangular area with a solid color:

```bash
# Syntax: rectangle x1,y1 x2,y2
convert input.png -fill "#1e3a5f" -draw "rectangle 1308,652 1408,752" output.png
```

**Example:** Remove a 100x100 area from the lower right corner of a 1408x752 image:

```bash
convert image.png -fill "#1e3a5f" -draw "rectangle 1308,652 1408,752" image.png
```

Coordinates:
- `1308,652` = top-left of rectangle (1408-100, 752-100)
- `1408,752` = bottom-right of rectangle (image width, image height)

---

## Common Tasks

### Resize an Image

```bash
# Resize to specific width (maintains aspect ratio)
convert input.png -resize 800 output.png

# Resize to specific dimensions
convert input.png -resize 800x600 output.png

# Resize to exact dimensions (may distort)
convert input.png -resize 800x600! output.png
```

### Convert Format

```bash
convert input.png output.jpg
convert input.svg output.png
```

### Convert SVG to PNG (with fonts)

Use `rsvg-convert` for SVGs with text elements:

```bash
rsvg-convert -w 200 input.svg -o output.png
```

### Crop an Image

```bash
# Crop to 800x600 starting at position 100,50
convert input.png -crop 800x600+100+50 output.png
```

### Add a Border

```bash
convert input.png -bordercolor "#1e3a5f" -border 10 output.png
```

### Create Optimized JPG

```bash
convert input.png -quality 85 output.jpg
```

---

## Brand Colors

When editing images for the project, use these brand colors:

| Color | Hex | Usage |
|-------|-----|-------|
| Navy Blue | `#1e3a5f` | Background |
| Green | `#3a8f5e` | Logo, accents |
| White | `#ffffff` | Text |

---

## Tips

- **In-place editing:** You can use the same file for input and output
- **Preview first:** Test on a copy before editing the original
- **Coordinate system:** Origin (0,0) is top-left corner
- **SVG with text:** Use `rsvg-convert` instead of ImageMagick for better font rendering
- **Finding coordinates:** Use an image editor or browser dev tools to find pixel positions
