# Slim Agents Report

## Summary

| File | Original Lines | New Lines | Reduction |
| :--- | :--- | :--- | :--- |
| `ARCHITECTURE.md` | 347 | 56 | 84% |
| `CODE_STYLE.md` | 397 | 52 | 87% |
| `AGENTS.md` | 44 | 44 | 0% (Polished) |
| **Total** | **788** | **152** | **81%** |

## Anti-Patterns Removed

- [x] **Code blocks**: Removed over 200 lines of example GDScript across files.
- [x] **Directory listings**: Removed the 70-line `tree` output from `ARCHITECTURE.md`.
- [x] **Redundant Tables**: Consolidated Autoloads and Scenes into concise lists with pointers.
- [x] **Verbose Sections**: Condensed multi-paragraph explanations into one-liners and tables.

## Non-Obvious Context Preserved

| Context | Location in New File | Importance |
| :--- | :--- | :--- |
| **PCK Footgun** | `ARCHITECTURE.md`, `AGENTS.md` | Prevents failed web deployments. |
| **JavaScript Bridge** | `ARCHITECTURE.md` | Explains essential Godot-to-React communication. |
| **Signal Naming** | `CODE_STYLE.md` | Ensures consistency (`past_tense`). |
| **LFS Tracking** | `AGENTS.md` | Critical for managing large binary files. |

## Validation Results

- [x] **Line count**: All files are <60 lines.
- [x] **Code blocks**: No block exceeds 5 lines.
- [x] **File references**: All use `[file:line](path)` format.
- [x] **Non-obvious emphasis**: Highlighted critical build and platform patterns.

## Migration Notes

- **Code Examples**: Long examples were removed. Agents should refer to:
  - [godot/scripts/Home.gd](godot/scripts/Home.gd) for script structure.
  - [godot/scripts/LoomDrop.gd](godot/scripts/LoomDrop.gd) for core game logic and typing.
  - [godot/tests/test_drop_ratchet.gd](godot/tests/test_drop_ratchet.gd) for testing patterns.
