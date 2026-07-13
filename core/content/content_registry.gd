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


## Empties the registry. Used by tests (which share this autoload across one
## process) and debug tools that reload content from scratch.
func clear() -> void:
	_content.clear()


## Runs registered validators and returns a list of human-readable problems.
## An empty list means content is valid. Callers (boot, debug panel, tests)
## decide whether problems are fatal.
func validate_all() -> Array[String]:
	var problems: Array[String] = []
	for type_name in _content:
		for id in _content[type_name]:
			var def = _content[type_name][id]
			if def is Object and def.has_method("validate"):
				problems.append_array(def.validate(self))
	_validate_globals(problems)
	return problems


## Cross-content checks no single definition can see on its own.
func _validate_globals(problems: Array[String]) -> void:
	# The first three lives are a scripted on-ramp: fixed_order_position 1..3
	# must each be claimed by exactly one universe.
	var positions: Dictionary = {}  # fixed_order_position -> universe id that claimed it
	var any_playable := false
	for u in all_of(ContentDefinition.TYPE_UNIVERSE).values():
		if not (u is UniverseDefinition):
			continue
		if u.playable:
			any_playable = true
		if u.fixed_order_position == -1:
			continue
		if positions.has(u.fixed_order_position):
			problems.append("universe:%s: fixed_order_position %d already used by '%s'" % [u.id, u.fixed_order_position, positions[u.fixed_order_position]])
		else:
			positions[u.fixed_order_position] = u.id
	for required_pos in [1, 2, 3]:
		if not positions.has(required_pos):
			problems.append("universe: no universe has fixed_order_position %d (the first three lives are fixed-order)" % required_pos)
	if not any_playable:
		problems.append("universe: at least one universe must be playable")
	if ids_of(ContentDefinition.TYPE_BODY_ARCHETYPE).is_empty():
		problems.append("body_archetype: at least one body archetype must be registered")
