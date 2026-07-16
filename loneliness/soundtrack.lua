-- soundtrack: ambient melancholic, A minor, 4-pattern loop
-- patterns: Am -> F -> G -> Em  (i - VI - VII - v relative motion)
-- channels per pattern: ch0=bass(tri) ch1=pad(organ) ch2=melody(tri) ch3=shimmer(tilted saw)
--
-- usage (when ready to implement):
--   call init_music() inside _init() after init_blending()
--   call music(0,1) where gameplay starts (e.g. on splash->play transition)
--   optional: sfx on attach chime = sfx slot 16+ (unused here)

-- tunables
snd_speed=18   -- ticks per note slot (lower=faster). 18 = slow ambient
snd_vol=8      -- master base volume for bass/pad
snd_mel=5      -- melody volume (sparser, quieter)
snd_shm=3      -- shimmer volume (rarest, quietest)

-- pitch constants (A minor, 0=C-0, +1 semitone, +12 octave)
-- A2=33 A3=45 A4=57 | C3=36 C4=48 C5=60 | E2=28 E3=40 E4=52
-- F2=29 F3=41 F4=53 | G2=31 G3=43 G4=55 | B3=47 B4=59 | D4=50 D5=62

-- encode one note to 16-bit SFX value
-- bits: 0-5 pitch | 6-9 volume | 10-12 instrument | 13-15 effect
function snd_n(p,v,i,f)
  return p%64 + (v%16)*64 + (i%8)*1024 + (f%8)*8192
end

-- write one SFX slot: speed + 32 notes (each slot = 2 bytes little-endian)
-- loop byte = 0 (no internal loop; music() loops the 4-pattern chain)
function snd_sfx(slot, speed, evs)
  local a=0x3200+slot*68
  poke(a, speed%256)
  poke(a+1, 0)
  for i=1,32 do
    local nv = i<=#evs and evs[i] or 0
    poke(a+2+(i-1)*2,   nv%256)
    poke(a+2+(i-1)*2+1, flr(nv/256))
  end
end

-- write one music pattern: 4 bytes, one SFX index per channel
-- bit 7 (0x80) on a channel = stop/wrap flag after this pattern
function snd_pat(p, s0,s1,s2,s3)
  local a=0x3100+p*4
  poke(a,s0); poke(a+1,s1); poke(a+2,s2); poke(a+3,s3)
end

-- expand 8 note-events into 32-slot sequence (each event held 4 slots)
-- event = {pitch, vol, inst, fx}
function snd_seq(e8)
  local out={}
  for i=1,#e8 do
    local e=e8[i]
    for r=1,4 do out[#out+1]=snd_n(e[1],e[2],e[3],e[4]) end
  end
  return out
end

function init_music()
  -- === pattern 0: Am ===
  snd_sfx(0, snd_speed, snd_seq{                       -- bass A2, swell in/out
    {33,snd_vol,0,4},{33,snd_vol,0,0},{33,snd_vol,0,0},{33,snd_vol,0,0},
    {33,snd_vol,0,0},{33,snd_vol,0,0},{33,snd_vol,0,0},{33,snd_vol,0,5}})
  snd_sfx(1, snd_speed, snd_seq{                       -- pad A3 C4 E4 arpeggiate
    {45,snd_vol,5,4},{48,snd_vol,5,0},{52,snd_vol,5,0},{45,snd_vol,5,0},
    {48,snd_vol,5,0},{52,snd_vol,5,0},{45,snd_vol,5,0},{48,snd_vol-2,5,5}})
  snd_sfx(2, snd_speed, snd_seq{                       -- melody A4 -> E4 sparse
    {57,0,0,0},{57,snd_mel,0,0},{57,0,0,0},{57,0,0,0},
    {57,0,0,0},{52,snd_mel-1,0,0},{52,0,0,0},{52,0,0,5}})
  snd_sfx(3, snd_speed, snd_seq{                       -- shimmer B4 (1 hit)
    {59,0,0,0},{59,0,0,0},{59,0,0,0},{59,snd_shm,1,0},
    {59,0,0,0},{59,0,0,0},{59,0,0,0},{59,0,0,0}})

  -- === pattern 1: F (VI) ===
  snd_sfx(4, snd_speed, snd_seq{                       -- bass F2
    {29,snd_vol,0,4},{29,snd_vol,0,0},{29,snd_vol,0,0},{29,snd_vol,0,0},
    {29,snd_vol,0,0},{29,snd_vol,0,0},{29,snd_vol,0,0},{29,snd_vol,0,5}})
  snd_sfx(5, snd_speed, snd_seq{                       -- pad F3 A3 C4
    {41,snd_vol,5,4},{45,snd_vol,5,0},{48,snd_vol,5,0},{41,snd_vol,5,0},
    {45,snd_vol,5,0},{48,snd_vol,5,0},{41,snd_vol,5,0},{45,snd_vol-2,5,5}})
  snd_sfx(6, snd_speed, snd_seq{                       -- melody C5 -> F4
    {60,0,0,0},{60,snd_mel,0,0},{60,0,0,0},{53,snd_mel-1,0,0},
    {53,0,0,0},{53,0,0,0},{53,0,0,0},{53,0,0,5}})
  snd_sfx(7, snd_speed, snd_seq{                       -- shimmer A4
    {57,0,0,0},{57,0,0,0},{57,0,0,0},{57,0,0,0},
    {57,snd_shm,1,0},{57,0,0,0},{57,0,0,0},{57,0,0,0}})

  -- === pattern 2: G (VII) ===
  snd_sfx(8, snd_speed, snd_seq{                       -- bass G2
    {31,snd_vol,0,4},{31,snd_vol,0,0},{31,snd_vol,0,0},{31,snd_vol,0,0},
    {31,snd_vol,0,0},{31,snd_vol,0,0},{31,snd_vol,0,0},{31,snd_vol,0,5}})
  snd_sfx(9, snd_speed, snd_seq{                       -- pad G3 B3 D4
    {43,snd_vol,5,4},{47,snd_vol,5,0},{50,snd_vol,5,0},{43,snd_vol,5,0},
    {47,snd_vol,5,0},{50,snd_vol,5,0},{43,snd_vol,5,0},{47,snd_vol-2,5,5}})
  snd_sfx(10, snd_speed, snd_seq{                      -- melody D4 -> B4
    {50,0,0,0},{50,snd_mel,0,0},{50,0,0,0},{59,snd_mel,0,0},
    {59,0,0,0},{59,0,0,0},{59,0,0,0},{59,0,0,5}})
  snd_sfx(11, snd_speed, snd_seq{                      -- shimmer D5
    {62,0,0,0},{62,0,0,0},{62,0,0,0},{62,snd_shm,1,0},
    {62,0,0,0},{62,0,0,0},{62,0,0,0},{62,0,0,0}})

  -- === pattern 3: Em (v) -- stop bit on ch0 wraps loop ===
  snd_sfx(12, snd_speed, snd_seq{                      -- bass E2
    {28,snd_vol,0,4},{28,snd_vol,0,0},{28,snd_vol,0,0},{28,snd_vol,0,0},
    {28,snd_vol,0,0},{28,snd_vol,0,0},{28,snd_vol,0,0},{28,snd_vol,0,5}})
  snd_sfx(13, snd_speed, snd_seq{                      -- pad E3 G3 B3
    {40,snd_vol,5,4},{43,snd_vol,5,0},{47,snd_vol,5,0},{40,snd_vol,5,0},
    {43,snd_vol,5,0},{47,snd_vol,5,0},{40,snd_vol,5,0},{43,snd_vol-2,5,5}})
  snd_sfx(14, snd_speed, snd_seq{                      -- melody B3 -> E4
    {47,0,0,0},{47,snd_mel,0,0},{47,0,0,0},{52,snd_mel-1,0,0},
    {52,0,0,0},{52,0,0,0},{52,0,0,0},{52,0,0,5}})
  snd_sfx(15, snd_speed, snd_seq{                      -- shimmer G4
    {55,0,0,0},{55,0,0,0},{55,0,0,0},{55,0,0,0},
    {55,snd_shm,1,0},{55,0,0,0},{55,0,0,0},{55,0,0,0}})

  -- music patterns: ch0=bass ch1=pad ch2=mel ch3=shm
  -- pattern 3 ch0 gets 0x80 stop flag -> music(,1) loops back to 0
  snd_pat(0, 0, 1, 2, 3)
  snd_pat(1, 4, 5, 6, 7)
  snd_pat(2, 8, 9,10,11)
  snd_pat(3, bor(12,0x80), 13,14,15)

  -- self-check: first note of SFX0 must equal encoded A2 fade-in
  local expect = snd_n(33,snd_vol,0,4)
  assert(peek(0x3202)==expect%256 and peek(0x3203)==flr(expect/256), "snd: sfx0 encode mismatch")
end

function start_music()
  music(0,1)   -- pattern 0, loop flag set
end
