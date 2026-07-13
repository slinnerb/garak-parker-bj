class_name TattooDefinition
extends ContentDefinition
## Memory tattoo definition (TYPE_TATTOO): a permanent mark on the soul that
## re-manifests on every new body, in every universe.
##
## A tattoo's mechanical behavior lives in its `functions` array (data, not
## code): each entry names a function kind plus its params. `soul_identity` is
## the cross-universe identity of the mark — the same symbol recognized in
## unrelated mythologies is part of the subtle wrongness that threads the
## universes together (see docs/GAME_VISION.md).
##
## Pure data + validation: no autoloads, no nodes. The registry parameter may
## be null, in which case cross-reference checks are skipped.

const FUNCTION_KINDS := ["preserve_item_memory", "guarantee_item_family", "passive_adaptation", "unlock_events", "modify_dialogue", "modify_death_rewards", "alter_universe_weighting", "modify_awareness"]

var soul_identity: String = ""
var functions: Array[Dictionary] = []
var stages: Array[Dictionary] = []
var universe_display_overrides: Dictionary = {}
var unlock_requirements: Dictionary = {}
var awareness_delta: float = 0.0


func type_name() -> String:
	return TYPE_TATTOO


static func from_dict(d: Dictionary) -> TattooDefinition:
	var def := TattooDefinition.new()
	def._apply_base(d)
	def.soul_identity = str(d.get("soul_identity", ""))
	def.functions = ContentDefinition.to_dict_array(d.get("functions", []))
	def.stages = ContentDefinition.to_dict_array(d.get("stages", []))
	var overrides_v: Variant = d.get("universe_display_overrides", {})
	def.universe_display_overrides = overrides_v if overrides_v is Dictionary else {}
	var reqs_v: Variant = d.get("unlock_requirements", {})
	def.unlock_requirements = reqs_v if reqs_v is Dictionary else {}
	def.awareness_delta = float(d.get("awareness_delta", 0.0))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	if soul_identity.is_empty():
		problems.append(_ctx("required field 'soul_identity' is empty (the mark's cross-universe identity)"))
	# A tattoo with no functions is dead ink — it must do at least one thing.
	if functions.is_empty():
		problems.append(_ctx("field 'functions' must contain at least one function"))
	for i in functions.size():
		_validate_function(registry, i, functions[i], problems)
	for i in stages.size():
		var req_v: Variant = stages[i].get("requirement", null)
		if not (req_v is Dictionary) or (req_v as Dictionary).is_empty():
			problems.append(_ctx("stages[%d] must have a non-empty 'requirement' Dictionary" % i))
	for key in universe_display_overrides:
		var universe_id := str(key)
		_check_ref(registry, TYPE_UNIVERSE, universe_id, "universe_display_overrides", problems)
		var override_v: Variant = universe_display_overrides[key]
		var has_payload := override_v is Dictionary \
				and ((override_v as Dictionary).has("display_name") or (override_v as Dictionary).has("art_ref"))
		if not has_payload:
			problems.append(_ctx("universe_display_overrides['%s'] must be a Dictionary with 'display_name' and/or 'art_ref'" % universe_id))
	return problems


## Per-kind parameter checks for one soul-function entry. Only kinds with
## structural requirements are checked deeply; the rest are free-form data
## interpreted by their systems when those land.
func _validate_function(registry, index: int, f: Dictionary, problems: Array[String]) -> void:
	var kind := str(f.get("kind", ""))
	var field := "functions[%d]" % index
	_check_in_set(kind, FUNCTION_KINDS, field + ".kind", problems)
	var params_v: Variant = f.get("params", {})
	if not (params_v is Dictionary):
		problems.append(_ctx("%s.params must be a Dictionary" % field))
		return
	var params: Dictionary = params_v
	match kind:
		"preserve_item_memory":
			var item_id := str(params.get("item_id", ""))
			if item_id.is_empty():
				problems.append(_ctx("%s (preserve_item_memory) requires params.item_id" % field))
			else:
				_check_ref(registry, TYPE_ITEM, item_id, field + ".params.item_id", problems)
		"guarantee_item_family":
			if str(params.get("item_tag", "")).is_empty():
				problems.append(_ctx("%s (guarantee_item_family) requires a non-empty params.item_tag" % field))
		"alter_universe_weighting":
			var universe_id := str(params.get("universe_id", ""))
			if universe_id.is_empty():
				problems.append(_ctx("%s (alter_universe_weighting) requires params.universe_id" % field))
			else:
				_check_ref(registry, TYPE_UNIVERSE, universe_id, field + ".params.universe_id", problems)
			if float(params.get("multiplier", 0.0)) <= 0.0:
				problems.append(_ctx("%s (alter_universe_weighting) requires params.multiplier > 0" % field))
		"modify_awareness":
			if float(params.get("delta", 0.0)) == 0.0:
				problems.append(_ctx("%s (modify_awareness) requires a non-zero params.delta" % field))
