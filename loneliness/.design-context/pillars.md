# Design Pillars

## Current Pillars

### P1 — Always Move Forward
- **Principle:** The player only moves forward; there is no going back.
- **How it guides decisions:** Ascent is literal and ratchet-locked — lost ground stays lost, lost bonds stay lost. Every system that involves position or progress must enforce one-way motion. Forward motion is the only escape from threats.
- **What it pushes against:** Backtracking, lateral exploration, downward camera, grounded level layouts, do-overs for lost bonds.
- **Tensions:** P3 (loss is permanent → forward-only amplifies loss cost).

### P2 — Show, Don't Tell
- **Principle:** Never tell the player what to do; use UX, visual affordance, and gameplay behavior to guide the player through.
- **How it guides decisions:** Every encounter signals visually — call ring, attach chime + ring, Big cast ring, flower particles, NPC despawn on flee. No tutorial text, no prompts, no hint arrows in gameplay.
- **What it pushes against:** Tutorial text in gameplay, button prompts, hint arrows, spoken instruction, system messages.
- **Tensions:** None active with P1/P3. **Open: flower "hold x" prompt (T2) — unresolved conflict.**

### P3 — Emotion Is the Only Currency
- **Principle:** Emotion is the only currency — no score, no fail state, no progression metric competes with how the player feels.
- **How it guides decisions:** Growth = light + music grow. Loss = light + music shrink. Identity shift = color change severs bonds. Every system feeds felt emotion. Any feature that adds a displayable metric, score, or fail state conflicts with this pillar.
- **What it pushes against:** Score counter, leaderboard, fail/game-over screen, win-condition metric, XP/level, achievements, session statistics, completion percentage.
- **Tensions:** P1 (permanent loss must not softlock emotional arc — see OQ1); P3 implies an ending beat is required since "play forever" is itself a progression framing (see OQ2 resolved, OQ4 raised).

## Pillar Evolution

### 2026-07-24 — Initial pillar set locked
- **Set:** P1 Always Move Forward / P2 Show Don't Tell / P3 Emotion Is the Only Currency.
- **Process:** Started with 5 candidate pillars drafted from devlog scan (P1 Ascent-Only, P2 Growth-Via-Match, P3 Loss-Is-Real, P4 Color-Change Costs Bonds, P5 Ends-With-A-Beat). User rejected P5 as aspirational-systemic, not a true pillar; user supplied 3 contextual-emotional pillars instead. Reframed all three into the pillar anatomy (principle / guides decisions / pushes against). P3 failed `gdd.py pillar` validation ("doesn't describe player experience; no push-against clause"); user picked reframe 3c ("Emotion is the only currency — no score, no fail, no progression metric competes with how the player feels"), validated strong.
- **Rationale:** Pillars are the central validation axis. They must be specific, observable, contradictable, and push against something. The user's contextual phrasings captured intent better than my devlog-derived systemic pillars; the systemic truths (ascent, attach-grow, loss-permanent, color-cost) became guides-decisions and pushes-against under the three emotional pillars rather than pillars of their own.
- **Alternatives rejected:**
  - `P5 Ends-With-A-Beat` — code has no ending state; made it an open question (OQ2) instead, since a pillar must describe player experience, not aspiration.
  - `P3a Every mechanic must produce a felt emotion` — too gate-keeping, reads as a process rule not a player-experience statement.
  - `P3b Player feels bonds deepen...` — prescribes the specific emotions; too narrow, excludes future emotion types.
- **Tensions resolved at lock time:**
  - T1 (intro text vs P2): written intro sits outside play state, is narrative framing, not instruction. Closed.
  - T3 (Big retreat downward vs P1): P1 binds player POV only. Closed.
- **Tensions carried forward:** T2 (flower "hold x" prompt vs P2) — open conflict.

### 2026-07-24 (2) — Pillar anatomy updated to v2.2.0 spec
- **Change:** Migrated pillar anatomy from old format (Statement / What this enables / What this forbids / How we verify) to v2.2.0 format (Principle / How it guides decisions / What it pushes against). Dropped "How we verify" — the new anatomy treats pillars as lenses, not testable hypotheses. Dropped "What this enables" — folded into "How it guides decisions". Terminology: "forbids" → "pushes against", "violation" → "conflict" throughout.
- **Rationale:** Skill v2.2.0 update changed the pillar anatomy. Old anatomy was too rigid (verify clause made pillars into testable hypotheses); new anatomy treats pillars as lenses with clear direction. Pushes-against is the most important part — a pillar that never conflicts filters nothing.
- **Alternatives rejected:** Keep old anatomy — would diverge from skill spec. Drop "Tensions" field — would lose cross-pillar conflict tracking; kept as supplementary field.
- **Override:** none.