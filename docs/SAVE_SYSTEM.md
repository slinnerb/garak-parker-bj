# Save System

Implemented in `core/save/save_manager.gd` (autoload `SaveManager`). Designed
early and on purpose, because a save system retrofitted late is a rewrite.

## Domains

Three independent files with different lifetimes. They are separate so a run
never risks the permanent profile, and settings are isolated from both.

| Domain     | File                         | Lifetime | Holds |
|------------|------------------------------|----------|-------|
| `profile`  | `user://saves/profile.json`  | Permanent (survives death) | Soul progression: soul level, remembrance, life/death counts, tattoo unlock state + slots, unlocked universes/items, adaptations, memories, tattoos, lore, stats. |
| `settings` | `user://saves/settings.json` | Permanent | Audio, video, accessibility, text speed, screen shake, reduced motion. |
| `run`      | `user://saves/run.json`      | Current life only; wiped on death | Universe, seed, current map node, body stats, equipped items, deck, inventory, health, run currency, modifiers. `{}` means no active run. |

On Windows the `user://` root resolves to:
`%APPDATA%\Godot\app_userdata\Reincarnation Roguelike\saves\`.

## File format

Each file is a JSON envelope:

```json
{
  "save_version": 1,
  "domain": "profile",
  "data": { ... }
}
```

`data` shapes come from `SaveManager.default_data(domain)`; see that function
for the authoritative current fields.

## Reliability

- **Versioned.** `SAVE_VERSION` is stamped in every file. Loading a file from an
  *older* version runs `_migrate()`; a file from a *newer* version is refused
  (we use in-memory defaults rather than downgrade/corrupt the real save).
- **Atomic-ish writes.** Writes go to `X.json.tmp`, then the previous good file
  is copied to `X.json.bak`, the old file removed, and the tmp renamed into
  place. A crash mid-write can never destroy the last good save.
- **Crash recovery.** If a load finds a `.tmp` but no final file (interrupted
  rename), it promotes the `.tmp`.
- **Corruption handling.** An unreadable/malformed file is **quarantined** to
  `X.json.corrupt` (never silently deleted), the `.bak` is tried, and failing
  that the domain falls back to defaults — always loudly logged via `Log`.
- **Forward-compatible defaults.** `_merge_defaults()` fills keys added since a
  save was written, so old saves stay valid as the schema grows.
- **No silent failures.** Every FileAccess/DirAccess error is logged.

## Migrations

When `SAVE_VERSION` increases, add a step in `SaveManager._migrate()` that
transforms `data` from each old version forward (v1→v2, v2→v3, …). Never rename
or repurpose an existing field's meaning without a migration. Keep old ids.

## API sketch

```gdscript
var profile := SaveManager.get_profile()     # cached; loads on first access
profile["life_count"] += 1
SaveManager.set_data("profile", profile)      # writes atomically

SaveManager.has_active_run()                  # bool
SaveManager.clear_run()                       # on death / abandon (profile untouched)
```

## Dev tools (future)

The debug panel will expose: reset active run, reset profile (with
confirmation), and force-write/reload — see [ROADMAP.md](ROADMAP.md). Resetting
run and profile are independent operations.

## Tests

`tests/unit/test_save.gd` covers round-trip, backup creation, corruption
quarantine + fallback, default shape, and the merge-defaults logic. It uses the
ephemeral `run` domain and cleans up so the developer's real profile is never
touched.
