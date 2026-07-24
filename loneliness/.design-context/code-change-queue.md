# Code Change Queue

Design decisions already made, awaiting code implementation. Each item: source (system + flag), decision, what to change, priority.

## High priority

| # | Source | Decision | Change | Status |
|---|--------|----------|--------|--------|
| 1 | System 02 Flag 1 | Add fixed-point overflow guard in call wave distance check | Pre-check `abs(dx)<range and abs(dy)<range` before `sqrt` — same pattern as Big/flower fixes | open |
| 2 | System 05 Flag 1 | Add overflow guards in 3 pollen distance paths (player repulse / Big cast push / burst push) | Same pre-check pattern in all 3 world-space distance checks | open |
| 3 | System 03 Flag 2 resolved | Big idle side-wall drift when onscreen but unengaged | Add `big_idle_drift` tunable + drift logic toward nearest side wall. Prevents player skirting `steal_range` to keep Big idle forever | open |
| 4 | System 04 Flag 4 resolved → OQ6 | Flower mis-input guard: skip `f.used=true` + burst when `f.col == pcol` | Add guard in flower charge completion: if no-op color, reset charge, don't consume flower | open |
| 5 | System 07 Flag 1 resolved | Remove hardcoded `grass[1..4]` from tab 1, derive from plant table at init | Replace hardcoded table with init loop: `grass[i]={x=p.x+12, y=p.y}` per plant | open |

## Medium priority

| # | Source | Decision | Change | Status |
|---|--------|----------|--------|--------|
| 6 | System 03 Flag 1 | Expose `post_steal` + `cast_t` as top-of-file tunables | Move hardcoded values to tunable declarations | open |
| 7 | OQ7 | Narrative Event camera lock (new mechanic) | Schema: event flag on flowers/NPCs, camera lock state, completion predicate (flower=color change; NPC=attach or flee), lock radius, multi-event ordering, editor tool | open — design + code TBD |

## Low priority

| # | Source | Decision | Change | Status |
|---|--------|----------|--------|--------|
| 8 | System 08 Flag 2 | Rename `fade_t` local in intro draw (shadows global) | Rename to `intro_fade_t` or similar for readability | open |
| 9 | System 04 Flag 3 | Delete dead tunables `flower_burst_r`, `flower_radius` | Remove unused declarations | open |
| 10 | System 08 Flag 3 | Wide-flag centering: `\^w` uses 8px chars but centering computes 4px/char → text off-center | Compute width properly or document | open |

## Deferred

| # | Source | Decision | Change | Status |
|---|--------|----------|--------|--------|
| 11 | OQ3 / T2 | Replace flower "hold x" prompt with visual affordance | Glow intensify on approach, pulse on hold-start. Cut `print("hold ❎", ...)` | deferred by user |
| 12 | OQ8 | Level-editor enforcement: no flower within `steal_range=56` of Big spawn | Add validation rule in `level_editor.html` | deferred |
| 13 | System 03 Flag 3 | Big offscreen cast continuation bug | `big_onscreen` only gates cast entry, not continuation. Defer until observed | deferred per user "wait and see" |