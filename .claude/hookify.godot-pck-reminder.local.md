---
name: godot-pck-reminder
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.gd$
---

⚠️ **GDScript changed — PCK rebuild required for web!**

You just edited a `.gd` file. This change is **not live on web** until you re-export the PCK.

**Rebuild:**
```
npm run export:godot
```

React/JS changes in `landing/` do NOT need a PCK rebuild — only GDScript changes do.
