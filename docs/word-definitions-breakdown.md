# Word Definitions — Implementation Breakdown

**Spec:** `features/word-definitions.feature`
**Parent Issue:** github.com/lux-sp4rk/wrdfall/issues/59

---

## Layer 1 — Data Tracking
**Issue label:** `word-defs-data`
**File:** `godot/scripts/StatsManager.gd`

**What to do:**
- Add two new properties:
  - `word_frequency: Dictionary`   # word → use count
  - `word_top_score: Dictionary`   # word → highest single-word score
- New method `record_word(word: String, tiles_cleared: int, word_score: int)` — update both dicts and `longest_word`
- Persist both dicts under a new `[words]` section in `save_stats()` as JSON
- Load them back in `load_stats()`
- Web blob (for React shell) should also include both dicts

**Acceptance:**
- Score "QUARTZ" twice in one session → frequency=2, top_score=max(both scores)
- Close/reopen → both dicts restored
- Unknown word → no crash, dict entries created normally

---

## Layer 2 — Dictionary API Service
**Issue label:** `word-defs-api`
**File:** `godot/scripts/WordDefinitionService.gd` (new)

**What to do:**
- Fetch from `https://api.dictionaryapi.dev/api/v2/entries/en/<word>` via HTTPRequest
- Emit signal: `definition_fetched(word: String, definition_text: String, is_error: bool)`
- `is_error = true` for: word not in dict, network failure, redirect loop
- Session-level cache: `Dictionary` to avoid re-fetching the same word within one run

**Acceptance:**
- "quartz" → definition string with at least one meaning returned
- "xyzqwerty" → `is_error = true`, no crash
- Same word fetched twice → second call uses cache, no new HTTP request
- Device offline → `is_error = true`, no crash, no error notification

---

## Layer 3 — Stats Screen UI Rows
**Issue label:** `word-defs-ui`
**File:** `godot/scripts/Stats.gd` (+ scene edits)

**What to do:**
- Add two new `@onready` rows: `most_played_row`, `highest_score_word_row`
- Each row: word name label + badge (use count or pts) + definition label with loading state
- `_update_display()` computes:
  - Most played: word with highest count in `word_frequency`
  - Highest score word: word with highest value in `word_top_score`
  - Tie-break: most recent scorer wins (add `word_last_scored: Dictionary` timestamp map if needed)
- Fetch definition for each word via `WordDefinitionService.fetch_definition()`
- Show loading indicator → resolve to text or muted "No definition found"
- Add theme updates to `_apply_theme()` for both new rows

**Acceptance:**
- No words scored → both rows show "—" with no definition
- "QUARTZ" scored 12 times → row shows "QUARTZ (12)" with async definition below
- Offline → definition area shows muted "—"
- Theme change → rows update colors correctly

---

## Layer 4 — Definition Detail Popup
**Issue label:** `word-defs-modal`
**File:** `godot/scripts/Stats.gd`

**What to do:**
- Tap the definition text label → open modal (ConfirmationDialog or custom Panel)
- Modal title: word in large text
- Modal body: all entries — part of speech, phonetic, all definitions bulleted
- Close button dismisses
- Theme to match game UI

**Acceptance:**
- Tap definition → modal opens with full dictionary entry
- Word with 3 meanings → all 3 shown as separate bullets
- Close → modal dismisses
- No tap required to read short inline definition on the row itself

---

## Layer 5 — React Shell / Web Blob (optional, later)

- `save_stats()` already writes the web blob — add `word_frequency` and `word_top_score` to it
- React Stats page can fetch definitions client-side from `dictionaryapi.dev`
- Not needed for Godot native; nice-to-have for web parity

---

## Recommended Issue Labels

| Label | Layer | Owner |
|-------|-------|-------|
| `word-defs-data` | Layer 1 — StatsManager data tracking | |
| `word-defs-api` | Layer 2 — Dictionary API service | |
| `word-defs-ui` | Layer 3 — Stats screen rows | |
| `word-defs-modal` | Layer 4 — Definition detail popup | |
