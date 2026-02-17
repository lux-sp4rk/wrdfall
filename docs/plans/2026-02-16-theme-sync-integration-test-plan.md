# React-Godot Theme Sync Integration Test Plan

**Date:** 2026-02-16
**Feature:** Full theme synchronization between React UI overlay and Godot game
**Status:** Ready for integration testing

## Overview

This document provides a complete test plan for verifying the React-Godot theme synchronization system. The system ensures that theme preferences persist across sessions and sync bidirectionally between React and Godot.

## Architecture Summary

```
User Action → React Theme Service → localStorage → Godot ThemeManager
                     ↓                                    ↓
                CSS Variables                      Scene Updates
```

**Key Components:**
- **React:** `landing/src/services/theme.js`, `landing/src/App.jsx`, CSS variables in `landing/src/App.css`
- **Godot:** `godot/scripts/ThemeManager.gd` with localStorage sync
- **Storage:** `localStorage['word-loom-theme']` key (values: `"light"` | `"dark"`)

## Prerequisites

Before testing, ensure:

1. **Godot Export** - Fresh HTML5 export to `dist/`
   ```bash
   # In Godot Editor:
   # Project > Export > Web > Export Project
   # Target: /Users/ulizzle/Work/word-loom/dist/
   ```

2. **React Build** - Production build deployed
   ```bash
   npm run build:landing
   # Verify dist/ contains React build artifacts
   ```

3. **Local Server** - Serve the built application
   ```bash
   cd /Users/ulizzle/Work/word-loom
   python3 -m http.server -d dist/ 8000
   ```

4. **Browser Setup** - Use Chrome/Firefox with DevTools
   - Clear localStorage before each test scenario
   - Disable browser caching (DevTools > Network > Disable cache)

## Test Scenarios

### Scenario 1: First Visit - Light OS Preference

**Objective:** Verify default light theme on first visit with light OS preference.

**Setup:**
1. Set OS to light mode
2. Open Chrome DevTools (F12)
3. Clear localStorage:
   ```javascript
   localStorage.clear();
   ```
4. Navigate to `http://localhost:8000`

**Expected Results:**

| Component | Expected State |
|-----------|---------------|
| localStorage | `localStorage.getItem('word-loom-theme') === null` initially |
| React UI | Light theme (cream background, terracotta buttons) |
| Godot Game | Light theme after engine loads |
| CSS Variables | `--bg-primary: #F5F2E8` (check via DevTools) |
| Console Logs | No initialization log (theme loaded silently) |

**Visual Verification:**
- [ ] React overlay has cream background (`#F5F2E8`)
- [ ] Godot canvas shows light theme (cream grid background)
- [ ] No theme "flash" or FOUC (Flash of Unstyled Content)

**Technical Verification:**
```javascript
// In DevTools Console:
localStorage.getItem('word-loom-theme'); // Should be null initially

// After page load:
getComputedStyle(document.querySelector('.landing-container')).getPropertyValue('--bg-primary').trim();
// Expected: "rgb(245, 242, 232)" or "#F5F2E8"

// Check React root element:
document.querySelector('#root').className; // Should include theme-related class
```

---

### Scenario 2: First Visit - Dark OS Preference

**Objective:** Verify default dark theme on first visit with dark OS preference.

**Setup:**
1. Set OS to dark mode (System Preferences)
2. Open Chrome DevTools (F12)
3. Clear localStorage:
   ```javascript
   localStorage.clear();
   ```
4. Navigate to `http://localhost:8000`

**Expected Results:**

| Component | Expected State |
|-----------|---------------|
| localStorage | `localStorage.getItem('word-loom-theme') === null` initially |
| React UI | Dark theme (dark teal background, muted accents) |
| Godot Game | Dark theme after engine loads |
| CSS Variables | `--bg-primary: #2B3D4F` (check via DevTools) |
| Console Logs | No initialization log (theme loaded silently) |

**Visual Verification:**
- [ ] React overlay has dark teal background (`#2B3D4F`)
- [ ] Godot canvas shows dark theme (dark grid background)
- [ ] High contrast text (white/cream on dark)

**Technical Verification:**
```javascript
// In DevTools Console:
localStorage.getItem('word-loom-theme'); // Should be null initially

// After page load:
getComputedStyle(document.querySelector('.landing-container')).getPropertyValue('--bg-primary').trim();
// Expected: "rgb(43, 61, 79)" or "#2B3D4F"

// Verify prefers-color-scheme detection:
window.matchMedia('(prefers-color-scheme: dark)').matches; // Should be true
```

---

### Scenario 3: Theme Change in Godot Settings

**Objective:** Verify React updates when theme changes in Godot Settings screen.

**Setup:**
1. Clear localStorage and reload page
2. Wait for game to fully load
3. Navigate: Home → Settings (gear icon)
4. Change theme via Settings > Theme dropdown

**Test Steps:**

**Step 3a: Switch to Dark Theme**
1. In Godot Settings, select "Dark" from Theme dropdown
2. Observe React UI update

**Expected Results:**
- [ ] React UI immediately switches to dark theme
- [ ] localStorage updated: `localStorage.getItem('word-loom-theme') === 'dark'`
- [ ] CSS variables updated to dark theme values
- [ ] No page reload or flicker
- [ ] Godot log: `ThemeManager: Synced theme to localStorage: dark`

**Technical Verification:**
```javascript
// Monitor localStorage changes (run before changing theme):
window.addEventListener('storage', (e) => {
  console.log('Storage event:', e.key, e.oldValue, '→', e.newValue);
});

// After changing theme in Godot:
localStorage.getItem('word-loom-theme'); // Should be 'dark'

getComputedStyle(document.querySelector('.landing-container')).getPropertyValue('--bg-primary').trim();
// Expected: "rgb(43, 61, 79)"
```

**Step 3b: Switch Back to Light Theme**
1. In Godot Settings, select "Light" from Theme dropdown
2. Observe React UI update

**Expected Results:**
- [ ] React UI immediately switches to light theme
- [ ] localStorage updated: `localStorage.getItem('word-loom-theme') === 'light'`
- [ ] CSS variables updated to light theme values
- [ ] Godot log: `ThemeManager: Synced theme to localStorage: light`

---

### Scenario 4: Invalid localStorage Value

**Objective:** Verify graceful handling of corrupted/invalid theme data.

**Setup:**
1. Clear localStorage
2. Set invalid theme value:
   ```javascript
   localStorage.setItem('word-loom-theme', 'invalid-value');
   ```
3. Reload page

**Expected Results:**

| Component | Expected Behavior |
|-----------|------------------|
| React UI | Falls back to OS preference (light or dark) |
| localStorage | Corrected to valid value (`"light"` or `"dark"`) |
| Console | Warning/error logged about invalid value |
| Godot Game | Uses fallback theme |

**Visual Verification:**
- [ ] No broken UI or blank screen
- [ ] Theme matches OS preference (fallback behavior)
- [ ] Theme can be changed normally after recovery

**Technical Verification:**
```javascript
// Set invalid value:
localStorage.setItem('word-loom-theme', 'neon-purple');

// Reload page (Cmd+R / Ctrl+R)

// After page load:
localStorage.getItem('word-loom-theme');
// Should be 'light' or 'dark' (OS preference), NOT 'neon-purple'

// Check for console warnings:
// Expected: console.warn() from theme service about invalid value
```

**Additional Edge Cases to Test:**
- Empty string: `localStorage.setItem('word-loom-theme', '');`
- Null string: `localStorage.setItem('word-loom-theme', 'null');`
- Number: `localStorage.setItem('word-loom-theme', '1');`
- Object: `localStorage.setItem('word-loom-theme', '[object Object]');`

---

### Scenario 5: React → Godot Transition (No Visual Flash)

**Objective:** Verify seamless theme transition when Godot game loads — the primary UX goal of this feature.

**Setup:**
1. Set a known theme in localStorage: `localStorage.setItem('word-loom-theme', 'dark');`
2. Reload page
3. Watch closely as the page loads

**Test Steps:**

1. Clear localStorage and reload (to reset state)
2. Set OS to dark mode
3. Reload the page
4. Observe the full load sequence:
   - React loading screen appears
   - Progress bar loads
   - "Play" button appears
   - Click Play
   - Godot canvas appears

**Expected Results:**

| Phase | Expected |
|-------|----------|
| React loading screen | Dark theme (dark teal `#2B3D4F` background) immediately |
| After clicking Play | Godot canvas appears with same dark theme |
| Transition moment | NO color flash or white/light flash |
| After Godot loads | Theme matches React exactly (same background color) |

**Visual Verification:**
- [ ] React loading screen background: `#2B3D4F` (dark)
- [ ] Godot game background: matches `#2B3D4F` exactly
- [ ] NO white flash or light-colored flash during transition
- [ ] NO visible theme switch after Godot canvas appears

**Technical Verification:**
```javascript
// Before clicking Play, confirm React theme:
localStorage.getItem('word-loom-theme'); // 'dark'
getComputedStyle(document.querySelector('.landing-container')).getPropertyValue('--bg-primary').trim();
// Expected: rgb(43, 61, 79) or #2B3D4F

// The Godot canvas should appear with the same background color
// as the React container, creating a seamless transition
```

**Tips for testing:**
- Record screen if possible to catch flash (may be <100ms)
- Test on slow network (DevTools > Network > Slow 3G) to extend the transition window
- Test both light→Godot and dark→Godot transitions

---

## Visual Verification Checklist

Use this checklist for each theme state:

### Light Theme Visual Checks
- [ ] Background color: Cream (`#F5F2E8`)
- [ ] Primary buttons: Terracotta (`#E07857`)
- [ ] Secondary buttons: Sage (`#7A9D8C`)
- [ ] Text: Dark (`#1F1F1F`)
- [ ] Grid cells: White/cream

### Dark Theme Visual Checks
- [ ] Background color: Dark teal (`#2B3D4F`)
- [ ] Primary buttons: Muted terracotta (`#F29170`)
- [ ] Secondary buttons: Muted sage (`#4D6B8A`)
- [ ] Text: Cream (`#F2F2F2`)
- [ ] Grid cells: Dark blue-grey

### Animation/Transition Checks
- [ ] Theme transitions are smooth (CSS transitions applied)
- [ ] No color "flashing" during switch
- [ ] No layout shift or reflow
- [ ] Godot canvas updates without reload

---

## Performance Verification

### Initial Load Performance
```javascript
// In DevTools Console:
performance.getEntriesByType('navigation')[0].domContentLoadedEventEnd
// Expected: < 500ms for DOM ready

performance.getEntriesByType('paint').find(p => p.name === 'first-contentful-paint')
// Expected: < 800ms for first paint
```

### Theme Switch Performance
```javascript
// Theme switch performance cannot be measured synchronously.
// Godot writes to localStorage asynchronously after a user interaction.
// Instead, verify the theme value is updated within a few seconds:
// 1. Open DevTools > Application > localStorage
// 2. Watch 'word-loom-theme' value while changing theme in Godot Settings
// 3. Value should update within 1 second of changing in Settings
```

### localStorage Access Performance
```javascript
// Verify localStorage isn't blocked:
console.time('localStorage-read');
localStorage.getItem('word-loom-theme');
console.timeEnd('localStorage-read');
// Expected: < 1ms
```

---

## Known Limitations & Edge Cases

### Browser Compatibility
- **localStorage:** Supported in all modern browsers
- **CSS Custom Properties:** Supported in Chrome 49+, Firefox 31+, Safari 9.1+
- **prefers-color-scheme:** Supported in Chrome 76+, Firefox 67+, Safari 12.1+

**Testing Note:** Test in at least 2 browsers (Chrome + Firefox/Safari).

### Edge Cases

#### 1. Private/Incognito Mode
**Issue:** Some browsers restrict localStorage in private mode.

**Test:**
1. Open incognito window
2. Navigate to game
3. Verify theme defaults to OS preference
4. Attempt to change theme

**Expected:** Theme changes work in-session but don't persist after closing window.

#### 2. Multiple Tabs
**Issue:** localStorage changes don't trigger `storage` event in same tab.

**Test:**
1. Open game in Tab A
2. Open same game in Tab B
3. Change theme in Tab A
4. Observe Tab B

**Expected:** Tab B updates when it regains focus or on next localStorage read.

#### 3. Browser Extensions
**Issue:** Ad blockers or privacy extensions may block localStorage.

**Test:**
1. Enable aggressive privacy extension (e.g., Privacy Badger)
2. Load game
3. Verify fallback behavior

**Expected:** Game defaults to OS preference if localStorage blocked.

#### 4. Godot Load Timing
**Issue:** Godot engine may take time to initialize.

**Test:**
1. Monitor theme application timing
2. Check if React updates before Godot ready

**Expected:** React applies theme immediately; Godot syncs when engine ready.

**Technical Check:**
```javascript
// Monitor Godot ready state:
// Check for Godot canvas element
document.querySelector('canvas#canvas');
// Should exist after ~1-2s load time
```

#### 5. Network Latency
**Issue:** Slow connection may delay Godot asset loading.

**Test:**
1. Chrome DevTools > Network > Throttle to "Slow 3G"
2. Load game
3. Verify theme applies before game loads

**Expected:** React UI shows correct theme immediately; Godot updates when loaded.

---

## Debugging Commands

### Check Current State
```javascript
// Current theme in localStorage
localStorage.getItem('word-loom-theme');

// Current CSS variable values
const styles = getComputedStyle(document.querySelector('.landing-container'));
console.log({
  bgPrimary: styles.getPropertyValue('--bg-primary').trim(),
  bgSecondary: styles.getPropertyValue('--bg-secondary').trim(),
  textPrimary: styles.getPropertyValue('--text-primary').trim(),
  primaryButton: styles.getPropertyValue('--primary-button').trim(),
});

// OS preference
window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';

// React root element classes
document.querySelector('#root').className;
```

### Monitor Theme Changes
```javascript
// Watch localStorage changes:
const originalSetItem = localStorage.setItem;
localStorage.setItem = function(key, value) {
  console.log(`[localStorage] ${key} =`, value);
  originalSetItem.apply(this, arguments);
};

// Watch CSS variable changes:
const observer = new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    if (mutation.attributeName === 'class') {
      console.log('[CSS] Landing container class changed');
    }
  });
});
observer.observe(document.querySelector('.landing-container'), { attributes: true });
```

### Force Theme States
```javascript
// Force light theme:
localStorage.setItem('word-loom-theme', 'light');
location.reload();

// Force dark theme:
localStorage.setItem('word-loom-theme', 'dark');
location.reload();

// Clear theme (use OS preference):
localStorage.removeItem('word-loom-theme');
location.reload();
```

### Simulate Storage Events
```javascript
// Simulate cross-tab update (for testing):
window.dispatchEvent(new StorageEvent('storage', {
  key: 'word-loom-theme',
  oldValue: 'light',
  newValue: 'dark',
  url: window.location.href,
  storageArea: localStorage
}));
```

---

## Regression Testing

After any code changes to theme system, re-run all scenarios and verify:

### React Changes
- [ ] `landing/src/services/theme.js` - Theme detection logic
- [ ] `landing/src/App.jsx` - Theme initialization and listener
- [ ] `landing/src/App.css` - CSS variables and theme classes

### Godot Changes
- [ ] `godot/scripts/ThemeManager.gd` - localStorage sync
- [ ] `godot/scenes/Settings.tscn` - Theme dropdown
- [ ] `godot/scripts/Settings.gd` - Theme change handler

### Build Process
- [ ] Godot HTML5 export settings
- [ ] React build configuration
- [ ] dist/ directory structure

---

## Success Criteria

The theme sync system is **PASSING** if:

✅ All 5 test scenarios complete without errors
✅ Visual verification checklist passes for both themes
✅ localStorage persists across page reloads
✅ React ↔ Godot sync is bidirectional and immediate
✅ Invalid values handled gracefully
✅ No console errors or warnings (except expected fallback logs)
✅ Performance metrics within acceptable ranges
✅ Works in at least 2 modern browsers
✅ React → Godot transition has no visible color flash

---

## Rollback Plan

If integration testing fails:

1. **Identify failing component:**
   - React-only issue → Check `theme.js`, `App.jsx`
   - Godot-only issue → Check `ThemeManager.gd`
   - Sync issue → Check localStorage read/write timing

2. **Revert commits if needed:**
   ```bash
   # Find problematic commit:
   git log --oneline docs/plans/2026-02-16-theme-sync-implementation.md

   # Revert specific commit:
   git revert <commit-hash>
   ```

3. **Re-test individual tasks:**
   - Task 1: React theme service in isolation
   - Task 4: React build and manual theme toggle
   - Task 5: Godot localStorage in isolation

4. **Document issues:**
   - Create GitHub issue with test scenario, expected vs actual results
   - Include browser version, OS, console logs, screenshots

---

## Next Steps After Testing

1. **If all tests pass:**
   - ✅ Mark Task 6 complete in implementation plan
   - ✅ Update main `README.md` with theme feature
   - ✅ Close related GitHub issue
   - ✅ Consider user documentation update

2. **If tests fail:**
   - ❌ Document failures in GitHub issue
   - ❌ Return to failing task (1-5) for fixes
   - ❌ Re-test after fixes

3. **Future enhancements:**
   - System theme change detection (auto-switch when OS changes)
   - Theme transition animations
   - Custom theme colors (user preferences)
   - High contrast mode for accessibility

---

## Appendix: File Locations

**React:**
- `/Users/ulizzle/Work/word-loom/landing/src/services/theme.js`
- `/Users/ulizzle/Work/word-loom/landing/src/App.jsx`
- `/Users/ulizzle/Work/word-loom/landing/src/App.css`

**Godot:**
- `/Users/ulizzle/Work/word-loom/godot/scripts/ThemeManager.gd`
- `/Users/ulizzle/Work/word-loom/godot/scenes/Settings.tscn`
- `/Users/ulizzle/Work/word-loom/godot/scripts/Settings.gd`

**Build Output:**
- `/Users/ulizzle/Work/word-loom/dist/` (HTML5 export + React build)

**Documentation:**
- `/Users/ulizzle/Work/word-loom/docs/plans/2026-02-16-theme-sync-implementation.md`
- `/Users/ulizzle/Work/word-loom/docs/plans/2026-02-16-theme-sync-integration-test-plan.md`

---

## Test Execution Log

Use this section to record actual test results:

```
Date: __________
Tester: __________
Browser: __________
OS: __________

Scenario 1 (First Visit - Light): [ PASS / FAIL ]
Notes:

Scenario 2 (First Visit - Dark): [ PASS / FAIL ]
Notes:

Scenario 3 (Godot Settings Change): [ PASS / FAIL ]
Notes:

Scenario 4 (Invalid localStorage): [ PASS / FAIL ]
Notes:

Scenario 5 (Transition Flash): [ PASS / FAIL ]
Notes:

Overall Result: [ PASS / FAIL ]
Issues Found:
```

---

**Document Version:** 1.1
**Last Updated:** 2026-02-16
**Related Docs:** `2026-02-16-theme-sync-implementation.md`
