# CLAUDE.md — Word Loom Instructions

## Project Context
Word Loom is a calm, senior-first word puzzle game built with **Godot 4.x (GDScript)**.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: No ads, no timers, high contrast, large tap targets.
- **Game modes**: Title screen offers two modes — classic **Puzzle** (loom slots + letter tray) and **Loom Drop** (Tetris-style falling letters on an 8×8 grid with word-swiping).

## Project Structure
```
godot/
  project.godot
  scenes/          # Title.tscn, Puzzle.tscn, LoomDrop.tscn
  scripts/         # GDScript files (see below)
  data/            # puzzles.json, words.txt (dictionary)
  dist/            # HTML5 export output
docs/              # Research notes, monetization ideas, verification guides
dist/              # Deployed web build (Netlify)
```

### Key Scripts
| Script | Purpose |
|---|---|
| `Title.gd` | Title screen — routes to Puzzle or Loom Drop |
| `Puzzle.gd` | Classic puzzle mode (letter tray → loom slots) |
| `LoomDrop.gd` | Loom Drop mode — 8×8 grid, drag-select words, gravity, Scrabble-weighted letter bag |
| `Dictionary.gd` | Loads `words.txt` and provides word lookup |
| `RuleChecker.gd` | Validates selected words against rules |
| `PuzzleLoader.gd` | Loads puzzle data from `puzzles.json` |
| `ValidationSmokeTest.gd` | Lightweight validation smoke test |

## Core Workflows
- **Build/Run**: Open `godot/project.godot` in Godot 4.3+ and press F5.
- **HTML5 Export**: Project > Export > Web preset > Export Project. Serve with `python3 -m http.server -d godot/dist/ 8000`.
- **Tests**: `ValidationSmokeTest.gd` for smoke tests; GUT for unit testing (not yet integrated).
- **Data**: Puzzles defined in `godot/data/puzzles.json`; word dictionary in `godot/data/words.txt`.
- **Deploy**: Web build is in `dist/` and served via Netlify. Build output ignored via `.gitignore`.

## Code Style (GDScript)
- **Signals**: Use `signal_name.connect(callable)` syntax (Godot 4).
- **Typing**: Use static typing where possible (e.g., `var x: int = 5`).
- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes.
- **Nodes**: Access nodes using `@onready var name = $Path` or `%UniqueName`.

## Workflow Rules
- **Verification**: After logic changes, run the smoke test or check the Godot scene manually (see `docs/issue-5-verify.md`).
- **Git**: Work on feature branches (`fix/` or `feat/`).
- **PRs**: Include a summary of changes and mention which issue is being addressed.
- **Updates**: Keep this `CLAUDE.md` updated with new build commands or style shifts.

## Key Docs
- `docs/issue-5-verify.md`: Manual verification steps for word validation.
- `docs/research/`: Research notes (lenses, oracle mechanics).
- `docs/monetization/`: Monetization strategy notes.
