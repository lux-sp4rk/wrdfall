# AGENTS.md — Wordfall Instructions

## Project Intent
Wordfall: Tetris-meets-Scrabble built with **Godot 4.6 (GDScript)**. Strategic word puzzles for iPad, mobile, and browser.

## Stack & Tooling

| Layer | Technology | Location |
|-------|------------|----------|
| Engine | Godot 4.6 | [godot/project.godot](godot/project.godot) |
| Backend | Supabase | [supabase_schema.sql](supabase_schema.sql) |
| Web | React + Vite | [landing/package.json](landing/package.json) |

**Non-obvious:**
- **Automated Builds**: Godot web exports are built automatically in GitHub Actions for PRs and main branch pushes. No manual export needed.
- **LFS Tracking**: Large binaries (`.wasm`, `.pck`) are in Git LFS.

## Essential Commands

```bash
# Run local web server
npm run serve

# Run tests
cd godot && ./run_tests.sh
```

## Git Workflow
- **PR-first**: Never push to main.

## Key Patterns

| Pattern | Location |
|---------|----------|
| Core Logic | [godot/scripts/LoomDrop.gd:50-200](godot/scripts/LoomDrop.gd) |
| Theme System | [godot/scripts/ThemeManager.gd](godot/scripts/ThemeManager.gd) |
| Persistence | [godot/scripts/GameSettings.gd:40-60](godot/scripts/GameSettings.gd) |
| Web Bridge | [godot/scripts/Boot.gd:15-30](godot/scripts/Boot.gd) |

## Quick References
- **Rules/Scoring**: [docs/game-rules.md](docs/game-rules.md)
- **Code Style**: [CODE_STYLE.md](CODE_STYLE.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
