extends Node
## Central signal hub (autoload singleton: `EventBus`).
##
## Decouples producers from consumers for high-level, cross-system events.
## Keep this focused: only genuinely global state transitions belong here.
## Local gameplay wiring should use explicit signals/dependencies, not this bus.
##
## Usage:
##   EventBus.boot_completed.connect(_on_boot_completed)
##   EventBus.emit_signal("scene_changed", "res://scenes/menus/main_menu.tscn")

## Emitted once the boot sequence finishes and services are ready.
signal boot_completed()

## Emitted after the active scene has been swapped. Carries the new scene path.
signal scene_changed(scene_path: String)

## Emitted when the high-level game state changes (see GameStateManager).
signal game_state_changed(previous: int, current: int)

## Emitted when settings are loaded or modified so listeners can re-read them.
signal settings_changed()

## Emitted when an update check completes. status is one of:
## "available", "up_to_date", "failed". info is a Dictionary (see UpdateService).
signal update_check_completed(status: String, info: Dictionary)

## Emitted when a save domain is written or loaded. Useful for debug/telemetry.
signal save_written(domain: String)
signal save_loaded(domain: String)

## Emitted when a new run (life) begins. Carries the universe id.
signal run_started(universe_id: String)
