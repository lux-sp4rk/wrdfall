# Word Loom

A calm, senior-first word puzzle game — no ads, no timers, high contrast, large tap targets. Built with Godot 4.x (GDScript) for iPad, phone, and browser.

## Game Modes

- **Puzzle** — Classic mode: drag letters from a tray into loom slots to form words.
- **Loom Drop** — Tetris-meets-word-search: letters fall onto an 8×8 grid. Swipe to select words in any direction (including diagonals). Valid words clear, gravity pulls letters down, and new letters drop in using a Scrabble-weighted distribution.

## Running the game

1. Install [Godot 4.3+](https://godotengine.org/download/) (standard or .NET edition).
2. Open Godot and choose **Import** > navigate to `godot/project.godot`.
3. Press **F5** (or the Play button) to run the Title screen.

## HTML5 export (for browser/iPad testing)

1. In Godot, go to **Project > Export...** and add a **Web** export preset.
2. Click **Export Project** and save to `godot/dist/`.
3. Serve locally: `python3 -m http.server -d godot/dist/ 8000` then open `http://localhost:8000`.

A pre-built web version is deployed via Netlify from the `dist/` directory.

## Project structure

```
godot/
  project.godot           # Godot project config
  scenes/
    Title.tscn            # Title screen — routes to Puzzle or Loom Drop
    Puzzle.tscn           # Classic puzzle mode
    LoomDrop.tscn         # Loom Drop mode (8×8 grid)
  scripts/
    Title.gd              # Title screen navigation
    Puzzle.gd             # Classic puzzle logic
    LoomDrop.gd           # Loom Drop — grid, selection, gravity, scoring
    Dictionary.gd         # Word lookup service (loads words.txt)
    RuleChecker.gd        # Word validation rules
    PuzzleLoader.gd       # Loads puzzle data from JSON
    ValidationSmokeTest.gd # Smoke test for validation
  data/
    puzzles.json          # Puzzle definitions
    words.txt             # English word dictionary
docs/                     # Research notes, verification guides
dist/                     # Deployed web build (Netlify)
```

## Key features implemented

- 8×8 grid with 8-directional word selection (including diagonals)
- Offline word validation against a full English dictionary
- Scrabble-weighted letter bag for balanced letter distribution
- Bigram-aware letter drops for more playable boards
- Rescue word system guaranteeing a valid word always exists
- Gravity and cascading after word clears
- Calm pacing: 8-second drop interval, game-over detection

See `CLAUDE.md` for development guidelines and code style.
