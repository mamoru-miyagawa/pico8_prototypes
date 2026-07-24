# Design Pillars

## Current Pillars

### P1 — Always Move Forward
- **Statement:** The player only moves forward; there is no going back.
- **What this enables:** Infinite procedural ascent, no map data, parallax pollen/grass, ratchet camera, irreversible progress.
- **What this forbids:** Backtracking, lateral exploration, downward camera, grounded level layouts, do-overs for lost bonds.
- **How we verify:** `cam_y` only decreases (ratchet); bottom clamp blocks downward motion; no `__map__` reload; no reset of attached/detached NPC state on retreat.
- **Tensions:** P3 (loss is permanent → forward-only amplifies loss cost).

### P2 — Show, Don't Tell
- **Statement:** Never tell the player what to do; use UX, visual affordance, and gameplay behavior to guide the player through.
- **What this enables:** Color matching read from NPC appearance, orbit feedback on attach, call-wave visual, Big NPC cast ring as warning, flower visual distinction (sprite 9 vs 10).
- **What this forbids:** Tutorial text in gameplay, button prompts, hint arrows, spoken instruction, system messages.
- **How we verify:** No `print(...)` instruction during `state=="play"`; any on-screen text is diegetic flavor only (intro screen is pre-play, see T1 resolution).
- **Tensions:** None active with P1/P3. **Open: flower "hold x" prompt (T2) — unresolved.**

### P3 — Emotion Is the Only Currency
- **Statement:** Emotion is the only currency — no score, no fail state, no progression metric competes with how the player feels.
- **What this enables:** Growth-as-bond (light/glow/music scale with `att`), loss-as-grief (Big steal / detach / range-lose), identity shift (color change severs mismatched bonds), ascent-as-distance-without-destination.
- **What this forbids:** Score counter, leaderboard, fail/game-over screen, win-condition metric, XP/level, achievements, session statistics, completion percentage.
- **How we verify:** No `score=` global; no `state=="gameover"`; `att` feed goes to glow/music only, never a displayed stat; ending (when added) triggers on narrative beat, not score threshold.
- **Tensions:** P1 (permanent loss must not softlock emotional arc — see OQ1); P3 implies an ending beat is required since "play forever" is itself a progression framing (see OQ2).

## Pillar Evolution

### 2026-07-24 — Initial pillar set locked
- **Set:** P1 Always Move Forward / P2 Show Don't Tell / P3 Emotion Is the Only Currency.
- **Process:** Started with 5 candidate pillars drafted from devlog scan (P1 Ascent-Only, P2 Growth-Via-Match, P3 Loss-Is-Real, P4 Color-Change Costs Bonds, P5 Ends-With-A-Beat). User rejected P5 as aspirational-systemic, not a true pillar; user supplied 3 contextual-emotional pillars instead. Reframed all three into the pillar anatomy (statement / enables / forbids / verify / tensions). P3 failed `gdd.py pillar` validation ("doesn't describe player experience; no forbid clause"); user picked reframe 3c ("Emotion is the only currency — no score, no fail, no progression metric competes with how the player feels"), validated strong.
- **Rationale:** Pillars are the central validation axis. They must be specific, observable, contradictable, and forbid something. The user's contextual phrasings captured intent better than my devlog-derived systemic pillars; the systemic truths (ascent, attach-grow, loss-permanent, color-cost) became *enables* and *forbids* under the three emotional pillars rather than pillars of their own.
- **Alternatives rejected:**
  - `P5 Ends-With-A-Beat` — code has no ending state; made it an open question (OQ2) instead, since a pillar must describe player experience, not aspiration.
  - `P3a Every mechanic must produce a felt emotion` — too gate-keeping, reads as a process rule not a player-experience statement.
  - `P3b Player feels bonds deepen...` — prescribes the specific emotions; too narrow, excludes future emotion types.
- **Tensions resolved at lock time:**
  - T1 (intro text vs P2): written intro sits outside `state=="play"`, is narrative framing, not instruction. Closed.
  - T3 (Big retreat downward vs P1): P1 binds player POV only. Closed.
- **Tensions carried forward:** T2 (flower "hold x" prompt vs P2) — open.