# Handover — loneliness.p8 + level_editor.html

Session date: 2026-08-01. All changes committed to working tree, NOT to git.
Files touched: `loneliness.p8`, `level_editor.html`.

## TL;DR

Eight bugs found, all fixed, plus one level-data change. Cart should run
end-to-end now if PICO-8 is reloaded
(`LOAD LONELINESS.P8` then `RUN` — Ctrl+R runs the *loaded* cart, not the file
on disk; see "Stale Cart" lesson in the devlog). Fixes 7-8 verified by a
headless Lua sim (Lua 5.4.8) replaying both post-edit data and a col=12
mutant: 11/11 assertions pass.

---

## Bugs found & fixed

### 1. `spawn_next_chunk` was missing (PICO-8 nil error at line 228)
The function was referenced 3× (flower absorb, NPC wave hit, Big despawn) but
never defined. The editor's export overwrites the tail of `loneliness.p8` from
`-- editor:plants=` downward — the function had originally been added *after*
the export block, so the next export wiped it.

**Fix:** `loneliness.p8:639-651` — moved the function *above* the export block
(line 639, just after `update_camera`) and added a one-line comment explaining
why it lives there. Re-exports no longer clobber it.

Also added `n.jx=n.jx or 0 n.jy=n.jy or 0` defaults inside the npc loop, because
the editor's chunk export omits these fields. The initial-block npcs have them
hardcoded; chunk npcs don't.

### 2. Big NPC: nil arithmetic on frame 1
The retreat movement was inside an `else` tied to `if big.post_steal` (line 347
of the original). On the very first frame, `big.post_steal` is nil, so the
`else` branch ran with `big.fdx/big.fdy` nil → runtime error halts `_update`
mid-frame → `update_camera` never runs → camera can't ratchet → event NPC at
y=-282 stays off-screen forever.

**Fix:** Restructured the block. The retreat movement is now the proper `else`
of `if not big.retreat` (line 312 of the original, now line 312 in the new
layout). Movement only runs when `big.retreat == true` and `big.fdx/fdy` are
guaranteed set. Static idle and cast states are unaffected.

Also added back a missing `end` I'd dropped in the restructure (closes
`if not big.done`). Indentation in this block is messy — a leftover from the
prior restructure; PICO-8 parses it fine. Tidy when this block gets rewritten.

### 3. Event NPC fleeing on proximity (player can't engage)
The non-matching color flee gate was `if n.col!=pcol then ... d<flee_range
trigger flee`. The event NPC at y=-282 is col=12 (blue) vs pcol=13 (white), so
as soon as the player approached (the camera lock puts them within 24px of the
NPC), the NPC fled upward at `flee_sp=1.4` and despawned off the top of the
world. Grass stays put (no flee rule), which is why the user saw "vegetation
but no NPC."

**Fix:** `loneliness.p8:271` — added `and not n.event` to the flee gate. Event
NPCs now stay put until the call wave actually hits them (which sets
`n.event_done=true` and triggers `spawn_next_chunk`). Non-event NPCs still
flee on contact as before.

### 4. Level editor: hardcoded Big default in export
`generateLua` always emitted `big={x=64,y=-260,...,event=true}` when no Big was
placed. So clearing the level and re-exporting still produced a hardcoded
event Big, even though the user didn't place one.

**Fix:** `level_editor.html:1047` — else branch now emits `big={done=true}`
(the sentinel the cart already uses for "no Big"). Existing `not big.done` /
`big.event` / `big.cast` checks treat the sentinel as gone, so zero
nil-guards needed.

### 5. Level editor: JSON array brackets in chunk export
`JSON.stringify` on chunk entries produces `npcs=[{...},{...}]` with literal
`[]` brackets. PICO-8 Lua uses `{...}` for both arrays and objects — `[]` is a
syntax error.

**Fix:** `level_editor.html:1069` — added `s.replace(/\[/g, '{').replace(/\]/g,
'}')` after the existing object-key post-process. Round-trips with `parseLua`
(which already uses `\{...\}` regex).

### 6. Level editor: player marker off-screen by default
`SEC0_TOP=-350, SEC0_BOT=130` → canvas is 1440px tall (scale=3). The player
marker at world y=84 maps to canvas y=1302, below the 800-900px viewport. The
`#canvas-container` has `overflow: auto` but didn't auto-scroll, so on first
load the user saw the upper portion of the section with the marker hidden.

**Fix:** `level_editor.html:390-394` — added `scrollToPlayer()` called from
`setSection(0)`. Scrolls so the player marker is at ~30% from the top of the
visible viewport.

### 7. Event NPC froze after wave hit (no visible reaction)
On wave hit, a non-matching event NPC got `n.fleeing=true` + `n.fdx/fdy` (and
`sfx(52)`) from the wave block — but the movement gate `not n.event`
(loneliness.p8:271) excluded event NPCs from the movement code *forever*, so
it froze in place: no visible reaction, never despawned. Additionally, the
wave hook `if n.event then n.event_done=true spawn_next_chunk() end` had no
`event_done` guard, so every later wave re-hitting the same event NPC re-fired
`spawn_next_chunk()`, advancing `next_chunk` and skipping gates.

**Fix:** loneliness.p8:231 — hook now
`if n.event and not n.event_done then n.event_done=true spawn_next_chunk() end`;
loneliness.p8:271 — gate now
`if n.col!=pcol and (not n.event or n.event_done) then` (resolved events flee
normally). Verified by sim scenario 2 (mutant col=12): on wave hit the NPC
flees, moves every frame, and despawns via a side edge 95 frames later; a
second wave does not re-fire the spawn.

### 8. Level data: no matching-color NPCs for the starting white player
The GDD Player Journey says the player "sees one matching NPC within
reach... first attach", but every NPC was col=12 (blue) vs white player
(pcol=13) — nothing could ever attach; blues fled and despawned before any
interaction.

**Fix (data only):** event NPC at (49,-282) flipped col=12→13 in both the
`-- editor:plants=` comment and the initial `npcs={}` block; chunk-1 NPCs at
(57,-395) and (28,-460) flipped col=12→13. The other six chunk-1 blues stay
col=12 and still flee (designed Lose beat); the blue event flower at -754
still severs white bonds (designed identity cost) and unlocks chunk-2 blues.
⚠ These are data-block edits — re-exporting from level_editor.html overwrites
everything from `-- editor:plants=` down; mirror the color changes in the
editor before re-exporting.

---

## Color system change (intentional, per user request)

`loneliness.p8:64-65`:
```
pcol=13 -- start white; matching-color npcs attract, others flee
glow_cols={[12]=1,[8]=2,[13]=5,[14]=2} -- [main]=outer glow color
```

White is now inner=13, outer=5 (was inner=6, outer=13). The level data in the
cart has no col=6 entities, so nothing else needed updating. If the user wants
white NPCs in the level, they'll need col=13 in the editor.

---

## Cart state (as of handover)

`loneliness.p8` tab 1 (lines ~654-665):
- 1 event NPC at world (49, -282), col=13 (white, matching the player)
- Big = `{done=true}` (no Big in the initial block — only the one event NPC)
- 1 grass tuft at (61, -282)
- 0 flowers
- `chunks[1]`: 8 NPCs — (28,-460) and (57,-395) are col=13 (white), the other
  six stay col=12 (blue) — plus one event flower at (49, -754)
- `chunks[2]`: unchanged (col=12 NPCs)

Flow: player starts white (pcol=13). Ascends. Camera locks on event NPC at
y=-282 (ceiling = -342, cam_y can't go below). Player uses call wave (O key)
to hit the NPC → `n.event_done=true` → `spawn_next_chunk()` → chunk 1 spawns.
Repeat for chunk 1's event flower (hold X near it) → chunk 2 spawns. Chunks
have no events after that, so the rest is open-ended.

---

## Outstanding

1. **Stale cart warning:** PICO-8's `Ctrl+R` reruns the *loaded* cart and
   does NOT reload from disk. After any external edit to `loneliness.p8`, the
   user must `LOAD LONELINESS.P8` then `RUN` to pick up the changes. This is
   the most common "fix doesn't work" cause. Documented in the devlog's
   "Lessons Learned" section.

2. **Editor chunk npcs still emit without `jx/jy/att/stolen` fields.** The
   `spawn_next_chunk` defaults handle the runtime crash, but the level data
   is technically inconsistent with the initial block. Cosmetic; safe to
   leave.

3. **Indentation drift in Big update block** (lines ~308-380). PICO-8 parses
   fine; only matters when someone next reads the file. Tidy during the next
   Big refactor.

4. **`expandPlantsIn` (level_editor.html:501) is referenced from
   `generateLua` but I didn't verify its current behavior** — the devlog
   mentions it expands plants with `count>1` into circle clusters of NPCs.
   If the user adds a multi-NPC plant in the editor and the export looks
   wrong, that's the place to look.

---

## Files & key line numbers

**loneliness.p8**
- 64-65: `pcol` and `glow_cols` (white = inner 13, outer 5)
- 142: flower absorb hook → `spawn_next_chunk()`
- 231: NPC wave-hit hook → `spawn_next_chunk()` (guarded by `not n.event_done`)
- 271: flee gate (now `and (not n.event or n.event_done)`)
- 308-380: Big NPC update (restructured, indentation drift)
- 372: Big despawn → `spawn_next_chunk()`
- 598-636: `update_camera` (event camera lock)
- 639-651: `spawn_next_chunk` (above export block, with jx/jy defaults)
- 654-665: level data block (initial + 2 chunks) — **target of editor paste**

**level_editor.html**
- 301-316: `DEFAULT_SECTIONS` seed
- 343-344: `SEC0_TOP/SEC0_BOT` (-350, 130)
- 390-394: `scrollToPlayer`
- 501: `expandPlantsIn` (multi-NPC plant expansion — verify before use)
- 1008: `generateChunkEntry` (per-chunk Lua emitter)
- 1028: `generateLua` (full export)
- 1047: Big default (`big={done=true}` when not placed)
- 1069: JSON `[]` → `{}` fix
- 1113: `parseLua` (load .txt back into editor; regex uses `\{...\}`)
