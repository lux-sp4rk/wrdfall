# Justfile - Word Loom Tasks
# Usage: just <recipe>

# Default recipe (lists all)
default:
    @just --list

# Run the game in Godot
run:
    godot --path .

# Run with debug output
debug:
    godot --path . --verbose

# Export for Linux
export-linux:
    godot --headless --quit --export-release "Linux/X11" ./builds/word-loom-linux.x86_64

# Export for Web  
export-web:
    godot --headless --quit --export-release "Web" ./builds/web/

# Clean build artifacts
clean:
    rm -rf ./builds/*
    echo "Builds cleaned"

# Run tests (if any)
test:
    echo "No tests configured yet"

# Check project for issues
check:
    gdlint . 2>/dev/null || echo "gdlint not installed"
    @echo "Project structure:"
    @find . -name "*.gd" | wc -l | xargs echo "GDScript files:"
    @find . -name "*.tscn" | wc -l | xargs echo "Scene files:"

# Show git status
status:
    git status -sb

# Quick commit with message
commit msg:
    git add -A && git commit -m "{{msg}}"
