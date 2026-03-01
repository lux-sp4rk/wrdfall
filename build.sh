#!/bin/bash
set -e

echo "🧹 Running asset cleanup..."
rm -f dist/index*.{wasm,pck,js,png} dist/assets/index*.{js,css} 2>/dev/null || true

echo "Verifying Godot files in landing/public/..."
if [ ! -f "landing/public/index.wasm" ]; then
  echo "Error: landing/public/index.wasm not found"
  exit 1
fi

echo "Building landing page..."
cd landing
npm run build
cd ..

echo "Verifying Godot files were copied to dist/..."
if [ ! -f "dist/index.wasm" ]; then
  echo "Error: dist/index.wasm not found after build"
  ls -la dist/
  exit 1
fi

echo "Verifying dictionaries..."
if [ ! -f "dist/dictionaries/en.txt" ]; then
  echo "Error: Dictionary not found"
  exit 1
fi

echo ""
echo "📁 Build output:"
echo "  Landing page: dist/index.html"
echo "  Godot engine: dist/index.wasm, dist/index.pck"
echo "  Dictionaries: dist/dictionaries/*.txt"

# Compress dictionaries
echo ""
echo "📦 Compressing dictionaries..."
for dict in dist/dictionaries/*.txt; do
  [ -f "$dict" ] || continue
  lang=$(basename "$dict" .txt)
  gzip -k9 "$dict" 2>/dev/null || true
  echo "  $lang: compressed"
done

echo "✅ Build complete!"
