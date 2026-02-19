#!/bin/bash
# Word Loom TDD Runner
# Runs GUT tests headlessly using the local Godot 4.3 binary.

GODOT_BIN="/home/uli/bin/godot"
PROJECT_PATH="/home/uli/Projects/word-loom/godot"

echo "🚀 Running Word Loom GUT Tests..."

$GODOT_BIN --headless --path "$PROJECT_PATH" -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "✅ Tests Passed!"
else
    echo "❌ Tests Failed with exit code $RESULT"
fi

exit $RESULT
