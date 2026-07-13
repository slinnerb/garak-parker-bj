extends Node
## Structured logging service (autoload singleton: `Log`).
##
## Provides category- and level-tagged logging so output stays greppable and
## can be filtered. Writes to the console always, and optionally mirrors to a
## rotating file under user://logs/ when file logging is enabled.
##
## Usage:
##   Log.info(Log.Cat.BOOT, "Boot sequence started")
##   Log.warn(Log.Cat.SAVE, "Falling back to defaults")
##   Log.error(Log.Cat.CONTENT, "Duplicate id: %s" % id)
##
## Categories mirror docs/ARCHITECTURE.md. Add new ones sparingly.

enum Level { DEBUG, INFO, WARN, ERROR }

## Content/domain categories. Kept as an enum because this is a closed set of
## engine-level channels; gameplay content uses string ids, not this.
enum Cat {
	BOOT, SAVE, CONTENT, RUN, MAP, COMBAT, ITEM, CARD,
	DEATH, MEMORY, TATTOO, UNIVERSE, UPDATE, SCENE, RNG, TEST,
}

const _CAT_NAMES := {
	Cat.BOOT: "BOOT", Cat.SAVE: "SAVE", Cat.CONTENT: "CONTENT", Cat.RUN: "RUN",
	Cat.MAP: "MAP", Cat.COMBAT: "COMBAT", Cat.ITEM: "ITEM", Cat.CARD: "CARD",
	Cat.DEATH: "DEATH", Cat.MEMORY: "MEMORY", Cat.TATTOO: "TATTOO",
	Cat.UNIVERSE: "UNIVERSE", Cat.UPDATE: "UPDATE", Cat.SCENE: "SCENE",
	Cat.RNG: "RNG", Cat.TEST: "TEST",
}

const _LEVEL_NAMES := {
	Level.DEBUG: "DEBUG", Level.INFO: "INFO", Level.WARN: "WARN", Level.ERROR: "ERROR",
}

## Messages below this level are suppressed. Lower this to DEBUG while working.
var min_level: int = Level.DEBUG
## When true, also append lines to user://logs/session.log.
var file_logging_enabled: bool = true

const _LOG_DIR := "user://logs"
const _LOG_FILE := "user://logs/session.log"
var _file: FileAccess = null


func _ready() -> void:
	if file_logging_enabled:
		_open_log_file()
	info(Cat.BOOT, "Logger online (version %s)" % GameVersion.current())


func _open_log_file() -> void:
	DirAccess.make_dir_recursive_absolute(_LOG_DIR)
	# Truncate at session start so the file does not grow unbounded across runs.
	_file = FileAccess.open(_LOG_FILE, FileAccess.WRITE)
	if _file == null:
		push_warning("Logger: could not open %s (err %d)" % [_LOG_FILE, FileAccess.get_open_error()])


func debug(category: int, message: String) -> void:
	_emit(Level.DEBUG, category, message)


func info(category: int, message: String) -> void:
	_emit(Level.INFO, category, message)


func warn(category: int, message: String) -> void:
	_emit(Level.WARN, category, message)


func error(category: int, message: String) -> void:
	_emit(Level.ERROR, category, message)


func _emit(level: int, category: int, message: String) -> void:
	if level < min_level:
		return
	var cat_name: String = _CAT_NAMES.get(category, "GENERAL")
	var lvl_name: String = _LEVEL_NAMES.get(level, "INFO")
	var line := "[%s][%s] %s" % [cat_name, lvl_name, message]
	match level:
		Level.ERROR:
			push_error(line)
			printerr(line)
		Level.WARN:
			push_warning(line)
			print(line)
		_:
			print(line)
	if _file != null:
		_file.store_line(line)
		_file.flush()
