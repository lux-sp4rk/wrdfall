# React-Godot Theme Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Sync theme preference between React landing page and Godot game for seamless visual transition without color flash.

**Architecture:** React reads theme from localStorage (with OS preference detection on first visit), applies via CSS classes. Godot's ThemeManager syncs theme to localStorage on web builds using JavaScriptBridge. Both use same localStorage key for consistency.

**Tech Stack:** React (Vite), CSS custom properties, Godot 4.6 (GDScript), JavaScriptBridge, localStorage

---

## Task 1: Create React Theme Service

**Files:**
- Create: `landing/src/services/theme.js`

**Step 1: Create theme service with OS detection**

```javascript
/**
 * ThemeService - Detect and manage theme preference
 *
 * Strategy:
 * - First visit: Detect OS dark mode preference
 * - Subsequent visits: Read from localStorage
 * - Sync with Godot via shared localStorage key
 */

const THEME_KEY = 'wordfall-theme';
const THEME_LIGHT = 'light';
const THEME_DARK = 'dark';

/**
 * Detect system dark mode preference
 */
export function detectSystemTheme() {
  try {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return THEME_DARK;
    }
  } catch (error) {
    console.warn('Failed to detect system theme:', error);
  }
  return THEME_LIGHT;
}

/**
 * Get current theme (reads localStorage, falls back to OS preference)
 */
export function getTheme() {
  try {
    // Try localStorage first
    const savedTheme = localStorage.getItem(THEME_KEY);

    // Validate saved theme
    if (savedTheme === THEME_LIGHT || savedTheme === THEME_DARK) {
      return savedTheme;
    }

    // First visit: detect OS preference and save
    const systemTheme = detectSystemTheme();
    localStorage.setItem(THEME_KEY, systemTheme);
    return systemTheme;
  } catch (error) {
    // localStorage not available (private browsing)
    console.warn('localStorage not available, using system theme:', error);
    return detectSystemTheme();
  }
}

/**
 * Set theme (for future use if React needs to change theme)
 */
export function setTheme(theme) {
  if (theme !== THEME_LIGHT && theme !== THEME_DARK) {
    console.warn(`Invalid theme: ${theme}, defaulting to light`);
    theme = THEME_LIGHT;
  }

  try {
    localStorage.setItem(THEME_KEY, theme);
  } catch (error) {
    console.warn('Failed to save theme to localStorage:', error);
  }
}
```

**Step 2: Verify theme service logic**

Manual verification checklist:
- Open browser DevTools
- Run `localStorage.clear()`
- Import and call `getTheme()` - should detect system preference
- Check `localStorage.getItem('wordfall-theme')` - should match system
- Call `getTheme()` again - should read from localStorage
- Set invalid value: `localStorage.setItem('wordfall-theme', 'invalid')`
- Call `getTheme()` - should return 'light' and overwrite with system theme

**Step 3: Commit**

```bash
git add landing/src/services/theme.js
git commit -m "feat: add theme service with OS preference detection"
```

---

## Task 2: Update App.jsx to Use Theme Service

**Files:**
- Modify: `landing/src/App.jsx:1-25` (imports and state)

**Step 1: Import theme service and add state**

```javascript
import React, { useState, useEffect, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { StorageManager } from './services/storage.js';
import { DictionaryManager } from './services/dictionary.js';
import { PrefetchManager } from './services/prefetch.js';
import { GodotLauncher } from './services/godotLauncher.js';
import { getTheme } from './services/theme.js';  // NEW
import './App.css';

// Initialize Supabase client
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'placeholder-key';
const supabase = createClient(supabaseUrl, supabaseKey);

function App() {
  // State management
  const [state, setState] = useState({
    prefetchStatus: 'idle', // idle | loading | ready | error
    prefetchProgress: 0,
    highScore: null,
    selectedLanguage: 'en',
    error: null,
    transitioning: false,
    theme: 'light',  // NEW: Add theme state
  });
```

**Step 2: Load theme on mount**

Add to useEffect (after line 35):

```javascript
  // Load high score and theme on mount
  useEffect(() => {
    loadHighScore();
    loadTheme();     // NEW
    startPrefetch();
  }, []);

  /**
   * Load theme preference
   */
  function loadTheme() {
    const currentTheme = getTheme();
    setState(prev => ({ ...prev, theme: currentTheme }));
  }
```

**Step 3: Apply theme class to container**

Modify landing-container div (around line 176):

```javascript
  return (
    <div className={`landing-container theme-${state.theme}`} ref={landingRef}>
      <div className="landing-content">
```

**Step 4: Verify theme is applied**

Manual verification:
- Run `npm run dev:landing`
- Open browser DevTools
- Check container element: should have `class="landing-container theme-light"` or `theme-dark"`
- Toggle OS dark mode
- Refresh page
- Verify class changes to match system preference

**Step 5: Commit**

```bash
git add landing/src/App.jsx
git commit -m "feat: integrate theme service into App component"
```

---

## Task 3: Add Dark Theme CSS Variables

**Files:**
- Modify: `landing/src/App.css:1-20` (add CSS variables at top)

**Step 1: Add CSS custom properties for both themes**

Add at the very top of App.css (before existing styles):

```css
/* ============================================
   Theme Variables
   ============================================ */

/* Light Theme (default) */
.theme-light {
  --bg-primary: #F5F2E8;
  --bg-card: #FFFFFF;
  --color-primary: #E07857;
  --color-primary-hover: #EB8563;
  --color-primary-pressed: #D16A48;
  --color-secondary: #7A9D8C;
  --text-primary: #1F1F1F;
  --text-secondary: #4D6659;
  --text-muted: #999999;
  --shadow: rgba(0, 0, 0, 0.12);
}

/* Dark Theme */
.theme-dark {
  --bg-primary: #2B3D4F;
  --bg-card: #364A5E;
  --color-primary: #F29170;
  --color-primary-hover: #FA9E7D;
  --color-primary-pressed: #E07857;
  --color-secondary: #4D6B8A;
  --text-primary: #F2F2F2;
  --text-secondary: #99BFB3;
  --text-muted: #999999;
  --shadow: rgba(0, 0, 0, 0.3);
}
```

**Step 2: Update landing-container to use CSS variables**

Replace hardcoded background gradient (line 14):

```css
.landing-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  width: 100vw;
  background: var(--bg-primary);  /* Changed from gradient */
  padding: 24px;
  transition: opacity 500ms ease-out;
}
```

**Step 3: Update logo color**

Replace hardcoded terracotta (line 37):

```css
.logo {
  font-size: 48px;
  font-weight: 700;
  color: var(--color-primary);  /* Changed from #a0522d */
  margin: 0 0 12px 0;
  letter-spacing: -0.5px;
}
```

**Step 4: Update tagline color**

```css
.tagline {
  font-size: 20px;
  color: var(--text-secondary);  /* Changed from #6b5b4d */
  margin: 0;
  font-weight: 400;
}
```

**Step 5: Update high score badge**

```css
.high-score-badge {
  background: var(--bg-card);   /* Changed from white */
  border: 2px solid var(--color-primary);  /* Changed from #a0522d */
  border-radius: 24px;
  padding: 16px 32px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  box-shadow: 0 2px 8px var(--shadow);  /* Changed */
}

.badge-label {
  font-size: 14px;
  color: var(--text-secondary);  /* Changed from #6b5b4d */
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 600;
}

.badge-score {
  font-size: 32px;
  font-weight: 700;
  color: var(--color-primary);  /* Changed from #a0522d */
}
```

**Step 6: Update progress bar**

```css
.progress-fill {
  height: 100%;
  background: var(--color-primary);  /* Changed from #a0522d */
  transition: width 200ms ease-out;
  border-radius: 4px;
}

.progress-text {
  font-size: 14px;
  color: var(--text-secondary);  /* Changed from #6b5b4d */
  font-weight: 500;
}
```

**Step 7: Update play button**

```css
.play-button {
  background: var(--color-primary);  /* Changed from #a0522d */
  color: white;
  font-size: 24px;
  font-weight: 700;
  padding: 0 48px;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 150ms ease;
  box-shadow: 0 4px 12px var(--shadow);  /* Changed */
  width: 100%;
  max-width: 300px;
  height: 60px;
  min-height: 60px;
}

.play-button:hover:not(:disabled) {
  background: var(--color-primary-hover);  /* Changed from #8b4513 */
  transform: translateY(-2px);
  box-shadow: 0 6px 16px var(--shadow);
}

.play-button:active:not(:disabled) {
  background: var(--color-primary-pressed);  /* NEW */
  transform: translateY(0);
  box-shadow: 0 2px 8px var(--shadow);
}
```

**Step 8: Update language buttons**

```css
.language-button {
  background: var(--bg-card);     /* Changed from white */
  border: 2px solid #ddd;
  color: var(--text-secondary);   /* Changed from #6b5b4d */
  font-size: 16px;
  font-weight: 600;
  padding: 12px 24px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 150ms ease;
  min-height: 48px;
  min-width: 100px;
}

.language-button:hover {
  border-color: var(--color-primary);  /* Changed from #a0522d */
}

.language-button.active {
  background: var(--color-primary);  /* Changed from #a0522d */
  color: white;
  border-color: var(--color-primary);  /* Changed from #a0522d */
}
```

**Step 9: Update how-to-play section**

```css
.how-to-play {
  background: var(--bg-card);  /* Changed from white */
  border-radius: 12px;
  padding: 24px;
  width: 100%;
  box-shadow: 0 2px 8px var(--shadow);  /* Changed */
}

.how-to-title {
  font-size: 20px;
  font-weight: 700;
  color: var(--color-primary);  /* Changed from #a0522d */
  margin: 0 0 16px 0;
}

.how-to-list li {
  font-size: 16px;
  color: var(--text-secondary);  /* Changed from #6b5b4d */
  line-height: 1.5;
  padding-left: 24px;
  position: relative;
}

.how-to-list li::before {
  content: '•';
  color: var(--color-primary);  /* Changed from #a0522d */
  font-weight: 700;
  font-size: 20px;
  position: absolute;
  left: 0;
}
```

**Step 10: Update retry button**

```css
.retry-button {
  background: var(--bg-card);      /* Changed from white */
  border: 2px solid var(--color-primary);  /* Changed from #a0522d */
  color: var(--color-primary);     /* Changed from #a0522d */
  font-size: 16px;
  font-weight: 600;
  padding: 12px 32px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 150ms ease;
  min-height: 48px;
  min-width: 120px;
}

.retry-button:hover {
  background: var(--color-primary);  /* Changed from #a0522d */
  color: white;
}
```

**Step 11: Update focus states**

```css
button:focus-visible {
  outline: 3px solid var(--color-primary);  /* Changed from #a0522d */
  outline-offset: 2px;
}
```

**Step 12: Verify CSS variables in browser**

Manual verification:
- Run `npm run dev:landing`
- Open DevTools
- Inspect `.landing-container` element
- Check Computed styles - should show CSS variables resolved
- Toggle OS dark mode, refresh
- Verify colors change (background goes dark, text goes light)
- Test all interactive elements (buttons, hover states)

**Step 13: Commit**

```bash
git add landing/src/App.css
git commit -m "feat: add dark theme CSS with custom properties"
```

---

## Task 4: Build and Test React Theme Switching

**Files:**
- No new files

**Step 1: Build landing page**

```bash
npm run build:landing
```

Expected output:
```
vite v5.x.x building for production...
✓ XXX modules transformed.
dist/index.html                 X.XX kB
dist/assets/index-XXXXX.css     X.XX kB │ gzip: X.XX kB
dist/assets/index-XXXXX.js    XXX.XX kB │ gzip: XX.XX kB
✓ built in XXXms
```

**Step 2: Serve and test light mode (OS light)**

```bash
npm run serve
```

Open `http://localhost:8000` in browser with OS light mode:
- Background: Cream (#F5F2E8)
- Logo: Terracotta (#E07857)
- Text: Dark gray (#1F1F1F)
- Cards: White background

**Step 3: Test dark mode (OS dark)**

- Enable OS dark mode
- Refresh browser
- Clear localStorage if needed: `localStorage.clear()`
- Background: Dark teal (#2B3D4F)
- Logo: Light terracotta (#F29170)
- Text: Light gray (#F2F2F2)
- Cards: Dark card background (#364A5E)

**Step 4: Test localStorage persistence**

- Keep OS dark mode on
- Check localStorage: `localStorage.getItem('wordfall-theme')` → should be 'dark'
- Refresh page → should stay dark theme
- Turn off OS dark mode
- Refresh page → should still be dark (localStorage wins)
- Clear localStorage
- Refresh page → should be light (OS preference)

**Step 5: Commit verification**

No code changes, just verification. If everything works, proceed to next task.

---

## Task 5: Add localStorage Sync to Godot ThemeManager

**Files:**
- Modify: `godot/scripts/ThemeManager.gd:59-100` (add localStorage functions)

**Step 1: Add _load_from_localstorage function**

Add after `_ready()` function (around line 61):

```gdscript
func _load_from_localstorage() -> String:
	"""Load theme from localStorage (web only)
	Returns theme string ('light' or 'dark') or empty string if unavailable
	"""
	if not OS.has_feature("web"):
		return ""  # Desktop build, skip localStorage

	var js_interface = JavaScriptBridge.get_interface("localStorage")
	if js_interface == null:
		push_warning("localStorage interface not available")
		return ""

	var theme = js_interface.getItem("wordfall-theme")
	if theme == null or theme == "":
		return ""

	# Validate theme value
	if theme != "light" and theme != "dark":
		push_warning("Invalid theme in localStorage: " + str(theme))
		return ""

	return theme
```

**Step 2: Update _ready to load from localStorage first**

Modify `_ready()` function (around line 59):

```gdscript
func _ready() -> void:
	# Web: Try localStorage first, then ConfigFile
	if OS.has_feature("web"):
		var web_theme = _load_from_localstorage()
		if web_theme != "":
			current_theme = web_theme
			GameSettings.theme = web_theme
			print("ThemeManager: Loaded theme from localStorage: ", web_theme)
			return  # Skip ConfigFile load on web if localStorage has valid theme

	# Desktop or localStorage empty: Load from ConfigFile
	_load_settings()
	current_theme = GameSettings.theme
```

**Step 3: Add _sync_to_localstorage function**

Add after `_load_from_localstorage()`:

```gdscript
func _sync_to_localstorage(theme_name: String) -> void:
	"""Write theme to localStorage (web only)"""
	if not OS.has_feature("web"):
		return  # Desktop build, skip localStorage

	var js_interface = JavaScriptBridge.get_interface("localStorage")
	if js_interface == null:
		push_warning("localStorage interface not available, cannot sync theme")
		return

	js_interface.setItem("wordfall-theme", theme_name)
	print("ThemeManager: Synced theme to localStorage: ", theme_name)
```

**Step 4: Update set_theme to sync localStorage**

Modify `set_theme()` function (around line 67):

```gdscript
func set_theme(theme_name: String) -> void:
	if theme_name not in ["light", "dark"]:
		push_warning("Invalid theme name: " + theme_name)
		return

	current_theme = theme_name
	GameSettings.theme = theme_name
	_save_settings()
	_sync_to_localstorage(theme_name)  # NEW: Sync to localStorage on web
	theme_changed.emit()
```

**Step 5: Verify Godot code syntax**

Open Godot editor:
- Open `godot/scripts/ThemeManager.gd`
- Check for syntax errors (should see no red underlines)
- Run game in editor (F5)
- Check Output tab for any errors

**Step 6: Commit**

```bash
git add godot/scripts/ThemeManager.gd
git commit -m "feat: add localStorage sync to ThemeManager for web builds"
```

---

## Task 6: Test Full Theme Sync Flow

**Files:**
- No new files

**Step 1: Export Godot web build**

In Godot editor:
- Project > Export
- Select "Web" preset
- Export to `dist/` directory
- Verify files exported: `dist/index.wasm`, `dist/index.pck`, `dist/index.js`

**Step 2: Rebuild landing page**

```bash
npm run build:landing
```

**Step 3: Test Scenario 1 - First visit with light OS preference**

```bash
npm run serve
```

1. Open browser DevTools
2. Run `localStorage.clear()`
3. Turn OFF OS dark mode
4. Navigate to `http://localhost:8000`
5. Verify React shows light theme
6. Click "Play" button
7. Verify Godot loads with light theme (no flash)
8. Check DevTools Console for: "ThemeManager: Loaded theme from localStorage: light"

**Step 4: Test Scenario 2 - First visit with dark OS preference**

1. Clear localStorage
2. Turn ON OS dark mode
3. Refresh page
4. Verify React shows dark theme immediately
5. Click "Play"
6. Verify Godot loads with dark theme (no flash)
7. Check Console: "ThemeManager: Loaded theme from localStorage: dark"

**Step 5: Test Scenario 3 - Theme change in Godot Settings**

1. Start with light theme
2. Play game
3. In Godot game, open Settings
4. Change theme to Dark
5. Check localStorage in DevTools: `localStorage.getItem('wordfall-theme')` → 'dark'
6. Refresh page (exit and restart)
7. Verify React landing page now shows dark theme
8. Verify Godot continues with dark theme

**Step 6: Test Scenario 4 - Invalid localStorage value**

1. Set invalid value: `localStorage.setItem('wordfall-theme', 'invalid')`
2. Refresh page
3. Verify React shows light theme (fallback)
4. Verify localStorage corrected to 'light' or OS preference
5. Click Play
6. Verify Godot loads normally

**Step 7: Visual verification checklist**

Go through each element and verify colors match:
- ✅ Background color matches Godot exactly
- ✅ Button primary color (terracotta) matches
- ✅ Text contrast is readable in both themes
- ✅ No color flash during React → Godot transition
- ✅ Progress bar color matches theme
- ✅ High score badge looks correct in both themes
- ✅ Language buttons work in both themes
- ✅ How to Play section readable in both themes

**Step 8: Document test results**

If all tests pass, create test report:

```bash
echo "# Theme Sync Test Results

## Scenario 1: First Visit (Light OS)
✅ React shows light theme immediately
✅ Godot loads with light theme
✅ localStorage set to 'light'

## Scenario 2: First Visit (Dark OS)
✅ React shows dark theme immediately
✅ Godot loads with dark theme
✅ localStorage set to 'dark'

## Scenario 3: Theme Change in Godot
✅ Theme change in Settings syncs to localStorage
✅ React respects updated preference on next visit

## Scenario 4: Invalid localStorage
✅ React falls back to system preference
✅ localStorage corrected

## Visual Verification
✅ All colors match Godot themes
✅ No visual flash during transition
✅ Text readable in both themes

Tested: $(date)
" > docs/plans/2026-02-16-theme-sync-test-results.md
```

**Step 9: Commit test results**

```bash
git add docs/plans/2026-02-16-theme-sync-test-results.md
git commit -m "docs: add theme sync test results"
```

---

## Final Verification

**All tasks complete!** The theme sync system should now work seamlessly:

1. ✅ React theme service detects OS preference
2. ✅ localStorage used as shared storage
3. ✅ CSS variables enable dark mode
4. ✅ Godot reads localStorage on web startup
5. ✅ Godot syncs theme changes back to localStorage
6. ✅ No visual flash during transition

**Next Steps:**
- Merge to main after all tests pass
- Monitor for edge cases in production
- Consider adding theme toggle UI in React if user feedback requests it

---

## Notes

- If colors don't match exactly, adjust CSS variables in `App.css` to fine-tune
- localStorage key `'wordfall-theme'` must stay consistent between React and Godot
- JavaScriptBridge only works in web builds (desktop uses ConfigFile only)
- OS preference detection only runs on first visit (then localStorage persists)
