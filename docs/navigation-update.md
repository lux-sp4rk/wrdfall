# Status Report: Word Loom Navigation & Settings

## Changes
- **New Home Screen (`scenes/Home.tscn`):** Created a main entry point with "Play" and "Settings" buttons.
- **New Settings Screen (`scenes/Settings.tscn`):** Added a dedicated screen for language swapping (English/Spanish).
- **Global Settings (`scripts/GameSettings.gd`):** Implemented an autoload singleton to persist language choice across scene changes.
- **Updated `project.godot`:** Set `Home.tscn` as the main scene and registered `GameSettings` as an autoload.
- **Updated Game Scene (`scenes/LoomDrop.tscn`):**
  - Replaced the in-game language selector with an "Exit" button to return to the Home screen.
  - Linked the game start to use the language selected in Settings.

## Next Steps
- Verify the scene transitions in the Godot editor.
- Consider adding more settings (e.g., volume, color themes) to the new screen.
