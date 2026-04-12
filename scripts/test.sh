#!/bin/bash
# scripts/test.sh - Run GUT tests headlessly
# Used locally and in CI (called by export-godot.sh before export)

set -e

GODOT_VERSION="4.6"
GODOT_RELEASE="stable"
GODOT_BIN_NAME="Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/${GODOT_BIN_NAME}.zip"

# Determine Godot binary path
if [ -f "./godot_bin" ]; then
    GODOT="./godot_bin"
elif [ -f "$HOME/bin/godot" ]; then
    GODOT="$HOME/bin/godot"
else
    GODOT="godot"
fi

# Download if missing
if ! command -v "$GODOT" &> /dev/null && [ ! -f "$GODOT" ]; then
    echo "📥 Godot not found. Downloading v${GODOT_VERSION}..."
    curl -fL -o godot.zip "$GODOT_URL"
    unzip -q godot.zip
    mv "$GODOT_BIN_NAME" godot_bin
    chmod +x godot_bin
    GODOT="./godot_bin"
fi

echo "🚀 Running Wordfall GUT Tests..."

"$GODOT" --headless --path godot -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "✅ Tests Passed!"
else
    echo "❌ Tests Failed with exit code $RESULT"
fi

exit $RESULT
