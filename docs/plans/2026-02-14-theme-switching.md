# Theme Switching Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add light/dark theme switching with persistent preference across all screens

**Architecture:** ThemeManager autoload with signal-based updates, ConfigFile persistence, and manual color application in each scene's _apply_theme() method

**Tech Stack:** Godot 4.6 (GDScript), ConfigFile for persistence

---

## Task 1: Create ThemeManager Autoload

**Files:**
- Create: `godot/scripts/ThemeManager.gd`

**Step 1: Create ThemeManager.gd file**

```gdscript
extends Node

# Signal emitted when theme changes
signal theme_changed

# Current active theme ("light" or "dark")
var current_theme: String = "light"

# Theme color definitions
var themes: Dictionary = {
	"light": {
		"background": Color(0.96, 0.95, 0.91, 1),
		"card_background": Color(1, 1, 1, 1),
		"primary_button": Color(0.88, 0.47, 0.34, 1),
		"primary_button_hover": Color(0.92, 0.52, 0.39, 1),
		"primary_button_pressed": Color(0.82, 0.42, 0.29, 1),
		"secondary_button": Color(0.48, 0.61, 0.55, 1),
		"secondary_button_hover": Color(0.53, 0.66, 0.60, 1),
		"secondary_button_pressed": Color(0.43, 0.56, 0.50, 1),
		"text_primary": Color(0.17, 0.17, 0.17, 1),
		"text_secondary": Color(0.48, 0.61, 0.55, 1),
		"text_muted": Color(0.6, 0.6, 0.6, 1),
		"divider": Color(0.85, 0.85, 0.85, 0.5),
		"shadow": Color(0, 0, 0, 0.12),
		"tile_background": Color(0.98, 0.97, 0.94, 1),
		"tile_text": Color(0.17, 0.17, 0.17, 1),
		"grid_line": Color(0.8, 0.8, 0.8, 1),
		"selection_highlight": Color(0.88, 0.47, 0.34, 0.3),
	},
	"dark": {
		"background": Color(0.17, 0.24, 0.31, 1),
		"card_background": Color(0.21, 0.29, 0.37, 1),
		"primary_button": Color(0.88, 0.47, 0.34, 1),
		"primary_button_hover": Color(0.92, 0.52, 0.39, 1),
		"primary_button_pressed": Color(0.82, 0.42, 0.29, 1),
		"secondary_button": Color(0.35, 0.50, 0.45, 1),
		"secondary_button_hover": Color(0.40, 0.55, 0.50, 1),
		"secondary_button_pressed": Color(0.30, 0.45, 0.40, 1),
		"text_primary": Color(0.95, 0.95, 0.95, 1),
		"text_secondary": Color(0.60, 0.75, 0.70, 1),
		"text_muted": Color(0.6, 0.6, 0.6, 1),
		"divider": Color(0.4, 0.4, 0.4, 0.3),
		"shadow": Color(0, 0, 0, 0.3),
		"tile_background": Color(0.25, 0.33, 0.41, 1),
		"tile_text": Color(0.95, 0.95, 0.95, 1),
		"grid_line": Color(0.3, 0.4, 0.5, 1),
		"selection_highlight": Color(0.88, 0.47, 0.34, 0.4),
	}
}

func _ready() -> void:
	_load_settings()
	current_theme = GameSettings.theme

func get_color(key: String) -> Color:
	var theme_colors = themes.get(current_theme, themes["light"])
	return theme_colors.get(key, Color.WHITE)

func set_theme(theme_name: String) -> void:
	if theme_name not in ["light", "dark"]:
		push_warning("Invalid theme name: " + theme_name)
		return

	current_theme = theme_name
	GameSettings.theme = theme_name
	_save_settings()
	theme_changed.emit()

func toggle_theme() -> void:
	var new_theme = "dark" if current_theme == "light" else "light"
	set_theme(new_theme)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("game", "theme", GameSettings.theme)
	config.set_value("game", "language", GameSettings.current_language)
	config.set_value("game", "difficulty", GameSettings.difficulty)
	var err = config.save("user://settings.cfg")
	if err != OK:
		push_warning("Failed to save settings: " + str(err))

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		GameSettings.theme = config.get_value("game", "theme", "light")
		GameSettings.current_language = config.get_value("game", "language", "en")
		GameSettings.difficulty = config.get_value("game", "difficulty", "normal")
	else:
		# File doesn't exist yet, use defaults
		pass
```

**Step 2: Verify file was created**

Check: `godot/scripts/ThemeManager.gd` exists

**Step 3: Commit**

```bash
git add godot/scripts/ThemeManager.gd
git commit -m "feat(theme): add ThemeManager autoload with light/dark themes"
```

---

## Task 2: Update GameSettings Autoload

**Files:**
- Modify: `godot/scripts/GameSettings.gd:3-4`

**Step 1: Add theme variable**

In `godot/scripts/GameSettings.gd`, after line 3:

```gdscript
var current_language: String = "en"
var difficulty: String = "normal"
var theme: String = "light"  # Add this line
```

**Step 2: Verify change**

Read file and confirm theme variable exists

**Step 3: Commit**

```bash
git add godot/scripts/GameSettings.gd
git commit -m "feat(theme): add theme variable to GameSettings"
```

---

## Task 3: Configure ThemeManager as Autoload

**Files:**
- Modify: `godot/project.godot` (autoload section)

**Step 1: Add autoload entry**

Open `godot/project.godot` in Godot Editor:
1. Go to Project > Project Settings
2. Select "Autoload" tab
3. Add new autoload:
   - Path: `res://scripts/ThemeManager.gd`
   - Node Name: `ThemeManager`
   - Click "Add"

**Step 2: Verify in project.godot**

Check that `[autoload]` section contains:
```ini
ThemeManager="*res://scripts/ThemeManager.gd"
```

**Step 3: Test autoload works**

Run: Press F5 in Godot
Expected: Game launches without errors, ThemeManager is accessible

**Step 4: Commit**

```bash
git add godot/project.godot
git commit -m "feat(theme): configure ThemeManager as autoload"
```

---

## Task 4: Add Theme Selector to Settings UI

**Files:**
- Modify: `godot/scenes/Settings.tscn` (add ThemeBox after LanguageBox)

**Step 1: Open Settings.tscn in Godot Editor**

1. Double-click `godot/scenes/Settings.tscn`
2. Find the `VBox` node (MarginContainer > VBox)
3. Right-click VBox, select "Add Child Node"
4. Add VBoxContainer, name it "ThemeBox"
5. Move ThemeBox to be after LanguageBox and before DifficultyBox

**Step 2: Add Label to ThemeBox**

1. Right-click ThemeBox, select "Add Child Node"
2. Add Label node
3. Set properties:
   - Text: "Theme"
   - Theme Overrides > Font Sizes > Font Size: 36

**Step 3: Add OptionButton to ThemeBox**

1. Right-click ThemeBox, select "Add Child Node"
2. Add OptionButton node, name it "ThemeOption"
3. Set properties:
   - Unique Name in Owner: checked (%)
   - Custom Minimum Size: (0, 80)
   - Theme Overrides > Font Sizes > Font Size: 32

**Step 4: Configure ThemeBox spacing**

Select ThemeBox node:
- Theme Overrides > Constants > Separation: 16

**Step 5: Save and verify**

Save scene (Ctrl+S)
Expected: ThemeBox appears between Language and Difficulty sections

**Step 6: Commit**

```bash
git add godot/scenes/Settings.tscn
git commit -m "feat(theme): add theme selector UI to Settings screen"
```

---

## Task 5: Update Settings.gd Logic

**Files:**
- Modify: `godot/scripts/Settings.gd:3-8` (add theme_option reference)
- Modify: `godot/scripts/Settings.gd:10-18` (update _ready)
- Add: New methods `_setup_themes()` and `_on_theme_selected()`
- Add: New method `_apply_theme()`

**Step 1: Add theme_option reference**

After line 4 in Settings.gd:

```gdscript
@onready var language_option: OptionButton = %LanguageOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var theme_option: OptionButton = %ThemeOption  # Add this
@onready var difficulty_label: Label = %DifficultyLabel
```

**Step 2: Update _ready() method**

Replace _ready() method:

```gdscript
func _ready() -> void:
	_setup_ui_text()
	_setup_languages()
	_setup_difficulties()
	_setup_themes()  # Add this
	_apply_theme()  # Add this
	_update_sync_ui()
	back_button.pressed.connect(_on_back_pressed)
	StatsManager.auth_completed.connect(_on_auth_completed)
	StatsManager.sync_completed.connect(_on_sync_completed)
	ThemeManager.theme_changed.connect(_apply_theme)  # Add this
```

**Step 3: Add _setup_themes() method**

Add at end of file:

```gdscript
func _setup_themes() -> void:
	theme_option.clear()
	theme_option.add_item("Light", 0)
	theme_option.set_item_metadata(0, "light")
	theme_option.add_item("Dark", 1)
	theme_option.set_item_metadata(1, "dark")

	var selected_index: int = 0 if GameSettings.theme == "light" else 1
	theme_option.selected = selected_index

	if not theme_option.item_selected.is_connected(_on_theme_selected):
		theme_option.item_selected.connect(_on_theme_selected)
```

**Step 4: Add _on_theme_selected() handler**

Add at end of file:

```gdscript
func _on_theme_selected(index: int) -> void:
	var theme_name = theme_option.get_item_metadata(index)
	ThemeManager.set_theme(theme_name)
```

**Step 5: Add _apply_theme() method**

Add at end of file:

```gdscript
func _apply_theme() -> void:
	# Update background
	var bg = $ColorRect
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update difficulty label color
	difficulty_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update all labels in LanguageBox
	var lang_label = $MarginContainer/VBox/LanguageBox/Label
	if lang_label:
		lang_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update ThemeBox label
	var theme_label = $MarginContainer/VBox/ThemeBox/Label
	if theme_label:
		theme_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update title
	var title = $MarginContainer/VBox/Title
	if title:
		title.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
```

**Step 6: Test in Godot**

Run: Press F6 to run Settings scene
Expected:
- Theme selector appears with Light/Dark options
- Selecting a theme changes colors instantly

**Step 7: Commit**

```bash
git add godot/scripts/Settings.gd
git commit -m "feat(theme): add theme switching logic to Settings"
```

---

## Task 6: Update Home Scene Theme Support

**Files:**
- Modify: `godot/scripts/Home.gd:15-32` (update _ready and add _apply_theme)

**Step 1: Update Home.gd _ready() method**

Add theme initialization at end of _ready():

```gdscript
func _ready() -> void:
	# Main navigation
	play_button.pressed.connect(_on_play_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Auth buttons
	if google_button:
		google_button.pressed.connect(_on_google_pressed)
	if sign_out_button:
		sign_out_button.pressed.connect(_on_sign_out_pressed)

	# Listen to auth state changes
	StatsManager.auth_completed.connect(_on_auth_completed)

	# Update UI based on current auth state (only if auth UI exists)
	if auth_panel:
		_update_auth_ui()

	# Apply theme
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)
```

**Step 2: Add _apply_theme() method to Home.gd**

Add at end of file:

```gdscript
func _apply_theme() -> void:
	# Update background
	var bg = $Background
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update main card
	var main_card = $CenterContainer/MainCard
	if main_card:
		var panel_style = main_card.get_theme_stylebox("panel")
		if panel_style:
			panel_style.bg_color = ThemeManager.get_color("card_background")
			panel_style.shadow_color = ThemeManager.get_color("shadow")

	# Update title
	var title = $CenterContainer/MainCard/VBox/TitleContainer/Title
	if title:
		title.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update tagline
	var tagline = $CenterContainer/MainCard/VBox/TitleContainer/Tagline
	if tagline:
		tagline.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))

	# Update Play button StyleBoxes
	var play_btn = %PlayButton
	if play_btn:
		var normal_style = play_btn.get_theme_stylebox("normal")
		if normal_style:
			normal_style.bg_color = ThemeManager.get_color("primary_button")
			normal_style.shadow_color = Color(ThemeManager.get_color("primary_button").r,
				ThemeManager.get_color("primary_button").g,
				ThemeManager.get_color("primary_button").b, 0.2)

		var hover_style = play_btn.get_theme_stylebox("hover")
		if hover_style:
			hover_style.bg_color = ThemeManager.get_color("primary_button_hover")

		var pressed_style = play_btn.get_theme_stylebox("pressed")
		if pressed_style:
			pressed_style.bg_color = ThemeManager.get_color("primary_button_pressed")

	# Update Stats and Settings buttons
	for btn_name in ["%StatsButton", "%SettingsButton"]:
		var btn = get_node_or_null(btn_name)
		if btn:
			var normal_style = btn.get_theme_stylebox("normal")
			if normal_style:
				normal_style.bg_color = ThemeManager.get_color("secondary_button")

			var hover_style = btn.get_theme_stylebox("hover")
			if hover_style:
				hover_style.bg_color = ThemeManager.get_color("secondary_button_hover")

			var pressed_style = btn.get_theme_stylebox("pressed")
			if pressed_style:
				pressed_style.bg_color = ThemeManager.get_color("secondary_button_pressed")

	# Update copyright
	var copyright = $Copyright
	if copyright:
		var muted = ThemeManager.get_color("text_muted")
		copyright.add_theme_color_override("font_color", Color(muted.r, muted.g, muted.b, 0.5))
```

**Step 3: Test in Godot**

Run: Press F5 to run game, go to Settings, toggle theme
Expected: Home screen updates immediately when theme changes

**Step 4: Commit**

```bash
git add godot/scripts/Home.gd
git commit -m "feat(theme): add theme support to Home screen"
```

---

## Task 7: Update LoomDrop Scene Theme Support

**Files:**
- Modify: `godot/scripts/LoomDrop.gd` (add _apply_theme method and connect signal)

**Step 1: Add theme initialization to LoomDrop.gd _ready()**

Find the _ready() method and add at the end (before any return statement):

```gdscript
# Apply theme
_apply_theme()
ThemeManager.theme_changed.connect(_apply_theme)
```

**Step 2: Add _apply_theme() method to LoomDrop.gd**

Add at end of file:

```gdscript
func _apply_theme() -> void:
	# Update background
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update tile backgrounds and text colors
	# Note: Tiles are created dynamically, so we need to update the template
	# The actual tiles will get these colors when created

	# Update score label
	var score_label = %ScoreLabel
	if score_label:
		score_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update word label (shows current selected word)
	var word_label = %WordLabel
	if word_label:
		word_label.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))

	# Update all existing tiles (if any)
	_update_existing_tiles_theme()

func _update_existing_tiles_theme() -> void:
	# Update all existing letter tiles with current theme
	var grid = %GridContainer
	if not grid:
		return

	for child in grid.get_children():
		if child is Button:
			# Update tile background
			var normal_style = child.get_theme_stylebox("normal")
			if normal_style and normal_style is StyleBoxFlat:
				normal_style.bg_color = ThemeManager.get_color("tile_background")

			# Update tile text color
			child.add_theme_color_override("font_color", ThemeManager.get_color("tile_text"))
```

**Step 3: Update tile creation to use theme colors**

Find the method that creates tiles (likely `_create_tile()` or similar) and update it to use ThemeManager colors:

```gdscript
# When creating tiles, use:
tile.add_theme_color_override("font_color", ThemeManager.get_color("tile_text"))

# For StyleBox:
var style = StyleBoxFlat.new()
style.bg_color = ThemeManager.get_color("tile_background")
```

**Step 4: Test in Godot**

Run: Press F5, start game, go to Settings, toggle theme
Expected: Game screen updates with new tile colors, background, and text colors

**Step 5: Commit**

```bash
git add godot/scripts/LoomDrop.gd
git commit -m "feat(theme): add theme support to game screen"
```

---

## Task 8: Update Stats Scene Theme Support

**Files:**
- Read: `godot/scenes/Stats.tscn` to understand structure
- Modify: `godot/scripts/Stats.gd` (if exists, or create it)

**Step 1: Check if Stats.gd exists**

```bash
ls godot/scripts/Stats.gd
```

**Step 2: If Stats.gd exists, add _apply_theme()**

Add to Stats.gd _ready():

```gdscript
_apply_theme()
ThemeManager.theme_changed.connect(_apply_theme)
```

Add method:

```gdscript
func _apply_theme() -> void:
	# Update background
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update all labels to use text_primary
	for child in get_tree().get_nodes_in_group("labels"):
		if child is Label:
			child.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
```

**Step 3: If Stats.gd doesn't exist, create it**

Create `godot/scripts/Stats.gd`:

```gdscript
extends Control

func _ready() -> void:
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

func _apply_theme() -> void:
	var bg = get_node_or_null("ColorRect")
	if bg:
		bg.color = ThemeManager.get_color("background")
```

Then attach it to Stats.tscn in the editor.

**Step 4: Test in Godot**

Run: Navigate to Stats screen, toggle theme in Settings
Expected: Stats screen updates with theme

**Step 5: Commit**

```bash
git add godot/scripts/Stats.gd
git commit -m "feat(theme): add theme support to Stats screen"
```

---

## Task 9: Update TopNavBar Theme Support

**Files:**
- Read: `godot/scenes/TopNavBar.tscn` to understand structure
- Modify: `godot/scripts/TopNavBar.gd` (if exists, or create it)

**Step 1: Check if TopNavBar.gd exists**

```bash
ls godot/scripts/TopNavBar.gd
```

**Step 2: If TopNavBar.gd exists, add _apply_theme()**

Add to _ready():

```gdscript
_apply_theme()
ThemeManager.theme_changed.connect(_apply_theme)
```

Add method:

```gdscript
func _apply_theme() -> void:
	# Update back button if it exists
	var back_btn = get_node_or_null("BackButton")
	if back_btn:
		back_btn.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update any labels
	for child in get_children():
		if child is Label:
			child.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
```

**Step 3: If TopNavBar.gd doesn't exist, create it**

Create `godot/scripts/TopNavBar.gd`:

```gdscript
extends Control

func _ready() -> void:
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

func _apply_theme() -> void:
	# TopNavBar styling
	pass
```

**Step 4: Attach script to scene if needed**

Open TopNavBar.tscn in editor, attach script if not already attached

**Step 5: Test**

Run: Check that TopNavBar updates with theme changes

**Step 6: Commit**

```bash
git add godot/scripts/TopNavBar.gd
git commit -m "feat(theme): add theme support to TopNavBar"
```

---

## Task 10: Manual Theme Switching Test

**Files:**
- Test: All scenes with theme switching

**Step 1: Test Home screen**

Run: Press F5
1. Note initial light theme colors
2. Go to Settings
3. Change theme to Dark
4. Go back to Home
Expected: All colors updated to dark theme

**Step 2: Test Settings screen**

1. In Settings screen
2. Toggle theme selector
Expected: Settings screen colors update immediately

**Step 3: Test game screen**

1. From Home, click Play
2. Note game colors match current theme
3. Go to Settings (if accessible from game)
4. Toggle theme
5. Return to game
Expected: Game colors updated

**Step 4: Test all scenes**

Navigate through: Home → Settings → Stats → Game
Toggle theme while in each screen
Expected: All screens update consistently

**Step 5: Document any issues**

Create list of any visual glitches or missing theme updates

---

## Task 11: Persistence Test

**Files:**
- Test: ConfigFile save/load functionality

**Step 1: Test initial save**

1. Run game in Godot (F5)
2. Go to Settings
3. Change theme to Dark
4. Close game (stop in Godot)

**Step 2: Check settings file created**

For web export (in browser):
- Check browser localStorage (DevTools > Application > Local Storage)

For desktop (in Godot editor):
```bash
# On macOS/Linux
cat ~/Library/Application\ Support/Godot/app_userdata/Word\ Loom/settings.cfg

# Or find user:// directory from Godot
# Project > Open User Data Folder
```

Expected: File contains `theme = "dark"`

**Step 3: Test persistence**

1. Run game again (F5)
2. Check Home screen
Expected: Starts in dark theme (persisted from previous session)

**Step 4: Test theme change persistence**

1. Go to Settings
2. Change theme to Light
3. Close and reopen game
Expected: Starts in light theme

**Step 5: Test fresh install (clear settings)**

1. Delete `settings.cfg` file
2. Run game
Expected: Defaults to light theme

**Step 6: Document results**

Note: Persistence works correctly across sessions

---

## Task 12: Final Verification & Documentation

**Files:**
- Update: `CLAUDE.md` with theme system notes
- Create: `docs/theme-system.md` (optional documentation)

**Step 1: Test success criteria**

Verify all items from design doc:
- [x] User can select Light or Dark theme in Settings
- [x] Theme changes immediately across all screens
- [x] Theme preference persists between sessions
- [x] Both themes maintain high contrast for readability
- [x] All UI elements respond to theme
- [x] Game elements respond to theme
- [x] No visual glitches during theme switching

**Step 2: Update CLAUDE.md**

Add to CLAUDE.md under Project Structure:

```markdown
## Theme System
wordfall supports light and dark themes with persistent user preference.

**Theme Manager:**
- `ThemeManager.gd` - Global autoload managing theme state
- Emits `theme_changed` signal for dynamic updates
- Persists to `user://settings.cfg` (desktop) or localStorage (web)

**Scenes:**
Each scene implements `_apply_theme()` method and connects to `ThemeManager.theme_changed` signal.

**Themes:**
- **Light mode** (default): Warm cream background, terracotta primary, sage secondary
- **Dark mode**: Dark teal background, muted accents, high contrast text

**Settings:**
User can switch theme via Settings > Theme selector (OptionButton).
```

**Step 3: Final commit**

```bash
git add CLAUDE.md
git commit -m "docs: document theme system in CLAUDE.md"
```

**Step 4: Create summary of changes**

Files modified:
- Created: `godot/scripts/ThemeManager.gd`
- Modified: `godot/scripts/GameSettings.gd`
- Modified: `godot/project.godot` (autoload)
- Modified: `godot/scenes/Settings.tscn`
- Modified: `godot/scripts/Settings.gd`
- Modified: `godot/scripts/Home.gd`
- Modified: `godot/scripts/LoomDrop.gd`
- Modified: `godot/scripts/Stats.gd`
- Modified: `godot/scripts/TopNavBar.gd`

---

## Post-Implementation Notes

**Common Gotchas:**
1. StyleBox colors are references - modifying them affects all instances
2. Must call `_apply_theme()` in `_ready()` AFTER UI is initialized
3. ConfigFile uses `user://` path (different per platform)
4. Browser localStorage is domain-specific (test in same domain)

**Future Enhancements:**
- Add system theme detection (prefer dark/light from OS)
- Add custom themes (user-created color schemes)
- Add theme preview in Settings
- Animate theme transitions

**Testing Checklist:**
- [ ] Light theme displays correctly on all screens
- [ ] Dark theme displays correctly on all screens
- [ ] Theme persists after closing/reopening
- [ ] Theme changes update all screens immediately
- [ ] No console errors when switching themes
- [ ] Web export persistence works in browser
- [ ] Desktop export persistence works in user data folder
