# System Design: Splash + Intro + Fade-In

**Classification:** Content Feature — pre-play presentation
**Scope Cost:** Low — three sequenced states (`splash → intro → play`), each with own draw + update branch; one-shot SFX sting; 2s splash timer; typewriter intro + hold + color-step fade; dither dissolve fade-in over 2s of play

### Purpose

First impression + narrative framing + transition choreography. Splash brands the studio. Intro types the title (ほたる / "hotaru" — firefly), holds, fades letter color 7→6→5→1→0, then enters play. Play opens with a dithered black overlay that thins over 60 frames (2s) — the world "appears" through dissolving dark. Together these deliver the emotional entry: identity (whose game), title (the word you carry into play), emergence (the world resolving from black). Sets the P3 tone before the first input.

### Core Loop Connection

No direct touch. Pre-play and play-entry. AGENTS.md rule: the system serves P2 (show don't tell — the *title itself* is the tell, but pre-game, not gameplay instruction; addressed in resolved T1) and P3 (sets emotional register before currency begins). Wrap-up: OQ4 ending beat will likely need a sibling state `play → ending → credits`, mirroring this entry sequence — design TBD.

### Pillars Served

- **P1 Always Move Forward:** State machine `splash → intro → play` is one-way, no rewind. Fade-in completes and never repeats. Player never sees splash or intro again in the session. **T1 resolved:** splash input-lock (no button skip) commits to forward-only preamble — no scrubbing back.
- **P2 Show, Don't Tell:** Splash = visual logo + studio name (pre-game branding, not gameplay instruction). Intro = typewriter title (narrative framing, resolved T1). Fade-in = pure visual transition. No button prompts, no "press start", no "press O to call" tutorial — play begins with the player already in the world, expected to discover Call/Flower via visual affordance. **T1 carries resolved: P2 binds `state=="play"` only.**
- **P3 Emotion Is the Only Currency:** No high score screen, no menu with options, no player account. Just a word, a sting, and emergence. Sets emotional register before attachment currency opens.

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `state` | global | string | Yes — branch |
| `fc` | frame counter | number | Yes — splash timer |
| `intro_t` | global | number | Yes — intro phase timer |
| `intro_text` | tunable | string | Yes — typewriter text |
| `intro_letter_f, intro_hold_f, intro_fade_f` | tunables | number | Yes — phase durations |
| `fade_t, fade_in_f` | globals | number | Yes — fade-in counter |
| SFX slot 50 | direct | trigger | Yes — splash sting |

### Process

```
-- _init:
sfx(50)                                            -- splash logo sting (one-shot)

-- _update splash:
if state == "splash":
  if fc >= 60:                                     -- 2s @ 30fps, no button skip (T1 resolved)
    state = "intro"; intro_t = 0
  return                                           -- early return prevents play movement

-- _update intro:
if state == "intro":
  intro_t += 1
  local full = #intro_text * intro_letter_f
  local fade_end = full + intro_hold_f + intro_fade_f
  if intro_t >= fade_end:
    state = "play"; fade_t = 0
    set_music_layers(0)                            -- bass only
    music(0, 1)                                    -- start pattern 0, loop mode
  return                                           -- early return

-- _update play (after movement + entities):
if state == "play" and fade_t < fade_in_f:
  fade_t += 1                                     -- increment fade progress

-- _draw splash:
if state == "splash":
  cls(0)
  sspr(0, 96, 32, 32, 48, 40)                     -- logo at (48,40), 32×32 from gfx bank
  print("hoshibocchi games", 30, 80, 7)           -- studio name col 7
  return

-- _draw intro:
if state == "intro":
  cls(0)
  local full = #intro_text * intro_letter_f
  local shown = flr(intro_t / intro_letter_f)
  if shown > #intro_text then shown = #intro_text end
  local txt = sub(intro_text, 1, shown)           -- typewriter reveal
  local col = 7
  local fade_t = intro_t - (full + intro_hold_f)  -- local shadow of global name; both == fade phase
  if fade_t > 0:
    local p = fade_t / intro_fade_f
    if p > 0.33 then col = 6 end
    if p > 0.66 then col = 5 end
    if p >  0.85 then col = 1 end
    if p >=    1 then col = 0 end                  -- black-on-black = invisible
  print(txt, 56 - #txt*2, 62, col)                -- horizontally centered, y=62
  return

-- _draw play fade-in (last, after pollen):
if fade_t < fade_in_f:
  local p = fade_t / fade_in_f
  if p < 0.25 then fillp(0)                        -- solid black
  elseif p < 0.5  then fillp(0b11001001_11001001)  -- 75%
  elseif p < 0.75 then fillp(0b10101010_10101010) -- 50%
  else fillp(0b01010101_01010101) end             -- 25%
  rectfill(0, 0, 127, 127, 0)
  fillp(0)                                         -- reset
```

**State Machine:**

```
States: splash (60f) → intro (typewriter + hold + fade) → play (60f fade-in then loop)
Transitions:
  splash → intro: fc >= 60 (no input skip)
  intro → play: intro_t >= #intro_text * intro_letter_f + intro_hold_f + intro_fade_f
  play (fade-in): fade_t < fade_in_f, dither overlay thins
  play (steady): fade_t >= fade_in_f, overlay cleared, normal loop
```

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| `state` change | every system gated on `state=="play"` | string | splash → intro → play |
| Splash screen pixels | screen | — | 2s |
| Intro screen pixels | screen | — | duration varies with `#intro_text` |
| `set_music_layers(0) + music(0,1)` | PICO-8 audio | trigger | once on intro→play |
| `sfx(50)` | audio | trigger | once in `_init` |
| Fade-in overlay (dithering rectfill col 0) | screen | overlay | 60f |
| `fillp(0)` reset | draw state | — | after overlay |

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| All gameplay systems | Reads `state=="play"` | Splash + intro branches `return` early — no gameplay updates or draws. Fade-in overlays normal play draw. |
| Player Movement + Camera | Reads `state` | Movement gated on play. Camera ratchets only during play. |
| Call Wave Attach / Big / Flower / Pollen | Reads `state` | All `_update` gameplay branches gated behind splash/intro early returns. |
| Dynamic Soundtrack | Calls `set_music_layers(0)` + `music(0,1)` at intro→play | Music starts after splash+intro silence. Splash sting `sfx(50)` is the only pre-play audio. |
| Grass / Flower Visual | Reads `state=="play"` | Drawn only after intro→play. Visible through dither overlay during fade-in. |
| Feedback Rings | None | Rings table is empty until play begins (player can't cast wave during splash/intro). |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| Splash duration | 30 | 180 | `60` (2s @ 30fps) | Hardcoded `fc>=60`. **Flag: expose as tunable.** |
| `intro_text` | — | — | `"\^w\^tほたる"` | Title text. Edit directly. Special chars `\^w\^t` are PICO-8 text formatting flags (wide/tall). |
| `intro_letter_f` | 6 | 30 | `12` | Frames per letter reveal. Lower = faster typing. |
| `intro_hold_f` | 30 | 180 | `60` (2s) | Hold time after full text before fade. |
| `intro_fade_f` | 15 | 90 | `30` (1s) | Fade-out duration. |
| `fade_in_f` | 30 | 120 | `60` (2s) | Total fade-in duration at play start. |
| Splash logo position (48, 40) | — | — | fixed | Hardcoded `sspr` destination. |
| Studio text position + col (`30, 80, 7`) | — | — | fixed | Hardcoded. |
| Intro text y=62 | — | — | fixed | Hardcoded. Horizontal centering computed from `#txt*2`. |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| `#intro_text=0` (empty title) | `full = 0`, hold starts at `intro_t=0`, fade begins immediately. Total intro = `0 + 60 + 30 = 90f` of blank screen. Acceptable — quick transition. |
| `intro_text` longer than screen width | PICO-8 wraps text at screen edge. With wide/tall flags, can clip. Current text `ほたる` is 3 glyphs centered — safe. |
| Frame 1 (`fc=0`) — `_init` runs `sfx(50)`, then `_update` runs `fc+=1 → fc=1`. Splash timer counts from `fc=1`. Total splash ≈ 59f instead of 60. Pedantic. | Safe. |
| Player input during splash | Ignored — splash ignores all `btnp()` (T1 resolved). Cannot skip. |
| Player input during intro | Ignored — no input handling in intro branch. Cannot skip. |
| `intro_t` increments during splash? | No — splash branch `return`s before intro block. `intro_t=0` set on splash→intro transition. Safe. |
| Fade-in runs while NPC also pulses | Overlay covers all draw output for first 25% (solid). World "appears" as overlay thins. Player movement already active — player sees their own motion through the dither. Intentional emergence feeling. |
| `fade_t` shadows global name in intro draw (line 397 `local fade_t=...`) | Local shadows global. Safe within intro draw scope. Global `fade_t` not used until play. Confusing name reuse. **Flag: rename local** for clarity. |
| Music starts at intro→play but fade-in still covers screen | Music plays under fade-in. Audio cue before visual reveal. Acceptable — emotional counterpoint. |
| Reload cart mid-splash (developer workflow) | PICO-8 reload re-runs `_init` → `sfx(50)` re-fires. Dev annoyance. Not a game-facing issue. |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| `state` machine typo (e.g. `state=="play"` becomes `state=="paly"`) | All gameplay update silently skips — black screen or stuck splash | Hard to debug; PICO-8 has no `printh`-asserted state asserts. **Flag: add `printh("state="..state)` debug** if state bugs appear. |
| `music(0, 1)` called more than once (e.g. bug in transition) | Pattern restarts from row 0 — jarring mid-phrase jump (per devlog "Tried first (failed)") | Already documented; never re-call. Splash+intro transition is single-fire. Safe. |
| `_init` not invoked (PICO-8 boot mode oddity) | `sfx(50)` skipped. Player sees splash without sting. Music still starts at intro→play because transition runs. | Verify `_init` is cart-declared. Currently present (line 102). Safe. |
| Splash/intro branches forget `return` | Both update and draw fall through into play logic. Player would see play through splash/intro overlay. | Verified present in both update (lines 114, 122) and draw (lines 386, 404). Safe. |
| Fade-in `fillp(0)` reset missing | All later draws in same frame become dithered. | Verified present (final line of fade block): `fillp(0)`. Safe. |
| Intro `print` horizontal centering off — `56 - #txt*2` assumes 4px/char | PICO-8 default 4px wide chars. Wide flag uses 8px. With `\^w`, `#txt` counts chars but each is 8px wide → centering shifts left of true center. Visually minor. | Document or compute width properly. Low priority. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Splash + Intro + Fade-In | Player Movement + Camera | ✅ | Gates via `state=="play"`; fade-in overlays normal play draw. |
| Splash + Intro + Fade-In | Call Wave Attach | ✅ | None — call wave runs only in play. |
| Splash + Intro + Fade-In | Big NPC Thief | ⚠ | Big spawn at y=-260 during init; `big_onscreen` gate may engage during fade-in if Big within range. Sub-flag from system 03 — defer per user "wait and see." |
| Splash + Intro + Fade-In | Flower Color-Change | ✅ | None — flowers init in tab 1; interactions only in play. |
| Splash + Intro + Fade-In | Pollen Ambient | ⚠ | Pollen init at `rnd(128)` (initial-screen world y 0..128). Visible through fade-in dither overlay. Acceptable aesthetic — feels like world emerging with pollen twisting. |
| Splash + Intro + Fade-In | Dynamic Soundtrack | ✅ | `set_music_layers(0); music(0,1)` on intro→play. Splash sting `sfx(50)`. |
| Splash + Intro + Fade-In | Grass / Flower Visual | ⚠ | Grass + flowers visible through fade-in. Acceptable. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P1 (one-way state machine, no rewind), P2 (visual entry, no prompt — T1 resolved outside play), P3 (sets emotional register without score/menu). |
| Connects to core loop? | No direct touch — pre-play and play-entry. AGENTS.md exception: serves P2/P3 register-setting. |
| Touches systems? | All gameplay (gated via `state`), Soundtrack (init), Grass/Flower/Pollen (visible during fade-in). |
| Scope cost? | Low. Three branches in update, three in draw, one-shot sting, 60f timers. Already implemented. Inherited: any new state (e.g. `ending`, OQ4) must mirror splash/intro branching pattern and respect `return` discipline. |
| Contradicts anything? | **Flag 1:** Splash duration hardcoded (`fc>=60`) — ponytail: ok, exposes would be one-liner. **Flag 2:** `fade_t` local shadows global in intro draw — readability nit, rename. **Flag 3:** Wide-flag centering shift — minor visual. **Flag 4:** Conceptual: ending beat (OQ4) needs sibling state machine — design TBD, not contradiction. |

**Verdict:** PASS with 4 flags.
- **Flag 1 (splash duration hardcoded)** — defer, expose in cleanup pass.
- **Flag 2 (`fade_t` shadow)** — rename local for readability. Small diff.
- **Flag 3 (wide-flag centering)** — minor, document. Centering computed for 4px chars but `\^w` uses 8px → text shifts left of true center by `#txt*2` px. Low priority.
- **Flag 4 (ending beat sibling)** — design path forward, not a bug. OQ4 will require state machine extension. Document.