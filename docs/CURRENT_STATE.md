# Current State

_Last updated: 2026-07-15 — **v0.2.0 shipped**: the full loop (map → fights →
death → recall → reincarnation) is now a public, auto-updating build. Live →
die → remember → adapt → reincarnate stronger._

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
- **Shipped: v0.2.0 is the public, downloadable build** — the first release with
  the whole loop (map → in-run fights → death → Moment of Recall →
  reincarnation). `tools/release/release.ps1 -Version X.Y.Z` builds the
  self-contained Windows exe, verifies it reports the right version, zips it, and
  publishes a GitHub release with notes pulled from `CHANGELOG.md`.
  **github.com/slinnerb/garak-parker-bj/releases/tag/v0.2.0** is live (38 MB
  zip); older builds auto-update into it. (Note: v0.1.x builds could reach the
  main menu but "New Life" led to a not-yet-built screen — v0.2.0 is the first
  build where a life is actually playable end to end.)
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
- **The death loop is playable (Phase 6)**: dying in a run leads to the
  **Moment of Recall** — the death report (killer → cause tags, distance,
  cargo), Remembrance earned, and a choice among the adaptations that death
  made eligible (data-driven trigger matching). The choice is recorded on the
  profile atomically (`Soul`), the second death unlocks the Memory Tattoo
  system, and **Reincarnate** begins the next life: universe chosen by
  `UniverseSelector` (fixed order 1–3, then seeded weighted with no-repeat/
  recency/unlock/death-cause rules; falls back to a playable universe), life
  count and history recorded, and the soul's adaptations ride into every fight
  as real combat modifiers (e.g. the boss-scar makes you hit bosses harder —
  proven by a same-seed test). The next life is measurably stronger.
- **The run map is the hub of a life (Phase 5)**: **New Life → a seeded,
  branching map** (`MapGenerator`/`RunMap` — a validated start-to-boss DAG,
  reproducible from the run seed) → travel node to node toward the boss.
  `RunState`/`RunManager` hold the life: HP carries between fights, items found
  at nodes are attuned into the deck, and each fight is built from the run
  (`RunCombat`: your deck, your HP, an enemy from the universe pool by node
  type). Combat feeds its outcome back (surviving HP, or death); beating the
  boss completes the run. Rest/shrine heal, item-search/treasure offer items,
  events give a choice. (Non-combat nodes are intentionally light for now; runs
  aren't saved/resumable yet.)
- **Combat passed an adversarial review**: a multi-agent review confirmed 3 bugs
  (Fortified self-nullified via a hook/decay phase mismatch; defeat not latching
  on a start-of-turn damage-over-time; a "random" transform that wasn't). All
  fixed with regression tests. See [DECISIONS.md](DECISIONS.md).
- **Tests — 128 unit tests, all green** (exit 0): SemVer, RNG determinism, save
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

- **Memory Tattoos unlock but can't be chosen yet** (the system opens at the
  2nd death; selection/effects/UI are Phase 7). Memories and the between-life
  hub are also still ahead.
- **Non-combat encounters are light**, and an in-progress run can't be saved and
  resumed yet. Winning a run returns to the menu (no run summary screen).
- **Japanese/Norse are selectable by fate but not playable** — the run falls
  back to the coast with a log note until they have content.
- **No turn animation**: enemy turns resolve instantly; the log shows the
  sequence. Stepped/animated resolution is a later polish pass.
- **Relic passive modifiers** are collected but not yet applied in combat.
- **No settings screen, no debug panel** yet.
- **Japanese/Norse universes** are unplayable samples by design (fixed order
  positions 2 and 3, `playable = false`).

## Immediate next task

**Direction confirmed:** combat pivots from turn-based to **real-time, top-down
action** (*Hades*-style) with the attuned loadout as your ability set. The whole
roguelite shell is kept. See [GAME_VISION.md](GAME_VISION.md) and the **Action
Combat Arc** in [ROADMAP.md](ROADMAP.md).

- **Phase A — Action + freeze core: first slice built** ✅ (not yet in a public
  build). A top-down arena (**Action Prototype (dev)** on the main menu) with a
  spectral player (move, dodge with i-frames, cursor-aimed spirit bolts), the
  **freeze-to-plan** slow-time mechanic (pure, unit-tested `FocusMeter` — one
  burst per press, exposed recharge window, world slows while the player stays
  full-speed), and The Drowned One (telegraphed melee + pursuit, slowed by
  focus). Win/lose overlay. Verified headless (drive + screenshots); 139 tests.
- **Phase B — Loadout as your hand: first slice built** ✅ (not yet in a public
  build). During the freeze you queue cards from a hand (keys 1-4) and unleash
  them in a burst on release; each goes on cooldown. Four cards resolve in real
  time — Wailing Bolt (projectile), Spirit Lash (melee), Drowned Ward (shield),
  Rip Tide (lunge + hit) — with player shield/dash. Pure, unit-tested `ActionCard`
  + `CardLoadout`; hand HUD with cooldown shading + queue-order badges. Verified
  headless (queue → unleash → damage/shield/cooldown) + screenshots. **143 tests.**
- **Next on the action arc**: hands-on feel tuning; manual targeting; then source
  the hand from the real **Attunement** (items→deck) instead of a default hand,
  and Phase C (map combat nodes launch action rooms).
- The turn-based v0.2.0 build stays the public playable version during the
  rebuild. (Phase 7 Memory Tattoos and richer non-combat nodes remain valuable
  and can slot in alongside the action arc.)
