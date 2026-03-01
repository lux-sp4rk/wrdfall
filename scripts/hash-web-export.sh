#!/bin/bash
#
# Godot HTML5 Export Hash Script
# Renames .wasm and .pck files with content hash for cache invalidation
# 
# Usage: ./hash-web-export.sh [dist_directory] [base_name]
#   dist_directory: Directory containing exported files (default: dist)
#   base_name: Base name of exported files (default: index)
#

set -e

DIST_DIR="${1:-dist}"
BASE_NAME="${2:-index}"

if [ ! -d "$DIST_DIR" ]; then
    echo "❌ Error: Directory '$DIST_DIR' not found!"
    exit 1
fi

echo "🔧 Godot HTML5 Cache Busting"
echo "   Directory: $DIST_DIR"
echo "   Base name: $BASE_NAME"

# Calculate content hash of wasm file
WASM_FILE="$DIST_DIR/${BASE_NAME}.wasm"
PCK_FILE="$DIST_DIR/${BASE_NAME}.pck"
JS_FILE="$DIST_DIR/${BASE_NAME}.js"
HTML_FILE="$DIST_DIR/${BASE_NAME}.html"

if [ ! -f "$WASM_FILE" ]; then
    echo "❌ Error: WASM file not found: $WASM_FILE"
    exit 1
fi

if [ ! -f "$PCK_FILE" ]; then
    echo "❌ Error: PCK file not found: $PCK_FILE"
    exit 1
fi

# Calculate short hash (first 8 chars of MD5)
echo "📊 Calculating content hashes..."
WASM_HASH=$(md5sum "$WASM_FILE" | cut -d' ' -f1 | cut -c1-8)
PCK_HASH=$(md5sum "$PCK_FILE" | cut -d' ' -f1 | cut -c1-8)

echo "   WASM hash: $WASM_HASH"
echo "   PCK hash:  $PCK_HASH"

# Create new filenames with hash
WASM_NEW="${BASE_NAME}.${WASM_HASH}.wasm"
PCK_NEW="${BASE_NAME}.${PCK_HASH}.pck"

echo "📝 New filenames:"
echo "   $WASM_NEW"
echo "   $PCK_NEW"

# Remove old hashed files if they exist (clean up previous builds)
echo "🧹 Cleaning old hashed files..."
find "$DIST_DIR" -name "${BASE_NAME}.*.wasm" -delete 2>/dev/null || true
find "$DIST_DIR" -name "${BASE_NAME}.*.pck" -delete 2>/dev/null || true

# Rename files
echo "🔄 Renaming files..."
cp "$WASM_FILE" "$DIST_DIR/$WASM_NEW"
cp "$PCK_FILE" "$DIST_DIR/$PCK_NEW"

# Update index.html to reference new filenames
echo "📝 Updating index.html..."
if [ -f "$HTML_FILE" ]; then
    # Replace the GODOT_CONFIG executable entry
    # Pattern: "executable":"index" -> "executable":"index.a1b2c3d4"
    sed -i "s/\"executable\":\"${BASE_NAME}\"/\"executable\":\"${BASE_NAME}.${WASM_HASH}\"/g" "$HTML_FILE"
    
    # Update fileSizes keys from index.wasm to index.{hash}.wasm
    sed -i "s/\"${BASE_NAME}\.wasm\"/\"${BASE_NAME}.${WASM_HASH}.wasm\"/g" "$HTML_FILE"
    sed -i "s/\"${BASE_NAME}\.pck\"/\"${BASE_NAME}.${PCK_HASH}.pck\"/g" "$HTML_FILE"
    
    # Update file sizes for the new filenames in GODOT_CONFIG
    WASM_SIZE=$(stat -c%s "$DIST_DIR/$WASM_NEW" 2>/dev/null || stat -f%z "$DIST_DIR/$WASM_NEW" 2>/dev/null)
    PCK_SIZE=$(stat -c%s "$DIST_DIR/$PCK_NEW" 2>/dev/null || stat -f%z "$DIST_DIR/$PCK_NEW" 2>/dev/null)
    
    sed -i "s/\"${BASE_NAME}\.${WASM_HASH}\.wasm\":[0-9]*/\"${BASE_NAME}.${WASM_HASH}.wasm\":${WASM_SIZE}/g" "$HTML_FILE"
    sed -i "s/\"${BASE_NAME}\.${PCK_HASH}\.pck\":[0-9]*/\"${BASE_NAME}.${PCK_HASH}.pck\":${PCK_SIZE}/g" "$HTML_FILE"
    
    echo "   ✓ index.html updated"
else
    echo "   ⚠️ index.html not found at $HTML_FILE"
fi

# Update index.js if it contains direct references
echo "📝 Updating index.js..."
if [ -f "$JS_FILE" ]; then
    # Update any hardcoded references to the base name
    sed -i "s/${BASE_NAME}\.wasm/${BASE_NAME}.${WASM_HASH}.wasm/g" "$JS_FILE"
    sed -i "s/${BASE_NAME}\.pck/${BASE_NAME}.${PCK_HASH}.pck/g" "$JS_FILE"
    echo "   ✓ index.js updated"
fi

# List files to verify
echo ""
echo "📁 Final dist contents:"
ls -la "$DIST_DIR/${BASE_NAME}"*.{wasm,pck,html,js} 2>/dev/null || ls -la "$DIST_DIR"

echo ""
echo "✅ Cache busting complete!"
echo "   Files are now content-hashed:"
echo "   - $WASM_NEW"
echo "   - $PCK_NEW"
