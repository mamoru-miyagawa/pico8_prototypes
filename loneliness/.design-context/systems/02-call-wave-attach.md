# System Design: Color-Matched NPC Attach (Call Wave)

**Classification:** Core System
**Scope Cost:** Medium — radial wave + per-NPC hit tracking + color-gated attach/flee + orbit phase split + range-detach

### Purpose

Press O emits a radial call wave from the player. NPCs of matching glow color attach (Grow node); non-matching NPCs flee (Lose node input). This is the primary player action and the only means of gaining bonds. Implements the **Grow** half of the core loop. Color is the gate — the system reads `pcol` to decide attach vs flee, tying identity (P3) to mechanics.

### Core Loop Connection

**Grow node + Lose node input.** Call wave is the input edge into Grow (matching attach) and into Lose (non-matching flee, range-detach). Returns to Move on wave end (`call.r >= call_max_r`).

### Pillars Served

- **P1 Always Move Forward:** NPCs live in world space; attached NPCs follow via orbit slot, but the player still ratchets upward. Detach at `att_lose_range` (90) prevents infinite chase — if player flees forward, bonds drop behind. Forward motion is never punished by orbit lag.
- **P2 Show, Don't Tell:** Call wave is a visible expanding ring (`circ` outlines in `pcol`). Attach = ring + chime + glow growth. Flee = NPC despawn off-screen. No prompts. **Open: T2 unrelated.**
- **P3 Emotion Is the Only Currency:** `att` count feeds glow radius and music layers only — never displayed as score. The wave is the verb; bonds are the noun; loss is the punctuation.

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `btnp(4)` (O button) | player | trigger edge | Yes |
| `call.cd` | system state | number | Yes — gating |
| `call.active` | system state | boolean | Yes |
| `pcol` | player state | number (color idx) | Yes — color gate |
| `n.col` (per NPC) | entity | number | Yes — match test |
| `n.att`, `n.stolen`, `n.fleeing` | entity | boolean | Yes — state guards |
| `px, py, n.x, n.y` | entity | number | Yes — distance |

### Process

```
-- per frame, _update (after movement):
if call.cd > 0 then call.cd -= 1 end
if btnp(4) and not call.active and call.cd <= 0 then
  call.active = true; call.r = 0; call.hit = {}
end

if call.active then
  call.r += call_speed
  for n in all(npcs):
    if not n.stolen and not call.hit[n]:
      local d = dist(player, n)
      if d <= call.r:
        call.hit[n] = true   -- one hit per cast per NPC
        if n.col == pcol:
          if not n.att:
            n.att = true; n.att_fc = fc; big.sc = 0  -- reset Big steal cadence
            add(rings, {r=8, a=12})
            sfx(51)
            recount att; set_music_layers(att)
        elseif not n.fleeing and d > 0.001:
          n.fleeing = true; set n.fdx, n.fdy (straight-up avoided)
          sfx(52)
  if call.r >= call_max_r:
    call.active = false; call.cd = call_cd

-- orbit + range-detach (always running, not gated on call):
local norbit = count(n.col == pcol and not n.stolen)
for n in all(npcs):
  if n.stolen: ... (Big orbit; see system 03)
  elseif n.col != pcol: ... (flee despawn; see Lose inputs)
  else:
    if n.att:
      if dist(player, n) > att_lose_range:
        n.att = false   -- drifts free, re-attachable on next wave
        recount att; set_music_layers(att)
      else:
        slot angle = fc*0.008 + (oi-1)/norbit  -- phase split
        slot pos = px + cos(a)*16, py + sin(a)*16
        lerp n.x,n.y toward slot at att_sp, clamped to att_max
    -- (approach/first-attach handled by call wave only — no proximity auto-attach)
```

**State Machine (per NPC):**

```
States: Free → Attached → Stolen (big) / Fleeing (color-mismatch) / Drift (range-detach)
Transitions:
  Free → Attached: call wave hit + color match
  Free → Fleeing: call wave hit + color mismatch  (then despawn off-screen)
  Attached → Stolen: Big NPC steal (system 03)
  Attached → Drift: dist > att_lose_range
  Drift → Attached: next call wave + color match
  Stolen → (deleted): Big retreat done (system 03 deletes from npcs)
  Fleeing → (deleted): off-screen (x<-16 or x>144 or y>cam_y+144)
```

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| `n.att=true` (per attached) | Glow system, music, Big steal, orbit | boolean | — |
| `att` count | Glow radii `g0/g1/g2 = g*b + att*glow_growth + flicker`, `set_music_layers(att)` | number | 0..N |
| `n.fleeing=true`, `n.fdx, n.fdy` | Flee movement branch + despawn | flag + vec | — |
| `rings` entries (attach chime ring) | Feedback ring draw | table | grows/shrinks |
| `sfx(51)` / `sfx(52)` | audio | trigger | — |
| `call.r`, `call.active`, `call.cd` | call wave draw (two `circ` outlines) | number/bool | — |

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| Player Movement + Camera | Reads `px,py, cam_y` | Orbit slots use world `px,py`; flee despawn bound `cam_y+144`. |
| Big NPC Thief | Writes `big.sc=0` on attach | Resets Big steal cadence so fresh-attached NPC has `steal_grace` window. |
| Big NPC Thief | Is read by | Big steal searches `n.att and not n.stolen and fc-n.att_fc > steal_grace`. |
| Glow + Player Visual | Reads `att` | `g0/g1/g2` reroll every 12f uses `att*glow_growth`. Outer glow uses `pcol2`, inner `pcol`. |
| Dynamic Soundtrack | Calls `set_music_layers(att)` | ch1≥1, ch2≥2, ch3≥3. |
| Pollen Ambient | Reads `call.r` indirectly | No direct link. Pollen unaffected by call wave. |
| Flower Color-Change | Writes `pcol` + detaches mismatches | See system 04. Re-routes matching NPCs to attract branch via dynamic color check. |
| Feedback Rings | Writes `rings{r=8,a=12}` | Draw pass renders rings after glow, before NPCs. |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `call_speed` | 1 | 4 | `2` | Wave expansion px/frame. Higher = wider reach per frame, smaller cast window. |
| `call_max_r` | 30 | 100 | `50` | Wave max radius. Reach to bond. Must be < `att_lose_range` (90) so call can't reach beyond detach range. |
| `call_cd` | 0 | 90 | `30` | Frames between casts. Lower = spam; higher = commitment per cast. |
| `att_sp` | 0.02 | 0.3 | `0.08` | Attached NPC lerp to orbit slot. Lower = trailing, heavy feel. Higher = snapping. |
| `att_max` | 0.5 | 3 | `1.5` | px/frame clamp on orbit lerp. Caps attached speed. |
| `att_lose_range` | 60 | 128 | `90` | Detach distance. Must be > `call_max_r`. Scales bond fragility. |
| `flee_range` | 16 | 48 | `24` | Proximity flee trigger for non-match (no wave needed). |
| `flee_sp` | 0.8 | 2.5 | `1.4` | Flee speed. Higher = quicker exit. |
| `glow_growth` | 2 | 8 | `4` | Glow radius added per attached NPC. Per-attach visual swell. |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| Cast wave hits NPC exactly as it despawns (concurrent) | `del` before `for` body fires — `call.hit[n]` write on deleted entity harmless; entity gone next frame. |
| Cast wave hits NPC that Big is mid-stealing (`n.stolen=true`) | Skip branch — stolen excluded from call wave loop. |
| Player casts during attach chime `sfx(51)` playing | `sfx` re-triggers (PICO-8 allows). Acceptable. |
| NPC at exact edge `d == call.r` (boundary) | `d <= call.r` — included. |
| Cast wave radius exceeds `att_lose_range` (`call_max_r` should be <) | If `call_max_r > att_lose_range`, could attach an NPC at 80px then immediately detach at 90px check. Tuning guard: keep `call_max_r < att_lose_range`. |
| All attached NPCs flee via color change then player casts before `call.cd` expires | Blocked by `call.cd`. Player waits, then casts. Recovers bonds (no permanent lockout). |
| `norbit=0` (no matching NPCs) | Outer for-loop: `oi` never increments; no orbit code runs. `call wave` still fires and may set `att`. No div-by-zero (no div in slot math — `(oi-1)/norbit` would be div-by-zero → PICO-8 returns NaN-ish). Guard: branch only runs if `n.att`, and `n.att` requires prior matching wave; if `norbit=0` no NPC enters the branch. Safe in practice but undocumented edge worth flagging. |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| Fixed-point overflow in distance check (dx>181) | `sqrt` returns 0 → false-positive hit → cross-map attach (prior bug pattern) | Currently NOT overflow-guarded in call wave (only Big/flower guard). Low risk since `call_max_r=50` caps effective range, but if dx>181 and `d<=call.r` with `d=0`, attached from across map. **Flag: add `abs(dx)<call.r and abs(dy)<call.r` guard.** |
| Stale `call.hit[n]` persisting across casts | `call` re-initialized each cast (`call.hit={}`), so identity table reset. Safe. |
| `n.att` stuck on steal recovery: NPC `stolen=true` detached but `n.att` stays true | Big steal sets `n.att=false` alongside `n.stolen=true` (line 328-329). Safe. |
| `att_fc=nil` on legacy NPC (pre-att_fc field) | `fc-(n.att_fc or 0)` guards. Safe. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Call Wave Attach | Player Movement + Camera | ✅ | Orbit uses world `px,py`; `cam_y` drives flee despawn; ratchet means attached NPCs follow into new screen. |
| Call Wave Attach | Big NPC Thief | ⚠ | Big steal cadence reset `big.sc=0` on attach couples systems; documented. Also: Call Wave Attach has **no fixed-point overflow guard** like Big/flower have — flag. |
| Call Wave Attach | Flower Color-Change | ⚠ TBD | Flower flips `pcol`, detaches mismatches → moves NPCs between attract/flee branches. Coupled via `pcol`. |
| Call Wave Attach | Pollen Ambient | ✅ | No interaction. |
| Call Wave Attach | Dynamic Soundtrack | ✅ | `set_music_layers(att)` called on every attach/detach. |
| Call Wave Attach | Grass / Flower Visual | ⚠ TBD | Grass derives from NPC spawn table, not from `att` state. No interaction. |
| Call Wave Attach | Splash + Intro + Fade-In | ⚠ TBD | Music layers set on intro→play (`att=0`); first attach raises ch1. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P1 (detach prevents backtrack-recovery: bonds lost forward stay lost), P2 (all feedback visual/auditory, no text), P3 (`att` feeds aesthetics only, no score). |
| Connects to core loop? | Is the action input to Grow + an input to Lose (non-match flee). |
| Touches systems? | Glow, music, Big steal, feedback rings, audio. |
| Scope cost? | Per-NPC state (`att`, `att_fc`, `fleeing`, `fdx,fdy`, `stolen`) + per-cast `call` table + ring pool. Acceptable for jam. |
| Contradicts anything? | **Flag:** missing fixed-point overflow guard in call wave distance check. Pattern matches already-fixed Big/flower bugs. Add guard. **Flag:** potential `norbit=0` div-by-zero in slot angle math, currently masked by branching. Document. |

**Verdict:** PASS with two flags. Flag 1 (overflow guard) = real bug risk; fix candidate. Flag 2 (div-by-zero) = latent, currently unreachable; document only.