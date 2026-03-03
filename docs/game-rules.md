# Word Loom: Game Rules

Word Loom is a strategic word puzzle game where word-building meets Tetris. The primary game mode is **Loom Drop** — a Tetris-style falling-letter puzzle where you swipe to form words on a 5x5 grid.

## How to Play

1. **Letters fall** one at a time into the 5x5 grid from random columns.
2. **Swipe across adjacent tiles** (horizontal, vertical, or diagonal) to spell a word of 3+ letters.
3. **Matched letters are cleared** from the board and gravity pulls remaining tiles down.
4. **Score points** to spend on power-ups that help you manage the board.
5. **Clear the entire board** to win, or **let it fill up** to lose.

## The Grid

- **Size:** 5 columns x 5 rows (25 tiles total)
- **Starting state:** Bottom 3 rows are pre-filled with letters, including several planted seed words to give you a playable start.
- **Selection:** Drag across tiles in any of 8 directions (up, down, left, right, and all 4 diagonals). Each tile in your path must be adjacent to the previous one.

## Scoring

Score is calculated per word as:

> **Score = Letter Sum x Length Multiplier x Combo Multiplier**

### Letter Values

Each letter has a point value based on Scrabble-style rarity:

| Points | English Letters |
|--------|----------------|
| 1 | A, E, I, L, N, O, R, S, T, U |
| 2 | D, G |
| 3 | B, C, M, P |
| 4 | F, H, V, W, Y |
| 5 | K |
| 8 | J, X |
| 10 | Q, Z |

Spanish has its own letter values (e.g. Q=5, Z=10).

### Length Multiplier

Longer words earn exponentially more. The multiplier is applied to the full letter sum:

| Word Length | Multiplier |
|-------------|------------|
| 3 letters | 1x |
| 4 letters | 2x |
| 5 letters | 4x |
| 6+ letters | 8x |

### Combo Streak

Consecutive 4+ letter words build a combo streak that multiplies your score further:

- Only words of **4 or more letters** build and maintain the streak.
- A **3-letter word resets** the streak to zero.
- Each streak step adds **+0.5x** to the combo multiplier (starting from 1.0x).
- The combo multiplier **caps at 3.0x**.

| Streak | Combo Multiplier |
|--------|-----------------|
| 0 | 1.0x |
| 1 | 1.5x |
| 2 | 2.0x |
| 3 | 2.5x |
| 4+ | 3.0x (cap) |

### Score Examples

| Word | Letter Sum | Length Mult | Combo (streak 0) | Total |
|------|-----------|-------------|-------------------|-------|
| CAT | 5 | 1x | 1.0x | 5 |
| STAR | 4 | 2x | 1.0x | 8 |
| QUEST | 14 | 4x | 1.0x | 56 |
| JAZZ | 29 | 2x | 1.0x | 58 |

With a 2-streak combo (2.0x):

| Word | Letter Sum | Length Mult | Combo | Total |
|------|-----------|-------------|-------|-------|
| STAR | 4 | 2x | 2.0x | 16 |
| QUEST | 14 | 4x | 2.0x | 112 |

## Drop Speed Ratchet

The pace of falling letters increases over time, creating mounting pressure:

- Every **5 letter drops**, the drop interval decreases by **0.5 seconds**.
- The interval never goes below **2 seconds** (the speed floor).
- Scoring a **5+ letter word resets** the drop speed back to its original pace and resets the drop counter.

This creates a core tension: play safe with short words and the game speeds up relentlessly, or invest in longer words to keep the pace manageable.

| Drops | Normal Interval | Hard Interval |
|-------|----------------|---------------|
| 0-4 | 8.0s | 4.0s |
| 5-9 | 7.5s | 3.5s |
| 10-14 | 7.0s | 3.0s |
| 15-19 | 6.5s | 2.5s |
| 20-24 | 6.0s | 2.0s |
| 25+ | 5.5s | 2.0s (floor) |

## Power-Ups

Power-ups cost points earned from clearing words. After using any power-up, gravity is applied to settle the board.

### Shake

Randomly redistributes all letters on the board into new positions.

| | Normal | Hard |
|---|--------|------|
| **Cost** | 3 pts | 8 pts |

### Swap

Pick any two tiles on the board and swap their positions. Enters a targeting mode — select the first tile, then select any second tile with a letter.

| | Normal | Hard |
|---|--------|------|
| **Cost** | 2 pts | 5 pts |

Press **ESC** or tap the Swap button again to cancel targeting mode.

## Difficulty Modes

### Normal

- **Drop interval:** 8 seconds (base)
- **Vowel ratio:** Boosted by 15% — more vowels appear, making words easier to form
- **Rescue words:** Enabled — when no valid words exist on the board, the game biases letter drops to build a playable word
- Lower power-up costs

### Hard

- **Drop interval:** 4 seconds (50% faster)
- **Vowel ratio:** Reduced by 25% — fewer vowels, more consonant-heavy boards
- **Rescue words:** Disabled — no safety net
- Higher power-up costs

## Win and Lose Conditions

- **Win:** Clear every letter from the 5x5 grid (all 25 cells empty).
- **Lose:** All 25 cells are occupied — no space for the next drop.

The game **does not end** when no valid words exist on the board. Players must use power-ups (Shake, Swap) to create new word opportunities, or wait for favorable letter drops.

## Letter Distribution

Letters are not purely random. The drop system uses three strategies to keep boards playable:

1. **Weighted bag** — Letters are drawn from a Scrabble-style weighted distribution (E and A appear far more often than Q and Z).
2. **Bigram awareness** — 50% of the time, the dropped letter is chosen based on what letter sits below it, favoring common letter pairs (TH, ER, IN, etc.).
3. **Vowel balancing** — If the board's vowel ratio falls below the target, the next drop is biased toward vowels.

## Languages

Word Loom supports English and Spanish, switchable in the Settings screen.

- **English:** SOWPODS dictionary (~270k words)
- **Spanish:** FISE 2017 dictionary (~639k words), includes the letter &#xD1;
