# CLAUDE.md — Word Loom Instructions

## Project Context
Word Loom is a calm, senior-first word puzzle game built with **Godot 4.6 (GDScript)**.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: No ads, no timers, high contrast, large tap targets.
- **Game mode**: **Loom Drop** — Tetris-style falling letters on a 5×6 grid with word-swiping.

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
| `LoomDrop.gd` | Main game — 5×6 grid, 8-directional word selection, gravity with falling animations, shake mechanic, win detection. Gravity uses visual overlay system: creates temporary Panel nodes that animate while preserving GridContainer layout. |
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
- **5×5 grid** with 8-directional word selection (horizontal, vertical, diagonal)
- **Power-ups** — difficulty-based costs (see Difficulty Modes below)
- **Game continues** even when no valid words exist (use power-ups to create opportunities)
- **Letter distribution** — Scrabble-weighted bag + bigram-aware drops + guaranteed seed words
- **Drop interval** — difficulty-based (8s normal, 5s hard)
- **Gravity with animation** — letters cascade down after word clears, with Tetris/Connect 4 style falling animations (visual overlays animate while grid structure remains intact)
- **Multi-language** — English and Spanish with in-game language switcher
- **Difficulty modes** — normal and hard with balanced challenge scaling

## Game Over Conditions
- **Win (Empty Board):** All letters cleared from the 5×5 grid (25 cells empty)
- **Lose (Full Board):** All 25 cells occupied with letters, no space for next drop
- **Important:** Game continues even when no valid 3+ letter words exist — players must use power-ups (shake/hammer/swap) to create word opportunities or risk filling the board

## Difficulty Modes
The game offers two difficulty levels (configurable in Settings screen):

### Normal Mode
- **Drop interval:** 10 seconds
- **Power-up costs:** Shake (3), Swap (2), Draw More (9)
- **Vowel ratio:** Increased by 15% (43.7% for English, 48.3% for Spanish)
- **Rescue words:** Enabled (auto-drops seed words when no valid words exist)

### Hard Mode
- **Drop interval:** 5 seconds (50% faster than normal)
- **Power-up costs:** Shake (8), Swap (5), Draw More (20)
- **Vowel ratio:** Reduced by 25% (28.5% for English, 31.5% for Spanish)
- **Rescue words:** Disabled (no safety net)

## Power-Ups (Score-Based)
All power-ups cost points earned from clearing words. Costs vary by difficulty (see above). After using a power-up, gravity is applied.

| Power-Up | Normal Cost | Hard Cost | Mechanic |
|----------|------------|-----------|----------|
| **Shake** | 3 pts | 8 pts | Randomly redistribute all letters on board, then apply gravity |
| **Swap** | 2 pts | 5 pts | Click any two tiles on the board, swap them, then apply gravity |
| **Draw More** | 9 pts | 20 pts | Draw up to 5 new letters in random open columns (top row must have space) |

**Targeting Mode:** Swap enters targeting mode when clicked (shows cancel icon). Press ESC or click the power-up button again to cancel.

## Scoring System
Points use Scrabble-style per-letter values plus a length bonus:

**Score = sum of letter points + length bonus**
- **Letter points**: Each letter has a point value (e.g. A=1, J=8, Q=10, Z=10). See `LanguageConfig.gd` for full tables per language.
- **Length bonus**: `max(0, word_length - 3) × 2` (3-letter words get no bonus, 4-letter +2, 5-letter +4, etc.)

| Word | Letter Sum | Length Bonus | Total |
|------|-----------|-------------|-------|
| CAT (3) | 3+1+1=5 | 0 | 5 |
| THE (3) | 1+4+1=6 | 0 | 6 |
| STAR (4) | 1+1+1+1=4 | 2 | 6 |
| QUEST (5) | 10+1+1+1+1=14 | 4 | 18 |
| JAZZ (4) | 8+1+10+10=29 | 2 | 31 |

## Key Docs
- `docs/research/`: Game design research notes
- `docs/monetization/`: Monetization strategy
- `docs/issue-5-verify.md`: Verification workflow guide
- `docs/navigation-update.md`: Navigation/scene transition notes
