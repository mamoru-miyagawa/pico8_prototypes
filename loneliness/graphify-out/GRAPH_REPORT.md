# Graph Report - loneliness  (2026-08-04)

## Corpus Check
- 54 files · ~74,472 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1319 nodes · 3223 edges · 77 communities (74 shown, 3 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 106 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8e8e8346`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- hotaru.js
- ke
- jh
- hb
- devlog — loneliness
- wt
- zq
- Pairs
- od
- bu
- assert
- Aq
- xq
- GDD — loneliness
- yu
- description_i18n
- title_i18n
- Mq
- sd
- _g
- GDD.md
- Bugs found & fixed
- ft
- MDA Analysis — Core Loop (Move → Grow → Lose)
- gt
- GDD Skeleton — <Game Title>
- System: <name>
- loneliness cart conventions
- System Design: Player Movement + Ratchet Camera
- System Design: Color-Matched NPC Attach (Call Wave)
- System Design: Big NPC Thief
- System Design: Flower Color-Change
- System Design: Pollen Ambient
- lb
- GDD Toolkit
- System Design: Dynamic Soundtrack
- System Design: Grass & Flower Visual Flourish
- System Design: Splash + Intro + Fade-In
- Web prototype layouts
- Design Log
- open-design.json
- tags
- Workflow
- Lessons Learned (PICO-8 pitfalls)
- Domain adapter: <genre>
- System: <name>
- _j
- Game: <title>
- Agent Browser
- devlog — feature registration
- Obsidian Vault Layout for Game Design
- The Game Design Workflow — as Flowcharts
- PICO-8 cart conventions
- Core Loop
- Current Pillars
- hv
- File templates
- _strftime
- callRuntimeCallbacks
- MDA Framework Reference
- soundtrack.lua
- Design Pillars — Reference
- Code Change Queue
- Web prototype checklist
- dynamicAlloc
- demangleAll
- jg
- ok
- opencode.json
- loneliness — PICO-8 cart
- Design Failure Modes: symptom → gate
- ih
- xv
- author
- index.md

## God Nodes (most connected - your core abstractions)
1. `bu()` - 108 edges
2. `wt()` - 83 edges
3. `zq()` - 83 edges
4. `jh()` - 54 edges
5. `devlog — loneliness` - 52 edges
6. `ke()` - 48 edges
7. `yd()` - 46 edges
8. `xq()` - 46 edges
9. `yc()` - 41 edges
10. `wq()` - 40 edges

## Surprising Connections (you probably didn't know these)
- `allocate()` --indirect_call--> `dynamicAlloc()`  [INFERRED]
  hotaru.js → hotaru.js  _Bridges community 64 → community 10_
- `oq()` --indirect_call--> `Ya()`  [INFERRED]
  hotaru.js → hotaru.js  _Bridges community 1 → community 6_
- `oq()` --indirect_call--> `Za()`  [INFERRED]
  hotaru.js → hotaru.js  _Bridges community 0 → community 6_
- `ke()` --indirect_call--> `_a()`  [INFERRED]
  hotaru.js → hotaru.js  _Bridges community 9 → community 1_
- `oq()` --indirect_call--> `fb()`  [INFERRED]
  hotaru.js → hotaru.js  _Bridges community 5 → community 6_

## Import Cycles
- None detected.

## Communities (77 total, 3 thin omitted)

### Community 0 - "hotaru.js"
Cohesion: 0.02
Nodes (42): abortOnCannotGrowMemory(), bn(), cv(), dg(), dn(), Do(), doCallback(), done() (+34 more)

### Community 1 - "ke"
Cohesion: 0.07
Nodes (91): ad(), Ae(), af(), bc(), bd(), be(), bf(), _c() (+83 more)

### Community 2 - "jh"
Cohesion: 0.05
Nodes (74): ab(), aj(), ak(), al(), bj(), bk(), bl(), ci() (+66 more)

### Community 3 - "hb"
Cohesion: 0.07
Nodes (54): ag(), ah(), As(), bh(), ch(), dm(), eb(), eh() (+46 more)

### Community 4 - "devlog — loneliness"
Cohesion: 0.04
Nodes (51): Attach Chime, Attachment System, Big NPC Cast Ring + Refined Steal, Big NPC: nil arithmetic on frame 1, Big NPC Thief, Call Wave Mechanic, Chunked/Gated Spawning, Color-Driven Attract/Flee + Start White (+43 more)

### Community 5 - "wt"
Cohesion: 0.09
Nodes (45): au(), bm(), bp(), Bq(), cc(), cm(), dh(), el() (+37 more)

### Community 6 - "zq"
Cohesion: 0.12
Nodes (38): ap(), Cq(), ds(), ep(), Eq(), Fq(), Gq(), io() (+30 more)

### Community 7 - "Pairs"
Cohesion: 0.06
Nodes (31): BigThief + Flower — ⚠, BigThief + Grass — ✅, BigThief + Pollen — ⚠, BigThief + Soundtrack — ✅, BigThief + Splash — ⚠, CallWave + BigThief — ⚠, CallWave + Flower — ✅, CallWave + Grass — ✅ (+23 more)

### Community 8 - "od"
Cohesion: 0.07
Nodes (30): assets, designSystem, skills, primary, od, capabilities, context, inputs (+22 more)

### Community 9 - "bu"
Cohesion: 0.17
Nodes (27): _a(), ai(), am(), _b(), bu(), bv(), cp(), Dq() (+19 more)

### Community 10 - "assert"
Cohesion: 0.09
Nodes (24): allocate(), allocateUTF8OnStack(), assert(), ccall(), _emscripten_get_now(), _emscripten_set_main_loop(), _emscripten_set_main_loop_timing(), getCFunc() (+16 more)

### Community 11 - "Aq"
Cohesion: 0.12
Nodes (24): Aq(), bb(), Bs(), cs(), db(), dp(), fn(), gb() (+16 more)

### Community 12 - "xq"
Cohesion: 0.17
Nodes (23): an(), dk(), fo(), fp(), go(), ho(), hp(), ip() (+15 more)

### Community 13 - "GDD — loneliness"
Cohesion: 0.09
Nodes (22): 10. Production & Scope, 11. Appendices, 1. Executive Summary, 2. Design Pillars, 3. Core Loop, 4. Player Journey, 5. Feature Catalog, 6. Systems Design (+14 more)

### Community 14 - "yu"
Cohesion: 0.12
Nodes (21): ao(), bo(), co(), hj(), jk(), lh(), lt(), ns() (+13 more)

### Community 15 - "description_i18n"
Cohesion: 0.11
Nodes (19): description_i18n, ar, de, en, es, fr, id, it (+11 more)

### Community 16 - "title_i18n"
Cohesion: 0.11
Nodes (19): title_i18n, ar, de, en, es, fr, id, it (+11 more)

### Community 17 - "Mq"
Cohesion: 0.12
Nodes (18): av(), cb(), Hq(), Lq(), mh(), mo(), Mq(), nh() (+10 more)

### Community 18 - "sd"
Cohesion: 0.17
Nodes (17): at(), bt(), dr(), fc(), fl(), gl(), hl(), _l() (+9 more)

### Community 19 - "_g"
Cohesion: 0.16
Nodes (17): _g(), hn(), If(), jn(), kn(), ln(), mc(), mn() (+9 more)

### Community 20 - "GDD.md"
Cohesion: 0.12
Nodes (6): Open Questions, Resolved, Rejected Ideas, Active Tensions, Design Tensions, Resolved Tensions

### Community 21 - "Bugs found & fixed"
Cohesion: 0.12
Nodes (15): 1. `spawn_next_chunk` was missing (PICO-8 nil error at line 228), 2. Big NPC: nil arithmetic on frame 1, 3. Event NPC fleeing on proximity (player can't engage), 4. Level editor: hardcoded Big default in export, 5. Level editor: JSON array brackets in chunk export, 6. Level editor: player marker off-screen by default, 7. Event NPC froze after wave hit (no visible reaction), 8. Level data: no matching-color NPCs for the starting white player (+7 more)

### Community 22 - "ft"
Cohesion: 0.14
Nodes (16): ct(), dt(), et(), ft(), hr(), ht(), it(), jt() (+8 more)

### Community 23 - "MDA Analysis — Core Loop (Move → Grow → Lose)"
Cohesion: 0.13
Nodes (14): Aesthetics (what the player feels), Dynamics (what emerges when played), Gap 1 — Narrative aesthetic under-served, Gap 2 — Expression ceiling, Gap 3 — Musical ceiling vs unbounded glow (already in tensions), Gap 4 — Fellowship = 1/5 is intentional, not a gap, MDA Analysis — Core Loop (Move → Grow → Lose), Mechanics (designer-controlled rules) (+6 more)

### Community 24 - "gt"
Cohesion: 0.22
Nodes (15): cu(), du(), eu(), fu(), gt(), gu(), hu(), id() (+7 more)

### Community 25 - "GDD Skeleton — <Game Title>"
Cohesion: 0.14
Nodes (13): 10. Production & Scope, 11. Appendices, 1. Executive Summary, 2. Design Pillars, 3. Core Loop, 4. Player Journey, 5. Feature Catalog, 6. Systems Design (+5 more)

### Community 26 - "System: <name>"
Cohesion: 0.14
Nodes (13): Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillars Served, Process (+5 more)

### Community 27 - "loneliness cart conventions"
Cohesion: 0.14
Nodes (13): Attached state, Draw order (in `_draw`), Feedback rings, File layout, Glow growth, Light engine, loneliness cart conventions, Making changes (+5 more)

### Community 28 - "System Design: Player Movement + Ratchet Camera"
Cohesion: 0.14
Nodes (13): Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate, Pillars Served (+5 more)

### Community 29 - "System Design: Color-Matched NPC Attach (Call Wave)"
Cohesion: 0.14
Nodes (14): Behavior Flowchart, Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate (+6 more)

### Community 30 - "System Design: Big NPC Thief"
Cohesion: 0.14
Nodes (14): Behavior Flowchart, Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate (+6 more)

### Community 31 - "System Design: Flower Color-Change"
Cohesion: 0.14
Nodes (14): Behavior Flowchart, Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate (+6 more)

### Community 32 - "System Design: Pollen Ambient"
Cohesion: 0.14
Nodes (13): Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate, Pillars Served (+5 more)

### Community 33 - "lb"
Cohesion: 0.21
Nodes (14): ac(), es(), ib(), lb(), oc(), pc(), sn(), tn() (+6 more)

### Community 34 - "GDD Toolkit"
Cohesion: 0.15
Nodes (12): CLI Tool: `gdd.py`, Code Audit, Common Pitfalls, Design Pillars, Design Pillars reference, GDD Toolkit, How to communicate, Mode 1 — Write the GDD (+4 more)

### Community 35 - "System Design: Dynamic Soundtrack"
Cohesion: 0.15
Nodes (13): Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate, Pillars Served (+5 more)

### Community 36 - "System Design: Grass & Flower Visual Flourish"
Cohesion: 0.15
Nodes (13): Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate, Pillars Served (+5 more)

### Community 37 - "System Design: Splash + Intro + Fade-In"
Cohesion: 0.15
Nodes (13): Core Loop Connection, Edge Cases, Failure States, Inputs, Outputs, Pairwise Status, Pillar Gate, Pillars Served (+5 more)

### Community 38 - "Web prototype layouts"
Cohesion: 0.15
Nodes (12): Class inventory (must exist in `template.html`), Layout 1 — Hero, centered, Layout 2 — Hero, split (text + visual), Layout 3 — Feature triplet, Layout 4 — Stat row (data billboard), Layout 5 — Pull quote (testimonial), Layout 6 — CTA strip (closing), Layout 7 — Log list (changelog / blog index / posts) (+4 more)

### Community 39 - "Design Log"
Cohesion: 0.17
Nodes (11): 2026-07-24, 2026-07-24 (2), 2026-07-24 (3), 2026-07-24 (4), 2026-07-24 (5), 2026-07-24 (6), 2026-07-24 (7), 2026-07-24 (8) (+3 more)

### Community 40 - "open-design.json"
Cohesion: 0.17
Nodes (11): compat, agentSkills, description, homepage, license, name, publishedAt, $schema (+3 more)

### Community 41 - "tags"
Cohesion: 0.17
Nodes (12): tags, design, desktop, example, first-party, homepage, landing, marketing-page (+4 more)

### Community 42 - "Workflow"
Cohesion: 0.17
Nodes (11): Hard rules (the seed protects most of these — don't fight it), Output contract, Resource map, Step 0 — Pre-flight (do this once before writing anything), Step 1 — Prepare the artifact from the seed, Step 2 — Plan the section list, Step 3 — Paste and fill, Step 4 — Self-check (+3 more)

### Community 43 - "Lessons Learned (PICO-8 pitfalls)"
Cohesion: 0.18
Nodes (11): Debug Workflow in PICO-8, Duplicate Code Blocks After Refactor, Fixed-Point Overflow in Distance Checks, Lessons Learned (PICO-8 pitfalls), Music Layer Toggling, NPC Orbit Phase Split, PICO-8 `^` is NOT power, Ponytail Notes in Code (+3 more)

### Community 44 - "Domain adapter: <genre>"
Cohesion: 0.18
Nodes (10): Authority order, Domain adapter: <genre>, Domain adapter: TEMPLATE, Done, by example, Evidence and primary sources, Fraud table (for Design Judge), Minimum evidence set (before any design work), Supporting content (+2 more)

### Community 45 - "System: <name>"
Cohesion: 0.18
Nodes (10): Balance Goals, Balance & Tuning Table Template, Curve Visualization (text approximation), Intent, Known Dependencies, Optional: Hard Numbers (Placeholders), Relative Power Ranking, System: <name> (+2 more)

### Community 46 - "_j"
Cohesion: 0.20
Nodes (11): ar(), bi(), br(), cr(), _j(), nr(), qs(), _r() (+3 more)

### Community 47 - "Game: <title>"
Cohesion: 0.20
Nodes (9): Core Loop (5-15 seconds), Core Loop Canvas, Game: <title>, Meta Loop (Across Sessions), Pacing Within a Session, Secondary Loops, Verification, What makes this loop different from similar games? (+1 more)

### Community 48 - "Agent Browser"
Cohesion: 0.20
Nodes (9): Agent Browser, Browser Context Extraction, CDP Startup Contract, Context Hygiene, Open Design Smoke Path, Requirements, Safety Rules, Specialized Upstream Guides (+1 more)

### Community 49 - "devlog — feature registration"
Cohesion: 0.22
Nodes (8): devlog — feature registration, Entry format, Proactive prompt, Purpose, Reading at session start, When NOT to register, When to register, Writing an entry

### Community 50 - "Obsidian Vault Layout for Game Design"
Cohesion: 0.22
Nodes (8): Dataview Queries, Feature Index (put in `02 Features/Feature Index.md`), Frontmatter Convention, Linking Conventions, Mermaid Usage in Obsidian, Obsidian Vault Layout for Game Design, Recent Design Reviews, Top-Level Structure

### Community 51 - "The Game Design Workflow — as Flowcharts"
Cohesion: 0.22
Nodes (8): 1. The Master Router, 2. The Pillar Gate, 3. The Code Audit Flow, 4. MDA Analysis Flow, 5. The Pillar Judge, 6. Project Discovery (Session Start), Reading these as a designer, The Game Design Workflow — as Flowcharts

### Community 52 - "PICO-8 cart conventions"
Cohesion: 0.22
Nodes (8): Cart file format, Coding style, Lifecycle, Output style, PICO-8 builtins, PICO-8 cart conventions, Single-cart philosophy, Verification

### Community 53 - "Core Loop"
Cohesion: 0.22
Nodes (8): 2026-07-24 — Initial loop locked, Core Loop, Encounter inputs, Evolution, Loop (4 nodes), Pillar check, Prose, Scope notes

### Community 54 - "Current Pillars"
Cohesion: 0.22
Nodes (8): 2026-07-24 (2) — Pillar anatomy updated to v2.2.0 spec, 2026-07-24 — Initial pillar set locked, Current Pillars, Design Pillars, P1 — Always Move Forward, P2 — Show, Don't Tell, P3 — Emotion Is the Only Currency, Pillar Evolution

### Community 55 - "hv"
Cohesion: 0.33
Nodes (9): hv(), iv(), mv(), nv(), uq(), Vl(), Wl(), Xl() (+1 more)

### Community 56 - "File templates"
Cohesion: 0.25
Nodes (7): design-log.md, File templates, index.md, Initialize, pillars.md, Project Context — `.design-context/`, tensions.md

### Community 57 - "_strftime"
Cohesion: 0.29
Nodes (8): __addDays(), __arraySum(), _emscripten_async_wget_data(), _emscripten_run_script(), __isLeapYear(), _strftime(), UTF8ArrayToString(), UTF8ToString()

### Community 58 - "callRuntimeCallbacks"
Cohesion: 0.25
Nodes (8): addOnPostRun(), addOnPreRun(), callRuntimeCallbacks(), ensureInitRuntime(), postRun(), preMain(), preRun(), run()

### Community 59 - "MDA Framework Reference"
Cohesion: 0.29
Nodes (6): Common MDA Mismatches, Debugging with MDA, How to Use MDA in Design, MDA Framework Reference, The 8 Aesthetic Types (LeBlanc, 2004), The Three Layers

### Community 60 - "soundtrack.lua"
Cohesion: 0.52
Nodes (5): init_music(), snd_n(), snd_pat(), snd_seq(), snd_sfx()

### Community 61 - "Design Pillars — Reference"
Cohesion: 0.33
Nodes (5): Anatomy, Design Pillars — Reference, Evolution, Examples, Good tests

### Community 62 - "Code Change Queue"
Cohesion: 0.33
Nodes (5): Code Change Queue, Deferred, High priority, Low priority, Medium priority

### Community 63 - "Web prototype checklist"
Cohesion: 0.33
Nodes (5): Anti-slop spot-check, P0 — must pass, P1 — should pass, P2 — nice to have, Web prototype checklist

### Community 64 - "dynamicAlloc"
Cohesion: 0.40
Nodes (5): ___buildEnvironment(), dynamicAlloc(), _emscripten_get_heap_size(), getMemory(), writeAsciiToMemory()

### Community 65 - "demangleAll"
Cohesion: 0.50
Nodes (4): demangle(), demangleAll(), jsStackTrace(), stackTrace()

### Community 66 - "jg"
Cohesion: 0.50
Nodes (4): gg(), hg(), ig(), jg()

### Community 67 - "ok"
Cohesion: 0.50
Nodes (4): ok(), up(), vj(), wj()

### Community 68 - "opencode.json"
Cohesion: 0.50
Nodes (3): instructions, $schema, .claude/devlog.md

### Community 71 - "ih"
Cohesion: 0.67
Nodes (3): ih(), wg(), zg()

### Community 72 - "xv"
Cohesion: 0.67
Nodes (3): wv(), xv(), yv()

### Community 73 - "author"
Cohesion: 0.67
Nodes (3): author, name, url

## Knowledge Gaps
- **486 isolated node(s):** `$schema`, `specVersion`, `name`, `title`, `zh-CN` (+481 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GDD — loneliness` connect `GDD — loneliness` to `GDD.md`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `System Design: Grass & Flower Visual Flourish` connect `System Design: Grass & Flower Visual Flourish` to `GDD.md`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Why does `bu()` connect `bu` to `hotaru.js`, `ke`, `jg`, `hb`, `jh`, `wt`, `zq`, `lb`, `Aq`, `xq`, `_j`, `sd`, `_g`, `ft`, `gt`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `$schema`, `specVersion`, `name` to the rest of the system?**
  _486 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `hotaru.js` be split into smaller, more focused modules?**
  _Cohesion score 0.01744186046511628 - nodes in this community are weakly interconnected._
- **Should `ke` be split into smaller, more focused modules?**
  _Cohesion score 0.07106227106227106 - nodes in this community are weakly interconnected._
- **Should `jh` be split into smaller, more focused modules?**
  _Cohesion score 0.05220288781932617 - nodes in this community are weakly interconnected._