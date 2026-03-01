#!/bin/bash
set -e

echo "🧹 Running asset cleanup..."
rm -f dist/assets/index*.{js,css} 2>/dev/null || true

echo "📦 Git LFS detected. Initializing and pulling binaries..."
git lfs install --skip-repo
git lfs pull || echo "Git LFS pull failed or already initialized"

echo "Verifying Godot export files exist in dist/..."
if [ ! -f "dist/index.wasm" ] && ! ls dist/index.*.wasm > /dev/null 2>&1; then
  echo "Error: Godot WASM not found in dist/. Godot export must be run before build.sh."
  exit 1
fi

# Check if files are already hashed; if not, hash them
if [ -f "dist/index.wasm" ] && ! ls dist/index.*.wasm > /dev/null 2>&1; then
  echo "Hashing Godot export files for cache busting..."
  bash scripts/hash-web-export.sh dist index 2>&1 | grep -E "✅|index\."
fi

# Clean up old hashed files (keep the newest ones)
echo "Cleaning up old versioned Godot files..."
find dist -type f \( -name "index.*.wasm" -o -name "index.*.pck" \) ! -newer dist/index.wasm -delete 2>/dev/null || true

echo "Building landing page..."
cd landing
npm run build
cd ..

# Get the actual hashed filenames
WASM_FILE=$(ls -1 dist/index.*.wasm 2>/dev/null | head -1)
PCK_FILE=$(ls -1 dist/index.*.pck 2>/dev/null | head -1)

if [ -z "$WASM_FILE" ] || [ -z "$PCK_FILE" ]; then
  echo "Error: Missing Godot export files after build"
  exit 1
fi

echo "Found Godot files:"
echo "  WASM: $WASM_FILE"
echo "  PCK:  $PCK_FILE"

# Extract hash from filenames (format: index.HASH.wasm)
GODOT_HASH=$(basename "$WASM_FILE" .wasm | cut -d. -f2)
echo "Godot hash: $GODOT_HASH"

echo "Verifying dictionaries exist..."
if [ ! -f "dist/dictionaries/en.txt" ]; then
  echo "Error: Dictionary not found. Run './godot/build.sh' first."
  exit 1
fi

echo ""
echo "📁 Build output:"
echo "  Landing page: dist/index.html"
echo "  Godot engine: $(basename $WASM_FILE), $(basename $PCK_FILE)"
echo "  Dictionaries: dist/dictionaries/*.txt"
echo ""
echo "📝 Note: Supabase credentials are hardcoded in the game."
echo "   They're public anon keys - safe to commit (security via RLS)."

# Compress dictionaries
echo ""
echo "📦 Compressing dictionaries for optimal delivery..."
bash -c '
  echo "📦 Compressing dictionaries..."
  for dict in dist/dictionaries/*.txt; do
    [ -f "$dict" ] || continue
    lang=$(basename "$dict" .txt)
    echo "  Compressing $lang..."
    
    orig_size=$(wc -c < "$dict")
    
    # Gzip
    gzip -k9 "$dict" 2>/dev/null
    gz_size=$(wc -c < "$dict.gz")
    
    # Brotli (if available)
    br_size=$(wc -c < "$dict" 2>/dev/null)
    if command -v brotli &> /dev/null; then
      brotli -k "$dict" 2>/dev/null
      br_size=$(wc -c < "$dict.br" 2>/dev/null)
    fi
    
    echo "    $lang: $orig_size bytes → gzip: $gz_size bytes, brotli: $br_size bytes"
  done
  
  total_orig=$(find dist/dictionaries -name "*.txt" -exec wc -c {} + 2>/dev/null | tail -1 | awk "{print \$1}")
  total_gz=$(find dist/dictionaries -name "*.txt.gz" -exec wc -c {} + 2>/dev/null | tail -1 | awk "{print \$1}")
  if [ -n "$total_orig" ] && [ "$total_orig" -gt 0 ]; then
    savings=$(( total_orig - total_gz ))
    percent=$(( savings * 100 / total_orig ))
    echo "✅ Total savings: $savings bytes (~$percent%)"
  fi
'

echo "✅ Build complete!"
