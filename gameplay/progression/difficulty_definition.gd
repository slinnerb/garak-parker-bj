class_name DifficultyDefinition
extends ContentDefinition
## A difficulty tier: global scaling multipliers applied to a life. Kept as
## data so new tiers (and their unlock conditions) can ship without code —
## per the soul-progression pillar, harder tiers grant more remembrance, not
## the player more raw power.
##
## unlock_requirements is a free-form Dictionary interpreted by the progression
## system (e.g. {"min_deaths": 5}); its keys are an open set and not validated
## here.
##
## Pure data + validation: the registry is a parameter and may be null.

var enemy_hp_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var remembrance_multiplier: float = 1.0
var unlock_requirements: Dictionary = {}


func type_name() -> String:
	return TYPE_DIFFICULTY


static func from_dict(d: Dictionary) -> DifficultyDefinition:
	var def := DifficultyDefinition.new()
	def._apply_base(d)
	def.enemy_hp_multiplier = float(d.get("enemy_hp_multiplier", 1.0))
	def.enemy_damage_multiplier = float(d.get("enemy_damage_multiplier", 1.0))
	def.remembrance_multiplier = float(d.get("remembrance_multiplier", 1.0))
	var unlock = d.get("unlock_requirements", {})
	if unlock is Dictionary:
		def.unlock_requirements = unlock
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	# Zero or negative multipliers would zero out combat or rewards entirely —
	# always an authoring mistake.
	if enemy_hp_multiplier <= 0.0:
		problems.append(_ctx("field 'enemy_hp_multiplier' must be > 0 (got %s)" % enemy_hp_multiplier))
	if enemy_damage_multiplier <= 0.0:
		problems.append(_ctx("field 'enemy_damage_multiplier' must be > 0 (got %s)" % enemy_damage_multiplier))
	if remembrance_multiplier <= 0.0:
		problems.append(_ctx("field 'remembrance_multiplier' must be > 0 (got %s)" % remembrance_multiplier))
	return problems
