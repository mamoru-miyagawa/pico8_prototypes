---
name: pico-8
description: PICO-8 Lua cart conventions and builtin idioms. Use when editing any .p8 file or working on PICO-8 cartridges. Covers __lua__/__gfx__ sections, tabs via -->8, _init/_update/_draw lifecycle, PICO-8 builtins, single-cart no-dependency philosophy, terse output style.
paths: "**/*.p8"
---

# PICO-8 cart conventions

## Cart file format

A `.p8` cartridge is a single text file with sections marked by headers:

```
pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
<lua code here>
__gfx__
<hex-encoded sprite data, one row per line, 128 chars wide>
__label__
<cart label image data>
__sfx__
<sound effect data>
__map__
<map data>
```

Tabs inside the Lua editor are separated by a line containing exactly `-->8`. Code after the last `-->8` but before the next section header (`__gfx__`, etc.) belongs to that tab. To write a comment into a specific tab from an external editor, place it after the `-->8` of that tab.

## Lifecycle

PICO-8 calls three callbacks if defined:

- `_init()` — once on startup. Use for one-time setup (build LUTs, init tables).
- `_update()` — every frame, 30fps by default or 60fps if `_update60()` is defined instead. Game logic goes here.
- `_draw()` — every frame, after `_update`. Rendering only. Start with `cls(color)`.

State can also live in global variables initialized at the top of the file (runs once at load, before `_init`).

## PICO-8 builtins

PICO-8 ships a fixed set of Lua builtins. There are no external libraries, no `require`, no `package`. Use only what's built in.

Common ones for gameplay/rendering:

- Movement/input: `btn(id)` (0=left,1=right,2=up,3=down,4-7=O/X), `btnp`
- Math: `cos sin atan2 sqrt abs sgn flr ceil mid max min rnd` — note `cos/sin` take turns (1.0 = full circle), not radians
- Bit ops: `band bor bxor bnot shl shr lshr rotl rotr`
- Drawing: `pset line rect rectfill circ circfill spr sspr pal palt fillp clip color`
- Memory: `peek poke memset memcpy sget sset cget cset`
- Text: `print`
- Audio: `sfx music`
- Map: `mget mset map`
- Time: `t()` seconds since boot, `fc`/`frame` counters are user-defined
- Helpers: `all` (safe iterator over table, skips holes), `del` (remove by value), `add` (append), `ipairs` (indexed iteration), `pairs` (key/value), `type`, `tonum`, `tostr`, `chr`, `ord`, `split`

`cos/sin` in PICO-8 use **turns** (1.0 = 360°), not radians. `cos(0.25)` = 0, `cos(0.5)` = -1.

`fillp(pattern)` sets a dither pattern for subsequent `circfill`/`rectfill` calls. `fillp(0)` resets to solid. Patterns: `░ ▒ ▓ ▚ ▞ █` etc. as literal glyphs in the source.

## Single-cart philosophy

PICO-8 carts are self-contained. No dependencies, no imports, no package manager. The entire game lives in one `.p8` file: code, sprites, sound, map. Keep it that way. Don't add build steps, preprocessors, or external tooling unless the user explicitly asks.

## Coding style

- Add a brief comment marking each new feature (e.g. `-- splash screen`), so the user can locate features in the file. Do not narrate every line — one short comment at the feature's entry point is enough.
- Shortest working diff wins. Boring over clever.
- Expose tunable values as named variables at the top of the file (or near where the system is initialized). Never inline magic numbers deep in logic — pull them up so they're easy to find and tweak.
- Reuse existing patterns in the file before introducing new abstractions. If a helper already exists a few lines up, use it.
- PICO-8 Lua is real Lua with a few extensions (`+=`, `!=`, shorthand `if`, etc.). Prefer the shorthand forms the cart already uses.
- Entity tables: plain Lua tables, often `{x=,y=,vx=,vy=,flag=false}`. Iterate pools with `for e in all(pool) do`, indexed tables with `for i,e in ipairs(t) do`.

## Verification

PICO-8 carts have no automated test framework. The only verification is running the cart in the PICO-8 app. Don't claim a change works without the user running it. If a change is non-trivial logic, suggest the user test specific scenarios (move toward NPC, let NPC attach, move away, observe orbit, etc.).

## Output style

Be terse. Code first, explanation after — and only if the explanation is shorter than the code it defends. No essays, no feature tours. When you add a tunable, name it clearly at the top so the user can find and adjust it.
