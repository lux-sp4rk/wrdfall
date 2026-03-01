#!/bin/bash

# Analyze which fonts are actually used in Godot project
# and identify candidates for removal from HTML5 export

set -e

echo "🔍 Analyzing Godot font usage..."

# Find all .gd files that reference fonts
echo ""
echo "Fonts referenced in GDScript (.gd files):"
grep -r "load(" godot --include="*.gd" | grep -i "\.ttf\|\.res" | grep -i font | cut -d: -f2 | sort -u || echo "  (none found)"

# Check export_presets.cfg for exclusions
echo ""
echo "Current export_presets.cfg settings:"
grep -A 20 "preset.0.options" godot/export_presets.cfg | head -30 || echo "  (no export presets)"

# List all fonts in the project
echo ""
echo "All fonts in godot/assets/:"
find godot/assets -name "*.ttf" -o -name "*.otf" | while read f; do
  size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null)
  printf "  %-50s %8d bytes\n" "$f" "$size"
done

echo ""
echo "Fonts in godot/addons/ (typically not needed in production):"
find godot/addons -name "*.ttf" | wc -l
echo "  These can be safely removed from HTML5 exports"

# Count total font size
echo ""
echo "📊 Font statistics:"
TOTAL_SIZE=$(find godot -name "*.ttf" -o -name "*.otf" | xargs stat -c%s 2>/dev/null | awk '{s+=$1} END {print s}')
echo "  Total font files: $(find godot -name "*.ttf" -o -name "*.otf" | wc -l)"
echo "  Total size: ~$(awk "BEGIN {printf \"%.2f\", $TOTAL_SIZE / 1048576}") MB"
