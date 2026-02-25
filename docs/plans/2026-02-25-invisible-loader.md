# Invisible Loader — React Shell Unification Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** React Shell becomes the full navigation layer (Home, Stats, Settings); Godot boots directly into the game, with heavy assets (~88MB WASM + PCK) prefetched silently in the background so the Play button feels instant.

**Architecture:** State-based routing in `App.jsx` (no React Router) drives three screens. Existing `PrefetchManager` + `GodotLauncher` infrastructure is preserved untouched. Stats flow through Supabase (authenticated) and `localStorage('word-loom-stats')` (guest). Godot adds a `Boot.gd` scene to skip `Home.tscn` on web builds.

**Tech Stack:** React 18, Vite, Supabase JS v2, Vitest + React Testing Library (new), GDScript

**⚠️ Known discrepancy:** `landing/src/services/storage.js` queries a `user_stats` table, but `supabase_schema.sql` defines `profiles`. The Stats service in this plan reads from `profiles` (correct table). The old `StorageManager` high-score path is left unchanged for now.

---

### Task 1: Add test infrastructure

**Files:**
- Modify: `landing/package.json`
- Modify: `landing/vite.config.js`
- Create: `landing/src/test-setup.js`

**Step 1: Install Vitest + React Testing Library**

```bash
cd /home/uli/Projects/word-loom/landing
npm install -D vitest jsdom @testing-library/react @testing-library/jest-dom
```

**Step 2: Update vite.config.js**

Current `landing/vite.config.js`:
```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
```

Replace with:
```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test-setup.js',
  },
})
```

**Step 3: Create test setup file**

Create `landing/src/test-setup.js`:
```js
import '@testing-library/jest-dom'
```

**Step 4: Add test scripts to package.json**

In `landing/package.json` `"scripts"`:
```json
"test": "vitest run",
"test:watch": "vitest"
```

**Step 5: Verify setup**

```bash
cd /home/uli/Projects/word-loom/landing && npm test
```
Expected output: `No test files found`

**Step 6: Commit**

```bash
git add landing/package.json landing/vite.config.js landing/src/test-setup.js landing/package-lock.json
git commit -m "chore: add Vitest + RTL test infrastructure to landing app (#143)"
```

---

### Task 2: Supabase schema migration

**Files:**
- Modify: `supabase_schema.sql`
- Create: `docs/migrations/2026-02-25-extend-stats.sql`

**Step 1: Create migration file**

Create `docs/migrations/2026-02-25-extend-stats.sql`:

```sql
-- Extend profiles table with richer stats columns
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS longest_word TEXT,
  ADD COLUMN IF NOT EXISTS max_wpm FLOAT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_tiles INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_time FLOAT DEFAULT 0;

-- Session history table (for React Stats history chart)
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

**Step 2: Run migration in Supabase**

1. Open your Supabase project → SQL Editor
2. Paste and run the migration SQL above
3. In Table Editor: verify `profiles` now has `longest_word`, `max_wpm`, `total_tiles`, `total_time` columns
4. Verify `sessions` table exists with correct columns

**Step 3: Append migration to supabase_schema.sql**

Add the migration SQL to the bottom of `supabase_schema.sql` so the file reflects the current full schema.

**Step 4: Commit**

```bash
mkdir -p docs/migrations
git add supabase_schema.sql docs/migrations/2026-02-25-extend-stats.sql
git commit -m "feat: extend Supabase schema with rich stats + sessions table (#143)"
```

---

### Task 3: SettingsService

**Files:**
- Create: `landing/src/services/settings.js`
- Create: `landing/src/services/__tests__/settings.test.js`

Manages the three localStorage keys that both React and Godot share.

**Step 1: Write the failing test**

Create `landing/src/services/__tests__/settings.test.js`:

```js
import { describe, it, expect, beforeEach } from 'vitest'
import { getSettings, saveSettings, DEFAULTS } from '../settings.js'

beforeEach(() => localStorage.clear())

describe('getSettings', () => {
  it('returns defaults when nothing is saved', () => {
    const s = getSettings()
    expect(s.theme).toBe('light')
    expect(s.language).toBe('en')
    expect(s.difficulty).toBe('normal')
  })

  it('reads saved values', () => {
    localStorage.setItem('word-loom-theme', 'dark')
    localStorage.setItem('word-loom-language', 'es')
    localStorage.setItem('word-loom-difficulty', 'hard')
    const s = getSettings()
    expect(s.theme).toBe('dark')
    expect(s.language).toBe('es')
    expect(s.difficulty).toBe('hard')
  })

  it('ignores invalid values and returns default', () => {
    localStorage.setItem('word-loom-theme', 'banana')
    expect(getSettings().theme).toBe('light')
  })
})

describe('saveSettings', () => {
  it('writes all three keys', () => {
    saveSettings({ theme: 'dark', language: 'es', difficulty: 'hard' })
    expect(localStorage.getItem('word-loom-theme')).toBe('dark')
    expect(localStorage.getItem('word-loom-language')).toBe('es')
    expect(localStorage.getItem('word-loom-difficulty')).toBe('hard')
  })

  it('partial update does not clobber other keys', () => {
    saveSettings({ theme: 'dark', language: 'en', difficulty: 'normal' })
    saveSettings({ theme: 'light' })
    expect(localStorage.getItem('word-loom-theme')).toBe('light')
    expect(localStorage.getItem('word-loom-language')).toBe('en')
  })
})
```

**Step 2: Run to verify failure**

```bash
cd /home/uli/Projects/word-loom/landing && npm test
```
Expected: FAIL — `Cannot find module '../settings.js'`

**Step 3: Implement settings.js**

Create `landing/src/services/settings.js`:

```js
const KEYS = {
  theme: 'word-loom-theme',
  language: 'word-loom-language',
  difficulty: 'word-loom-difficulty',
}

export const DEFAULTS = {
  theme: 'light',
  language: 'en',
  difficulty: 'normal',
}

const VALID = {
  theme: ['light', 'dark'],
  language: ['en', 'es'],
  difficulty: ['normal', 'hard'],
}

export function getSettings() {
  const result = {}
  for (const [key, storageKey] of Object.entries(KEYS)) {
    const saved = localStorage.getItem(storageKey)
    result[key] = VALID[key].includes(saved) ? saved : DEFAULTS[key]
  }
  return result
}

export function saveSettings(partial) {
  for (const [key, value] of Object.entries(partial)) {
    if (KEYS[key] && VALID[key]?.includes(value)) {
      localStorage.setItem(KEYS[key], value)
    }
  }
}
```

**Step 4: Run tests to verify pass**

```bash
cd /home/uli/Projects/word-loom/landing && npm test
```
Expected: All tests PASS

**Step 5: Commit**

```bash
git add landing/src/services/settings.js landing/src/services/__tests__/settings.test.js
git commit -m "feat: add SettingsService with localStorage persistence (#143)"
```

---

### Task 4: StatsService

**Files:**
- Create: `landing/src/services/statsService.js`
- Create: `landing/src/services/__tests__/statsService.test.js`

**Step 1: Write the failing tests**

Create `landing/src/services/__tests__/statsService.test.js`:

```js
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { StatsService, EMPTY_STATS } from '../statsService.js'

beforeEach(() => {
  localStorage.clear()
  vi.clearAllMocks()
})

describe('StatsService.getStats', () => {
  it('returns empty stats when nothing saved', async () => {
    const s = new StatsService(null)
    const stats = await s.getStats()
    expect(stats.high_score).toBe(0)
    expect(stats.total_words).toBe(0)
    expect(stats.session_history).toEqual([])
  })

  it('reads guest stats from localStorage', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({
      high_score: 1234,
      longest_word: 'QUARTZ',
      total_words: 42,
      session_history: [{ score: 1234, wpm: 5.2 }],
    }))
    const s = new StatsService(null)
    const stats = await s.getStats()
    expect(stats.high_score).toBe(1234)
    expect(stats.longest_word).toBe('QUARTZ')
    expect(stats.session_history).toHaveLength(1)
  })

  it('merges EMPTY_STATS defaults for missing keys', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 500 }))
    const s = new StatsService(null)
    const stats = await s.getStats()
    expect(stats.high_score).toBe(500)
    expect(stats.total_tiles).toBe(0)  // default filled in
  })
})

describe('StatsService.formatTime', () => {
  const s = new StatsService(null)
  it('formats hours and minutes', () => expect(s.formatTime(3661)).toBe('1h 1m'))
  it('formats minutes only', () => expect(s.formatTime(90)).toBe('1m'))
  it('shows <1m for short durations', () => expect(s.formatTime(30)).toBe('<1m'))
})

describe('StatsService.getShareText', () => {
  it('formats stats as copyable text', () => {
    const s = new StatsService(null)
    const text = s.getShareText({ high_score: 1000, longest_word: 'QUARTZ', max_wpm: 6.5, total_words: 42, total_tiles: 100, total_time: 90 })
    expect(text).toContain('High Score: 1000')
    expect(text).toContain('Longest Word: QUARTZ')
  })
})
```

**Step 2: Run to verify failure**

```bash
cd /home/uli/Projects/word-loom/landing && npm test
```
Expected: FAIL — `Cannot find module '../statsService.js'`

**Step 3: Implement statsService.js**

Create `landing/src/services/statsService.js`:

```js
const LOCAL_STATS_KEY = 'word-loom-stats'

export const EMPTY_STATS = {
  high_score: 0,
  longest_word: '',
  max_wpm: 0,
  total_words: 0,
  total_tiles: 0,
  total_time: 0,
  session_history: [],
}

export class StatsService {
  constructor(supabaseClient) {
    this.supabase = supabaseClient
  }

  async getStats(userId = null) {
    if (this.supabase && userId) {
      try {
        const [profile, sessions] = await Promise.all([
          this._fetchProfile(userId),
          this._fetchSessions(userId),
        ])
        if (profile) return { ...EMPTY_STATS, ...profile, session_history: sessions }
      } catch (err) {
        console.warn('Supabase stats fetch failed, using localStorage fallback', err)
      }
    }
    return this._getLocalStats()
  }

  async getLeaderboard(limit = 20) {
    if (!this.supabase) return []
    try {
      const { data, error } = await this.supabase
        .from('leaderboards')
        .select('score, profiles(display_name)')
        .order('score', { ascending: false })
        .limit(limit)
      if (error) throw error
      return data ?? []
    } catch (err) {
      console.warn('Leaderboard fetch failed', err)
      return []
    }
  }

  async resetStats() {
    localStorage.removeItem(LOCAL_STATS_KEY)
  }

  getShareText(stats) {
    return [
      'Word Loom Stats',
      '━━━━━━━━━━━━━━━',
      `High Score: ${stats.high_score}`,
      `Longest Word: ${stats.longest_word || '—'}`,
      `Max WPM: ${stats.max_wpm?.toFixed(1) ?? '0.0'}`,
      '',
      `Total Words: ${stats.total_words}`,
      `Total Tiles: ${stats.total_tiles}`,
      `Time Played: ${this.formatTime(stats.total_time ?? 0)}`,
    ].join('\n')
  }

  formatTime(seconds) {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    if (h > 0) return `${h}h ${m}m`
    if (m > 0) return `${m}m`
    return '<1m'
  }

  _getLocalStats() {
    try {
      const raw = localStorage.getItem(LOCAL_STATS_KEY)
      if (!raw) return { ...EMPTY_STATS }
      return { ...EMPTY_STATS, ...JSON.parse(raw) }
    } catch {
      return { ...EMPTY_STATS }
    }
  }

  async _fetchProfile(userId) {
    const { data, error } = await this.supabase
      .from('profiles')
      .select('high_score, longest_word, max_wpm, total_words, total_tiles, total_time')
      .eq('id', userId)
      .single()
    if (error) throw error
    return data
  }

  async _fetchSessions(userId) {
    const { data, error } = await this.supabase
      .from('sessions')
      .select('score, wpm, words_found, duration, timestamp')
      .eq('user_id', userId)
      .order('timestamp', { ascending: false })
      .limit(10)
    if (error) return []
    return data ?? []
  }
}
```

**Step 4: Run tests to verify pass**

```bash
cd /home/uli/Projects/word-loom/landing && npm test
```
Expected: All tests PASS (6 tests)

**Step 5: Commit**

```bash
git add landing/src/services/statsService.js landing/src/services/__tests__/statsService.test.js
git commit -m "feat: add StatsService with Supabase + localStorage fallback (#143)"
```

---

### Task 5: React routing scaffold

**Files:**
- Modify: `landing/src/App.jsx`
- Create: `landing/src/screens/HomeScreen.jsx`
- Create: `landing/src/screens/StatsScreen.jsx` (stub)
- Create: `landing/src/screens/SettingsScreen.jsx` (stub)

**Step 1: Create HomeScreen.jsx**

Extract the existing JSX from `App.jsx` (lines 147–190) into `landing/src/screens/HomeScreen.jsx`:

```jsx
import React from 'react'

export function HomeScreen({ state, onPlayClick, onStatsClick, onSettingsClick }) {
  return (
    <div className={`landing-container theme-${state.theme}`} style={{ opacity: state.transitioning ? 0 : 1, transition: 'opacity 500ms ease-out' }}>
      <div className="landing-content">
        <div className="hero">
          <h1 className="logo">Word Loom</h1>
          <p className="tagline">Word-building meets Tetris</p>
        </div>

        {state.highScore !== null && (
          <div className="high-score-badge">
            <div className="badge-label">Your Best</div>
            <div className="badge-score">{state.highScore.toLocaleString()}</div>
          </div>
        )}

        {state.prefetchStatus === 'loading' && state.showProgress && (
          <div className="progress-container">
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${state.prefetchProgress}%` }} />
            </div>
            <div className="progress-text">Loading... {state.prefetchProgress}%</div>
          </div>
        )}

        {state.error && (
          <div className="error-container">
            <div className="error-message">{state.error}</div>
            {state.prefetchStatus === 'error' && (
              <button className="retry-button" onClick={state.onRetry}>Retry</button>
            )}
          </div>
        )}

        <button className="play-button" onClick={onPlayClick} disabled={state.transitioning}>
          {state.transitioning ? 'Starting...' :
           (state.prefetchStatus === 'loading' && state.showProgress) ? 'Loading...' : 'Play'}
        </button>

        <div className="secondary-buttons">
          <button className="secondary-button" onClick={onStatsClick}>Stats</button>
          <button className="secondary-button" onClick={onSettingsClick}>Settings</button>
        </div>
      </div>
    </div>
  )
}
```

**Step 2: Create stub screens**

Create `landing/src/screens/StatsScreen.jsx`:
```jsx
export function StatsScreen({ theme, onBack }) {
  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="landing-content">
        <button onClick={onBack}>← Back</button>
        <p>Stats — coming in next task</p>
      </div>
    </div>
  )
}
```

Create `landing/src/screens/SettingsScreen.jsx`:
```jsx
export function SettingsScreen({ theme, onBack, onThemeChange }) {
  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="landing-content">
        <button onClick={onBack}>← Back</button>
        <p>Settings — coming in next task</p>
      </div>
    </div>
  )
}
```

**Step 3: Refactor App.jsx**

In `App.jsx`:

1. Add `currentScreen: 'home'` to the initial state object (line 22–30)
2. Add `onRetry` to state so `HomeScreen` can call `startPrefetch`:
   - Pass `onRetry: startPrefetch` in the `state` prop, or pass it as a separate prop
3. Remove the `ref={landingRef}` from the container div (it moves to `HomeScreen`)
4. Replace the return statement (lines 147–190) with:

```jsx
import { HomeScreen } from './screens/HomeScreen.jsx'
import { StatsScreen } from './screens/StatsScreen.jsx'
import { SettingsScreen } from './screens/SettingsScreen.jsx'

// In the return:
return (
  <>
    {state.currentScreen === 'home' && (
      <div ref={landingRef}>
        <HomeScreen
          state={{ ...state, onRetry: startPrefetch }}
          onPlayClick={handlePlayClick}
          onStatsClick={() => setState(prev => ({ ...prev, currentScreen: 'stats' }))}
          onSettingsClick={() => setState(prev => ({ ...prev, currentScreen: 'settings' }))}
        />
      </div>
    )}
    {state.currentScreen === 'stats' && (
      <StatsScreen
        theme={state.theme}
        onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
      />
    )}
    {state.currentScreen === 'settings' && (
      <SettingsScreen
        theme={state.theme}
        onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
        onThemeChange={(theme) => setState(prev => ({ ...prev, theme }))}
      />
    )}
  </>
)
```

**Step 4: Verify app builds and navigates**

```bash
cd /home/uli/Projects/word-loom/landing && npm run dev
```

Open browser. Verify:
- [ ] Home screen shows with Play / Stats / Settings buttons
- [ ] Stats button shows stub screen
- [ ] Settings button shows stub screen
- [ ] Back button returns to Home from both

**Step 5: Commit**

```bash
git add landing/src/App.jsx landing/src/screens/
git commit -m "refactor: extract screens + add state-based routing to App.jsx (#143)"
```

---

### Task 6: HomeScreen visual redesign

**Files:**
- Modify: `landing/src/screens/HomeScreen.jsx`
- Modify: `landing/src/App.css`
- Modify: `landing/index.html`

**Step 1: Add Inter font to index.html**

In `landing/index.html`, inside `<head>`, add before `</head>`:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
```

Also in the inline `<style>` block, update `body`:
```css
body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  /* keep other rules unchanged */
}
```

**Step 2: Update HomeScreen.jsx with card layout**

Replace `landing/src/screens/HomeScreen.jsx`:

```jsx
import React from 'react'

export function HomeScreen({ state, onPlayClick, onStatsClick, onSettingsClick }) {
  return (
    <div className={`landing-container theme-${state.theme}`}
         style={{ opacity: state.transitioning ? 0 : 1, transition: 'opacity 500ms ease-out' }}>

      {/* Decorative tiles — matches Godot's DecorativePattern */}
      <div className="decorative-pattern" aria-hidden="true">
        <div className="letter-tile tile-1" />
        <div className="letter-tile tile-2" />
        <div className="letter-tile tile-3" />
        <div className="letter-tile tile-4" />
      </div>

      {/* Main card */}
      <div className="main-card">
        <div className="title-section">
          <h1 className="logo">Word Loom</h1>
          <p className="tagline">Word-building meets Tetris</p>
          {state.highScore > 0 && (
            <p className="high-score-text">Best: {state.highScore.toLocaleString()}</p>
          )}
        </div>

        {state.prefetchStatus === 'loading' && state.showProgress && (
          <div className="progress-container">
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${state.prefetchProgress}%` }} />
            </div>
            <div className="progress-text">Loading... {state.prefetchProgress}%</div>
          </div>
        )}

        {state.error && (
          <div className="error-container">
            <div className="error-message">{state.error}</div>
            {state.prefetchStatus === 'error' && (
              <button className="retry-button" onClick={state.onRetry}>Retry</button>
            )}
          </div>
        )}

        <button className="play-button" onClick={onPlayClick} disabled={state.transitioning}>
          {state.transitioning ? 'Starting…' :
           (state.prefetchStatus === 'loading' && state.showProgress) ? 'Loading…' : 'Play'}
        </button>

        <div className="secondary-buttons">
          <button className="secondary-button" onClick={onStatsClick}>Stats</button>
          <button className="secondary-button" onClick={onSettingsClick}>Settings</button>
        </div>

        <div className="card-divider" />
        <p className="copyright">©2026 Lux Spark</p>
      </div>
    </div>
  )
}
```

**Step 3: Add card + decorative styles to App.css**

Append to the bottom of `landing/src/App.css`:

```css
/* ===== Main Card (matches Godot MainCardPanel) ===== */

.landing-container {
  /* override: remove old padding-based centering */
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100dvh;
  width: 100vw;
  background: var(--bg-primary);
  transition: opacity 500ms ease-out;
  padding: 24px;
  overflow-y: auto;
}

.main-card {
  background: var(--bg-card);
  border-radius: 24px;
  box-shadow: 0 8px 20px var(--shadow);
  padding: 60px 50px;
  width: 100%;
  max-width: 520px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 32px;
  position: relative;
  z-index: 1;
}

/* ===== Title section ===== */

.title-section {
  text-align: center;
}

/* Override .logo to be larger (matches Godot's 104px Title) */
.main-card .logo {
  font-size: clamp(48px, 10vw, 80px);
  text-align: center;
}

.main-card .tagline {
  font-size: clamp(16px, 3vw, 22px);
  text-align: center;
}

.high-score-text {
  font-size: clamp(18px, 3.5vw, 28px);
  font-weight: 700;
  color: var(--color-primary);
  margin: 8px 0 0 0;
  text-align: center;
}

/* ===== Secondary buttons row ===== */

.secondary-buttons {
  display: flex;
  gap: 20px;
  width: 100%;
}

.secondary-button {
  flex: 1;
  background: var(--color-secondary);
  color: var(--text-on-primary);
  font-family: inherit;
  font-size: clamp(18px, 3vw, 28px);
  font-weight: 700;
  height: 85px;
  min-height: 85px;
  border: none;
  border-radius: 14px;
  cursor: pointer;
  transition: all 150ms ease;
  box-shadow: 0 3px 8px var(--shadow);
}

.secondary-button:hover {
  filter: brightness(1.08);
  transform: translateY(-2px);
}

.secondary-button:active {
  filter: brightness(0.95);
  transform: translateY(0);
}

/* Play button height override (matches Godot's 110px) */
.play-button {
  height: 110px;
  min-height: 110px;
  font-size: clamp(24px, 5vw, 48px);
}

/* ===== Divider + Copyright ===== */

.card-divider {
  width: 100%;
  height: 1px;
  background: var(--border-neutral);
  opacity: 0.5;
}

.copyright {
  font-size: 14px;
  color: var(--text-muted);
  opacity: 0.5;
  margin: 0;
  text-align: center;
}

/* ===== Decorative background tiles ===== */
/* Matches Godot's DecorativePattern — 4 subtle squares at corners */

.decorative-pattern {
  position: fixed;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.letter-tile {
  position: absolute;
  width: 60px;
  height: 60px;
  border-radius: 6px;
}

.tile-1 { background: var(--color-secondary); opacity: 0.08; top: 100px; left: 50px; transform: rotate(10deg); }
.tile-2 { background: var(--color-primary);   opacity: 0.08; top: 200px; right: 50px; transform: rotate(-15deg); }
.tile-3 { background: var(--color-secondary); opacity: 0.08; bottom: 160px; left: 80px; transform: rotate(20deg); }
.tile-4 { background: var(--color-primary);   opacity: 0.08; bottom: 100px; right: 60px; transform: rotate(-10deg); }

/* ===== Mobile card adjustments ===== */

@media (max-width: 560px) {
  .main-card {
    padding: 40px 24px;
    gap: 24px;
  }
  .secondary-button {
    height: 70px;
    min-height: 70px;
  }
  .play-button {
    height: 88px;
    min-height: 88px;
  }
}
```

**Step 4: Visual verification**

```bash
cd /home/uli/Projects/word-loom/landing && npm run dev
```

Check against `godot/scenes/Home.tscn` values. Verify:
- [ ] White card centered on background (dark: `#2B3D4F`, light: `#F5F2E8`)
- [ ] 4 decorative tiles at corners (barely visible, < 10% opacity)
- [ ] Inter font on title + buttons
- [ ] Play button is large and orange (~110px tall)
- [ ] Stats + Settings row same width (sage green, ~85px tall)
- [ ] Divider + copyright at card bottom
- [ ] Toggle `localStorage.setItem('word-loom-theme','dark')` + refresh → dark mode correct

**Step 5: Commit**

```bash
git add landing/src/screens/HomeScreen.jsx landing/src/App.css landing/index.html
git commit -m "feat: HomeScreen visual parity with Godot Home.tscn (#143)"
```

---

### Task 7: SettingsScreen

**Files:**
- Modify: `landing/src/screens/SettingsScreen.jsx`
- Modify: `landing/src/App.css`

**Step 1: Replace SettingsScreen stub**

Replace `landing/src/screens/SettingsScreen.jsx`:

```jsx
import React, { useState } from 'react'
import { getSettings, saveSettings } from '../services/settings.js'

export function SettingsScreen({ theme, onBack, onThemeChange }) {
  const [settings, setSettings] = useState(() => getSettings())

  function handleChange(key, value) {
    const updated = { ...settings, [key]: value }
    setSettings(updated)
    saveSettings({ [key]: value })
    if (key === 'theme') onThemeChange(value)
  }

  const groups = [
    {
      key: 'theme',
      label: 'Theme',
      options: [{ value: 'light', label: 'Light' }, { value: 'dark', label: 'Dark' }],
    },
    {
      key: 'language',
      label: 'Language',
      options: [{ value: 'en', label: 'English' }, { value: 'es', label: 'Español' }],
    },
    {
      key: 'difficulty',
      label: 'Difficulty',
      options: [{ value: 'normal', label: 'Normal' }, { value: 'hard', label: 'Hard' }],
    },
  ]

  return (
    <div className={`landing-container theme-${settings.theme}`}>
      <div className="main-card">
        <div className="screen-header">
          <button className="back-button" onClick={onBack}>← Back</button>
          <h2 className="screen-title">Settings</h2>
        </div>

        {groups.map((group, i) => (
          <React.Fragment key={group.key}>
            {i > 0 && <div className="card-divider" />}
            <div className="settings-group">
              <span className="settings-label">{group.label}</span>
              <div className="radio-group">
                {group.options.map(opt => (
                  <label
                    key={opt.value}
                    className={`radio-option ${settings[group.key] === opt.value ? 'selected' : ''}`}
                  >
                    <input
                      type="radio"
                      name={group.key}
                      value={opt.value}
                      checked={settings[group.key] === opt.value}
                      onChange={() => handleChange(group.key, opt.value)}
                    />
                    {opt.label}
                  </label>
                ))}
              </div>
            </div>
          </React.Fragment>
        ))}
      </div>
    </div>
  )
}
```

**Step 2: Add settings + shared screen CSS to App.css**

Append to `landing/src/App.css`:

```css
/* ===== Shared screen chrome ===== */

.screen-header {
  display: flex;
  align-items: center;
  width: 100%;
  gap: 16px;
}

.back-button {
  background: none;
  border: none;
  color: var(--color-primary);
  font-family: inherit;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  padding: 8px 0;
  min-height: 44px;
}

.screen-title {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
  flex: 1;
  text-align: center;
}

/* ===== Settings screen ===== */

.settings-group {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.settings-label {
  font-size: 13px;
  font-weight: 700;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.radio-group {
  display: flex;
  gap: 12px;
}

.radio-option {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px;
  border: 2px solid var(--border-neutral);
  border-radius: 12px;
  cursor: pointer;
  font-family: inherit;
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  transition: all 150ms ease;
}

.radio-option.selected {
  border-color: var(--color-primary);
  background: var(--bg-primary);
  color: var(--color-primary);
}

.radio-option input[type="radio"] {
  display: none;
}
```

**Step 3: Visual verification**

```bash
cd /home/uli/Projects/word-loom/landing && npm run dev
```

Verify:
- [ ] Switching theme immediately updates background color (live)
- [ ] Persists on Back → Settings (still selected)
- [ ] Language + Difficulty selections persist (check localStorage in DevTools)

**Step 4: Commit**

```bash
git add landing/src/screens/SettingsScreen.jsx landing/src/App.css
git commit -m "feat: SettingsScreen with live theme switching (#143)"
```

---

### Task 8: StatsScreen

**Files:**
- Modify: `landing/src/screens/StatsScreen.jsx`
- Modify: `landing/src/App.css`

**Step 1: Replace StatsScreen stub**

Replace `landing/src/screens/StatsScreen.jsx`:

```jsx
import React, { useState, useEffect, useRef } from 'react'
import { createClient } from '@supabase/supabase-js'
import { StatsService } from '../services/statsService.js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_KEY
const supabase = supabaseUrl && !supabaseUrl.includes('placeholder')
  ? createClient(supabaseUrl, supabaseKey) : null

const statsService = new StatsService(supabase)

export function StatsScreen({ theme, onBack }) {
  const [stats, setStats] = useState(null)
  const [leaderboard, setLeaderboard] = useState([])
  const [copied, setCopied] = useState(false)
  const [showReset, setShowReset] = useState(false)
  const chartRef = useRef(null)

  useEffect(() => {
    statsService.getStats().then(setStats)
    statsService.getLeaderboard().then(setLeaderboard)
  }, [])

  useEffect(() => {
    if (stats?.session_history && chartRef.current) {
      drawChart(chartRef.current, stats.session_history, theme)
    }
  }, [stats, theme])

  function drawChart(canvas, history, currentTheme) {
    const ctx = canvas.getContext('2d')
    const { width, height } = canvas
    ctx.clearRect(0, 0, width, height)
    const recent = history.slice(-10)
    if (!recent.length) return
    const maxScore = Math.max(...recent.map(s => s.score), 1)
    const barW = (width / recent.length) * 0.7
    const gap = (width / recent.length) * 0.3
    const accentHex = currentTheme === 'dark' ? '#F29170' : '#E07857'
    recent.forEach((s, i) => {
      const barH = (s.score / maxScore) * (height - 24)
      const x = i * (barW + gap) + gap / 2
      const y = height - barH - 20
      const alpha = Math.round((0.4 + (i / recent.length) * 0.6) * 255).toString(16).padStart(2, '0')
      ctx.fillStyle = accentHex + alpha
      ctx.beginPath()
      ctx.roundRect?.(x, y, barW, barH, 4) ?? ctx.rect(x, y, barW, barH)
      ctx.fill()
    })
  }

  function handleShare() {
    if (!stats) return
    navigator.clipboard.writeText(statsService.getShareText(stats))
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  async function handleReset() {
    await statsService.resetStats()
    setStats(await statsService.getStats())
    setShowReset(false)
  }

  if (!stats) {
    return (
      <div className={`landing-container theme-${theme}`}>
        <div className="main-card"><p className="tagline">Loading…</p></div>
      </div>
    )
  }

  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="main-card stats-card">
        <div className="screen-header">
          <button className="back-button" onClick={onBack}>← Back</button>
          <h2 className="screen-title">Stats</h2>
          <div className="header-actions">
            <button className="icon-button" onClick={handleShare}>{copied ? '✓' : 'Share'}</button>
            <button className="icon-button icon-button-danger" onClick={() => setShowReset(true)}>Reset</button>
          </div>
        </div>

        <div className="stats-section">
          <h3 className="stats-section-title">Records</h3>
          <StatRow label="High Score" value={(stats.high_score ?? 0).toLocaleString()} />
          <StatRow label="Longest Word" value={stats.longest_word || '—'} />
          <StatRow label="Max WPM" value={(stats.max_wpm ?? 0).toFixed(1)} />
        </div>

        <div className="card-divider" />

        <div className="stats-section">
          <h3 className="stats-section-title">Totals</h3>
          <StatRow label="Words Found" value={(stats.total_words ?? 0).toLocaleString()} />
          <StatRow label="Tiles Cleared" value={(stats.total_tiles ?? 0).toLocaleString()} />
          <StatRow label="Time Played" value={statsService.formatTime(stats.total_time ?? 0)} />
        </div>

        <div className="card-divider" />

        <div className="stats-section">
          <h3 className="stats-section-title">History</h3>
          {(stats.session_history?.length ?? 0) > 0
            ? <canvas ref={chartRef} className="history-chart" width={400} height={120} />
            : <p className="stats-empty">No games played yet</p>
          }
        </div>

        {leaderboard.length > 0 && (
          <>
            <div className="card-divider" />
            <div className="stats-section">
              <h3 className="stats-section-title">Leaderboard</h3>
              {leaderboard.map((entry, i) => (
                <div key={i} className="leaderboard-row">
                  <span className="lb-rank">{i + 1}.</span>
                  <span className="lb-name">{entry.profiles?.display_name ?? 'Anonymous'}</span>
                  <span className="lb-score">{(entry.score ?? 0).toLocaleString()}</span>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {showReset && (
        <div className="confirm-overlay">
          <div className="confirm-dialog">
            <p>Reset all stats? This cannot be undone.</p>
            <div className="confirm-actions">
              <button className="secondary-button" onClick={() => setShowReset(false)}>Cancel</button>
              <button className="play-button confirm-danger-button" onClick={handleReset}>Reset</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function StatRow({ label, value }) {
  return (
    <div className="stat-row">
      <span className="stat-label">{label}</span>
      <span className="stat-value">{value}</span>
    </div>
  )
}
```

**Step 2: Add Stats CSS to App.css**

Append to `landing/src/App.css`:

```css
/* ===== Stats screen ===== */

.stats-card {
  overflow-y: auto;
  max-height: 90dvh;
  gap: 24px;
}

.stats-section {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.stats-section-title {
  font-size: 12px;
  font-weight: 700;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 1px;
  margin: 0;
}

.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.stat-label {
  font-size: 16px;
  color: var(--text-secondary);
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
}

.stats-empty {
  font-size: 14px;
  color: var(--text-muted);
  text-align: center;
  margin: 0;
}

.history-chart {
  width: 100%;
  height: 120px;
  border-radius: 8px;
  background: var(--bg-primary);
}

.leaderboard-row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 16px;
  color: var(--text-primary);
}

.lb-rank { color: var(--text-muted); width: 24px; flex-shrink: 0; }
.lb-name { flex: 1; }
.lb-score { font-weight: 700; color: var(--color-primary); }

.header-actions {
  display: flex;
  gap: 8px;
}

.icon-button {
  background: none;
  border: 2px solid var(--border-neutral);
  color: var(--text-secondary);
  font-family: inherit;
  font-size: 13px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: 8px;
  cursor: pointer;
  min-height: 36px;
}

.icon-button-danger {
  color: var(--color-error);
  border-color: var(--color-error);
}

.confirm-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.confirm-dialog {
  background: var(--bg-card);
  border-radius: 16px;
  padding: 32px;
  max-width: 320px;
  width: 90%;
  display: flex;
  flex-direction: column;
  gap: 20px;
  font-size: 16px;
  color: var(--text-primary);
}

.confirm-actions {
  display: flex;
  gap: 12px;
}

.confirm-danger-button {
  background: var(--color-error) !important;
  height: 52px;
  min-height: 52px;
  font-size: 16px;
}
```

**Step 3: Visual verification**

```bash
cd /home/uli/Projects/word-loom/landing && npm run dev
```

Verify:
- [ ] Stats screen renders all sections (zeros / dashes for empty state)
- [ ] Share copies formatted text to clipboard (check DevTools Console → `navigator.clipboard.writeText`)
- [ ] Reset shows confirmation dialog, then clears
- [ ] Back returns to Home

**Step 4: Commit**

```bash
git add landing/src/screens/StatsScreen.jsx landing/src/App.css
git commit -m "feat: StatsScreen with records, history chart, leaderboard (#143)"
```

---

### Task 9: Godot — Boot scene

**Files:**
- Create: `godot/scripts/Boot.gd`
- Create: `godot/scenes/Boot.tscn`
- Modify: `godot/project.godot`

On web builds: skip `Home.tscn`, go straight to `LoomDrop.tscn`. In editor: go to `Home.tscn` (unchanged).

**Step 1: Create Boot.gd**

Create `godot/scripts/Boot.gd`:

```gdscript
extends Node
## Boot scene: routes to LoomDrop on web (React Shell owns navigation),
## or to Home on desktop/editor builds.

func _ready() -> void:
	GameSettings.load_from_localstorage()
	if OS.has_feature("web"):
		get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Home.tscn")
```

**Step 2: Create Boot.tscn**

Open Godot editor → Scene menu → New Scene → Add a `Node` root → name it `Boot` → attach `Boot.gd` → Save as `res://scenes/Boot.tscn`.

Or create the file directly:

```
godot/scenes/Boot.tscn
```

```
[gd_scene format=3 uid="uid://boot_scene_143"]

[ext_resource type="Script" path="res://scripts/Boot.gd" id="1"]

[node name="Boot" type="Node"]
script = ExtResource("1")
```

**Step 3: Update project.godot main scene**

In `godot/project.godot`, find and change:
```ini
run/main_scene="res://scenes/Home.tscn"
```
to:
```ini
run/main_scene="res://scenes/Boot.tscn"
```

**Step 4: Test in editor**

Press F5 in Godot. Verify: opens `Home.tscn` (editor is not `web` feature).

**Step 5: Commit**

```bash
git add godot/scripts/Boot.gd godot/scenes/Boot.tscn godot/project.godot
git commit -m "feat: Boot scene routes web builds to LoomDrop, editor to Home (#143)"
```

---

### Task 10: Godot — Extended StatsManager sync

**Files:**
- Modify: `godot/scripts/StatsManager.gd`

**Step 1: Extend push_stats_to_supabase with new schema columns**

In `godot/scripts/StatsManager.gd`, find `push_stats_to_supabase()` and update the `data` dictionary:

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

**Step 2: Add push_session_to_supabase**

After `push_stats_to_supabase()`, add:

```gdscript
func push_session_to_supabase(session_record: Dictionary) -> void:
	if not is_authenticated():
		return
	var data = {
		"user_id": _current_user.id,
		"score": session_record.get("score", 0),
		"wpm": session_record.get("wpm", 0.0),
		"words_found": session_record.get("words_found", 0),
		"duration": session_record.get("duration", 0.0),
		"timestamp": Time.get_datetime_string_from_system(true),
		"difficulty": session_record.get("difficulty", "normal"),
		"language": session_record.get("language", "en")
	}
	Supabase.database.query(SupabaseQuery.new().from("sessions").insert([data]))
```

**Step 3: Call push_session_to_supabase from end_session**

In `end_session()`, find the existing auth block and add the session push:

```gdscript
if is_authenticated():
    push_stats_to_supabase()
    submit_to_leaderboard(final_score)
    push_session_to_supabase(session_record)  # ← add this line
```

**Step 4: Add localStorage guest bridge to save_stats**

At the end of `save_stats()`, before the closing `}`, add:

```gdscript
	# Write guest-accessible JSON blob for React Stats page
	if OS.has_feature("web"):
		var js = JavaScriptBridge.get_interface("localStorage")
		if js:
			var blob = {
				"high_score": high_score,
				"longest_word": longest_word,
				"max_wpm": max_wpm,
				"total_words": total_words_found,
				"total_tiles": total_tiles_cleared,
				"total_time": total_time_played,
				"session_history": session_history
			}
			js.setItem("word-loom-stats", JSON.stringify(blob))
```

**Step 5: Commit**

```bash
git add godot/scripts/StatsManager.gd
git commit -m "feat: StatsManager syncs rich stats to Supabase + localStorage bridge (#143)"
```

---

### Task 11: Godot — GameSettings localStorage sync

**Files:**
- Modify: `godot/scripts/GameSettings.gd`

React's SettingsScreen writes `word-loom-language` and `word-loom-difficulty`. Godot reads them at boot so the game uses the correct language and difficulty.

**Step 1: Add load_from_localstorage to GameSettings.gd**

In `godot/scripts/GameSettings.gd`, replace the empty `_ready()` with:

```gdscript
func _ready() -> void:
	load_from_localstorage()

func load_from_localstorage() -> void:
	"""Read language and difficulty from localStorage (set by React SettingsScreen).
	Theme is handled separately by ThemeManager."""
	if not OS.has_feature("web"):
		return
	var js = JavaScriptBridge.get_interface("localStorage")
	if js == null:
		return
	var lang = js.getItem("word-loom-language")
	if lang == "en" or lang == "es":
		current_language = lang
	var diff = js.getItem("word-loom-difficulty")
	if diff == "normal" or diff == "hard":
		difficulty = diff
```

Note: `Boot.gd` also calls `GameSettings.load_from_localstorage()` explicitly before scene change, so settings are guaranteed to be loaded even if `GameSettings._ready()` runs after `Boot._ready()`.

**Step 2: Commit**

```bash
git add godot/scripts/GameSettings.gd
git commit -m "feat: GameSettings reads language/difficulty from localStorage on boot (#143)"
```

---

### Task 12: End-to-end verification

Manual test checklist. Run against `netlify dev` or a preview deploy.

**First visit (cold cache — throttle to "Fast 3G" in DevTools):**
- [ ] Home screen appears in < 1s (React renders immediately)
- [ ] Check Network tab: WASM + PCK start downloading in background
- [ ] Play, Stats, Settings buttons all clickable immediately
- [ ] No loading bar visible (assets load silently)
- [ ] Click Play while loading: inline "Loading… X%" appears in button area, then starts game when done

**Play flow:**
- [ ] Once assets are cached (second visit or after prefetch completes), click Play
- [ ] React fades out in ~500ms → Godot canvas appears → game starts with no blank screen
- [ ] No white flash during transition
- [ ] Game uses correct theme (set dark in Settings → game should have dark background)
- [ ] After game ends: open DevTools → Application → localStorage → verify `word-loom-stats` JSON is present and contains correct values

**Stats screen (after playing a game):**
- [ ] Navigate to Stats → correct high score displayed
- [ ] History chart shows bars for recent sessions
- [ ] Share → clipboard contains formatted stats text
- [ ] Reset → confirmation → stats clear to zero

**Settings screen:**
- [ ] Theme toggle → background changes live (no page reload needed)
- [ ] Language switch (en ↔ es) → persists after Back and Settings re-open
- [ ] Difficulty switch → persists
- [ ] Play game → game uses the language/difficulty set in Settings

**Returning visit (warm cache — no throttle):**
- [ ] WASM + PCK served from browser cache (Network tab shows "(disk cache)")
- [ ] Play button enables within ~1s
- [ ] Zero loading bars visible

**Mobile (test on real device or DevTools device emulation):**
- [ ] iPhone SE (375px): card fits, all buttons reachable, no horizontal scroll
- [ ] iPad (768px): card looks centered and well-proportioned
- [ ] All buttons meet 48px touch targets

**Godot editor (verify non-regression):**
- [ ] Press F5 in Godot → opens `Home.tscn` (not LoomDrop directly)
- [ ] Navigate Play → game works as before

---
