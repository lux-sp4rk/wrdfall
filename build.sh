#!/bin/bash
set -e

echo "🧹 Running asset cleanup..."
rm -f landing/dist/index*.{js,wasm,pck,worklet.js,png} 2>/dev/null || true

echo "📦 Git LFS detected. Initializing and pulling binaries..."
git lfs install --skip-repo
git lfs pull || echo "Git LFS pull failed or already initialized"

echo "Cleaning up old versioned Godot files in dist/..."
rm -f dist/index.*.js dist/index.*.wasm dist/index.*.pck dist/index.*.worklet.js dist/index.*.png 2>/dev/null || true

echo "Building landing page..."
cd landing
npm run build
cd ..

echo "Verifying Godot export files exist in dist/..."
if ! ls dist/index.*.wasm > /dev/null 2>&1; then
  echo "Error: Godot WASM not found in dist/. Godot export must be run before build.sh."
  exit 1
fi

# Get the actual hashed filenames
WASM_FILE=$(ls -1 dist/index.*.wasm 2>/dev/null | head -1)
PCK_FILE=$(ls -1 dist/index.*.pck 2>/dev/null | head -1)
JS_FILE=$(ls -1 dist/index.*.js 2>/dev/null | head -1)

if [ -z "$WASM_FILE" ] || [ -z "$PCK_FILE" ]; then
  echo "Error: Missing Godot export files (wasm or pck)"
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

# Copy Godot and dictionary files to landing/dist so they're served with the React app
echo "Copying Godot files to landing/dist/..."
cp "$WASM_FILE" landing/dist/
cp "$PCK_FILE" landing/dist/
cp "$JS_FILE" landing/dist/
mkdir -p landing/dist/dictionaries
cp dist/dictionaries/*.txt landing/dist/dictionaries/ 2>/dev/null || true
cp dist/dictionaries/*.gz landing/dist/dictionaries/ 2>/dev/null || true
cp dist/dictionaries/*.br landing/dist/dictionaries/ 2>/dev/null || true

echo "Verifying landing/dist has all files..."
if [ ! -f "landing/dist/$(basename $WASM_FILE)" ]; then
  echo "Error: Failed to copy WASM to landing/dist/"
  exit 1
fi

# Run minification
echo ""
echo "📦 Running minification..."

cd landing/dist
for js_file in index.*.js; do
  [ -f "$js_file" ] && echo "Processing JS: $js_file"
  [ -f "$js_file" ] && node -e "const fs=require('fs'); const code=fs.readFileSync('$js_file','utf8'); const minified=code.replace(/\/\/.*$/gm,'').replace(/\/\*[\s\S]*?\*\//g,'').replace(/\s+/g,' '); fs.writeFileSync('$js_file',minified);" || true
  [ -f "$js_file" ] && echo "✅ Minified JS: $js_file"
done

for html_file in index.html; do
  [ -f "$html_file" ] && echo "Processing HTML: $html_file"
  [ -f "$html_file" ] && node -e "const fs=require('fs'); const code=fs.readFileSync('$html_file','utf8'); const minified=code.replace(/<!--[\s\S]*?-->/g,'').replace(/\s+/g,' '); fs.writeFileSync('$html_file',minified);" || true
  [ -f "$html_file" ] && echo "✅ Minified HTML: $html_file"
done
cd ../..

echo ""
echo "Landing page: landing/dist/index.html"
echo "Godot engine: landing/dist/$(basename $WASM_FILE), landing/dist/$(basename $PCK_FILE)"
echo "Dictionaries: landing/dist/dictionaries/*.txt"
echo ""
echo "📝 Note: Supabase credentials are hardcoded in the game."
echo "   They're public anon keys - safe to commit (security via RLS)."

# Compress dictionaries in landing/dist
echo ""
echo "📦 Compressing dictionaries for optimal delivery..."
bash -c '
  echo "📦 Compressing dictionaries..."
  for dict in landing/dist/dictionaries/*.txt; do
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
  
  total_orig=$(find landing/dist/dictionaries -name "*.txt" -exec wc -c {} + 2>/dev/null | tail -1 | awk "{print \$1}")
  total_gz=$(find landing/dist/dictionaries -name "*.txt.gz" -exec wc -c {} + 2>/dev/null | tail -1 | awk "{print \$1}")
  if [ -n "$total_orig" ] && [ "$total_orig" -gt 0 ]; then
    savings=$(( total_orig - total_gz ))
    percent=$(( savings * 100 / total_orig ))
    echo "✅ Total savings: $savings bytes (~$percent%)"
  fi
'

echo "✅ Build complete!"
