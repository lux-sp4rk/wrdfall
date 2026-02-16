# Word Loom

**Strategic word puzzles meet Tetris.** Built with Godot 4.6 (GDScript). High contrast, large tap targets. Targets iPad, phone, and browser (HTML5).

## Quick Start

**Prerequisites:** [Godot 4.6+](https://godotengine.org/download/) (standard edition)

```bash
# Open project in Godot
open godot/project.godot   # macOS — or open via Godot's Import dialog

# Press F5 to run (launches Home screen)
```

## Development

### Project Structure

```
godot/
  project.godot        # Engine config (main scene: Home.tscn)
  scenes/              # .tscn scene files (Home, Settings, LoomDrop, Stats, TopNavBar)
  scripts/             # GDScript files (~15 scripts)
  data/                # Word lists (English SOWPODS, Spanish FISE 2017)
  assets/              # Fonts, themes (.tres), icons
  addons/supabase/     # Supabase plugin
docs/
  game-rules.md        # Full game rules reference
  deployment.md        # Deployment guide
  plans/               # Feature design docs and implementation plans
dist/                  # Deployed web build (Netlify)
```

### Key Scripts

| Script | Role |
|---|---|
| `LoomDrop.gd` | Main game logic — grid, word selection, gravity, power-ups, scoring, combo streaks, drop ratchet |
| `GameConstants.gd` | All game mechanic constants (autoload) |
| `GameSettings.gd` | Persistent user settings — language, difficulty, theme (autoload) |
| `ThemeManager.gd` | Light/dark theme state and color dictionaries (autoload) |
| `LanguageConfig.gd` | Per-language config — letter weights, bigrams, seed words, UI strings |
| `Dictionary.gd` | Word validation with multi-language and extra alphabet support (Ñ) |
| `TopNavBar.gd` | Reusable nav component — exit, pause, score display |

### Autoloads

`GameSettings` · `StatsManager` · `GameConstants` · `ThemeConstants` · `ThemeManager` · `Supabase`

### Code Style

- Static typing: `var x: int = 5`
- `snake_case` for variables/functions, `PascalCase` for classes
- Signals: `signal_name.connect(callable)` (Godot 4 syntax)
- Node access: `@onready var name = $Path` or `%UniqueName`

## Web Export & Deployment

### Local testing

```bash
# Export from Godot: Project → Export → Web (exports to dist/)
npm run serve             # Serve from dist/ on :8000
```

### Production (Netlify)

Deployed automatically from `dist/` via Netlify.

```bash
# Manual deploy workflow:
# 1. Export from Godot (outputs to dist/)
# 2. Push — Netlify deploys from dist/
```

## Game Overview

**Loom Drop** — letters fall onto a 5×5 grid. Swipe adjacent tiles (8 directions) to spell words. Matched letters clear, gravity pulls remaining tiles down. Score uses multiplicative formula: `letter_sum × length_multiplier × combo_multiplier`.

- **Two difficulty modes** (Normal / Hard) with different drop speeds, power-up costs, and vowel ratios
- **Three power-ups** — Shake, Swap, Draw More (cost score points)
- **Combo streaks** — consecutive 4+ letter words build a score multiplier (cap 3.0×)
- **Drop speed ratchet** — pace increases over time; 5+ letter words reset it
- **Two languages** — English and Spanish, switchable in Settings
- **Light/dark themes** — switchable in Settings, persisted across sessions

Full rules: [`docs/game-rules.md`](docs/game-rules.md)

## Backend

Uses [Supabase](https://supabase.com/) for backend services. Plugin in `godot/addons/supabase/`, schema in `supabase_schema.sql`. Public anon keys are safe to commit (security via RLS).

## Docs

| Doc | Contents |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | AI assistant instructions and project context |
| [`docs/game-rules.md`](docs/game-rules.md) | Complete game rules, scoring tables, mechanics |
| [`docs/deployment.md`](docs/deployment.md) | Deployment guide |
| [`docs/plans/`](docs/plans/) | Feature design docs and implementation plans |

## License

MIT
