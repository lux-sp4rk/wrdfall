#!/bin/bash
set -e

echo "🧹 Running asset cleanup..."
rm -f dist/index*.{wasm,pck,js,png} dist/assets/index*.{js,css} 2>/dev/null || true

# If Godot files are missing or we are in CI, rebuild them
if [ ! -f "landing/public/index.wasm" ] || [ "$NETLIFY" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
  echo "🏗️  Rebuilding Godot exports from source..."
  ./scripts/export-godot.sh
fi

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
rm -f dist/dictionaries/*.gz dist/dictionaries/*.br 2>/dev/null || true
for dict in dist/dictionaries/*.txt; do
  [ -f "$dict" ] || continue
  lang=$(basename "$dict" .txt)
  # Create .gz (for fallback) and .br (preferred)
  gzip -k9 -c "$dict" > "dist/dictionaries/${lang}.gz" 2>/dev/null || true
  brotli -k -q 11 -o "dist/dictionaries/${lang}.br" "$dict" 2>/dev/null || true
  gz_size=$(stat -c%s "dist/dictionaries/${lang}.gz" 2>/dev/null || echo 0)
  br_size=$(stat -c%s "dist/dictionaries/${lang}.br" 2>/dev/null || echo 0)
  orig_size=$(stat -c%s "$dict" 2>/dev/null || echo 0)
  echo "  $lang: raw=${orig_size}B gzip=${gz_size}B brotli=${br_size}B"
done

echo "✅ Build complete!"
