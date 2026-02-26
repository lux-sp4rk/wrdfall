# Design: Web Navigation & PCK Reminder

**Date:** 2026-02-26
**Branch:** feature/invisible-loader-143
**Issue:** Web builds show Godot Home/Stats/Settings scenes; PCK rebuild footgun causes repeated confusion

---

## Problem

On web, the React shell owns Home, Stats, and Settings. Godot should only show the game (LoomDrop). Three issues:

1. **LoomDrop exit/quit** navigates to Godot's `Home.tscn` on web — GDScript fix exists in `dcf68a1` but PCK hasn't been rebuilt yet
2. **GameSidebar** (burger menu during gameplay) has Settings and Stats buttons that unconditionally navigate to Godot's `Settings.tscn` / `Stats.tscn` on web
3. **PCK footgun** — GDScript changes don't take effect on web until Godot re-exports `dist/index.pck`; this is repeatedly forgotten

---

## Design

### 1. Hide Settings/Stats in GameSidebar on web

In `GameSidebar.gd` `_ready()`, add a web check:

```gdscript
if OS.has_feature("web"):
    settings_button.hide()
    stats_button.hide()
```

On web, users access Stats and Settings from the React home screen. No Godot scene navigation needed from the sidebar.

Desktop builds are unaffected.

### 2. Rebuild PCK

Export from Godot headless to regenerate `dist/index.pck` with all accumulated GDScript fixes:
- `LoomDrop.gd`: exit/quit → `window.wordLoomGoHome()` on web
- `Settings.gd`: back → `window.wordLoomGoHome()` on web
- `Stats.gd`: back → `window.wordLoomGoHome()` on web
- `GameSidebar.gd`: hide Settings/Stats on web (new)

### 3. PCK reminder — AGENTS.md callout

Add a prominent callout to `AGENTS.md` in the Web Deployment Architecture section:

```
> ⚠️ PCK FOOTGUN: Editing any `.gd` file requires a Godot re-export to
> regenerate `dist/index.pck`. React/JS-only changes (landing/) do NOT
> require a PCK rebuild. GDScript changes are invisible on web until the
> PCK is rebuilt and committed.
```

### 4. PCK reminder — Hookify rule

Add a PostToolUse hookify rule that fires when Claude edits a `.gd` file and appends:

> "⚠️ GDScript changed — remember to re-export the PCK from Godot before testing on web."

This is automatic — no manual memory required.

---

## Files Changed

| File | Change |
|---|---|
| `godot/scripts/GameSidebar.gd` | Hide settings/stats buttons on web in `_ready()` |
| `dist/index.pck` | Re-export from Godot headless |
| `AGENTS.md` | Add PCK footgun callout |
| hookify config | Add PostToolUse `.gd` reminder rule |

---

## Out of Scope

- Moving Stats/Settings content into the React shell (existing React screens already handle this)
- In-game overlay for Stats/Settings (YAGNI — user accesses these after exiting)
- Rules/Help sidebar buttons (already no-ops with TODO comments)
