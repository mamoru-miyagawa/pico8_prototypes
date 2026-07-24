# System Design: Flower Color-Change

**Classification:** Core System — identity mechanic
**Scope Cost:** Medium — charge loop with player freeze, multi-stage particle effect (idle orbit / emit-home / spiral-in), color burst ring with pollen push, single-use per flower, overflow-guarded distance check

### Purpose

Hold X near an unused flower for 3 seconds → player's glow color changes to the flower's color. Color is the gate of the Call Wave system (system 02) — changing color re-routes which NPCs attract vs flee. This is the player's only identity-shifting action, and it costs bonds: mismatched attached NPCs detach and flee. Flower is the **trade** node — give up old bonds to enable new ones.

### Core Loop Connection

Sits between Grow and Lose — both an input to each. Color change can grow new matches (next call wave) and lose old matches (immediate detach). Single-use per flower, finite per session. Not a per-frame loop node; a discrete decision event triggered by proximity + hold.

### Pillars Served

- **P1 Always Move Forward:** Flowers are world-space, finite, single-use. Once passed, gone. No backtrack to re-trigger. Flower spawn at y=-27 (near start) means first flower encountered on ascent. Identity decisions are irreversible within a session — like bonds, like movement.
- **P2 Show, Don't Tell:** Flower visual speaks: sprite 9 (vibrant) vs 10 (inert after use), idle orbit particles in flower's color, charge ring expands with progress, particles emit from flower center then home to player, player-accumulating particles spiral in, color burst ring on completion. **VIOLATION: `print("hold ❎", px-9, (py-cam_y)+22, 7)` at loneliness.p8:519** — explicit text prompt telling player what to do. Tracked as T2/OQ3, deferred by user.
- **P3 Emotion Is the Only Currency:** Color change itself is not a goal — it's an emotional pivot. The trade (severed bonds) is the cost. New color = new identity = new potential bonds. No "color collected" counter, no flower-completed metric.

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `btn(5)` (X button) | player | held | Yes — charge trigger |
| `px, py` | player state | number | Yes — proximity |
| `f.x, f.y, f.col, f.used, f.charge` (per flower) | entity | number + bool + number | Yes |
| `flower_absorb_r` | tunable | number | Yes — proximity gate |
| `flower_charge` | tunable | number | Yes — hold duration |
| `pcol` | player state | number | Yes — `set_player_color` no-op guard |
| `cam_y` | camera | number | Yes — draw transform |

### Process

```
-- per frame, _update (before movement; flower_charging freezes player):
local flower_charging = false
for f in all(flowers):
  if not f.used:
    local fdx, fdy = px-f.x, py-f.y
    if abs(fdx) < flower_absorb_r and abs(fdy) < flower_absorb_r and btn(5):
      -- overflow guard before sqrt (fixed in prior bug)
      local fd = sqrt(fdx*fdx + fdy*fdy)
      if fd < flower_absorb_r:
        flower_charging = true
        f.charge = (f.charge or 0) + 1
        if f.charge >= flower_charge:           -- 90f = 3s @ 30fps
          f.charge = 0
          f.used = true                          -- sprite 9 → 10
          set_player_color(f.col)                -- detaches mismatched attached NPCs, sfx(52)
          add(rings, {r=8, a=36, vg=6, x=px+4, y=(py-cam_y)+4, col=f.col, burst=true})
      else:
        f.charge = 0                              -- out of range, reset
    else:
      f.charge = 0                                -- not holding X or not in range, reset

if not flower_charging:
  -- normal movement proceeds (system 01)

-- set_player_color(c):
if c == pcol: return                              -- no-op guard
pcol = c
pcol2 = glow_cols[c] or c                          -- outer glow color pair
for n in all(npcs):
  if n.col == c:
    n.fleeing = false                              -- matching NPCs (re-)attract
  elseif n.att and not n.stolen and n.col != c:
    n.att = false; n.fleeing = true                -- mismatched attached detach + flee
    set n.fdx, n.fdy (straight-up avoided)
    sfx(52)
recount att; set_music_layers(att)
```

**State Machine (per flower):**

```
States: Unused → Charging → Used (inert)
Transitions:
  Unused → Charging: player in range + btn(5) held
  Charging → Charging: each frame in range + btn held (charge++)
  Charging → Unused: out of range OR btn released (charge=0, reset)
  Charging → Used: charge >= flower_charge (90)
  Used → (terminal): sprite 10, no interactions, inert forever
```

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| `pcol` (new), `pcol2` (new outer) | Glow system, Call Wave color gate, NPC attract/flee branch | number | {6, 8, 12, 14} |
| `n.att=false`, `n.fleeing=true` (per mismatched attached) | NPC update, music, glow | flag | — |
| `att` recount | Glow radii, music layers | count | 0..N |
| `sfx(52)` | audio | trigger | — |
| `rings{r=8,a=36,vg=6,x,y,col,burst=true}` | feedback ring draw + pollen push | table | — |
| `f.used=true` | draw pass (sprite 9→10), interaction gate | boolean | — |
| `flower_charging` (local) | gates movement this frame | boolean | — |

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| Call Wave Attach | Writes `pcol` | Re-routes matching condition `n.col == pcol`. Mismatched attached → flee. Matching free → stop fleeing. |
| Call Wave Attach | Reads `f.col` | Flower color determines new `pcol` on completion. |
| Player Movement + Camera | Freezes player during charge | `if not flower_charging then movement`. Camera ratchet continues (Big could engage during charge — risk). |
| Big NPC Thief | Reads `att` after detach | If detach drives `att==0` mid-Big-cast, Big enters post-steal early. Likely benign (Big was stealing nothing anyway). |
| Pollen Ambient | Reads `r.burst` rings | Color burst ring pushes pollen aggressively (`flower_burst_s=8`), flags `p.burst=true`, despawns off-screen, `pollen_deficit++` → slow respawn. |
| Feedback Rings | Writes `rings{...burst=true}` | Burst ring is the only ring with `burst=true` flag. Own position, color, `vg=6`. |
| Glow + Player Visual | Reads `pcol` | Player glow recolors: outer in `pcol2`, mid/inner in `pcol`. |
| Dynamic Soundtrack | Calls `set_music_layers(att)` after detach recount | Layer drop = grief cue (same as Big steal). |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `flower_charge` | 30 | 180 | `90` | Frames to hold X (3s @ 30fps). Lower = quick swap; higher = deeper commitment, harder to trigger accidentally. |
| `flower_absorb_r` | 30 | 80 | `50` | Interaction range. Must be > player diagonal to avoid clipping past flower. |
| `flower_particles` | 4 | 16 | `8` | Idle orbit particle count (visual density). |
| `flower_orbit_r` | 6 | 20 | `10` | Idle orbit radius. Aesthetic only. |
| `flower_burst_s` | 4 | 16 | `8` | Pollen push strength on color change. Affects pollen scatter drama. |
| `flower_burst_r` | 40 | 120 | `80` | (Declared, used in ring radius? verify — appears unused in code path, only `r.r+8` used in pollen push) **Flag: dead tunable or rename.** |
| `flower_radius` | 4 | 12 | `8` | (Declared, appears unused in current logic — actual flower visuals use sprite 9/10, not `circfill`.) **Flag: dead tunable, candidate for deletion.** |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| Player enters range, taps X briefly, leaves | `f.charge` resets to 0. Next entry restarts from 0. No partial charge saved. |
| Player holds X in range of two unused flowers simultaneously | Inner loop per-flower: both increment `f.charge` per frame. `flower_charging` latches true on first. Risk: both flowers complete same frame if overlapping. No overlap in current level (`flowers` has 1 entry at y=-27). Safe for now; flag if multi-flower overlap added. |
| Color change to current color (`f.col == pcol`) | `set_player_color` no-op guard returns early. **RESOLVED 2026-07-24:** Prevent mis-input — flower must NOT be consumed on no-op. Add guard: skip `f.used=true` + burst if `f.col == pcol`. Reset `f.charge=0` instead. Code change TBD. |
| Cast wave in flight during color change | Call wave uses `pcol` at hit-check time. NPC mid-wave changes from-attract-to-flee branch mid-flight. Acceptable dynamic behavior. |
| Big cast active during flower charge | Player frozen 3s in Big's `steal_range` (56). Big could steal during charge. Risk: player loses bonds *while* paying color-change cost. **RESOLVED 2026-07-24:** Level design constraint — no flower placed within Big's `steal_range` radius of any Big spawn. Enforced via `level_editor.html` placement discipline, not code. If violated later, revisit. |
| Player ratchets above flower mid-charge | Flower screen Y goes below player view (`sy < -8`), but `fdx,fdy` is world-space — charge continues based on world distance. Charge completes after flower offscreen. Likely fine but odd feel. |
| Flower spawns on top of NPC | No collision check between flowers and NPCs. Possible to change color while an NPC orbits on same spot — visual stack only. |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| Fixed-point overflow in flower distance check | Already guarded (prior bug fix): `abs(fdx)<flower_absorb_r and abs(fdy)<flower_absorb_r` before `sqrt`. Safe. |
| `f.charge` nil on first frame | `(f.charge or 0)` guard throughout. Safe. |
| Color burst ring spawns at player x,y but player moves same frame | Ring uses `x=px+4, y=(py-cam_y)+4` captured at spawn; ring position locked. Safe. |
| `set_player_color` called when `npcs` table not initialized | `for n in all(npcs)` is safe on missing/empty table. Safe. |
| Player kills X mid-charge frame after `set_player_color` firing | Color already set; flower already `used=true`. No rollback. Acceptable — commitment enforced. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Flower Color-Change | Call Wave Attach | ⚠ | Writes `pcol` which re-routes Call Wave's color gate — strongest coupling in cart. Shared `att` recount. Same `sfx(52)` on detach. |
| Flower Color-Change | Big NPC Thief | ⚠ | Dual-loss tension: Big can steal during 3s charge freeze. Design decision pending — intentional grief or unfun? |
| Flower Color-Change | Player Movement + Camera | ⚠ | Player freeze during charge; camera ratchet continues; flower offscreen mid-charge edge case. |
| Flower Color-Change | Pollen Ambient | ✅ | Burst ring pushes pollen + despawn + deficit respawn. Documented. |
| Flower Color-Change | Dynamic Soundtrack | ✅ | `set_music_layers(att)` on detach recount. |
| Flower Color-Change | Grass / Flower Visual | ✅ | Flower sprite 9→10 own draw pass; shadow under glow. |
| Flower Color-Change | Splash + Intro + Fade-In | ⚠ TBD | Flowers initialized in tab 1; `f.used=false`, `f.charge` nil. First interaction requires player to travel to flower y and discover X mechanic (P2 violation via prompt). |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P1 (finite, single-use, world-space, no backtrack), P2 (violated by "hold x" prompt — tracked T2/OQ3), P3 (identity shift costs bonds — pure emotional trade, no metric). |
| Connects to core loop? | Both Grow (enables new bonds) and Lose (severs old ones). A decision node between loop phases. |
| Touches systems? | Call Wave (color gate), Pollen (burst), Rings, Music, Glow, Movement (freeze). Highest coupling count after Big. |
| Scope cost? | Multi-stage particle system is the bulk of code. Inherited: any new player-color-dependent system must read `pcol`. `glow_cols` table hardcodes 4 colors — adding 5th color means editing the table. |
| Contradicts anything? | **Flag 1 (P2 T2):** "hold x" prompt, deferred. **Flag 2:** dual-loss tension (Big during charge) — design decision point. **Flag 3:** dead/duplicate tunables (`flower_burst_r`, `flower_radius`) — ponytail deletion candidates. **Flag 4:** no-op color change still consumes flower (mis-input cost) — design decision point, currently accepted. |

**Verdict:** PASS with 4 flags.
- **Flag 1** (P2 "hold x" prompt) — deferred per user (T2/OQ3).
- **Flag 2 RESOLVED 2026-07-24:** Big-not-near-flower is a level-editor placement discipline, not a code rule. `level_editor.html` must enforce: no flower within `steal_range=56` of Big spawn. Documented in system 03 + level-editor system (TBD). If level design breaks rule, revisit.
- **Flag 3** (dead tunables `flower_burst_r`, `flower_radius`) — review later per user.
- **Flag 4 RESOLVED 2026-07-24:** Prevent mis-input. `set_player_color` no-op must propagate back: skip `f.used=true` + burst ring + charge reset to 0 when `f.col == pcol`. Code change TBD.

**New mechanic raised 2026-07-24 — Narrative Event lock:**
- Some flowers / NPCs flagged as Narrative Events.
- When player enters event radius, camera ratchets lock until event interaction complete.
- Flower event: complete = color change (any color, including no-op-with-guard? design TBD).
- NPC event: complete = NPC attached OR fled.
- Not in code. Design decision recorded; implementation TBD (see OQ6).