# Design Log

## 2026-07-24
**Decision:** Locked initial pillar set: P1 Always Move Forward / P2 Show Don't Tell / P3 Emotion Is the Only Currency.
**Rationale:** Pillars must be player-experience constraints (specific, observable, contradictable, with explicit forbids). User's contextual-emotional phrasings captured design intent better than my devlog-derived systemic candidates (ascent/grow/loss/color-cost). Systemic truths became enables/forbids under the three emotional pillars. P3 ("Emotion is the only currency") passed `gdd.py pillar` once reworded to bind player experience and carry an explicit forbid (no score/fail/metric).
**Alternatives rejected:** P5 Ends-With-A-Beat (aspirational, moved to OQ2). P3a/P3b reframes (process rule / too narrow).
**Tensions resolved:** T1 (intro text — outside play state, narrative not instruction). T3 (Big retreat downward — P1 binds player POV only).
**Tensions carried:** T2 (flower "hold x" prompt vs P2) — open. Log after fix.
**Override:** none.

## 2026-07-24 (2)
**Decision:** OQ2 resolved — narrative game has an ending beat; ending is required but design TBD. Raised OQ4 (ending beat design).
**Rationale:** User clarified: metrics ban under P3 targets scoring/fail/win-condition systems, not a story conclusion. Cart already has intro text (narrative framing) → ending beat is consistent sibling. P3 still forbids ending triggered by score/height/attachment count metric; ending must trigger on narrative beat. OQ1 (loss-recovery) blocks on ending design since arc resolution depends on it.
**Alternatives rejected:** "no ending, endless toy" — contradicts narrative intent stated by user. "ending on att=N threshold" — converts att to a metric, violates P3.
**Tensions:** none new. P1↔P3 tension (OQ1) now subsumes ending design.
**Override:** none.

## 2026-07-24 (3)
**Decision:** Locked core loop as 4 nodes: Move → Grow → Lose → Move.
**Rationale:** Core loop = 5-15s heartbeat, not exhaustive state graph. First draft (13-node encounter branch per type) too long, user collapsed encounter variants into Grow/Lose inputs. Tighter loop = clearer pillar fit, easier tuning.
**Alternatives rejected:** 13-node encounter graph (correct but too detailed for core loop; encounter variants belong in Feature & System Design phase, not the loop).
**Tensions:** T2 (flower prompt) carries. P1↔P3 (OQ1) carries.
**Override:** none.

## 2026-07-24 (4)
**Decision:** Big NPC idle behavior — drift toward nearest side wall when onscreen but unengaged (no cast). Resolves Big Thief Flag 2.
**Rationale:** Without idle drift, player can skirt `steal_range` and Big lingers onscreen indefinitely → clutter, not dread. Horizontal wall-drift forces exit, preserves P1 (forward = escape, no skirting), keeps P3 (involuntary loss threat without fatigue). Current retreat already horizontal-biased (`fy*=0.2`); idle drift extends same logic to pre-cast state.
**Implementation:** TBD. Proposed tunable `big_idle_drift` (px/frame toward nearest wall: `x<64 → -drift, else +drift`). Not a code change this session — design decision recorded only.
**Alternatives rejected:** "Big despawns on idle timer" — arbitrary, no diegetic justification. "Big chases player if skirted" — violates P1 (player can't escape forward). "Do nothing, accept lingering" — fatigue risk under P3.
**Tensions:** none new. Flag 3 (offscreen cast / spawn timing) deferred per user: "wait and see."
**Override:** none.

## 2026-07-24 (5)
**Decision:** Flower Color-Change flags resolved + new mechanic raised.
- **Flag 2 (Big vs flower dual-loss):** Level design constraint — no flower within `steal_range=56` of any Big spawn. Enforced via `level_editor.html` placement discipline. No code change. If violated, revisit.
- **Flag 4 (mis-input no-op color change):** Prevent mis-input. Add guard: when `f.col == pcol` at charge completion, skip `f.used=true` + burst ring, reset `f.charge=0` instead. Flower not consumed on no-op. Code change TBD.
- **Flag 3 (dead tunables):** Defer.
- **Flag 1 (P2 prompt):** Defer (T2/OQ3).
**Rationale:** Mis-input cost violates intent — color change is an emotional decision, not a finger-slip tax. Big-near-flower constraint preserves emotional beat of color change from being stomped by theft. Both keep P3 (emotion currency) clean.
**Tensions:** none new.
**Override:** none.

## 2026-07-24 (6)
**Decision:** New mechanic raised — Narrative Event camera lock.
**Definition:** Some flowers / NPCs flagged as Narrative Events. On player entering event radius, camera ratchets lock until event interaction complete.
- Flower event: complete = color change performed.
- NPC event: complete = NPC attached OR fled.
**Rationale:** P1 (Always Move Forward) + OQ2 (narrative ending) imply story beats. Locking camera forces the beat to land — player can't ratchet past a story moment without resolving it. Serves P3 (emotion currency — events deliver emotional payload) and OQ4 (ending beat may be one such event).
**Implementation:** Not in code. Requires: event flag on flowers/NPCs, camera lock state, completion predicate per event type, unlock trigger. Design TBD — user raised as addition direction.
**Alternatives rejected:** "Auto-pause the game" — breaks flow, contradicts P1 forward motion feel. "Soft-gate via visual" — player could skip, undermines narrative beat. Camera lock keeps world live while pinning progress.
**Tensions:** P1 (forward-only) vs camera lock (camera frozen). Resolve: lock is temporary, releases on event completion — forward motion resumes, never reverses. Lock is a pause on forward, not a reversal.
**Override:** none.
**Raised:** OQ6 — Narrative Event implementation details (event flag schema, lock radius, completion predicate, multi-event ordering, placement tool in level_editor.html).

## 2026-07-24 (7)
**Decision:** Remove hardcoded `grass` table from tab 1. Grass derives from plant table at init.
**Rationale:** Level layout moved to tab 1 — hardcoded grass copy predates that move and is now redundant. Editor export is sole source of truth. Removes drift risk (system 07 Flag 1). Derivation rule `grass[i]={x=p.x+12, y=p.y}` per plant already used in editor (devlog 2026-07-23 — grass one per plant, not per NPC).
**Implementation:** TBD — replace hardcoded `grass` table with init loop over `npcs` plant groupings (or a `plants` table if editor emits one). Code change small.
**Alternatives rejected:** "Keep both copies" — drift risk, contradicts single-source-of-truth principle. "Editor writes derived grass explicitly" — derivative data, editor should emit source only.
**Tensions:** none.
**Override:** none.