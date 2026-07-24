# System Design: Grass & Flower Visual Flourish

**Classification:** Content Feature — ambient visual
**Scope Cost:** Low — 4 hardcoded grass tufts, 1 default flower, two-pass draw (under-glow shadow + over-glow sprite), world-space with screen cull, no update logic

### Purpose

Grass tufts (sprite 7) and flowers (sprite 9/10) are the only static world dressing. They give the void a "ground" — something the player is leaving behind as they ascend. Grass anchors each NPC spawn cluster visually, communicates that the world has *places*, and (with pollen parallax) drives the felt sense of upward motion. Flowers are flower-system visual dressing (already in system 04) — covered here only as a visual peer to grass.

### Core Loop Connection

No direct touch. Like pollen, grass is atmosphere — no state, no loop edge. AGENTS.md "none is not an answer": grass touches Movement + Camera (world-space parallax) and is derived from NPC spawn table in the level editor. Reason it exists: P1 (forward) requires *felt* motion; grass + pollen are the two parallax layers that make ascent visible.

### Pillars Served

- **P1 Always Move Forward:** Grass is world-space, scrolls downward as `cam_y` decreases. Each tuft passes once and is gone. No grass is unique / revisit-able — reinforces irreversibility.
- **P2 Show, Don't Tell:** Grass is pure drawing. No "you are leaving a meadow" text. The visual of grass sliding off the bottom of the screen IS the communication of ascent.
- **P3 Emotion Is the Only Currency:** Grass has no value, no interaction, no count. It is decoration that makes the emotional beats land (NPC orphaned in a meadow → NPC leaving meadow as player ascends → meadow gone).

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `grass` table (4 tufts, hardcoded tab 1) | entity init | number pairs | Yes |
| `g.x, g.y` (per tuft) | entity | number | Yes |
| `cam_y` | camera | number | Yes — draw transform + cull |
| `npc_fillp` | tunable (dither pattern) | fillp | Yes — shadow dither |
| Flower-related covered in system 04 | — | — | — |

### Process

```
-- init: 4 grass tufts, hardcoded coords matching NPC plant positions
grass = {}
grass[1] = {x=24+12, y=44}
grass[2] = {x=101+12, y=16}
grass[3] = {x=98+12, y=-72}
grass[4] = {x=21+12, y=-90}

-- _draw pass 1: grass shadows (before player glow)
for g in all(grass):
  local sy = g.y - cam_y
  if sy > -8 and sy < 136:                           -- screen cull
    fillp(npc_fillp);  circfill(g.x+4, sy+6, 5, 2)   -- col 2 shadow, dithered
    fillp(0)                                         -- reset

-- _draw pass 2: grass sprites (after glow, after feedback rings)
for g in all(grass):
  local sy = g.y - cam_y
  if sy > -8 and sy < 136:
    spr(7, g.x, sy)
```

**State Machine:** none. Pure draw, no state.

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| Dither dithered col-2 circle (shadow) | screen pixels | pixels | under glow |
| Sprite 7 (grass blades) | screen pixels | pixels | over glow/rings |

No system reads grass. Terminal draw sink.

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| Player Movement + Camera | Reads `cam_y` | World-to-screen Y, screen cull. Parallax. |
| Level Editor HTML | Writes `grass` table | Grass derived per-plant in editor export (`grass[i] = {x=p.x+12, y=p.y}`); tab 1 has hardcoded copy. Editor is source of truth when used. |
| Pollen Ambient | Drawn before pollen | Pollen on top per draw order. |
| Flower Color-Change | Drawn together | Flower shares two-pass structure (shadow under, sprite+particles over). Pattern reused. |
| Call Wave Attach / Big / Soundtrack | None | |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `grass` table contents | — | — | 4 hardcoded | Positioning. Author via `level_editor.html`, not via tunable. **Flag: hardcoded coords in tab 1 duplicate editor output — drift risk.** |
| Shadow radius `5` (hardcoded line 412) | 3 | 10 | `5` | Shadow size. Inline constant. Ponytail: ok until tuning. |
| Shadow col `2` (hardcoded) | — | — | `2` (dark green) | Shadow color. Inline constant. Fixed aesthetic. |
| Shadow y offset `sy+6` (hardcoded) | 0 | 12 | `6` | Shadow base offset from sprite. |
| Screen cull bounds `-8..136` (hardcoded) | — | — | fixed | Visibility window. Reasonable for 128px screen + 8px margin. |
| `npc_fillp` (shared, tunable) | — | — | `▒` | Dither pattern shared with NPC glow. Tuning affects both — coupling. |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| Grass tuft off-screen above (`sy < -8`) | Skip draw. Re-enter when camera ascends — but camera ratchets up only, so once off top, grass gone forever. P1-aligned. |
| Grass tuft below cull (`sy > 136`) | Skip draw. Will enter screen when camera ratchets up to it. |
| `grass` table empty (editor export with no plants) | Loops are no-ops. Safe — player sees no grass. Aesthetic loss only. |
| `fillp(0)` forgotten after shadow draw | All later draws become dithered. **Verified present in code** (line 413): `fillp(0)` after each shadow. Safe. |
| Multiple grass tufts at same x | Visually stack. No collision, no depth sort. Acceptable in current level (no overlap). |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| Hardcoded `grass[1..4]` drifts from editor output | Tab 1 manual coords vs editor export mismatch. Currently aligned (devlog 2026-07-23 fix: grass per plant, not per NPC). | Run editor → export → paste over tab 1 `grass` block. |
| `spr(7, ...)` but sprite 7 not in spritesheet | Renders blank. Currently sprite 7 is grass blade per spritesheet. | Verify spritesheet stays unchanged. |
| `g.x+4` overflow (g.x near 32767) | World coords far from origin. PICO-8 fixed-point cap 32767. Grass at y=-90 (near start) far from cap. Safe. |
| Screen cull misses rapidly scrolling grass (cam_y ratchets >8px/frame) | Grass sprite may pop in/out without smooth enter. `cam_dead=60` makes ratchet smooth. Safe. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Grass Visual | Player Movement + Camera | ✅ | World-space parallax + cull. Documented. |
| Grass Visual | Pollen Ambient | ✅ | Draw order: grass shadow under glow, grass sprite over glow/rings, pollen over grass. Documented. |
| Grass Visual | NPC orbit/draw | ⚠ TBD | NPC drawn after grass sprite per draw order. No interaction but worth verifying. |
| Grass Visual | Flower Color-Change | ✅ | Shared two-pass pattern (shadow under, sprite over). Same `npc_fillp` dither. |
| Grass Visual | Big NPC Thief | ✅ | None. |
| Grass Visual | Call Wave Attach | ✅ | None. |
| Grass Visual | Dynamic Soundtrack | ✅ | None. |
| Grass Visual | Splash + Intro + Fade-In | ⚠ TBD | Grass drawn during fade-in (after pollen underlay), visible through dither dissolve. Acceptable. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P1 (parallax sells forward motion), P2 (silent decoration), P3 (no value, ambiance only). |
| Connects to core loop? | No direct touch. Exists to make P1 *felt* via parallax. AGENTS.md exception: serves pillars without loop touch. |
| Touches systems? | Movement + Camera (world-space), Level Editor (source of truth), Flower (shared draw pattern). |
| Scope cost? | Lowest in cart. ~15 lines + 4 hardcoded entries. |
| Contradicts anything? | **Flag 1:** Hardcoded `grass` table in tab 1 duplicating editor output — drift risk. Editor is source of truth but tab 1 has copy. Ponytail: fine if you re-export regularly; brittle if multiple edits diverge. **Flag 2:** Shadow inline constants (radius 5, col 2, offset 6) — defer to tuning. |

**Verdict:** PASS with 2 flags.
- **Flag 1 RESOLVED 2026-07-24:** Remove hardcoded `grass[1..4]` from tab 1. Level lives entirely on tab 1 now, so grass should derive from the plant/NPC table at init (same derivation `grass[i]={x=p.x+12, y=p.y}` per plant, indexed by plant not NPC — see devlog 2026-07-23). Editor is sole source of truth; no duplicate copy. Code change TBD. **Note:** Hardcoded copy predates the move of level layout to tab 1; obsolete.
- **Flag 2 (inline shadow constants)** — defer.