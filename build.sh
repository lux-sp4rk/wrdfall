#!/bin/bash
# Netlify build script for Word Loom
# Verifies the exported Godot web build exists in dist/

set -e

echo "🎮 Building Word Loom for web..."

# Check that the Godot export exists
if [ ! -f "dist/index.html" ]; then
  echo "❌ Error: dist/index.html not found."
  echo "   Export the game from Godot first:"
  echo "   Project → Export → Web → Export Project"
  echo "   (export_presets.cfg already targets dist/)"
  exit 1
fi

echo "✅ Build complete!"
echo ""
echo "📝 Note: Supabase credentials are hardcoded in the game."
echo "   They're public anon keys - safe to commit (security via RLS)."
