# Decisions Log

Reasonable assumptions and deliberate choices, recorded so future work doesn't
re-litigate them. Newest first.

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
