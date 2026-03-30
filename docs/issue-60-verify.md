# Issue #60 Verification: iPad Zoom Lock on Game Over

## Problem
On iPad, the view zooms in when the 'Game Over' modal appears and fails to return to normal scale.

## Root Cause
iOS Safari has a known behavior where it will zoom in when elements (particularly buttons) receive focus, even when `user-scalable=no` is set. Without `maximum-scale=1.0` in the viewport meta tag, iOS will:
1. Zoom in when a button/input gets focus
2. Not automatically zoom back out

## Solution Implemented

### 1. Custom HTML Export Template
**File**: `godot/export-template.html`

**Change**: Modified viewport meta tag from:
```html
<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">
```

To:
```html
<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
```

**Effect**: Prevents iOS Safari from scaling the viewport beyond 1.0x, even when elements receive focus.

### 2. Export Preset Configuration
**File**: `godot/export_presets.cfg`

**Change**: Set custom HTML shell path:
```
html/custom_html_shell="res://export-template.html"
```

**Effect**: Godot will use our custom HTML template instead of the default when exporting for web.

### 3. Prevent Auto-Focus (Defensive)
**File**: `godot/scripts/LoomDrop.gd:1224`

**Change**: Added explicit focus release in `_show_game_over_modal()`:
```gdscript
# Ensure buttons don't auto-focus (prevents iOS zoom on focus)
retry_button.release_focus()
quit_button.release_focus()
```

**Effect**: Ensures modal buttons never receive focus automatically, preventing the iOS zoom trigger.

## Testing Instructions

### Prerequisites
- Access to an iPad (physical device or simulator)
- Safari browser on iPad

### Export Steps
1. Open the project in Godot 4.6
2. Go to Project > Export
3. Select the "Web" preset
4. Click "Export Project" and save to `dist/` (overwrites existing)
5. Deploy the new build to your test environment (Netlify or local server)

### Test Cases

#### Test 1: Win Condition Zoom Check
1. Open Wordfall on iPad in Safari
2. Play until you win (clear all letters or no valid words remain)
3. Observe the Game Over modal appearing
4. **Expected**: No zoom occurs, viewport remains at 1.0x scale
5. **Expected**: Modal is fully visible and properly scaled

#### Test 2: Lose Condition Zoom Check
1. Open Wordfall on iPad in Safari
2. Play until the grid fills (top row has no space for new letters)
3. Observe the Game Over modal appearing
4. **Expected**: No zoom occurs, viewport remains at 1.0x scale
5. **Expected**: Modal is fully visible and properly scaled

#### Test 3: Button Interaction
1. Trigger either win or lose condition
2. Tap the "Play Again" button in the modal
3. **Expected**: Game restarts without any zoom artifacts
4. Trigger game over again
5. Tap the "Quit to Menu" button
6. **Expected**: Returns to home screen without zoom artifacts

#### Test 4: Orientation Change
1. Trigger game over on iPad
2. Rotate device from portrait to landscape
3. **Expected**: Viewport scale remains at 1.0x, no zoom

#### Test 5: Multiple Game Sessions
1. Play 3-5 complete games in a row
2. Observe modal appearance each time
3. **Expected**: Consistent behavior, no zoom on any game over

### Success Criteria
- ✅ No zoom occurs when Game Over modal appears
- ✅ Viewport scale remains at 1.0x throughout the session
- ✅ Modal is fully visible and properly positioned
- ✅ Buttons are tappable without triggering zoom
- ✅ Behavior is consistent across multiple game sessions

### Regression Testing
- ✅ Verify game still works on desktop browsers (Chrome, Firefox, Safari)
- ✅ Verify game still works on Android devices
- ✅ Verify game still works on iPhone (in addition to iPad)
- ✅ Verify all game mechanics still function correctly

## Technical Notes

### Why `maximum-scale=1.0` Works
iOS Safari has special accessibility features that override `user-scalable=no` to help users read small text. By setting `maximum-scale=1.0`, we explicitly tell iOS that:
- The maximum allowed zoom is 1.0x (no zoom)
- This applies even when elements receive focus
- This overrides the accessibility zoom behavior

### Alternative Approaches Considered
1. ❌ **Increase font sizes to ≥16px**: Buttons already use 28px font
2. ❌ **JavaScript-based zoom reset**: Unreliable, doesn't prevent initial zoom
3. ❌ **CSS `touch-action` modifications**: Already set to `none`, didn't help
4. ✅ **Viewport meta tag + focus prevention**: Most reliable solution

### Browser Support
- **iOS Safari**: ✅ Primary fix target
- **Android Chrome**: ✅ Unaffected (already works)
- **Desktop Safari**: ✅ Unaffected (already works)
- **Desktop Chrome/Firefox**: ✅ Unaffected (already works)

## Deployment

After verification passes:

1. **Build**: Export Web preset in Godot (overwrites `dist/index.html`)
2. **Verify**: Check that `dist/index.html` contains the updated viewport meta tag
3. **Deploy**: Push to Netlify (automatic deployment from `dist/` folder)
4. **Test**: Re-test on live deployment URL with iPad

## References
- Issue: https://github.com/lux-sp4rk/word-loom/issues/60
- Godot HTML5 Export Docs: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- iOS Safari Viewport Behavior: https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/UsingtheViewport/UsingtheViewport.html
