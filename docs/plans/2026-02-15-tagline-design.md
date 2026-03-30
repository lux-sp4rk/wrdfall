# Wordfall Tagline Update — Design Doc

**Date:** 2026-02-15
**Status:** Approved

## Problem

The current tagline "A calm, senior-first word puzzle game" no longer accurately represents Wordfall's gameplay experience. Recent features have transformed the game:

- **Combo streak system** — Consecutive 4+ letter words build score multipliers (up to 3.0×), rewarding risky play
- **Drop speed ratchet** — Every 5 letter drops speeds up the game by 0.5s (floor at 2s), creating mounting pressure
- **Strategic tension** — Players must choose between safe short words (which accelerate the pace) vs. risky longer words (which reset the drop speed)

The game has evolved into a strategic, pressure-building hybrid that's far from "calm."

## New Tagline

**"Strategic word puzzles meet Tetris"**

### Why This Works

1. **Accurate** — Captures the Tetris-style falling-letter mechanic combined with word-swiping
2. **Strategic positioning** — Emphasizes thoughtful gameplay over frantic reflex action
3. **Clear value prop** — Immediately communicates the unique genre hybrid
4. **Memorable** — Short (5 words), uses universally recognized reference (Tetris)
5. **Broad appeal** — Doesn't pigeonhole as "senior game" while maintaining accessible design

## What Changes

### Files to Update

1. **README.md** (line 3)
   - **Current:** "A calm, senior-first word puzzle game built with **Godot 4.6** (GDScript). No ads, no timers, high contrast, large tap targets."
   - **New:** "**Strategic word puzzles meet Tetris.** Built with Godot 4.6 (GDScript). High contrast, large tap targets. Targets iPad, phone, and browser (HTML5)."
   - **Removes:** "No ads" claim (free version will have ads for monetization)

2. **CLAUDE.md** (line 4)
   - **Current:** "Wordfall is a calm, senior-first word puzzle game built with **Godot 4.6 (GDScript)**."
   - **New:** "Wordfall is a strategic word puzzle game built with **Godot 4.6 (GDScript)** — strategic word puzzles meet Tetris."

3. **docs/game-rules.md** (line 3)
   - **Current:** "Wordfall is a calm, senior-first word puzzle game. The primary game mode is **Loom Drop**..."
   - **New:** "Wordfall is a strategic word puzzle game where word-building meets Tetris. The primary game mode is **Loom Drop**..."

### What Stays the Same

- **Accessibility features** remain core to the design (high contrast, large tap targets, senior-first UX)
- **Implementation** doesn't change — this is purely positioning/messaging
- **Documentation** of accessibility features continues in feature lists, just not in the headline tagline

## Rationale

### Market Positioning

- **Target audience** still includes seniors, but positioning as "strategic" broadens appeal without losing accessibility
- **"No ads" removed** — user's mom plays games with ads; senior market tolerates ads in free versions
- **Gameplay-first** — Let the accessible design speak through the experience rather than telegraphing it in the tagline

### Competitive Differentiation

The Tetris-meets-words hybrid is unique. Most word games are either:
- Static grids (Boggle-style)
- Turn-based board games (Scrabble-style)
- Time-limited search games (word search-style)

Wordfall's falling-letter + gravity mechanic creates a distinct niche that deserves a tagline that highlights it.

## Success Criteria

- [ ] Tagline accurately represents current gameplay (strategic tension, falling blocks)
- [ ] Messaging is consistent across README, CLAUDE.md, and game-rules.md
- [ ] "No ads" claim removed from positioning (allows future monetization)
- [ ] Accessibility features remain documented but not in headline tagline
