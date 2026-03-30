#!/bin/bash

# Comprehensive build with all optimizations enabled
# Runs all asset optimization steps before and after the main build

set -e

echo "🚀 Wordfall Optimized Build Pipeline"
echo "===================================="
echo ""

# Step 1: Analyze glyphs (populate glyphs.txt)
echo "📊 Step 1: Analyzing used glyphs..."
if [ -f "scripts/analyze-glyphs.js" ]; then
  node scripts/analyze-glyphs.js 2>&1 | tail -10
else
  echo "⚠️  analyze-glyphs.js not found"
fi
echo ""

# Step 2: Run standard build
echo "🏗️  Step 2: Running standard build..."
bash build.sh
echo ""

# Step 3: Subset fonts
echo "🔤 Step 3: Subsetting fonts..."
if [ -f "scripts/subset-font.sh" ]; then
  bash scripts/subset-font.sh 2>&1 | tail -5
else
  echo "⚠️  subset-font.sh not found"
fi
echo ""

# Step 4: Compress dictionaries
echo "📦 Step 4: Compressing dictionaries..."
if [ -f "scripts/compress-dictionaries.sh" ]; then
  bash scripts/compress-dictionaries.sh 2>&1 | tail -5
else
  echo "⚠️  compress-dictionaries.sh not found"
fi
echo ""

# Step 5: Generate font CSS
echo "📝 Step 5: Generating font CSS..."
if [ -f "scripts/generate-font-css.sh" ]; then
  bash scripts/generate-font-css.sh 2>&1
else
  echo "⚠️  generate-font-css.sh not found"
fi
echo ""

# Summary
echo "✅ Optimized build complete!"

# Step 6: Post-processing (WASM-OPT and Brotli)
echo "⚡ Step 6: Post-processing artifacts..."
WASM_FILE="landing/public/index.wasm"
PCK_FILE="landing/public/index.pck"

if [ -f "$WASM_FILE" ]; then
    echo "  Running wasm-opt -Oz on $(basename $WASM_FILE)..."
    wasm-opt -Oz "$WASM_FILE" -o "$WASM_FILE"
    echo "  Compressing $(basename $WASM_FILE) with brotli..."
    brotli -9 -f "$WASM_FILE" -o "${WASM_FILE}.br"
fi

if [ -f "$PCK_FILE" ]; then
    echo "  Compressing $(basename $PCK_FILE) with brotli..."
    brotli -9 -f "$PCK_FILE" -o "${PCK_FILE}.br"
fi

echo ""
echo "📊 Build artifacts:"
echo "  Main build: dist/index.html"
echo "  Assets: dist/assets/"
echo "  Dictionaries (compressed): dist/dictionaries/*.{txt,gz,br}"
echo "  Fonts: dist/assets/noto-color-emoji.*.ttf"
echo ""
