# Wordfall Code Style

> GDScript coding conventions for the Wordfall project (Godot 4.6)

## Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| **Files** | `PascalCase` | `LoomDrop.gd`, `GameSettings.gd`, `TopNavBar.tscn` |
| **Classes** | `PascalCase` | `class_name DictionaryService` |
| **Functions** | `snake_case` | `get_color()`, `_on_play_pressed()` |
| **Private Functions** | `_snake_case` (leading underscore) | `_apply_theme()`, `_load_settings()` |
| **Variables** | `snake_case` | `current_theme`, `score` |
| **Private Variables** | `_snake_case` (leading underscore) | `_loaded`, `_words` |
| **Constants** | `UPPER_SNAKE_CASE` | `ROWS`, `SHAKE_COST_NORMAL` |
| **Signals** | `snake_case` (past tense verbs) | `theme_changed`, `word_scored` |
| **Node References** | `snake_case` (matching node name) | `grid_container`, `shake_button` |

### Signal Naming

Use past tense verbs describing what happened:
```gdscript
signal theme_changed                    # Good
signal word_scored(points: int)         # Good
signal score_update                     # Avoid — use past tense
```

### Private vs Public

Prefix with `_` for internal/private members:
```gdscript
var _bag_distribution: Array = []       # Internal state
var _loaded: bool = false               # Private flag

func _setup_dev_toolbar() -> void:      # Private method
func _on_shake_pressed() -> void:       # Signal handler (private convention)
```

## File Organization

### Script Structure

Order within a GDScript file:

```gdscript
extends Node
class_name MyClass                    # 1. class_name (if needed)

## Doc comment describing the script

# 2. Signals
signal something_happened

# 3. Constants
const MAX_SIZE: int = 100

# 4. Exported variables (@export)
@export var speed: float = 10.0

# 5. Regular variables
var health: int = 100
var _private_state: Dictionary = {}

# 6. @onready variables (node references)
@onready var player = %Player
@onready var label: Label = %ScoreLabel

# 7. _ready() and lifecycle methods
func _ready() -> void:
    pass

# 8. Public methods
func take_damage(amount: int) -> void:
    pass

# 9. Private/internal methods
func _calculate_damage() -> int:
    pass

# 10. Signal handlers
func _on_player_died() -> void:
    pass
```

### Scene Organization

Scenes should follow a consistent node hierarchy:
```
LoomDrop (Control)
├── ColorRect (Background)
├── MarginContainer
│   └── VBox
│       ├── TopNavBar (instantiated scene)
│       ├── GridCenter (CenterContainer)
│       │   └── BoardPanel (PanelContainer)
│       │       └── GridContainer (5×5 buttons)
│       └── GameSidebar (instantiated scene)
└── GameOverModal (ColorRect - initially hidden)
```

## Static Typing

Always use static typing where possible:

```gdscript
# Good
var score: int = 0
var grid: Array = []
var current_theme: String = "light"

# Function signatures
func get_color(key: String) -> Color:
func calculate_score(word: String, tiles: int) -> int:

# Avoid
var score = 0           # Inferred, but explicit is better
var data                # Untyped — avoid
```

## Node Access Patterns

### @onready with Type Hints

```gdscript
# Preferred — unique names with type hints
@onready var grid_container: GridContainer = %"GridContainer"
@onready var word_label: Label = %"WordLabel"
@onready var shake_button: Button = %"ShakeButton"
```

### Direct Path Access

```gdscript
# Use $ for direct paths when unique names aren't set
@onready var modal_panel: Panel = $MarginContainer/VBox/Modal/Panel
```

### Safe Node Access

```gdscript
# Use get_node_or_null for optional nodes
@onready var auth_panel: Control = get_node_or_null("%AuthPanel")

# Check before using
if auth_panel:
    auth_panel.visible = true
```

## Signal Connection

Use Godot 4's `connect()` syntax:

```gdscript
func _ready() -> void:
    # Method reference syntax (preferred)
    play_button.pressed.connect(_on_play_pressed)
    ThemeManager.theme_changed.connect(_apply_theme)
    
    # Lambda for simple handlers
    timer.timeout.connect(func():
        drop_letter()
    )
```

### Signal Handler Naming

```gdscript
# Pattern: _on_[node]_[signal]
func _on_play_pressed() -> void:
func _on_settings_pressed() -> void:
func _on_shake_button_pressed() -> void:

# For custom signals from other objects
func _on_theme_manager_theme_changed() -> void:  # Or just _apply_theme
```

## Constants Organization

Group related constants in dedicated files:

```gdscript
# GameConstants.gd — Game mechanic constants
const ROWS: int = 5
const COLS: int = 5
const MIN_WORD_LENGTH: int = 3
const WORD_MULTIPLIERS: Dictionary = {3: 1, 4: 2, 5: 4, 6: 8}

# ThemeConstants.gd — Visual constants
const BG_GAME: Color = Color(0.17, 0.24, 0.31, 1)
const ICON_SHAKE: String = "\u21bb"
```

### Static Helper Functions

```gdscript
# GameConstants.gd
static func get_shake_cost(is_hard_mode: bool) -> int:
    return SHAKE_COST_HARD if is_hard_mode else SHAKE_COST_NORMAL

static func get_drop_interval(is_hard_mode: bool) -> float:
    return DROP_INTERVAL_HARD if is_hard_mode else DROP_INTERVAL_NORMAL
```

## Error Handling

### Defensive Programming

```gdscript
func _load_settings() -> void:
    var config = ConfigFile.new()
    var err = config.load("user://settings.cfg")
    if err == OK:
        has_completed_tutorial = config.get_value("game", "has_completed_tutorial", false)
    # Silently fail with defaults — not critical
```

### Push Error for Critical Issues

```gdscript
func save_stats() -> void:
    var err := config.save(STATS_FILE)
    if err != OK:
        push_error("Failed to save stats: " + str(err))
```

## Platform-Specific Code

Use `OS.has_feature()` for platform checks:

```gdscript
if OS.has_feature("web"):
    # Web-specific code (localStorage, JavaScriptBridge)
    var js = JavaScriptBridge.get_interface("localStorage")
    if js:
        js.setItem("key", "value")
else:
    # Desktop-specific code (ConfigFile, filesystem)
    var config = ConfigFile.new()
    config.save("user://settings.cfg")
```

## Documentation Comments

Use doc comments for classes and public methods:

```gdscript
## Boot scene: routes to LoomDrop on web (React Shell owns navigation),
## or to Home on desktop/editor builds.
## On web, checks window.WORD_LOOM_LAUNCH_SCENE to route to Tutorial or LoomDrop.
extends Node

## Singleton for managing player statistics and progress tracking
## Data persists via ConfigFile (maps to IndexedDB on web builds)
extends Node

## Begin tracking a new game session
func start_session() -> void:
    pass

## Calculate words per minute
func _calculate_wpm(words: int, seconds: float) -> float:
    pass
```

## Dictionary/Array Patterns

### Dictionary as Set

```gdscript
var _words := {}  # Used as Set: word -> true

func _load_from_file() -> void:
    while not f.eof_reached():
        var line := f.get_line().strip_edges()
        if line.is_empty() or line.begins_with("#"):
            continue
        _words[line.to_upper()] = true  # Add to set

func is_valid_word(word: String) -> bool:
    return _words.has(word.to_upper())
```

### Typed Arrays

```gdscript
var session_history: Array[Dictionary] = []
var selected_path: Array = []  # Array of Vector2i
```

## Class Design

### RefCounted for Services

```gdscript
extends RefCounted
class_name DictionaryService

# Good for data services that don't need to be in the scene tree
# Automatically freed when no longer referenced
```

### Node for Scene Objects

```gdscript
extends Control
# Use for UI components and game objects that need to be in the scene tree
```

## Testing Patterns

### GUT Test Structure

```gdscript
extends GutTest

var _game = null

func before_each():
    var scene = load("res://scenes/LoomDrop.tscn")
    _game = scene.instantiate()
    add_child(_game)
    await get_tree().process_frame

func after_each():
    if is_instance_valid(_game):
        _game.free()
    _game = null

func test_ratchet_progression():
    FeatureFlags.drop_ratchet_enabled = true
    var initial_interval = _game.current_drop_interval
    _game._ratchet_drop_speed()
    assert_almost_eq(_game.current_drop_interval, expected, 0.01)
```

## Do's and Don'ts

### Do

- ✅ Use static typing for all variables and function signatures
- ✅ Use `PascalCase` for file names and class names
- ✅ Use `snake_case` for functions and variables
- ✅ Use `UPPER_SNAKE_CASE` for constants
- ✅ Prefix private members with `_`
- ✅ Use `@onready` for node references
- ✅ Connect signals in `_ready()` using `.connect()` syntax
- ✅ Use `get_node_or_null()` for optional nodes
- ✅ Add doc comments for classes and public methods
- ✅ Check for `OS.has_feature("web")` for platform-specific code

### Don't

- ❌ Mix naming conventions (don't use camelCase)
- ❌ Leave variables untyped when type is known
- ❌ Use old `connect(signal, target, method)` syntax
- ❌ Access nodes directly without `@onready` caching
- ❌ Ignore error returns from `load()`, `save()`, etc.
- ❌ Forget to free instantiated scenes in tests
- ❌ Use string-based node paths without safety checks

## Example: Complete Script

```gdscript
extends Control
## Home screen with navigation to game, settings, stats, and tutorial.

signal play_requested

const MAX_HIGH_SCORES: int = 10

@export var show_tutorial_button: bool = true

var current_high_score: int = 0

@onready var play_button: Button = %PlayButton
@onready var high_score_label: Label = %HighScoreLabel

func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    _load_high_score()
    _apply_theme()
    ThemeManager.theme_changed.connect(_apply_theme)

func _load_high_score() -> void:
    current_high_score = StatsManager.high_score
    if high_score_label and current_high_score > 0:
        high_score_label.text = "Best: %d" % current_high_score

func _apply_theme() -> void:
    var bg = $Background
    if bg:
        bg.color = ThemeManager.get_color("background")

func _on_play_pressed() -> void:
    play_requested.emit()
    get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
```
