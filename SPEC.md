# Word Loom — Product Spec (v0)

## Core promise
A calm, tactile word puzzle where you “weave” words into patterns. It should feel like the little word game booklets people grew up with: simple, cozy, satisfying.

## Target player
- Seniors / casual players
- Likes word games, dislikes stress and manipulation

## Platforms
- iPad / phone / browser
- Touch-first UI
- Offline-friendly (avoid "didn’t load" moments)

## North-star constraints
- No ads
- No timers (default)
- No energy systems
- Hints are helpful, not stingy

## Core loop
1. Choose a tapestry (puzzle).
2. You get a **letter tray** (7–9 letters) and 1–2 **rules**.
3. Drag letters into the **loom slots** to form a valid word.
4. Submit → word “locks” as woven thread.
5. Complete all required words to finish the tapestry.

## Optional mode: Loom Drop ("Tetris-flavor")
Goal: introduce *gentle pressure* (frustration) without timers/ads/energy by adding a spatial constraint + replenishing letters.

**Setup**
- Player has a fixed **grid** (e.g. 6×8 or 7×9) of letters.
- Player forms a word by dragging a path through **adjacent** letters (Boggle-style).
- Player can also **reposition** letters using a *push-move* (Tetris-like constraint):
  - Clears create **empty cells**.
  - A move is dragging a letter **one step** up/down/left/right into an **adjacent empty cell**.
  - (Optional) Allow "push chains": if you drag a letter into an adjacent letter, the whole line shifts by 1 **only if** there is an empty cell at the far end.

**Clear + drop**
- When a word is accepted:
  - Those letters **disappear**.
  - Letters above **fall down** to fill gaps (gravity).
  - New letters **spawn from the top** to fill emptied cells.

**Loss condition (no timers)**
- Game over when new letters cannot spawn because at least one column is "blocked" (top row occupied when it needs to spawn), or when the grid reaches a defined "jam" state.
- Prefer the classic, legible rule: **"If any spawn would overflow, game over."**

**Difficulty tuning knobs**
- Grid size (smaller = harsher).
- Spawn distribution (Scrabble-like bag vs uniform random).
- Minimum word length.
- Limited reshuffles/undos.
- Optional "rising" mechanic *without time*: after each word, add +1 garbage letter row at bottom unless you clear 2+ words in a streak.

**Fairness requirement**
- Avoid unwinnable random states by using a letter bag + "pity" logic:
  - Track last N clears; if the board has no valid words ≥ min length, force spawns toward vowels/common consonants or offer an auto-reshuffle.

**Scoring (motivates risk)**
- Base points by length.
- Bonus for clearing near the top / clearing many letters in one word.
- Streak/combo bonus for consecutive clears without reshuffle.

## Puzzle structure
A puzzle is a set of word slots. Each slot has:
- Length (required)
- Rule(s) (optional)
- (Later) Theme hint / shared letter(s)

Start with **one slot** puzzles, then scale to 2–3 slots.

## Rule types (v0)
Keep it readable and obvious:
- **Length**: “Make a 5‑letter word.”
- **Starts with** / **Ends with**: “Starts with S.”
- **Contains**: “Must include RA.”

## Difficulty progression
- Early: 1 word, 4–6 letters, generous hints
- Mid: 2 words, mild constraints
- Late: themed sets + tighter trays

## Hints (non-predatory)
- **Nudge**: explains which rule is broken
- **Reveal letter**: places 1 correct letter
- **Reveal word**: solves the slot (still lets you complete the tapestry)

## Senior-first UX rules
- Font size: default large (aim 18–20pt+ equivalent)
- Tap targets: >= 44px; forgiving drag/drop
- High contrast + accessible color palette
- Undo always visible
- Clear “Valid/Invalid” feedback without harsh sounds

## Monetization (no ads)
Recommended:
- **Paid base game** ($4.99–$9.99) with a solid library + daily puzzles.
Optional:
- Themed packs ($1.99–$4.99 each)
- Family sharing / gifting option

## Playtest checklist (with Giselle)
- Understands goal in < 30 seconds
- Completes 3 puzzles without frustration
- Uses hints without confusion
- Asks for “one more” naturally
