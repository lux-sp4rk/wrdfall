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
- **PCK Footgun**: Re-export required for any `.gd` changes to be seen on web. [ARCHITECTURE.md:43](ARCHITECTURE.md:43)
- **LFS Tracking**: Large binaries (`.wasm`, `.pck`) are in Git LFS.

## Essential Commands

```bash
# Export Godot to landing/public/
npm run build:godot

# Full build (Godot + React)
./build.sh

# Run local web server
npm run serve
```

## Git Workflow
- **PR-first**: Never push to main.
- **Commit Assets**: Re-exported `.wasm` and `.pck` files MUST be committed for deploys.

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
