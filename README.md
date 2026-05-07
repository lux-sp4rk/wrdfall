# Wordfall

**Strategic word puzzles meet Tetris.**

[▶ Play Wordfall on Vercel](https://wrdfall.vercel.app)

![Wordfall gameplay](https://github.com/lux-sp4rk/wordfall/assets/screenshot.png)

Built with Godot 4.6 (GDScript). High contrast, large tap targets. Targets iPad, phone, and browser (Web export).

## Game Overview

**Loom Drop** — letters fall onto a 5×5 grid. Swipe adjacent tiles (8 directions) to spell words. Matched letters clear, gravity pulls remaining tiles down. Score uses multiplicative formula: `letter_sum × length_multiplier × combo_multiplier`.

- **Two difficulty modes** (Normal / Hard) with different drop speeds, power-up costs, and vowel ratios
- **Three power-ups** — Shake, Swap, Draw More (cost score points)
- **Combo streaks** — consecutive 4+ letter words build a score multiplier (cap 3.0×)
- **Drop speed ratchet** — pace increases over time; 5+ letter words reset it
- **Two languages** — English and Spanish, switchable in Settings
- **Light/dark themes** — switchable in Settings, persisted across sessions

Full rules: [`docs/game-rules.md`](docs/game-rules.md)

## Contributing

Fork the repo, create a branch, open a PR. See [`docs/plans/`](docs/plans/) for feature designs.

## License

MIT
