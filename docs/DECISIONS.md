# Decisions Log

Reasonable assumptions and deliberate choices, recorded so future work doesn't
re-litigate them. Newest first.

## 2026-07-14 — Phase 3 combat engine

### Combat is a headless domain engine; UI observes it (built later)
All combat rules live in plain `class_name` RefCounted classes under
`gameplay/combat/` (`CombatState` orchestrator + `Combatant`/`PlayerState`/
`EnemyState`, `CardInstance`, and the `StatusEngine`/`EffectExecutor`/
`IntentSelector` subsystems). No autoloads, no nodes: the content provider and
RNG stream are injected. This is why the whole turn loop is unit-testable
(master prompt §10–11 require enemy behavior testable without rendering). The
combat scene (Phase 3b) will render `CombatState` and send `play_card`/
`end_player_turn` — it will hold no rules.

### One effect executor; no per-card scripts
`EffectExecutor` interprets all 14 `CardEffectDefinition` kinds; containers
(conditional/repeat/random_target) recurse. Cards are pure data composing these
atoms, per the §5/§10 architecture rule. Card conditions are still open
(`chance_pct` is the only one content uses); the executor evaluates a small set
and fails closed on unknown keys until Phase 6 formalizes the vocabulary.

### Combat rule calls made explicit (surfaced during implementation)
- **Damage chain**: `outgoing(attacker) × incoming(defender) × type-resistance
  (enemies only) → round → block`, recomputed per hit so multi-hit interacts
  correctly with block and mid-sequence death. Players have no damage-type
  resistances yet (adaptations add them in Phase 6).
- **Damage-over-time ignores block** (Burning), matching the genre convention;
  direct attacks go through block.
- **Defeat wins ties**: if the player and the last enemy would both die on one
  exchange, the outcome is defeat (permadeath is the point — see
  [[garak-parker-roguelike]] / GAME_VISION).
- **Status/curse cards are unplayable** in the engine (`can_play` refuses them),
  making the "Unplayable" flavor real without a new data flag.

### Status hook phase must match decay phase (Fortified fix)
An adversarial review of combat confirmed `fortified` granted zero block: its
block hook fires at `on_turn_start` but decay was `turn_end`, so a 1-stack
application (all shipped content) decayed before the hook could ever run. Fixed
by aligning decay to the hook phase (`turn_start`): the hook grants block at
turn start, then the stack fades. General rule for status content: a status
whose only hook is `on_turn_start` must not decay at `turn_end` (and vice
versa), or it self-nullifies. Regression test:
`test_combat.test_fortified_grants_block_next_turn` drives this through the real
turn loop (not the hook in isolation, which is what hid the bug originally).

### Terminal outcome is checked after every hook, including turn start
The same review found `start_player_turn` ran the player's `on_turn_start` hooks
without re-checking the outcome, so a lethal start-of-turn damage-over-time
status could leave the player "dead but still acting" (defeat never latched,
`can_play` still returned true). Every hook/damage site now calls
`_check_outcome()`; `can_play` also guards on `player.is_alive()`. Regression:
`test_start_of_turn_dot_latches_defeat`.

## 2026-07-13 — Genre confirmation + Phase 2 data model

### Genre: roguelite, confirmed by the user — plus "fate-shaping"
The user explicitly confirmed the roguelite direction (true permadeath + seeded
random generation, with soul meta-progression carrying between lives), and
added a requirement: soul progression must include **earning control over
reincarnation** — from nudging universe selection weights, to rerolling/vetoing
at the Moment of Recall, to eventually choosing the next universe outright, and
widening in-run path choices. Captured in GAME_VISION.md ("Fate-shaping") and
ROADMAP Phases 5–6. The data model already carries the hooks (universe
`base_weight` / `death_cause_weights` / `tattoo_weights` /
`unlock_requirements`, tattoo function `alter_universe_weighting`).

### Definitions: plain `RefCounted` classes + dictionary content, not `.tres`
Content definitions are pure-data `class_name` classes extending a shared
`ContentDefinition` base (`from_dict()` defensive parsing + `validate(registry)`
returning problem strings). Authored content lives in plain GDScript data
scripts (`content/**` — `static content_type()` + `static data()`), registered
by `ContentLoader` at boot. Chosen over Godot `Resource`/`.tres` files because:
headless-testable without the editor, git-diff-friendly, no inspector round
trips, and trivially migratable to JSON later for modding. Validation is the
safety net the inspector would have been.

### Validation is strict about types: reject, don't coerce, at validate time
An adversarial review found a class of bug where `validate()` checked an
`int()`-coerced *copy* of a param while `from_dict()` stored the raw value — so
`{"amount": "abc"}` (→ 0) or `{"amount": 7.5}` (→ 7) validated clean but shipped
wrong data downstream. Fixed everywhere numeric params are checked (card
effects, loot amounts): validation now requires a real `int` and reports
non-int values instead of silently coercing. Same principle for empty strings in
required id lists — a shared `ContentDefinition._check_id_list` reports empty
entries (which `_check_ref` would otherwise skip as "absent optional ref").

### Card↔item link is validated in both directions (registry-level)
Each definition only checks its own outgoing reference resolves; only the
registry sees both ends. `_validate_card_item_links` confirms a card's
`source_item_id` item lists that card in `granted_card_ids` and vice versa, so a
card sourced to the wrong (but real) item can't pass — enforcing the "cards come
from things" invariant that content comments already claimed.

### Dropped content fails the boot gate (no silent loss)
A definition dropped at load time (empty/duplicate id) never runs `validate()`,
so boot used to report "validation passed" while content was silently missing.
`ContentLoader` now records such failures via `ContentRegistry.record_load_problem`,
and `validate_all()` surfaces them — dirty data fails loudly, per §17 of the brief.

### Validation philosophy: definitions self-validate, registry cross-validates
Each definition validates its own fields and outgoing references (registry
passed as a parameter, null-safe for unit tests); `ContentRegistry.validate_all`
adds global checks no single definition can see (fixed-order universe positions
1–3 exactly once, at least one playable universe, at least one body archetype).
Boot fails loudly in dev builds when content is invalid.

## 2026-07-12 — Foundation kickoff

### Engine: Godot 4.7 stable, GDScript
Godot 4.7 is already installed on this machine
(`C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe`) and matches the
master prompt's recommendation. GDScript (not C#/Mono) keeps the toolchain
simple and needs no dotnet build step, even though dotnet 10 is available.

### Renderer: GL Compatibility
Chosen over Forward+ for maximum hardware compatibility on a friend's PC. A 2D
deckbuilder does not need the advanced renderer. Set in
`project.godot` (`rendering/rendering_method="gl_compatibility"`).

### Update mechanism: GitHub Releases, browser hand-off (not silent auto-update)
The `gh` CLI is authenticated (user `slinnerb`, `repo`+`workflow` scopes), so
GitHub Releases is free and simple. Chosen distribution: a **public** repo so a
friend can download release assets with no login. The in-game "Check for
Updates" button queries the Releases API and, if a newer version exists, opens
the releases page in the browser. We deliberately do **not** silently download
and self-replace the running `.exe` — that is fragile on Windows (can't
overwrite a running executable without a relaunch helper). Browser hand-off is
reliable and safe; true auto-update can be added later.

The updater reads owner/repo from `core/update/update_config.gd`
(`GITHUB_REPO` is intentionally empty until the repo is created), and reports a
clean "not set up yet" state instead of making doomed network calls pre-launch.

### Scope of this pass: foundation only
Per the user's choice, this pass builds the engine shell, core services, save
system, update system, main menu, tests, and release pipeline — **not** combat,
cards, items, map, or death yet. This proves the shell + update loop before
gameplay is layered on. See [ROADMAP.md](ROADMAP.md).

### Version single-source-of-truth: `project.godot`
`GameVersion.current()` reads `application/config/version` from ProjectSettings,
so there is exactly one place to bump (the release script edits it). A test
(`test_version_matches_project_setting`) guards this wiring.

### RNG: named streams from one master seed, no global randomness
`RNG.stream(name)` derives an independent `RngStream` from the master seed via a
deterministic FNV-style mix. Gameplay must never call global `randi()/randf()`.
`RNG.fresh_seed()` is the single sanctioned entropy source (for choosing a new
run seed). This keeps runs reproducible from a seed.

### Testable core over singletons
Logic worth testing lives in plain `class_name` classes (`SemVer`, `RngStream`)
with thin autoload wrappers. Confirmed that Godot autoloads *are* available when
running `--script res://tests/run_all.gd`, but tests still prefer constructing
classes directly for isolation.

### Project / game title
Working title "Reincarnation Roguelike" (folder is `Garak_Parker_BJ`, a
codename). The display name lives in `project.godot`; changing it later is a
one-line edit and does not affect save paths beyond the `user://` folder name.
