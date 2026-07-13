class_name ContentDefinition
extends RefCounted
## Base class for all data-driven content definitions (Phase 2 data model).
##
## Every content type (cards, items, enemies, universes, ...) extends this and
## follows the same pattern:
##   - static from_dict(d) builds the definition from plain dictionary data,
##     coercing defensively — malformed input becomes validation problems,
##     never crashes.
##   - validate(registry) returns human-readable problems ([] = valid). Every
##     message is prefixed with "type:id:" via _ctx().
##   - type_name() returns the registry type key (one of the TYPE_* constants).
##
## Definitions are PURE DATA plus validation. They never touch autoloads or
## scene nodes; the ContentRegistry is passed in as a parameter so everything
## stays headless-testable. Cross-reference checks are skipped when registry
## is null (pure unit tests).

# Registry type keys. Content is registered and looked up under these.
const TYPE_CARD := "card"
const TYPE_ITEM := "item"
const TYPE_ENEMY := "enemy"
const TYPE_STATUS := "status"
const TYPE_UNIVERSE := "universe"
const TYPE_MAP_NODE := "map_node"
const TYPE_LOOT_TABLE := "loot_table"
const TYPE_TATTOO := "tattoo"
const TYPE_MEMORY := "memory"
const TYPE_ADAPTATION := "adaptation"
const TYPE_BODY_ARCHETYPE := "body_archetype"
const TYPE_DIFFICULTY := "difficulty"

# Shared closed vocabularies (used by more than one content type).
const RARITIES := ["starter", "common", "uncommon", "rare", "special"]
const DAMAGE_TYPES := ["physical", "fire", "frost", "poison", "cosmic", "holy"]

var id: String = ""
var display_name: String = ""
var description: String = ""
var tags: Array[String] = []


## Override: return the ContentDefinition.TYPE_* key for this content type.
func type_name() -> String:
	return "content"


## Override: call super.validate(registry) first, append your own problems.
func validate(_registry) -> Array[String]:
	var problems: Array[String] = []
	if id.is_empty():
		problems.append(_ctx("required field 'id' is empty"))
	elif not is_valid_id(id):
		problems.append(_ctx("id must be snake_case ascii (a-z, 0-9, _) starting with a letter"))
	if display_name.is_empty():
		problems.append(_ctx("required field 'display_name' is empty"))
	for t in tags:
		if t.is_empty():
			problems.append(_ctx("tags contains an empty string"))
	return problems


## Parses the fields every definition shares. Call first inside from_dict().
func _apply_base(d: Dictionary) -> void:
	id = str(d.get("id", ""))
	display_name = str(d.get("display_name", ""))
	description = str(d.get("description", ""))
	tags = to_string_array(d.get("tags", []))


# ---------------------------------------------------------------------------
# Validation helpers for subclasses
# ---------------------------------------------------------------------------

## Prefixes a problem message with "type:id:" so aggregated reports are traceable.
func _ctx(message: String) -> String:
	var shown := id if not id.is_empty() else "<no id>"
	return "%s:%s: %s" % [type_name(), shown, message]


## Records a problem if ref_id is set but not registered under ref_type.
## Silently passes when registry is null (unit tests without a registry).
func _check_ref(registry, ref_type: String, ref_id: String, field: String, problems: Array[String]) -> void:
	if registry == null or ref_id.is_empty():
		return
	if not registry.has_def(ref_type, ref_id):
		problems.append(_ctx("field '%s' references missing %s '%s'" % [field, ref_type, ref_id]))


## Records a problem if value is not one of the allowed strings.
func _check_in_set(value: String, allowed: Array, field: String, problems: Array[String]) -> void:
	if not allowed.has(value):
		problems.append(_ctx("field '%s' has invalid value '%s' (allowed: %s)" % [field, value, ", ".join(allowed)]))


## Validates a universe_availability list: each entry is "*" (everywhere) or a
## registered universe id. An empty list is a problem — use ["*"] for everywhere.
func _check_universe_availability(registry, availability: Array[String], problems: Array[String]) -> void:
	if availability.is_empty():
		problems.append(_ctx("universe_availability must not be empty (use [\"*\"] for everywhere)"))
	for u in availability:
		if u == "*":
			continue
		_check_ref(registry, TYPE_UNIVERSE, u, "universe_availability", problems)


# ---------------------------------------------------------------------------
# Static coercion helpers (safe against malformed data)
# ---------------------------------------------------------------------------

## True for non-empty snake_case ascii ids starting with a letter.
static func is_valid_id(s: String) -> bool:
	if s.is_empty():
		return false
	var first := s.unicode_at(0)
	if first < 97 or first > 122:  # must start a-z
		return false
	for i in s.length():
		var c := s.unicode_at(i)
		var ok := (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95
		if not ok:
			return false
	return true


## Coerces any value to Array[String] (non-arrays become []).
static func to_string_array(v) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for e in v:
			out.append(str(e))
	return out


## Coerces any value to Array[Dictionary], dropping non-dictionary entries.
## Shape problems surface later in validate(), which checks expected counts.
static func to_dict_array(v) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if v is Array:
		for e in v:
			if e is Dictionary:
				out.append(e)
	return out
