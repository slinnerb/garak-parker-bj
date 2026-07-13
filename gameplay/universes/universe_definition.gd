class_name UniverseDefinition
extends ContentDefinition
## A universe is the setting of one entire life (run): a mythology with its own
## enemies, items, and tone (see docs/GAME_VISION.md).
##
## Universes own the content lists that map generation draws from (enemy_ids /
## elite_ids / boss_ids / item_ids) and the weighting knobs the reincarnation
## system uses to pick the next life (base_weight, recent_visit_penalty,
## death_cause_weights, tattoo_weights). The first three lives are a scripted
## on-ramp — fixed_order_position 1..3 marks those; -1 means "random pool only".
##
## Pure data + validation: the registry is a parameter and may be null (then
## cross-reference checks are skipped).

var intro_text: String = ""
var theme_tags: Array[String] = []
var enemy_ids: Array[String] = []
var elite_ids: Array[String] = []
var boss_ids: Array[String] = []
var item_ids: Array[String] = []
## Accepted but NOT ref-checked: the event system lands in Phase 5, and
## universes may name their events before those definitions exist.
var event_ids: Array[String] = []
var card_theme: String = ""
var music_refs: Array[String] = []
var difficulty_min: int = 1
var difficulty_max: int = 1
var unlock_requirements: Dictionary = {}
var base_weight: float = 1.0
var recent_visit_penalty: float = 0.5
var death_cause_weights: Dictionary = {}
var tattoo_weights: Dictionary = {}
var awareness_modifier: float = 0.0
var map_gen_settings: Dictionary = {}
var fixed_order_position: int = -1
var playable: bool = false


func type_name() -> String:
	return TYPE_UNIVERSE


static func from_dict(d: Dictionary) -> UniverseDefinition:
	var def := UniverseDefinition.new()
	def._apply_base(d)
	def.intro_text = str(d.get("intro_text", ""))
	def.theme_tags = ContentDefinition.to_string_array(d.get("theme_tags", []))
	def.enemy_ids = ContentDefinition.to_string_array(d.get("enemy_ids", []))
	def.elite_ids = ContentDefinition.to_string_array(d.get("elite_ids", []))
	def.boss_ids = ContentDefinition.to_string_array(d.get("boss_ids", []))
	def.item_ids = ContentDefinition.to_string_array(d.get("item_ids", []))
	def.event_ids = ContentDefinition.to_string_array(d.get("event_ids", []))
	def.card_theme = str(d.get("card_theme", ""))
	def.music_refs = ContentDefinition.to_string_array(d.get("music_refs", []))
	def.difficulty_min = int(d.get("difficulty_min", 1))
	def.difficulty_max = int(d.get("difficulty_max", 1))
	var unlock = d.get("unlock_requirements", {})
	if unlock is Dictionary:
		def.unlock_requirements = unlock
	def.base_weight = float(d.get("base_weight", 1.0))
	def.recent_visit_penalty = float(d.get("recent_visit_penalty", 0.5))
	var dcw = d.get("death_cause_weights", {})
	if dcw is Dictionary:
		def.death_cause_weights = dcw
	var tw = d.get("tattoo_weights", {})
	if tw is Dictionary:
		def.tattoo_weights = tw
	def.awareness_modifier = float(d.get("awareness_modifier", 0.0))
	var mgs = d.get("map_gen_settings", {})
	if mgs is Dictionary:
		def.map_gen_settings = mgs
	def.fixed_order_position = int(d.get("fixed_order_position", -1))
	def.playable = bool(d.get("playable", false))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)

	_check_id_list(registry, enemy_ids, TYPE_ENEMY, "enemy_ids", problems)
	_check_id_list(registry, elite_ids, TYPE_ENEMY, "elite_ids", problems)
	_check_id_list(registry, boss_ids, TYPE_ENEMY, "boss_ids", problems)
	_check_id_list(registry, item_ids, TYPE_ITEM, "item_ids", problems)
	# event_ids intentionally skipped — see the field comment.
	if registry != null:
		_check_enemy_roles(registry, problems)

	if difficulty_min < 1:
		problems.append(_ctx("field 'difficulty_min' must be >= 1 (got %d)" % difficulty_min))
	if difficulty_max < difficulty_min:
		problems.append(_ctx("field 'difficulty_max' must be >= difficulty_min (got %d < %d)" % [difficulty_max, difficulty_min]))
	if base_weight <= 0.0:
		problems.append(_ctx("field 'base_weight' must be > 0 (got %s)" % base_weight))
	if recent_visit_penalty < 0.0 or recent_visit_penalty > 1.0:
		problems.append(_ctx("field 'recent_visit_penalty' must be between 0 and 1 (got %s)" % recent_visit_penalty))

	_check_weight_dict(death_cause_weights, "death_cause_weights", problems)
	_check_weight_dict(tattoo_weights, "tattoo_weights", problems)
	for tattoo_key in tattoo_weights:
		var tattoo_id := str(tattoo_key)
		if tattoo_id.is_empty():
			problems.append(_ctx("tattoo_weights contains an empty key"))
		else:
			_check_ref(registry, TYPE_TATTOO, tattoo_id, "tattoo_weights", problems)

	if fixed_order_position != -1 and (fixed_order_position < 1 or fixed_order_position > 3):
		problems.append(_ctx("field 'fixed_order_position' must be -1 or 1..3 (got %d)" % fixed_order_position))

	if playable:
		# A playable universe must be able to fill a run: fights, a finale,
		# and enough items to build a deck from.
		if enemy_ids.is_empty():
			problems.append(_ctx("playable universe needs at least 1 entry in enemy_ids"))
		if boss_ids.is_empty():
			problems.append(_ctx("playable universe needs at least 1 entry in boss_ids"))
		if item_ids.size() < 3:
			problems.append(_ctx("playable universe needs at least 3 entries in item_ids (got %d)" % item_ids.size()))
	return problems


## Every id in a content list must resolve. Empty strings would be silently
## skipped by _check_ref (it treats empty as "optional ref"), so catch them here.
func _check_id_list(registry, ids: Array[String], ref_type: String, field: String, problems: Array[String]) -> void:
	for ref_id in ids:
		if ref_id.is_empty():
			problems.append(_ctx("field '%s' contains an empty id" % field))
		else:
			_check_ref(registry, ref_type, ref_id, field, problems)


## Enemies must be listed under the tier matching their flags — otherwise map
## generation would seed bosses into normal fights (or vice versa). Missing
## refs are already reported by _check_id_list, so nulls are skipped here.
func _check_enemy_roles(registry, problems: Array[String]) -> void:
	for eid in enemy_ids:
		var def = registry.get_def(TYPE_ENEMY, eid)
		if def != null and (def.get("is_elite") == true or def.get("is_boss") == true):
			problems.append(_ctx("field 'enemy_ids' entry '%s' is elite/boss — list it under elite_ids or boss_ids" % eid))
	for eid in elite_ids:
		var def = registry.get_def(TYPE_ENEMY, eid)
		if def != null and def.get("is_elite") != true:
			problems.append(_ctx("field 'elite_ids' entry '%s' is not flagged is_elite" % eid))
	for eid in boss_ids:
		var def = registry.get_def(TYPE_ENEMY, eid)
		if def != null and def.get("is_boss") != true:
			problems.append(_ctx("field 'boss_ids' entry '%s' is not flagged is_boss" % eid))


## Weight dictionaries steer the weighted universe pick; a zero or negative
## weight is always an authoring mistake, never a valid "disable this entry".
## Types are checked before coercion so malformed values report, never crash.
func _check_weight_dict(weights: Dictionary, field: String, problems: Array[String]) -> void:
	for key in weights:
		var w = weights[key]
		if not (w is int or w is float) or float(w) <= 0.0:
			problems.append(_ctx("field '%s' value for '%s' must be a number > 0" % [field, str(key)]))
