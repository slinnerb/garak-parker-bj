# Reincarnation Roguelike

A single-player **roguelike reincarnation deckbuilder**. Each run is a whole life
in a different mythological universe; you explore, collect physical items that
become your cards, fight, and eventually die. Death is the core mechanic — the
soul carries adaptations, memories, and tattoos into the next life, while the
body and its equipment are lost.

> This repository currently contains the **foundation** (engine shell, core
> services, save system, update system, and a working main menu). Gameplay
> systems — combat, cards, items, the run map, death/reincarnation — are built
> in later phases. See [docs/ROADMAP.md](docs/ROADMAP.md) and
> [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md).

## Tech

- **Engine:** Godot 4.7 (stable), GDScript
- **Renderer:** GL Compatibility (broad hardware support)
- **Platform:** Windows desktop first
- **Base resolution:** 1280×720, resolution-independent (canvas_items stretch)

## Running the project

The Godot 4.7 editor binary on this machine is:

```
C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe
```

Open the folder in that editor, or run it from the command line:

```powershell
# Play the game
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --path .

# Boot headlessly (no window) — useful for smoke-checking logs
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --quit-after 150
```

## Running the tests

```powershell
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --script res://tests/run_all.gd
```

Exit code is `0` when all tests pass, `1` otherwise. Tests live in
`tests/unit/` and extend `TestCase`; drop a new `test_*.gd` file there and the
runner finds it automatically.

## Updates ("Check for Updates")

The game can tell your friend when a newer build exists, via **GitHub Releases**.

**One-time setup**

1. Create a **public** GitHub repo for this project.
2. Set the repo name in [`core/update/update_config.gd`](core/update/update_config.gd)
   (`GITHUB_REPO`). The owner is already `slinnerb`.
3. Push the code.

**Shipping an update to your friend**

```powershell
./tools/release/release.ps1 -Version 0.2.0 -Notes "What changed in this build."
```

That script bumps the version in `project.godot`, exports the Windows build,
zips it, and publishes a GitHub release tagged `v0.2.0`. Your friend's copy,
when they press **Check for Updates**, compares its version to the latest
release and offers to open the download page.

> Exporting a build requires Godot **export templates** for 4.7 to be installed
> (one-time: open the project in Godot → *Editor ▸ Manage Export Templates ▸
> Download and Install*). Until then, `-DryRun` and the in-game update check
> still work; only the actual `.exe` export needs templates.

## Project layout

```
core/          Engine-level services (autoloads): logging, events, RNG,
               save, content registry, scene flow, state, bootstrap, update.
gameplay/      (future) Combat, cards, items, map, death, progression, etc.
content/       (future) Data-driven definitions (cards, enemies, universes…).
scenes/        Godot scenes (boot, menus, and later combat/map/hub).
tests/         Headless test runner + unit tests.
tools/         Release pipeline and (future) debug/validation tooling.
docs/          Design and architecture documentation.
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit together.
