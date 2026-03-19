# Word Loom Code Style

> GDScript coding conventions for the Word Loom project (Godot 4.6)

## Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Files/Classes | `PascalCase` | [LoomDrop.gd](godot/scripts/LoomDrop.gd) |
| Functions/Variables | `snake_case` | `get_color()`, `score` |
| Private members | `_snake_case` | `_apply_theme()`, `_loaded` |
| Constants | `UPPER_SNAKE_CASE` | [GameConstants.gd](godot/scripts/GameConstants.gd) |
| Signals | `snake_case` (past tense) | `theme_changed`, `word_scored` |

## Script Structure
Standard order within GDScript files:
1. `class_name`
2. `signals`, `constants`, `@export`, `variables`, `@onready`
3. Lifecycle methods (`_ready()`, etc.)
4. Public methods → Private/internal methods → Signal handlers

See [godot/scripts/Home.gd](godot/scripts/Home.gd) for a reference script structure.

## Technical Standards

### Typing & Nodes
- **Explicit Typing**: Use static typing for all variables and function signatures. [LoomDrop.gd:20-50](godot/scripts/LoomDrop.gd)
- **Node Access**: Prefer `@onready var name: Type = %"UniqueName"`. Avoid direct path access.
- **Signal Connection**: Use Godot 4 syntax: `node.signal.connect(_on_handler)`.

### Platform Logic
Use `OS.has_feature("web")` for platform-specific persistence and bridging.
- **Web**: `JavaScriptBridge.get_interface("localStorage")`
- **Desktop**: `ConfigFile` class.
- **Reference**: [godot/scripts/GameSettings.gd](godot/scripts/GameSettings.gd)

### Grouped Constants
Store game mechanics in [GameConstants.gd](godot/scripts/GameConstants.gd) and visual values in [ThemeConstants.gd](godot/scripts/ThemeConstants.gd). Use `static func` for calculations like `get_shake_cost()`.

## Testing Patterns
Use the **GUT framework**. Ensure scenes are instantiated and freed correctly in `before_each`/`after_each`.
- **Location**: [godot/tests/](godot/tests/)
- **Template**: [godot/tests/test_drop_ratchet.gd](godot/tests/test_drop_ratchet.gd)

## Quick Review
- ✅ Static typing everywhere
- ✅ PascalCase for filenames/classes
- ✅ Leading `_` for all private members
- ✅ `@onready` + `%UniqueName` + Type Hints
- ✅ Past tense signals
- ❌ No `camelCase`, no untyped variables, no direct node pathing.
