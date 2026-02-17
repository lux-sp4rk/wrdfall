#!/bin/bash

# Build script for Word Loom (Netlify)

set -e  # Exit on error

echo "Building landing page..."

# --- Git LFS Pull ---
# Force Netlify to pull binary WASM/PCK files if it missed them during the clone.
if command -v git-lfs &> /dev/null; then
  echo "📦 Git LFS detected. Pulling binaries..."
  git lfs pull
else
  echo "⚠️  Git LFS not found in build environment. This may cause 'Magic Word' errors."
fi

npm run build:landing

echo "Verifying dist/ exists..."
if [ ! -d "dist" ]; then
  echo "Error: dist/ directory not found. Run Godot export first."
  exit 1
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
echo "Godot engine: dist/index.wasm, dist/index.pck"
echo "Dictionaries: dist/dictionaries/*.txt"
echo ""
echo "📝 Note: Supabase credentials are hardcoded in the game."
echo "   They're public anon keys - safe to commit (security via RLS)."
