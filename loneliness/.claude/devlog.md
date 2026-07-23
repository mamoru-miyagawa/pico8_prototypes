# devlog — loneliness

Living record of completed features. Newest at the bottom. Read at the start of every session to restore context.

---

## NPC Twitch
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** NPCs jitter the same way the player does.
- **What it does:** Each NPC rerolls its own `jx/jy` offset every 8 frames (`fc%8==0`) and applies it to `spr`, so NPCs desync naturally from the player and each other.
- **How implemented:**
  - Added `jx=0,jy=0` fields to each NPC table in `npcs`.
  - In NPC draw loop: `if fc%8==0 then n.jx=flr(rnd(3))-1; n.jy=flr(rnd(3))-1 end`
  - `spr(s, n.x+n.jx, n.y+n.jy)`
  - Glow position `nx,ny` stays anchored (no jitter on light), matches player where `cx,cy` uses clean `px,py`.

## NPC Orbit & Attraction
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** NPCs approach the player when close and orbit around them.
- **What it does:** Within attract range, each NPC eases toward a rotating slot on a ring around the player. N NPCs split the circle evenly: 1 alone, 2 opposite, 3 triangle, etc.
- **How implemented:**
  - Update loop, per NPC: `if d<attract_range or n.att then ... end`
  - Slot angle: `fc*angular_vel + (i-1)/#npcs` (phase split by index)
  - Slot pos: `px+cos(a)*orbit_radius, py+sin(a)*orbit_radius`
  - Lerp: `n.x += (tx-n.x)*sp` (sp differs for attached vs approaching)
  - `cos/sin` use PICO-8 turns (1.0 = full circle).

## Attachment System
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** NPCs attach to the player on close proximity and stay attached permanently.
- **What it does:** First time a NPC gets within attach range, `n.att` flips true and never resets. Attached NPCs: keep orbiting regardless of distance, lose their circle glow, and each grows the player's glow. On attach, an expanding feedback ring emits from the player and fades.
- **How implemented:**
  - `n.att` field on each NPC, `false` until `d<attach_range`, then `true` forever.
  - Orbit gate: `d<attract_range or n.att` → attached NPCs never detach.
  - Draw: `if not n.att then` draw NPC glow `else` skip it.
  - Player glow: count `att`, radii = base + `att*glow_growth` + flicker.
  - Feedback rings: `rings={}` pool, spawn `{r=8,a=12}` on attach. Update: `r.r+=1.5; r.a-=1; del if a<=0`. Draw: `circ(cx,cy,r.r,col)` with color step-down as `a` decreases.
- **Tunables added:**
  - `glow_growth=3` — glow radius added per attached NPC
  - `att_sp=0.2` — attached NPC lerp speed toward orbit slot (faster than approach speed so attached NPCs follow tighter)

## Pollen Repulsion
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Pollen particles flee from the player when it gets close.
- **What it does:** Within `pollen_rep_r`, pollen is pushed directly away from the player with linear falloff (stronger near center, zero at edge). Player-only, constant strength. Composes with existing drift; wraparound still applies.
- **How implemented:**
  - In pollen update loop, before drift: compute `dx,dy=p.x-px,p.y-py`, `d=sqrt(...)`.
  - `if d<pollen_rep_r and d>0.001 then f=(pollen_rep_r-d)/pollen_rep_r*pollen_rep_s; p.x+=dx/d*f; p.y+=dy/d*f end`
  - Then existing `p.x+=p.vx` drift and wraparound.
- **Tunables added:**
  - `pollen_rep_r=30` — repulsion radius from player
  - `pollen_rep_s=0.5` — push strength (constant across all pollen)

## Pollen Count Tunable
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Pollen particle count is a variable.
- **What it does:** `pollen_n` controls how many pollen particles spawn at init. Change one number at the top instead of editing the loop bound.
- **How implemented:**
  - `pollen_n=20` declared at top with other tunables.
  - `for i=1,pollen_n do` in pollen init.
- **Tunables added:**
  - `pollen_n=20` — pollen particle count

## Pollen Draw Order
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Pollen renders on top of everything.
- **What it does:** Pollen drawn last in `_draw`, after glow, light, feedback rings, NPCs, and player sprite. Pollen sits on top visually.
- **How implemented:**
  - Moved pollen draw loop to the end of `_draw`, after player sprite.

## Devlog System
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** A skill + context file that records completed features and is auto-loaded every session.
- **What it does:** The `devlog` skill prompts the AI to register features on completion (with user confirmation). `.claude/devlog.md` accumulates entries and is read at session start via `opencode.json` `instructions` (opencode) and `CLAUDE.md` pointer (Claude Code), so context survives across sessions.
- **How implemented:**
  - `.claude/skills/devlog/SKILL.md` — workflow skill (prompt, format, append-only).
  - `.claude/devlog.md` — this file, seeded with session's features.
  - `opencode.json` — `instructions: [".claude/devlog.md"]` for opencode auto-load.
  - `CLAUDE.md` — pointer telling Claude to read devlog at session start.

## Project Skills
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Two reusable AI skills encoding cart conventions, cross-tool compatible (opencode + Claude Code).
- **What it does:** `pico-8` skill covers generic PICO-8 Lua idioms (cart format, lifecycle, builtins, no-deps philosophy). `loneliness` skill covers this cart's exact patterns (tunables at top, entity shape, twitch, orbit, attachment, pollen repulsion, draw order, light engine black box). Both auto-load when editing `.p8` files via `paths` frontmatter + description keywords.
- **How implemented:**
  - `.claude/skills/pico-8/SKILL.md` — generic PICO-8 reference, `paths: **/*.p8`.
  - `.claude/skills/loneliness/SKILL.md` — cart-specific conventions, `paths: **/loneliness.p8`.
  - Both use shared `.claude/skills/` path scanned by opencode and Claude Code.

## Splash Screen
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Title screen shown before gameplay, with logo and studio name.
- **What it does:** On boot, `state="splash"` gates `_update` and `_draw`. Shows logo (4×4 sprite block via `sspr`) + "hoshibocchi games" text on `cls(1)` background. Auto-starts after 2 seconds (`fc>=60` @ 30fps); any button skips early. Returns early from both callbacks while in splash — no gameplay updates or draws.
- **How implemented:**
  - `state="splash"` declared at top, defaults to splash on boot.
  - `_update`: `if state=="splash" then if fc>=60 or btnp(any) then state="play" end return end`
  - `_draw`: `if state=="splash" then cls(1); sspr(0,96,32,32,48,40); print("hoshibocchi games",32,88,7); return end`
  - Logo at y=40 (moved 8px up from center), title at y=88.
  - Marked with `-- splash screen` comment at entry point.

## Feature Comment Convention
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** New features marked with a brief comment at their entry point.
- **What it does:** Every new feature gets a one-line comment (e.g. `-- splash screen`) so the user can locate features in the file. Does not narrate every line — just the entry point.
- **How implemented:**
  - Updated `pico-8` skill: replaced "No comments unless asked" with "Add a brief comment marking each new feature".
  - Updated `loneliness` skill: added same rule to "Making changes" section.
  - Applied to splash screen as first example.

## Light Scales with Attachment
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Light engine brightness grows per attached NPC, so the lit area expands with the glow.
- **What it does:** `bri=1.2+att*light_growth` feeds `fl_light`, and since `bf=bri*bri` inside, the light radius scales quadratically. Outer glow circles and light rect now grow together.
- **How implemented:**
  - Added `light_growth=0.06` tunable next to `glow_growth`.
  - In `_draw`: `local bri=1.2+att*light_growth` replaces fixed `bri=1.2`.
- **Tunables added:**
  - `light_growth=0.06` — brightness added per attached NPC (scales light radius via `bf=bri*bri`)

## Noise Shader Removed
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Per-row random multiplier removed from light engine.
- **What it does:** `fl_light` had `mul=bf*(rnd(0.16)+0.92)` rerolled per scanline, causing horizontal banding at large glow sizes. Replaced with `mul=bf` deterministic. Glow circles' own flicker (line 194-196) untouched.
- **How implemented:**
  - `local mul=bf*(rnd(0.16)+0.92)` → `local mul=bf` in `fl_light`.

## _sqrt Table Extended
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** `_sqrt` lookup table range doubled to fix blank horizontal lines at large glow.
- **What it does:** `init_blending` built `_sqrt` to index 4096. At high `att`, `brng=light_rng[lv]*bf` exceeded 4096 → `_sqrt[brng-ysq]` returned nil → `brkpts` kept stale values → blank gaps in light rect. Extended to 8192 for headroom (safe up to bri≈2.15).
- **How implemented:**
  - `for i=0,4096 do` → `for i=0,8192 do` in `init_blending`.

## Light Flicker Sync
- **Date:** 2026-07-15
- **Status:** complete
- **What it is:** Light engine brightness now flickers in sync with glow circles.
- **What it does:** Glow circles (`g0/g1/g2`) reroll every 12 frames with `rnd` jitter, but `bri` was fixed — light rect didn't animate. Added `gbri` rerolled on same `fc%12` tick with matching amplitude (`rnd(0.16)-0.08`), feeds both `lrng` and `fl_light`.
- **How implemented:**
  - Added `gbri=1.2` init next to `g0/g1/g2`.
  - In `fc%12==0` block: `gbri=1.2+att*light_growth+rnd(0.16)-0.08`.
  - `local lrng=flr(42*gbri)` and `fl_light(cx,cy,gbri)` replace fixed `bri`.

## Splash Logo SFX
- **Date:** 2026-07-16
- **Status:** complete
- **What it is:** One-shot SFX sting plays on boot alongside the splash logo.
- **What it does:** `sfx(50)` fires once in `_init` (loneliness.p8:121). Slot 50 composed by user in PICO-8 SFX editor. Splash stays otherwise silent; soundtrack starts later on gameplay.
- **How implemented:**
  - Added `sfx(50) -- splash logo sting` in `_init` after `init_blending(6)`.

## Dynamic Soundtrack
- **Date:** 2026-07-16
- **Status:** complete
- **What it is:** 2-pattern looping soundtrack in Dm with layers that join per NPC attach.
- **What it does:** Bass plays alone at gameplay start. Pad joins on 1st NPC attach, melody on 2nd. No restart, no desync — layers toggle via PICO-8's native channel-empty flag (bit 6 of music pattern channel bytes). Transitions hit at next pattern boundary, so layer additions land on musical phrase starts.
- **How implemented:**
  - User composed patterns 0-1 in PICO-8 music/SFX editor (3 channels: ch0 bass, ch1 pad, ch2 melody; ch3 silent). `__music__` pattern 1 carries loop-back flag `02` so 0↔1 loops forever.
  - `set_music_layers(att)` function (loneliness.p8:16) pokes `0x3100+pattern*4+channel`: sets bit 6 (`0x40`) to mute, clears it (`band(...,0xbf)`) to unmute. PICO-8 music engine natively skips channels marked empty — same mechanism as editor channel toggle.
  - Called on splash→play with `att=0` (bass only) then `music(0,1)` starts the loop (loneliness.p8:130-131).
  - Called inside NPC attach block after `n.att=true` (loneliness.p8:170-172) with fresh `att` count.
- **Tried first (failed):**
  - `music(0,0,mask)` re-call on attach: restarts pattern from row 0 each time — jarring mid-phrase jump.
  - Per-frame `sfx(-1,ch)` on muted channels: music engine re-triggers notes faster than we can kill them → buzzes/bleeds instead of muting.
- **Tunables added:** none — `set_music_layers` takes `att` directly.

## Attach Chime
- **Date:** 2026-07-16
- **Status:** complete
- **What it is:** One-shot SFX plays when an NPC attaches to the player.
- **What it does:** `sfx(51)` fires once inside the attach block (loneliness.p8:168), alongside the feedback ring and soundtrack layer addition. Slot 51 composed by user in PICO-8 SFX editor.
- **How implemented:**
  - Added `sfx(51) -- attach chime` after `add(rings,{r=8,a=12})` in the NPC attach branch.

## Soundtrack 4-Layer / 8-Pattern
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Soundtrack expanded to 8 music patterns × 4 channels, 4th layer (shimmer) joins at att≥3.
- **What it does:** `set_music_layers(att)` loops all 8 patterns, toggles ch1 (pad @att≥1), ch2 (mel @att≥2), ch3 (shm @att≥3) via PICO-8 music channel empty flag (bit 6). Full track plays at 3 attachments. Whole-tone scale (C D E F# G# A#) across all SFX.
- **How implemented:**
  - `snd_patterns=8` tunable, loop `p=0,snd_patterns-1` poke `0x3100+p*4+ch`.
  - Inner loop `ch=1,3`: `if att>=ch then band(b,0xbf) else bor(b,0x40)`.
  - Music data 8 patterns in `__music__` section, pat 7 flag=02 (loop-back).
- **Tunables added:** `snd_patterns=8` — number of music patterns in the loop

## Infinite Ascending Corridor
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Camera ratchets upward only; world-space entities scroll; pollen has parallax. No `__map__` data — procedural, no visual walls.
- **What it does:** `cam_y` (world Y of screen top) decreases when `py-cam_y < cam_dead` (player in top zone), frozen otherwise. Down blocked at screen bottom (`py>cam_y+120`). Sides blocked at screen edges (`corridor_l=0, corridor_r=120`). Pollen + grass in world space, drawn at `y-cam_y` → scroll downward as player ascends = upward motion feeling. Light engine feeds screen coords (immune to `camera()`).
- **How implemented:**
  - Tab 1 (after `-->8`): `cam_y`, `corridor_l/r`, `cam_dead` tunables + `update_camera()`.
  - `_update`: `update_camera()` replaces old `px/py=mid(...)` clamp.
  - `_draw`: all entity Y converted to `y-cam_y` (player, NPCs, pollen, grass). Light `cx,cy=px+4,(py-cam_y)+4`.
  - Pollen wrap in world space: band ±160 around camera.
- **Tunables added:**
  - `cam_dead=32` — screen Y threshold that triggers camera ascent (lower = more tolerance)
  - `corridor_l=0` / `corridor_r=120` — player x-clamp bounds (screen edges)

## Repel NPCs
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Colored NPCs (col 8/14/11) flee player on contact instead of attracting. Never attach.
- **What it does:** On contact within `flee_range`, NPC enters `fleeing` state with normalized direction from player→NPC. Flee vector avoids upward (y-component zeroed if negative, renormalized). Moves at constant `flee_sp`. Despawns off any screen edge/bottom. Pre-placed ahead of player (y=-40/-120/-200), encountered ascending.
- **How implemented:**
  - NPC tables: `col`, `repel=true` fields added.
  - Update loop: `n.repel` branch. On `d<flee_range`: `fleeing=true`, store `fdx,fdy`. If `fdy<0: fdy=0`, renormalize. Flee at `flee_sp`.
  - Despawn: `n.x<-16 or n.x>144 or n.y>cam_y+144`.
  - Draw: glow uses `n.col` (not hardcoded col 1). `npc_fillp` tunable for all NPC glow patterns.
- **Tunables added:**
  - `flee_range=24` — contact distance to trigger flee
  - `flee_sp=1.4` — flee speed (constant)
  - `npc_fillp=░` — dither pattern for all NPC glows

## Grass Tufts
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Sprite 7 (grass) placed next to every NPC spawn point, col 2 base glow.
- **What it does:** World-space, scrolls with pollen parallax. Built from NPC spawn table at init: `grass[i]={x=n.x+12, y=n.y}`. Drawn before NPCs (ground level). Visibility-culled to screen range. Base glow: `circfill(x+4, sy+6, 5, 2)` with `npc_fillp`.
- **How implemented:**
  - `grass={}` table built in init loop over `npcs`.
  - Draw block before NPC draw: `if sy>-8 and sy<136 then` glow + `spr(7)`.

## Big NPC Thief
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** 2×2 sprite NPC (16px) that steals attached NPCs from the player. Passive thief with player-structure glow.
- **What it does:** Passive at spawn (y=-260). When an attached NPC comes within `steal_range` (measured NPC-to-Big, not player-to-Big), Big steals one every `steal_interval` frames after a `steal_grace` window on the NPC's attach time. Stolen NPCs orbit Big (same formula as player orbit, phase split among stolen count). At att=0, Big retreats radially from player (avoiding upward, same flee rule), despawns off any screen edge. No respawn. Glow = 3 concentric circles mirroring player structure (own params, no `fl_light` rect). Twitches every 8 frames like player. Animation = 1232 cycle @ 8fps using sprites {33,34,49,50}/{35,36,51,52}/{37,38,53,54}.
- **How implemented:**
  - `big={x,y,done,retreat,engaged,sc,jx,jy}` global. `big_spr`/`big_cycle` tables.
  - Update: stolen NPCs branch orbits Big. Big steal search: `big_onscreen` guard + `abs(ndx)<range and abs(ndy)<range` pre-check (fixed-point overflow fix — see below) + `fc-att_fc > steal_grace` per-NPC grace + `nd<steal_range` + `big.sc>=steal_interval` cadence. Retreat: radial flee from player, upward zeroed.
  - Draw: 3-circle glow (col 1 ░, col 12 ▒, col 12 solid) rerolled every 12f, then 2×2 `spr` block with `big.jx/jy` twitch.
  - Stolen NPCs excluded from: `norbit` count, `att` count (player glow + light + music), small NPC glow draw.
- **Tunables added:**
  - `steal_range=28` — NPC-to-Big distance to steal
  - `steal_interval=15` — frames between steals
  - `steal_grace=60` — grace period after NPC attach before stealable
  - `big_retreat_sp=0.5` — Big retreat speed
  - `bg0=28` / `bg1=20` / `bg2=12` — Big glow radii (own params, not linked to player)
- **Bug fixed:** PICO-8 16.16 fixed-point max ~32767. `dx*dx` overflows at dx>181 → `sqrt` returns garbage → distance check false-positive (Big stole from across map). Pre-check `abs(dx)<range and abs(dy)<range` before `sqrt` gates the overflow path.

## Light Engine Removed
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Per-scanline light engine (`fl_light`/`crect`/`init_blending`/`fl_blend`/`_sqrt` LUT/blend LUT) deleted entirely.
- **What it does:** Glow now = 3 colored circles only (g0/g1/g2). No lit-area rect. ~87 lines removed. `gbri`/`light_growth` tunables gone. `_init` no longer calls `init_blending`.
- **How implemented:**
  - Deleted functions: `crect`, `fl_color`, `fl_none`, `init_blending`, `fl_blend`, `fl_light`. Deleted tables: `light_rng`, `light_fills`, `brkpts`, `_sqrt`.
  - `_draw`: removed `gbri` reroll, `lrng=flr(42*gbri)`, `crect(...)` call.
  - `_init`: removed `init_blending(6)`.

## Player Glow Tunable Base
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Glow circle base radii exposed as `g0b/g1b/g2b` tunables.
- **What it does:** Reroll references `g0b+att*glow_growth` instead of hardcoded 22/16/8 (which ignored the `g0/g1/g2` init values and overwrote them every 12 frames). Start small, `+glow_growth` per attach, shrink on steal via `att` recount (excludes `n.stolen`).
- **How implemented:**
  - Tab 0: `g0b=30 g1b=20 g2b=10` + runtime `g0=30 g1=20 g2=10`.
  - `_draw` reroll: `g0=g0b+att*glow_growth+rnd(3)-1.5` (same for g1/g2).
- **Tunables added:**
  - `g0b=30` / `g1b=20` / `g2b=10` — base radii for outer/mid/inner glow circles (change these, not `g0/g1/g2`)
  - `glow_growth=4` — radius added per attached NPC

## Flee Diagonal + Grass Draw Order
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Fleeing NPCs and Big retreat allow diagonal-up but block straight-up. Grass split into 2 draw passes.
- **What it does:** Flee vector: if `fy<0 and abs(fx)<0.001` (straight up), push `fx=1`. Diagonal up (fx≠0, fy<0) passes unchanged. Grass: shadow (col 2 circfill) drawn before player glow (under), sprite (spr 7) drawn after feedback rings (on top).
- **How implemented:**
  - Repel NPC flee trigger + Big retreat: `if fy<0 and abs(fx)<0.001 then fx=1 end` then renormalize.
  - `_draw`: grass loop split — shadow pass before `g0/g1/g2` circles, sprite pass after `rings` loop.

## Player Glow Color System
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Player has a color group (`pcol`); NPCs attract if same color, flee if different. Changing color detaches mismatched attached NPCs.
- **What it does:** `pcol=12` (white) default. NPC `n.col==pcol` → attract/attach branch. `n.col!=pcol` → flee branch (radial, straight-up avoided, despawn). `set_player_color(c)`: matching NPCs reset `fleeing=false`; mismatched attached NPCs detach, enter flee, play `sfx(52)`; recounts `att`, updates music. Player glow circles use `pcol` (was hardcoded cols 5/6).
- **How implemented:**
  - `pcol=12` + `set_player_color(c)` function (tab 0, after `set_music_layers`).
  - Update loop: `if n.col != pcol then` (flee) `else` (attract) — replaces `n.repel` check. `norbit` count only matching-color.
  - `_draw` glow: `circfill(cx,cy,g0,pcol)` etc.
  - NPC tables: `repel` field obsolete (color drives behavior), `col` drives both glow + attraction.
- **Tunables added:** `pcol=12` — player's current color group

## Flower (Color Change Mechanic)
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Sprite 9 flower (world-space) changes player's glow color on hold X for 3 sec. Single-use (sprite 9→10 after).
- **What it does:** Player within `flower_absorb_r` of unused flower + holds X → player frozen, charge counter rises (90 frames = 3 sec). Particles emit from flower center at random angles, ease-out then accelerate toward player (magical homing). Idle orbit particles vanish during charge. Player-accumulating particles spiral in (20→5px) as charge completes. "hold x" prompt shows under player when in range + not charging. On completion: `set_player_color(f.col)`, color burst ring at player (expands 36 frames, pushes pollen aggressively), flower `used=true` → sprite 10, inert.
- **How implemented:**
  - `flowers={}` table: 4 flowers at world positions, `{x,y,col,used}`.
  - Update: flower charge loop before movement (freezes player via `flower_charging` gate). Fixed-point overflow guard: `abs(fdx)<r and abs(fdy)<r` before `sqrt`.
  - Draw: flower shadow (col 2, `npc_fillp`, under glow) + sprite (9 or 10) + idle orbit particles (when not charging) + charge particles (emit→home, 30 count, 4 speed tiers) + player-accumulating particles + charge ring + "hold x" prompt.
  - Pollen burst: ring `r.burst=true` flag, pushes pollen with `flower_burst_s=8` strength. Pollen flagged `p.burst=true`, despawns off-screen instead of wrapping.
- **Tunables added:**
  - `flower_charge=90` — frames to hold X (3 sec @ 30fps)
  - `flower_absorb_r=50` — interaction range
  - `flower_burst_s=8` — pollen push strength on color change
  - `flower_particles=8` — idle orbit particle count
  - `flower_orbit_r=10` — idle orbit radius

## Pollen Respawn After Burst
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Pollen despawned by color burst respawns slowly, one at a time, maintaining total count.
- **What it does:** Burst-despawned pollen tracked in `pollen_deficit`. Every `pollen_respawn_cd` frames, one new pollen spawns at random screen position (world space). Staggered refill, not instant.
- **How implemented:**
  - `pollen_deficit` counter incremented on burst despawn.
  - Respawn block after pollen loop: `if pollen_deficit>0 then pollen_cd+=1; if pollen_cd>=pollen_respawn_cd then add(pollen,...); pollen_deficit-=1 end`.
- **Tunables added:** `pollen_respawn_cd=8` — frames between each pollen respawn

## Big NPC Cast Ring + Refined Steal
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Big NPC casts expanding ring before stealing; steals 1 NPC at a time; retreats horizontally biased after 0.5s delay.
- **What it does:** Player enters `steal_range` (56, doubled) → Big spawns expanding ring at own position (36 frames, vg=4.5). Ring pushes pollen outward during expansion. After ring completes: steals 1 attached NPC every `steal_interval` frames (past `steal_grace`). When all stolen: 15-frame pause, then retreat with locked direction (horizontal-biased: `fy*=0.2`, straight-up avoided). Player position ignored after retreat starts.
- **How implemented:**
  - `big.cast`/`big.cast_t`/`big.post_steal`/`big.fdx`/`big.fdy` fields.
  - Ring: `add(rings,{r=8,a=36,vg=4.5,x=big.x+8,y=...})` — per-ring position + `vg` (expansion speed). Rings support `r.x/r.y` (fallback player center) + `r.col`.
  - Pollen push during cast: `br=36-cast_t`, reach `br+16`, strength 6.
  - Steal loop: 1 at a time with `break` after each. `post_steal=15` delay before retreat.
  - Retreat direction locked at `post_steal` end, `fy*=0.2` for horizontal bias.
- **Tunables added/changed:**
  - `steal_range=56` (doubled from 28)
  - `big_retreat_sp=0.3` (slowed from 0.5)

## Detach Chime
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** SFX plays when an NPC is stolen/detached from player.
- **What it does:** `sfx(52)` fires when Big steals an NPC and when `set_player_color` detaches mismatched NPCs.
- **How implemented:**
  - Added `sfx(52) --detach chime` in Big steal block + `set_player_color` detach loop.

## Fixed-Point Overflow Fix (Flower)
- **Date:** 2026-07-17
- **Status:** complete
- **What it is:** Same overflow bug as Big NPC, fixed in flower distance checks.
- **What it does:** Flower at y=-160, player at y=84 → `ddy=244`, `244*244=59536` overflows PICO-8 16.16 fixed-point → `sqrt` returns 0 → distance check false-positive (prompt showed at spawn, charge triggered from across map).
- **How implemented:**
  - Flower charge loop + prompt loop: `abs(fdx)<r and abs(fdy)<r` pre-check before `sqrt`. Same pattern as Big NPC fix.

## Color-Driven Attract/Flee + Start White
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** Static `repel` flag removed; attract/flee now derived dynamically from `n.col == pcol`. Player starts white.
- **What it does:** `pcol=6` (white) default. Matching-color NPCs enter the attract/orbit branch; non-matching flee on contact within `flee_range` (proximity, no cast needed). `norbit` count keys off `m.col==pcol` instead of `not m.repel`. `set_player_color` already handled detach+flee of mismatched attached NPCs — unchanged, now fully correct under the dynamic rule.
- **How implemented:**
  - Removed `repel` field from all 5 NPC defs. Col 11 NPC → col 6 so the white pair is live at spawn.
  - Update loop: `n.col!=pcol` flee branch (was `n.repel`); `norbit` uses `m.col==pcol` (was `not m.repel`).
  - Col 11 flower → col 6 to match the converted NPC.
- **Tunables changed:** `pcol=6` (was 12) — start white; matching-color NPCs attract, others flee

## Two-Color Player Glow
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** Player glow renders two colors — outer ring uses a secondary color per primary, mid/inner use the primary.
- **What it does:** `glow_cols` lookup maps primary→outer: blue 12→1, red 8→2, white 6→13, pink 14→2. `pcol2` holds the current outer color; updated in `set_player_color`. Draw: `g0` (outer) uses `pcol2`, `g1`/`g2` use `pcol`.
- **How implemented:**
  - `glow_cols={[12]=1,[8]=2,[6]=13,[14]=2}` table + `pcol2=glow_cols[pcol] or pcol` at top.
  - `set_player_color`: `pcol2=glow_cols[c] or c` after `pcol=c`.
  - `_draw` glow: `fillp(░) circfill(cx,cy,g0,pcol2)` then `g1`/`g2` in `pcol`.
- **Tunables added:** `glow_cols` table, `pcol2` — outer glow color paired with `pcol`

## Call Wave Mechanic
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** Press O to cast a radial wave from the player; matching-color NPCs attach, non-matching flee. Replaces proximity-based attach. Attached NPCs detach when too far.
- **What it does:** `btnp(4)` starts an expanding ring (`call.r` grows by `call_speed`/frame) centered on the player. Each NPC is hit once per cast (`call.hit[n]` set); on hit: matching color → `n.att=true` (attach chime, feedback ring, music layer up), non-matching → flee (vector set, flee chime). Wave ends at `call_max_r`, cooldown `call_cd`. Proximity attach removed — only attached NPCs orbit (`if n.att then`). Attached NPCs detach when distance exceeds `att_lose_range` (music layer recount). Orbit lerp clamped by `att_max` so `att_sp` tuning actually bites (old hardcoded `2` clamp saturated the new low `att_sp=0.08`).
- **How implemented:**
  - `call={active=false,r=0,hit={},cd=0}` global. `btnp(4)` starts wave if not active and `cd<=0`.
  - Wave loop: grow `call.r`, per-NPC `d<=call.r` + `not call.hit[n]` gate → attach matching or flee non-matching, set `call.hit[n]=true`.
  - Orbit branch: `if n.att then` (was `if d<40 or n.att then`); removed auto-attach block (`if not n.att and d<20`).
  - Detach: `if d>att_lose_range then n.att=false; recount att; set_music_layers(att) end` inside orbit branch.
  - Lerp clamp: `if mvl>att_max then mvx*=att_max/mvl mvy*=att_max/mvl end` (was hardcoded `2`).
  - Draw: two `circ` outlines in `pcol` at `call.r` and `call.r-1`, after feedback rings.
- **Tunables added:**
  - `call_speed=2` — wave expansion px/frame
  - `call_max_r=50` — wave max radius
  - `call_cd=30` — cooldown frames between casts
  - `att_max=1.5` — max px/frame an attached NPC moves toward orbit slot
  - `att_lose_range=90` — detach distance (must stay > `call_max_r`)
- **Tunable changed:** `att_sp` 0.2 → 0.08 — attached NPC lerp speed (slower approach)
- **Bug fixed:** permanent `n.att` made wave-hit NPCs chase across the map via orbit lerp. Distance-based detach (`att_lose_range`) + clamp tuning (`att_max`) resolved both the infinite-follow and the lunge-speed complaints.
## Splash Input Lock
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** Splash screen can no longer be skipped with buttons; advances only by timer.
- **What it does:** `_update` splash branch triggers `state="intro"` only on `fc>=60` (2s). All `btnp()` checks removed. `_draw` splash branch unchanged.
- **How implemented:**
  - Update splash branch: `if fc>=60 then state="intro" intro_t=0 end` (was `fc>=60 or btnp(4) or ...`).

## Intro Typewriter Screen
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** Black screen with centered text typed letter-by-letter, then held, then color-step faded out. Sits between splash and play.
- **What it does:** After splash, `state="intro"` runs three phases: (1) typewriter reveal at `intro_letter_f` frames/letter, (2) hold for `intro_hold_f` frames at full color, (3) fade over `intro_fade_f` frames stepping color 7→6→5→1→0. Music starts on intro→play transition (splash+intro silent except splash sting). Text centered: `print(txt, 64-#txt*2, 62, col)`.
- **How implemented:**
  - `state="intro"` third state. `intro_t` counter incremented in `_update`.
  - Update: `intro_t+=1`; `full=#intro_text*intro_letter_f`; `fade_end=full+intro_hold_f+intro_fade_f`; on `intro_t>=fade_end` → `state="play" fade_t=0`, `set_music_layers(0)`, `music(0,1)`.
  - Draw: `cls(0)`, `sub(intro_text,1,shown)` for reveal, color-step fade on `intro_t` progress (no fillp — readable on black). Early `return` keeps play draw untouched.
- **Tunables added:**
  - `intro_text="test text"` — the message (edit directly in editor)
  - `intro_letter_f=8` — frames per letter reveal
  - `intro_hold_f=60` — hold frames after full text (2s)
  - `intro_fade_f=30` — fade-out duration
  - `intro_t=0` — runtime counter

## Scene Fade-In (Dither Dissolve)
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** When play starts, a dithered black overlay thins out to reveal the scene.
- **What it does:** Over `fade_in_f` frames, a full-screen `rectfill(0,0,127,127,0)` overlay uses fillp patterns that get sparser: solid (`0xff`) → `▓` (`0xee`) → `▒` (`0xaa`) → `░` (`0x55`) → clear. Drawn last in `_draw` (after pollen) so it covers everything. `fade_t` increments in `_update` (gated `state=="play"`), resets to 0 on intro→play. `fillp(0)` reset after overlay so later frames aren't corrupted.
- **How implemented:**
  - `fade_t`/`fade_in_f` tunables. `fade_t=0` reset on intro→play transition.
  - `_update`: `if state=="play" and fade_t<fade_in_f then fade_t+=1 end` (state change in update, not draw — PICO-8 convention).
  - `_draw`: `if fade_t<fade_in_f then local p=fade_t/fade_in_f; pick pat by quartile; fillp(pat); rectfill(...); fillp(0) end` after pollen loop.
- **Tunables added:**
  - `fade_in_f=60` — total fade-in duration (2s @ 30fps)
  - `fade_t=0` — runtime counter
## Visual Level Editor (HTML)
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** Self-contained HTML tool (`level_editor.html`) for placing plants/flowers/big-NPC visually and exporting the exact Lua tables for tab 1.
- **What it does:** Canvas shows world space (y=0..128 = initial screen, dashed; y goes up = negative) with 16px grid + player spawn marker (64,84). Tools: Plant (with NPC count 1-8), Flower, Big NPC, Select. Click to place, click to select, drag to move, Del/Backspace or floating ✕ button to delete. Color picker updates the selected entity live (or sets next-placement color if nothing selected). Plants expand to N NPCs clustered in a circle (radius 6) on export. Grass auto-derives (NPC x+12). Export writes Lua to a textarea + downloads `level_setup.txt`; Copy Code button for direct paste. Load button re-imports a `.txt` (lossless via embedded `-- editor:plants=JSON` metadata; falls back to regex-parsing NPC entries). Seeded with cart's current layout.
- **How implemented:**
  - Single file, vanilla JS, no deps. PICO-8 palette hardcoded for entity colors.
  - `plants[]` with `{x,y,col,count}`; `expandPlants()` builds NPC list on export (count=1 → single NPC; count>1 → circle cluster).
  - Export format matches cart exactly: `npcs={...}`, `big={...}`, `grass={}` + `for i,n in ipairs(npcs) do` loop, `flowers={...}`.
  - Floating delete button: red ✕ circle drawn at `(entity_canvas_x + 8*SCALE, entity_canvas_y - 8*SCALE)` when something selected; `deleteBtnHit()` checks click radius.
  - Color button dual-mode: updates `selected.col` if a plant/flower is selected, else sets `curCol` for next placement.
  - Count input dual-mode: updates `selected.count` if a plant is selected, else sets `curCount`.

## Entity Tables Moved to Tab 1
- **Date:** 2026-07-18
- **Status:** complete
- **What it is:** `npcs`/`big`/`grass`/`flowers` block relocated from tab 0 to tab 1 so all level positioning lives with the camera/level code.
- **What it does:** Tab 1 now holds the full level layout: `cam_y`/`corridor_*`/`update_camera()` + entity tables. Tab 0 keeps runtime state (`rings`, `call`, `pollen`) and systems. Editor export pastes cleanly into tab 1 with no duplicate globals.
- **How implemented:**
  - Deleted entity block from tab 0 (was lines 93-114).
  - Inserted after `update_camera()` in tab 1, before `__gfx__`.
  - `rings`/`call` stayed in tab 0 (runtime state, not level layout).
  - Added `-- npcs (place via level_editor.html)` comment as the paste target marker.
---

## Lessons Learned (PICO-8 pitfalls)

Reference section — not features, but hard-won knowledge for future work.

### Fixed-Point Overflow in Distance Checks
- PICO-8 numbers = 16.16 fixed-point. Max ~32767.
- `dx*dx` overflows when |dx|>181 → wraps to garbage → `sqrt` returns 0 (not error).
- **Symptom:** distance check false-positive — steals/charges from across map, prompt shows at spawn, NPC teleports to Big.
- **Fix:** pre-check `abs(dx)<range and abs(dy)<range` before `sqrt`. Skips overflow path entirely.
- **Applies to:** Big NPC steal search, flower charge loop, flower prompt. Any world-space distance where entities >181px apart on any axis.
- **Safe:** screen-space distances (max ~128px) — pollen repulsion, NPC orbit. No overflow possible.

### PICO-8 `^` is NOT power
- `(px-f.x)^2` ≠ squared. Returns wrong value.
- Use `dx*dx` for squaring. Never `^` for math.

### Stale Cart During Iteration
- PICO-8 `Ctrl+R` reruns the *loaded* cart — does NOT reload file from disk.
- Must `LOAD LONELINESS.P8` → `RUN` to pick up external edits.
- **Symptom:** fixes "don't work" despite correct code in file. Always reload after external edits.

### Duplicate Code Blocks After Refactor
- When moving logic (e.g. flower charge from end of update to before movement), old block may remain.
- **Symptom:** conflicting state writes — charge resets, `f.used` never sticks, behavior contradicts edits.
- **Fix:** grep for duplicate patterns after restructure. One source of truth per behavior.

### Ratchet Camera + World-Space Entities
- `cam_y` decreases only (ratchet). Player screen Y = `py - cam_y`.
- Light engine writes screen RAM directly — immune to `camera()`. Feed screen coords.
- Pollen/grass/NPCs in world space, draw at `y - cam_y` for parallax.
- Pollen wrap in world space: band ±160 around camera.

### Music Layer Toggling
- `music()` restarts pattern from row 0 — jarring mid-phrase. Never re-call to add layers.
- Instead poke `0x3100+pattern*4+channel` bit 6: `bor(b,0x40)` = mute, `band(b,0xbf)` = unmute.
- PICO-8 engine natively skips "empty" channels — seamless layer add/remove at pattern boundary.
- `set_music_layers(att)` loops all patterns, toggles ch1/ch2/ch3 by `att>=ch`.

### SFX Slot Discipline
- 50 = splash sting, 51 = attach chime, 52 = detach chime.
- Compose in PICO-8 SFX editor, reference by slot number in code.
- Whole-tone scale (C D E F# G# A#) across all SFX — keep new SFX in-collection: `p%12 ∈ {0,2,4,6,8,10}`.

### NPC Orbit Phase Split
- `a = fc*angular_vel + (i-1)/#npcs` splits N NPCs evenly around circle.
- 1 alone, 2 opposite, 3 triangle. Use `norbit` (count of eligible NPCs) not `#npcs` — excludes stolen/fled.
- Attached NPCs use `att_sp` (tight follow); approaching use 0.05 (slow ease in).

### Debug Workflow in PICO-8
- `printh(str)` logs to host console — but requires running PICO-8 from terminal to see output.
- On-screen debug: `print("var="..tostr(x),0,y,7)`. Reliable, no console needed.
- `^` broke distance debug (`(px-f.x)^2` → 0). Use `*` in debug too.

### Ponytail Notes in Code
- Mark deliberate simplifications/known ceilings with `-- ponytail: [what] [ceiling] [upgrade path]`.
- Future-self breadcrumbs. Don't over-comment normal code.

## Grass = One Per Plant (Not Per NPC)
- **Date:** 2026-07-23
- **Status:** complete
- **What it is:** Grass tufts now spawn once per level-editor plant, not once per expanded NPC.
- **What it does:** Fixes "plant count:2 → two grass tufts with one NPC each." Multi-NPC plants now show a single grass tuft at the plant center with their NPC cluster.
- **How implemented:** Replaced `for i,n in ipairs(npcs) do grass[i]={x=n.x+12,y=n.y} end` with explicit per-plant entries (loneliness.p8:603-608). Editor already fixed in commit `38d5e70` (`grass[i]={x=p.x+12,y=p.y}` indexed by plant, not NPC).
