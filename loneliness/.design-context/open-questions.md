# Open Questions

| # | Question | Raised | Status |
|---|----------|--------|--------|
| OQ1 | Does permanent loss risk an unrecoverable "empty" late-game emotional state, and is that intentional grief or a softlock? | 2026-07-24 | open — block on ending beat design |
| OQ2 | ~~Does the session reach a written conclusion?~~ | 2026-07-24 | **resolved 2026-07-24** — narrative game, story has an end. Ending beat required. P3 forbids score/win *metrics*, not a story conclusion. Design TBD. |
| OQ3 | Flower "hold x" prompt (T2) — direct P2 violation. Replace with visual affordance (flower glow intensify on approach, pulse on X-hold start, orbit particles already exist). Pick replacement signal + cut prompt. | 2026-07-24 | open — deferred by user |
| OQ4 | What is the ending beat trigger and form? Narrative conclusion must exist (OQ2 resolved). Needs: trigger condition, text/visual/music treatment, credits transition. Blocks final GDD section. | 2026-07-24 | open — raised from OQ2 resolution |
| OQ5 | Big NPC: implement idle side-wall drift (Flag 2 resolved)? Tunable `big_idle_drift` proposed. Also: expose `post_steal` + `cast_t` as tunables (Flag 1). Also: offscreen cast continuation bug (Flag 3) — defer until observed? | 2026-07-24 | open — design decision locked, code change TBD |
| OQ6 | Flower color-change mis-input guard — when `f.col == pcol` at charge completion, skip `f.used=true` + burst, reset `f.charge=0`. Implement in code. | 2026-07-24 | open — code change TBD |
| OQ7 | Narrative Event camera lock (new mechanic raised 2026-07-24). Schema: event flag on flowers/NPCs, camera lock state, completion predicate (flower=color change; NPC=attach or flee), lock radius, multi-event ordering, placement tool in `level_editor.html`. Not in code yet. | 2026-07-24 | open — design + code TBD |
| OQ8 | Level-editor enforcement: no flower within `steal_range=56` of Big spawn (Flower Flag 2 resolution). Add as validation rule in `level_editor.html`? | 2026-07-24 | open — editor change TBD |

## Resolved
| # | Question | Resolution |
|---|----------|------------|
| OQ2 | Ending beat? | 2026-07-24: narrative game, ending required, design TBD (OQ4) |