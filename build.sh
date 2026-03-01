#!/bin/bash
set -e

echo "🧹 Running asset cleanup..."
rm -f dist/assets/index*.{js,css} 2>/dev/null || true

echo "📦 Git LFS setup..."
# Ensure LFS is installed and pull files
git lfs install 2>/dev/null || true
git lfs pull 2>&1 || echo "⚠️ LFS pull may have failed, continuing..."

echo "Checking for Godot files..."
ls -la dist/index.wasm dist/index.pck 2>/dev/null || echo "Files not found yet..."

echo "Verifying Godot export files exist in dist/..."
if [ ! -f "dist/index.wasm" ] && ! ls dist/index.*.wasm > /dev/null 2>&1; then
  echo "Error: Godot WASM not found in dist/."
  echo "Checking what's in dist/:"
  ls -la dist/ 2>/dev/null || echo "dist/ empty or missing"
  exit 1
fi

# Check if files are already hashed; if not, hash them
if [ -f "dist/index.wasm" ] && ! ls dist/index.*.wasm > /dev/null 2>&1; then
  echo "Hashing Godot export files for cache busting..."
  bash scripts/hash-web-export.sh dist index 2>&1 | grep -E "✅|index\.|Error" || true
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
  echo "Contents of dist/:"
  ls -la dist/ 2>/dev/null || echo "dist/ is empty"
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
  echo "Error: Dictionary not found."
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
  for dict in dist/dictionaries/*.txt; do
    [ -f "$dict" ] || continue
    lang=$(basename "$dict" .txt)
    echo "  Compressing $lang..."
    
    orig_size=$(wc -c < "$dict")
    
    # Gzip
    gzip -k9 "$dict" 2>/dev/null
    gz_size=$(wc -c < "$dict.gz" 2>/dev/null || echo 0)
    
    echo "    $lang: $orig_size bytes → gzip: $gz_size bytes"
  done
  echo "✅ Dictionary compression complete"
'

echo "✅ Build complete!"
