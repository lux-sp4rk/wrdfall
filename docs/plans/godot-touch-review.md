# Godot 4.6 HTML5 Touch Input Review

## Current Status
- **Project Version:** Confirmed `config/features=PackedStringArray("4.6")`.
- **Input Handling:** `LoomDrop.gd` currently relies on `InputEventMouseButton`.
  ```gdscript
  func _input(event: InputEvent) -> void:
      if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
          ...
      elif event is InputEventMouseMotion and is_selecting:
          ...
  ```

## Issues & Risks
1. **Emulation Dependency:** Relying on `InputEventMouseButton` for touch input on mobile/HTML5 requires "Emulate Mouse From Touch" (enabled by default, but can be inconsistent across browsers).
2. **Multi-touch:** `InputEventMouseButton` does not support multi-touch gestures (e.g., pinch to zoom, two-finger tap). If the game design requires this, `InputEventScreenTouch` / `InputEventScreenDrag` must be implemented.
3. **Latency:** Some HTML5 exports experience input lag with mouse emulation compared to native touch events.

## Recommendations
1. **Explicit Touch Handling:** Update `_input(event)` to handle `InputEventScreenTouch` and `InputEventScreenDrag` explicitly.
   ```gdscript
   func _input(event):
       if event is InputEventScreenTouch:
           if event.pressed:
               _on_touch_start(event.position)
           else:
               _on_touch_end(event.position)
       elif event is InputEventScreenDrag:
           _on_touch_drag(event.position, event.relative)
   ```
2. **Project Settings:** Ensure `input_devices/pointing/emulate_touch_from_mouse` and `input_devices/pointing/emulate_mouse_from_touch` are configured correctly in `project.godot` if sticking with mouse events (defaults are usually fine but explicit is better for clarity).
3. **Testing:** Test on actual mobile device via HTML5 export, as desktop browser emulation often behaves differently regarding touch points.

## Action Plan
- [ ] Refactor `LoomDrop.gd` to include `InputEventScreen*` handling.
- [ ] Verify `project.godot` input settings.
