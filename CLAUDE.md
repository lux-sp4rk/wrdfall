# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Word Loom is a calm, senior-first word puzzle game (no ads) targeting iPad, phone, and browser. The repo is currently in the **pre-code design phase** — it contains the product spec, puzzle content, and design notes but no application code yet.

## Key Design Documents

- `SPEC.md` — Full product spec: core loop, rules, Loom Drop mode, hints, UX constraints, monetization
- `build-plan.md` — Phased build plan; Phase 0 is a web-first prototype playable on iPad
- `research/oracle-notes.md` — Senior-first UX research and puzzle design best practices
- `puzzles/` — Hand-crafted puzzle sets (starter-10, flash-pack-30) in markdown table format
- `packs/pack-ideas.md` — Theme pack concepts
- `monetization/arrow-notes.md` — Ethical pricing model (paid base game, no subscriptions)

## Game Modes

1. **Tapestry mode (core)**: Player gets a letter tray + rule constraints, drags letters into loom slots to form valid words. Puzzles have 1–3 word slots with rules like length, starts-with, ends-with, contains.
2. **Loom Drop (optional Tetris-flavor)**: Grid-based mode with 4-direction adjacency path-finding, gravity, letter spawning, and a spatial "jam" loss condition (no timers).

## Architecture Intent (Phase 0)

- Single-page web app, static hosting, offline-friendly
- Touch-first UI with large tap targets (>=44px), high contrast
- Local wordlist for validation (no server required)
- 10 starter puzzles hard-coded as JSON
- Potential future wrapping with Tauri/Capacitor for native app feel

## Design Constraints

- No ads, no timers (default), no energy systems
- Hints must create forward progress (nudge → reveal letter → reveal word)
- Accept any valid dictionary word meeting rule constraints (avoid "ghost answers")
- Font size default large (18–20pt+), WCAG AAA-ish contrast
- Vocabulary restricted to common/familiar words (frequency-weighted)
- Unlimited undo always visible
