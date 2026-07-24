# Pairwise Interaction Matrix

Run 2026-07-24. 8 features → 28 pairs.

```
                Move  Call  Big   Flwr  Poln  Snd   Grass Splash
Move              —    ⚠    ⚠    ✅    ⚠    ✅    ✅    ✅
Call              ⚠     —    ⚠    ✅    ✅    ✅    ✅    ✅
Big               ⚠    ⚠     —    ⚠    ⚠    ✅    ✅    ⚠
Flwr              ✅    ✅    ⚠     —    ⚠    ✅    ✅    ⚠
Poln              ⚠    ✅    ⚠    ⚠     —    ✅    ✅    ✅
Snd               ✅    ✅    ✅    ✅    ✅     —    ✅    ✅
Grass             ✅    ✅    ✅    ✅    ✅    ✅     —    ✅
Splash            ✅    ✅    ⚠    ⚠    ✅    ✅    ✅     —
```

**Stats:** 19 ✅ documented, 9 ⚠ open. 0 undocumented.

All ⚠ pair to existing code-change-queue items.

## Pairs

### Move + CallWave — ⚠
- Simultaneous? YES — player casts while moving
- Result: Wave follows player as it expands; attached NPCs orbit moving player; detached drift free
- Edge: Overflow risk in attach distance check at large world deltas (unguarded)
- Open: queue #1

### Move + BigThief — ⚠
- Simultaneous? YES — Big chases while player moves
- Result: Big ratchet-bound; player escapes by ascending above `steal_range`; Big retreats if no targets
- Edge: Big idle forever if player skirts range — drift fix pending
- Open: queue #3

### Move + Flower — ✅
- Simultaneous? NO — charge freezes player; SEQUENCE-ONLY
- Result: Movement locked during 3s charge; camera ratchet continues
- Edge: Flower scrolls off mid-charge (charge continues by world distance); guard applied

### Move + Pollen — ⚠
- Simultaneous? YES
- Result: Pollen repulses around player; wraps in world band ±160 around camera; parallax scroll
- Edge: Overflow in 3 pollen paths at large world delta (unguarded)
- Open: queue #2

### Move + Soundtrack — ✅
- Simultaneous? YES — music schedule camera-independent
- Result: No interaction

### Move + Grass — ✅
- Simultaneous? YES
- Result: Grass world-space parallax + screen cull
- Edge: grass gone forever once scrolled past top (P1-aligned)

### Move + Splash — ✅
- Simultaneous? SEQUENCE-ONLY — splash/intro run before camera engagement
- Result: Camera initialized to 0; ratchet engages on play start

### CallWave + BigThief — ⚠
- Simultaneous? YES — Big steals attached while player casts
- Result: Shared `att` count, `n.att/att_fc/stolen`, `big.sc=0` reset on attach. Tightest coupling
- Edge: Big cast may continue if Big goes offscreen mid-cast
- Open: queue #13 (deferred)

### CallWave + Flower — ✅
- Simultaneous? NO — sequence via `pcol` change
- Result: Flower flips `pcol` → mismatches detach → next call uses new `pcol` to gate attach/flee
- Edge: Strongest coupling in cart
- Note: mis-input guard pending (queue #4)

### CallWave + Pollen — ✅
- Simultaneous? YES
- Result: None — call ring has no `burst=true`, pollen untouched

### CallWave + Soundtrack — ✅
- Simultaneous? YES
- Result: Soundtrack layers added/dropped on every attach/detach; chimes on attach/flee

### CallWave + Grass — ✅
- Simultaneous? YES
- Result: None — grass driven by level layout, not attachment state

### CallWave + Splash — ✅
- Simultaneous? SEQUENCE-ONLY
- Result: First attach after play start raises pad layer

### BigThief + Flower — ⚠
- Simultaneous? YES — Big can steal during 3s charge freeze
- Result: Dual-loss tension. Resolved by level-editor constraint (no flower near Big)
- Edge: Flower detach → `att=0` mid-Big-cast → Big post-steal starts early (benign)
- Open: queue #12 (OQ8)

### BigThief + Pollen — ⚠
- Simultaneous? YES — cast ring pushes pollen outward during 36f cast
- Result: Pollen visibly dramatizes Big reach
- Edge: Overflow in pollen Big-cast path at large world delta (unguarded)
- Open: queue #2

### BigThief + Soundtrack — ✅
- Simultaneous? YES
- Result: Layer drop on steal; detach chime per steal

### BigThief + Grass — ✅
- Simultaneous? YES
- Result: None

### BigThief + Splash — ⚠
- Simultaneous? YES — Big spawn at y=-260 during init
- Result: During fade-in Big may already be visible if camera starts near y=0
- Open: queue #13 (deferred per user "wait and see")

### Flower + Pollen — ⚠
- Simultaneous? YES — burst ring scatters pollen aggressively
- Result: Burst flag pushes pollen, flagged pollen despawns offscreen, slow respawn via deficit
- Edge: Stuck burst particle if player ratchets past onscreen
- Open: queue #10 (low priority)

### Flower + Soundtrack — ✅
- Simultaneous? YES
- Result: Layer drop on detach recount; detach chime per detached NPC

### Flower + Grass — ✅
- Simultaneous? YES — shared two-pass draw pattern
- Result: Both shadow-under-glow + sprite-over-rings; same dither pattern

### Flower + Splash — ⚠
- Simultaneous? SEQUENCE-ONLY — interactions only in play
- Result: First interaction requires travel + X mechanic discovery (P2 conflict via prompt)
- Open: queue #11 (OQ3 deferred)

### Pollen + Soundtrack — ✅
- Simultaneous? YES
- Result: None

### Pollen + Grass — ✅
- Simultaneous? YES — draw order
- Result: Grass shadow under, grass sprite over, pollen on top

### Pollen + Splash — ✅
- Simultaneous? YES — pollen init at screen-space y
- Result: Pollen visible through fade-in dither overlay — feels like world emerging with pollen twisting

### Soundtrack + Grass — ✅
- Simultaneous? YES
- Result: None

### Soundtrack + Splash — ✅
- Simultaneous? SEQUENCE-ONLY — music start at intro→play
- Result: Bass only at start; splash sting at boot

### Grass + Splash — ✅
- Simultaneous? YES — grass drawn during fade-in
- Result: Grass visible through dither overlay; acceptable

## Gap analysis

All 9 open pairs decompose to 4 root causes:

1. **Overflow guards missing** (queue #1, #2) — covers Move+Call, Move+Poln, Big+Poln. Fix once, closes 3 pairs.
2. **Big idle drift** (queue #3) — covers Move+Big. Closes 1 pair.
3. **Big + Flower / Big + Splash edge cases** (queue #12, #13) — covers Big+Flwr, Big+Splash. Deferred pairs.
4. **Flower prompt + stuck burst** (queue #10, #11) — covers Flwr+Splash, Flwr+Poln. 1 deferred, 1 low priority.

No undocumented interactions. No unknown-unknowns surfaced. System files' pairwise tables match this matrix.