# Architecture

This document describes how the codebase is organized and the rules that keep
it extensible. It reflects what exists **today** (the foundation) and marks
future systems clearly.

## Layering

The project separates **domain/gameplay logic** from **presentation**:

- **Core services** (`core/`) — engine-level, cross-cutting singletons that
  persist for the whole session. Autoloaded.
- **Gameplay systems** (`gameplay/`, future) — combat, cards, items, map,
  death, progression. Plain classes with explicit dependencies, *not*
  autoloads. Testable without rendering.
- **Content** (`content/`, future) — data-driven definitions keyed by stable
  string ids. No logic, just data.
- **Presentation** (`scenes/`, `presentation/`) — scenes and UI. They *display
  state* and *send commands*; they do not contain game rules.

> Rule of thumb: if deleting all the UI would break a game rule, that rule is in
> the wrong place.

## Core services (autoloads)

Registered in `project.godot` `[autoload]`, initialized in this order:

| Singleton        | Script                                   | Responsibility |
|------------------|------------------------------------------|----------------|
| `Log`            | `core/logging/logger.gd`                 | Category + level structured logging (console + `user://logs/session.log`). |
| `EventBus`       | `core/events/game_event_bus.gd`          | Global signals for high-level state transitions only. |
| `RNG`            | `core/rng/rng_service.gd`                | Seeded, named random streams for reproducible runs. |
| `SaveManager`    | `core/save/save_manager.gd`              | Atomic, versioned save/load across profile / settings / run domains. |
| `ContentRegistry`| `core/content/content_registry.gd`       | Register + look up + validate data-driven content by id. |
| `Updater`        | `core/update/update_service.gd`          | Checks GitHub Releases for a newer build. |
| `SceneFlow`      | `core/scene_flow/scene_flow_manager.gd`  | The single place scenes are swapped. |
| `GameState`      | `core/state/game_state_manager.gd`       | Coarse top-level mode (BOOT / MAIN_MENU / HUB / RUN / DEATH). |
| `GameBootstrap`  | `core/bootstrap/game_bootstrap.gd`       | Orchestrates the boot sequence; called by the boot scene. |

**Autoload discipline:** only genuinely global, persistent services are
autoloaded. Local gameplay systems will take explicit dependencies (passed in),
not reach for singletons. This avoids the "everything is global" trap and keeps
systems unit-testable.

### Why the boot scene calls `GameBootstrap.boot()`

Autoloads' `_ready()` runs *before* the main scene is instantiated, so an
autoload must not change scenes during its own `_ready()`. Instead, the boot
scene (`scenes/boot/boot.gd`) drives startup: it calls `GameBootstrap.boot()`
(load + apply settings, warm the profile, validate content) and then asks
`SceneFlow` to go to the main menu.

## Testable-core pattern

Logic that benefits from unit tests lives in **plain classes** (`RefCounted`
with `class_name`) that can be constructed directly, with thin autoload wrappers
for global access:

- `SemVer` (static) — version comparison, used by `Updater`.
- `RngStream` — one deterministic stream; `RNG` manages a set of them.
- `TestCase` — base class for tests in `tests/unit/`.

This is why `tests/run_all.gd` can validate RNG determinism and version logic
without standing up the whole game.

## Determinism

All gameplay randomness must come from `RNG` streams derived from one master
seed — never the global `randi()/randf()`. Streams are independent, so
consuming loot randomness never perturbs combat randomness. The one sanctioned
source of true entropy is `RNG.fresh_seed()`, used only to pick a brand-new run
seed. See [DECISIONS.md](DECISIONS.md).

## Events vs. explicit calls

Use `EventBus` for a handful of high-level, many-listener transitions
(`boot_completed`, `scene_changed`, `game_state_changed`, `settings_changed`,
`update_check_completed`, `save_written`/`save_loaded`). Everything else uses
explicit signals/method calls between the specific systems involved. Avoid
routing local gameplay wiring through the global bus.

## Directory map

```
core/
  bootstrap/    boot orchestration
  content/      content registry
  events/       global event bus
  logging/      logger
  rng/          rng service + stream
  save/         save manager
  scene_flow/   scene navigation
  state/        game state manager
  update/       semver, update config, update service
  version.gd    single source of truth for the version
gameplay/       (future) combat, cards, items, map, death, progression, ...
content/        (future) data definitions
scenes/
  boot/         boot splash
  menus/        main menu
  (future)      combat/, map/, hub/, transitions/
presentation/   (future) themes, effects, audio, shared ui
tests/
  framework/    TestCase base
  unit/         unit tests
  run_all.gd    headless runner
tools/
  release/      release.ps1 (export + GitHub release)
  (future)      debug/, validation/
docs/           this documentation
```

## Coding standards (enforced by convention)

- Typed GDScript wherever practical.
- Small, focused functions and scenes; no giant manager scripts.
- Composition over deep inheritance.
- Stable **string ids** for expandable content; enums only for closed sets.
- Never swallow save or content errors — log them via `Log`.
- No game rules inside button callbacks.
