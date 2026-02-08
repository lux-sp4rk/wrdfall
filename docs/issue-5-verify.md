# Issue #5 verification (offline word validation + rule checking)

## Pre-req
- Open the Godot project at `word-loom/godot/project.godot`.

## Manual checks

### A) Loom Drop: invalid word rejected
1. Run the project.
2. Start **Loom Drop** (from the Title screen).
3. Drag-select 3+ letters to form something that is **not** in `res://data/words.txt`.
4. Release mouse.

Expected:
- No tiles are cleared.
- Score does not change.
- The label shows: `Not a valid word.`

### B) Loom Drop: valid word accepted
1. Run the project.
2. Start **Loom Drop**.
3. Select letters that form `HELLO` or `WORLD` (both are in `res://data/words.txt`).

Expected:
- Word is accepted.
- Score increases.
- Selected tiles clear, gravity applies, new letters spawn.
- Label shows `+<points>`.

## Lightweight script check (editor)

Option 1 (quick):
- Open `godot/scripts/ValidationSmokeTest.gd`.
- Temporarily attach it to any test scene as a Node.
- Add in `_ready()`:
  - `ValidationSmokeTest.run()`

Expected output:
- Prints: `ValidationSmokeTest: OK`
- No assertion failures.
