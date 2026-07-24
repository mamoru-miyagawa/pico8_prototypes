# System Design: Pollen Ambient

**Classification:** Secondary System — ambient
**Scope Cost:** Low — per-particle drift + three radial pushes + world-space wrap + burst-despawn/respawn

### Purpose

60 ambient pollen particles drift through the world, repelled by the player, pushed by Big's cast ring, and scattered explosively by flower color-burst. Pollen is the visual air of the game — it gives motion to the void, makes the player's presence felt (repulsion), and dramatizes the two loudest beats (Big cast warning, flower color change). Without pollen the screen is dead space; with it, every player motion has a wake.

### Core Loop Connection

No direct touch. Pollen is **outside** the Move/Grow/Lose loop — it is atmosphere, not state. Player does not gain or lose pollen; pollen does not gate anything. Per AGENTS.md rule "touches systems = none is not an answer": pollen touches Big (cast push), Flower (burst push), and Player (repulsion), but as a *receiver* of forces, not a *sender*. Reason for existing despite no loop touch: P3 (emotion) requires the world to react to the player — pollen is the cheapest reactive substrate.

### Pillars Served

- **P1 Always Move Forward:** Pollen is world-space, wraps in band ±160 around `cam_y` — as player ascends, pollen scrolls downward, sells the upward motion visually. No pollen state regresses; no per-pollen permanence (burst pollen dies and respawns).
- **P2 Show, Don't Tell:** Pollen is pure visual. No pollen counter, no "pollen scattered" text. The player *sees* their wake, Big's cast reach, flower's burst radius — pollen makes forces visible without UI.
- **P3 Emotion Is the Only Currency:** Pollen has no score value, no collection, no interaction verb. It exists to make the emotional beats *felt* — calm drift (neutral), push-away (player presence), scatter (burst drama).

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `p.x, p.y, p.vx, p.vy, p.p` (per particle) | entity | number | Yes |
| `px, py` | player | number | Yes — repulsion center |
| `pollen_rep_r, pollen_rep_s` | tunables | number | Yes — repulsion radius/strength |
| `big.cast, big.cast_t, big.x, big.y, big.done` | Big state | mixed | Yes — cast push |
| `rings` with `r.burst=true` | feedback rings | table | Yes — burst push |
| `cam_y` | camera | number | Yes — wrap band, draw transform, respawn y |

### Process

```
-- init: 60 particles, random pos/vel/radius
for i=1,pollen_n:
  pollen[i] = {x=rnd(128), y=rnd(128), vx=(rnd()-0.5)*0.15, vy=(rnd()-0.5)*0.15, p=rnd(1)+0.5}

-- per frame, _update (after movement, before rings):
for p in all(pollen):
  -- 1. player repulsion (linear falloff)
  dx, dy = p.x-px, p.y-py
  d = sqrt(dx*dx + dy*dy)
  if d < pollen_rep_r and d > 0.001:
    f = (pollen_rep_r - d) / pollen_rep_r * pollen_rep_s
    p.x += dx/d * f;  p.y += dy/d * f

  -- 2. Big cast ring push (during cast_t countdown)
  if big.cast and not big.done:
    bdx, bdy = p.x-big.x, p.y-big.y
    br = 36 - big.cast_t                       -- ring current radius
    if br > -16:
      bd = sqrt(bdx*bdx + bdy*bdy)
      reach = br + 16
      if bd < reach and bd > 0.001:
        f = (reach - bd) / reach * 6           -- strength 6 (hardcoded)
        p.x += bdx/bd * f;  p.y += bdy/bd * f

  -- 3. flower burst ring push (aggressive)
  for r in all(rings):
    if r.burst:
      rdx, rdy = p.x-px, p.y-py
      rd = sqrt(rdx*rdx + rdy*rdy)
      if rd < r.r + 8 and rd > 0.001:
        f = (r.r + 8 - rd) / (r.r + 8) * flower_burst_s   -- 8
        p.x += rdx/rd * f;  p.y += rdy/rd * f
        p.burst = true

  -- 4. drift + wrap/despawn
  p.x += p.vx;  p.y += p.vy
  if p.burst:
    if p.x<-8 or p.x>136 or p.y-cam_y<-8 or p.y-cam_y>136:
      del(pollen, p);  pollen_deficit += 1
  else:
    if p.x<0 then p.x+=128 end
    if p.x>128 then p.x-=128 end
    if p.y-cam_y<-16 then p.y+=160 end
    if p.y-cam_y>144 then p.y-=160 end

-- 5. slow respawn (one per pollen_respawn_cd frames)
if pollen_deficit > 0:
  pollen_cd += 1
  if pollen_cd >= pollen_respawn_cd:
    pollen_cd = 0
    add(pollen, {x=rnd(128), y=cam_y+rnd(128), vx=..., vy=..., p=...})
    pollen_deficit -= 1

-- draw (last, on top):
for p in all(pollen): circfill(p.x, p.y-cam_y, p.p, 15)
```

**State Machine (per particle):**

```
States: Drift ↔ Pushed → Burst (flag) → Despawned (burst-only) → Replaced
Transitions:
  Drift → Pushed: any of 3 radial forces active
  Pushed → Drift: forces cease
  Drift/Pushed → Burst: caught in burst ring (r.burst=true)
  Burst → Despawned: off-screen edge
  Despawned → (deleted from pollen), pollen_deficit++ — new Drift particle spawns elsewhere after pollen_respawn_cd
```

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| `p.x, p.y` (updated) | draw pass (screen via `y-cam_y`) | number | world |
| `p.burst=true` | self despawn branch | boolean | — |
| `pollen_deficit` | respawn block | number | 0..N |
| screen pixels (`circfill` col 15) | player eye | pixels | — |

No system reads pollen state. Pollen is a terminal sink — receives forces, produces pixels, never feeds back.

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| Player Movement + Camera | Reads `px,py` + `cam_y` | Player repulse center; pollen draw uses `y-cam_y`; wrap band tied to `cam_y`. |
| Big NPC Thief | Reads `big.cast, big.cast_t, big.x, big.y, big.done` | Cast ring pushes pollen outward during 36f cast. Pollen makes Big's reach visible. |
| Flower Color-Change | Reads `rings[].burst, r.r` | Burst ring pushes pollen aggressively (`flower_burst_s=8`), flags `p.burst=true`, despawn triggers `pollen_deficit++`. |
| Feedback Rings | Reads `r.burst` flag | Pollen is the *recipient* of feedback rings' burst flag — visual inflation of the ring. |
| Call Wave Attach | None | Call ring (no burst) does not push pollen. |
| Dynamic Soundtrack | None | |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `pollen_n` | 20 | 120 | `60` | Particle count. Lower = cheaper; higher = denser air, more CPU on per-particle loop. PICO-8 perf: 60 is safe, 120 risks frame drops on top of glow + rings. |
| `pollen_rep_r` | 16 | 64 | `30` | Player repulsion radius. Larger = bigger wake, more "ghostly halo". |
| `pollen_rep_s` | 0.5 | 3 | `1` | Repulsion strength. Push drama. |
| `pollen_respawn_cd` | 4 | 20 | `8` | Frames between each respawn. Slow refill after burst. |
| Big cast push strength `6` (hardcoded line 174) | 3 | 12 | `6` | Big cast pollen scatter drama. **Flag: expose as tunable.** |
| Burst ring reach `r.r+8` (hardcoded line 185) | 4 | 16 | `8` | Burst ring pollen-fetch radius. Inline constant. |
| Drift vel range `±0.075` (via `(rnd()-0.5)*0.15`) | — | — | fixed | Drift speed. Not tunable — tuning means editing the init/respawn expression. **Flag: expose `pollen_drift_v` tunable.** |
| Particle radius `p=rnd(1)+0.5` | — | — | `[0.5,1.5]` | Visual size variation. Not tunable — inline in init/respawn. |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| Pollen wraps while `p.burst=true`? | No — burst pollen does not wrap, only despawns off-screen. If burst particle stays onscreen forever, never despawns. Possible stuck-burst-pollen case if `r.r+8` reaches near screen edge — particle lingers at wrap edge. Low risk. |
| Pollen caught in multiple burst rings simultaneously | Each `r.burst` ring pushes independently per frame — cumulative force. Dragonary but correct. |
| Big cast ring at world y far from pollen band | `big.y` in world; pollen world-wrap band is `cam_y ± 160`. If Big is outside band, pollen unaffected (distance too large). Safe. |
| `pollen_deficit` exceeding `pollen_n` (many bursts)? | No cap — `pollen_deficit` can grow beyond `pollen_n`. Respawn decrements 1 per `pollen_respawn_cd` frames. Recovery time scales with deficit. Acceptable — long burst-driven depletion has long recovery. |
| Player ratchets past burst particle still onscreen | Burst despawns off-screen edges only. If player ratchets above a burst particle, it remains until it drifts off. Still flagged `p.burst=true` indefinitely — behaves like a "dying" particle that never died. **Minor edge — flag, low priority.** |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| Fixed-point overflow in repulse distance | Player repulse: max distance check `d < pollen_rep_r=30`. `dx*dx` overflows at dx>181. Pollen wraps ±160 around `cam_y`, so `dx` in world could exceed 181 if pollen far behind in world. Distance check uses `p.x-px` world coords → potential overflow. **Flag: add `abs(dx)<pollen_rep_r and abs(dy)<pollen_rep_r` guard like Big/flower.** Low practical risk since repulse `r=30` gates the inner branch — but `sqrt` happens *before* the `d < pollen_rep_r` check... no, guard is `d<pollen_rep_r`, so sqrt runs first. Overflow path is real. |
| Big cast push overflow | `bdx = p.x - big.x` in world. Same risk — Big spawns at y=-260, pollen wraps near cam_y=0 → `bdy` up to 260 → `bdy*bdy` overflows 32767. But guarded by `if br > -16` then `bd < reach` (reach ≈ 52). sqrt runs first again. **Same flag.** |
| Burst push overflow | `rdx = p.x-px`, `rdy = p.y-py` in world. Burst ring at player pos; player near `px` pollen range. Lower risk — player is close to pollen in world typically. But pollen wraps ±160 around `cam_y`, PICO-8 fixed-point cap is 181. If pollen is 200 world-px from player on one axis, overflow. **Same flag.** |
| Particle deleted while iterated by `for...all` | PICO-8 `for...all` handles deletion mid-iteration safely (documented). Safe. |
| Respawn spawns particle offscreen | `y = cam_y + rnd(128)` — always on current screen. Safe. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Pollen Ambient | Player Movement + Camera | ✅ | Repulse + wrap + parallax. Documented. |
| Pollen Ambient | Big NPC Thief | ✅ | Cast ring pushes pollen. Documented. **Flag: overflow risk same as system 02/03 unguarded paths.** |
| Pollen Ambient | Call Wave Attach | ✅ | None — call ring does not push pollen. Documented. |
| Pollen Ambient | Flower Color-Change | ✅ | Burst ring pushes pollen + despawn + respawn. Documented. |
| Pollen Ambient | Dynamic Soundtrack | ✅ | None. |
| Pollen Ambient | Grass / Flower Visual | ⚠ TBD | Both drawn before pollen; pollen on top per draw order. No interaction. |
| Pollen Ambient | Splash + Intro + Fade-In | ⚠ TBD | Pollen init at session start spawns at `rnd(128)` (screen space y 0..128). During fade-in may be visible through dither overlay. Acceptable aesthetic. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P2 (makes forces visible without UI), P3 (world reacts to player — emotion currency is felt, not counted). |
| Connects to core loop? | No direct connection. Exists because P3 demands the world react to player + emotional beats. AGENTS.md rule: not a loop orphan because it serves pillars even without loop touch. Documented rationale. |
| Touches systems? | Player (repulse), Big (cast push), Flower (burst push). As receiver only. |
| Scope cost? | Low. Init + 1 update loop + 1 draw loop. ~30 lines. |
| Contradicts anything? | **Flag 1:** Three possible fixed-point overflow paths (player repulse, Big cast push, burst push) — all use world-space deltas >181px possible, same bug pattern as Big/flower already fixed. Pre-check guard needs adding in 3 places. **Flag 2:** Hardcoded constants (Big push strength `6`, drift velocity, particle radius) not exposed as tunables — ponytail: fine until tuning phase. **Flag 3:** Burst particle can stay onscreen with `p.burst=true` if player ratchets past it — low priority. |

**Verdict:** PASS with 3 flags.
- **Flag 1 (overflow risk)** — real bug, same class as already-fixed Big/flower. Three distance checks need `abs(dx)<range and abs(dy)<range` pre-check. Code change TBD.
- **Flag 2 (tunable exposure)** — defer to Balance & Tuning phase.
- **Flag 3 (stuck burst particle)** — cosmetic, low priority, defer.