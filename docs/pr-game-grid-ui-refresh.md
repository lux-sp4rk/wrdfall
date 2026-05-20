# Game Grid UI Refresh

## What

New visual reference for the game grid UI — sharper score display, properly sized power-up buttons, cleaner header layout.

## Why

The existing game screen had good bones but was undercooked:
- Score was a whisper in the corner instead of a statement
- Power-up buttons were cramped postage stamps
- The timer/diamond icon had no room to breathe
- Point values on tiles were near-illegible
- Too much empty vertical space above the grid with no header substance

## Visual Changes

**Before:**
- Score small and visually secondary
- Power-up row: tiny icons, cramped labels
- Timer icon: undefined meaning, no glow
- Tiles: decent but point values buried

**After:**
- Score prominently displayed, bold hierarchy
- Power-up buttons properly sized with breathing room
- Timer icon with soft glow, clear presence
- Grid tiles: cleaner spacing, legible point values
- Header bar fills the vertical space with intent

## Theme

Kept the dark navy + slate-blue palette — it was solid. Just executed with more intent. Falls in line with the "waterfall-inspired blue" direction from the brand guide.

## Reviewers

- **Gigi** — playtester, Word definitions feature (#59)
- UX/UI owner

## Attachments

- `branding/game-grid-ui-refresh.jpg` — visual mock

---

*This is a design reference for implementation. Actual code changes will follow in subsequent PRs targeting the Godot scenes and React landing components.*