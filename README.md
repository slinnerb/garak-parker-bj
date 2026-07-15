# Reincarnation Roguelike

A single-player **roguelike reincarnation deckbuilder**. Each run is a whole life
in a different mythological universe; you explore, collect physical items that
become your cards, fight, and eventually die. Death is the core mechanic — the
soul carries adaptations, memories, and tattoos into the next life, while the
body and its equipment are lost.

> **Status — v0.1.0, first playable build.** A vertical slice of the core loop
> runs on screen: **main menu → attune a loadout → turn-based combat → win/lose.**
> Your attuned gear generates your deck, enemies telegraph their intent, statuses
> resolve, and the game checks for and installs its own updates from GitHub.
> Still ahead: the seeded **run map** and the full **death / reincarnation** loop.
> See [docs/ROADMAP.md](docs/ROADMAP.md) and [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md).

## Play it

Download the latest build from the
**[Releases page](https://github.com/slinnerb/garak-parker-bj/releases)**, unzip,
and run `ReincarnationRoguelike.exe` — a single self-contained file, no install.
On first launch Windows SmartScreen may warn about the unsigned exe: choose
*More info ▸ Run anyway*. The game checks for updates on launch and can update
itself (click the version number any time for the changelog + a manual check).

## Tech

- **Engine:** Godot 4.7 (stable), GDScript
- **Renderer:** GL Compatibility (broad hardware support)
- **Platform:** Windows desktop first (Steam-ready architecture)
- **Base resolution:** 1280×720, resolution-independent (canvas_items stretch)

## Running from source

The Godot 4.7 editor binary on this machine is:

```
C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe
```

```powershell
# Play the game
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --path .

# Boot headlessly (no window) — smoke-check the startup logs
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --quit-after 150
```

## Running the tests

```powershell
& "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" --headless --path . --script res://tests/run_all.gd
```

Exit code `0` when all pass (**102 tests** currently). Tests live in
`tests/unit/` and extend `TestCase`; drop a new `test_*.gd` file there and the
runner finds it automatically. (The one `Parse JSON failed` line during a run is
an intentional corrupt-save test, not a failure.)

## Building & shipping updates

Godot 4.7 **export templates are installed**, so one command builds and ships:

```powershell
./tools/release/release.ps1 -Version 0.2.0        # notes pulled from CHANGELOG.md
./tools/release/release.ps1 -Version 0.2.0 -DryRun # build + zip, no publish
```

It bumps the version in `project.godot`, exports the self-contained Windows
build, zips it, and publishes a GitHub release with notes taken from the matching
`CHANGELOG.md` section. Players **auto-update**: on launch their copy sees the
newer release, shows the changelog, and (on confirm) downloads it, replaces the
running build via a helper, and relaunches. See
[docs/DECISIONS.md](docs/DECISIONS.md) for the mechanism, and keep
[CHANGELOG.md](CHANGELOG.md) as the single source of release notes.

## Project layout

```
core/          Engine-level services (autoloads): logging, events, RNG, save,
               content registry, scene flow, state, bootstrap, update/self-update.
gameplay/      Domain logic (no autoloads, headless-testable):
                 combat/     turn-based engine (state, effects, statuses, AI)
                 inventory/  Inventory + Attunement (items -> deck)
                 cards/ items/ enemies/ universes/ ...  data definitions
content/       Data-driven content (Lovecraft items/cards/enemies, statuses,
               universes, tattoos, memories, adaptations, archetypes).
presentation/  Shared UI kit (palette + builders).
scenes/        Godot scenes: boot, menus (+ updates panel), combat, hub (attune).
tests/         Headless test runner + unit tests.
tools/         Release pipeline + debug tools (screenshot, update check).
docs/          Design and architecture documentation.
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit together.
