# CLAUDE.md — Word Loom Instructions

## Project Context
Word Loom is a calm, senior-first word puzzle game built with **Godot 4.6 (GDScript)**.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: No ads, no timers, high contrast, large tap targets.
- **Game mode**: **Loom Drop** — Tetris-style falling letters on a 7×6 grid with word-swiping.

## Project Structure
```
godot/
  project.godot      # Godot 4.6 config (main scene: LoomDrop.tscn)
  scenes/
    LoomDrop.tscn    # Main game scene
  scripts/
    LoomDrop.gd      # Main game logic
    Dictionary.gd    # Word lookup service (multi-language)
    LanguageConfig.gd # Per-language data (weights, bigrams, UI strings)
  data/
    words_en.txt     # SOWPODS English dictionary (~270k words)
    words_es.txt     # FISE 2017 Spanish dictionary (~639k words)
  dist/              # HTML5 export output (ignored in git)
docs/
  research/          # Game design research
  monetization/      # Monetization strategy
  issue-5-verify.md  # Verification guide
dist/                # Deployed web build (Netlify)
```

### Key Scripts
| Script | Purpose |
|---|---|
| `LoomDrop.gd` | Main game — 7×6 grid, 8-directional word selection, gravity, shake mechanic, win detection |
| `Dictionary.gd` | Loads word list with configurable path and extra alphabet support (e.g. Ñ) |
| `LanguageConfig.gd` | Per-language config: letter weights, bigrams, seed words, UI strings |

## Core Workflows
- **Build/Run**: Open `godot/project.godot` in Godot 4.6+ and press F5 (launches LoomDrop directly).
- **HTML5 Export**: Project > Export > Web preset > Export Project to `godot/dist/`. Serve locally with `python3 -m http.server -d godot/dist/ 8000`.
- **Data**: English (SOWPODS) in `godot/data/words_en.txt`, Spanish (FISE 2017) in `godot/data/words_es.txt`.
- **Deploy**: Web build deployed from `dist/` via Netlify (see `netlify.toml`).

## Code Style (GDScript)
- **Signals**: Use `signal_name.connect(callable)` syntax (Godot 4).
- **Typing**: Use static typing where possible (e.g., `var x: int = 5`).
- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes.
- **Nodes**: Access nodes using `@onready var name = $Path` or `%UniqueName`.

## Workflow Rules
- **Verification**: After logic changes, test in Godot by pressing F5 to run the game.
- **Git**: Work on feature branches (`fix/` or `feat/`).
- **PRs**: Include a summary of changes and mention which issue is being addressed.
- **Updates**: Keep this `CLAUDE.md` updated with new build commands or style shifts.

## Game Features
- **7×6 grid** with 8-directional word selection (horizontal, vertical, diagonal)
- **Shake mechanic** (unlimited uses) — reshuffles grid to create new word opportunities
- **Win condition** — game ends when no valid 3+ letter words exist on the board
- **Letter distribution** — Scrabble-weighted bag + bigram-aware drops + guaranteed seed words
- **Drop interval** — 6 seconds between automatic letter drops
- **Gravity** — letters cascade down after word clears
- **Multi-language** — English and Spanish with in-game language switcher

## Key Docs
- `docs/research/`: Game design research notes
- `docs/monetization/`: Monetization strategy
- `docs/issue-5-verify.md`: Verification workflow guide
