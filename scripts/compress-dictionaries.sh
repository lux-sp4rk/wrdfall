#!/bin/bash

# Compress dictionaries with gzip and optionally brotli
# Reduces dictionary file sizes and adds runtime decompression

set -e

DICT_DIR="dist/dictionaries"

if [ ! -d "$DICT_DIR" ]; then
  echo "⚠️  $DICT_DIR not found. Skipping compression."
  exit 0
fi

echo "📦 Compressing dictionaries..."

# Track compression stats
TOTAL_BEFORE=0
TOTAL_AFTER=0

for lang_file in "$DICT_DIR"/*.txt; do
  if [ ! -f "$lang_file" ]; then
    continue
  fi

  lang=$(basename "$lang_file" .txt)
  before=$(stat -c%s "$lang_file" 2>/dev/null || stat -f%z "$lang_file" 2>/dev/null)
  TOTAL_BEFORE=$((TOTAL_BEFORE + before))

  echo "  Compressing ${lang}..."
  
  # Gzip compression
  gzip -9 -k "$lang_file" -c > "${lang_file}.gz"
  gz_size=$(stat -c%s "${lang_file}.gz" 2>/dev/null || stat -f%z "${lang_file}.gz" 2>/dev/null)
  
  # Brotli compression (if available)
  if command -v brotli &> /dev/null; then
    brotli -9 -k "$lang_file" -c > "${lang_file}.br"
    br_size=$(stat -c%s "${lang_file}.br" 2>/dev/null || stat -f%z "${lang_file}.br" 2>/dev/null)
    echo "    ${lang}: ${before} bytes → gzip: ${gz_size} bytes, brotli: ${br_size} bytes"
    TOTAL_AFTER=$((TOTAL_AFTER + gz_size + br_size))
  else
    echo "    ${lang}: ${before} bytes → gzip: ${gz_size} bytes (brotli not available)"
    TOTAL_AFTER=$((TOTAL_AFTER + gz_size))
  fi
done

# Calculate space savings
if [ $TOTAL_BEFORE -gt 0 ]; then
  SAVED=$((TOTAL_BEFORE - TOTAL_AFTER))
  PERCENT=$((SAVED * 100 / TOTAL_BEFORE))
  echo "✅ Total savings: $SAVED bytes (~${PERCENT}%)"
fi
