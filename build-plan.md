# Word Loom — Minimal Build Plan (web-first)

Goal: a playable prototype on iPad via browser in 1–2 evenings.

## Phase 0: Prototype (no accounts)
- Single screen:
  - Puzzle title
  - Rule card(s)
  - Loom slots (empty boxes)
  - Letter tray (buttons)
  - Undo, Clear, Hint
  - Submit
- Word validation:
  - Local wordlist (wordfreq / wordset) OR simple dictionary file
  - Accept any valid word meeting rule constraints
- 10 starter puzzles hard-coded as JSON

## Phase 1: Content + UX polish
- Bigger fonts/tap targets
- Better feedback states
- More puzzles + 1 theme pack

## Phase 2: Packaging
- iOS: consider wrapping with Tauri/Capacitor later if you want “real app” feel.
- Web: host static site.

## Verification targets
- Can Giselle complete 3 puzzles with zero coaching?
- Do hints behave predictably?
- Any mis-taps / drag frustration on iPad?
