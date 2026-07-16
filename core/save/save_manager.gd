extends Node
## Save/load service (autoload singleton: `SaveManager`).
##
## Three independent domains with different lifetimes (see docs/SAVE_SYSTEM.md):
##   - "profile"  permanent soul progression (survives death)
##   - "settings" audio/video/accessibility preferences
##   - "run"      the current life; wiped on death
##
## Reliability guarantees:
##   - Versioned headers with a migration hook.
##   - Atomic-ish writes via a temp file + rename, keeping a .bak of the prior
##     good file. A crash mid-write never destroys the last good save.
##   - Corrupt/unreadable files are quarantined (.corrupt), never silently
##     deleted, and the domain falls back to defaults with a loud log.
##
## Errors are never swallowed — every failure is logged via Log.

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"

const _DOMAIN_FILES := {
	"profile": "profile.json",
	"settings": "settings.json",
	"run": "run.json",
}

# In-memory copies. Loaded lazily / on boot; mutate via getters and re-save.
var _cache: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	Log.info(Log.Cat.SAVE, "SaveManager ready (save_version %d) at %s" % [SAVE_VERSION, ProjectSettings.globalize_path(SAVE_DIR)])


# ---------------------------------------------------------------------------
# Domain defaults — the shape each domain takes for a brand-new player.
# ---------------------------------------------------------------------------

func default_data(domain: String) -> Dictionary:
	match domain:
		"profile":
			return {
				"soul_level": 0,
				"remembrance": 0,
				"life_count": 0,
				"death_count": 0,
				"tattoo_system_unlocked": false,
				"tattoo_slots": 0,
				"unlocked_universes": ["lovecraft_coast"],
				# Universe ids in the order lives were lived (newest last). Drives
				# the no-repeat / recent-visit rules in universe selection.
				"universe_history": [],
				"unlocked_items": [],
				"adaptations": [],
				"memories": [],
				"tattoos": [],
				"lore": [],
				"stats": {},
			}
		"settings":
			return {
				"master_volume": 1.0,
				"music_volume": 0.8,
				"sfx_volume": 0.9,
				"fullscreen": false,
				"reduced_motion": false,
				"screen_shake": true,
				"text_speed": 1.0,
			}
		"run":
			# Empty = no active run in progress.
			return {}
		_:
			push_error("SaveManager.default_data: unknown domain '%s'" % domain)
			return {}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the cached data for a domain, loading it from disk on first access.
func get_data(domain: String) -> Dictionary:
	if not _cache.has(domain):
		_cache[domain] = load_domain(domain)
	return _cache[domain]

func get_profile() -> Dictionary: return get_data("profile")
func get_settings() -> Dictionary: return get_data("settings")
func get_run() -> Dictionary: return get_data("run")

## Replaces the cached data for a domain and writes it to disk.
func set_data(domain: String, data: Dictionary) -> bool:
	_cache[domain] = data
	return save_domain(domain)

func has_active_run() -> bool:
	return not get_run().is_empty()

## Deletes the active run (on death / abandon). Profile is untouched.
func clear_run() -> bool:
	_cache["run"] = {}
	return save_domain("run")


# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------

## Loads a domain from disk. On any problem, quarantines the bad file and
## returns defaults. Never throws; always returns a usable Dictionary.
func load_domain(domain: String) -> Dictionary:
	var path := _path_for(domain)
	var tmp := path + ".tmp"

	# Crash recovery: a leftover .tmp with no final file means a write was
	# interrupted after the old file was removed but before rename. Promote it.
	if not FileAccess.file_exists(path) and FileAccess.file_exists(tmp):
		Log.warn(Log.Cat.SAVE, "Recovering interrupted write for '%s' from .tmp" % domain)
		DirAccess.rename_absolute(tmp, path)

	if not FileAccess.file_exists(path):
		Log.info(Log.Cat.SAVE, "No save for '%s'; using defaults" % domain)
		var d := default_data(domain)
		EventBus.emit_signal("save_loaded", domain)
		return d

	var parsed := _read_json(path)
	if parsed.is_empty() or not parsed.has("save_version"):
		return _recover_from_backup(domain, "unreadable or malformed")

	var loaded_version := int(parsed.get("save_version", 0))
	var data: Dictionary = parsed.get("data", {})

	if loaded_version > SAVE_VERSION:
		# Save is from a NEWER build. Do not clobber it — refuse and use
		# defaults in memory so we never downgrade the player's real save.
		Log.error(Log.Cat.SAVE, "Save '%s' is version %d, newer than supported %d. Not loading." % [domain, loaded_version, SAVE_VERSION])
		return default_data(domain)

	if loaded_version < SAVE_VERSION:
		data = _migrate(domain, data, loaded_version)

	# Fill any keys added since the save was written.
	data = _merge_defaults(default_data(domain), data)
	Log.info(Log.Cat.SAVE, "Loaded '%s' (from version %d)" % [domain, loaded_version])
	EventBus.emit_signal("save_loaded", domain)
	return data


func _recover_from_backup(domain: String, reason: String) -> Dictionary:
	var path := _path_for(domain)
	var bak := path + ".bak"
	Log.error(Log.Cat.SAVE, "Save '%s' is %s; quarantining and trying backup" % [domain, reason])
	_quarantine(path)
	if FileAccess.file_exists(bak):
		var parsed := _read_json(bak)
		if not parsed.is_empty() and parsed.has("save_version"):
			var data: Dictionary = parsed.get("data", {})
			data = _merge_defaults(default_data(domain), data)
			Log.warn(Log.Cat.SAVE, "Recovered '%s' from backup" % domain)
			return data
	Log.error(Log.Cat.SAVE, "No usable backup for '%s'; using defaults" % domain)
	return default_data(domain)


# ---------------------------------------------------------------------------
# Save (atomic-ish)
# ---------------------------------------------------------------------------

## Writes the cached data for a domain to disk. Returns true on success.
func save_domain(domain: String) -> bool:
	if not _DOMAIN_FILES.has(domain):
		Log.error(Log.Cat.SAVE, "save_domain: unknown domain '%s'" % domain)
		return false

	var data: Dictionary = _cache.get(domain, default_data(domain))
	var envelope := {
		"save_version": SAVE_VERSION,
		"domain": domain,
		"data": data,
	}
	var json := JSON.stringify(envelope, "\t")

	var path := _path_for(domain)
	var tmp := path + ".tmp"
	var bak := path + ".bak"

	# 1. Write to temp.
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		Log.error(Log.Cat.SAVE, "Cannot open temp '%s' (err %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(json)
	f.flush()
	f.close()

	# 2. Back up the previous good file, then swap temp into place. Absolute
	# paths avoid any ambiguity about what a bare filename is relative to.
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		var cerr := DirAccess.copy_absolute(path, bak)
		if cerr != OK:
			Log.warn(Log.Cat.SAVE, "Could not back up '%s' before save (err %d)" % [domain, cerr])
		DirAccess.remove_absolute(path)

	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		Log.error(Log.Cat.SAVE, "Rename failed for '%s' (err %d)" % [domain, err])
		return false

	Log.info(Log.Cat.SAVE, "Saved '%s'" % domain)
	EventBus.emit_signal("save_written", domain)
	return true


# ---------------------------------------------------------------------------
# Migration — grows as SAVE_VERSION increments. See docs/SAVE_SYSTEM.md.
# ---------------------------------------------------------------------------

func _migrate(domain: String, data: Dictionary, from_version: int) -> Dictionary:
	Log.warn(Log.Cat.SAVE, "Migrating '%s' from version %d to %d" % [domain, from_version, SAVE_VERSION])
	# No historical versions yet. When SAVE_VERSION > 1, transform `data`
	# step-by-step here (v1->v2, v2->v3, ...). Return the upgraded dict.
	return data


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _path_for(domain: String) -> String:
	return "%s/%s" % [SAVE_DIR, _DOMAIN_FILES.get(domain, domain + ".json")]

func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		Log.error(Log.Cat.SAVE, "Cannot read '%s' (err %d)" % [path, FileAccess.get_open_error()])
		return {}
	var text := f.get_as_text()
	f.close()
	var result = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		Log.error(Log.Cat.SAVE, "'%s' did not contain a JSON object" % path)
		return {}
	return result

func _quarantine(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var corrupt := path + ".corrupt"
	if FileAccess.file_exists(corrupt):
		DirAccess.remove_absolute(corrupt)
	DirAccess.rename_absolute(path, corrupt)

## Recursively fills missing keys in `data` from `defaults` without overwriting
## existing values. Keeps old saves valid as the schema grows.
func _merge_defaults(defaults: Dictionary, data: Dictionary) -> Dictionary:
	var out := data.duplicate(true)
	for key in defaults:
		if not out.has(key):
			out[key] = defaults[key]
		elif typeof(defaults[key]) == TYPE_DICTIONARY and typeof(out[key]) == TYPE_DICTIONARY:
			out[key] = _merge_defaults(defaults[key], out[key])
	return out
