class_name DeathAdaptationDefinition
extends ContentDefinition
## Death adaptation definition (TYPE_ADAPTATION): a permanent soul change
## earned by dying in a particular way. Adaptations are data, not hard-coded
## branches in the death manager (see docs/CONTENT_SCHEMA.md).
##
## The `trigger` dictionary describes which deaths qualify (cause-of-death
## tags, killer's tags, carried item tags, or specific universes). The
## `effect` is what the next life gains; the optional `drawback` keeps
## adaptations from becoming raw power creep (see docs/GAME_VISION.md).
##
## Pure data + validation: no autoloads, no nodes. The registry parameter may
## be null, in which case cross-reference checks are skipped.

const TRIGGER_KEYS := ["death_cause_tags", "enemy_tags", "carried_item_tags", "universe_ids"]

var trigger: Dictionary = {}
var effect: Dictionary = {}
var drawback: Dictionary = {}
var unlock_requirements: Dictionary = {}


func type_name() -> String:
	return TYPE_ADAPTATION


static func from_dict(d: Dictionary) -> DeathAdaptationDefinition:
	var def := DeathAdaptationDefinition.new()
	def._apply_base(d)
	var trigger_v: Variant = d.get("trigger", {})
	def.trigger = trigger_v if trigger_v is Dictionary else {}
	var effect_v: Variant = d.get("effect", {})
	def.effect = effect_v if effect_v is Dictionary else {}
	var drawback_v: Variant = d.get("drawback", {})
	def.drawback = drawback_v if drawback_v is Dictionary else {}
	var reqs_v: Variant = d.get("unlock_requirements", {})
	def.unlock_requirements = reqs_v if reqs_v is Dictionary else {}
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	# An adaptation must be reachable: at least one trigger key with entries,
	# and no unknown keys silently ignored by the death manager later.
	var has_populated_trigger := false
	for key in trigger:
		var key_name := str(key)
		if not TRIGGER_KEYS.has(key_name):
			problems.append(_ctx("trigger has unknown key '%s' (allowed: %s)" % [key_name, ", ".join(TRIGGER_KEYS)]))
			continue
		var value_v: Variant = trigger[key]
		if not (value_v is Array):
			problems.append(_ctx("trigger.%s must be an Array of String" % key_name))
			continue
		var entries := to_string_array(value_v)
		if entries.is_empty():
			continue
		has_populated_trigger = true
		for e in entries:
			if e.is_empty():
				problems.append(_ctx("trigger.%s contains an empty string" % key_name))
			elif key_name == "universe_ids":
				_check_ref(registry, TYPE_UNIVERSE, e, "trigger.universe_ids", problems)
	if not has_populated_trigger:
		problems.append(_ctx("trigger must have at least one non-empty key (allowed: %s)" % ", ".join(TRIGGER_KEYS)))
	if effect.is_empty():
		problems.append(_ctx("required field 'effect' is empty"))
	return problems
