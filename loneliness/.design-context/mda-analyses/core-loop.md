# MDA Analysis — Core Loop (Move → Grow → Lose)

Run 2026-07-24. Applies Mechanics-Dynamics-Aesthetics to the whole core loop, then compares the predicted aesthetic profile against the three pillars.

---

## Mechanics (designer-controlled rules)

The rules of the game, as written in the cart:

1. **Movement ratchets upward only.** `cam_y` decreases when player enters top zone; bottom clamp blocks downward motion. Side walls invisible but enforced.
2. **Call wave attaches color-matching NPCs.** Press O → expanding ring; matching NPCs in radius become attached (orbit player + grow light + music); non-matching flee + despawn.
3. **Attached NPCs orbit the player.** Smooth lerp toward a rotating slot, phase-split by index. Light radius glows with attach count; music layers add at attach count 1, 2, 3.
4. **Attached NPCs detach beyond range.** Past `att_lose_range=90`, bond drops, NPC drifts free. Player must keep moving forward; bonds left behind.
5. **Big NPC steals attached bonds.** Cast ring warning (36f), then steals one attached NPC per cadence until none left, then retreats horizontally-biased. Big cannot be destroyed, only escaped by ascending.
6. **Flower changes player color.** Hold near unused flower 3s → color shifts; mismatched attached NPCs detach + flee. Flower is single-use.
7. **Pollen ambient.** 60 particles drift, repelled by player, pushed by Big cast, scattered by flower burst. No state, no score.
8. **Splash + intro + dithered fade-in.** Pre-play sequence; no input skip.
9. **No score, no fail state, no displayed metric.** Session ends at narrative beat (TBD).

---

## Dynamics (what emerges when played)

What the player actually does, loop after loop:

- **Chase matching colors upward.** Player scans ahead for NPCs colored like themselves, moves toward them, calls.
- **Hoarding at first.** New player bonds every NPC they can, glow swells, music fills. Sense of accumulation.
- **Loss reorients movement.** When Big appears, the player either sacrifices a bond or ascends away. Forward motion becomes escape, not just exploration.
- **Color-change hesitation.** As player accumulates bonds of one color, switching costs those bonds. The flower decision becomes a real trade — give up certain present for uncertain future.
- **Forward drift after loss.** After Big strips bonds, the player keeps moving — there is no other direction. The world keeps scrolling. The loss is not undone, just left behind.
- **Musical feedback as guidance.** The player notices music dropping before they consciously register that Big stole. Sound leads attention.
- **Pollen as presence-marker.** The player's wake in the pollen becomes how they read their own motion. Big's cast reach is felt in pollen scatter before it's consciously traced.
- **No rote optimization.** Without score or fail, the player doesn't grind an optimal path. They wander, attach, lose, pick a color, continue.

---

## Aesthetics (what the player feels)

Mapped to LeBlanc's 8 aesthetics:

| Aesthetic | Intensity | Source |
|---|---|---|
| **Sensation** | 4/5 | Glow flicker, dither dissolve, chimes, pollen drift — continuous visual/audio pleasure |
| **Fantasy** | 3/5 | Player is a firefly ("ほたる"); spirits are color-coded; ascent is metaphor. Light framing, not heavy narrative. |
| **Narrative** | 2/5 | Intro title + ending beat (TBD). Currently thin — narrative lives in framing, not in branching. |
| **Challenge** | 2/5 | Big's steal cadence is a soft threat, not a wall. No skill gate, no fail. |
| **Fellowship** | 1/5 | None — single-player, no social system. Bonds are with NPCs, not other players. |
| **Discovery** | 4/5 | Mapping color verbs, finding what flowers do, learning Big's behavior without text. Mechanical discovery through experimentation. |
| **Expression** | 3/5 | Color choice is the expressive verb. Build = current color + current bonds. Limited but genuine. |
| **Submission** | 1/5 | No grind, no collection, no checklist. Loop is too short and too varied to produce submission. |

**Primary aesthetics:** Sensation, Discovery, Expression.
**Secondary:** Fantasy (frame), Challenge (soft threat).
**Suppressed by design:** Fellowship, Submission, heavy Narrative.

---

## Pillar check

Does the MDA profile match the pillars?

### P1 — Always Move Forward

- Mechanics: ratchet camera, no backtrack, finite flowers, no map. ✅ enforces.
- Dynamics: forward drift after loss, no rote optimization, ascent as escape. ✅ emerges.
- Aesthetics: Discovery (forward = unknown) + Sensation (parallax) — both forward-facing. ✅

**Match: strong.** No drift toward Submission (which would require grind/repetition). No backtracking dynamic. Pillar says forward; player feels forward.

### P2 — Show, Don't Tell

- Mechanics: visual call ring, chime on attach, Big cast ring, flower particles, pollen repulsion. ✅
- Dynamics: player learns color verbs by experiment, reads Big reach via pollen, senses loss via music before conscious registration. ✅ emerges — the world teaches.
- Aesthetics: Discovery (mechanical) as primary — player feels-out the game, not reads it. ✅
- **Known conflict:** flower "hold x" prompt (T2/OQ3) — direct tell. Deferred. Resolving it doesn't change the dominant aesthetic profile, just removes one contradiction.

**Match: strong with one deferred flag.** Dominant aesthetic is Discovery through show-don't-tell mechanics. Prompt is a local conflict, not a profile mismatch.

### P3 — Emotion Is the Only Currency

- Mechanics: no score, no fail, att feeds glow + music only. ✅
- Dynamics: no rote optimization, no grind, no leaderboard chase. Player wanders, attaches, loses. ✅ no metric-grind dynamic emerges.
- Aesthetics: Sensation + Discovery + Expression — none are Submission. Player experiences feeling, not count. ✅

**Match: strong.** P3 says emotion is the only currency; MDA profile shows Submission suppressed, Expression elevated. The mechanic (att→aesthetics only) produces the intended aesthetic (felt emotion, not score).

**Tension flagged in tensions.md:** P1↔P3 — permanent loss + irreversible ascent risks "empty late-game" emotional state. MDA reading: that's a *Narrative* aesthetic gap. Loss dynamics produce grief/discovery but not resolution. Ending beat (OQ4) is the proposed mitigation. MDA confirms it's needed, not optional.

---

## Mismatches and gaps

### Gap 1 — Narrative aesthetic under-served

- **Designer intent (from OQ2 resolved):** narrative game, ending required.
- **MDA profile:** Narrative at 2/5. Intro title + ending TBD. Currently the narrative aesthetic is *framing*, not *substance*.
- **Risk:** player feels the Discovery/Sensation strongly but the Narrative too weakly to register as a story game. The "meditation on irreversible attachment" stays abstract.
- **Layer:** Dynamics → Aesthetics. Mechanics (intro text, ending TBD) don't produce enough narrative dynamics. The fix is mechanical — add the ending beat (OQ4 already open).

### Gap 2 — Expression ceiling

- **Designer intent:** color change is identity shift.
- **MDA profile:** Expression at 3/5. Only 4 colors. Once all flowers used, color choice is fixed. No further expression.
- **Risk:** late-game player feels no expressive agency — they've settled into a color and there's nothing more to say. Matches the post-loss "empty" state flagged in tensions.
- **Layer:** Dynamics → Aesthetics. Mechanics allow expression early but cap it. Two design paths: (a) accept as intentional — fits P3 (emotion arc has a peak then resolution / ending); (b) add periodic flowers up to the ending beat. Already an implicit OQ4 dependency.

### Gap 3 — Musical ceiling vs unbounded glow (already in tensions)

- **Designer intent:** growth = layer adds.
- **MDA profile:** mechanic caps layers at 3, glow growth unbounded. Past 3 bonds, player gets visual but not musical growth feedback.
- **Risk:** player senses "more of the same" — Discovery fades at high att. Submission dynamic could creep in if accumulation is silent.
- **Layer:** Mechanics → Dynamics. Fix at mechanic layer (retune layer thresholds, add a 4th layer) or accept as design (glow continues where music can't).

### Gap 4 — Fellowship = 1/5 is intentional, not a gap

- Single-player game. No multiplayer intent. Listed for completeness — flagging that this aesthetic is deliberately suppressed, not a mismatch.

---

## Verdict

**Core loop MDA profile matches pillars.** No pillar-pillar denial surfaced at the aesthetic level. Three mechanics-level gaps already tracked as Open Questions:

- Gap 1 ↔ OQ4 (ending beat)
- Gap 2 ↔ OQ4 (ending settles color arc)
- Gap 3 ↔ tensions.md active (musical ceiling vs glow)

**Recommendation:** prioritize OQ4 (ending beat). MDA confirms narrative aesthetic is the weakest leg and the ending is the load-bearing fix. Submit for user decision.

User decides whether to design the ending beat next, retune the musical ceiling, or accept current gaps as jam-scope acceptable.