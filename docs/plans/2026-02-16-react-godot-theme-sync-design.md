# React-Godot Theme Sync Design

**Date:** 2026-02-16
**Status:** Approved
**Goal:** Sync theme preference between React landing page and Godot game for seamless visual transition

---

## Problem Statement

The React landing page currently has hardcoded light theme styling that doesn't match the Godot game's theme system. When users have dark mode enabled in Godot, there's a jarring visual transition from the light-themed React loader to the dark-themed game.

**Current Issues:**
- React only supports light theme (hardcoded colors)
- No sync between React and Godot theme preferences
- Visual flash during transition if user prefers dark mode
- React colors don't exactly match Godot's theme palette

---

## Requirements

1. **Read-only React**: Landing page reads saved theme preference, no theme toggle UI (user changes theme in Godot Settings)
2. **Storage sync**: localStorage (React/web) synced with ConfigFile (Godot)
3. **Default behavior**: Detect OS dark mode preference on first visit
4. **Immediate application**: React applies theme on load, Godot inherits (no flash)

---

## Architecture Overview

### Approach: localStorage as Web Source of Truth

**High-level flow:**

1. **First Visit (no saved theme)**
   - React detects OS dark mode preference via `window.matchMedia('(prefers-color-scheme: dark)')`
   - Writes default theme to `localStorage.setItem('wordfall-theme', 'light' or 'dark')`
   - Applies theme to React UI immediately

2. **Subsequent Visits**
   - React reads `localStorage.getItem('wordfall-theme')`
   - Applies theme immediately (no flash)
   - Godot launches, reads same localStorage value

3. **Theme Changes in Godot**
   - User changes theme in Settings.tscn
   - ThemeManager updates `GameSettings.theme` and emits `theme_changed`
   - ThemeManager writes to localStorage (web only via JavaScriptBridge)
   - ConfigFile save still happens (desktop + web)

**Storage Strategy:**
- **Web builds**: localStorage is primary, ConfigFile is backup
- **Desktop builds**: ConfigFile only (localStorage not used)
- **Sync point**: Godot ThemeManager writes to both on web

---

## Component Changes

### Files to Modify

**React (3 files):**

1. **`landing/src/services/theme.js`** (NEW)
   - Detects OS dark mode preference
   - Reads/writes localStorage
   - Returns current theme ('light' or 'dark')
   - Exports: `getTheme()`, `detectSystemTheme()`

2. **`landing/src/App.jsx`**
   - Import theme service
   - Call `getTheme()` on mount
   - Store theme in state
   - Apply theme class to landing container (`className="landing-container theme-light"` or `theme-dark"`)

3. **`landing/src/App.css`**
   - Add dark theme color overrides
   - Use CSS class selectors (`.theme-dark .landing-container { background: ... }`)
   - Mirror Godot's exact dark theme colors

**Godot (1 file):**

4. **`godot/scripts/ThemeManager.gd`**
   - Add `_sync_to_localstorage()` function (web only, uses JavaScriptBridge)
   - Call in `set_theme()` after ConfigFile save
   - Add `_load_from_localstorage()` function for web startup
   - Call in `_ready()` before loading ConfigFile

**No changes needed:**
- GameSettings.gd (already stores theme)
- Settings.tscn (theme toggle already works)
- Other React services

---

## Data Flow

### Scenario 1: First Visit (No Saved Theme)

```
User opens app
  ↓
React mounts
  ↓
theme.js checks localStorage.getItem('wordfall-theme')
  ↓
Not found → detectSystemTheme()
  ↓
window.matchMedia('(prefers-color-scheme: dark)').matches
  ↓
Set theme = 'dark' (or 'light')
  ↓
localStorage.setItem('wordfall-theme', theme)
  ↓
Apply CSS class to React (.theme-dark)
  ↓
User clicks Play
  ↓
Godot launches → ThemeManager._ready()
  ↓
Web: Read localStorage first, fallback to ConfigFile
Desktop: Read ConfigFile only
  ↓
Apply theme in Godot
```

### Scenario 2: Returning User

```
React mounts
  ↓
localStorage.getItem('wordfall-theme') → 'dark'
  ↓
Apply .theme-dark immediately (no flash)
  ↓
Godot launches
  ↓
Reads same localStorage value
  ↓
Theme matches perfectly (seamless transition)
```

### Scenario 3: User Changes Theme in Godot Settings

```
User changes theme in Settings.tscn
  ↓
ThemeManager.set_theme('light')
  ↓
GameSettings.theme = 'light'
  ↓
ConfigFile.save('user://settings.cfg')
  ↓
Web only: Access localStorage via JavaScriptBridge and set theme
  ↓
theme_changed signal emitted
  ↓
Next visit: React reads updated localStorage value
```

---

## Color Mapping

### Exact colors from Godot ThemeManager to React CSS

**Light Theme:**
```css
.theme-light {
  --bg-primary: #F5F2E8;        /* Godot: background (0.96, 0.95, 0.91) */
  --bg-card: #FFFFFF;           /* Godot: card_background */
  --color-primary: #E07857;     /* Godot: primary_button (0.88, 0.47, 0.34) */
  --color-primary-hover: #EB8563; /* Godot: primary_button_hover */
  --color-secondary: #7A9D8C;   /* Godot: secondary_button (0.48, 0.61, 0.55) */
  --text-primary: #1F1F1F;      /* Godot: text_primary (0.12, 0.12, 0.12) */
  --text-secondary: #4D6659;    /* Godot: text_secondary (0.30, 0.40, 0.35) */
  --shadow: rgba(0, 0, 0, 0.12); /* Godot: shadow */
}
```

**Dark Theme:**
```css
.theme-dark {
  --bg-primary: #2B3D4F;        /* Godot: background (0.17, 0.24, 0.31) */
  --bg-card: #364A5E;           /* Godot: card_background (0.21, 0.29, 0.37) */
  --color-primary: #F29170;     /* Godot: primary_button (0.95, 0.57, 0.44) */
  --color-primary-hover: #FA9E7D; /* Godot: primary_button_hover */
  --color-secondary: #4D6B8A;   /* Godot: secondary_button (0.30, 0.42, 0.54) */
  --text-primary: #F2F2F2;      /* Godot: text_primary (0.95, 0.95, 0.95) */
  --text-secondary: #99BFB3;    /* Godot: text_secondary (0.60, 0.75, 0.70) */
  --shadow: rgba(0, 0, 0, 0.3); /* Godot: shadow */
}
```

**CSS Changes:**
- Replace hardcoded colors with CSS variables (`background: var(--bg-primary)`)
- Remove current gradient (replace with solid `--bg-primary`)
- Update terracotta `#a0522d` → `--color-primary` to match Godot exactly

---

## Error Handling & Edge Cases

### Edge Cases

1. **localStorage not available** (private browsing, disabled)
   - React: Catch errors, fall back to 'light' theme
   - Godot: Already has ConfigFile fallback

2. **Invalid theme value in localStorage** (corrupted data)
   - Validate: `if (theme !== 'light' && theme !== 'dark') theme = 'light'`
   - Overwrite with valid default

3. **OS preference detection fails**
   - `window.matchMedia` not supported (old browsers)
   - Default to 'light' theme

4. **JavaScriptBridge fails on web** (shouldn't happen)
   - Godot falls back to ConfigFile
   - No localStorage sync, but theme still works

### Fallback Chain

```
localStorage → OS preference → 'light' (hardcoded default)
```

### Error Logging

- React: `console.warn()` for localStorage errors (non-blocking)
- Godot: `push_warning()` for JavaScriptBridge errors (already exists)

---

## Testing Strategy

### Manual Testing Scenarios

**1. First Visit (Light Mode System)**
- Clear localStorage and browser data
- OS dark mode OFF
- Open app → verify React shows light theme immediately
- Click Play → verify Godot continues with light theme (no flash)
- Check localStorage: `wordfall-theme` = 'light'

**2. First Visit (Dark Mode System)**
- Clear localStorage
- OS dark mode ON
- Open app → verify React shows dark theme immediately
- Click Play → verify Godot continues with dark theme
- Check localStorage: `wordfall-theme` = 'dark'

**3. Theme Change in Godot**
- Start with light theme
- Play game → Settings → change to dark theme
- Exit to main menu, restart
- Verify React landing page now shows dark theme

**4. Desktop Build (ConfigFile only)**
- Export desktop build
- Verify theme saves to `user://settings.cfg`
- Verify no localStorage errors in console
- Theme persists across restarts

### Visual Checklist

- ✅ Background color matches Godot exactly
- ✅ Button colors match (primary terracotta)
- ✅ Text contrast is readable
- ✅ No color flash during React → Godot transition
- ✅ Progress bar color matches theme

---

## Implementation Notes

- Colors can be adjusted post-implementation if needed
- localStorage key: `'wordfall-theme'` (keep consistent)
- Theme values: `'light'` or `'dark'` (lowercase, no other values)
- JavaScriptBridge: Use `JavaScriptBridge.get_interface("localStorage")` to safely access localStorage (follows pattern from Dictionary.gd)

---

## Next Steps

1. Create implementation plan using writing-plans skill
2. Implement in feature branch (`feat/react-godot-theme-sync`)
3. Test all scenarios (manual + visual checklist)
4. Merge to main after verification
