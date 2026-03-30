# Tagline Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update Wordfall's tagline from "A calm, senior-first word puzzle game" to "Strategic word puzzles meet Tetris" across all documentation files and remove "no ads" claim.

**Architecture:** Simple text replacements across 3 documentation files (README.md, CLAUDE.md, docs/game-rules.md). No code changes required.

**Tech Stack:** Markdown documentation, Git

---

## Task 1: Update README.md Tagline

**Files:**
- Modify: `README.md:3`

**Step 1: Read current README.md**

Verify the current content at line 3:

```bash
head -5 README.md
```

Expected: Line 3 contains "A calm, senior-first word puzzle game built with **Godot 4.6** (GDScript). No ads, no timers, high contrast, large tap targets."

**Step 2: Update tagline in README.md**

Replace line 3 with new tagline and remove "no ads" claim:

**Old:**
```markdown
A calm, senior-first word puzzle game built with **Godot 4.6** (GDScript). No ads, no timers, high contrast, large tap targets. Targets iPad, phone, and browser (HTML5).
```

**New:**
```markdown
**Strategic word puzzles meet Tetris.** Built with Godot 4.6 (GDScript). High contrast, large tap targets. Targets iPad, phone, and browser (HTML5).
```

Use Edit tool to make the change.

**Step 3: Verify the change**

```bash
head -5 README.md
```

Expected: Line 3 now shows the new tagline with bolded "Strategic word puzzles meet Tetris" and no "No ads" claim.

**Step 4: Commit README.md update**

```bash
git add README.md
git commit -m "docs: update README tagline to reflect strategic gameplay

Replace 'calm, senior-first word puzzle' with 'Strategic word
puzzles meet Tetris' to accurately represent game mechanics (combo
streaks, drop speed ratchet, mounting pressure).

Remove 'no ads' claim to allow future monetization.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Update CLAUDE.md Tagline

**Files:**
- Modify: `CLAUDE.md:4`

**Step 1: Read current CLAUDE.md project context section**

```bash
head -10 CLAUDE.md
```

Expected: Line 4 contains "Wordfall is a calm, senior-first word puzzle game built with **Godot 4.6 (GDScript)**."

**Step 2: Update tagline in CLAUDE.md**

Replace line 4 with new positioning:

**Old:**
```markdown
Wordfall is a calm, senior-first word puzzle game built with **Godot 4.6 (GDScript)**.
```

**New:**
```markdown
Wordfall is a strategic word puzzle game built with **Godot 4.6 (GDScript)** — strategic word puzzles meet Tetris.
```

Use Edit tool to make the change.

**Step 3: Verify the change**

```bash
head -10 CLAUDE.md
```

Expected: Line 4 now shows "strategic word puzzle game" and includes "strategic word puzzles meet Tetris" tagline.

**Step 4: Commit CLAUDE.md update**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md tagline for accurate positioning

Replace 'calm, senior-first' with 'strategic word puzzle game'
and add tagline reference to maintain consistency with README.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Update docs/game-rules.md Tagline

**Files:**
- Modify: `docs/game-rules.md:3`

**Step 1: Read current game-rules.md introduction**

```bash
head -5 docs/game-rules.md
```

Expected: Line 3 contains "Wordfall is a calm, senior-first word puzzle game. The primary game mode is **Loom Drop**..."

**Step 2: Update tagline in game-rules.md**

Replace line 3 with new description:

**Old:**
```markdown
Wordfall is a calm, senior-first word puzzle game. The primary game mode is **Loom Drop** — a Tetris-style falling-letter puzzle where you swipe to form words on a 5x5 grid.
```

**New:**
```markdown
Wordfall is a strategic word puzzle game where word-building meets Tetris. The primary game mode is **Loom Drop** — a Tetris-style falling-letter puzzle where you swipe to form words on a 5x5 grid.
```

Use Edit tool to make the change.

**Step 3: Verify the change**

```bash
head -5 docs/game-rules.md
```

Expected: Line 3 now shows "strategic word puzzle game where word-building meets Tetris".

**Step 4: Commit game-rules.md update**

```bash
git add docs/game-rules.md
git commit -m "docs: update game rules tagline for consistency

Replace 'calm, senior-first' with 'strategic word puzzle game
where word-building meets Tetris' to align with new positioning.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Verify Consistency Across All Documentation

**Files:**
- Read: `README.md`
- Read: `CLAUDE.md`
- Read: `docs/game-rules.md`

**Step 1: Search for remaining "calm" references**

Verify that all "calm, senior-first" references have been updated:

```bash
grep -n "calm" README.md CLAUDE.md docs/game-rules.md
```

Expected: No matches (or only matches in unrelated contexts, not in tagline descriptions).

**Step 2: Search for "no ads" references**

Verify that "no ads" claim has been removed from positioning:

```bash
grep -n "No ads" README.md CLAUDE.md docs/game-rules.md
```

Expected: No matches in main positioning text.

**Step 3: Verify new tagline presence**

Confirm new tagline appears in all three files:

```bash
grep -n "Strategic word puzzles meet Tetris" README.md CLAUDE.md docs/game-rules.md
```

Expected: 3 matches (one in each file).

**Step 4: Final visual review**

Read the introduction section of each file to confirm:
- README.md: Tagline is prominent and clear
- CLAUDE.md: Project context accurately reflects strategic positioning
- game-rules.md: Introduction matches overall messaging

---

## Task 5: Create Summary Commit (Optional Squash)

**Note:** Only do this if the individual commits were made as separate commits. If you prefer a single atomic commit for the tagline update, squash the previous commits.

**Step 1: Review commit history**

```bash
git log --oneline -4
```

Expected: See 3 commits for README.md, CLAUDE.md, and game-rules.md updates.

**Step 2: (Optional) Interactive rebase to squash**

If you want a single commit for the entire tagline update:

```bash
git rebase -i HEAD~3
```

In the editor, change:
```
pick <commit1> docs: update README tagline to reflect strategic gameplay
pick <commit2> docs: update CLAUDE.md tagline for accurate positioning
pick <commit3> docs: update game rules tagline for consistency
```

To:
```
pick <commit1> docs: update README tagline to reflect strategic gameplay
squash <commit2> docs: update CLAUDE.md tagline for accurate positioning
squash <commit3> docs: update game rules tagline for consistency
```

**Step 3: Edit squashed commit message**

Use this message:
```
docs: update tagline across all documentation

Replace "calm, senior-first word puzzle" with "Strategic word
puzzles meet Tetris" to accurately reflect current gameplay:
- Combo streak system rewards risky play
- Drop speed ratchet creates mounting pressure
- Strategic tension between safety and speed management

Also remove "no ads" claim to allow future monetization.

Updated files:
- README.md: Main project tagline
- CLAUDE.md: Project context description
- docs/game-rules.md: Game introduction

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Step 4: Verify final state**

```bash
git log --oneline -2
git status
```

Expected: Clean working tree, single commit for tagline update (or 3 separate commits if not squashed).

---

## Verification Checklist

Before marking complete, verify:

- [ ] README.md line 3 contains "Strategic word puzzles meet Tetris" (bolded)
- [ ] README.md does not contain "No ads" in main description
- [ ] CLAUDE.md line 4 contains "strategic word puzzle game" and tagline
- [ ] docs/game-rules.md line 3 contains "strategic word puzzle game where word-building meets Tetris"
- [ ] No remaining "calm, senior-first" references in tagline positions
- [ ] All changes committed to git
- [ ] Working tree is clean

---

## Success Criteria

1. **Consistency:** All three documentation files use the new "Strategic word puzzles meet Tetris" positioning
2. **Accuracy:** New tagline reflects current gameplay mechanics (combo streaks, drop ratchet, strategic tension)
3. **Future-proof:** "No ads" claim removed to allow monetization options
4. **Git history:** Clean commits with clear messages
