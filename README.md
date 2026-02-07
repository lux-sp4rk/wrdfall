# Word Loom

Calm, senior-first word puzzle (no ads) designed for iPad/phone/browser.

This folder holds the product spec, starter content, and a Godot 4.x prototype.

## Running the game

1. Install [Godot 4.3+](https://godotengine.org/download/) (standard or .NET edition).
2. Open Godot and choose **Import** > navigate to `godot/project.godot`.
3. Press **F5** (or the Play button) to run. You'll see the Title screen with a Start button that leads to the placeholder Puzzle screen.

## HTML5 export (for browser/iPad testing)

1. In Godot, go to **Project > Export...**.
2. Add a **Web** export preset.
3. Click **Export Project** and save to a folder (e.g. `build/web/`).
4. Serve locally: `python3 -m http.server -d build/web/ 8000` then open `http://localhost:8000`.

## Project structure

```
godot/
  project.godot          # Godot project config
  scenes/
    Title.tscn           # Title screen (main scene)
    Puzzle.tscn           # Puzzle placeholder (loom slots + letter tray)
  scripts/
    Title.gd              # Start button -> Puzzle scene
    Puzzle.gd             # Populates letter tray, back navigation
```

See `SPEC.md` for the full game design and `build-plan.md` for the phased roadmap.
