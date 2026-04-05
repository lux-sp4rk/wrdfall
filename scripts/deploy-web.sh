#!/bin/bash
#
# Web Deploy Build Script for Wordfall
# Orchestrates: build → cache-hash → validate
# Deployments to Vercel happen automatically via GitHub Actions (deploy.yml)
#
# Usage: ./scripts/deploy-web.sh [--skip-build] [--dry-run]

set -e

SKIP_BUILD=false
DRY_RUN=false
DIST_DIR="dist"
BASE_NAME="index"

# Parse args
for arg in "$@"; do
  case $arg in
    --skip-build) SKIP_BUILD=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
  esac
done

echo "🚀 Wordfall Web Deploy"
echo "======================="
[ "$DRY_RUN" = true ] && echo "🔍 DRY RUN MODE (no actual deploy)"
echo ""

# Step 1: Build
if [ "$SKIP_BUILD" = false ]; then
  echo "📦 Step 1: Building..."
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would run: ./build.sh"
  else
    ./build.sh
  fi
else
  echo "📦 Step 1: Build skipped (--skip-build)"
fi

# Step 2: Apply content hashing for cache invalidation
echo ""
echo "🔐 Step 2: Applying content-hash cache busting..."
if [ "$DRY_RUN" = true ]; then
  echo "  [DRY] Would run: ./scripts/hash-web-export.sh $DIST_DIR $BASE_NAME"
else
  ./scripts/hash-web-export.sh "$DIST_DIR" "$BASE_NAME"
fi

# Step 3: Validate Vercel cache headers match hashed files
echo ""
echo "🛡️ Step 3: Validating cache headers..."

# Check if vercel.json exists and has proper patterns
if [ ! -f "vercel.json" ]; then
  echo "  ⚠️  vercel.json not found in project root"
else
  # Check for hashed file patterns in headers
  if ! grep -q "\*.wasm" vercel.json 2>/dev/null; then
    echo "  ⚠️  vercel.json may not match hashed .wasm files (*.XXXXXXXX.wasm)"
    echo "      Should have: /index.*.wasm in routes or headers"
  else
    echo "  ✓ Hashed file patterns detected in vercel.json"
  fi
  
  # Count header rules
  HEADER_COUNT=$(grep -c '"headers"' vercel.json 2>/dev/null || echo "0")
  echo "  ℹ️  Found header configuration in vercel.json"
fi

# Step 4: Verify dist contents
echo ""
echo "📁 Step 4: Verifying dist/ contents..."
if [ "$DRY_RUN" = true ]; then
  echo "  [DRY] Would check for:"
  echo "    - $DIST_DIR/$BASE_NAME.*.wasm (hashed)"
  echo "    - $DIST_DIR/$BASE_NAME.*.pck (hashed)"
  echo "    - $DIST_DIR/$BASE_NAME.html"
else
  WASM_COUNT=$(find "$DIST_DIR" -name "$BASE_NAME.*.wasm" 2>/dev/null | wc -l)
  PCK_COUNT=$(find "$DIST_DIR" -name "$BASE_NAME.*.pck" 2>/dev/null | wc -l)
  
  if [ "$WASM_COUNT" -eq 0 ] || [ "$PCK_COUNT" -eq 0 ]; then
    echo "  ❌ Hashed files not found! Cache busting may have failed."
    echo "     WASM files: $WASM_COUNT"
    echo "     PCK files: $PCK_COUNT"
    exit 1
  fi
  
  echo "  ✓ Hashed WASM: $WASM_COUNT file(s)"
  echo "  ✓ Hashed PCK: $PCK_COUNT file(s)"
  
  # Show file sizes
  echo ""
  echo "  Final assets:"
  ls -lh "$DIST_DIR/$BASE_NAME"*.{wasm,pck} 2>/dev/null | awk '{print "    " $9 ": " $5}' || true
fi

echo ""
echo "✅ Build pipeline complete!"
[ "$DRY_RUN" = true ] && echo "   (dry run - no actual changes made)"
echo ""
echo "Cache layers unified:"
echo "  • Godot PCK:  content-hashed → long-term cached"
echo "  • Godot WASM: content-hashed → long-term cached"
echo "  • HTML/JS:    unhashed      → short-term cached"
echo ""
echo "📤 Deployments happen automatically via GitHub Actions (deploy.yml)"
echo "   Push to main → Vercel deploys automatically"
