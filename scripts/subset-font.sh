#!/bin/bash

# Subset NotoColorEmoji font to only include glyphs used in the app
# Uses fonttools (pyftsubset) to reduce font file size

set -e

FONT_DIR="dist/assets"
FONT_SOURCE="node_modules/@fontsource/noto-color-emoji/files/noto-color-emoji-400-normal.ttf"
FONT_SUBSET="${FONT_DIR}/noto-color-emoji.subset.ttf"

# Create assets directory if needed
mkdir -p "$FONT_DIR"

# Check if source font exists
if [ ! -f "$FONT_SOURCE" ]; then
  echo "⚠️  NotoColorEmoji font not found at $FONT_SOURCE"
  echo "   Skipping font subsetting."
  exit 0
fi

echo "🔤 Subsetting NotoColorEmoji font..."

# Check if fonttools is installed
if ! command -v pyftsubset &> /dev/null; then
  echo "⚠️  fonttools (pyftsubset) not found. Install with: pip install fonttools"
  exit 0
fi

before=$(stat -c%s "$FONT_SOURCE" 2>/dev/null || stat -f%z "$FONT_SOURCE" 2>/dev/null)

# Read glyph list from analysis
if [ -f "scripts/glyphs.txt" ]; then
  GLYPH_LIST=$(cat scripts/glyphs.txt | sed 's/^/U+/' | paste -sd ',' -)
  echo "   Using analyzed glyphs from scripts/glyphs.txt ($(echo $GLYPH_LIST | tr ',' '\n' | wc -l) glyphs)"
else
  # Fallback: use common emoji
  echo "   Using default emoji subset (glyphs.txt not found)"
  GLYPH_LIST="U+1F600,U+1F601,U+1F602,U+1F603,U+1F604,U+1F605,U+1F606,U+1F607,U+1F608,U+1F609,U+1F60A,U+1F60B,U+1F60C,U+1F60D,U+1F60E,U+1F60F,U+1F610,U+1F611,U+1F612,U+1F613,U+1F614,U+1F615,U+1F616,U+1F617,U+1F618,U+1F619,U+1F61A,U+1F61B,U+1F61C,U+1F61D,U+1F61E,U+1F61F,U+1F620"
fi

# Subset the font to only include specified glyphs
pyftsubset "$FONT_SOURCE" \
  --unicodes="$GLYPH_LIST" \
  --output-file="$FONT_SUBSET" 2>&1 | grep -v "^WARNING" || true

if [ ! -f "$FONT_SUBSET" ]; then
  echo "❌ Font subsetting failed"
  exit 1
fi

after=$(stat -c%s "$FONT_SUBSET" 2>/dev/null || stat -f%z "$FONT_SUBSET" 2>/dev/null)
saved=$((before - after))
percent=$((saved * 100 / before))

echo "✅ Font subset created:"
echo "   Before: $before bytes"
echo "   After:  $after bytes"
echo "   Saved:  $saved bytes (~${percent}%)"
echo "   Path:   $FONT_SUBSET"

# Calculate hash for versioning
FONT_HASH=$(md5sum "$FONT_SUBSET" | cut -c 1-8)
FONT_VERSIONED="${FONT_DIR}/noto-color-emoji.${FONT_HASH}.ttf"
cp "$FONT_SUBSET" "$FONT_VERSIONED"

echo "   Versioned: $FONT_VERSIONED"
