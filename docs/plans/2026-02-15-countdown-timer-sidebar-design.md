# Countdown Timer & Sidebar Menu Design

**Date:** 2026-02-15
**Status:** Approved
**Goal:** Add countdown timer to show time until next letter drop, reorganize top bar with burger menu sidebar, move pause to bottom action bar

---

## Overview

Add a countdown timer that shows how long until the next letter drops, displayed prominently in the center of the top bar. When a word is scored, the timer temporarily swaps with an animated word score display ("+150 GREAT!") for 2 seconds. Reorganize UI to reduce top bar crowding by adding a burger menu sidebar for Settings/Stats/Rules/Help, and move Pause button to the bottom action bar as a "free action."

---

## Architecture

### Component Structure

```
LoomDrop (main game scene)
├── TopNavBar
│   ├── BurgerMenuButton (new)
│   ├── ExitButton (existing)
│   ├── CenterDisplay (new - timer/word score swap)
│   └── ScoreContainer (existing - score + high score)
├── GameSidebar (new component)
│   ├── Settings button
│   ├── Stats button
│   ├── Game Rules button
│   └── Help button
└── BottomActionBar
    ├── ShakeButton (existing)
    ├── SwapButton (existing)
    ├── DrawMoreButton (existing)
    └── PauseButton (moved from TopNavBar)
```

### Signal Flow

1. **Timer countdown:** LoomDrop's `drop_timer` ticks → TopNavBar updates countdown display each second
2. **Word scored:** LoomDrop emits `word_scored(points: int, word_length: int)` → TopNavBar swaps to word score display → waits 2s → swaps back to timer
3. **Sidebar toggle:** BurgerMenuButton pressed → GameSidebar slides in/out
4. **Navigation:** GameSidebar button pressed → navigates to respective scene (Settings, Stats, etc.)

### Key Design Decisions

- TopNavBar tracks `drop_timer.time_left` to display countdown (doesn't own the timer)
- Word score phrases calculated in TopNavBar based on word length thresholds
- Sidebar overlays the game (semi-transparent backdrop), pauses game while open
- Pause button treats pause as a "free action" alongside power-ups

---

## Component Details

### TopNavBar.tscn/gd Changes

**Layout:**
```
HBoxContainer (TopNavBar)
├── BurgerMenuButton (new Button, ~60×60px, hamburger icon ☰)
├── ExitButton (existing, stays)
├── CenterDisplay (new VBoxContainer, flex grow)
│   ├── TimerLabel (shows "3s", "2s", etc.)
│   └── WordScoreLabel (shows "+150 GREAT!", hidden by default)
├── Spacer (Control with size_flags_horizontal = 3)
└── ScoreContainer (existing, stays)
```

**New Properties:**
- `drop_timer_ref: Timer` - reference to LoomDrop's timer for countdown
- `is_showing_word_score: bool` - tracks display state
- `word_score_timer: Timer` - 2-second timer for score display

**New Methods:**
- `set_drop_timer(timer: Timer)` - called by LoomDrop during setup
- `show_word_score(points: int, word_length: int)` - swaps display, starts 2s timer
- `_update_timer_display()` - updates countdown text every frame
- `_calculate_phrase(word_length: int) -> String` - returns "NICE!", "GREAT!", etc.

**New Signal to Connect:**
- Connect to LoomDrop's `word_scored(points, word_length)` signal

---

### GameSidebar.tscn/gd (New Component)

**Layout:**
```
Panel (GameSidebar)
├── VBoxContainer
│   ├── CloseButton (X button, top-right)
│   ├── SettingsButton (→ Settings.tscn)
│   ├── StatsButton (→ Stats.tscn)
│   ├── RulesButton (→ new GameRules.tscn)
│   └── HelpButton (→ new Help.tscn)
└── BackgroundOverlay (ColorRect, semi-transparent black)
```

**Properties:**
- `is_open: bool`

**Signals:**
- `sidebar_opened`
- `sidebar_closed`

**Methods:**
- `toggle()` - slides in/out from left
- `open()` / `close()` - explicit control
- Navigation buttons use `get_tree().change_scene_to_file()`

**Dimensions:**
- Width: 300px
- Overlays left side of screen
- Background overlay: semi-transparent black (alpha 0.5)

---

### Bottom Action Bar Changes

Add PauseButton after DrawMoreButton with same styling as other power-up buttons. Update button layout to accommodate 4 buttons (reduce button width from 150px to ~135px to fit).

---

## Timer and Display Logic

### Countdown Timer Implementation

TopNavBar's `_process(delta)` checks `drop_timer_ref.time_left` and updates display:

```gdscript
func _process(_delta: float) -> void:
    if not is_showing_word_score and drop_timer_ref and not drop_timer_ref.is_stopped():
        var time_left := ceili(drop_timer_ref.time_left)
        timer_label.text = "%ds" % time_left
```

**Why `_process` instead of signals:**
- Timer countdown is continuous, not event-based
- Smoother updates (every frame vs every signal emit)
- Simple: just read `time_left` property

---

### Word Score Display Flow

1. LoomDrop scores a word → emits `word_scored(points, word_length)`
2. TopNavBar receives signal:
   ```gdscript
   func show_word_score(points: int, word_length: int) -> void:
       is_showing_word_score = true
       timer_label.visible = false

       var phrase := _calculate_phrase(word_length)
       word_score_label.text = "+%d %s" % [points, phrase]
       word_score_label.visible = true

       _animate_word_score(word_length)

       word_score_timer.start(2.0)  # Show for 2 seconds
   ```

3. After 2 seconds:
   ```gdscript
   func _on_word_score_timeout() -> void:
       is_showing_word_score = false
       word_score_label.visible = false
       timer_label.visible = true
   ```

---

### Phrase Calculation Logic

```gdscript
func _calculate_phrase(word_length: int) -> String:
    match word_length:
        3: return "NICE!"
        4: return "GREAT!"
        5: return "AMAZING!"
        6: return "FANTASTIC!"
        _: return "SPECTACULAR!"  # 7+ letters
```

**Design Rationale:**
- Phrase based on word length reinforces "longer words = better"
- Simple, encouraging language for senior-first design
- Clear progression of excitement

---

### Edge Case Handling

- **Multiple words scored quickly:** Reset timer and update with new score (don't stack)
- **Pause during word score display:** Pause the 2-second timer too
- **Timer reaches 0 during display:** Still swap back after 2 seconds (timer takes priority)

---

## Animations and Theming

### Word Score Celebration Animations

Different animation intensity based on word length:

**3-letter (NICE!) - Gentle bounce:**
```gdscript
tween.tween_property(word_score_label, "scale", Vector2(1.2, 1.2), 0.2)
tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.2)
```

**4-letter (GREAT!) - Bigger bounce with rotation:**
```gdscript
tween.tween_property(word_score_label, "scale", Vector2(1.4, 1.4), 0.2)
tween.tween_property(word_score_label, "rotation_degrees", 5, 0.1)
tween.tween_property(word_score_label, "rotation_degrees", -5, 0.1)
tween.tween_property(word_score_label, "rotation_degrees", 0, 0.1)
tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.2)
```

**5+ letter (AMAZING!/FANTASTIC!/SPECTACULAR!) - Big celebration:**
```gdscript
tween.tween_property(word_score_label, "scale", Vector2(1.6, 1.6), 0.3)
tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.5)
```

Font sizes also scale with importance:
- 3-letter = 32px
- 4-letter = 36px
- 5+ = 42px

---

### Sidebar Slide Animation

**Open:**
```gdscript
func open() -> void:
    visible = true
    var tween := create_tween()
    position.x = -300  # Start off-screen left
    tween.tween_property(self, "position:x", 0, 0.3).set_ease(Tween.EASE_OUT)
    background_overlay.modulate.a = 0
    tween.parallel().tween_property(background_overlay, "modulate:a", 0.5, 0.3)
    sidebar_opened.emit()
```

**Close:**
```gdscript
func close() -> void:
    var tween := create_tween()
    tween.tween_property(self, "position:x", -300, 0.3).set_ease(Tween.EASE_IN)
    tween.parallel().tween_property(background_overlay, "modulate:a", 0, 0.3)
    tween.tween_callback(func(): visible = false)
    sidebar_closed.emit()
```

---

### Theme Integration

All new components follow existing theme system via `ThemeManager`:

- **BurgerMenuButton:** Uses `secondary_button` colors, white hamburger icon (☰)
- **CenterDisplay labels:** `text_primary` for timer, gradient color for word score (based on phrase tier)
- **GameSidebar:** Panel uses `background_primary` with slight transparency, buttons use `secondary_button`
- **PauseButton:** Matches existing power-up button style

Each component implements `_apply_theme()` and connects to `ThemeManager.theme_changed`.

---

## Testing Strategy

### Manual Testing Checklist

**Countdown Timer:**
- [ ] Timer counts down accurately (matches drop_timer)
- [ ] Timer displays whole seconds only (3s, 2s, 1s)
- [ ] Timer updates smoothly without flickering
- [ ] Timer pauses when game is paused
- [ ] Timer resumes when game unpauses
- [ ] Timer reflects speed changes (ratchet up, reset on 5+ letter words)

**Word Score Display:**
- [ ] Scoring 3-letter word shows "+X NICE!" with gentle bounce
- [ ] Scoring 4-letter word shows "+X GREAT!" with bigger animation
- [ ] Scoring 5+ letter word shows "+X AMAZING/FANTASTIC/SPECTACULAR!" with celebration
- [ ] Display shows for exactly 2 seconds then swaps back to timer
- [ ] Scoring multiple words quickly updates display (doesn't stack)
- [ ] Word score display pauses if game paused during 2-second window

**Sidebar:**
- [ ] Burger menu button opens sidebar with smooth slide animation
- [ ] Sidebar overlays game with semi-transparent backdrop
- [ ] Game pauses when sidebar is open
- [ ] Close button (X) closes sidebar
- [ ] Settings/Stats/Rules/Help buttons navigate to correct scenes
- [ ] Sidebar works in both light and dark themes

**Bottom Action Bar:**
- [ ] Four buttons (Shake, Swap, Draw More, Pause) fit properly
- [ ] Pause button toggles correctly
- [ ] Pause button styling matches other action buttons
- [ ] All buttons still accessible on small screens

**Theme Compatibility:**
- [ ] All new components render correctly in light mode
- [ ] All new components render correctly in dark mode
- [ ] Theme switching updates all new components dynamically

**Edge Cases:**
- [ ] Timer behavior when drop happens during word score display
- [ ] Sidebar navigation doesn't crash game
- [ ] Rapid burger menu toggling doesn't break animation
- [ ] Very long scores don't overflow display area

---

## Future Enhancements

- Sound effects for word score animations (different sounds for different tiers)
- Particle effects for 5+ letter words
- Combo multiplier indicator in word score display
- Accessibility: voice announcements for timer and scores
