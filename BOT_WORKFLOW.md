# Word Loom — Bot Workflow (Claude Code)

## Role split
- **Talena (manager):** issues, scope, acceptance criteria, playtests, merges.
- **Claude Code (implementer):** code changes + commits + PRs.

## Hard rules
1) Work only in local dir: `/home/uli/Projects/word-loom`.
2) All changes go through a branch + PR to `lux-sp4rk/word-loom`.
3) No scope creep: implement *only* the linked issue’s acceptance criteria.
4) Keep changes small. If uncertain, ask in the issue before building.

## Standard PR checklist
- Links the issue (e.g., `Closes #2`).
- Includes run steps + screenshots/GIF if UI.
- Notes any tradeoffs or follow-ups as checklist items.

## Branch naming
- `issue-2-godot-bootstrap`
- `issue-7-html5-pages`

## Definition of done
- Acceptance criteria met.
- Build runs locally.
- For UX changes: quick playtest notes captured (Mom/Hector when applicable).
