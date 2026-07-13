extends Node
## Content registry (autoload singleton: `ContentRegistry`).
##
## Central lookup for all data-driven content (cards, items, enemies,
## universes, tattoos, ...). Everything is keyed by a stable string id; display
## names are never used as keys (see docs/CONTENT_SCHEMA.md).
##
## The foundation ships this deliberately empty — content types will register
## as their data models land in Phase 2. The important part now is the shape:
## a single place to register, look up, and *validate* content so the game can
## fail loudly in development when data is wrong.

## type_name -> { id -> definition }
var _content: Dictionary = {}


func _ready() -> void:
	Log.info(Log.Cat.CONTENT, "ContentRegistry ready (0 types registered)")


## Registers a definition under a content type. Returns false on duplicate id
## (and logs an error) so bad data surfaces immediately.
func register(type_name: String, id: String, definition) -> bool:
	if id.is_empty():
		Log.error(Log.Cat.CONTENT, "Empty id registering into '%s'" % type_name)
		return false
	if not _content.has(type_name):
		_content[type_name] = {}
	if _content[type_name].has(id):
		Log.error(Log.Cat.CONTENT, "Duplicate id '%s' in '%s'" % [id, type_name])
		return false
	_content[type_name][id] = definition
	return true


## Returns the definition, or null if absent.
func get_def(type_name: String, id: String):
	return _content.get(type_name, {}).get(id, null)

func has_def(type_name: String, id: String) -> bool:
	return _content.get(type_name, {}).has(id)

func ids_of(type_name: String) -> Array:
	return _content.get(type_name, {}).keys()

func all_of(type_name: String) -> Dictionary:
	return _content.get(type_name, {})


## Runs registered validators and returns a list of human-readable problems.
## An empty list means content is valid. Callers (boot, debug panel, tests)
## decide whether problems are fatal.
func validate_all() -> Array[String]:
	var problems: Array[String] = []
	# Future: iterate content types, check missing references, invalid costs,
	# empty required fields, unreachable content, broken loot tables, etc.
	# For now there is no content, so there is nothing to invalidate.
	return problems
