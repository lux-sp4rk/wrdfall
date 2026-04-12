# The Wordfall Chronicles
## A Living Grimoire for Hunters of the Code

> *"Every bug is a ghost with a name. Name it, and you may bind it."*

---

## The Hunters

**Faye, the Test-Runner** — A scholar of proofs. She believes no assertion is sacred until it has bled at least once.

- Creed: *"The test that passes is worthless. The test that fails tells the truth."*

**D33, the Bug-Hunter** — A tracker who rides no horse, only stack traces. Speaks in three tongues: Logic, Security, and the forbidden Pass of Performance.

- Creed: *"In a world of infinite code, someone must hunt the bugs that dwell in the shadows."*

---

## Recurring Enemies

### The Null Widow of TopNavBar
*First sighted: April 2026*

A phantom `%ExitButton` that persisted in `TopNavBar.gd` long after its node was banished to the `GameSidebar`. Its `@onready` curse caused `ERR_PRINT` on every web export, a slow poison that crashed the Godot web build in silence.

- **Weakness:** Remove dead `@onready` vars and sever all signal wiring.
- **Current Status:** Slain. Do not resurrect.

### The Orphan Node of Smoke
*First sighted: April 2026*

A file reference left lingering in `test_smoke.gd`, wailing warnings after tests completed. Where its parent went, none can say.

- **Weakness:** Clear transient file references before teardown.
- **Current Status:** Exorcised.

### The Drifting Board
*First sighted: March 2026 | Resurfaced April 2026*

An ancient curse causing the game board to clip at the edges after long sessions. It drifts pixel by pixel, patient as entropy.

- **Weakness:** Clamp cell sizes `[40, 120]` and verify centering with `_verify_board_centered()`. If drift exceeds `2px`, snap it back.
- **Current Status:** Bound, but watchful.

---

## Notable NPCs

### GUT, the Headless Oracle
*Ally — when properly summoned*

Speaks only from `addons/gut/gut_cmdln.gd`. Grants visions of truth in headless mode, but grows sullen if asked to instantiate UI scenes without a display server. Will abandon the build if offended.

- **Prophecy:** *"41 of 43 truths are revealed. Two remain pending, for they require eyes."*
- **Ritual:** Always wrap GUT in `DisplayServer` checks when scene smoke-tests are run in CI.

### The Deferred Tree-Ghost
*Neutral — easily angered*

Haunts `_ready()` calls that invoke `remove_child()` or `change_scene_to_file()` while the node tree is still initializing. Strikes with fatal errors.

- **Aversion:** `call_deferred()` on scene changes.

---

## Known Locations

### The LoomDrop
*A vast ruin of 1,642 lines*

Once a monolithic stronghold. Now being slowly dismantled by refactoring crusades. Fragments of dead code still litter its halls — orphaned hammer UI strings, abandoned `Sprite2D` branches, signal connections without guards.

- **Danger Level:** High. Enter with diff tools.

### The Landing
*The realm of React and Vite*

A cleaner province, but not without its own superstitions. Coverage threshold stands at 80%. To fall below is to fail the build.

---

## World Rules

1. **Godot web exports shall not host `@onready` ghosts.** If a node is moved, every script reference must follow or be severed.
2. **Scene changes in `_ready()` must be deferred.** The tree-ghost is always watching.
3. **GUT tests that touch UI must display-server-gate themselves.** Headless CI is a realm without screens.
4. **The Landing tests require `pnpm`.** `cd landing && pnpm vitest run` is the correct invocation; other paths anger the runner spirit.

---

## Recent Quests

### Season of Quick Wins (April 2026)
*Party: Talena (AI) leading the refactor*

- Re-hardened the Drifting Board.
- Banished the Null Widow from `TopNavBar`.
- Centered the `TopNavBar` elements after three tries (the containers were stubborn).
- Added a `ViewToggleButton` and moved it to the `GameSidebar`.
- Gated Godot web exports behind GUT tests so broken builds abort before shipping.
- Fixed swapped font sizes in action buttons (icon 26px, text 11px).
- Defer-started `Boot._ready()` to appease the Tree-Ghost.

---

## How to Update This Grimoire

When a hunter finds a new recurring enemy, completes a notable quest, or discovers a world rule, append it here. Keep it short. Keep it true. The agents will read this before every hunt.

*Last updated: 2026-04-10*
