# AGENTS.md — Word Loom Instructions

## Project Context
Word Loom is a strategic word puzzle game built with **Godot 4.6 (GDScript)** — strategic word puzzles meet Tetris.
- **Target**: iPad, phone, browser (HTML5).
- **Style**: High contrast, large tap targets, senior-first design.
- **Game mode**: **Loom Drop** — Tetris-style falling letters on a 5×5 grid with word-swiping.

## Project Structure
```
godot/
  project.godot        # Godot 4.6 config (main scene: Home.tscn)
  scenes/              # Game scenes (.tscn)
  scripts/             # GDScript files (.gd)
  data/                # Dictionaries and game data
landing/
  public/              # Canonical Godot web exports (index.wasm, index.pck, etc.)
  src/                 # React landing page source
dist/                  # Final production build (generated from landing/)
docs/                  # Design docs and rules
```

## Key Workflows
- **Sync**: Run `npm run sync` before starting work to update `main` and prune merged branches.
- **Local Dev**: Open `godot/project.godot` in Godot 4.6 and press F5.
- **Web Export**: Run `npm run build:godot`. This exports the Godot project to `landing/public/`.
- **Full Build**: Run `./build.sh` to export Godot AND build the React landing page into `dist/`.
- **Deployment**: Netlify deploys from `dist/`.

## Web Deployment & LFS
- **Canonical Exports**: `landing/public/` contains the canonical Godot binaries. These MUST be committed.
- **Git LFS**: `.wasm` and `.pck` files are tracked via Git LFS.
- **Automated CI**: GitHub Actions rebuild the Godot export on PRs for deploy previews, but they **do not** commit back to your branch to avoid history conflicts. You must commit your local exports for the final merge.

## Code Style (GDScript)
- **Godot 4.6**: Use `signal.connect(callable)` and static typing.
- **Nodes**: Use `@onready` and `%UniqueNames`.
- **Naming**: `snake_case` for members, `PascalCase` for classes.

## Game Rules
See `docs/game-rules.md` for scoring, multipliers, and mechanics.
- **5×5 grid**, 8-directional selection, 3+ letter words.
- **Combo streak**: 4+ letter words build multiplier.
- **Drop ratchet**: Speed increases every 5 drops.
