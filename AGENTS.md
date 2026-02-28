# AGENTS.md — Word Loom Instructions

## Project Context
Word Loom is a strategic word puzzle game built with **Godot 4.6 (GDScript)** — strategic word puzzles meet Tetris.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: High contrast, large tap targets, senior-first design.
- **Game mode**: **Loom Drop** — Tetris-style falling letters on a 5×5 grid with word-swiping.

## Project Structure
```
godot/
  project.godot        # Godot 4.6 config (main scene: Home.tscn)
  scenes/
    Home.tscn          # Main menu / Home screen
    Settings.tscn      # Settings screen (Language, Difficulty, Theme)
    LoomDrop.tscn      # Main game scene
    Stats.tscn         # Stats / high scores screen
    TopNavBar.tscn     # Reusable top nav bar component
  scripts/
    Home.gd            # Home screen logic
    Settings.gd        # Settings screen logic
    GameSettings.gd    # Autoload: persistent user settings
    GameConstants.gd   # Autoload: all game mechanic constants
    StatsManager.gd    # Autoload: high score tracking
    ThemeManager.gd    # Autoload: light/dark theme state
    ThemeConstants.gd  # Autoload: shared color constants
    LoomDrop.gd        # Main game logic (~1400 lines)
    TopNavBar.gd       # Top nav bar (exit, pause, score display)
    Dictionary.gd      # Word lookup service (multi-language)
    LanguageConfig.gd  # Per-language data (weights, bigrams, UI strings)
    Stats.gd           # Stats screen logic
  data/
    words_en.txt       # SOWPODS English dictionary (~270k words)
    words_es.txt       # FISE 2017 Spanish dictionary (~639k words)
  addons/supabase/     # Supabase plugin for backend integration
docs/
  game-rules.md        # Canonical game rules reference
  deployment.md        # Deployment guide
  plans/               # Feature design docs and implementation plans
  research/            # Game design research
  monetization/        # Monetization strategy
dist/                  # Deployed web build (Netlify)
```

### Key Scripts
| Script | Purpose |
|---|---|
| `LoomDrop.gd` | Main game — 5×5 grid, 8-directional word selection, gravity with falling animations, power-ups, combo streaks, drop speed ratchet. Gravity uses visual overlay system: temporary Panel nodes animate while preserving GridContainer layout. |
| `GameConstants.gd` | Central config for all game mechanics: scoring multipliers, combo streak, drop ratchet, power-up costs, vowel ratios |
| `Dictionary.gd` | Loads word list with configurable path and extra alphabet support (e.g. Ñ) |
| `LanguageConfig.gd` | Per-language config: letter weights, bigrams, seed words, letter points, UI strings |
| `ThemeManager.gd` | Light/dark theme state, color dictionaries, `theme_changed` signal |
| `TopNavBar.gd` | Reusable nav bar: Exit, Pause buttons + score/high-score display |

### Autoloads (project.godot)
`GameSettings` · `StatsManager` · `GameConstants` · `ThemeConstants` · `ThemeManager` · `Supabase`

## Theme System
Word Loom supports light and dark themes with persistent user preference.

**Theme Manager:**
- `ThemeManager.gd` - Global autoload managing theme state
- Emits `theme_changed` signal for dynamic updates
- Persists to `user://settings.cfg` (desktop) or localStorage (web)

**Scenes:**
Each scene implements `_apply_theme()` method and connects to `ThemeManager.theme_changed` signal.

**Themes:**
- **Light mode** (default): Warm cream background, terracotta primary, sage secondary
- **Dark mode**: Dark teal background, muted accents, high contrast text

**Settings:**
User can switch theme via Settings > Theme selector (OptionButton).

## Core Workflows
- **Fresh Start**: **CRITICAL** — Before starting any new task, run `npm run sync`. This ensures your local `main` is up-to-date and cleans up merged feature branches.
- **Build/Run**: Open `godot/project.godot` in Godot 4.6+ and press F5 (launches LoomDrop directly).
- **HTML5 Export**: Project > Export > Web preset > Export Project (exports to top-level `dist/`). Serve locally with `python3 -m http.server -d dist/ 8000`.
- **Data**: English (SOWPODS) in `godot/data/words_en.txt`, Spanish (FISE 2017) in `godot/data/words_es.txt`.
- **Deploy**: Web build deployed from `dist/` via Netlify (see `netlify.toml`).
- **Sync Repository**: Run `npm run sync` to fetch origin changes and prune merged branches.

## Display Config
- **Viewport**: 720×1280 portrait orientation
- **Stretch mode**: `canvas_items` with `expand` aspect — UI scales to fill screen
- **Renderer**: GL Compatibility (required for HTML5/mobile export)

## Code Style (GDScript)
- **Signals**: Use `signal_name.connect(callable)` syntax (Godot 4).
- **Typing**: Use static typing where possible (e.g., `var x: int = 5`).
- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes.
- **Nodes**: Access nodes using `@onready var name = $Path` or `%UniqueName`.

## Web Deployment Architecture
**IMPORTANT**: This project uses a hybrid deployment model.
- **`dist/` must be committed**: Netlify serves the web build directly from the `dist/` directory in the repository.
- **No CI Export**: Netlify does NOT run the Godot export process (no Godot SDK in build environment).
- **LFS Required**: Large binaries (`.wasm`, `.pck`) and dictionary files in `dist/` are tracked via **Git LFS**.
- **Manual Export**: After making changes in `godot/`, you must manually export to `dist/` from the Godot Editor before pushing to trigger a Netlify update.
> **⚠️ PCK FOOTGUN — easy to forget, painful to debug:**
> Editing ANY `.gd` file requires a Godot re-export to regenerate `dist/index.pck`.
> React/JS-only changes in `landing/` do NOT require a PCK rebuild.
> GDScript changes are invisible on web until the PCK is rebuilt and committed.
> **Rebuild command:** `npm run export:godot`
- **`build.sh`**: This script only pulls LFS assets and builds the React landing page; it does not generate the Godot engine files.

## Workflow Rules
- **Verification**: After logic changes, test in Godot by pressing F5 to run the game.
- **Deployment**: If changes affect the web build, ensure you export to `dist/`, verify files are staged, and commit. **Never delete `dist/` or add it to `.gitignore`**.
- **Git**: Work on feature branches (`fix/` or `feat/`).
- **PRs**: Include a summary of changes and mention which issue is being addressed.
- **Updates**: Keep this `CLAUDE.md` updated with new build commands or style shifts.

## Game Rules (Summary)
Full rules: [`docs/game-rules.md`](docs/game-rules.md). Key points:

- **5×5 grid**, 8-directional word selection, 3+ letter minimum
- **Scoring**: `letter_sum × length_multiplier × combo_multiplier` (see `GameConstants.gd`)
- **Combo streak**: Consecutive 4+ letter words build multiplier (+0.5× per streak, cap 3.0×); 3-letter words reset
- **Drop ratchet**: Every 5 drops speeds up by 0.5s (floor 2s); 5+ letter words reset speed
- **Power-ups**: Shake, Swap, Draw More — costs vary by difficulty (Normal/Hard)
- **Difficulty**: Normal (8s drops, rescue words) vs Hard (4s drops, no rescue, higher costs)
- **Win**: Clear all letters. **Lose**: Board fills up. Game continues when no words exist — use power-ups.
- **Languages**: English (SOWPODS) and Spanish (FISE 2017)

## Key Docs
- `docs/game-rules.md`: Canonical game rules (scoring, power-ups, difficulty, letter distribution)
- `docs/deployment.md`: Deployment guide
- `docs/supabase-auth-setup.md`: Supabase authentication setup
- `docs/plans/`: Feature design docs and implementation plans
- `docs/research/`: Game design research notes
- `docs/monetization/`: Monetization strategy
