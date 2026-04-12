#!/bin/bash
# scripts/export-godot.sh - Headless Godot export for CI/CD environments
set -e

GODOT_VERSION="4.6"
GODOT_RELEASE="stable"
GODOT_BIN_NAME="Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/${GODOT_BIN_NAME}.zip"
TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz"

# Determine Godot binary path
# Priority: 
# 1. Project-level bin/ (if we download it)
# 2. Local user bin (per package.json)
# 3. Path
if [ -f "./godot_bin" ]; then
    GODOT="./godot_bin"
elif [ -f "$HOME/bin/godot" ]; then
    GODOT="$HOME/bin/godot"
else
    GODOT="godot"
fi

# In CI (Netlify/GitHub Actions), download if not found
if ! command -v "$GODOT" &> /dev/null && [ ! -f "$GODOT" ]; then
    echo "📥 Godot not found. Downloading v${GODOT_VERSION}..."
    curl -fL -o godot.zip "$GODOT_URL"
    unzip -q godot.zip
    mv "$GODOT_BIN_NAME" godot_bin
    chmod +x godot_bin
    GODOT="./godot_bin"
fi

# Ensure templates exist (Godot needs them for headless export)
TEMPLATE_PATH="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}"
if [ ! -d "$TEMPLATE_PATH" ]; then
    echo "📥 Export templates not found. Downloading..."
    curl -fL -o templates.tpz "$TEMPLATES_URL"
    mkdir -p "$TEMPLATE_PATH"
    unzip -q templates.tpz -d /tmp/godot_templates/
    mv /tmp/godot_templates/templates/* "$TEMPLATE_PATH/"
    rm -rf /tmp/godot_templates/ templates.tpz
fi

echo "🚀 Running GUT tests (fail-fast)..."
"$GODOT" --headless --path godot -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

echo "🚀 Exporting Godot project..."
# 1. Preload to import assets
timeout 120 "$GODOT" --headless --path godot --editor --quit >/dev/null 2>&1 || true

# 2. Run export
# Note: output path is relative to the godot project folder if we use --path,
# but our preset says "../landing/public/index.html".
"$GODOT" --headless --path godot --export-release "Web" ../landing/public/index.html

echo "✅ Godot export complete."
