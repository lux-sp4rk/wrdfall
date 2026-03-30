# Web Navigation & PCK Reminder Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** On web, hide Godot's Settings/Stats from the in-game sidebar, rebuild the PCK with accumulated routing fixes, and add a durable PCK-rebuild reminder so the footgun doesn't recur.

**Architecture:** Three independent changes — one GDScript edit, one AGENTS.md edit, one new hookify rule file — followed by a manual Godot headless export to bake everything into the PCK.

**Tech Stack:** GDScript (Godot 4.3), hookify plugin, Godot headless CLI at `/home/uli/bin/godot`

---

## Context (read before starting)

The current `dist/index.pck` was built from commit `94170e2`. Since then, `dcf68a1` added web-aware routing to `LoomDrop.gd`, `Settings.gd`, and `Stats.gd` — but the PCK was never rebuilt. Those fixes are live in GDScript but invisible on web until the PCK is re-exported.

**The PCK footgun:** GDScript changes require a Godot headless re-export to take effect on web. React/JS changes in `landing/` do NOT need this. When in doubt: did you touch any `.gd` file? Then rebuild the PCK.

---

## Task 1: Hide Settings/Stats in GameSidebar on web

**Files:**
- Modify: `godot/scripts/GameSidebar.gd` (in `_ready()` function, around line 21)

**Step 1: Add web check to `_ready()`**

In `godot/scripts/GameSidebar.gd`, find the end of `_ready()` (after the `background_overlay.mouse_filter` line) and add:

```gdscript
# On web, React shell owns Stats and Settings navigation
if OS.has_feature("web"):
    settings_button.hide()
    stats_button.hide()
```

The full `_ready()` should end like:

```gdscript
func _ready() -> void:
    # Initial position (off-screen left)
    position.x = -300

    # Connect theme system
    ThemeManager.theme_changed.connect(_apply_theme)
    _apply_theme()

    # Connect button signals
    close_button.pressed.connect(_on_close_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    stats_button.pressed.connect(_on_stats_pressed)
    rules_button.pressed.connect(_on_rules_pressed)
    help_button.pressed.connect(_on_help_pressed)

    # Connect overlay click to close
    background_overlay.gui_input.connect(_on_overlay_input)

    # Initially hide overlay (both visually and for input)
    background_overlay.modulate.a = 0.0
    background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # On web, React shell owns Stats and Settings navigation
    if OS.has_feature("web"):
        settings_button.hide()
        stats_button.hide()
```

**Step 2: Verify in Godot editor (optional but fast)**

Open `godot/project.godot` in Godot, press F5. The sidebar should still show Settings and Stats (desktop build). No desktop regression.

**Step 3: Commit this change alone**

```bash
git add godot/scripts/GameSidebar.gd
git commit -m "fix: hide Settings/Stats sidebar buttons on web (React shell owns nav)"
```

---

## Task 2: Update AGENTS.md with PCK footgun callout

**Files:**
- Modify: `AGENTS.md` (Web Deployment Architecture section, around line 94)

**Step 1: Replace the existing "Manual Export" bullet**

Find this text in `AGENTS.md`:
```
- **Manual Export**: After making changes in `godot/`, you must manually export to `dist/` from the Godot Editor before pushing to trigger a Netlify update.
```

Replace with:

```markdown
- **Manual Export**: After making changes in `godot/`, you must manually export to `dist/` from the Godot Editor before pushing to trigger a Netlify update.

> **⚠️ PCK FOOTGUN — Easy to forget, painful to debug:**
> Editing ANY `.gd` file requires a Godot re-export to regenerate `dist/index.pck`.
> React/JS-only changes in `landing/` do NOT require a PCK rebuild.
> GDScript changes are completely invisible on web until the PCK is rebuilt and committed.
> **Command:** `cd godot && /home/uli/bin/godot --headless --export-release "Web" ../dist/index.html`
```

**Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add prominent PCK footgun warning to AGENTS.md"
```

---

## Task 3: Add hookify PCK reminder rule

**Files:**
- Create: `.claude/hookify.godot-pck-reminder.local.md`

**Step 1: Create the rule file**

```markdown
---
name: godot-pck-reminder
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.gd$
---

⚠️ **GDScript changed — PCK rebuild required for web!**

You just edited a `.gd` file. This change is **not live on web** until you re-export the PCK from Godot.

**To rebuild:**
```
cd godot && /home/uli/bin/godot --headless --export-release "Web" ../dist/index.html
```

React/JS changes in `landing/` do NOT need a PCK rebuild — only GDScript changes do.
```

**Step 2: Verify rule syntax is valid**

```bash
python3 -c "
import re
pattern = r'\.gd$'
test = 'godot/scripts/GameSidebar.gd'
print('Match:', bool(re.search(pattern, test)))
"
```

Expected output: `Match: True`

**Step 3: Commit**

```bash
git add .claude/hookify.godot-pck-reminder.local.md
git commit -m "feat: add hookify rule to remind about PCK rebuild after .gd edits"
```

---

## Task 4: Rebuild the PCK

This bakes all accumulated GDScript fixes into `dist/index.pck`:
- `LoomDrop.gd`: exit/quit → `window.wordfallGoHome()` on web (from `dcf68a1`)
- `Settings.gd`: back → `window.wordfallGoHome()` on web (from `dcf68a1`)
- `Stats.gd`: back → `window.wordfallGoHome()` on web (from `dcf68a1`)
- `GameSidebar.gd`: hide Settings/Stats buttons on web (Task 1 above)

**Step 1: Export from Godot headless**

```bash
cd /home/uli/Projects/word-loom/godot && /home/uli/bin/godot --headless --export-release "Web" ../dist/index.html 2>&1
```

Expected output ends with something like:
```
  Exporting project...
  PCK export successful!
```

The command exits 0. If it errors, check that `export_presets.cfg` has the "Web" preset (it does — added in `94170e2`).

**Step 2: Verify PCK was updated**

```bash
ls -lh /home/uli/Projects/word-loom/dist/index.pck
```

The timestamp should be recent (just now).

**Step 3: Verify file size is reasonable**

```bash
stat -c%s /home/uli/Projects/word-loom/dist/index.pck
```

Expected: ~50–60 MB (not a tiny LFS pointer file).

**Step 4: Quick local test**

```bash
cd /home/uli/Projects/word-loom && python3 -m http.server -d dist/ 8000
```

Open http://localhost:8000 in browser:
- Click Play → game loads directly (no Godot home screen)
- Open burger menu → Settings and Stats buttons are NOT visible
- Click Exit → React home screen reappears (no Godot home screen)
- At game over → click Quit → React home screen reappears

Stop server with Ctrl+C.

**Step 5: Commit the new PCK**

```bash
cd /home/uli/Projects/word-loom
git add dist/index.pck dist/index.html dist/index.js dist/index.wasm
git commit -m "build: rebuild PCK — web nav routing + hide sidebar Settings/Stats on web"
```

---

## Task 5: Final verification

**Step 1: Check all changed files are committed**

```bash
git status
```

Expected: clean working tree.

**Step 2: Confirm commit history looks right**

```bash
git log --oneline -6
```

Should show the 4 new commits from Tasks 1–4.

**Step 3: Push**

```bash
git push
```

---

## Testing Checklist

| Scenario | Expected |
|---|---|
| Web: click Play | Game starts directly (no Godot home) |
| Web: open burger menu | Settings and Stats buttons hidden |
| Web: click Exit during game | React home screen appears |
| Web: game over → Quit | React home screen appears |
| Desktop: open burger menu | Settings and Stats buttons visible |
| Desktop: click Exit | Godot Home.tscn loads |
| Desktop: F5 from editor | Home.tscn loads normally |

---

## What Was Already Correct (no changes needed)

- `Boot.gd`: already routes web → LoomDrop.tscn (skips Godot home on startup)
- `LoomDrop.gd`: exit/quit already call `window.wordfallGoHome()` on web (`dcf68a1`)
- `Settings.gd`: back already calls `window.wordfallGoHome()` on web (`dcf68a1`)
- `Stats.gd`: back already calls `window.wordfallGoHome()` on web (`dcf68a1`)
- `App.jsx`: `window.wordfallGoHome` callback already registered
