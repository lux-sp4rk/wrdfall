# CLAUDE.md — Word Loom Instructions

## Project Context
Word Loom is a calm, senior-first word puzzle game built with **Godot 4.x (GDScript)**.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: No ads, no timers, high contrast, large tap targets.

## Core Workflows
- **Build/Run**: Use Godot editor on Mac or headless export for testing.
- **Tests**: (Pending) Use GUT for GDScript unit testing.
- **Data**: Puzzles are defined in `puzzles/*.md` and compiled to `godot/data/puzzles.json`.

## Code Style (GDScript)
- **Signals**: Use the `signal_name.connect(callable)` syntax (Godot 4).
- **Typing**: Use static typing where possible (e.g., `var x: int = 5`).
- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes.
- **Nodes**: Access nodes using the `@onready var name = $Path` pattern.

## Workflow Rules
- **Verification**: After logic changes, run a verification script or check the Godot scene.
- **Git**: Work on feature branches (`fix/` or `feat/`).
- **PRs**: Include a summary of changes and mention which issue is being addressed.
- **Updates**: Keep this `CLAUDE.md` updated with new build commands or style shifts.

## Key Docs
- `SPEC.md`: Core loop and UX constraints.
- `build-plan.md`: Current implementation phase.
- `puzzles/`: Source material for JSON puzzle data.
