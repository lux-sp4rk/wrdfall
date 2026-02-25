# Design: Invisible Loader — React Shell Unification

**Date**: 2026-02-25
**Issue**: [#143 — Refactor: 'Invisible Loader' Strategy](https://github.com/lux-sp4rk/word-loom/issues/143)
**Goal**: Eliminate the visual disconnect between the loading state and the game. The React Shell becomes the full navigation layer; Godot only runs the game.

---

## The Illusion

The core trick: the React Home Screen is **instantly interactive** (< 1s), while the heavy Godot assets (WASM + PCK, ~88MB) download silently in the background. By the time the user clicks Play, everything is already in memory. No loading bar, no wait — just a seamless handoff.

```
User visits site
  ↓
React Home Screen appears instantly (~200ms)
  ↓ (background, invisible to user)
  Godot WASM + PCK + dictionary prefetch in parallel
  ↓
User reads, sees high score, clicks Stats/Settings
  ↓
User clicks Play (assets already loaded)
  ↓
React fades out (500ms) → Godot canvas appears → game starts immediately
```

---

## Architecture

```
React Shell (state-based routing, no React Router)
├── <HomeScreen>    — visually identical to Godot Home.tscn
├── <StatsScreen>   — reads from Supabase + localStorage fallback
└── <SettingsScreen> — writes to localStorage, Godot reads on boot

Godot
└── boots directly into LoomDrop.tscn (game only)
    └── on game end → syncs full stats to Supabase + localStorage
```

Three screens, simple `currentScreen` state in `App.jsx`. No router dependency.

---

## Section 1: React Home Screen

Visually identical to Godot's `Home.tscn`:

- **Background**: theme-aware (`#F5F2E8` light / `#2B3D4F` dark)
- **Decorative tiles**: 4 subtle letter-tile panels at corners (same opacity/rotation as tscn)
- **Card**: centered `PanelContainer` equivalent — white/dark bg, `border-radius: 24px`, drop shadow
- **Font**: Inter (self-hosted from `godot/assets/fonts/Inter/`)
- **Title**: "Word Loom" — large, terracotta `#E07857`
- **Tagline**: "Word-building meets Tetris" — teal `#7A9D8C`
- **High Score**: shown if > 0 (reads from Supabase / localStorage)
- **Play button**: terracotta, full card-width, 110px height
- **Stats + Settings row**: sage secondary buttons, equal width, 85px height
- **Divider**: subtle horizontal rule
- **Copyright**: "©2026 Lux Spark" — muted, bottom center

Auth panel omitted (separate issue).

### Loading States on the Play Button

| Prefetch state | Button label | Clickable? |
|---|---|---|
| loading | Play | Yes — shows inline progress if clicked |
| ready | Play | Yes — starts game |
| error | Retry | Yes — retries prefetch |
| transitioning | Starting… | No |

The progress bar (already implemented) only appears if loading takes > 1.5s or user clicks Play while still loading.

---

## Section 2: React Stats Screen

### Data Sources

| Data | Source | Fallback |
|---|---|---|
| Records (high score, longest word, max WPM) | Supabase `profiles` | localStorage |
| Totals (words, tiles, time) | Supabase `profiles` | localStorage |
| History chart (last 10 sessions) | Supabase `sessions` | localStorage |
| Leaderboard (top 20) | Supabase `leaderboards` | — |
| Averages | Computed from sessions | Computed from localStorage |

### UI Layout

```
← Back          Stats         [Share]  [Reset]

Records
  High Score      12,450
  Longest Word    QUARTZ
  Max WPM         8.4

Totals
  Words Found     1,240
  Tiles Cleared   3,892
  Time Played     4h 12m

Averages
  Games Played    42
  Avg Score       8,230
  Avg WPM         5.2

[History Chart — bar chart, last 10 sessions]

Leaderboard
  1. Anonymous   45,200
  2. player2     38,100
  …
```

### Guest Users

For unauthenticated users, all data comes from `localStorage('word-loom-stats')` (a JSON blob written by Godot after each game). The leaderboard section is hidden for guests.

---

## Section 3: React Settings Screen

Reads/writes localStorage keys that Godot already monitors:

| Setting | localStorage key | Values |
|---|---|---|
| Theme | `word-loom-theme` | `light` / `dark` |
| Language | `word-loom-language` | `en` / `es` |
| Difficulty | `word-loom-difficulty` | `normal` / `hard` |

Theme is already synced via `ThemeManager.gd`. Language and difficulty get the same treatment.

### UI Layout

```
← Back        Settings

Theme
  ○ Light   ● Dark

Language
  ○ English   ○ Español

Difficulty
  ○ Normal   ○ Hard
```

Changes apply immediately in React (background/colors update live) and persist to localStorage for Godot to read on next boot.

---

## Section 4: Supabase Schema Extension

```sql
-- Extend profiles with richer stats
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS longest_word TEXT,
  ADD COLUMN IF NOT EXISTS max_wpm FLOAT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_tiles INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_time FLOAT DEFAULT 0;

-- Session history for chart data
CREATE TABLE IF NOT EXISTS public.sessions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INTEGER NOT NULL DEFAULT 0,
  wpm FLOAT DEFAULT 0,
  words_found INTEGER DEFAULT 0,
  duration FLOAT DEFAULT 0,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  difficulty TEXT,
  language TEXT
);

-- RLS for sessions
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own sessions"
  ON public.sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions"
  ON public.sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
```

---

## Section 5: Godot Changes

### 5a. Boot Flow

Add `Boot.tscn` + `Boot.gd` as the new main scene:

```gdscript
# Boot.gd
extends Node

func _ready() -> void:
    if OS.has_feature("web"):
        get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
    else:
        get_tree().change_scene_to_file("res://scenes/Home.tscn")
```

`Home.tscn` is preserved unchanged for desktop/editor use. `project.godot` main scene changes to `Boot.tscn`.

### 5b. StatsManager — Extended Supabase Sync

`push_stats_to_supabase()` gains the new fields:

```gdscript
var data = {
    "id": user_id,
    "high_score": high_score,
    "total_words": total_words_found,
    "longest_word": longest_word,
    "max_wpm": max_wpm,
    "total_tiles": total_tiles_cleared,
    "total_time": total_time_played,
    "last_sync": Time.get_datetime_string_from_system(true)
}
```

`end_session()` also calls a new `push_session_to_supabase(session_record)` to insert into the `sessions` table.

### 5c. Guest localStorage Bridge

`save_stats()` also writes a JSON blob for unauthenticated users:

```gdscript
if OS.has_feature("web"):
    var js = JavaScriptBridge.get_interface("localStorage")
    if js:
        js.setItem("word-loom-stats", JSON.stringify({
            "high_score": high_score,
            "longest_word": longest_word,
            "max_wpm": max_wpm,
            "total_words": total_words_found,
            "total_tiles": total_tiles_cleared,
            "total_time": total_time_played,
            "session_history": session_history
        }))
```

### 5d. Settings localStorage Sync

`GameSettings.gd` gains `save_to_localstorage()` / `load_from_localstorage()` (mirrors `ThemeManager`'s existing localStorage pattern) for language and difficulty.

---

## Data Flow Summary

```
React Settings → localStorage ──────────────────────→ Godot reads on boot
                                                        (theme: already working)
                                                        (language, difficulty: new)

Godot game ends → StatsManager.end_session()
    → push_stats_to_supabase()      ──→ Supabase profiles + sessions
    → push_session_to_supabase()    ──→ Supabase sessions
    → save_stats() localStorage     ──→ localStorage('word-loom-stats')
                                         (guest fallback)

React Stats page → Supabase profiles  (records + totals)
                 → Supabase sessions  (history chart)
                 → Supabase leaderboards (top 20)
                 → localStorage fallback (guests)
```

---

## Success Metrics

- **Zero visible loading bars** for returning users (assets cached)
- **Play button clickable instantly** (React renders in < 1s)
- **Visual parity**: user cannot tell when React ends and Godot begins
- **Stats page works** for both authenticated and guest users
- **Settings persist** across React and Godot sessions

---

## Out of Scope

- Google / Apple auth integration (separate issue)
- Service worker / offline support
- Animated preview or screenshots on Home
- `HowToPlay` section

---

## Implementation Order

1. Supabase schema migration
2. React Home Screen redesign (visual parity)
3. React routing (Home / Stats / Settings state)
4. React Stats Screen
5. React Settings Screen
6. Godot: Boot scene + skip Home on web
7. Godot: Extended StatsManager sync (Supabase + localStorage)
8. Godot: GameSettings localStorage sync for language + difficulty
9. End-to-end testing
