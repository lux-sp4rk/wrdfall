#!/bin/bash

# Clean stale assets before build
# Removes old hashed JS, WASM, and PCK files to prevent accumulation

set -e

DIST_DIR="dist"
ASSETS_DIR="${DIST_DIR}/assets"

if [ ! -d "$DIST_DIR" ]; then
  echo "⚠️  dist/ directory not found. Skipping cleanup."
  exit 0
fi

echo "🧹 Cleaning stale assets..."

# Count before
BEFORE=$(find "$DIST_DIR" -type f \( -name "*.*.js" -o -name "*.*.wasm" -o -name "*.*.pck" -o -name "*.*.css" \) ! -name "index.html" 2>/dev/null | wc -l)

# Remove versioned asset files (hashed)
find "$DIST_DIR" -type f -regex '.*\.[a-f0-9]\{8\}\.\(js\|wasm\|pck\|css\|png\)$' -delete 2>/dev/null || true

# Remove worklet files from previous builds
find "$DIST_DIR" -type f -name "*.audio.worklet.js" -o -name "*.audio.position.worklet.js" -delete 2>/dev/null || true

# Empty assets directory if it exists
[ -d "$ASSETS_DIR" ] && find "$ASSETS_DIR" -type f -delete 2>/dev/null || true

# Count after
AFTER=$(find "$DIST_DIR" -type f \( -name "*.*.js" -o -name "*.*.wasm" -o -name "*.*.pck" -o -name "*.*.css" \) ! -name "index.html" 2>/dev/null | wc -l)

REMOVED=$((BEFORE - AFTER))
echo "✅ Cleaned $REMOVED stale asset(s)"
