# Roadmap

Phased plan. **Do not begin mass content production until the vertical slice is
stable.** Checkboxes reflect reality.

## Phase 0 — Audit & documentation ✅
- [x] Inspect machine + tooling (Godot 4.7, git, gh, dotnet, node found)
- [x] Establish engine direction (Godot 4.7 GDScript, GL Compatibility)
- [x] Create all docs (README + docs/*)

## Phase 1 — Project foundation ✅
- [x] Directory structure
- [x] Autoload services (Log, EventBus, RNG, SaveManager, ContentRegistry,
      SceneFlow, GameState, GameBootstrap, Updater)
- [x] Boot scene + scene flow
- [x] Main menu with working **Check for Updates**
- [x] Save system (atomic, versioned, 3 domains, backups, corruption handling)
- [x] Headless test runner + foundation tests (all green)
- [x] Release pipeline (`tools/release/release.ps1`)

## Phase 1.5 — Distribution hookup (next)
- [ ] Create public GitHub repo; set `GITHUB_REPO` in `update_config.gd`
- [ ] Push code; install export templates; cut a first `v0.1.0` release
- [ ] Verify end-to-end: an older local build sees the new release
- [ ] Settings screen (audio/video/accessibility) wired to `SaveManager`
- [ ] Debug panel scaffold (dev-only)

## Phase 2 — Data model
- [ ] `CardDefinition`, `CardEffectDefinition` (composable effects)
- [ ] `ItemDefinition` (categories, slot cost, granted cards, passives)
- [ ] `EnemyDefinition`, `EnemyIntentDefinition`, `StatusEffectDefinition`
- [ ] `UniverseDefinition` (Lovecraft full; Japanese/Norse sample)
- [ ] `MemoryDefinition`, `TattooDefinition`, `DeathAdaptationDefinition`
- [ ] Content validation tooling (duplicates, missing refs, empty fields)

## Phase 3 — Combat
- [ ] Player + enemy state (domain-level, headless-testable)
- [ ] Deck / hand / draw / discard / exhaust
- [ ] Card execution via reusable effects
- [ ] Status effects, buffs/debuffs
- [ ] Enemy intents (deterministic), victory/defeat
- [ ] Combat UI (display state, send commands)

## Phase 4 — Item & deck integration
- [ ] Inventory + attunement slots (6–8, multi-slot items)
- [ ] **Deck derived from equipped items** (equip/remove/upgrade/break/consume)
- [ ] Item-search encounter, item rewards

## Phase 5 — Run structure
- [ ] Seeded, validated branching map generator (logical data first)
- [ ] Node traversal + encounters + rewards
- [ ] Rest / shrine, elite path, boss

## Phase 6 — Death & reincarnation
- [ ] Death report (cause, universe, distance, items, choices, damage types)
- [ ] Cause-of-death → adaptation eligibility (data-driven)
- [ ] Moment of Recall + adaptation selection
- [ ] Meta-progression persistence; clear body state; increment life
- [ ] Fixed universe order (Lovecraft → Japanese → Norse), then seeded weighted

## Phase 7 — Tattoo system
- [ ] Unlock after 2nd death; 1 slot → up to 3
- [ ] Tattoo selection, effects, persistence, basic UI
- [ ] Universe-specific display hooks

## Phase 8 — Save reliability hardening
- [x] Atomic writes, versioning, backups, corruption handling (baseline done)
- [ ] Migration path exercised with a real v1→v2 change
- [ ] Debug reset tools (run vs profile, independent)

## Phase 9 — Vertical-slice completion
- [ ] One fully playable Lovecraftian Coast run, elite + boss
- [ ] Full death loop → measurably stronger next life
- [ ] Tattoo unlock demonstration + run summary
- [ ] Debug simulate-first/second-death options

## Phase 10 — Hardening
- [ ] Expand automated tests to every core system in §20 of the master prompt
- [ ] Content validation pass; bug fixing; perf + architecture review
- [ ] Keep docs in sync with implementation
