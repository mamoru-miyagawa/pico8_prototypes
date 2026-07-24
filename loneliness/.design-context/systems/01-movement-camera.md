# System Design: Player Movement + Ratchet Camera

**Classification:** Core System
**Scope Cost:** Low-Medium (camera math + world-space Y conversion on every entity draw)

### Purpose

The player moves freely in 2D within corridor bounds; the camera ratchets upward only. This is the literal enforcement of P1 (Always Move Forward) and the axle on which the Move node of the core loop rotates. Without it, loss has no weight (bonds could be re-earned by backtracking) and ascent has no meaning.

### Core Loop Connection

**Move node.** Player input drives `px,py`. `update_camera()` runs after movement per frame, ratcheting `cam_y` upward when the player enters the top dead-zone and clamping downward motion at the screen bottom. All entities (NPCs, pollen, grass, flowers, Big, rings) inherit the world-to-screen transform `y - cam_y` for parallax. The loop returns to Move from Grow and Lose unchanged.

### Pillars Served

- **P1 Always Move Forward:** `cam_y` only decreases (ratchet clause); bottom clamp `py = cam_y + 120` blocks downward escape from current screen; no `__map__` reload.
- **P2 Show, Don't Tell:** Movement is direct input → response. No tutorial, no map overlay, no direction hints. Visible parallax (pollen/grass scroll downward) communicates ascent without text.
- **P3 Emotion Is the Only Currency:** No speed stat displayed, no distance meter, no height score. `spd` is a dev-facing tunable only.

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `btn(0)` / `btn(1)` | player | held | Yes — horizontal |
| `btn(2)` / `btn(3)` | player | held | Yes — vertical |
| `spd` | tunable (top of file) | number | Yes — px/frame |
| `px, py` | player state | number | Yes |
| `cam_y` | system state | number | Yes |

### Process

```
-- per frame, _update:
if btn(0) then px-=spd end
if btn(1) then px+=spd end
if btn(2) then py-=spd end
if btn(3) then py+=spd end
update_camera()

-- update_camera():
local sy = py - cam_y
if sy < cam_dead then cam_y -= (cam_dead - sy) end   -- ratchet up only
if py > cam_y + 120 then py = cam_y + 120 end         -- bottom clamp (no regress)
px = mid(corridor_l, px, corridor_r)                 -- corridor walls

-- _draw entity transform:
screen_y = world_y - cam_y
```

**State Machine:** not applicable — single state, per-frame.

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| `px, py` | every entity/update using world position | number | corr x ∈ [0,120]; y ∈ (-∞, cam_y+120] |
| `cam_y` | every entity draw transform | number | (-∞, spawn 0], only decreasing |
| `sy` (local) | ratchet decision | number | [0, 120] (clamped) |

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| All entity draws | Reads `cam_y` | World-to-screen Y = `world_y - cam_y`. Drives parallax pollen/grass, NPC screen pos, Big screen pos, flower screen pos, feedback ring center. |
| Pollen system | Reads `cam_y` | Wrap band ±160 around camera; pollen respawn on burst uses `cam_y + rnd(128)`. |
| Big NPC despawn | Reads `cam_y` | Despawn when `big.y - cam_y > 144` (off bottom). |
| NPC flee despawn | Reads `cam_y` | Despawn when `n.y > cam_y + 144`. |
| Corridor bounds | Written by | `px` clamped to `[corridor_l=0, corridor_r=120]`. Lateral walls enforced in code, not visible. |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `spd` | 0.5 | 2 | `1` | Player px/frame. Lower = heavier feel; higher = arcade-y. P3 says no speed metric — keep invisible. |
| `cam_dead` | 16 | 96 | `60` | Screen-Y threshold that triggers ratchet. Lower = camera follows sooner (player stays lower on screen); higher = more tolerance before ratchet. |
| `corridor_l` | 0 | 60 | `0` | Left wall x. Corner-bumps player. |
| `corridor_r` | 68 | 120 | `120` | Right wall x. |

**Ponytail note:** `corridor_l/r` are invisible walls — P2 violation candidate (player learns by bonking). Acceptable for jam scope; flagged for later if walls become a confusion point.

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| Frame 1 (spawn): `cam_y=0`, `py=84`, `sy=84` | `sy > cam_dead=60` → no ratchet, no bottom clamp (84<120). Player may move down 36px before bottom clamp fires. Pedantically violates "no going back" but within-screen local nav, not world regress. Acceptable interpretation of P1. |
| Player holds Down for full session | `py` clamps at `cam_y + 120`. Camera frozen. Player stuck on bottom edge until Up pressed. Not a fail state — soft-stick. |
| Player holds Up continuously | Ratchet engages every frame, `cam_y` decreases by `(cam_dead - sy)` ≈ `60 - py_offset`. World scrolls down at `spd` rate. Pure ascent. |
| `py` would exceed `cam_y+120` from below (spawn delta) | Clamp sets `py = cam_y + 120`. No teleport — single-frame slide via `mid`. |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| `corridor_l/r` mistakenly swapped (`l>r`) | `mid()` returns garbage; player teleports to `r` | Verify tunable order; not in code path currently. |
| `cam_y` accidentally increases (regress bug) | World scrolls up — backward motion felt, P1 break | Ratchet clause has no `+=` branch. Add `assert`-style `printh` guard if needed. |
| `spd=0` | Player frozen. No fail state catch. | Tunable discipline; do not set 0. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Movement + Ratchet Camera | Color-Matched NPC Attach | ⚠ | TBD — NPC orbit uses world `px,py`; attach range check needs overflow guard at large world deltas. |
| Movement + Ratchet Camera | Big NPC Thief | ⚠ | TBD — Big despawn bound on `cam_y+144`; fixed-point overflow already fixed in steal search. |
| Movement + Ratchet Camera | Flower Color-Change | ⚠ | TBD — Flower uses world coords; fixed-point overflow guard already applied. |
| Movement + Ratchet Camera | Pollen Ambient | ✅ | Pollen wraps in world band ±160 around `cam_y`. Documented in devlog. |
| Movement + Ratchet Camera | Dynamic Soundtrack | ⚠ | TBD — Music schedule independent of camera; `cam_y` not consumed by `set_music_layers`. Likely no interaction. |
| Movement + Ratchet Camera | Splash + Intro + Fade-In | ⚠ | TBD — Splash/intro/fade run before camera engages; `cam_y=0` initialized at runtime. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | Yes — P1 (ratchet enforces), P2 (silent teaching via parallax), P3 (no speed/distance metric). |
| Connects to core loop? | Yes — *is* the Move node. |
| Touches systems? | All entity draw paths, pollen wrap, Big/NPC despawn bounds. |
| Scope cost? | Already implemented. Inherited constraints: every new entity must convert `y-cam_y`. No `__map__` reloads ever. |
| Contradicts anything? | Edge case: frame-1 local down-movement within spawn screen. Pedantic P1 question — user decision: is "no going back" world-only or screen-also? Default: world-only (camera ratchet), screen-local ok. |

**Verdict:** PASS. One flag (corridor invisible walls, P2-adjacent) deferred to pair pass / judge phase.