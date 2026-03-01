#!/bin/bash

# Build script for Word Loom (Netlify)

set -e  # Exit on error

echo "Building landing page..."

# --- Git LFS Pull ---
# Force Netlify to pull binary WASM/PCK files if it missed them during the clone.
if command -v git-lfs &> /dev/null; then
  echo "📦 Git LFS detected. Initializing and pulling binaries..."
  git lfs install --force
  git lfs pull
else
  echo "⚠️  Git LFS not found in build environment. This may cause 'Magic Word' errors."
fi

# npm run build:godot

echo "Cleaning up old versioned Godot files..."
rm -f dist/index.*.js dist/index.*.wasm dist/index.*.pck dist/index.*.worklet.js dist/index.*.png

echo "Verifying Godot export files exist in dist/..."
if [ ! -f "dist/index.wasm" ]; then
  echo "Error: dist/index.wasm not found. Godot export must be run before build.sh."
  exit 1
fi

# Calculate hash from the WASM and PCK files
echo "Calculating Godot file hashes..."
G_HASH=$(cat dist/index.wasm dist/index.pck | md5sum | cut -c 1-8)
echo "Godot hash: $G_HASH"

# Calculate sizes
WASM_SIZE=$(stat -c%s "dist/index.wasm" 2>/dev/null || stat -f%z "dist/index.wasm" 2>/dev/null)
PCK_SIZE=$(stat -c%s "dist/index.pck" 2>/dev/null || stat -f%z "dist/index.pck" 2>/dev/null)

# Calculate MB for Prefetch progress (Vite needs these)
WASM_MB=$(awk "BEGIN {printf \"%.3f\", $WASM_SIZE / 1048576}")
PCK_MB=$(awk "BEGIN {printf \"%.3f\", $PCK_SIZE / 1048576}")

echo "WASM: $WASM_SIZE bytes ($WASM_MB MB)"
echo "PCK: $PCK_SIZE bytes ($PCK_MB MB)"

# Export versioned filenames and metadata to environment for Vite
export VITE_GODOT_HASH=$G_HASH
export VITE_GODOT_JS="index.$G_HASH"
export VITE_GODOT_WASM="index.$G_HASH"
export VITE_GODOT_PCK="index.$G_HASH.pck"
export VITE_GODOT_WASM_SIZE=$WASM_SIZE
export VITE_GODOT_PCK_SIZE=$PCK_SIZE
export VITE_GODOT_WASM_SIZE_MB=$WASM_MB
export VITE_GODOT_PCK_SIZE_MB=$PCK_MB

echo "Building landing page with Godot version $G_HASH..."
npm run build:landing

# Rename Godot files to versioned names
echo "Versioning Godot files..."
mv dist/index.js "dist/index.$G_HASH.js"
mv dist/index.wasm "dist/index.$G_HASH.wasm"
mv dist/index.pck "dist/index.$G_HASH.pck"

# Optional: rename worker/position files if they exist
[ -f "dist/index.audio.worklet.js" ] && mv "dist/index.audio.worklet.js" "dist/index.$G_HASH.audio.worklet.js"
[ -f "dist/index.audio.position.worklet.js" ] && mv "dist/index.audio.position.worklet.js" "dist/index.$G_HASH.audio.position.worklet.js"

# Optional: rename PNG assets
[ -f "dist/index.png" ] && mv "dist/index.png" "dist/index.$G_HASH.png"
[ -f "dist/index.icon.png" ] && mv "dist/index.icon.png" "dist/index.$G_HASH.icon.png"
[ -f "dist/index.apple-touch-icon.png" ] && mv "dist/index.apple-touch-icon.png" "dist/index.$G_HASH.apple-touch-icon.png"

echo "Verifying dist/ exists..."
if [ ! -d "dist" ]; then
  echo "Error: dist/ directory not found."
  exit 1
fi

echo "Checking versioned WASM size..."
WASM_SIZE_V=$(stat -c%s "dist/index.$G_HASH.wasm" 2>/dev/null || stat -f%z "dist/index.$G_HASH.wasm" 2>/dev/null)
echo "index.$G_HASH.wasm size: $WASM_SIZE_V bytes"
if [ "$WASM_SIZE_V" -lt 1000 ]; then
  echo "❌ Error: index.$G_HASH.wasm is too small! (Likely an LFS pointer)."
  echo "   Pointer content:"
  cat "dist/index.$G_HASH.wasm"
  echo "   Attempting forced pull..."
  git lfs pull || echo "⚠️ git lfs pull failed"
  WASM_SIZE_RETRY=$(stat -c%s "dist/index.$G_HASH.wasm" 2>/dev/null || stat -f%z "dist/index.$G_HASH.wasm" 2>/dev/null)
  echo "index.$G_HASH.wasm size after retry: $WASM_SIZE_RETRY bytes"
  if [ "$WASM_SIZE_RETRY" -lt 1000 ]; then
    echo "❌ ERROR: Still a pointer after retry. Failing build."
    echo "💡 TIP: Ensure GIT_LFS_ENABLED=true is set in Netlify environment variables."
    exit 1
  fi
fi

echo "Verifying dictionaries exist..."
if [ ! -f "dist/dictionaries/en.txt" ]; then
  echo "Error: dist/dictionaries/en.txt not found."
  exit 1
fi

if [ ! -f "dist/dictionaries/es.txt" ]; then
  echo "Error: dist/dictionaries/es.txt not found."
  exit 1
fi

echo "✅ Build complete!"
echo ""
echo "📦 Running minification..."
if [ -f "scripts/minify.js" ]; then
  npm install --no-audit --no-fund --quiet
  node scripts/minify.js
else
  echo "⚠️  Minification script not found. Skipping."
fi
echo ""
echo "Landing page: dist/index.html"
echo "Godot engine: dist/index.$G_HASH.wasm, dist/index.$G_HASH.pck"
echo "Dictionaries: dist/dictionaries/*.txt"
echo ""
echo "📝 Note: Supabase credentials are hardcoded in the game."
echo "   They're public anon keys - safe to commit (security via RLS)."
