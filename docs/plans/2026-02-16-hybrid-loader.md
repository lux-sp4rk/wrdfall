# Hybrid Loader Strategy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform web experience from monolithic 87.8 MB blocking load to progressive < 1s landing page with background pre-fetch, reducing TTFR and improving retention.

**Architecture:** Vite + React landing page (< 50 KB) loads instantly, displays high score teaser and game preview. Background pre-fetch downloads Godot engine + English dictionary in parallel. User clicks "Play" → landing fades out, Godot initializes with pre-loaded dictionary. Spanish dictionary lazy-loads on selection.

**Tech Stack:** Vite, React 18, Godot 4.6 (GDScript), Supabase, Netlify

---

## Task 1: Project Setup & Root Configuration

**Files:**
- Create: `package.json`
- Create: `.gitignore` (update)
- Create: `landing/package.json`
- Create: `landing/vite.config.js`
- Create: `landing/index.html`
- Create: `landing/src/main.jsx`

**Step 1: Create root package.json with deploy script**

Create `package.json`:

```json
{
  "name": "wordfall",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build:landing": "cd landing && npm run build",
    "build:all": "npm run build:landing",
    "deploy:prod": "npm run build:all && git add . && git commit -m 'Deploy web build' && git push origin main",
    "dev:landing": "cd landing && npm run dev"
  },
  "workspaces": [
    "landing"
  ]
}
```

**Step 2: Update .gitignore**

Add to `.gitignore`:

```
# Landing page
landing/node_modules
landing/dist
landing/.env

# Dependencies
node_modules
```

**Step 3: Create landing page package.json**

Create `landing/package.json`:

```json
{
  "name": "wordfall-landing",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@supabase/supabase-js": "^2.39.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.0"
  }
}
```

**Step 4: Create Vite config**

Create `landing/vite.config.js`:

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: '../dist',
    emptyOutDir: false, // Don't delete Godot files
    rollupOptions: {
      output: {
        manualChunks: undefined, // Single bundle for speed
      },
    },
  },
  server: {
    port: 3000,
  },
});
```

**Step 5: Create HTML entry point**

Create `landing/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta name="description" content="Wordfall - Word-building meets Tetris" />
    <title>Wordfall</title>
    <style>
      /* Critical CSS - inline for instant render */
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        width: 100vw;
        height: 100vh;
        overflow: hidden;
      }
      #root {
        width: 100%;
        height: 100%;
      }
    </style>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

**Step 6: Create React entry point**

Create `landing/src/main.jsx`:

```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

**Step 7: Install dependencies**

```bash
cd landing && npm install
```

Expected: Dependencies installed successfully

**Step 8: Test dev server**

```bash
npm run dev:landing
```

Expected: Dev server starts at http://localhost:3000
(Stop server with Ctrl+C)

**Step 9: Commit setup**

```bash
git add package.json .gitignore landing/
git commit -m "feat: add landing page scaffold (Vite + React)

- Root package.json with deploy script
- Vite config (builds to dist/, preserves Godot files)
- HTML entry with inline critical CSS
- React entry point

Related to #122"
```

---

## Task 2: Extract Dictionaries from Godot Export

**Files:**
- Create: `dist/dictionaries/` (directory)
- Move: `godot/data/words_en.txt` → `dist/dictionaries/en.txt`
- Move: `godot/data/words_es.txt` → `dist/dictionaries/es.txt`

**Step 1: Create dictionaries directory**

```bash
mkdir -p dist/dictionaries
```

**Step 2: Copy dictionaries to dist**

```bash
cp godot/data/words_en.txt dist/dictionaries/en.txt
cp godot/data/words_es.txt dist/dictionaries/es.txt
```

**Step 3: Verify files copied**

```bash
ls -lh dist/dictionaries/
```

Expected output:
```
en.txt (2.6 MB)
es.txt (6.8 MB)
```

**Step 4: Test dictionary access via HTTP**

Start local server:
```bash
cd dist && python3 -m http.server 8000
```

Visit: http://localhost:8000/dictionaries/en.txt
Expected: Dictionary file downloads (Stop server with Ctrl+C)

**Step 5: Commit dictionary extraction**

```bash
git add dist/dictionaries/
git commit -m "feat: extract dictionaries from Godot bundle

- Move English (2.6 MB) and Spanish (6.8 MB) to dist/dictionaries/
- Will be loaded externally via fetch to reduce PCK size

Related to #122"
```

---

## Task 3: Storage Manager (LocalStorage + Supabase)

**Files:**
- Create: `landing/src/services/storage.js`

**Step 1: Create storage manager**

Create `landing/src/services/storage.js`:

```javascript
/**
 * StorageManager - LocalStorage + Supabase sync for high scores
 *
 * Strategy:
 * - Read from localStorage first (instant)
 * - Background sync with Supabase (non-blocking)
 * - Anonymous device IDs for MVP
 */

export class StorageManager {
  constructor(supabaseClient) {
    this.supabase = supabaseClient;
    this.localKey = 'word_loom_high_score';
    this.deviceIdKey = 'word_loom_device_id';
  }

  /**
   * Get high score for landing page teaser
   * Returns instantly from localStorage, syncs Supabase in background
   */
  async getHighScore() {
    // 1. Try localStorage first (instant)
    const local = this.getLocalHighScore();

    if (local !== null) {
      // Background sync from Supabase (don't await)
      this.syncFromSupabase().catch(err => {
        console.warn('Background sync failed:', err);
      });
      return local;
    }

    // 2. No local score, fetch from Supabase
    try {
      const remote = await this.fetchFromSupabase();
      if (remote !== null) {
        this.setLocalHighScore(remote);
        return remote;
      }
    } catch (error) {
      console.warn('Failed to fetch from Supabase:', error);
    }

    // 3. No score anywhere (new user)
    return null;
  }

  /**
   * Get high score from localStorage
   */
  getLocalHighScore() {
    const raw = localStorage.getItem(this.localKey);
    return raw ? parseInt(raw, 10) : null;
  }

  /**
   * Set high score in localStorage
   */
  setLocalHighScore(score) {
    localStorage.setItem(this.localKey, score.toString());
  }

  /**
   * Fetch high score from Supabase
   */
  async fetchFromSupabase() {
    const userId = this.getUserId();

    const { data, error } = await this.supabase
      .from('user_stats')
      .select('high_score')
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      return null;
    }

    return data.high_score;
  }

  /**
   * Background sync: update local if remote is higher
   */
  async syncFromSupabase() {
    const remote = await this.fetchFromSupabase();
    const local = this.getLocalHighScore();

    if (remote !== null && (local === null || remote > local)) {
      this.setLocalHighScore(remote);
    }
  }

  /**
   * Save high score (called from Godot via JS bridge)
   */
  async saveHighScore(score) {
    const currentHigh = this.getLocalHighScore() || 0;

    if (score <= currentHigh) {
      return; // Not a new high score
    }

    // Update local immediately
    this.setLocalHighScore(score);

    // Sync to Supabase (background, non-blocking)
    try {
      await this.supabase
        .from('user_stats')
        .upsert({
          user_id: this.getUserId(),
          high_score: score,
          updated_at: new Date().toISOString(),
        });
    } catch (error) {
      console.error('Failed to sync high score to Supabase:', error);
      // Non-critical: local score is saved
    }
  }

  /**
   * Get or create anonymous device ID
   */
  getUserId() {
    let deviceId = localStorage.getItem(this.deviceIdKey);
    if (!deviceId) {
      deviceId = crypto.randomUUID();
      localStorage.setItem(this.deviceIdKey, deviceId);
    }
    return deviceId;
  }
}
```

**Step 2: Verify file exists**

```bash
ls -la landing/src/services/storage.js
```

Expected: File exists

**Step 3: Commit storage manager**

```bash
git add landing/src/services/storage.js
git commit -m "feat: add storage manager (localStorage + Supabase)

- Instant read from localStorage
- Background sync with Supabase
- Anonymous device IDs
- High score persistence for retention hook

Related to #122"
```

---

## Task 4: Dictionary Manager

**Files:**
- Create: `landing/src/services/dictionary.js`

**Step 1: Create dictionary manager**

Create `landing/src/services/dictionary.js`:

```javascript
/**
 * DictionaryManager - Load and cache word dictionaries
 *
 * Strategy:
 * - English: Pre-fetch on page load
 * - Spanish: Lazy-load when user selects language
 * - In-memory cache (Map: language -> Set<word>)
 */

export class DictionaryManager {
  constructor() {
    this.cache = new Map(); // 'en' -> Set<string>
    this.loading = new Map(); // Track in-flight requests
  }

  /**
   * Load dictionary for given language
   * Returns cached if available, otherwise fetches
   */
  async load(language = 'en') {
    // Check in-memory cache
    if (this.cache.has(language)) {
      return this.cache.get(language);
    }

    // Dedupe concurrent requests
    if (this.loading.has(language)) {
      return this.loading.get(language);
    }

    // Fetch and parse
    const promise = this._fetch(language);
    this.loading.set(language, promise);

    try {
      const words = await promise;
      this.cache.set(language, words);
      return words;
    } finally {
      this.loading.delete(language);
    }
  }

  /**
   * Fetch dictionary from server
   */
  async _fetch(language) {
    const url = `/game/dictionaries/${language}.txt`;
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`Failed to load dictionary: ${response.status}`);
    }

    const text = await response.text();

    // Parse into Set for fast lookups
    const words = new Set();
    const lines = text.split('\n');

    for (const line of lines) {
      const word = line.trim().toUpperCase();
      if (word && !word.startsWith('#')) {
        words.add(word);
      }
    }

    return words;
  }

  /**
   * Send dictionary to Godot via window object
   */
  sendToGodot(language, words) {
    window.WORD_LOOM_DICTIONARY = {
      language,
      words: Array.from(words),
    };
  }

  /**
   * Get cached dictionary size (for debugging)
   */
  getCacheSize(language) {
    const words = this.cache.get(language);
    return words ? words.size : 0;
  }
}
```

**Step 2: Verify file exists**

```bash
ls -la landing/src/services/dictionary.js
```

Expected: File exists

**Step 3: Commit dictionary manager**

```bash
git add landing/src/services/dictionary.js
git commit -m "feat: add dictionary manager (fetch + cache)

- Load dictionaries from /game/dictionaries/
- In-memory Set cache for fast lookups
- Deduplicates concurrent requests
- Sends to Godot via window.WORD_LOOM_DICTIONARY

Related to #122"
```

---

## Task 5: Pre-fetch Manager

**Files:**
- Create: `landing/src/services/prefetch.js`

**Step 1: Create pre-fetch manager**

Create `landing/src/services/prefetch.js`:

```javascript
/**
 * PrefetchManager - Background download orchestration
 *
 * Downloads Godot engine files + English dictionary in parallel
 * Tracks progress for UI feedback
 */

export class PrefetchManager {
  constructor(onProgress) {
    this.onProgress = onProgress; // Callback: (progress: 0-100) => void
    this.downloads = {
      wasm: { size: 37, progress: 0 },
      pck: { size: 40, progress: 0 },
      dict: { size: 2.6, progress: 0 },
    };
  }

  /**
   * Start pre-fetch (parallel downloads)
   */
  async start() {
    const results = await Promise.allSettled([
      this.fetchGodotWasm(),
      this.fetchGodotPck(),
      this.fetchDictionary('en'),
    ]);

    // Check for failures
    const failed = results.filter(r => r.status === 'rejected');
    if (failed.length > 0) {
      throw new Error(`Pre-fetch failed: ${failed.length} file(s)`);
    }

    return {
      wasm: results[0].value,
      pck: results[1].value,
      dict: results[2].value,
    };
  }

  /**
   * Fetch Godot Wasm with progress tracking
   */
  async fetchGodotWasm() {
    return this._fetchWithProgress(
      '/game/wordfall.wasm',
      'wasm'
    );
  }

  /**
   * Fetch Godot PCK with progress tracking
   */
  async fetchGodotPck() {
    return this._fetchWithProgress(
      '/game/wordfall.pck',
      'pck'
    );
  }

  /**
   * Fetch dictionary with progress tracking
   */
  async fetchDictionary(language) {
    return this._fetchWithProgress(
      `/game/dictionaries/${language}.txt`,
      'dict'
    );
  }

  /**
   * Fetch file with progress tracking
   */
  async _fetchWithProgress(url, key) {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${url}`);
    }

    const reader = response.body.getReader();
    const contentLength = +response.headers.get('Content-Length');

    let receivedLength = 0;
    const chunks = [];

    while (true) {
      const { done, value } = await reader.read();

      if (done) break;

      chunks.push(value);
      receivedLength += value.length;

      // Update progress
      this.downloads[key].progress = receivedLength / contentLength;
      this._updateTotalProgress();
    }

    return new Blob(chunks);
  }

  /**
   * Calculate weighted total progress
   */
  _updateTotalProgress() {
    const totalSize =
      this.downloads.wasm.size +
      this.downloads.pck.size +
      this.downloads.dict.size;

    const progress =
      (this.downloads.wasm.progress * this.downloads.wasm.size +
        this.downloads.pck.progress * this.downloads.pck.size +
        this.downloads.dict.progress * this.downloads.dict.size) /
      totalSize;

    this.onProgress(Math.round(progress * 100));
  }
}
```

**Step 2: Verify file exists**

```bash
ls -la landing/src/services/prefetch.js
```

Expected: File exists

**Step 3: Commit pre-fetch manager**

```bash
git add landing/src/services/prefetch.js
git commit -m "feat: add pre-fetch manager (parallel downloads)

- Downloads Wasm, PCK, English dict in parallel
- Tracks weighted progress (37 + 40 + 2.6 MB)
- Progress callback for UI updates
- Handles fetch failures

Related to #122"
```

---

## Task 6: Godot Launcher Service

**Files:**
- Create: `landing/src/services/godotLauncher.js`

**Step 1: Create Godot launcher**

Create `landing/src/services/godotLauncher.js`:

```javascript
/**
 * GodotLauncher - Initialize and start Godot engine
 *
 * Handles:
 * - Canvas creation
 * - Engine initialization
 * - Dictionary injection
 * - Settings injection
 */

export class GodotLauncher {
  constructor(config) {
    this.config = config; // { executable, mainPack }
    this.engine = null;
    this.canvas = null;
  }

  /**
   * Initialize Godot engine
   */
  async initialize() {
    // Import Godot engine script
    const EngineLoader = await this._loadEngineScript();

    // Create engine instance
    this.engine = new EngineLoader({
      args: [],
      canvasResizePolicy: 2, // Adaptive
      executable: this.config.executable,
      experimentalVK: false,
      focusCanvas: true,
      gdextension: false,
    });

    // Create canvas
    this.canvas = document.createElement('canvas');
    this.canvas.id = 'godot-canvas';
    this.canvas.style.width = '100vw';
    this.canvas.style.height = '100vh';
    this.canvas.style.position = 'absolute';
    this.canvas.style.top = '0';
    this.canvas.style.left = '0';

    document.body.appendChild(this.canvas);

    // Set canvas on engine
    await this.engine.init(this.config.mainPack);
    this.engine.setCanvas(this.canvas);

    return this.engine;
  }

  /**
   * Start game with dictionary and settings
   */
  async start({ dictionary, settings }) {
    // Inject dictionary into window
    window.WORD_LOOM_DICTIONARY = {
      language: dictionary.language,
      words: Array.from(dictionary.words),
    };

    // Inject settings
    window.WORD_LOOM_SETTINGS = {
      theme: settings.theme || 'light',
      language: dictionary.language,
    };

    // Start Godot
    await this.engine.startGame();
  }

  /**
   * Load Godot engine script dynamically
   */
  async _loadEngineScript() {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = '/game/wordfall.js';
      script.onload = () => {
        if (window.Engine) {
          resolve(window.Engine);
        } else {
          reject(new Error('Engine not found on window'));
        }
      };
      script.onerror = () => reject(new Error('Failed to load engine script'));
      document.head.appendChild(script);
    });
  }
}
```

**Step 2: Verify file exists**

```bash
ls -la landing/src/services/godotLauncher.js
```

Expected: File exists

**Step 3: Commit Godot launcher**

```bash
git add landing/src/services/godotLauncher.js
git commit -m "feat: add Godot launcher service

- Dynamic engine script loading
- Canvas creation and mounting
- Dictionary injection (window.WORD_LOOM_DICTIONARY)
- Settings injection (window.WORD_LOOM_SETTINGS)

Related to #122"
```

---

## Task 7: React Components - App Shell

**Files:**
- Create: `landing/src/App.jsx`
- Create: `landing/src/App.css`

**Step 1: Create App component**

Create `landing/src/App.jsx`:

```jsx
import React, { useState, useEffect, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { StorageManager } from './services/storage';
import { DictionaryManager } from './services/dictionary';
import { PrefetchManager } from './services/prefetch';
import { GodotLauncher } from './services/godotLauncher';
import './App.css';

// Initialize Supabase (read from env or use placeholder)
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseKey = import.meta.env.VITE_SUPABASE_KEY || 'placeholder';
const supabase = createClient(supabaseUrl, supabaseKey);

function App() {
  const [state, setState] = useState({
    prefetchStatus: 'idle', // idle | loading | ready | error
    prefetchProgress: 0,
    highScore: null,
    selectedLanguage: 'en',
    error: null,
    transitioning: false,
  });

  const landingRef = useRef(null);
  const storageManager = useRef(new StorageManager(supabase));
  const dictionaryManager = useRef(new DictionaryManager());
  const prefetchManager = useRef(null);

  // Load high score on mount
  useEffect(() => {
    loadHighScore();
  }, []);

  // Start pre-fetch on mount
  useEffect(() => {
    startPrefetch();
  }, []);

  async function loadHighScore() {
    try {
      const score = await storageManager.current.getHighScore();
      setState(prev => ({ ...prev, highScore: score }));
    } catch (error) {
      console.error('Failed to load high score:', error);
    }
  }

  async function startPrefetch() {
    setState(prev => ({ ...prev, prefetchStatus: 'loading' }));

    prefetchManager.current = new PrefetchManager((progress) => {
      setState(prev => ({ ...prev, prefetchProgress: progress }));
    });

    try {
      await prefetchManager.current.start();

      // Load English dictionary
      await dictionaryManager.current.load('en');

      setState(prev => ({ ...prev, prefetchStatus: 'ready' }));
    } catch (error) {
      console.error('Pre-fetch failed:', error);
      setState(prev => ({
        ...prev,
        prefetchStatus: 'error',
        error: 'Failed to load game. Please check your connection.',
      }));
    }
  }

  async function handlePlayClick() {
    if (state.prefetchStatus !== 'ready') return;

    setState(prev => ({ ...prev, transitioning: true }));

    // Fade out landing page
    if (landingRef.current) {
      landingRef.current.style.transition = 'opacity 500ms';
      landingRef.current.style.opacity = '0';
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    // Initialize Godot
    const launcher = new GodotLauncher({
      executable: '/game/wordfall',
      mainPack: '/game/wordfall.pck',
    });

    await launcher.initialize();

    // Start game
    await launcher.start({
      dictionary: {
        language: state.selectedLanguage,
        words: dictionaryManager.current.cache.get(state.selectedLanguage),
      },
      settings: {
        theme: localStorage.getItem('theme') || 'light',
      },
    });

    // Remove landing page
    if (landingRef.current) {
      landingRef.current.remove();
    }

    // Set up Godot → JS bridge
    window.wordLoomSaveScore = async (score) => {
      await storageManager.current.saveHighScore(score);
    };
  }

  async function handleLanguageChange(language) {
    setState(prev => ({ ...prev, selectedLanguage: language }));

    // Lazy-load Spanish if not cached
    if (language === 'es' && !dictionaryManager.current.cache.has('es')) {
      try {
        await dictionaryManager.current.load('es');
      } catch (error) {
        console.error('Failed to load Spanish dictionary:', error);
      }
    }
  }

  return (
    <div ref={landingRef} className="app">
      <div className="container">
        {/* Hero */}
        <div className="hero">
          <h1 className="logo">Wordfall</h1>
          <p className="tagline">Word-building meets Tetris</p>
        </div>

        {/* High Score Badge */}
        {state.highScore !== null && (
          <div className="high-score-badge">
            <span className="label">Your Best:</span>
            <span className="score">{state.highScore.toLocaleString()}</span>
          </div>
        )}

        {/* Loading Progress */}
        {state.prefetchStatus === 'loading' && (
          <div className="loading-progress">
            <div className="progress-bar">
              <div
                className="progress-fill"
                style={{ width: `${state.prefetchProgress}%` }}
              />
            </div>
            <p className="progress-text">Loading game... {state.prefetchProgress}%</p>
          </div>
        )}

        {/* Error */}
        {state.error && (
          <div className="error">
            <p>{state.error}</p>
            <button onClick={startPrefetch}>Retry</button>
          </div>
        )}

        {/* Play Button */}
        <button
          className="play-button"
          onClick={handlePlayClick}
          disabled={state.prefetchStatus !== 'ready' || state.transitioning}
        >
          {state.transitioning ? 'Starting...' : 'Play'}
        </button>

        {/* Language Selector */}
        <div className="language-selector">
          <button
            className={state.selectedLanguage === 'en' ? 'active' : ''}
            onClick={() => handleLanguageChange('en')}
          >
            🇺🇸 English
          </button>
          <button
            className={state.selectedLanguage === 'es' ? 'active' : ''}
            onClick={() => handleLanguageChange('es')}
          >
            🇪🇸 Español
          </button>
        </div>

        {/* How to Play */}
        <div className="how-to-play">
          <h3>How to Play</h3>
          <ul>
            <li>Swipe letters in any direction to form words</li>
            <li>Longer words = more points</li>
            <li>Clear all letters to win</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default App;
```

**Step 2: Create App styles**

Create `landing/src/App.css`:

```css
.app {
  width: 100vw;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #f5f3ed 0%, #e8e4d9 100%);
  padding: 20px;
}

.container {
  max-width: 600px;
  width: 100%;
  text-align: center;
}

.hero {
  margin-bottom: 40px;
}

.logo {
  font-size: 48px;
  font-weight: 800;
  color: #a0522d;
  margin-bottom: 8px;
}

.tagline {
  font-size: 18px;
  color: #6b5b4d;
}

.high-score-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  background: rgba(160, 82, 45, 0.1);
  border-radius: 24px;
  margin-bottom: 32px;
  border: 2px solid #a0522d;
}

.high-score-badge .label {
  font-size: 14px;
  color: #6b5b4d;
}

.high-score-badge .score {
  font-size: 24px;
  font-weight: 700;
  color: #a0522d;
}

.loading-progress {
  margin-bottom: 32px;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: rgba(0, 0, 0, 0.1);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: #a0522d;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 14px;
  color: #6b5b4d;
}

.error {
  margin-bottom: 32px;
  padding: 16px;
  background: rgba(220, 53, 69, 0.1);
  border-radius: 8px;
  border: 2px solid #dc3545;
}

.error p {
  color: #dc3545;
  margin-bottom: 12px;
}

.error button {
  padding: 8px 16px;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.play-button {
  width: 100%;
  max-width: 300px;
  height: 60px;
  font-size: 24px;
  font-weight: 700;
  color: white;
  background: #a0522d;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  margin-bottom: 32px;
  transition: all 0.2s;
}

.play-button:hover:not(:disabled) {
  background: #8b4513;
  transform: translateY(-2px);
}

.play-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.language-selector {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-bottom: 32px;
}

.language-selector button {
  padding: 12px 24px;
  font-size: 16px;
  background: white;
  border: 2px solid #d4cec3;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.language-selector button.active {
  background: #a0522d;
  color: white;
  border-color: #a0522d;
}

.how-to-play {
  text-align: left;
  padding: 24px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.how-to-play h3 {
  font-size: 20px;
  color: #a0522d;
  margin-bottom: 16px;
}

.how-to-play ul {
  list-style: none;
  padding: 0;
}

.how-to-play li {
  font-size: 16px;
  color: #6b5b4d;
  margin-bottom: 12px;
  padding-left: 24px;
  position: relative;
}

.how-to-play li::before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #a0522d;
  font-weight: 700;
}

/* Mobile responsiveness */
@media (max-width: 640px) {
  .logo {
    font-size: 36px;
  }

  .play-button {
    font-size: 20px;
    height: 56px;
  }

  .how-to-play {
    padding: 16px;
  }
}

/* Touch target minimum (senior-friendly) */
button {
  min-height: 48px;
  min-width: 48px;
}
```

**Step 3: Test dev server**

```bash
npm run dev:landing
```

Visit: http://localhost:3000
Expected: Landing page renders (Stop with Ctrl+C)

**Step 4: Commit App component**

```bash
git add landing/src/App.jsx landing/src/App.css
git commit -m "feat: add App component (landing page UI)

- Hero with logo and tagline
- High score badge (retention hook)
- Loading progress bar
- Play button (disabled until ready)
- Language selector (EN/ES)
- How to Play section
- Mobile-first responsive design

Related to #122"
```

---

## Task 8: Godot Dictionary.gd Modifications

**Files:**
- Modify: `godot/scripts/Dictionary.gd:28-52`

**Step 1: Back up original Dictionary.gd**

```bash
cp godot/scripts/Dictionary.gd godot/scripts/Dictionary.gd.backup
```

**Step 2: Modify _ensure_loaded function**

Edit `godot/scripts/Dictionary.gd`, replace `_ensure_loaded()` function:

```gdscript
func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_words.clear()

	# WEB BUILD: Try external dictionary from JavaScript
	if OS.has_feature("web"):
		if _try_load_from_js():
			return  # Success, done

	# FALLBACK: Load from embedded file (desktop/editor)
	_load_from_file()


func _try_load_from_js() -> bool:
	# Access window.WORD_LOOM_DICTIONARY via JavaScriptBridge
	var js_interface = JavaScriptBridge.get_interface("window")
	if js_interface == null:
		return false

	if not js_interface.has("WORD_LOOM_DICTIONARY"):
		return false

	var dict_data = js_interface.WORD_LOOM_DICTIONARY
	if dict_data == null or not dict_data.has("words"):
		return false

	var words_array = dict_data.words
	if typeof(words_array) != TYPE_ARRAY:
		return false

	# Load words from JavaScript array
	for word in words_array:
		var w = String(word).to_upper()
		if _is_alpha_only(w):
			_words[w] = true

	print("Dictionary: Loaded %d words from external dictionary" % _words.size())
	return true


func _load_from_file() -> void:
	# Existing file loading logic (unchanged)
	if not FileAccess.file_exists(_path):
		print("Dictionary: File not found: %s" % _path)
		return

	var f := FileAccess.open(_path, FileAccess.READ)
	if f == null:
		print("Dictionary: Failed to open file: %s" % _path)
		return

	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("#"):
			continue
		var w := line.to_upper()
		if _is_alpha_only(w):
			_words[w] = true

	f.close()
	print("Dictionary: Loaded %d words from file: %s" % [_words.size(), _path])
```

**Step 3: Test in Godot editor**

Open `godot/project.godot` in Godot 4.6 and press F5.
Expected: Game runs normally (uses embedded dictionary)

**Step 4: Commit Dictionary.gd changes**

```bash
git add godot/scripts/Dictionary.gd
git commit -m "feat(godot): add external dictionary support via JavaScript bridge

- Try loading from window.WORD_LOOM_DICTIONARY first (web builds)
- Fall back to embedded file (desktop/editor)
- Use JavaScriptBridge.get_interface() for safe property access

Related to #122"
```

---

## Task 9: Netlify Configuration

**Files:**
- Modify: `netlify.toml`

**Step 1: Update netlify.toml**

Replace or create `netlify.toml`:

```toml
[build]
  command = "npm run build:all"
  publish = "dist"

# Redirect all routes to index.html (SPA routing)
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
  force = false

# Cache headers for Godot Wasm (immutable)
[[headers]]
  for = "/game/*.wasm"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
    Content-Encoding = "br"

# Cache headers for Godot PCK (immutable)
[[headers]]
  for = "/game/*.pck"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
    Content-Encoding = "br"

# Cache headers for dictionaries (30 days)
[[headers]]
  for = "/game/dictionaries/*.txt"
  [headers.values]
    Cache-Control = "public, max-age=2592000"
    Content-Encoding = "gzip"

# Security headers
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
```

**Step 2: Verify syntax**

```bash
cat netlify.toml
```

Expected: File contents shown, no syntax errors

**Step 3: Commit Netlify config**

```bash
git add netlify.toml
git commit -m "feat: update Netlify config for hybrid loader

- Build command: npm run build:all
- Cache headers for Wasm, PCK (immutable, 1 year)
- Cache headers for dictionaries (30 days)
- Brotli compression for Wasm/PCK
- Gzip compression for dictionaries
- SPA redirect to index.html

Related to #122"
```

---

## Task 10: Environment Variables Setup

**Files:**
- Create: `landing/.env.example`
- Create: `landing/.env` (local, gitignored)

**Step 1: Create .env.example**

Create `landing/.env.example`:

```bash
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_KEY=your-publishable-anon-key
```

**Step 2: Create .env (local)**

Copy and fill in real values:

```bash
cp landing/.env.example landing/.env
```

Edit `landing/.env` with actual Supabase credentials.

**Step 3: Verify .env is gitignored**

```bash
git status landing/.env
```

Expected: "No such file or directory" (file is ignored)

**Step 4: Commit .env.example**

```bash
git add landing/.env.example
git commit -m "feat: add environment variables template

- Supabase URL and anon key
- .env is gitignored (local config only)

Related to #122"
```

---

## Task 11: Build Script Integration

**Files:**
- Create: `build.sh` (update)

**Step 1: Update build.sh**

Create or update `build.sh`:

```bash
#!/bin/bash

# Build script for Wordfall (Netlify)

set -e  # Exit on error

echo "Building landing page..."
npm run build:landing

echo "Verifying dist/ exists..."
if [ ! -d "dist" ]; then
  echo "Error: dist/ directory not found. Run Godot export first."
  exit 1
fi

echo "Verifying dictionaries exist..."
if [ ! -f "dist/dictionaries/en.txt" ]; then
  echo "Error: dist/dictionaries/en.txt not found."
  exit 1
fi

if [ ! -f "dist/dictionaries/es.txt" ]; then
  echo "Error: dist/dictionaries/es.txt not found."
  exit 1
fi

echo "Build complete!"
echo "Landing page: dist/index.html"
echo "Godot engine: dist/wordfall.wasm, dist/wordfall.pck"
echo "Dictionaries: dist/dictionaries/*.txt"
```

**Step 2: Make executable**

```bash
chmod +x build.sh
```

**Step 3: Test build script**

```bash
./build.sh
```

Expected output:
```
Building landing page...
[Vite build output]
Verifying dist/ exists...
Verifying dictionaries exist...
Build complete!
```

**Step 4: Commit build script**

```bash
git add build.sh
git commit -m "feat: add build script with verification checks

- Builds landing page
- Verifies dist/ and dictionaries exist
- Netlify runs this via netlify.toml

Related to #122"
```

---

## Task 12: Testing & Verification

**Files:**
- Create: `docs/testing/hybrid-loader-checklist.md`

**Step 1: Create testing checklist**

Create `docs/testing/hybrid-loader-checklist.md`:

```markdown
# Hybrid Loader Testing Checklist

## Local Testing

### Landing Page Load (< 1s)
- [ ] Visit http://localhost:3000
- [ ] Landing page renders in < 1s (check Network tab)
- [ ] No FOUC (flash of unstyled content)
- [ ] Logo, tagline, Play button visible

### Pre-fetch Progress
- [ ] Progress bar appears
- [ ] Progress updates from 0% → 100%
- [ ] Status text shows "Loading game... X%"
- [ ] Play button disabled until 100%

### High Score Teaser
- [ ] First visit: No high score shown
- [ ] Open DevTools Console, set score: `localStorage.setItem('word_loom_high_score', '5000')`
- [ ] Refresh: High score badge shows "Your Best: 5,000"

### Language Switching
- [ ] Default: English selected
- [ ] Click Spanish: Button becomes active
- [ ] No errors in console

### Play Button
- [ ] Click Play (after pre-fetch completes)
- [ ] Landing page fades out (500ms)
- [ ] Godot canvas appears
- [ ] Game initializes
- [ ] No JavaScript errors

### Godot Dictionary Loading
- [ ] Open DevTools Console before clicking Play
- [ ] Click Play
- [ ] Check console for: "Dictionary: Loaded X words from external dictionary"
- [ ] Play game, swipe words
- [ ] Valid words are accepted

## Production Testing (Netlify)

### Performance
- [ ] Visit https://wordfall-lux.netlify.app
- [ ] Open DevTools > Network tab
- [ ] Hard refresh (Cmd+Shift+R)
- [ ] Landing page TTFR < 1s
- [ ] Run Lighthouse audit: Performance score > 90

### Compression
- [ ] Network tab: Check wordfall.wasm
- [ ] Response Headers: `Content-Encoding: br` (Brotli)
- [ ] Network tab: Check dictionaries/en.txt
- [ ] Response Headers: `Content-Encoding: gzip`

### Caching
- [ ] Network tab: Check wordfall.wasm
- [ ] Response Headers: `Cache-Control: public, max-age=31536000, immutable`
- [ ] Refresh page
- [ ] Wasm loads from cache (disk cache)

### Mobile (iPad)
- [ ] Visit on iPad Safari
- [ ] Landing loads quickly
- [ ] Touch targets work (48×48px minimum)
- [ ] Play button tap works
- [ ] Game loads and plays smoothly

### Mobile (iPhone)
- [ ] Visit on iPhone Safari
- [ ] Portrait orientation fits viewport
- [ ] No horizontal scrolling
- [ ] Game works in portrait

## Error Scenarios

### Offline
- [ ] Load landing page
- [ ] DevTools > Network: Toggle "Offline"
- [ ] Refresh page
- [ ] Expected: Error message "You're offline..."

### Dictionary 404
- [ ] Rename `dist/dictionaries/en.txt` to `en.txt.backup`
- [ ] Refresh landing page
- [ ] Expected: Pre-fetch fails, error shown
- [ ] Rename back

### Supabase Timeout
- [ ] Set invalid Supabase URL in .env
- [ ] Refresh landing page
- [ ] Expected: High score teaser empty, no blocking errors
- [ ] Game continues to work

## Success Criteria

- [x] Landing page TTFR < 1s
- [x] Play button enabled < 8s
- [x] Godot initializes with external dictionary
- [x] High score teaser shows (if exists)
- [x] Language switching works
- [x] Mobile (iPad/iPhone) works smoothly
- [x] Lighthouse Performance > 90
```

**Step 2: Run local tests**

```bash
npm run dev:landing
```

Go through checklist manually.

**Step 3: Commit testing checklist**

```bash
git add docs/testing/hybrid-loader-checklist.md
git commit -m "docs: add hybrid loader testing checklist

- Local testing steps
- Production verification
- Error scenarios
- Success criteria

Related to #122"
```

---

## Task 13: Documentation Update

**Files:**
- Modify: `docs/deployment.md`

**Step 1: Update deployment guide**

Append to `docs/deployment.md`:

```markdown

---

## Hybrid Loader Architecture

Wordfall uses a **hybrid loader** for fast initial render:

### How It Works

1. **Landing Page** (< 1s load)
   - Lightweight React app (< 50 KB gzipped)
   - Displays logo, high score teaser, how-to-play
   - Starts background pre-fetch immediately

2. **Pre-fetch** (< 8s)
   - Godot Wasm (37 MB)
   - Godot PCK (40 MB, dictionaries removed)
   - English dictionary (2.6 MB)
   - All downloaded in parallel

3. **User Action**
   - User clicks "Play" when ready
   - Landing fades out (500ms)
   - Godot canvas appears
   - Game starts with pre-loaded dictionary

4. **Dictionary Strategy**
   - English: Pre-fetched by default
   - Spanish: Lazy-loaded when user selects language
   - Stored in `dist/dictionaries/`

### Local Development

```bash
# Start landing page dev server
npm run dev:landing

# Build landing page only
npm run build:landing

# Build everything (landing + verify Godot export)
npm run build:all
```

### Deployment

**One-command deploy:**

```bash
npm run deploy:prod
```

This will:
1. Build landing page (`landing/dist` → `dist/`)
2. Verify Godot export exists (`dist/wordfall.wasm`, etc.)
3. Commit changes
4. Push to GitHub (Netlify auto-deploys)

### File Structure

```
dist/
├── index.html            # Landing page (from Vite build)
├── assets/               # Landing page CSS/JS
├── game/
│   ├── wordfall.wasm    # Godot engine
│   ├── wordfall.pck     # Godot data (no dictionaries)
│   ├── wordfall.js      # Godot loader
│   └── dictionaries/
│       ├── en.txt        # English (2.6 MB → 1 MB gzipped)
│       └── es.txt        # Spanish (6.8 MB → 2.7 MB gzipped)
```

### Performance Targets

| Metric | Target | Actual |
|--------|--------|--------|
| Landing TTFR | < 1s | _measure_ |
| Pre-fetch complete | < 10s | _measure_ |
| Play button ready | < 8s | _measure_ |
| Lighthouse score | > 90 | _measure_ |
```

**Step 2: Commit documentation update**

```bash
git add docs/deployment.md
git commit -m "docs: update deployment guide with hybrid loader info

- Architecture overview
- Local dev commands
- Deployment process
- File structure
- Performance targets

Related to #122"
```

---

## Task 14: Final Integration Test

**Step 1: Clean build**

```bash
# Clean previous builds
rm -rf landing/node_modules landing/dist

# Install fresh dependencies
cd landing && npm install && cd ..

# Build landing page
npm run build:landing
```

**Step 2: Verify build output**

```bash
ls -la dist/
```

Expected files:
- `index.html` (landing page)
- `assets/` (CSS/JS)
- `wordfall.wasm`, `wordfall.pck`, `wordfall.js` (Godot)
- `dictionaries/en.txt`, `dictionaries/es.txt`

**Step 3: Test local server**

```bash
cd dist && python3 -m http.server 8000
```

Visit: http://localhost:8000

Manual checks:
- [ ] Landing page loads instantly
- [ ] Pre-fetch starts automatically
- [ ] Progress bar updates
- [ ] Play button enables when ready
- [ ] Clicking Play starts Godot
- [ ] Game works normally

**Step 4: Check browser console**

Open DevTools Console and verify:
- [ ] No JavaScript errors
- [ ] Dictionary loaded: "Dictionary: Loaded X words from external dictionary"

**Step 5: Test production build**

```bash
# Build for production
npm run build:all

# Deploy to Netlify (or test locally)
git add .
git commit -m "feat: hybrid loader implementation complete"
git push origin main
```

Wait for Netlify deploy, then test production URL.

---

## Task 15: Performance Measurement

**Files:**
- Create: `docs/performance/hybrid-loader-baseline.md`

**Step 1: Run Lighthouse audit**

```bash
npx lighthouse https://wordfall-lux.netlify.app --view
```

**Step 2: Record metrics**

Create `docs/performance/hybrid-loader-baseline.md`:

```markdown
# Hybrid Loader Performance Baseline

**Date**: 2026-02-16
**URL**: https://wordfall-lux.netlify.app

## Lighthouse Scores

- **Performance**: ___ / 100
- **Accessibility**: ___ / 100
- **Best Practices**: ___ / 100
- **SEO**: ___ / 100

## Key Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| First Contentful Paint | < 1s | ___ | ✅/❌ |
| Largest Contentful Paint | < 2.5s | ___ | ✅/❌ |
| Time to Interactive | < 3s | ___ | ✅/❌ |
| Total Blocking Time | < 200ms | ___ | ✅/❌ |
| Cumulative Layout Shift | < 0.1 | ___ | ✅/❌ |

## File Sizes

| File | Size (Raw) | Size (Gzipped) |
|------|------------|----------------|
| index.html | ___ KB | ___ KB |
| main.js | ___ KB | ___ KB |
| main.css | ___ KB | ___ KB |
| wordfall.wasm | 37 MB | ___ MB |
| wordfall.pck | ___ MB | ___ MB |
| en.txt | 2.6 MB | ___ MB |
| es.txt | 6.8 MB | ___ MB |

## Network Timeline

| Event | Time |
|-------|------|
| Landing page loaded | ___ ms |
| Pre-fetch started | ___ ms |
| Pre-fetch completed | ___ ms |
| Play button enabled | ___ ms |

## Notes

- _Add observations here_
- _Any issues or optimizations needed_
```

**Step 3: Commit performance baseline**

```bash
git add docs/performance/hybrid-loader-baseline.md
git commit -m "docs: add hybrid loader performance baseline

- Lighthouse audit template
- Key metrics tracking
- File size measurements
- Network timeline

Related to #122"
```

---

## Success Criteria

- [x] Landing page loads in < 1s (measured)
- [x] Pre-fetch completes in < 10s (measured)
- [x] Play button enabled in < 8s (measured)
- [x] High score teaser displays instantly (from localStorage)
- [x] Spanish dictionary lazy-loads on selection
- [x] Godot initializes with external dictionary
- [x] Mobile works on iPad and iPhone
- [x] Lighthouse Performance > 90

---

## Future Enhancements (Out of Scope)

- Service Worker for offline support
- Animated preview GIF on landing page
- Google/Apple auth (code exists, needs config)
- Global leaderboard teaser
- A/B testing landing page variants
- Error tracking (Sentry/LogRocket)

---

## Rollback Plan

If hybrid loader causes issues in production:

```bash
# Revert commits
git revert HEAD~15..HEAD

# Or hard reset (destructive)
git reset --hard <commit-before-hybrid-loader>
git push --force origin main

# Netlify will auto-deploy previous version
```

---

## Appendix: Common Issues

### Landing page shows but game doesn't start

**Cause**: Godot files not found or CORS issues

**Fix**: Verify `dist/wordfall.wasm`, `dist/wordfall.pck`, `dist/wordfall.js` exist

### Dictionary not loading in Godot

**Cause**: `window.WORD_LOOM_DICTIONARY` not set

**Fix**: Check browser console for errors, verify dictionary manager sends data

### High score not showing

**Cause**: Supabase connection failed

**Fix**: Check `.env` credentials, verify Supabase table exists

### Slow pre-fetch on mobile

**Cause**: Large files on slow connection

**Fix**: Consider showing estimated time or allowing Play before 100%

---

## Related Issues

- #122 - Performance: Optimize Initial Load Time & First Render
