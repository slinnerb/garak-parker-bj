# Current State

_Last updated: 2026-07-12 — end of the foundation pass._

## What works today

- **Project boots cleanly** (verified headless): autoloads initialize in order,
  `GameBootstrap` runs the boot sequence, state transitions `BOOT → MAIN_MENU`,
  and the main menu scene loads with **zero errors**.
- **Core services** (all autoloaded):
  - `Log` — category/level logging to console + `user://logs/session.log`.
  - `EventBus` — global signals for high-level transitions.
  - `RNG` — deterministic named streams from a master seed.
  - `SaveManager` — atomic, versioned save/load; 3 domains; backups; corruption
    quarantine; crash recovery.
  - `ContentRegistry` — id-keyed register/lookup/validate (empty, ready for data).
  - `Updater` — GitHub Releases update check with graceful error handling.
  - `SceneFlow`, `GameState`, `GameBootstrap`.
- **Main menu** with a working **Check for Updates** button, version label, and
  an update dialog that opens the download page. Gameplay buttons (New Life /
  Continue / Settings) are present but honestly disabled until their systems
  exist.
- **Release pipeline** — `tools/release/release.ps1` bumps the version, exports
  Windows, zips, and publishes a GitHub release.
- **Update system is live and verified** against the public repo
  **github.com/slinnerb/garak-parker-bj**. Verified end-to-end (headless):
  the "up to date" path (no releases) and the "update available" path (a newer
  release is detected with its notes + download URL), using a throwaway release
  that was then removed. Repo currently has no releases (clean at 0.1.0).
- **Tests** — 22 unit tests across SemVer, RNG determinism, save round-trip /
  backup / corruption / merge, and version wiring. **All green** (exit 0).

## Verified commands

```powershell
# Boot headlessly (logs the full startup, then quits)
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --quit-after 150

# Run tests (exit 0 = all pass)
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --script res://tests/run_all.gd
```

## Known limitations / not yet built

- **No gameplay** yet: no combat, cards, items, inventory/attunement, map,
  enemies, death/reincarnation, memories, or tattoos. These are Phases 2–7.
- **Export templates not installed**: producing the actual `.exe` needs the
  Godot 4.7 export templates (one-time editor install). The in-game update
  check and `-DryRun` do not need them.
- **Not visually smoke-tested on a real display in this pass** beyond the
  headless boot (the menu is a simple Control layout; low risk).
- **No settings screen, no debug panel** yet (Phase 1.5 / later).
- **Two universe definitions (Japanese, Norse)** and their content are not yet
  present; only the data architecture is planned.

## Immediate next task

Install the Godot 4.7 export templates and cut the first real `v0.1.0` release
(so there's a downloadable build for a friend), then begin **Phase 2: data
model** — starting with `CardDefinition` / `CardEffectDefinition` and
`ItemDefinition`, since the item→deck relationship is the spine of the whole
game.
