# Word Loom — Oracle Notes (senior-first puzzle design)

## Best practices (UX + cognitive load)
- High contrast (aim WCAG AAA-ish), large type.
- Tap targets >= 44px; snap-to-grid / forgiving drag.
- No timers by default (stress kills performance).
- Keep all needed info visible (no screen-flipping).
- Favor familiar, common vocabulary (frequency-weighted lists).
- Minimal UI noise (no busy backgrounds).
- Hints should create forward progress, not just scold.
- Unlimited undo.
- Simple progression map (linear, not branching).

## Rule types (safest → riskiest)
1) Linear word search / simple find (very familiar)
2) Missing-letter / fill-in (context helps)
3) Letter-connection (spatial planning but intuitive)
4) Anagrams (higher cognitive load; keep short)
5) Thematic association (subjective → frustration risk)
6) Abstract constraint stacking (working memory load)

## Common failure modes + mitigation
- “Ghost answers” (valid words not accepted) → use a real dictionary, allow bonus words, or accept any valid word meeting the rule.
- Obscure vocab sneaks in → restrict to top N by frequency.
- Grid/text too dense on mobile → cap grid sizes; add padding.
- Ambiguous input feedback → immediate pressed state + confirm feedback.
- Difficulty spikes → tag words by complexity and smooth the curve.
