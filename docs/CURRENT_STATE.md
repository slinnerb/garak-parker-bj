# Current State

_Last updated: 2026-07-14 — Phase 3 combat engine (headless domain)._

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
- **Main menu** with a working **Check for Updates** button and version label.
  Gameplay buttons (New Life / Continue / Settings) still honestly disabled.
- **Release pipeline** — `tools/release/release.ps1` bumps the version, exports
  Windows, zips, and publishes a GitHub release. Update system verified
  end-to-end against **github.com/slinnerb/garak-parker-bj**.
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
- **Combat passed an adversarial review**: a multi-agent review confirmed 3 bugs
  (Fortified self-nullified via a hook/decay phase mismatch; defeat not latching
  on a start-of-turn damage-over-time; a "random" transform that wasn't). All
  fixed with regression tests. See [DECISIONS.md](DECISIONS.md).
- **Tests — 79 unit tests, all green** (exit 0): SemVer, RNG determinism, save
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

- **Combat has no UI yet** and isn't wired into a run/map flow — it's a
  headless domain engine (Phase 3b adds the scene). Inventory/attunement (the
  deck is currently built by listing card ids, not derived from items),
  map generation, and death/reincarnation are Phases 4–7.
- **Export templates not installed** (user deferred): producing the actual
  `.exe` needs the one-time ~900 MB Godot 4.7 template download; no GitHub
  release published yet.
- **No settings screen, no debug panel** yet.
- **Japanese/Norse universes** are unplayable samples by design (fixed order
  positions 2 and 3, `playable = false`).

## Immediate next task

**Phase 3b: combat UI** — a combat scene that renders `CombatState` (hand,
piles, HP/block/energy, enemy intents) and sends `play_card` / `end_turn`
commands, so a fight is playable on screen. Then **Phase 4** derives the deck
from attuned items (inventory/attunement) — the spine that connects items to
the combat deck.
