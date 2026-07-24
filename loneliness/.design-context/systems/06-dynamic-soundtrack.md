# System Design: Dynamic Soundtrack

**Classification:** Secondary System — audio
**Scope Cost:** Medium — 8 music patterns × 4 channels, layer-toggling via PICO-8 music pattern memory poke (`0x3100`), whole-tone scale discipline, 3 SFX slots

### Purpose

Music is the audible mirror of attachment. Bass plays alone at start (player alone). Pad joins at 1st NPC attach. Melody joins at 2nd. Shimmer joins at 3rd. Layers drop as bonds sever. The soundtrack is the player's *emotional status display* — P3 says emotion is the only currency, and music encodes the count without ever displaying a number. Player feels growth/loss as musical density.

### Core Loop Connection

No direct touch. Soundtrack is a **passive display** of `att`, fed by every system that changes attachment count. Like pollen, it is atmosphere — but where pollen shows motion, soundtrack shows *state*. AGENTS.md "none is not an answer" rule: soundtrack touches Call Wave (writes `att`), Big (writes `att`), Flower (writes `att` via detach recount), and intro→play transition (init).

### Pillars Served

- **P1 Always Move Forward:** Music loops 0-7 with pattern 7 carry-loop-back (`02` flag). No restarts on layer change — pattern boundary transitions are seamless. Player doesn't hear "going back"; music never restarts, only thickins/thins. Linear progression of musical density parallels linear ascent.
- **P2 Show, Don't Tell:** Music is non-speech audio — not text, not prompt. Layer additions as attachments accrue communicate growth without UI. Whole-tone scale (C D E F# G# A#) across all SFX gives ambiguous, spa-like emotion — keeps the game from "telling" a specific mood via key/scale choice.
- **P3 Emotion Is the Only Currency:** `att` count flows directly into audible layer count. The only displayed form of attachment is musical density — no `print(att)` ever. Music IS the score, except it can't be counted, only felt.

---

### Inputs

| Input | Source | Type | Required? |
|---|---|---|---|
| `att` (attachment count, recounted at each change) | Call Wave / Big / Flower | number | Yes |
| `snd_patterns` | tunable | number | Yes — loop bound |
| SFX slot 50/51/52 | invoked directly | trigger | Yes |
| `state` transitions (`intro → play`) | state machine | trigger | Yes — music start |

### Process

```
-- init: 8 patterns × 4 channels (ch0 bass, ch1 pad, ch2 mel, ch3 shimmer)
-- pattern 7 flag = 02 → loop back to 0
-- soundtrack: toggle bit 6 (0x40) of each pattern's channel bytes

function set_music_layers(att):
  for p = 0, snd_patterns-1:                       -- 8 patterns
    local base = 0x3100 + p*4                       -- pattern channel bytes
    for ch = 1, 3:                                  -- toggle ch1, ch2, ch3 (ch0 always on)
      local b = peek(base + ch)
      if att >= ch:
        poke(base + ch, band(b, 0xbf))               -- clear bit 6 → audible
      else:
        poke(base + ch, bor(b, 0x40))                -- set bit 6 → "empty" → skipped
  -- ch0 (bass) never toggled — always on at att=0

-- intro → play transition (loneliness.p8:122-123):
set_music_layers(0)                                  -- bass only
music(0, 1)                                          -- start pattern 0, loop mode

-- every att change site (attach / detach / steal / color-change):
recount att; set_music_layers(att)

-- SFX slots (one-shots, composed in PICO-8 SFX editor):
-- slot 50: splash sting (sfx(50) in _init)
-- slot 51: attach chime (sfx(51) on NPC attach in call wave)
-- slot 52: detach chime (sfx(52) on Big steal, color-change detach, non-match flee in call wave)
```

**State Machine (layer state, derived):**

```
States: Bass-only (att=0) → Bass+Pad (att=1) → Bass+Pad+Mel (att=2) → Bass+Pad+Mel+Shm (att≥3)
Transitions:
  Bass-only → Bass+Pad: any attach (att 0→1)
  Bass+Pad → Bass+Pad+Mel: any attach (att 1→2)
  Bass+Pad+Mel → Bass+Pad+Mel+Shm: any attach (att 2→3)
  Any → any lower: detach/steal/color-change-mismatch-detach (att decremented)
  att>3 clamps to same top state (4 layers max — there is no ch4)
```

### Outputs

| Output | Consumer | Type | Range |
|---|---|---|---|
| PICO-8 music engine bit-6 toggles | audio mixer | memory byte | per pattern channel |
| Audible musical layers | player ear | audio | ch0..ch3 |
| `sfx(50/51/52)` | audio mixer | trigger | discrete SFX slots |

No system reads soundtrack state. Music is a terminal display — receives `att`, outputs sound, never feeds back.

---

### System Interactions

| System | Interaction Type | Effect |
|---|---|---|
| Call Wave Attach | Calls `set_music_layers(att)` after each attach | Layer up. |
| Call Wave Attach | Calls `sfx(51)` on attach | Attach chime one-shot. |
| Call Wave Attach | Calls `sfx(52)` on non-match flee | Detach/flee chime. |
| Big NPC Thief | Calls `set_music_layers(att)` after each steal | Layer down. |
| Big NPC Thief | Calls `sfx(52)` per steal | Detach chime. |
| Flower Color-Change | Calls `set_music_layers(att)` after recount | Layer down (usually) on mismatch detach. |
| Flower Color-Change | Calls `sfx(52)` per detached NPC | Detach chime. |
| Splash + Intro + Fade-In | Calls `set_music_layers(0)` + `music(0, 1)` on intro→play | Music start at att=0. |
| Splash + Intro + Fade-In | Calls `sfx(50)` once in `_init` | Splash sting. |
| Player Movement + Camera | None | Music schedule independent of camera. |
| Pollen Ambient | None | |

### Tuning Levers

| Lever | Min | Max | Default | Effect |
|---|---|---|---|---|
| `snd_patterns` | 4 | 8 | `8` | Pattern count in loop. Currently hardcoded to match `__music__` data (8 patterns composed). Lower = shorter loop (جدي, tighter repetition); higher = need to compose more patterns. |
| Layer add thresholds (hardcoded `att>=ch`) | 1 | 3 | `1, 2, 3` | Layer N triggers at att≥N. **Flag: implicit, no tunable — to retune, edit `set_music_layers` body. Ponytail: ok until Balance & Tuning phase.** |
| Pattern content (`__music__` data) | — | — | 8 patterns | Composed in PICO-8 music editor, not code-tunable. Whole-tone scale enforced as authoring discipline (per devlog). |
| SFX slot content (50/51/52) | — | — | fixed | Composed in PICO-8 SFX editor. Whole-tone scale enforced. |

---

### Edge Cases

| Condition | Expected Behavior |
|---|---|
| `att > 3` | `for ch=1,3` caps at ch3. All layers audible. `att` of 4, 5, 6+ produces identical audible state. Music saturates at 3 attachments. Ponytail: ok — no ch4 in PICO-8 music data anyway. Player may notice no layer-up on 4th attach, but visual glow continues growing. **Flag: design acceptance — 3-layer musical ceiling vs unbounded glow growth.** |
| Attach + immediately steal (same frame?) | `set_music_layers` called twice with `att` up then down. End state correct. Audio may flicker on 1-frame transition but PICO-8 music engine reads at pattern boundary. Safe. |
| Player reaches `att=3` simultaneously with Big steal reducing `att` to 2 | Race condition impossible — code is single-threaded, sequential. Order determined by source code order in `_update`. Final `att` after both halves of update reflects correct count. |
| `music(0, 1)` called during intro fade | Currently called once at intro→play. If state machine bug retfires `music(0)` mid-play, pattern restarts from row 0 — jarring mid-phrase jump (per devlog "Tried first" note). Critical to never re-call. |
| `snd_patterns=8` but `__music__` has fewer than 8 patterns composed | Poke loop reads uninitialized bytes (`peek(0x3100 + p*4)` on missing pattern) and toggles bit 6. PICO-8 RAM zero-init → zeros toggled to `0x40`. Safe (empty channels). |
| `att` recount reads `n.att and not n.stolen` after Big steal but before stolen orbit block runs | Recount logic: `for m in all(npcs) do if m.att and not m.stolen then att+=1 end`. Stolen NPCs have `n.att=false` set in steal. Safe. |

### Failure States

| What can go wrong | Symptom | Recovery |
|---|---|---|
| Re-calling `music(0,1)` to "add layer" | Pattern restarts from row 0 (prior bug). NEVER re-call. Use `set_music_layers` poke instead. | Already documented in devlog "Tried first (failed)". |
| `bor(band(b, 0xbf), 0x40)` ordering bug | `band` clears bit 6, `bor` sets it. If logic flipped, channel stays muted. | Verify branch: `att>=ch` → `band(b, 0xbf)` (clear → audible); `else` → `bor(b, 0x40)` (set → muted). Correct per current code. |
| `peek(base+ch)` reads illegal addr | `0x3100 + p*4 + ch`, p∈[0,7], ch∈[1,3]. Max addr = 0x311f. PICO-8 music pattern RAM. Safe. |
| SFX slot collision (50/51/52 reused for music notes) | SFX slots 0-63 are shared with music pattern note slots. SFX 50-52 are within music pattern 16-21 range. Composing a pattern that uses slot 50-52 as instrument notes would conflict with `.sfx()` calls. **Discipline: don't use slots 50-52 as music notes** (per devlog). Authoring rule. |
| Whole-tone scale violation in new SFX | In-collection rule (`p%12 ∈ {0,2,4,6,8,10}`) not enforced in code — authoring discipline only. | Verify in SFX editor before shipping. |

---

### Pairwise Status

| Feature A | Feature B | Status | Interaction |
|---|---|---|---|
| Dynamic Soundtrack | Call Wave Attach | ✅ | `set_music_layers(att)` on attach/detach + `sfx(51/52)`. Tightest coupling. |
| Dynamic Soundtrack | Big NPC Thief | ✅ | `set_music_layers(att)` on steal + `sfx(52)`. |
| Dynamic Soundtrack | Flower Color-Change | ✅ | `set_music_layers(att)` on recount + `sfx(52)`. |
| Dynamic Soundtrack | Player Movement + Camera | ✅ | None — music schedule camera-independent. |
| Dynamic Soundtrack | Pollen Ambient | ✅ | None. |
| Dynamic Soundtrack | Grass / Flower Visual | ⚠ TBD | None expected. |
| Dynamic Soundtrack | Splash + Intro + Fade-In | ✅ | Music start at intro→play (`set_music_layers(0); music(0,1)`). Splash sting `sfx(50)` at `_init`. |

### Pillar Gate

| Check | Result |
|---|---|
| Serves a pillar? | P2 (audio as state display, no text), P3 (emotion currency = music density, no score). P1 weak (linear density mirrors ascent) |
| Connects to core loop? | No direct touch — passive display of `att`. AGENTS.md rule: not a loop orphan because it serves P2 + P3 by making attachment audible. |
| Touches systems? | Call Wave (att writes), Big (att writes), Flower (att writes), Splash/Intro (init). 4 systems. |
| Scope cost? | Medium. Music data authoring (8 patterns × 4 channels composed by user) + 3 SFX slots + poke toggling. Already implemented. Inherited: any new system that changes `att` must call `set_music_layers(att)` after recount. |
| Contradicts anything? | **Flag 1:** Musical ceiling at att=3 vs unbounded glow growth at att→∞. Design acceptance — flag for design judge / pair pass. **Flag 2:** Layer-add threshold (`att>=ch`) is hardcoded in `set_music_layers` body — ponytail: ok until tuning. **Flag 3:** SFX slot collision discipline is authoring-only, not enforced — fragile if new contributor adds music. Single-dev jam — safe. |

**Verdict:** PASS with 3 flags.
- **Flag 1 (musical ceiling vs unbounded glow)** — real design tension. Glow visually saturates later but music saturates at att=3. Either retune music to ceiling at att=N (different layer logic, requires new channels/patterns) or accept. Punt to judge / Balance & Tuning.
- **Flag 2 (layer threshold tuning)** — defer to tuning phase.
- **Flag 3 (SFX slot collision discipline)** — authoring rule only. Doc-only flag.