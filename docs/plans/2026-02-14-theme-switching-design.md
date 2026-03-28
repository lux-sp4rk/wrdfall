# Theme Switching Design

**Date:** 2026-02-14
**Status:** Approved
**Author:** Claude Code

## Overview

Add light/dark theme switching to wordfall with persistent user preference. All screens (Home, Settings, Stats, LoomDrop, TopNavBar) will respond to theme changes for consistent visual experience.

## Requirements

1. **Two themes:** Light mode (new default) and Dark mode (existing dark teal)
2. **All screens themed:** Home, Settings, Stats, LoomDrop game, TopNavBar
3. **Persistent preference:** Save theme choice to disk/browser storage
4. **Dynamic switching:** Theme updates immediately when changed in Settings
5. **Senior-friendly:** Maintain high contrast and accessibility in both themes

## Architecture

### Core Components

**1. ThemeManager.gd (new autoload)**
- Singleton managing global theme state
- Stores `current_theme: String` ("light" or "dark")
- Defines color dictionaries for each theme
- Emits `theme_changed` signal when theme switches
- Provides helper methods: `get_color(key)`, `set_theme(name)`, `toggle_theme()`
- Handles persistence via ConfigFile to `user://settings.cfg`

**2. GameSettings.gd (update existing)**
- Add `theme: String = "light"` variable
- ThemeManager reads from this on startup
- Settings UI updates this when changed

**3. Each Scene (update all)**
- Connects to `ThemeManager.theme_changed` signal in `_ready()`
- Implements `_apply_theme()` method that updates colors
- Initial theme applied on load

### Signal Flow

```
User changes theme in Settings
  ↓
Settings.gd calls ThemeManager.set_theme("dark")
  ↓
ThemeManager updates GameSettings.theme
  ↓
ThemeManager saves to ConfigFile
  ↓
ThemeManager emits theme_changed signal
  ↓
All scenes receive signal and call _apply_theme()
  ↓
Visual update happens instantly
```

## Theme Definitions

### Light Theme

```gdscript
"light": {
  "background": Color(0.96, 0.95, 0.91, 1),      # Cream #F5F1E8
  "card_background": Color(1, 1, 1, 1),          # White
  "primary_button": Color(0.88, 0.47, 0.34, 1),  # Terracotta #E07856
  "primary_button_hover": Color(0.92, 0.52, 0.39, 1),
  "secondary_button": Color(0.48, 0.61, 0.55, 1), # Sage #7B9B8C
  "secondary_button_hover": Color(0.53, 0.66, 0.60, 1),
  "text_primary": Color(0.17, 0.17, 0.17, 1),    # Dark charcoal
  "text_secondary": Color(0.48, 0.61, 0.55, 1),  # Sage (accents)
  "text_muted": Color(0.6, 0.6, 0.6, 1),         # Gray
  "divider": Color(0.85, 0.85, 0.85, 0.5),       # Light gray
  "shadow": Color(0, 0, 0, 0.12),                # Subtle shadow
  "tile_background": Color(0.98, 0.97, 0.94, 1), # Light tile
  "tile_text": Color(0.17, 0.17, 0.17, 1),       # Dark text
  "grid_line": Color(0.8, 0.8, 0.8, 1),          # Medium gray
  "selection_highlight": Color(0.88, 0.47, 0.34, 0.3), # Terracotta transparent
}
```

### Dark Theme

```gdscript
"dark": {
  "background": Color(0.17, 0.24, 0.31, 1),      # Dark teal #2B3E4F
  "card_background": Color(0.21, 0.29, 0.37, 1), # Lighter teal
  "primary_button": Color(0.88, 0.47, 0.34, 1),  # Terracotta (warmth)
  "primary_button_hover": Color(0.92, 0.52, 0.39, 1),
  "secondary_button": Color(0.35, 0.50, 0.45, 1), # Darker sage
  "secondary_button_hover": Color(0.40, 0.55, 0.50, 1),
  "text_primary": Color(0.95, 0.95, 0.95, 1),    # Near white
  "text_secondary": Color(0.60, 0.75, 0.70, 1),  # Light sage
  "text_muted": Color(0.6, 0.6, 0.6, 1),         # Gray
  "divider": Color(0.4, 0.4, 0.4, 0.3),          # Dark gray
  "shadow": Color(0, 0, 0, 0.3),                 # Stronger shadow
  "tile_background": Color(0.25, 0.33, 0.41, 1), # Dark tile
  "tile_text": Color(0.95, 0.95, 0.95, 1),       # Light text
  "grid_line": Color(0.3, 0.4, 0.5, 1),          # Teal-gray
  "selection_highlight": Color(0.88, 0.47, 0.34, 0.4), # Terracotta transparent
}
```

## Settings Integration

### UI Changes (Settings.tscn)

Add theme selector between Language and Difficulty sections:

```
ThemeBox (VBoxContainer)
  ├─ Label: "Theme" (36pt font)
  └─ ThemeOption (OptionButton, 80px height, 32pt font)
      ├─ Item 0: "Light" (metadata: "light")
      └─ Item 1: "Dark" (metadata: "dark")
```

### Logic Updates (Settings.gd)

```gdscript
@onready var theme_option: OptionButton = %ThemeOption

func _ready() -> void:
    # ... existing code ...
    _setup_themes()
    _apply_theme()
    ThemeManager.theme_changed.connect(_apply_theme)

func _setup_themes() -> void:
    theme_option.clear()
    theme_option.add_item("Light", 0)
    theme_option.set_item_metadata(0, "light")
    theme_option.add_item("Dark", 1)
    theme_option.set_item_metadata(1, "dark")

    var selected_index = 0 if GameSettings.theme == "light" else 1
    theme_option.selected = selected_index

    theme_option.item_selected.connect(_on_theme_selected)

func _on_theme_selected(index: int) -> void:
    var theme_name = theme_option.get_item_metadata(index)
    ThemeManager.set_theme(theme_name)

func _apply_theme() -> void:
    # Update Settings screen colors
    # Background, buttons, labels, etc.
```

## Scene Application

### Standard Pattern (all scenes)

```gdscript
func _ready() -> void:
    # ... existing setup code ...

    _apply_theme()
    ThemeManager.theme_changed.connect(_apply_theme)

func _apply_theme() -> void:
    # Update colors from ThemeManager
```

### Scene-Specific Updates

**Home.tscn:**
- Background ColorRect → `ThemeManager.get_color("background")`
- MainCard PanelContainer → StyleBox bg_color = `"card_background"`
- PlayButton → StyleBox bg_color = `"primary_button"`
- Stats/Settings buttons → StyleBox bg_color = `"secondary_button"`
- Title text → `"text_primary"`
- Tagline text → `"text_secondary"`
- Decorative tiles → Adjust modulate based on theme

**Settings.tscn:**
- Background → `"background"`
- Buttons → `"secondary_button"` or `"primary_button"`
- Labels → `"text_primary"`
- OptionButtons → Custom styling based on theme

**Stats.tscn:**
- Similar to Settings.tscn

**LoomDrop.tscn (game):**
- Background → `"background"`
- Grid container → `"card_background"`
- Letter tiles → `"tile_background"` + `"tile_text"`
- Grid lines → `"grid_line"`
- Selection highlight → `"selection_highlight"`
- Power-up buttons → `"secondary_button"`
- Score labels → `"text_primary"`
- Word preview → `"text_secondary"`

**TopNavBar.tscn:**
- Nav background → `"card_background"` or transparent
- Back button → `"secondary_button"`
- Labels → `"text_primary"`

## Persistence

### ConfigFile Implementation

**File:** `user://settings.cfg`
- Desktop: OS-specific user data directory
- Web: Browser localStorage (automatic)

**Format (INI):**
```ini
[game]
language = "en"
difficulty = "normal"
theme = "light"
```

### Save Logic

```gdscript
# In ThemeManager
func set_theme(theme_name: String) -> void:
    if theme_name not in ["light", "dark"]:
        return

    current_theme = theme_name
    GameSettings.theme = theme_name
    _save_settings()
    theme_changed.emit()

func _save_settings() -> void:
    var config = ConfigFile.new()
    config.set_value("game", "theme", GameSettings.theme)
    config.set_value("game", "language", GameSettings.current_language)
    config.set_value("game", "difficulty", GameSettings.difficulty)
    config.save("user://settings.cfg")
```

### Load Logic

```gdscript
# In ThemeManager._ready()
func _ready() -> void:
    _load_settings()
    current_theme = GameSettings.theme

func _load_settings() -> void:
    var config = ConfigFile.new()
    var err = config.load("user://settings.cfg")
    if err == OK:
        GameSettings.theme = config.get_value("game", "theme", "light")
        GameSettings.current_language = config.get_value("game", "language", "en")
        GameSettings.difficulty = config.get_value("game", "difficulty", "normal")
```

### Timing
- **Load:** ThemeManager._ready() (before any scene)
- **Save:** Immediately on theme change
- **Fallback:** Defaults to "light" if no saved preference

## Implementation Order

1. Create ThemeManager.gd autoload
2. Update GameSettings.gd with theme variable
3. Update Settings.tscn with theme selector UI
4. Update Settings.gd with theme logic
5. Update Home.tscn/_apply_theme()
6. Update LoomDrop.tscn/_apply_theme()
7. Update Stats.tscn/_apply_theme()
8. Update TopNavBar.tscn/_apply_theme()
9. Test theme switching in all scenes
10. Test persistence across sessions

## Success Criteria

- [ ] User can select Light or Dark theme in Settings
- [ ] Theme changes immediately across all screens
- [ ] Theme preference persists between sessions
- [ ] Both themes maintain high contrast for readability
- [ ] All UI elements (buttons, text, backgrounds) respond to theme
- [ ] Game elements (tiles, grid) respond to theme
- [ ] No visual glitches during theme switching
