# Word Loom

A calm, senior-first word puzzle game — no ads, no timers, high contrast, large tap targets. Built with Godot 4.6 (GDScript) for iPad, phone, and browser.

## Game Mode

**Loom Drop** — Tetris-meets-word-search: letters fall onto a 5×6 grid. Swipe to select words in any direction (including diagonals). Valid words clear, gravity pulls letters down, and new letters drop in using a Scrabble-weighted distribution. Shake the grid when stuck to reshuffle letters. The game ends when no valid words remain.

## Running the game

1. Install [Godot 4.6+](https://godotengine.org/download/) (standard edition).
2. Open Godot and choose **Import** > navigate to `godot/project.godot`.
3. Press **F5** (or the Play button) to launch Loom Drop.

## HTML5 export (for browser/iPad testing)

1. In Godot, go to **Project > Export...** and add a **Web** export preset.
2. Click **Export Project** and save to `godot/dist/`.
3. Serve locally: `python3 -m http.server -d godot/dist/ 8000` then open `http://localhost:8000`.

A pre-built web version is deployed via Netlify from the `dist/` directory.

## Project structure

```
godot/
  project.godot    # Godot 4.6 config (main scene: LoomDrop.tscn)
  scenes/
    LoomDrop.tscn  # Main game scene
  scripts/
    LoomDrop.gd    # Main game logic — grid, selection, gravity, shake, win detection
    Dictionary.gd  # Word validation service
  data/
    words.txt      # SOWPODS dictionary (Scrabble-compliant, ~270k words)
  dist/            # HTML5 export output (gitignored)
docs/              # Research notes, monetization strategy, verification guides
dist/              # Deployed web build (Netlify)
netlify.toml       # Netlify deployment config
```

## Key features

- **5×6 grid** with 8-directional word selection (horizontal, vertical, diagonal)
- **Shake mechanic** — unlimited reshuffles to create new opportunities
- **Win condition** — game ends when no valid 3+ letter words exist
- **SOWPODS dictionary** — Scrabble-compliant word validation (~270k words)
- **Smart letter generation** — Scrabble-weighted bag + bigram-aware drops + seed words
- **Gravity** — letters cascade down after word clears
- **Calm pacing** — 6-second drop interval, high contrast UI, large tap targets

See `CLAUDE.md` for development guidelines and code style.
