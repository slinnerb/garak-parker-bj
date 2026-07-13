extends Node
## Boot orchestrator (autoload singleton: `GameBootstrap`).
##
## Runs the non-visual startup sequence in a defined order and hands control to
## the first screen. Autoloads initialize themselves; this coordinates the
## cross-cutting steps that depend on several of them being ready.
##
## The boot *scene* (scenes/boot/boot.gd) calls boot() — we do NOT change scenes
## from an autoload _ready(), because the main scene is not up yet at that point.

var _booted := false


## Runs the boot sequence. Safe to call once; subsequent calls are ignored.
## Returns true if content validated cleanly.
func boot() -> bool:
	if _booted:
		return true
	_booted = true
	GameState.set_state(GameState.State.BOOT)
	Log.info(Log.Cat.BOOT, "==== Reincarnation Roguelike %s ====" % GameVersion.current())

	_load_and_apply_settings()
	_warm_profile()
	var content_ok := _validate_content()

	Log.info(Log.Cat.BOOT, "Boot sequence complete")
	EventBus.emit_signal("boot_completed")
	return content_ok


func _load_and_apply_settings() -> void:
	var settings := SaveManager.get_settings()
	_apply_audio(settings)
	_apply_video(settings)
	EventBus.emit_signal("settings_changed")


func _apply_audio(settings: Dictionary) -> void:
	_set_bus_volume("Master", float(settings.get("master_volume", 1.0)))
	# Music/SFX buses are optional; only apply if the project defines them.
	if AudioServer.get_bus_index("Music") != -1:
		_set_bus_volume("Music", float(settings.get("music_volume", 0.8)))
	if AudioServer.get_bus_index("SFX") != -1:
		_set_bus_volume("SFX", float(settings.get("sfx_volume", 0.9)))


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))


func _apply_video(settings: Dictionary) -> void:
	var want_fullscreen := bool(settings.get("fullscreen", false))
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if want_fullscreen and not is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not want_fullscreen and is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _warm_profile() -> void:
	var profile := SaveManager.get_profile()
	Log.info(Log.Cat.BOOT, "Profile: life %d, %d deaths, tattoos %s" % [
		int(profile.get("life_count", 0)),
		int(profile.get("death_count", 0)),
		"unlocked" if bool(profile.get("tattoo_system_unlocked", false)) else "locked",
	])


func _validate_content() -> bool:
	var problems := ContentRegistry.validate_all()
	if problems.is_empty():
		Log.info(Log.Cat.CONTENT, "Content validation passed")
		return true
	for p in problems:
		Log.error(Log.Cat.CONTENT, "Content invalid: %s" % p)
	# Fail loudly in development; ship builds log but continue.
	if OS.is_debug_build():
		push_error("Content validation failed with %d problem(s). See log." % problems.size())
	return false
