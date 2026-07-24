# System Design: Big NPC Thief

**Classification:** Core System — antagonist
**Scope Cost:** Medium-High — multi-state AI (cast → steal cadence → post-steal pause → locked retreat), per-stolen orbit around Big, fixed-point overflow guard, own glow + animation cycle, pollen push during cast.

### Purpose

A 2×2 sprite NPC that hunts attached bonds, casts a warning ring, plucks them one at a time, then retreats off-screen. This system is the primary **Lose** agent — the source of grief that P3 makes the emotional substance of the game. Without Big, growth is unbounded and the loop has no tension. Big is the only entity in the game that can take a bond without the player choosing to change color.

### Core Loop Connection

**Lose node.** Big converts Attached NPCs into Stolen ones, decrementing `att` → glow shrinks → music layer drops. Also pushes pollen during the cast ring (secondary). Triggered by spatial proximity to an *attached* NPC (not the player). Player cannot destroy Big, only outpace it (P1 — move forward) or sacrifice a bond.

### Pillars Served

- **P1 Always Move Forward:** Big's retreat direction is horizontal-biased (`fy*=0.2`, straight-up avoided) and locked at post-steal end. Player can only escape by ascending away. Big despawns off any screen edge. Forward motion = escape.
- **P2 Show, Don't Tell:** Cast ring is a visible warning (36f expansion, `vg=4.5`). Steal visible as NPC snaps to Big's orbit. Retreat visible. No "danger" text, no health bar on Big, no tutorial. Twitch + glow mirror player structure so Big reads as a dark twin.
- **P3 Emotion Is the Only Currency:** Big has no HP, no score value, no kill reward. Its only output is *loss*. `sfx(52)` detach chime = the grief signal. Big's glow is aesthetic, not a health bar.

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `big.x, big.y` | entity state | number | Yes |
| `big.done` | entity state | boolean | Yes — gate whole block |
| `big.retreat` | entity state | boolean | Yes — branch |
| `big.cast, big.cast_t` | entity state | bool + number | Yes — steal phase |
| `big.sc` | entity state | number | Yes — steal cadence |
| `big.post_steal` | entity state | number | Yes — pre-retreat pause |
| `big.fdx, big.fdy` | entity state | number | Yes — retreat vec |
| `big.jx, big.jy` | entity state | number | Yes — twitch |
| `px, py` | player | number | Yes — proximity trigger, retreat dir |
| `n.att, n.att_fc, n.stolen` | per NPC | bool + number + bool | Yes — steal target |
| `fc` | global | number | Yes — `steal_grace` calc |
| `cam_y` | camera | number | Yes — onscreen guard, despawn |

### Process

```
-- per frame, _update (after call wave, after NPC orbit):
if not big.done:
  local bdy = big.y - cam_y
  local big_onscreen = bdy > -16 and bdy < 144

  if not big.retreat:
    if big_onscreen:
      -- proximity (player-to-Big) triggers cast, then steal searches NPC-to-Big
      local pdx, pdy = px-big.x, py-big.y
      if abs(pdx) < steal_range and abs(pdy) < steal_range     -- overflow guard
         and sqrt(pdx*pdx+pdy*pdy) < steal_range:
        if not big.cast:
          big.cast = true; big.cast_t = 36
          add(rings, {r=8, a=36, vg=4.5, x=big.x+8, y=(big.y-cam_y)+8})

      if big.cast:
        if big.cast_t > 0:
          big.cast_t -= 1
        else:
          big.sc += 1
          if big.sc >= steal_interval:
            big.sc = 0
            for n in all(npcs):
              if n.att and not n.stolen and fc-(n.att_fc or 0) > steal_grace:
                n.att = false; n.stolen = true; sfx(52)
                recount att; set_music_layers(att)
                break   -- one steal per cadence tick

    -- if cast done and no targets left, start post-steal pause
    local att = count(n.att and not n.stolen)
    if big.cast and big.cast_t <= 0 and att == 0 and not big.post_steal:
      big.post_steal = 15

    if big.post_steal:
      big.post_steal -= 1
      if big.post_steal <= 0:
        big.engaged = true; big.retreat = true
        rdx, rdy = big.x-px, big.y-py
        rd = sqrt(rdx*rdx+rdy*rdy)
        if rd > 0.001:
          fx, fy = rdx/rd, rdy/rd
          if fy < 0 and abs(fx) < 0.001: fx = 1        -- no straight up
          fy *= 0.2                                     -- horizontal bias
          renormalize; big.fdx, big.fdy = fx, fy
  else:
    big.x += big.fdx * big_retreat_sp
    big.y += big.fdy * big_retreat_sp
    if big.y-cam_y > 144 or big.x < -16 or big.x > 144: big.done = true

-- stolen NPCs orbit Big (in main NPC loop, see system 02):
if n.stolen:
  if scount > 0:
    a = fc*0.008 + si/scount
    slot = big.x + cos(a)*16, big.y + sin(a)*16
    lerp n toward slot at 0.05
  si += 1
  if big.done: del(npcs, n)    -- garbage collect stolen NPCs on Big exit

-- big twitch (with player's 8f cadence):
if fc%8 == 0: big.jx = flr(rnd(3))-1; big.jy = flr(rnd(3))-1
```

**State Machine (Big):**

```
States: Idle (onscreen, cast not yet triggered) → Casting → Stealing → PostSteal → Retreating → Done (despawned)
Transitions:
  Idle → Casting: player within steal_range (56)
  Casting → Stealing: cast_t reaches 0
  Stealing → PostSteal: att==0 and cast complete
  PostSteal → Retreating: 15f pause elapses
  Retreating → Done: off any screen edge
  (any state) → Done: off-screen during retreat only; idle/cast/steal stay engaged onscreen
```

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| `n.stolen=true` (per stolen NPC) | NPC orbit branch, Big orbit count `scount` | boolean | — |
| `att` decrement | Glow, music, light (deprecated — glow only now) | count | 0..N |
| `sfx(52)` | audio | trigger | — |
| `rings{r=8,a=36,vg=4.5,x,y}` | feedback ring draw + pollen push | table | — |
| `big.x, big.y` | draw pass (3-circle glow + 2×2 sprite), stolen NPC orbit anchor | number | world |
| `big.done=true` | stolen NPC garbage collection (`del(npcs,n)`) | boolean | — |

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| Call Wave Attach | Reads `n.att`, `n.att_fc`, `n.stolen` | Steal search predicate. Attach resets `big.sc=0` so fresh bonds get `steal_grace` window. |
| Call Wave Attach | Is read by | Call wave excludes `n.stolen`, so stolen NPCs immune to player recall. |
| Pollen Ambient | Reads `big.cast`, `big.cast_t` | Cast ring pushes pollen outward during expansion (`br = 36 - cast_t`, reach `br + 16`, strength 6). |
| Player Movement + Camera | Reads `cam_y` | Onscreen guard `bdy ∈ (-16,144)`, despawn `bdy > 144`. Big AI gate uses player world pos. |
| Dynamic Soundtrack | Calls `set_music_layers(att)` after each steal | Layer drops as `att` decreases. |
| Feedback Rings | Writes `rings{...vg=4.5,x,y}` | Cast ring uses per-ring position + expansion speed (`vg`), not player center. |
| Glow + Player Visual | Independent | Big has its own `bg0/bg1/bg2` radii (32/26/20), col 1/12/12, not linked to player `g0/g1/g2`. |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `steal_range` | 32 | 96 | `56` | Player-to-Big proximity to trigger cast. Doubled from 28 in v2. Larger = Big engages from further, harder to skirt. |
| `steal_interval` | 8 | 30 | `15` | Frames between each steal. Lower = faster drain. |
| `steal_grace` | 30 | 120 | `60` | Frames after attach before stealable. Player breathing room for fresh bonds. |
| `big_retreat_sp` | 0.2 | 1.0 | `0.3` | Retreat speed. Slow = lingering threat after cast. |
| `bg0/bg1/bg2` | 16/12/8 | 48/36/24 | `32/26/20` | Big glow radii. Visual threat scale. |
| `post_steal` (hardcoded) | 8 | 30 | `15` | Pause after all bonds stolen, before retreat. Dramatic beat. Not a top-of-file tunable currently — **flag: expose.** |
| `cast_t` (hardcoded) | 24 | 60 | `36` | Cast ring duration + expansion. Warning window. Not a top-of-file tunable — **flag: expose.** |
| `big_idle_drift` (proposed) | 0 | 1 | TBD | Horizontal drift toward nearest side wall when onscreen but unengaged. Prevents skirting. **Design decision 2026-07-24, not yet implemented.** |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| Player enters `steal_range` with `att=0` | Cast triggers, completes, immediately hits `att==0` post-cast → `post_steal=15` → retreat. No steals occur. Big wastes cast on empty player. |
| Player exits `steal_range` mid-cast | Cast continues to completion (no cancel). Steal cadence still runs as long as any `n.att` exists. |
| All attached NPCs pass `steal_grace` simultaneously | `break` after first steal — one per `steal_interval`. Cadence enforced. |
| `big.done` set true with stolen NPCs still in `npcs` | Next NPC loop iteration: `if big.done then del(npcs,n)`. Stolen garbage-collected. |
| Big spawns with no attached NPCs in session yet | Idle until player attaches one and Big enters `steal_range`. Single Big per session (`big` global, not re-spawned). |
| Player ratchets camera above Big during cast | `big_onscreen` may go false mid-cast — cast block only enters if `big_onscreen`; but `big.cast` persists and `cast_t` decrements. **Potential bug: if Big goes offscreen mid-cast, steal loop still runs as long as `big.cast` is true.** Verify. |
| Fixed-point overflow in steal search | Already guarded: `abs(pdx)<steal_range and abs(pdy)<steal_range` before `sqrt` (line 312). Inherited from prior bug fix. |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| `big.cast_t` decrements below 0 without steal targets | Safe — `if big.cast_t > 0` gates decrement, then `else` steal branch. Post-steal triggers when `cast_t <= 0 and att == 0`. |
| `big.post_steal` nil on first cast completion | Set to `15` only when `att==0 and not big.post_steal`. If `att > 0`, post_steal never starts — Big keeps stealing until none left. Correct. |
| Stolen NPC deleted while Big still casting | `big.done` false during cast; stolen NPCs only `del` when `big.done`. Safe. |
| Big retreats toward player (radial back) | Retreat vec uses `big - player`, so Big moves *away* from player. Horizontal-biased + straight-up-avoided. Cannot chase. |
| Player never approaches Big; Big idles onscreen forever | Big only despawns via retreat (post-cast). If player skirts `steal_range`, Big never triggers cast, never retreats. **Risk: Big clutters screen indefinitely. Mitigation: none current. Flag.** |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Big NPC Thief | Player Movement + Camera | ✅ | Overflow guard + onscreen guard + despawn bound + horizontal-biased retreat compounds with ratchet (player ascend = escape). |
| Big NPC Thief | Call Wave Attach | ⚠ | Shared `att` count, `n.att/att_fc/stolen` fields, `big.sc=0` reset on attach. Coupled. Flag: cast continues even if Big offscreen (edge case above). |
| Big NPC Thief | Flower Color-Change | ⚠ TBD | Flower detach via `set_player_color` reduces `att`. If reduces to 0 mid-Big-cast, Big enters post-steal early. Likely benign, undocumented. |
| Big NPC Thief | Pollen Ambient | ✅ | Cast ring pushes pollen; documented. |
| Big NPC Thief | Dynamic Soundtrack | ✅ | `set_music_layers(att)` after each steal. Layer drop = grief cue. |
| Big NPC Thief | Feedback Rings | ✅ | Cast ring uses `r.x, r.y, r.vg` — only ring with own position + expansion speed. |
| Big NPC Thief | Grass / Flower Visual | ⚠ TBD | Grass static, no interaction. |
| Big NPC Thief | Splash + Intro + Fade-In | ⚠ TBD | Big spawn at y=-260 (world) during init; spawn-guarded by `big_onscreen`. During fade-in Big may already be visible if camera starts near y=0. Verify. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P1 (forward = escape, no other defense), P2 (visible cast ring, no HP bar, no text warning), P3 (output is loss only; no score, no kill reward). |
| Connects to core loop? | Is the Lose agent. Without it, Lose only fires via player-chosen color change. Big = involuntary loss. |
| Touches systems? | Call wave (shared `att`/`stolen`), pollen (cast push), music (layer drop), feedback rings (cast ring), NPC orbit (stolen orbit branch). |
| Scope cost? | Multi-state AI + own glow + 2×2 sprite + stolen orbit branch + overflow guards. Highest-complexity system in cart. Justified by P3: involuntary loss is the engine of emotional tension. |
| Contradicts anything? | **Flag 1:** `post_steal` and `cast_t` hardcoded — violates tunable discipline (ponytail: only a concern if you actually tweak). **Flag 2:** Big lingers forever if player skirts range — no timeout. Compatibility with P3 unclear: lingering threat could read as dread or as clutter. **Flag 3:** Cast may continue offscreen (edge case) — minor bug. **T1 already resolved:** Big retreats downward but P1 binds player POV. |

**Verdict:** PASS with 3 flags.
- **Flag 1** (expose `post_steal` + `cast_t` tunables) = small cleanup, deferred.
- **Flag 2 RESOLVED 2026-07-24:** Big will drift toward nearest side wall when onscreen but unengaged (no cast triggered). Goal: faster exit, prevents player skirting `steal_range` to keep Big idle forever. Serves P1 (forward-only escape) + P3 (dread without fatigue). New tunable `big_idle_drift` proposed. **Not yet implemented — design decision recorded, code change TBD.**
- **Flag 3 DEFERRED 2026-07-24:** Cast may continue if Big goes offscreen mid-cast; Big spawn timing during fade-in. User: "Big should only be active when it appears on screen so it doesn't matter too much whether it spawns at start or only when the player is close. Might become a bug eventually but should wait and see." Revisit if observed.