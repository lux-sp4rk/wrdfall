# Wordfall Bestiary
*Project-specific bug encounters and lore*

---

## The Mimic (Heisenbug)
*First encounter: 2026-05-04*

### The Sighting

During PR #267 (particle burst + floating score label), the TopNavBar was exhibiting an errant "+N" word score animation that should have been removed. Signal connections were severed in `LoomDrop.gd` and `TutorialLoomDrop.gd`. The function itself was gutted in `TopNavBar.gd`. A fresh clone on a clean machine still displayed the ghost score.

### The Nature of the Creature

The bug vanished under observation. Every instrument brought to bear — signal disconnection, function nulling, fresh repo clone — the creature shifted shape and survived. The Mimic does not die when you look at it directly. It becomes what it needs to be.

### The Trap

Root cause could not be definitively pinned. Working theories:
- Stale Godot bytecode cache in `.godot/` folder
- Pre-exported Mac binary with embedded signal connections
- Some unknown code path that was never found

### The Exorcism

```gdscript
# TopNavBar.gd — show_word_score() reduced to a no-op
func show_word_score(points: int, word_length: int) -> void:
    pass  # Mimic containment — TopNavBar score animation disabled
```

The FloatingScoreLabel at the board continues to function. Only the TopNavBar animation was removed.

### Lessons Learned

- A Mimic is not a ghost. Doubt yourself, not the observation.
- When the bug survives a fresh clone, the environment is not the problem — something in the build artifacts is.
- The workaround (making the function a no-op) is not the same as understanding. The creature is still there. We just built a cage around it.

---

*Last updated: 2026-05-04*