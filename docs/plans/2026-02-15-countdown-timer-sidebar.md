# Countdown Timer & Sidebar Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add countdown timer showing time until next letter drop, with animated word score feedback, and burger menu sidebar for navigation.

**Architecture:** TopNavBar displays countdown timer in center, swaps to animated word score display for 2 seconds after each word. New GameSidebar component slides in from left for Settings/Stats/Rules/Help navigation. Pause button moves to bottom action bar as a "free action."

**Tech Stack:** Godot 4.6 (GDScript), Tween animations, signal-based communication

---

## Task 1: Add word_scored Signal to LoomDrop

**Files:**
- Modify: `godot/scripts/LoomDrop.gd` (add signal and emit on word validation)

**Step 1: Add word_scored signal declaration**

Find the signal declarations at the top of LoomDrop.gd and add:

```gdscript
signal word_scored(points: int, word_length: int)
```

**Step 2: Emit signal when word is validated**

Find the `_on_score_word_pressed()` method (around line 200-300). After the score is calculated and added, emit the signal:

```gdscript
# After: score += points (or wherever final points are calculated)
word_scored.emit(points, word_text.length())
```

**Step 3: Test in Godot**

Run: Press F5 in Godot
Expected: Game runs without errors (signal not connected yet, but declared)

**Step 4: Commit**

```bash
git add godot/scripts/LoomDrop.gd
git commit -m "feat: add word_scored signal to LoomDrop

Emit signal when word is validated with points and word length.
Part of countdown timer feature.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Add Countdown Timer Display to TopNavBar

**Files:**
- Modify: `godot/scenes/TopNavBar.tscn` (add CenterDisplay container and labels)
- Modify: `godot/scripts/TopNavBar.gd` (add timer tracking logic)

**Step 1: Add CenterDisplay to TopNavBar.tscn**

Open `godot/scenes/TopNavBar.tscn` in Godot editor:

1. Click on TopNavBar (HBoxContainer root)
2. Add new VBoxContainer as child, rename to "CenterDisplay"
3. Set CenterDisplay properties:
   - Layout → Size Flags Horizontal: Fill + Expand
   - Layout → Size Flags Vertical: Fill + Expand
   - Layout → Alignment: Center
4. Add Label as child of CenterDisplay, rename to "TimerLabel"
5. Set TimerLabel properties:
   - Unique Name in Owner: ✓ (enables %TimerLabel access)
   - Text: "8s"
   - Horizontal Alignment: Center
   - Vertical Alignment: Center
   - Theme Overrides → Font Size: 42
6. Add another Label as child of CenterDisplay, rename to "WordScoreLabel"
7. Set WordScoreLabel properties:
   - Unique Name in Owner: ✓
   - Text: "+150 GREAT!"
   - Horizontal Alignment: Center
   - Vertical Alignment: Center
   - Theme Overrides → Font Size: 36
   - Visibility: Off (hidden by default)

**Step 2: Move Spacer after CenterDisplay**

In scene tree, drag the "Spacer" node to be after CenterDisplay (before ScoreContainer).

**Step 3: Add timer tracking to TopNavBar.gd**

Add new properties after existing ones:

```gdscript
@onready var timer_label = %TimerLabel
@onready var word_score_label = %WordScoreLabel

var drop_timer_ref: Timer = null
var is_showing_word_score: bool = false
```

Add new method:

```gdscript
func set_drop_timer(timer: Timer) -> void:
	drop_timer_ref = timer
```

Add _process method to update timer display:

```gdscript
func _process(_delta: float) -> void:
	if not is_showing_word_score and drop_timer_ref and not drop_timer_ref.is_stopped():
		var time_left := ceili(drop_timer_ref.time_left)
		timer_label.text = "%ds" % time_left
```

**Step 4: Connect drop_timer in LoomDrop**

In `godot/scripts/LoomDrop.gd`, find the `_ready()` method. After TopNavBar setup, add:

```gdscript
top_nav_bar.set_drop_timer(drop_timer)
```

**Step 5: Test countdown timer**

Run: Press F5 in Godot
Expected:
- Timer displays in center of top bar
- Counts down from 8s to 0s (Normal mode) or 4s to 0s (Hard mode)
- Updates every second
- Resets when new letter drops

**Step 6: Commit**

```bash
git add godot/scenes/TopNavBar.tscn godot/scripts/TopNavBar.gd godot/scripts/LoomDrop.gd
git commit -m "feat: add countdown timer display to TopNavBar

Timer shows time remaining until next letter drop. Updates in
_process() by reading drop_timer.time_left.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Add Word Score Display and Swap Logic

**Files:**
- Modify: `godot/scripts/TopNavBar.gd` (add word score display methods)

**Step 1: Add word score timer**

In TopNavBar.gd `_ready()` method, after existing setup:

```gdscript
# Create word score display timer (2 seconds)
var word_score_timer := Timer.new()
word_score_timer.wait_time = 2.0
word_score_timer.one_shot = true
word_score_timer.timeout.connect(_on_word_score_timeout)
add_child(word_score_timer)
```

Store reference as property:

```gdscript
var word_score_timer: Timer
```

Update _ready() to assign:

```gdscript
word_score_timer = Timer.new()
# ... rest of setup
```

**Step 2: Add phrase calculation method**

```gdscript
func _calculate_phrase(word_length: int) -> String:
	match word_length:
		3: return "NICE!"
		4: return "GREAT!"
		5: return "AMAZING!"
		6: return "FANTASTIC!"
		_: return "SPECTACULAR!"  # 7+ letters
```

**Step 3: Add show_word_score method**

```gdscript
func show_word_score(points: int, word_length: int) -> void:
	# If already showing word score, restart timer with new score
	if is_showing_word_score:
		word_score_timer.stop()

	is_showing_word_score = true
	timer_label.visible = false

	var phrase := _calculate_phrase(word_length)
	word_score_label.text = "+%d %s" % [points, phrase]
	word_score_label.visible = true

	word_score_timer.start()
```

**Step 4: Add timeout handler**

```gdscript
func _on_word_score_timeout() -> void:
	is_showing_word_score = false
	word_score_label.visible = false
	timer_label.visible = true
```

**Step 5: Connect to word_scored signal in LoomDrop**

In `godot/scripts/LoomDrop.gd` `_ready()` method, after TopNavBar setup:

```gdscript
word_scored.connect(top_nav_bar.show_word_score)
```

**Step 6: Test word score display**

Run: Press F5 in Godot
Expected:
- Score a 3-letter word → "+X NICE!" appears for 2s, then timer returns
- Score a 4-letter word → "+X GREAT!" appears for 2s, then timer returns
- Score a 5+ letter word → "+X AMAZING/FANTASTIC/SPECTACULAR!" appears for 2s
- Timer correctly resumes countdown after word score disappears

**Step 7: Commit**

```bash
git add godot/scripts/TopNavBar.gd godot/scripts/LoomDrop.gd
git commit -m "feat: add word score display with timer swap

When word scored, timer swaps to show points + encouraging phrase
for 2 seconds, then swaps back. Phrase based on word length.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Add Word Score Animations

**Files:**
- Modify: `godot/scripts/TopNavBar.gd` (add animation method)

**Step 1: Add animation method**

```gdscript
func _animate_word_score(word_length: int) -> void:
	var tween := create_tween()

	# Set font size based on word length
	var font_size := 32
	match word_length:
		3: font_size = 32
		4: font_size = 36
		_: font_size = 42
	word_score_label.add_theme_font_size_override("font_size", font_size)

	# Reset transform
	word_score_label.scale = Vector2.ONE
	word_score_label.rotation_degrees = 0

	# Animate based on word length
	match word_length:
		3:  # NICE! - gentle bounce
			tween.tween_property(word_score_label, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.2)

		4:  # GREAT! - bigger bounce with rotation
			tween.tween_property(word_score_label, "scale", Vector2(1.4, 1.4), 0.2)
			tween.tween_property(word_score_label, "rotation_degrees", 5, 0.1)
			tween.tween_property(word_score_label, "rotation_degrees", -5, 0.1)
			tween.tween_property(word_score_label, "rotation_degrees", 0, 0.1)
			tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.2)

		_:  # AMAZING!/FANTASTIC!/SPECTACULAR! - big celebration
			tween.tween_property(word_score_label, "scale", Vector2(1.6, 1.6), 0.3)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.5)
```

**Step 2: Call animation in show_word_score**

In `show_word_score()`, after setting text and visibility:

```gdscript
word_score_label.visible = true

# Add this line:
_animate_word_score(word_length)

word_score_timer.start()
```

**Step 3: Test animations**

Run: Press F5 in Godot
Expected:
- 3-letter word: Gentle scale bounce, font size 32px
- 4-letter word: Bigger bounce with wiggle rotation, font size 36px
- 5+ letter word: Big elastic bounce, font size 42px
- Animations smooth and complete before timer swaps back

**Step 4: Commit**

```bash
git add godot/scripts/TopNavBar.gd
git commit -m "feat: add word score celebration animations

Different animation intensity based on word length:
- 3-letter: gentle bounce
- 4-letter: bigger bounce with rotation
- 5+ letter: elastic celebration

Font size scales with word length.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Create GameSidebar Component

**Files:**
- Create: `godot/scenes/GameSidebar.tscn`
- Create: `godot/scripts/GameSidebar.gd`

**Step 1: Create GameSidebar.tscn**

In Godot:
1. Scene → New Scene → Panel
2. Save as `godot/scenes/GameSidebar.tscn`
3. Rename root Panel to "GameSidebar"
4. Set GameSidebar properties:
   - Layout → Custom Minimum Size: (300, 0)
   - Layout → Anchors Preset: Left Wide
   - Visibility → Visible: Off

**Step 2: Add BackgroundOverlay**

1. Add ColorRect as child of GameSidebar
2. Rename to "BackgroundOverlay"
3. Set properties:
   - Unique Name in Owner: ✓
   - Layout → Anchors Preset: Full Rect
   - Layout → Offset Left: 300 (starts right of sidebar)
   - Layout → Offset Right: 720 (extends to screen edge)
   - Color: Color(0, 0, 0, 0.5)
   - Mouse → Filter: Stop

**Step 3: Add VBoxContainer for buttons**

1. Add VBoxContainer as child of GameSidebar
2. Rename to "ButtonContainer"
3. Set properties:
   - Layout → Anchors Preset: Full Rect
   - Layout → Margins: Top 20, Left 20, Right 20, Bottom 20
   - Theme Overrides → Constants → Separation: 16

**Step 4: Add Close button**

1. Add Button as child of ButtonContainer
2. Rename to "CloseButton"
3. Set properties:
   - Unique Name in Owner: ✓
   - Text: "✕ Close"
   - Custom Minimum Size: (0, 60)
   - Theme Overrides → Font Size: 28

**Step 5: Add navigation buttons**

Add 4 more Buttons as children of ButtonContainer:
1. SettingsButton - Text: "⚙ Settings", Unique Name ✓, Min Height 60, Font Size 28
2. StatsButton - Text: "📊 Stats", Unique Name ✓, Min Height 60, Font Size 28
3. RulesButton - Text: "📖 Rules", Unique Name ✓, Min Height 60, Font Size 28
4. HelpButton - Text: "❓ Help", Unique Name ✓, Min Height 60, Font Size 28

**Step 6: Create GameSidebar.gd**

```gdscript
extends Panel

## Sidebar menu for Settings, Stats, Rules, and Help navigation

signal sidebar_opened
signal sidebar_closed

@onready var close_button = %CloseButton
@onready var settings_button = %SettingsButton
@onready var stats_button = %StatsButton
@onready var rules_button = %RulesButton
@onready var help_button = %HelpButton
@onready var background_overlay = %BackgroundOverlay

var is_open: bool = false

func _ready() -> void:
	close_button.pressed.connect(close)
	settings_button.pressed.connect(_on_settings_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	help_button.pressed.connect(_on_help_pressed)

	# Make overlay clickable to close sidebar
	background_overlay.gui_input.connect(_on_overlay_input)

	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	if is_open:
		return

	is_open = true
	visible = true

	var tween := create_tween()
	position.x = -300  # Start off-screen left
	tween.tween_property(self, "position:x", 0, 0.3).set_ease(Tween.EASE_OUT)

	background_overlay.modulate.a = 0
	tween.parallel().tween_property(background_overlay, "modulate:a", 1.0, 0.3)

	sidebar_opened.emit()

func close() -> void:
	if not is_open:
		return

	is_open = false

	var tween := create_tween()
	tween.tween_property(self, "position:x", -300, 0.3).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(background_overlay, "modulate:a", 0, 0.3)
	tween.tween_callback(func(): visible = false)

	sidebar_closed.emit()

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")

func _on_rules_pressed() -> void:
	# TODO: Create GameRules scene
	print("Rules button pressed - scene not yet created")

func _on_help_pressed() -> void:
	# TODO: Create Help scene
	print("Help button pressed - scene not yet created")

func _apply_theme() -> void:
	# Panel background
	var panel_style = get_theme_stylebox("panel")
	if panel_style:
		panel_style.bg_color = ThemeManager.get_color("background_secondary")

	# Buttons
	for btn in [close_button, settings_button, stats_button, rules_button, help_button]:
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
```

**Step 7: Attach script to scene**

In Godot, select GameSidebar root node → Attach Script → Select `godot/scripts/GameSidebar.gd`

**Step 8: Test sidebar independently**

Run: Open GameSidebar.tscn and press F5
Expected: Sidebar appears (won't animate yet since visible=false by default)

Manually test:
1. Set GameSidebar visibility to On
2. Press F5
3. Expected: Sidebar visible on left, background overlay on right
4. Click Settings/Stats → navigates to those scenes
5. Click Close → prints to console (animation won't work in isolated scene)

**Step 9: Commit**

```bash
git add godot/scenes/GameSidebar.tscn godot/scripts/GameSidebar.gd
git commit -m "feat: create GameSidebar component

Sidebar menu with Settings, Stats, Rules, Help navigation.
Includes slide-in/out animations and semi-transparent overlay.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Add Burger Menu Button to TopNavBar

**Files:**
- Modify: `godot/scenes/TopNavBar.tscn` (add BurgerMenuButton)
- Modify: `godot/scripts/TopNavBar.gd` (add burger button handler)

**Step 1: Add BurgerMenuButton to TopNavBar.tscn**

In Godot, open `godot/scenes/TopNavBar.tscn`:
1. Add Button as FIRST child of TopNavBar (before ExitButton)
2. Rename to "BurgerMenuButton"
3. Set properties:
   - Unique Name in Owner: ✓
   - Text: "☰"
   - Custom Minimum Size: (70, 70)
   - Theme Overrides → Font Size: 36
   - Theme Overrides → Styles → Copy from ExitButton

**Step 2: Add burger button handler to TopNavBar.gd**

Add property:

```gdscript
@onready var burger_button = %BurgerMenuButton

signal burger_pressed
```

In `_ready()`:

```gdscript
burger_button.pressed.connect(_on_burger_pressed)
```

Add method:

```gdscript
func _on_burger_pressed() -> void:
	burger_pressed.emit()
```

**Step 3: Update _apply_theme to include burger button**

In `_apply_theme()`, update the button loop:

```gdscript
# Update Exit, Burger, and Pause buttons
for btn in [exit_button, burger_button, pause_button]:
	if btn:
		# ... existing theme code
```

**Step 4: Test burger button appearance**

Run: Press F5
Expected: Burger menu button (☰) appears as first button in top bar

**Step 5: Commit**

```bash
git add godot/scenes/TopNavBar.tscn godot/scripts/TopNavBar.gd
git commit -m "feat: add burger menu button to TopNavBar

Hamburger icon button emits burger_pressed signal for sidebar
toggle. Styled to match other nav buttons.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Integrate GameSidebar into LoomDrop

**Files:**
- Modify: `godot/scenes/LoomDrop.tscn` (add GameSidebar as child)
- Modify: `godot/scripts/LoomDrop.gd` (connect sidebar signals)

**Step 1: Add GameSidebar to LoomDrop.tscn**

In Godot, open `godot/scenes/LoomDrop.tscn`:
1. Right-click LoomDrop root → Add Child Node → Saved Scene
2. Select `godot/scenes/GameSidebar.tscn`
3. Rename instance to "GameSidebar"
4. Set Unique Name in Owner: ✓
5. Set Z Index: 10 (appears above other UI elements)

**Step 2: Connect burger button to sidebar in LoomDrop.gd**

Add property:

```gdscript
@onready var game_sidebar = %GameSidebar
```

In `_ready()`, after TopNavBar setup:

```gdscript
# Connect burger menu to sidebar
top_nav_bar.burger_pressed.connect(game_sidebar.toggle)

# Pause game when sidebar opens/closes
game_sidebar.sidebar_opened.connect(_on_sidebar_opened)
game_sidebar.sidebar_closed.connect(_on_sidebar_closed)
```

Add handlers:

```gdscript
func _on_sidebar_opened() -> void:
	# Pause the game
	drop_timer.paused = true

func _on_sidebar_closed() -> void:
	# Resume if game wasn't already paused
	if not top_nav_bar.is_paused:
		drop_timer.paused = false
```

**Step 3: Test sidebar integration**

Run: Press F5
Expected:
- Click burger menu → sidebar slides in from left
- Game pauses (drop timer stops)
- Click Close or overlay → sidebar slides out
- Game resumes (drop timer continues)
- Navigation buttons (Settings, Stats) work

**Step 4: Commit**

```bash
git add godot/scenes/LoomDrop.tscn godot/scripts/LoomDrop.gd
git commit -m "feat: integrate GameSidebar into LoomDrop

Connect burger menu to sidebar toggle. Game pauses when sidebar
opens and resumes when closed.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Move Pause Button to Bottom Action Bar

**Files:**
- Modify: `godot/scenes/TopNavBar.tscn` (remove Pause button)
- Modify: `godot/scenes/LoomDrop.tscn` (add Pause to bottom bar)
- Modify: `godot/scripts/TopNavBar.gd` (remove pause logic)
- Modify: `godot/scripts/LoomDrop.gd` (handle pause in main game)

**Step 1: Remove Pause button from TopNavBar.tscn**

In Godot, open `godot/scenes/TopNavBar.tscn`:
1. Select PauseButton node
2. Right-click → Delete

**Step 2: Remove pause code from TopNavBar.gd**

Remove these lines:

```gdscript
@onready var pause_button = %PauseButton
signal pause_pressed
var is_paused: bool = false
```

Remove `_on_pause_pressed()` method.

Remove `set_paused()` method.

Remove `pause_button.pressed.connect(_on_pause_pressed)` from `_ready()`.

Update `_apply_theme()` to remove `pause_button` from button loop:

```gdscript
for btn in [exit_button, burger_button]:
```

**Step 3: Add Pause button to LoomDrop.tscn bottom bar**

In Godot, open `godot/scenes/LoomDrop.tscn`:
1. Find the HBoxContainer that contains ShakeButton, SwapButton, DrawMoreButton
2. Add Button as child (after DrawMoreButton)
3. Rename to "PauseButton"
4. Set properties:
   - Unique Name in Owner: ✓
   - Text: "⏸ Pause\n(Free)"
   - Custom Minimum Size: (135, 100)
   - Theme Overrides → Font Size: 22
   - Theme Overrides → Styles → Copy from ShakeButton
5. Reduce all power-up button widths from 150 to 135:
   - ShakeButton: Custom Minimum Size X: 135
   - SwapButton: Custom Minimum Size X: 135
   - DrawMoreButton: Custom Minimum Size X: 135

**Step 4: Update LoomDrop.gd to handle pause button**

Add property:

```gdscript
@onready var pause_button = %PauseButton

var is_paused: bool = false
```

In `_ready()`:

```gdscript
pause_button.pressed.connect(_on_pause_pressed)
```

Add pause handler:

```gdscript
func _on_pause_pressed() -> void:
	is_paused = !is_paused
	pause_button.text = "▶ Resume\n(Free)" if is_paused else "⏸ Pause\n(Free)"

	if is_paused:
		drop_timer.paused = true
		word_label.text = lang_config.ui_strings.get("paused", "Game Paused")
	else:
		drop_timer.paused = false
		word_label.text = ""

	# Update button states
	_update_button_states()
```

Update `_on_sidebar_closed()` to use local `is_paused`:

```gdscript
func _on_sidebar_closed() -> void:
	if not is_paused:
		drop_timer.paused = false
```

**Step 5: Remove old pause button references**

Search LoomDrop.gd for `top_nav_bar.is_paused` and replace with `is_paused`.

Search for `top_nav_bar.set_paused` and remove those calls.

**Step 6: Test pause button**

Run: Press F5
Expected:
- Bottom bar has 4 buttons (Shake, Swap, Draw More, Pause)
- All buttons fit properly (135px each)
- Click Pause → game pauses, button shows "▶ Resume (Free)"
- Click Resume → game resumes, button shows "⏸ Pause (Free)"
- Pause doesn't cost points

**Step 7: Commit**

```bash
git add godot/scenes/TopNavBar.tscn godot/scripts/TopNavBar.gd godot/scenes/LoomDrop.tscn godot/scripts/LoomDrop.gd
git commit -m "feat: move Pause button to bottom action bar

Pause is now a 'free action' alongside power-ups. Removed from
TopNavBar, added to bottom bar. Button widths adjusted to 135px.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Handle Pause State During Word Score Display

**Files:**
- Modify: `godot/scripts/TopNavBar.gd` (pause word_score_timer when game paused)

**Step 1: Add method to handle pause state**

```gdscript
func set_game_paused(paused: bool) -> void:
	if paused and is_showing_word_score:
		word_score_timer.paused = true
	elif not paused and is_showing_word_score:
		word_score_timer.paused = false
```

**Step 2: Call from LoomDrop pause handler**

In `godot/scripts/LoomDrop.gd`, update `_on_pause_pressed()`:

```gdscript
func _on_pause_pressed() -> void:
	is_paused = !is_paused
	pause_button.text = "▶ Resume\n(Free)" if is_paused else "⏸ Pause\n(Free)"

	if is_paused:
		drop_timer.paused = true
		word_label.text = lang_config.ui_strings.get("paused", "Game Paused")
		top_nav_bar.set_game_paused(true)  # Add this line
	else:
		drop_timer.paused = false
		word_label.text = ""
		top_nav_bar.set_game_paused(false)  # Add this line

	_update_button_states()
```

**Step 3: Test pause during word score**

Run: Press F5
Expected:
- Score a word → word score appears
- Quickly press Pause (within 2 seconds)
- Word score display freezes (doesn't swap back to timer)
- Press Resume → word score timer continues, swaps back after remaining time

**Step 4: Commit**

```bash
git add godot/scripts/TopNavBar.gd godot/scripts/LoomDrop.gd
git commit -m "feat: pause word score display timer when game paused

If game is paused during word score display, the 2-second timer
also pauses to prevent premature swap back to countdown.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Add Theme Support to New Components

**Files:**
- Modify: `godot/scripts/TopNavBar.gd` (theme CenterDisplay labels)
- Already done: `godot/scripts/GameSidebar.gd` (has _apply_theme)

**Step 1: Update TopNavBar _apply_theme for CenterDisplay**

In `_apply_theme()`, add after existing label theming:

```gdscript
# Update timer and word score labels
if timer_label:
	timer_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

if word_score_label:
	# Word score gets accent color
	word_score_label.add_theme_color_override("font_color", ThemeManager.get_color("primary_button"))
```

**Step 2: Test theme switching**

Run: Press F5
Expected:
- Light mode: All UI elements use light theme colors
- Settings → Switch to Dark mode
- Return to game → All UI updates to dark theme
- Timer label, word score label, sidebar, buttons all themed correctly

**Step 3: Commit**

```bash
git add godot/scripts/TopNavBar.gd
git commit -m "feat: add theme support for countdown timer displays

Timer and word score labels now respond to theme changes. Timer
uses text_primary, word score uses primary_button accent color.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Final Testing and Polish

**Files:**
- Test all components together
- Fix any edge cases discovered
- Update game rules documentation

**Step 1: Run full testing checklist**

Reference design doc testing section. Test:

**Countdown Timer:**
- ✓ Timer counts down accurately
- ✓ Shows whole seconds only
- ✓ Pauses when game paused
- ✓ Reflects speed changes (ratchet)

**Word Score Display:**
- ✓ 3-letter → NICE! gentle bounce
- ✓ 4-letter → GREAT! bigger animation
- ✓ 5+ letter → AMAZING/FANTASTIC/SPECTACULAR! celebration
- ✓ 2-second display duration
- ✓ Multiple words update display (don't stack)
- ✓ Pauses if game paused

**Sidebar:**
- ✓ Burger menu opens/closes smoothly
- ✓ Game pauses when open
- ✓ Navigation works
- ✓ Both themes work

**Bottom Action Bar:**
- ✓ 4 buttons fit properly
- ✓ Pause toggles correctly
- ✓ All buttons accessible

**Edge Cases:**
- ✓ Timer during word score display
- ✓ Rapid burger toggling
- ✓ Score overflow handling

**Step 2: Fix any bugs found**

Document and fix any issues discovered during testing.

**Step 3: Update documentation**

If game rules mention UI layout, update `docs/game-rules.md` to reflect:
- Countdown timer in top bar
- Pause as a free action in bottom bar
- Burger menu for navigation

**Step 4: Final commit**

```bash
git add -A
git commit -m "test: verify countdown timer and sidebar feature

Completed full testing checklist. All features working as designed:
- Countdown timer displays and updates correctly
- Word score animations work for all tiers
- Sidebar navigation functional
- Pause moved to bottom bar as free action
- Theme support complete

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Step 5: Create PR or merge**

```bash
# If on feature branch:
git push -u origin HEAD

# Create PR with summary of changes
# OR merge to main if working directly:
git checkout main
git merge <feature-branch>
git push
```

---

## Success Criteria

✅ Countdown timer displays in top bar center, updates every second
✅ Timer swaps to word score display for 2 seconds after each word
✅ Word score shows points + encouraging phrase with animation
✅ Different animations for 3/4/5+ letter words
✅ Burger menu button opens sidebar with slide animation
✅ Sidebar contains Settings, Stats, Rules, Help navigation
✅ Game pauses when sidebar open
✅ Pause button in bottom action bar as "free action"
✅ All components support light/dark themes
✅ No visual glitches or layout issues

---

## Notes for Implementation

**Godot Scene Editing:**
- Most UI changes require opening .tscn files in Godot editor
- Use "Unique Name in Owner" (%) for easy node access in scripts
- Scene tree saves to .tscn text format (git-friendly)

**Testing in Godot:**
- Press F5 to run main scene (LoomDrop)
- Press F6 to run current scene (useful for isolated component testing)
- Use print() statements for debugging

**Signal Connections:**
- Prefer code-based connections over editor connections
- Makes signal flow easier to trace and review

**Tween Animations:**
- Use `create_tween()` for smooth animations
- Chain tweens with `tween_property()` calls
- Use `parallel()` for simultaneous animations

**Theme System:**
- All new components must implement `_apply_theme()`
- Connect to `ThemeManager.theme_changed` signal
- Use `ThemeManager.get_color()` for color values
