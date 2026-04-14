#!/bin/bash
# Run repomix and pipe output to Gemini for code review
set -e

STYLE=${1:-markdown}
OUTPUT="repomix-output.md"

echo "📦 Running repomix..."
npx repomix@latest --style "$STYLE" --output "$OUTPUT" --verbose

echo ""
echo "📊 Summary:"
grep "Total Files:" "$OUTPUT" | head -1
grep "Total Tokens:" "$OUTPUT" | head -1
grep "Security:" "$OUTPUT" | head -1

echo ""
echo "✅ Output saved to $OUTPUT"
