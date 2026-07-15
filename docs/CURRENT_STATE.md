# Current State

_Last updated: 2026-07-14 — Phase 4: your gear is your deck._

## What works today

- **Project boots cleanly** (verified headless): autoloads initialize,
  `GameBootstrap` loads **69 content definitions**, content validation passes,
  state transitions `BOOT → MAIN_MENU`, main menu loads with **zero errors**.
- **Core services** (all autoloaded):
  - `Log` — category/level logging to console + `user://logs/session.log`.
  - `EventBus` — global signals for high-level transitions.
  - `RNG` — deterministic named streams from a master seed.
  - `SaveManager` — atomic, versioned save/load; 3 domains; backups; corruption
    quarantine; crash recovery.
  - `ContentRegistry` — id-keyed register/lookup + per-definition and global
    cross-content validation (`validate_all`), `clear()` for tests/tools.
  - `Updater` — GitHub Releases update check with graceful error handling.
  - `SceneFlow`, `GameState`, `GameBootstrap`.
- **Phase 2 data model** — 13 definition classes on a shared `ContentDefinition`
  base (`from_dict` defensive parsing, `validate(registry)` problem reporting):
  cards + composable effects (14 effect kinds incl. conditional/repeat/nesting),
  items (9 categories, slot costs, granted cards, passives, curses, charges),
  enemies + weighted conditional intents, statuses (stacking/decay/hooks),
  universes (weights, unlock reqs, fixed-order positions), map node types, loot
  tables, difficulties, tattoos, memories, death adaptations, body archetypes.
- **Sample content (validates clean at boot)** — the vertical-slice Lovecraft
  set: 13 items, 15 cards (bidirectionally linked to items), 3 normal enemies +
  1 elite + 1 boss, 6 statuses, 3 loot tables, 3 universes (Lovecraft playable;
  Japanese/Norse samples at fixed order 1/2/3), 2 difficulties, 12 map node
  types, coastal_drifter archetype, 2 tattoos, 3 memories, 3 adaptations —
  loaded by `ContentLoader` at boot.
- **Main menu** with a clickable **version number** → an Updates & Version
  History panel: current build, Check for Updates, and the changelog parsed from
  the bundled `CHANGELOG.md` (offline-capable). The game **auto-checks on
  launch**; if a newer build exists it shows what changed and an **Update &
  Relaunch** that downloads the build, self-replaces via a helper, and restarts
  (`SelfUpdater`). Browser hand-off remains the fallback (editor/non-Windows/no
  asset). **Validated end to end**: a shipped **v0.1.0** build detected, downloaded,
  self-replaced, and relaunched into **v0.1.2** on its own, then correctly reported
  up-to-date. The version-history panel and changelog also render in the packaged
  build.
- **Shipped: v0.1.0 is a public, downloadable build.** Export templates are
  installed; `tools/release/release.ps1 -Version X.Y.Z` builds the self-contained
  Windows exe, zips it, and publishes a GitHub release with notes pulled from
  `CHANGELOG.md`. **github.com/slinnerb/garak-parker-bj/releases/tag/v0.1.0** is
  live (36 MB zip); the exe boots clean.
- **Phase 3 combat engine (headless, domain-level)** — a full turn-based fight
  runs with no scene: `CombatState` orchestrates the loop (start → player
  draw/play/end → enemies act on telegraphed intents → repeat) over
  `PlayerState`/`EnemyState`/`Combatant`, the four card piles, and
  `CardInstance`. `EffectExecutor` runs all 14 composable effect kinds;
  `StatusEngine` interprets status data (stacking, decay, damage modifiers, turn
  hooks like Burning/Regeneration/Fortified/Hallucinating); `IntentSelector` is
  a deterministic weighted/sequence enemy AI honoring HP/first-turn/cooldown/
  max-uses conditions. Damage runs the full outgoing×incoming×resistance chain
  through block; victory/defeat latch (defeat wins ties). Not yet wired to a
  combat scene or to run/map flow.
- **Items are the deck (Phase 4)**: `Inventory` holds what the body carries;
  `Attunement` is the slot-limited loadout that *generates* the combat deck
  (attune/remove rebuilds it; multi-slot items; cursed items resist removal;
  consumables give one card per charge; passive relics collected). The
  **attunement screen** (Main Menu → New Life) shows carried items and a live
  deck preview that updates as you toggle; "Begin the Fight" hands the loadout
  to combat via `CombatRequest`. Verified: a custom loadout reaches combat as
  the real deck. Not yet: finding items in a run (needs the map), mid-combat
  deck changes, and applying relic passive modifiers.
- **Combat passed an adversarial review**: a multi-agent review confirmed 3 bugs
  (Fortified self-nullified via a hook/decay phase mismatch; defeat not latching
  on a start-of-turn damage-over-time; a "random" transform that wasn't). All
  fixed with regression tests. See [DECISIONS.md](DECISIONS.md).
- **Tests — 102 unit tests, all green** (exit 0): SemVer, RNG determinism, save
  round-trip/backup/corruption/merge, version wiring, definition parsing +
  validation rules, registry cross-checks (incl. bidirectional card↔item link
  and surfaced load failures), full sample-content validation, and the combat
  engine (integration against real content, status mechanics, intent gating,
  full-fight determinism).
- **Adversarial review pass complete**: a multi-agent review found and confirmed
  7 validation-hardening issues (over-permissive coercion letting fractional/
  non-int params and empty-string references validate clean; card↔item links
  only existence-checked; dropped definitions not surfacing at boot). All 7 are
  fixed with regression tests. See [DECISIONS.md](DECISIONS.md).

## Verified commands

```powershell
# Boot headlessly (logs the full startup, then quits)
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --quit-after 150

# Run tests (exit 0 = all pass)
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --script res://tests/run_all.gd
```

## Known limitations / not yet built

- **No run structure yet.** Combat is playable (Main Menu → New Life → attune →
  fight), and the deck is now derived from a real `Attunement`, but it isn't
  strung into a *run*: there's no map, and the demo's carried items are a
  stand-in for scavenging until the map hands out loot. Map generation is
  Phase 5; death/reincarnation is Phase 6.
- **No turn animation**: enemy turns resolve instantly; the log shows the
  sequence. Stepped/animated resolution is a later polish pass.
- **Relic passive modifiers** are collected but not yet applied in combat.
- **No settings screen, no debug panel** yet.
- **Japanese/Norse universes** are unplayable samples by design (fixed order
  positions 2 and 3, `playable = false`).

## Immediate next task

**Phase 5: the run map.** A seeded, branching node map (combat / elite / item
search / event / rest / shrine / boss) that strings encounters into an actual
life, replacing the current direct-to-demo entry. This is where the loadout
stops being a fixed demo set and starts filling from items found along the way,
and where the fixed opening universe (Lovecraftian Coast) gets a real shape.
(Then Phase 6 — death & reincarnation — closes the core loop.)
