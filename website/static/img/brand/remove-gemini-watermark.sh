#!/bin/bash
# remove-gemini-watermark.sh - Remove Gemini watermark from images
#
# Gemini adds a small sparkle/star watermark in the lower right corner of
# generated images. This script paints over it with the background color.
#
# IMPORTANT: Run this script inside the devcontainer where ImageMagick is available.
#
# Usage:
#   ./remove-gemini-watermark.sh <input.png> [output.png] [size] [color]
#
# Arguments:
#   input.png  - Image to process
#   output.png - Optional. Output filename (default: overwrites input)
#   size       - Optional. Size of area to cover in pixels (default: 100)
#   color      - Optional. Background color to use (default: #1e3a5f navy blue)
#
# Examples:
#   # Remove watermark in place
#   ./remove-gemini-watermark.sh my-image.png
#
#   # Save to new file
#   ./remove-gemini-watermark.sh my-image.png my-image-clean.png
#
#   # Custom size and color
#   ./remove-gemini-watermark.sh my-image.png my-image-clean.png 150 "#ffffff"

set -e

INPUT="${1}"
OUTPUT="${2:-$INPUT}"
SIZE="${3:-100}"
COLOR="${4:-#1e3a5f}"

# Check arguments
if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 <input.png> [output.png] [size] [color]"
    echo ""
    echo "Examples:"
    echo "  $0 image.png                    # Remove watermark in place"
    echo "  $0 image.png clean.png          # Save to new file"
    echo "  $0 image.png clean.png 150      # Larger area (150x150)"
    exit 1
fi

# Check input exists
if [[ ! -f "$INPUT" ]]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

# Check ImageMagick
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is required. Run this inside the devcontainer."
    exit 1
fi

# Get image dimensions
DIMENSIONS=$(identify -format "%wx%h" "$INPUT")
WIDTH=$(echo $DIMENSIONS | cut -d'x' -f1)
HEIGHT=$(echo $DIMENSIONS | cut -d'x' -f2)

# Calculate rectangle coordinates (lower right corner)
X1=$((WIDTH - SIZE))
Y1=$((HEIGHT - SIZE))
X2=$WIDTH
Y2=$HEIGHT

echo "Removing Gemini watermark..."
echo "  Input: $INPUT (${WIDTH}x${HEIGHT})"
echo "  Output: $OUTPUT"
echo "  Area: ${SIZE}x${SIZE} pixels in lower right corner"
echo "  Color: $COLOR"

# Paint over the watermark area
convert "$INPUT" -fill "$COLOR" -draw "rectangle $X1,$Y1 $X2,$Y2" "$OUTPUT"

echo "Done!"
