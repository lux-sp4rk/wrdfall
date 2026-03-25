# Word Loom Architecture

> **A calm, strategic word puzzle game** — Letters fall, words rise. Built with Godot 4.6 (GDScript).

## Overview

Word Loom is a Tetris-meets-Scrabble word puzzle game where players swipe adjacent tiles on a 5×5 grid to form words. Targets iPad, phone, and browser (HTML5) with senior-first design: high contrast, large tap targets, and calm pacing.

## Tech Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| Engine | Godot 4.6 | [godot/project.godot](godot/project.godot) |
| Backend | Supabase | Auth, DB, Leaderboards. See [supabase_schema.sql](supabase_schema.sql) |
| Web Shell | React + Vite | [landing/package.json](landing/package.json) |
| Testing | GUT | [godot/tests/](godot/tests/) |

## Core Components

### Autoloads (Singletons)
Defined in [godot/project.godot:30-50](godot/project.godot). Key logic:
- `FeatureFlags`: Toggles like `drop_ratchet_enabled`.
- `GameSettings`: Persistence (ConfigFile or localStorage).
- `StatsManager`: WPM, high scores, Supabase sync.
- `ThemeManager`: Light/dark state and `theme_changed` signal.

### Scene Hierarchy
- **Boot**: Routes based on platform. [godot/scripts/Boot.gd](godot/scripts/Boot.gd)
- **Home**: Main menu and Auth. [godot/scripts/Home.gd](godot/scripts/Home.gd)
- **LoomDrop**: Core 5x5 grid and word selection. [godot/scripts/LoomDrop.gd](godot/scripts/LoomDrop.gd)
- **Settings/Stats**: Persistence and metrics.

## Data & Mechanics

### Core Loop
1. **Input**: 8-directional swipe on 5x5 grid.
2. **Validation**: [godot/scripts/Dictionary.gd](godot/scripts/Dictionary.gd) (Desktop: file; Web: JS global).
3. **Scoring**: `sum × length_multiplier × combo_multiplier`. See [godot/scripts/GameConstants.gd](godot/scripts/GameConstants.gd).
4. **Gravity**: Letters fall; new rows added via drop timer.

### Platform Bridge (Web Only)
Godot communicates with React via `JavaScriptBridge`.
- **Read**: `JavaScriptBridge.get_interface("localStorage").getItem("key")`
- **Write**: `JavaScriptBridge.get_interface("localStorage").setItem("key", "value")`

## Build & Deployment

### ⚠️ CRITICAL: PCK Footgun
Any change to `.gd` files requires a Godot re-export to regenerate `dist/index.pck`. The web build will NOT see GDScript changes without a new PCK.
- **Export**: `npm run build:godot`
- **Full Build**: `./build.sh`

### Netlify
Serves pre-built files from `dist/`. Large binaries (`.wasm`, `.pck`) are tracked via **Git LFS**.

## Key Patterns
- **Signals**: Decoupled UI updates (e.g., `theme_changed`).
- **Factories**: `LanguageConfig` provides per-language letter weights/UI strings.
- **Abstraction**: `OS.has_feature("web")` for platform-specific persistence.
