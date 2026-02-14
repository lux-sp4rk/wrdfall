#!/bin/bash
# Netlify build script for Word Loom
# Simply copies the exported Godot web build to the dist folder

set -e

echo "🎮 Building Word Loom for web..."

# Check that the Godot export exists
if [ ! -d "godot/dist" ]; then
  echo "❌ Error: godot/dist not found."
  echo "   Export the game from Godot first:"
  echo "   Project → Export → Web → Export Project → godot/dist/"
  exit 1
fi

# Copy exported game to publish directory
echo "📦 Copying game files to dist/..."
mkdir -p dist
cp -r godot/dist/* dist/

echo "✅ Build complete!"
echo ""
echo "📝 Note: Supabase credentials are hardcoded in the game."
echo "   They're public anon keys - safe to commit (security via RLS)."
