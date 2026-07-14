class_name EnemyDefinition
extends ContentDefinition
## Enemy definition (Phase 2 data model) — registered under TYPE_ENEMY.
##
## An enemy is base stats plus a list of telegraphed intents; the combat AI
## chooses among the intents per `behavior`. Loot and universe placement are
## id references resolved through the registry at validate time, so enemies
## stay pure data with no combat logic of their own.

## How the AI picks the next intent. Const String array, not an enum:
## content data references these by literal string.
const BEHAVIORS := ["weighted_random", "sequence"]

var base_hp: int = 1
## Random spread applied around base_hp per encounter so repeated fights
## don't feel scripted.
var hp_variance: int = 0
## damage_type -> multiplier (> 0). Types missing here default to 1.0 at
## runtime, so only deviations from neutral are listed in data.
var damage_taken_multipliers: Dictionary = {}
var intents: Array[EnemyIntentDefinition] = []
var behavior: String = "weighted_random"
var loot_table_id: String = ""
var universe_availability: Array[String] = ["*"]
var is_elite: bool = false
var is_boss: bool = false


func type_name() -> String:
	return TYPE_ENEMY


static func from_dict(d: Dictionary) -> EnemyDefinition:
	var def := EnemyDefinition.new()
	def._apply_base(d)
	def.base_hp = int(d.get("base_hp", 1))
	def.hp_variance = int(d.get("hp_variance", 0))
	# Kept as-is (not coerced) so validate() reports bad keys/values instead
	# of silently normalizing them.
	var raw_multipliers = d.get("damage_taken_multipliers", {})
	def.damage_taken_multipliers = raw_multipliers if raw_multipliers is Dictionary else {}
	for intent_d in to_dict_array(d.get("intents", [])):
		def.intents.append(EnemyIntentDefinition.from_dict(intent_d))
	def.behavior = str(d.get("behavior", "weighted_random"))
	def.loot_table_id = str(d.get("loot_table_id", ""))
	def.universe_availability = to_string_array(d.get("universe_availability", ["*"]))
	def.is_elite = bool(d.get("is_elite", false))
	def.is_boss = bool(d.get("is_boss", false))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	if base_hp < 1:
		problems.append(_ctx("field 'base_hp' must be >= 1 (got %d)" % base_hp))
	if hp_variance < 0:
		problems.append(_ctx("field 'hp_variance' must be >= 0 (got %d)" % hp_variance))
	elif base_hp >= 1 and hp_variance >= base_hp:
		# Variance is a spread around base_hp; if it can equal or exceed base_hp
		# an encounter could roll an enemy in at 0 or negative HP.
		problems.append(_ctx("field 'hp_variance' (%d) must be < base_hp (%d) so rolled HP stays positive" % [hp_variance, base_hp]))
	for damage_type in damage_taken_multipliers:
		if not DAMAGE_TYPES.has(damage_type):
			problems.append(_ctx("damage_taken_multipliers has unknown damage type '%s' (allowed: %s)" % [damage_type, ", ".join(DAMAGE_TYPES)]))
		var multiplier = damage_taken_multipliers[damage_type]
		if not ((multiplier is float or multiplier is int) and float(multiplier) > 0.0):
			problems.append(_ctx("damage_taken_multipliers['%s'] must be a number > 0 (got '%s')" % [damage_type, multiplier]))
	_validate_intents(registry, problems)
	_check_in_set(behavior, BEHAVIORS, "behavior", problems)
	_check_ref(registry, TYPE_LOOT_TABLE, loot_table_id, "loot_table_id", problems)
	_check_universe_availability(registry, universe_availability, problems)
	# Elite and boss pools are disjoint by design — universes list them in
	# separate fields with separate map-node roles.
	if is_elite and is_boss:
		problems.append(_ctx("is_elite and is_boss must not both be true"))
	return problems


## Intents drive combat entirely, so the list shape is checked here (count,
## unique ids, guaranteed fallback) while each intent validates its own fields
## under an "enemy:<id> intent#<i>" context prefix.
func _validate_intents(registry, problems: Array[String]) -> void:
	if intents.is_empty():
		problems.append(_ctx("field 'intents' must contain at least one intent"))
		return
	var shown := id if not id.is_empty() else "<no id>"
	var seen_ids := {}
	var has_unconditional := false
	for i in intents.size():
		var intent := intents[i]
		if not intent.id.is_empty():
			if seen_ids.has(intent.id):
				problems.append(_ctx("duplicate intent id '%s'" % intent.id))
			seen_ids[intent.id] = true
		if intent.conditions.is_empty():
			has_unconditional = true
		problems.append_array(intent.validate(registry, "%s:%s intent#%d" % [type_name(), shown, i]))
	if not has_unconditional:
		problems.append(_ctx("needs at least one intent with empty conditions (guaranteed fallback so the enemy always has a legal move)"))
