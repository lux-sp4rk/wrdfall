#!/bin/bash
set -e

echo "🧹 Running asset cleanup..."
rm -f landing/dist/index*.{js,wasm,pck,worklet.js,png}

echo "🧹 Cleaning stale assets..."
STALE_COUNT=$(find dist -type f \( -name "index.*.js" -o -name "index.*.wasm" -o -name "index.*.pck" \) -mmin +60 -delete 2>/dev/null | wc -l)
echo "✅ Cleaned $STALE_COUNT stale asset(s)"

echo "📦 Git LFS detected. Initializing and pulling binaries..."
git lfs install --skip-repo
git lfs pull || echo "Git LFS pull failed or already initialized"

echo "Cleaning up old versioned Godot files..."
rm -f dist/index.*.js dist/index.*.wasm dist/index.*.pck dist/index.*.worklet.js dist/index.*.png

echo "Building landing page..."
cd landing
npm run build
cd ..

echo "Verifying Godot export files exist in dist/..."
if ! compgen -G "dist/index.*.wasm" > /dev/null; then
  echo "Error: Godot WASM not found in dist/. Godot export must be run before build.sh."
  exit 1
fi

# Get the actual hashed filenames
WASM_FILE=$(ls -1 dist/index.*.wasm | head -1)
PCK_FILE=$(ls -1 dist/index.*.pck | head -1)
JS_FILE=$(ls -1 dist/index.*.js | head -1)

if [ -z "$WASM_FILE" ] || [ -z "$PCK_FILE" ] || [ -z "$JS_FILE" ]; then
  echo "Error: Missing Godot export files (wasm, pck, or js)"
  exit 1
fi

echo "Found Godot files:"
echo "  WASM: $WASM_FILE"
echo "  PCK:  $PCK_FILE"
echo "  JS:   $JS_FILE"

# Extract hash from filenames (format: index.HASH.wasm)
GODOT_HASH=$(basename "$WASM_FILE" .wasm | cut -d. -f2)
echo "Godot hash: $GODOT_HASH"

# Calculate sizes
WASM_SIZE=$(stat -c%s "$WASM_FILE" 2>/dev/null || stat -f%z "$WASM_FILE" 2>/dev/null)
PCK_SIZE=$(stat -c%s "$PCK_FILE" 2>/dev/null || stat -f%z "$PCK_FILE" 2>/dev/null)

# Calculate MB for Prefetch progress (Vite needs these)
WASM_MB=$(awk "BEGIN {printf \"%.3f\", $WASM_SIZE / 1048576}")
PCK_MB=$(awk "BEGIN {printf \"%.3f\", $PCK_SIZE / 1048576}")

echo "Verifying dictionaries exist..."
if [ ! -f "dist/dictionaries/en.txt" ]; then
  echo "Error: Dictionary not found. Run './godot/build.sh' first."
  exit 1
fi

# Run minification
echo ""
echo "📦 Running minification..."

cd landing/dist
for js_file in index.*.js; do
  echo "Processing JS: $js_file"
  # Minify (simple: remove comments and whitespace)
  node -e "const fs=require('fs'); const code=fs.readFileSync('$js_file','utf8'); const minified=code.replace(/\/\/.*$/gm,'').replace(/\/\*[\s\S]*?\*\//g,'').replace(/\s+/g,' '); fs.writeFileSync('$js_file',minified);" || true
  echo "✅ Minified JS: $js_file"
done

for html_file in index.html; do
  [ -f "$html_file" ] && echo "Processing HTML: $html_file"
  [ -f "$html_file" ] && node -e "const fs=require('fs'); const code=fs.readFileSync('$html_file','utf8'); const minified=code.replace(/<!--[\s\S]*?-->/g,'').replace(/\s+/g,' '); fs.writeFileSync('$html_file',minified);" || true
  [ -f "$html_file" ] && echo "✅ Minified HTML: $html_file"
done
cd ../..

echo ""
echo "Landing page: dist/index.html"
echo "Godot engine: dist/$WASM_FILE, dist/$PCK_FILE"
echo "Dictionaries: dist/dictionaries/*.txt"
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
  
  total_orig=$(find dist/dictionaries -name "*.txt" -exec wc -c {} + | tail -1 | awk "{print \$1}")
  total_gz=$(find dist/dictionaries -name "*.txt.gz" -exec wc -c {} + | tail -1 | awk "{print \$1}")
  savings=$(( total_orig - total_gz ))
  percent=$(( savings * 100 / total_orig ))
  echo "✅ Total savings: $savings bytes (~$percent%)"
'

echo "✅ Build complete!"
