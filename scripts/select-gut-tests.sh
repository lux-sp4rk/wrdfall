#!/bin/bash
# Maps changed files to relevant GUT test files.
# Outputs a comma-separated list of res:// paths for GUT's -gtest flag,
# or nothing if no Godot files changed.

set -e

# Get files changed vs origin/main (works from any git subdir)
CHANGED_FILES=$(git diff --name-only origin/main...HEAD 2>/dev/null || true)

if [ -z "$CHANGED_FILES" ]; then
	# Nothing changed vs main — probably a new branch or weird state.
	# Default to smoke test to be safe but fast.
	echo "res://tests/test_smoke.gd"
	exit 0
fi

# If infrastructure, test files, or project config changed → run everything.
INFRA=$(echo "$CHANGED_FILES" | grep -E '^(\.github/workflows/|lefthook\.yml|scripts/|godot/project\.godot|godot/export_presets\.cfg|godot/tests/)' || true)
if [ -n "$INFRA" ]; then
	echo "res://tests/test_dictionary.gd,res://tests/test_drop_ratchet.gd,res://tests/test_feature_flags.gd,res://tests/test_game_constants.gd,res://tests/test_game_settings.gd,res://tests/test_smoke.gd"
	exit 0
fi

# Only care about Godot-side changes
GODOT_FILES=$(echo "$CHANGED_FILES" | grep '^godot/' || true)
if [ -z "$GODOT_FILES" ]; then
	exit 0
fi

# Build list of test files (one per line for deduplication)
TEST_LIST=""

# Dictionary
echo "$GODOT_FILES" | grep -qE 'godot/scripts/Dictionary\.gd|godot/data/words_' && TEST_LIST="${TEST_LIST}res://tests/test_dictionary.gd\n"

# Drop Ratchet
echo "$GODOT_FILES" | grep -qE 'godot/scripts/LoomDrop\.gd|godot/scripts/DropRatchet\.gd' && TEST_LIST="${TEST_LIST}res://tests/test_drop_ratchet.gd\n"

# Feature Flags
echo "$GODOT_FILES" | grep -qE 'godot/scripts/FeatureFlags\.gd' && TEST_LIST="${TEST_LIST}res://tests/test_feature_flags.gd\n"

# Game Constants
echo "$GODOT_FILES" | grep -qE 'godot/scripts/GameConstants\.gd' && TEST_LIST="${TEST_LIST}res://tests/test_game_constants.gd\n"

# Game Settings
echo "$GODOT_FILES" | grep -qE 'godot/scripts/GameSettings\.gd' && TEST_LIST="${TEST_LIST}res://tests/test_game_settings.gd\n"

# Scenes or core script changes → smoke test
echo "$GODOT_FILES" | grep -qE 'godot/scenes/|godot/scripts/.*\.gd' && TEST_LIST="${TEST_LIST}res://tests/test_smoke.gd\n"

if [ -z "$TEST_LIST" ]; then
	echo "res://tests/test_smoke.gd"
	exit 0
fi

# Deduplicate, sort, and join with commas
TESTS=$(printf "%b" "$TEST_LIST" | sort -u | grep -v '^$' | paste -sd ',' -)

if [ -z "$TESTS" ]; then
	echo "res://tests/test_smoke.gd"
else
	echo "$TESTS"
fi
