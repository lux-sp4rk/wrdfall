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
- [ ] Visit https://word-loom-lux.netlify.app
- [ ] Open DevTools > Network tab
- [ ] Hard refresh (Cmd+Shift+R)
- [ ] Landing page TTFR < 1s
- [ ] Run Lighthouse audit: Performance score > 90

### Compression
- [ ] Network tab: Check word-loom.wasm
- [ ] Response Headers: `Content-Encoding: br` (Brotli)
- [ ] Network tab: Check dictionaries/en.txt
- [ ] Response Headers: `Content-Encoding: gzip`

### Caching
- [ ] Network tab: Check word-loom.wasm
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
