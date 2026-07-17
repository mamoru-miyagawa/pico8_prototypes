---
name: loneliness
description: Conventions for the "loneliness" PICO-8 cart. Use when editing loneliness.p8. Covers tunable vars at top of file, NPC entity tables (jx/jy/att), twitch pattern via fc%8, orbit phase split via (i-1)/#npcs, attached state, feedback rings, pollen repulsion, draw order, glow growth per attached NPC.
paths: "**/loneliness.p8"
---

# loneliness cart conventions

## File layout

`loneliness.p8` is a single PICO-8 cart. Code is in the `__lua__` section. Top of file holds **global state and tunables** — this is the control panel. Keep tunables grouped there; do not bury magic numbers inside `_update`/`_draw`.

## Tunables (top of file)

Named variables the user can tweak. Current set:

```lua
px=64 py=64          -- player position
spd=1                -- player move speed (px/frame)
fc=0                 -- frame counter (incremented in _update)
jx=0 jy=0            -- player twitch offset
g0=22 g1=16 g2=8     -- glow radii (outer/mid/inner)
glow_growth=3        -- glow radius added per attached NPC
att_sp=0.2           -- attached NPC lerp speed toward orbit slot
pollen_rep_r=30      -- pollen repulsion radius from player
pollen_rep_s=0.5     -- pollen repulsion push strength (constant)
pollen_n=20          -- pollen particle count
```

When adding a new tunable: declare it at the top near related ones, give it a sensible default, and use it in the logic. Never inline a number that the user might want to adjust.

## NPC entity table

```lua
npcs={
 {x=30,y=40,jx=0,jy=0,att=false},
 {x=90,y=80,jx=0,jy=0,att=false},
 ...
}
```

- `x,y` — world position (top-left of 8x8 sprite; center is `x+4, y+4`)
- `jx,jy` — twitch offset, rerolled every 8 frames
- `att` — attached flag, false until player proximity, then true forever

To add NPCs: append entries to this table. Orbit logic auto-splits by `#npcs`, no other changes needed.

## Twitch pattern (player + NPCs)

Every 8 frames, reroll `jx/jy` to a random value in `{-1, 0, 1}`:

```lua
if fc%8==0 then
 jx=flr(rnd(3))-1
 jy=flr(rnd(3))-1
end
spr(s, px+jx, py+jy)
```

NPCs use the same pattern with their own `n.jx/n.jy` so they desync naturally. Each NPC rerolls independently — do not share state.

## Orbit behavior

When a NPC is within attract range OR is already attached, it eases toward a rotating slot on a ring around the player:

```lua
for i,n in ipairs(npcs) do
 local dx,dy=px-n.x,py-n.y
 local d=sqrt(dx*dx+dy*dy)
 if d<attract_range or n.att then
  local a=fc*angular_vel+(i-1)/#npcs
  local tx,ty=px+cos(a)*orbit_radius,py+sin(a)*orbit_radius
  local sp=n.att and att_sp or approach_sp
  n.x+=(tx-n.x)*sp
  n.y+=(ty-n.y)*sp
 end
end
```

- Phase split: `(i-1)/#npcs` distributes N NPCs evenly around the circle. 1 NPC alone, 2 opposite, 3 triangle, etc.
- `fc*angular_vel` rotates the whole formation. Tune `angular_vel` for orbit speed.
- `att_sp` (attached) is faster than `approach_sp` (not yet attached) so attached NPCs follow the player more tightly.
- **cos/sin use turns in PICO-8** — `cos(0.25)` = 0, full circle = 1.0.

## Attached state

`n.att` flips to `true` the first time the NPC gets close to the player (e.g. `d<20`). It is **never reset**. Once attached:

- NPC stays in orbit regardless of distance (`d<attract_range or n.att` gate).
- NPC loses its circle glow (skip the `fillp(░) circfill(...)` draw).
- Player glow grows by `glow_growth` per attached NPC (count attached, multiply).

On attach, spawn a feedback ring:

```lua
if not n.att and d<attach_range then
 n.att=true
 add(rings,{r=8,a=12})
end
```

## Feedback rings

```lua
rings={}
-- spawn: add(rings,{r=start_radius, a=lifetime_frames})

-- in _update:
for r in all(rings) do
 r.r+=1.5          -- growth per frame (knob 1)
 r.a-=1
 if r.a<=0 then del(rings,r) end
end

-- in _draw (after glow, before NPCs):
for r in all(rings) do
 local col=10
 if r.a<6 then col=10 end
 if r.a<3 then col=9 end
 circ(cx,cy,r.r,col)
end
```

Max ring size = `start_radius + growth_per_frame * lifetime` = `8 + 1.5*12` = 26px. To adjust max size, change growth speed (`r.r+=X`), lifetime (`a=N` at spawn), or start radius. Color steps down as `a` decreases for a fade effect.

## Pollen

Particle system for ambient motion. Defined at top:

```lua
pollen={}
for i=1,pollen_n do
 pollen[i]={x=rnd(128),y=rnd(128),vx=(rnd()-0.5)*0.15,vy=(rnd()-0.5)*0.15,p=rnd(1)+0.5}
end
```

Update in `_update`:
- Repulsion from player (linear falloff inside `pollen_rep_r`, player-only, constant strength `pollen_rep_s`):

```lua
local dx,dy=p.x-px,p.y-py
local d=sqrt(dx*dx+dy*dy)
if d<pollen_rep_r and d>0.001 then
 local f=(pollen_rep_r-d)/pollen_rep_r*pollen_rep_s
 p.x+=dx/d*f
 p.y+=dy/d*f
end
p.x+=p.vx
p.y+=p.vy
-- wraparound
if p.x<0 then p.x+=128 end
if p.x>128 then p.x-=128 end
if p.y<0 then p.y+=128 end
if p.y>128 then p.y-=128 end
```

Draw last (on top of everything):

```lua
for p in all(pollen) do
 circfill(p.x,p.y,p.p,15)
end
```

## Draw order (in `_draw`)

1. `cls(0)`
2. Player glow (3 layered `circfill` with `fillp` dithering) + light via `crect` + `fl_light`
3. Feedback rings (`circ`, no fill)
4. NPCs (conditional glow only if `not n.att`, then sprite with twitch)
5. Player sprite (with twitch)
6. Pollen (on top of everything)

`fillp(0)` must be reset to solid after any dithered fill so later draws aren't affected.

## Glow growth

Player glow radii scale by attached count:

```lua
local att=0
for n in all(npcs) do if n.att then att+=1 end end
g0=22+att*glow_growth+rnd(3)-1.5
g1=16+att*glow_growth+rnd(3)-1.5
g2=8+att*glow_growth+rnd(2)-1
```

The `rnd(...)-x` term adds flicker, rerolled every `fc%12` frames. Keep the flicker — it's part of the aesthetic. Only `glow_growth` is the tunable for per-NPC growth.

## Light engine

The `crect` / `fl_light` / `fl_blend` / `init_blending` block is a custom lighting engine that pokes the screen memory directly for performance. Treat it as a black box unless the user asks to modify lighting. Call site in `_draw`:

```lua
local bri=1.2
local lrng=flr(42*bri)
crect(cx-lrng,cy-lrng,cx+lrng,cy+lrng, fl_light(cx,cy,bri))
```

`bri` controls light brightness/range. `cx,cy` is the player center (`px+4, py+4`). Don't feed jittered (`+jx`) positions into the light — it uses the clean player position.

## Making changes

- Add a tunable → declare at top, use in logic, tell the user where it lives.
- Add an NPC → append to `npcs` table with full field set.
- Add a behavior → check if it should be gated on `att` state. Attached NPCs have different rules than free NPCs.
- Keep diffs short. Reuse existing patterns. Add a brief comment at each new feature's entry point so the user can locate it (e.g. `-- splash screen`). Do not narrate every line.
- After edits, remind the user to run the cart in PICO-8 to verify — there's no automated test path.
