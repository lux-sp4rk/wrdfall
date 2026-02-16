# Hybrid Loader Strategy Design

**Date**: 2026-02-16
**Issue**: [#122 - Optimize Initial Load Time & First Render](https://github.com/lux-sp4rk/word-loom/issues/122)
**Goal**: Reduce Time to First Render (TTFR) to < 3 seconds, improve perceived performance, boost retention

---

## Problem Statement

The current web build (`word-loom-lux.netlify.app`) experiences significant initial load delays:
- **Total payload**: 87.8 MB (37.69 MB Wasm + 50.11 MB PCK)
- **Dictionary files**: 9.4 MB embedded in PCK (2.6 MB English + 6.8 MB Spanish)
- **User experience**: Long blank screen, no feedback during load
- **Impact**: Poor first impression, especially on mobile devices (primary usage: iPad, iPhone)

---

## Solution Overview

Implement a **hybrid loader architecture** with:
1. **Lightweight React landing page** (< 1s load) - shows content immediately
2. **Background pre-fetch** - parallel downloads while user reads landing page
3. **Rich preview** - high score teaser (retention hook), how-to-play, screenshots
4. **User-triggered initialization** - Godot starts only when user clicks "Play"
5. **Extracted dictionaries** - move out of PCK bundle, load externally

---

## Architecture

### High-Level Flow

```
User visits word-loom.netlify.app
    ↓
[Vite + React Landing Page] (< 1s)
    ├─ Inline critical CSS
    ├─ Read localStorage for high score
    ├─ Display: Logo, Tagline, Play button, How-to-Play, Screenshots
    └─ Background pre-fetch starts:
        ├─ Godot .wasm (37 MB) in parallel with
        ├─ Godot .pck (reduced, no dictionaries)
        └─ English dictionary (2.6 MB)
    ↓
User sees landing page (reads content, sees high score)
    ↓
Pre-fetch completes (progress bar shows 100%)
    ↓
User clicks "Play"
    ↓
Landing page fades out (500ms) → Godot canvas mounts
    ↓
Godot engine initializes with pre-loaded dictionary
    ↓
Game starts
```

### File Structure

```
word-loom/
├── landing/                 # NEW: Vite + React landing page
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.jsx
│       ├── App.jsx
│       ├── components/
│       │   ├── Hero.jsx              # Logo, tagline, Play button
│       │   ├── HighScoreBadge.jsx    # "Your Best: 12,450" (retention hook)
│       │   ├── HowToPlay.jsx         # 3-4 bullet points
│       │   ├── LanguageSelector.jsx  # English/Spanish flags
│       │   └── LoadingProgress.jsx   # Progress bar (0-100%)
│       ├── services/
│       │   ├── prefetch.js           # Pre-fetch orchestration
│       │   ├── dictionary.js         # Dictionary loading
│       │   ├── storage.js            # localStorage + Supabase
│       │   └── godotLauncher.js      # Godot initialization
│       └── styles/
│           └── app.css
├── dist/                    # Godot HTML5 export (existing)
│   ├── word-loom.wasm       # 37 MB
│   ├── word-loom.pck        # Reduced (no dictionaries)
│   ├── word-loom.js
│   └── dictionaries/        # NEW: Extracted dictionaries
│       ├── en.txt           # 2.6 MB (→ ~1 MB gzipped)
│       └── es.txt           # 6.8 MB (→ ~2.7 MB gzipped)
├── godot/                   # Godot project (existing)
├── package.json             # NEW: Root-level deploy script
└── netlify.toml             # Updated build config
```

---

## Component Design

### React Component Tree

```jsx
<App>
  ├─ <Hero>
  │   ├─ Logo (SVG inline)
  │   ├─ Tagline: "Word-building meets Tetris"
  │   └─ PlayButton (disabled until pre-fetch ready)
  │
  ├─ <HighScoreBadge>
  │   ├─ Shows: "Your Best: 12,450"
  │   ├─ Data: localStorage → Supabase fallback
  │   └─ Skeleton loader while fetching
  │
  ├─ <HowToPlay>
  │   ├─ 3-4 bullet points
  │   └─ Icon + text
  │
  ├─ <LanguageSelector>
  │   ├─ English (default, pre-fetched)
  │   ├─ Spanish (lazy-loads on select)
  │   └─ Flag icons
  │
  └─ <LoadingProgress>
      ├─ Progress bar (0-100%)
      ├─ Shows: "Loading game... 65%"
      └─ Hides when complete
```

### App State

```typescript
interface AppState {
  prefetchStatus: 'idle' | 'loading' | 'ready' | 'error';
  prefetchProgress: number; // 0-100
  highScore: number | null;
  selectedLanguage: 'en' | 'es';
  dictionaryLoaded: boolean;
  error: string | null;
  transitioning: boolean;
}
```

### Mobile-First Styling

- **Viewport**: 100vw × 100vh, no scroll
- **Touch targets**: Minimum 48×48px (senior-friendly)
- **Font sizes**: Base 18px, headings 24-32px
- **Colors**: Use existing ThemeManager colors (light/dark)
- **Layout**: Flexbox, centered, vertical stack on mobile

---

## Pre-fetch Strategy

### Parallel Downloads

```javascript
// services/prefetch.js
class PrefetchManager {
  async start() {
    const downloads = await Promise.allSettled([
      this.fetchGodotWasm(),     // 37 MB
      this.fetchGodotPck(),      // ~40 MB (reduced)
      this.fetchDictionary('en') // 2.6 MB
    ]);

    this.updateProgress(downloads);
  }

  async fetchGodotWasm() {
    const response = await fetch('/game/word-loom.wasm');
    const reader = response.body.getReader();
    const contentLength = +response.headers.get('Content-Length');

    let receivedLength = 0;
    const chunks = [];

    while (true) {
      const {done, value} = await reader.read();
      if (done) break;

      chunks.push(value);
      receivedLength += value.length;

      this.emit('wasm-progress', receivedLength / contentLength);
    }

    return new Blob(chunks);
  }
}
```

### Progress Calculation

Weighted by file size:
```javascript
const totalSize = 37 + 40 + 2.6; // MB
const progress =
  (wasmProgress * 37 + pckProgress * 40 + dictProgress * 2.6) / totalSize;
```

### Caching Strategy

**HTTP Cache Headers** (in `netlify.toml`):
```toml
[[headers]]
  for = "/game/*.wasm"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/game/dictionaries/*.txt"
  [headers.values]
    Cache-Control = "public, max-age=2592000" # 30 days
```

**Service Worker** (optional Phase 2):
- Cache Wasm, PCK, dictionaries after first load
- Instant repeat visits

### Error Handling

```javascript
async fetchWithRetry(url, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response;
    } catch (error) {
      if (i === maxRetries - 1) {
        this.emit('error', `Failed to load ${url}`);
        throw error;
      }
      // Exponential backoff
      await this.delay(1000 * Math.pow(2, i));
    }
  }
}
```

---

## Dictionary Management

### Loading Strategy

**English**: Pre-fetch on page load (always)
**Spanish**: Lazy-load only when user selects language

```javascript
// services/dictionary.js
class DictionaryManager {
  constructor() {
    this.cache = new Map(); // 'en' -> Set<string>
    this.loading = new Map();
  }

  async load(language = 'en') {
    // Check in-memory cache
    if (this.cache.has(language)) {
      return this.cache.get(language);
    }

    // Dedupe concurrent requests
    if (this.loading.has(language)) {
      return this.loading.get(language);
    }

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

  async _fetch(language) {
    const url = `/game/dictionaries/${language}.txt`;
    const response = await fetch(url);
    const text = await response.text();

    // Parse into Set (fast lookups)
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

  sendToGodot(language, words) {
    window.WORD_LOOM_DICTIONARY = {
      language,
      words: Array.from(words)
    };
  }
}
```

### Storage Format

**Keep as .txt** (not JSON/binary) because:
- Simple, human-readable
- Easy to update/replace
- GZip compresses effectively (~60% reduction)
- Parsing is fast enough (< 500ms for 6.8 MB)

---

## Godot Integration

### JavaScript ↔ Godot Bridge

**Landing page → Godot:**

```javascript
// services/godotLauncher.js
class GodotLauncher {
  async start(dictionary) {
    // Inject dictionary into window
    window.WORD_LOOM_DICTIONARY = {
      language: dictionary.language,
      words: Array.from(dictionary.words)
    };

    // Inject settings
    window.WORD_LOOM_SETTINGS = {
      theme: localStorage.getItem('theme') || 'light',
      language: dictionary.language
    };

    // Start Godot engine
    await this.engine.startGame();
  }
}
```

**Godot reads external dictionary:**

> **Security Note**: Godot's `JavaScriptBridge.eval()` is the official API for web builds. While it uses code evaluation, it's sandboxed within the browser context and only accesses data we control (`window.WORD_LOOM_DICTIONARY`). Alternative: Use Godot's `JavaScriptBridge.get_interface()` for safer property access.

```gdscript
# Dictionary.gd - add external dictionary support
func _ensure_loaded() -> void:
    if _loaded:
        return
    _loaded = true
    _words.clear()

    # WEB BUILD: Try external dictionary
    if OS.has_feature("web"):
        if _try_load_from_js():
            return

    # FALLBACK: Embedded file (desktop/editor)
    _load_from_file()

func _try_load_from_js() -> bool:
    # Using JavaScriptBridge to access window.WORD_LOOM_DICTIONARY
    # This is Godot's official API for web builds
    var js_interface = JavaScriptBridge.get_interface("window")
    if js_interface == null:
        return false

    var dict_data = js_interface.WORD_LOOM_DICTIONARY
    if dict_data == null or not dict_data.has("words"):
        return false

    var words_array = dict_data.words
    if typeof(words_array) != TYPE_ARRAY:
        return false

    for word in words_array:
        var w = String(word).to_upper()
        if _is_alpha_only(w):
            _words[w] = true

    print("Loaded %d words from external dictionary" % _words.size())
    return true
```

### Transition Flow

```jsx
// App.jsx
async function handlePlayClick() {
  setState({ transitioning: true });

  // 1. Fade out landing page
  await fadeOut(landingRef.current, 500);

  // 2. Create Godot canvas
  const canvas = document.createElement('canvas');
  canvas.id = 'godot-canvas';
  canvas.style.width = '100vw';
  canvas.style.height = '100vh';
  document.body.appendChild(canvas);

  // 3. Initialize Godot
  const launcher = new GodotLauncher(canvas, {
    executable: '/game/word-loom',
    mainPack: '/game/word-loom.pck'
  });

  await launcher.initialize();

  // 4. Start game with dictionary
  await launcher.start({
    language: state.selectedLanguage,
    words: dictionaryManager.cache.get(state.selectedLanguage)
  });

  // 5. Remove landing page from DOM
  landingRef.current.remove();
}
```

---

## Data Persistence

### LocalStorage + Supabase Sync

```javascript
// services/storage.js
class StorageManager {
  async getHighScore() {
    // 1. Try localStorage first (instant)
    const local = this.getLocalHighScore();

    if (local !== null) {
      // Background sync (don't await)
      this.syncFromSupabase().catch(console.error);
      return local;
    }

    // 2. Fetch from Supabase
    const remote = await this.fetchFromSupabase();
    if (remote !== null) {
      this.setLocalHighScore(remote);
      return remote;
    }

    // 3. New user
    return null;
  }

  async saveHighScore(score) {
    const currentHigh = this.getLocalHighScore() || 0;

    if (score <= currentHigh) return;

    // Update local immediately
    this.setLocalHighScore(score);

    // Sync to Supabase (background)
    try {
      await this.supabase
        .from('user_stats')
        .upsert({
          user_id: this.getUserId(),
          high_score: score,
          updated_at: new Date().toISOString()
        });
    } catch (error) {
      console.error('Failed to sync high score:', error);
      // Non-critical: local score is saved
    }
  }

  getUserId() {
    // Anonymous device ID (MVP)
    let deviceId = localStorage.getItem('word_loom_device_id');
    if (!deviceId) {
      deviceId = crypto.randomUUID();
      localStorage.setItem('word_loom_device_id', deviceId);
    }
    return deviceId;
  }
}
```

### Godot → JavaScript Communication

```gdscript
# LoomDrop.gd - when game ends
func _on_game_over(final_score: int):
    if OS.has_feature("web"):
        # Call JavaScript function directly
        var js_interface = JavaScriptBridge.get_interface("window")
        if js_interface and js_interface.has("wordLoomSaveScore"):
            js_interface.wordLoomSaveScore.call(final_score)
```

```javascript
// Global handler
window.wordLoomSaveScore = async (score) => {
  await storageManager.saveHighScore(score);
};
```

### Authentication

**Phase 1 (MVP)**: Anonymous device IDs
**Phase 2 (Future)**: Google/Apple auth (code already exists, just needs config)

---

## Error Handling

### Error Scenarios

```javascript
const ERROR_SCENARIOS = {
  WASM_LOAD_FAILED: {
    message: "Game engine failed to load. Check your connection.",
    action: "retry",
    critical: true
  },

  DICT_LOAD_FAILED: {
    message: "Dictionary failed to load.",
    action: "fallback",
    critical: false
  },

  SUPABASE_SYNC_FAILED: {
    message: "Cloud sync failed. Your score is saved locally.",
    action: "warn",
    critical: false
  },

  NETWORK_OFFLINE: {
    message: "You're offline. The game needs an internet connection.",
    action: "wait",
    critical: true
  }
};
```

### Retry Logic

- Exponential backoff (1s, 2s, 4s)
- Max 3 retries
- User-facing retry button for critical errors

### Offline Detection

```javascript
window.addEventListener('offline', () => {
  setState({ error: { code: 'NETWORK_OFFLINE' } });
});

window.addEventListener('online', () => {
  setState({ error: null });
  prefetchManager.resume();
});
```

---

## Deployment

### Build Script

**Root `package.json`:**
```json
{
  "scripts": {
    "build:landing": "cd landing && npm run build",
    "build:all": "npm run build:landing",
    "deploy:prod": "npm run build:all && git add . && git commit -m 'Deploy web build' && git push origin main"
  }
}
```

**Single command:**
```bash
npm run deploy:prod
```

### Netlify Configuration

**`netlify.toml`:**
```toml
[build]
  command = "npm run build:all"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/game/*.wasm"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
    Content-Encoding = "br"

[[headers]]
  for = "/game/dictionaries/*.txt"
  [headers.values]
    Cache-Control = "public, max-age=2592000"
    Content-Encoding = "gzip"
```

---

## Performance Targets

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Landing TTFR | < 1s | Chrome DevTools Performance |
| Pre-fetch complete | < 10s | Network tab |
| Play button enabled | < 8s | User can click Play |
| Transition to Godot | < 2s | Fade + initialize |
| Lighthouse score | > 90 | Lighthouse audit |

---

## Testing Strategy

### Manual Testing Checklist

**Landing Page Load:**
- [ ] Visit on fast connection (fiber/5G)
- [ ] Visit on slow connection (3G throttled)
- [ ] Measure TTFR < 1s
- [ ] No FOUC (flash of unstyled content)

**Pre-fetch:**
- [ ] Progress bar updates smoothly
- [ ] All files load in parallel (Network tab)
- [ ] Play button disabled until 100%

**High Score Teaser:**
- [ ] First visit: No score shown
- [ ] After game: High score appears
- [ ] Revisit: Loads instantly (localStorage)
- [ ] Clear localStorage: Fetches from Supabase

**Language Switching:**
- [ ] English pre-fetched by default
- [ ] Spanish lazy-loads on select
- [ ] Game uses correct dictionary

**Godot Transition:**
- [ ] Landing fades out smoothly
- [ ] Godot canvas appears
- [ ] Game initializes with correct theme

**Mobile:**
- [ ] iPad (Safari): Works smoothly
- [ ] iPhone (Safari): Portrait fits
- [ ] Touch targets are 48×48px

### Performance Benchmarks

```bash
# Lighthouse audit
npx lighthouse https://word-loom-lux.netlify.app --view

# WebPageTest (real device)
# https://www.webpagetest.org/
```

---

## Future Enhancements (Out of Scope)

- Service Worker for offline support
- Animated preview GIF on landing page
- Google/Apple auth for cross-device sync
- Global leaderboard teaser
- A/B testing different landing page variants
- Error tracking (Sentry/LogRocket)

---

## Success Metrics

**Primary:**
- TTFR < 1s (measured)
- Play button enabled < 8s (measured)
- Bounce rate decreases (analytics)

**Secondary:**
- High score teaser increases return visits
- Mobile performance score > 90 (Lighthouse)
- User satisfaction (qualitative feedback)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| React bundle too large | Misses < 1s goal | Code splitting, tree-shaking, use Preact if needed |
| Pre-fetch slow on 3G | Poor UX on slow connections | Show estimated time, allow Play before 100% |
| Dictionary parsing slow | Delay game start | Use Web Worker for parsing |
| Supabase timeout | High score not shown | LocalStorage fallback, non-blocking |

---

## Open Questions

- **Answered**: Use Vite + React (Approach A)
- **Answered**: Pre-fetch English, lazy-load Spanish
- **Answered**: Replace mode (landing fades out)
- **Answered**: LocalStorage + Supabase sync
- **Answered**: Anonymous IDs for MVP, auth later

---

## Next Steps

1. Create implementation plan (use `writing-plans` skill)
2. Scaffold landing page (Vite + React)
3. Extract dictionaries from Godot export
4. Implement pre-fetch manager
5. Build Godot integration bridge
6. Test on mobile devices (iPad, iPhone)
7. Deploy to Netlify
8. Measure performance and iterate
