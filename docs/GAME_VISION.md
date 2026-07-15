# Game Vision

## Elevator pitch

A single-player roguelike deckbuilder about **death, reincarnation, and the
memory a soul carries between lives**. Every run is an entire life in a
different mythological universe. You survive as long as you can — then you die,
for real, and the next life begins a little stronger in ways the new body does
not understand.

## The core fantasy

> While alive, the character forgets. At death, the soul remembers. Upon
> reincarnation, conscious memories disappear again.

The player should always feel the tension:

> "I want to survive longer — but even this death will teach my next life
> something."

## Pillars

1. **Death is the central system, not a game-over.** Dying records how and why
   you died, grants permanent progression, shows the *Moment of Recall*, and
   seeds the next life.
2. **Cards come from things, not from thin air.** Every card originates from a
   physical item you found, equipped, remembered, or manifested this life.
   Equipment and deckbuilding are two views of one system.
3. **Two kinds of progress, strictly separated.** The *body* (items, deck,
   gold, map progress) is lost at death. The *soul* (adaptations, memories,
   tattoos, unlocks) persists — but grants **options and knowledge, not raw
   power creep**.
4. **Restrained cosmic horror threading distinct mythologies.** Each universe
   keeps its own recognizable mythology; a subtle wrongness connects them (the
   same symbol in unrelated cultures, NPCs recognizing a soul they've never
   met, reflections of previous bodies).

## Universe progression

The first three lives are a fixed on-ramp:

1. **Lovecraftian Coast** — a flooded, failing coastal town. Teaches the loop.
2. **Japanese Mythos** — haunted feudal Japan. Unlocks the Memory Tattoo system
   after the second death.
3. **Norse Mythos** — a frozen, corrupted Ragnarök.

From life four onward, universe selection becomes **weighted and seeded random**
(no repeats back-to-back, prefers unseen universes, influenced by cause of
death and active tattoos). Future universes (Gothic Europe, Egypt, Celtic,
Slavic, Greek, Mesoamerican, Victorian occult, prehistoric) plug in as data.

### Fate-shaping: earning control over reincarnation

A core soul-progression axis: the player gradually *earns* influence over where
and how they reincarnate. Control is the reward.

1. **Nudge** (early) — adaptations and tattoos multiply universe selection
   weights; the soul drifts toward familiar mythologies.
2. **Reroll / veto** (mid) — at the Moment of Recall, spend Remembrance to
   reroll the destined universe, or exclude one from the draw.
3. **Choice** (late) — outright pick the next universe from those unlocked
   ("this death I choose the Lovecraft coast; next death, the Japanese
   mythos"). May be limited-use or cost Remembrance so randomness stays the
   default texture.

The same idea applies within a life: **path-range upgrades** widen the run map
— more branch options at forks, revealed node types further ahead, and
eventually a choice of starting region when a life begins. Narratively this is
the soul learning to steer the current between lives; mechanically every step
stays seeded and deterministic.

## What the vertical slice will prove

One complete, playable loop in the Lovecraftian Coast: explore → find items →
build a deck → fight → hit an elite and a boss → die → record cause of death →
Moment of Recall → pick one adaptation → reincarnate measurably stronger, with
Memory Tattoos unlocking on the second death.

**Built so far** (v0.1.0): the middle of that loop — attune items into a deck,
and fight a turn-based combat to a win/loss. **Still to close the loop:** the
run map (explore → elite → boss) and death → Moment of Recall → reincarnation.
See [CURRENT_STATE.md](CURRENT_STATE.md) and [ROADMAP.md](ROADMAP.md).

## Non-goals for now

- No mass content production before the loop is proven.
- No permanent flat stat boosts that trivialize future runs.
- No paid assets or heavy plugins.
