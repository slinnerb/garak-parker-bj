class_name ContentLoader
extends RefCounted
## Loads every content script into a ContentRegistry (Phase 2 data model).
##
## Content lives in plain data scripts (extends RefCounted, no class_name)
## exposing exactly two statics: content_type() and data(). The script list is
## hardcoded here so a typo'd path fails loudly at boot instead of silently
## shipping less content.
##
## Pure: the registry is always a parameter, never an autoload reference, so
## the loader stays headless-testable. push_error() is reserved for programmer
## errors (missing script, unknown content type) — malformed *data* inside a
## script becomes validation problems via the definitions themselves.

## Every content script, loaded in order. Cross-references are resolved at
## validate time, not load time, so ordering here is only cosmetic.
const CONTENT_SCRIPTS: Array[String] = [
	"res://content/statuses.gd",
	"res://content/map_nodes.gd",
	"res://content/difficulties.gd",
	"res://content/body_archetypes.gd",
	"res://content/universes.gd",
	"res://content/lovecraft/items.gd",
	"res://content/lovecraft/cards.gd",
	"res://content/lovecraft/enemies.gd",
	"res://content/lovecraft/loot_tables.gd",
	"res://content/soul/tattoos.gd",
	"res://content/soul/memories.gd",
	"res://content/soul/adaptations.gd",
]


## Loads all content scripts into the registry and returns how many
## definitions were registered. Idempotent: universes are always part of the
## shipped content, so if any are present the registry is already populated
## and the call is a no-op returning 0.
static func load_all(registry) -> int:
	if not registry.ids_of(ContentDefinition.TYPE_UNIVERSE).is_empty():
		return 0
	var total := 0
	for path in CONTENT_SCRIPTS:
		total += _load_script(registry, path)
	return total


## Loads one content script and registers its definitions. Returns how many
## registered successfully (duplicate ids are rejected and logged by the
## registry itself).
static func _load_script(registry, path: String) -> int:
	# Deliberately untyped: content scripts have no class_name, so their
	# statics are reached through dynamic dispatch on the loaded GDScript.
	var script = load(path)
	if script == null:
		push_error("ContentLoader: cannot load content script '%s'" % path)
		return 0
	var type_name := str(script.content_type())
	var count := 0
	for d in script.data():
		var def = _build_definition(type_name, d)
		if def == null:
			# One error, not one per entry — the whole script is mistyped.
			push_error("ContentLoader: unknown content type '%s' in '%s'" % [type_name, path])
			registry.record_load_problem("content loader: unknown content type '%s' in '%s'" % [type_name, path])
			return count
		if registry.register(type_name, def.id, def):
			count += 1
		else:
			# Dropped for an empty or duplicate id. register() logs it, but the
			# def is now gone and can't validate itself — record it so the boot
			# content-validation gate still fails instead of reporting success.
			registry.record_load_problem("content loader: could not register %s '%s' from '%s' (empty or duplicate id)" % [type_name, def.id, path])
	return count


## Maps a content type string to its definition class's from_dict. Returns
## null for unknown types — the type vocabulary is closed here even though
## content ids are an open set.
static func _build_definition(type_name: String, d: Dictionary):
	match type_name:
		ContentDefinition.TYPE_CARD:
			return CardDefinition.from_dict(d)
		ContentDefinition.TYPE_ITEM:
			return ItemDefinition.from_dict(d)
		ContentDefinition.TYPE_ENEMY:
			return EnemyDefinition.from_dict(d)
		ContentDefinition.TYPE_STATUS:
			return StatusEffectDefinition.from_dict(d)
		ContentDefinition.TYPE_UNIVERSE:
			return UniverseDefinition.from_dict(d)
		ContentDefinition.TYPE_MAP_NODE:
			return MapNodeDefinition.from_dict(d)
		ContentDefinition.TYPE_LOOT_TABLE:
			return LootTableDefinition.from_dict(d)
		ContentDefinition.TYPE_TATTOO:
			return TattooDefinition.from_dict(d)
		ContentDefinition.TYPE_MEMORY:
			return MemoryDefinition.from_dict(d)
		ContentDefinition.TYPE_ADAPTATION:
			return DeathAdaptationDefinition.from_dict(d)
		ContentDefinition.TYPE_BODY_ARCHETYPE:
			return BodyArchetypeDefinition.from_dict(d)
		ContentDefinition.TYPE_DIFFICULTY:
			return DifficultyDefinition.from_dict(d)
	return null
