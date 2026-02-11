# CLAUDE.md — Word Loom Instructions

## Project Context
Word Loom is a calm, senior-first word puzzle game built with **Godot 4.6 (GDScript)**.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: No ads, no timers, high contrast, large tap targets.
- **Game mode**: **Loom Drop** — Tetris-style falling letters on a 7×6 grid with word-swiping.

## Project Structure
```
godot/
  project.godot      # Godot 4.6 config (main scene: Home.tscn)
  scenes/
    Home.tscn        # Main menu / Home screen
    Settings.tscn    # Settings screen (Language select)
    LoomDrop.tscn    # Main game scene
  scripts/
    Home.gd          # Home screen logic
    Settings.gd      # Settings screen logic
    GameSettings.gd  # Global autoload for settings
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

## Display Config
- **Viewport**: 720×1280 portrait orientation
- **Stretch mode**: `canvas_items` with `expand` aspect — UI scales to fill screen
- **Renderer**: GL Compatibility (required for HTML5/mobile export)

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
- **Power-ups** — shake (5 pts), hammer (8 pts), swap (3 pts), draw more (15 pts)
- **Game continues** even when no valid words exist (use power-ups to create opportunities)
- **Letter distribution** — Scrabble-weighted bag + bigram-aware drops + guaranteed seed words
- **Drop interval** — 10 seconds between automatic letter drops
- **Gravity** — letters cascade down after word clears
- **Multi-language** — English and Spanish with in-game language switcher

## Game Over Conditions
- **Win (Empty Board):** All letters cleared from the 7×6 grid (42 cells empty)
- **Lose (Full Board):** All 42 cells occupied with letters, no space for next drop
- **Important:** Game continues even when no valid 3+ letter words exist — players must use power-ups (shake/hammer/swap) to create word opportunities or risk filling the board

## Power-Ups (Score-Based)
All power-ups cost points earned from clearing words. After using a power-up, gravity is applied.

| Power-Up | Cost | Mechanic |
|----------|------|----------|
| **Shake** | 5 pts | Randomly redistribute all letters on board, then apply gravity |
| **Hammer** | 8 pts | Click to target a single tile, destroy it, then apply gravity |
| **Swap** | 3 pts | Click two adjacent tiles (8-directional), swap them, then apply gravity |
| **Draw More** | 15 pts | Draw up to 5 new letters in random open columns (top row must have space) |

**Targeting Modes:** Hammer and Swap enter targeting mode when clicked (shows cancel icon). Press ESC or click the power-up button again to cancel.

## Scoring System
Points are awarded based on word length:

| Word Length | Points |
|-------------|--------|
| 3 letters | 5 pts |
| 4 letters | 7 pts |
| 5 letters | 10 pts |
| 6 letters | 14 pts |
| 7+ letters | 14 + (length - 6) × 5 |

**Example:** An 8-letter word = 14 + (8-6) × 5 = 24 points

## Key Docs
- `docs/research/`: Game design research notes
- `docs/monetization/`: Monetization strategy
- `docs/issue-5-verify.md`: Verification workflow guide
- `docs/navigation-update.md`: Navigation/scene transition notes
