# wordfall Architecture

> **A calm, strategic word puzzle game** — Letters fall, words rise. Built with Godot 4.6 (GDScript).

## Overview

wordfall is a Tetris-meets-Scrabble word puzzle game where players swipe adjacent tiles on a 5×5 grid to form words. The game targets iPad, phone, and browser (HTML5) with a senior-first design philosophy: high contrast, large tap targets, and calm pacing.

**Core Game Mode: Loom Drop**
- Letters fall onto a 5×5 grid at timed intervals
- Swipe 8-directionally to select 3+ letter words
- Valid words clear tiles; gravity pulls remaining letters down
- Scoring: `letter_sum × length_multiplier × combo_multiplier`

## Tech Stack

| Layer | Technology |
|-------|------------|
| Engine | Godot 4.6 (GDScript) |
| Language | GDScript with static typing |
| Backend | Supabase (Auth, Database, Leaderboards) |
| Web Shell | React + Vite (landing page) |
| Deployment | Netlify (serves pre-built Godot web export) |
| Testing | GUT (Godot Unit Testing framework) |

## Directory Structure

```
word-loom/
├── godot/                      # Main Godot project
│   ├── project.godot          # Godot config (main scene: Boot.tscn)
│   ├── scenes/                # .tscn scene files
│   │   ├── Boot.tscn          # Entry point — routes to Home (desktop) or LoomDrop (web)
│   │   ├── Home.tscn          # Main menu / home screen
│   │   ├── LoomDrop.tscn      # Main game scene (5×5 grid, word selection)
│   │   ├── Settings.tscn      # Settings screen
│   │   ├── Stats.tscn         # Stats / high scores
│   │   ├── Tutorial.tscn      # Interactive tutorial
│   │   ├── TopNavBar.tscn     # Reusable nav component
│   │   └── GameSidebar.tscn   # Game HUD (timer, combo, power-ups)
│   │
│   ├── scripts/               # GDScript source files
│   │   # --- Core Game ---
│   │   ├── LoomDrop.gd        # Main game logic (~1500 lines)
│   │   ├── Boot.gd            # Boot/routing logic
│   │   ├── Home.gd            # Home screen logic
│   │   ├── Settings.gd        # Settings screen
│   │   ├── Stats.gd           # Stats screen
│   │   # --- Autoloads (Singletons) ---
│   │   ├── GameSettings.gd    # Persistent user settings
│   │   ├── GameConstants.gd   # All game mechanic constants
│   │   ├── StatsManager.gd    # High scores, session tracking
│   │   ├── ThemeManager.gd    # Light/dark theme state
│   │   ├── ThemeConstants.gd  # Shared color/icon constants
│   │   ├── FeatureFlags.gd    # Feature toggle system
│   │   # --- Services ---
│   │   ├── Dictionary.gd      # Word validation service
│   │   ├── LanguageConfig.gd  # Per-language config
│   │   ├── TopNavBar.gd       # Nav bar component logic
│   │   └── GameSidebar.gd     # Sidebar component logic
│   │   # --- Tutorial ---
│   │   ├── Tutorial.gd, TutorialUI.gd, TutorialLoomDrop.gd
│   │   └── TutorialController.gd, TutorialData.gd
│   │
│   ├── data/                  # Game data
│   │   ├── words_en.txt       # SOWPODS English dictionary (~270k words)
│   │   ├── words_es.txt       # FISE 2017 Spanish dictionary (~639k words)
│   │   └── tutorial_phases.json  # Tutorial phase definitions
│   │
│   ├── addons/                # Third-party plugins
│   │   ├── supabase/          # Supabase integration (Auth, DB, Realtime)
│   │   └── gut/               # GUT testing framework
│   │
│   ├── assets/                # Fonts, themes, graphics
│   │   ├── fonts/             # Inter font family, symbol fallbacks
│   │   └── themes/            # spacey/ (current), clashy/ (legacy)
│   │
│   └── tests/                 # GUT unit tests
│       ├── test_drop_ratchet.gd
│       ├── test_feature_flags.gd
│       └── test_smoke.gd
│
├── landing/                   # React web shell (hybrid architecture)
│   ├── src/                   # React components, screens, services
│   └── public/                # Static assets, dictionaries
│
├── dist/                      # Pre-built web export (committed, LFS tracked)
│   ├── index.html             # Main HTML entry
│   ├── index.wasm             # Godot WebAssembly (LFS)
│   ├── index.pck              # Game package (LFS) — **REBUILD ON ANY .gd CHANGE**
│   └── dictionaries/          # Compressed word lists for web
│
├── docs/                      # Documentation
│   ├── game-rules.md          # Canonical game rules
│   ├── deployment.md          # Deployment guide
│   └── plans/                 # Feature design documents
│
└── scripts/                   # Build and utility scripts
    ├── build.sh               # Main build orchestrator
    ├── sync-repo.sh           # Git sync helper
    └── compress-dictionaries.sh
```

## Core Components

### Autoloads (Singletons)

Defined in `godot/project.godot` — loaded automatically at startup:

| Autoload | Purpose | Key Responsibilities |
|----------|---------|---------------------|
| `FeatureFlags` | Feature toggles | `drop_ratchet_enabled`, `draw_more_enabled` — persisted to ConfigFile/localStorage |
| `GameSettings` | User preferences | Language, difficulty, theme, tutorial completion — ConfigFile persistence |
| `StatsManager` | Progress tracking | High scores, session history, WPM, Supabase sync |
| `GameConstants` | Game rules | Grid size, scoring multipliers, power-up costs, drop intervals |
| `ThemeConstants` | Visual constants | Color definitions, icon strings |
| `ThemeManager` | Theme system | Light/dark switching, color lookup, `theme_changed` signal |
| `Supabase` | Backend | Auth, database queries, leaderboards (from addon) |

### Scene Components

| Scene | Responsibility |
|-------|---------------|
| `Boot` | Entry routing — web goes direct to game, desktop to Home |
| `Home` | Main menu — Play, Tutorial, Stats, Settings, Auth |
| `LoomDrop` | Core game — grid, input, scoring, power-ups, game over |
| `Settings` | Language, difficulty, theme selection |
| `Stats` | Session history, high scores, performance metrics |
| `Tutorial` | Interactive onboarding with gated interactions |

### Service Classes

| Class | Role |
|-------|------|
| `DictionaryService` | Word validation — loads from file (desktop) or JS global (web) |
| `LanguageConfig` | Per-language data: letter weights, bigrams, seed words, UI strings |
| `TopNavBar` | Reusable nav with exit, pause, score display |
| `GameSidebar` | Power-up buttons, countdown timer, combo display |

## Data Flow

### Game Startup Flow

```
Boot.tscn (main_scene)
    ├── Web: Check window.WORD_LOOM_LAUNCH_SCENE
    │       ├── "tutorial" → Tutorial.tscn
    │       └── default → LoomDrop.tscn
    └── Desktop: Home.tscn
```

### Game Session Flow

```
LoomDrop._ready()
    ├── Load settings (difficulty → power-up costs, drop interval)
    ├── Load language config (letter weights, word list)
    ├── Initialize DictionaryService
    ├── Build weighted letter bag
    ├── Initialize 5×5 grid with initial letters
    └── Start session tracking (StatsManager)

Player Input → LoomDrop
    ├── Touch/mouse down → Start selection
    ├── Drag over adjacent tiles → Add to path
    ├── Release → Validate word
    │       ├── Valid → Clear tiles, apply gravity, score
    │       └── Invalid → Reset selection
    └── Drop timer → Add new letter row
```

### Scoring Flow

```
Word submitted
    ├── Calculate base score: sum of letter points
    ├── Apply length multiplier (3=1×, 4=2×, 5=4×, 6+=8×)
    ├── Apply combo multiplier (streak of 4+ letter words)
    ├── Update score UI
    ├── Emit word_scored signal
    └── StatsManager.record_word()
```

### Settings Persistence Flow

```
Web Build:
    React SettingsScreen → localStorage
                              ↓
    Godot GameSettings.load_from_localstorage() ← on boot

Desktop Build:
    Godot ConfigFile → user://settings.cfg
```

## External Integrations

### Supabase Backend

| Service | Usage |
|---------|-------|
| Auth | Google/Apple OAuth, anonymous login |
| Database | User profiles, session history |
| Leaderboards | Global high scores |

**Key Files:**
- `godot/addons/supabase/` — Plugin
- `supabase_schema.sql` — Database schema

### JavaScript Bridge (Web Only)

Godot communicates with the React shell via:

```gdscript
# Reading from JavaScript
var launch_scene = JavaScriptBridge.eval("window.WORD_LOOM_LAUNCH_SCENE || ''")
var theme = JavaScriptBridge.get_interface("localStorage").getItem("word-loom-theme")

# Writing to JavaScript
JavaScriptBridge.get_interface("localStorage").setItem("key", "value")
```

## Configuration

### Godot Project Settings (`godot/project.godot`)

| Section | Key Settings |
|---------|-------------|
| Application | Name: "wordfall", Main Scene: `Boot.tscn` |
| Display | 720×1280 viewport, canvas_items stretch, portrait orientation |
| Rendering | GL Compatibility (required for HTML5) |
| Autoload | 7 singletons loaded in order |
| GUI | Custom theme: `spacey.tres`, font: `InterWithSymbols.tres` |

### Game Constants (`GameConstants.gd`)

```gdscript
const ROWS: int = 5
const COLS: int = 5
const MIN_WORD_LENGTH: int = 3

# Difficulty variants
const DROP_INTERVAL_NORMAL: float = 10.0
const DROP_INTERVAL_HARD: float = 6.0

# Scoring
const WORD_MULTIPLIERS: Dictionary = {3: 1, 4: 2, 5: 4, 6: 8}
const COMBO_MULTIPLIER_MAX: float = 3.0
```

## Build & Deploy

### Local Development

```bash
# Run in Godot
open godot/project.godot  # Then press F5

# Serve web build locally
npm run serve  # Serves dist/ on :8000
```

### Web Export Process

**⚠️ CRITICAL: PCK FOOTGUN**

Any change to `.gd` files requires a Godot re-export to regenerate `dist/index.pck`.

```bash
# Rebuild after GDScript changes
npm run build:godot  # Or export from Godot Editor

# The PCK contains compiled GDScript — web won't see changes without it
```

### Deployment (Netlify)

```bash
# Full deploy workflow
npm run build:all    # Build landing page, verify Godot files
git add dist/        # Stage updated PCK/WASM
git commit -m "Deploy: [description]"
git push origin main # Netlify deploys from dist/
```

**Architecture Note:** Netlify serves pre-built files from `dist/` — it cannot run Godot export. Large binaries (`.wasm`, `.pck`) are tracked via Git LFS.

## Key Design Patterns

### Autoload (Singleton) Pattern
Global state and services as Godot autoloads:
```gdscript
# Access anywhere
GameSettings.difficulty = "hard"
ThemeManager.set_theme("dark")
StatsManager.record_word("LOOM", 4)
```

### Signal-Based Communication
Decoupled UI updates via signals:
```gdscript
# ThemeManager.gd
signal theme_changed

# Home.gd
ThemeManager.theme_changed.connect(_apply_theme)
```

### Factory Pattern (LanguageConfig)
Language-specific configuration:
```gdscript
var lang_config = LanguageConfig.get_config(GameSettings.current_language)
# Returns English or Spanish config with weights, bigrams, UI strings
```

### Platform Abstraction
Web vs desktop handling:
```gdscript
if OS.has_feature("web"):
    # Use JavaScriptBridge for localStorage
else:
    # Use ConfigFile for native filesystem
```

## Testing

Using GUT (Godot Unit Testing) framework:

```bash
# Run tests from Godot Editor
# Project → Tools → GUT → Run Tests
```

**Test Files:**
- `test_drop_ratchet.gd` — Drop speed ratchet mechanics
- `test_feature_flags.gd` — Feature toggle persistence
- `test_smoke.gd` — Basic smoke tests

## Documentation

| Document | Purpose |
|----------|---------|
| `docs/game-rules.md` | Canonical game rules, scoring tables |
| `docs/deployment.md` | Deployment procedures |
| `docs/plans/*.md` | Feature design documents |
| `ARCHITECTURE.md` | This file — system overview |
| `CODE_STYLE.md` | Coding conventions |
