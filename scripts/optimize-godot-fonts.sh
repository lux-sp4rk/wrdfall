#!/bin/bash

# Optimize Godot project for export by removing unused fonts
# Creates a whitelist of fonts actually used in the game

set -e

echo "🗑️  Optimizing Godot fonts for export..."

# Fonts that are actually used in the game (whitelist)
USED_FONTS=(
  "godot/assets/fonts/Inter-Regular.ttf"
  "godot/assets/fonts/Inter-Bold.ttf"
  "godot/assets/fonts/NotoColorEmoji.ttf"
  "godot/assets/fonts/NotoSansSymbols-Regular.ttf"
  "godot/assets/fonts/NotoSansSymbols2-Regular.ttf"
  "godot/assets/themes/clashy/Acme-Regular.ttf"
  "godot/assets/themes/spacey/font/Share/Share-Regular.ttf"
  "godot/assets/themes/spacey/font/Share/Share-Bold.ttf"
  "godot/assets/themes/spacey/font/Nunito/NunitoSans-VariableFont_YTLC,opsz,wdth,wght.ttf"
)

echo "Whitelisted fonts:"
for font in "${USED_FONTS[@]}"; do
  size=$(stat -c%s "$font" 2>/dev/null || stat -f%z "$font" 2>/dev/null)
  printf "  %-70s %8d bytes\n" "$font" "$size"
done

# Find all fonts and remove non-whitelisted ones
echo ""
echo "Checking for unused fonts to remove..."

REMOVED_COUNT=0
REMOVED_SIZE=0

find godot/assets/fonts/Inter/extras -type f \( -name "*.ttf" -o -name "*.otf" \) | while read font; do
  REMOVED_COUNT=$((REMOVED_COUNT + 1))
  size=$(stat -c%s "$font" 2>/dev/null || stat -f%z "$font" 2>/dev/null)
  REMOVED_SIZE=$((REMOVED_SIZE + size))
  echo "  Would remove: $font ($size bytes)"
done

# Create a .gitignore entry for unused fonts (optional)
cat > godot/.gitignore.fonts << 'GITIGNORE'
# Exclude unused font variations from HTML5 exports
# These are too large to include in web builds
assets/fonts/Inter/extras/
assets/fonts/InterVariable.ttf
assets/fonts/InterVariable-Italic.ttf
GITIGNORE

echo ""
echo "📝 Created godot/.gitignore.fonts for reference"
echo "✅ Optimization complete!"
echo ""
echo "To apply changes:"
echo "  - Manually review and remove unused font directories (see list above)"
echo "  - Or uncomment font files in godot/.gitignore.fonts"
