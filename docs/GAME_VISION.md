# Game Vision

## Elevator pitch

A single-player **top-down action roguelite** about **death, reincarnation, and
the memory a soul carries between lives** — *Hades*-style real-time combat with a
deckbuilder's soul. Every run is an entire life in a different mythological
universe. You fight in real time — dodging and repositioning — then
**bend time to a crawl to plan the cards your soul has equipped**: part *Hades*
reflex, part *Slay the Spire* tactics. You survive as long as you can. Then you
die, for real, and the next life begins a little stronger in ways the new body
does not understand.

## The core fantasy

> While alive, the character forgets. At death, the soul remembers. Upon
> reincarnation, conscious memories disappear again.

The player should always feel the tension:

> "I want to survive longer — but even this death will teach my next life
> something."

## The larger arc — Spirit → Bones → Flesh

The whole game is one soul **reassembling its own existence** in three phases,
each a step back toward being whole. Full detail in **[STORY.md](STORY.md)**.

1. **Raise That Specter (Spirit).** You begin a disembodied ghost in the depths of
   an afterlife. Escape, learn to survive as a spectre, travel the realms, and
   gather fragments of why your soul refuses to disappear.
2. **Roll the Bones (Bones).** Recover your scattered skeleton across the realms;
   each bone permanently unlocks movement, slots, health, or abilities as your
   body reconstructs, and the mystery of your death deepens.
3. **Ashes to Ashes (Flesh).** Reach the living world, restore your flesh, learn
   the complete truth of your death, and face a final choice about what you become.

The realms you travel are the **mythological universes** (Lovecraftian, Japanese,
Norse, and future Fey / underworld / purgatorial worlds), connected by your death
and fragmented identity. The roguelite death loop is the texture *within* this
arc — a ghost can't truly die; each death casts the unfinished soul back to try
again, stronger. This may ship as one game, three campaigns, or a trilogy.

## Pillars

1. **Death is the central system, not a game-over.** Dying records how and why
   you died, grants permanent progression, shows the *Moment of Recall*, and
   seeds the next life.
2. **Cards come from things, not from thin air.** Every ability originates from a
   physical item you found, equipped, remembered, or manifested this life. In
   combat, your attuned cards are the **plays you queue when you freeze time** —
   your loadout *is* your hand. Equipment, deckbuilding, and your combat kit are
   three views of one system.
3. **Two kinds of progress, strictly separated.** The *body* (items, deck, gold,
   map progress) is lost at death. The *soul* (adaptations, memories, tattoos,
   Mirror upgrades, unlocks) persists — but grants **options and knowledge, not
   raw power creep**.
4. **Restrained cosmic horror threading distinct mythologies.** Each universe
   keeps its own recognizable mythology; a subtle wrongness connects them (the
   same symbol in unrelated cultures, NPCs recognizing a soul they've never met,
   reflections of previous bodies).

## How it plays — combat & controls

Combat fuses **real-time action (Hades)** with **turn-based card tactics (Slay
the Spire)** through a *freeze-to-plan* mechanic — you feel both at once.

**Perspective.** Top-down 2D, Hades-style: an overhead view of arena rooms with
free 8-directional movement. You dodge, kite, and reposition around enemies in
real time. (Top-down 2D over isometric 3D is a deliberate, solo-sustainable
choice that still delivers the Hades feel.)

**Real-time layer.** You always have free **movement** and a **dodge/dash** with
i-frames (and, by default, a light basic attack). Enemies move and telegraph
their attacks in real time — spacing and timing keep you alive moment to moment.

**Freeze-to-plan layer.** Press a button and **time slows to a crawl**. Your hand
— the cards from your attuned loadout — fans out; you **queue one or more plays**
(target enemies/positions), spending a **planning meter**. Release, and time
snaps back as the queued abilities execute in a burst. The meter then **refills
over real time**, so a big plan leaves you exposed until it recharges: the core
risk/reward. Deckcraft happens in prep (which items to carry, which to attune);
the *decisions* happen in the freeze; the *dodging* happens live. Cards are
loadout-based (no random draw) and go on cooldown after use.

**The horror hook.** The freeze is the character's mind cracking too far open —
perceiving more than a mind should, time distending around the dread. That's
*why* it's limited: stare too long into the abyss and you are defenceless in it.
Your Attunement screen is the loadout screen.

**Weapon / aspect archetypes.** Distinct starting kits — like Hades' weapons —
change how you fight from the very first room: a different base attack, a
different rhythm, and different starting cards. The current `coastal_drifter`
body archetype is the first of these; more become unlockable soul options.

**Mid-run boons.** Between rooms you choose one of a few blessings that modify
your equipped abilities for the rest of the run ("your dash leaves fire in its
wake," "strikes chain to a second target," "every third ability is free"). Boons
stack into run-defining builds — the engine of Hades' replay variety — and are
delivered through the map's shrine / event / merchant nodes.

## The run — a single life

**New Life → a seeded, branching map** of the current universe. You travel node
to node toward the boss, choosing your path: fights, elites, item-searches,
treasure, merchants, shrines, events, and a guaranteed rest before the finale.
Your HP carries between rooms; the enemy you face depends on the node you step
into; the last node is a boss. Beat the boss and the run is complete — or fall,
and the death loop begins.

## Death, memory & reincarnation

Dying leads to the **Moment of Recall**: a report of *how* this life ended
(killer → cause tags like drowning or burning, distance travelled, elites
felled, cargo carried), the **Remembrance** the soul keeps, and a choice among
the **adaptations** that this specific death unlocked. Choose what to carry, then
**Reincarnate** into the next life — a new body, in a universe chosen by fate,
measurably stronger in ways it doesn't consciously understand.

### Between lives — the hub (Hades-style)

The Moment of Recall grows from a single screen into a **place between lives**: a
hub where recurring characters react to your deaths, the story advances across
runs, and death reads as narrative rather than a reset. This is where you spend
what the soul has earned:

- **The Mirror — a meta-upgrade tree.** Spend **Remembrance** on persistent
  upgrades (more HP, an extra dodge, stronger starting loadouts, wider fate
  control), layered on top of the death-driven adaptations. Permanent *options*,
  never trivializing power creep.
- **Adaptations & tattoos.** The death-shaped upgrades and (from the second
  death) Memory Tattoos continue to accrue here.

## Universe progression

The first three lives are a fixed on-ramp:

1. **Lovecraftian Coast** — a flooded, failing coastal town. Teaches the loop.
2. **Japanese Mythos** — haunted feudal Japan. Unlocks the Memory Tattoo system
   after the second death.
3. **Norse Mythos** — a frozen, corrupted Ragnarök.

From life four onward, universe selection becomes **weighted and seeded random**
(no repeats back-to-back, prefers unseen universes, influenced by cause of death
and active tattoos). Future universes (Gothic Europe, Egypt, Celtic, Slavic,
Greek, Mesoamerican, Victorian occult, prehistoric) plug in as data.

### Fate-shaping: earning control over reincarnation

A core soul-progression axis: the player gradually *earns* influence over where
and how they reincarnate. Control is the reward.

1. **Nudge** (early) — adaptations and tattoos multiply universe selection
   weights; the soul drifts toward familiar mythologies.
2. **Reroll / veto** (mid) — at the Moment of Recall, spend Remembrance to
   reroll the destined universe, or exclude one from the draw.
3. **Choice** (late) — outright pick the next universe from those unlocked. May
   be limited-use or cost Remembrance so randomness stays the default texture.

The same idea applies within a life: **path-range upgrades** widen the run map —
more branch options at forks, revealed node types further ahead, and eventually a
choice of starting region when a life begins. Narratively this is the soul
learning to steer the current between lives; mechanically every step stays seeded
and deterministic.

## Where the project is — and where combat is going

**Shipped so far (v0.2.0):** the *entire loop* is playable end to end — attune
items into a loadout, travel the branching map, fight, hit an elite and a boss,
die, read the Moment of Recall, pick an adaptation, and reincarnate measurably
stronger, with Memory Tattoos unlocking on the second death.

**Combat today is turn-based (Slay-the-Spire-style).** That engine was the
scaffold that *proved every surrounding system* — the item→deck pipeline, the
map, the death loop, the reincarnation math — cheaply and with full test
coverage. The next major arc **replaces it with the real-time + freeze-to-plan
hybrid combat described above**, reusing the entire roguelite shell unchanged.
The turn-based build stays playable while the action combat is built.

See [CURRENT_STATE.md](CURRENT_STATE.md) and [ROADMAP.md](ROADMAP.md).

## Non-goals for now

- No mass content production before the action loop is proven.
- No permanent flat stat boosts that trivialize future runs.
- No paid assets or heavy plugins; solo-sustainable scope (top-down 2D, no 3D
  pipeline).
