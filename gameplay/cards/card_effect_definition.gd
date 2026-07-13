class_name CardEffectDefinition
extends RefCounted
## One composable card effect (Phase 2 data model).
##
## Cards compose these small effect atoms instead of shipping one script per
## card (docs/CONTENT_SCHEMA.md). Kind-specific parameters live in `params`;
## the container kinds (conditional / repeat / random_target) additionally
## carry nested effects parsed into `then_effects` / `else_effects`.
##
## Plain RefCounted, not a ContentDefinition: effects have no id of their own.
## Callers supply a `ctx` prefix (e.g. "card:strike_harpoon effect#0") that is
## baked into every problem message so aggregated reports stay traceable to
## the owning definition. Like all definitions this is pure data + validation;
## the registry is a parameter and may be null (cross-ref checks skipped).

const KINDS := ["deal_damage", "gain_block", "heal", "draw_cards", "apply_status", "remove_status", "modify_energy", "add_temporary_card", "exhaust_card", "transform_card", "modify_item", "conditional", "repeat", "random_target"]

# Closed vocabularies for kind-specific params.
const STATUS_TARGETS := ["self", "enemy", "all_enemies"]
const CARD_DESTINATIONS := ["hand", "draw_pile", "discard_pile"]
const EXHAUST_SELECTORS := ["this", "chosen", "random_in_hand"]

# Container effects may nest at most this deep (depth 0 = top level). Deeper
# trees are almost certainly authoring mistakes and would be unreadable in play.
const MAX_DEPTH := 4

var kind: String = ""
var params: Dictionary = {}
## Nested effects: the "then" branch for conditional, the body for
## repeat / random_target. Empty for all leaf kinds.
var then_effects: Array[CardEffectDefinition] = []
## Nested effects: the "else" branch. Conditional only.
var else_effects: Array[CardEffectDefinition] = []


static func from_dict(d: Dictionary) -> CardEffectDefinition:
	var effect := CardEffectDefinition.new()
	effect.kind = str(d.get("kind", ""))
	var raw_params = d.get("params", {})
	if raw_params is Dictionary:
		effect.params = raw_params
	# Container kinds keep their children inside params in the raw data; parse
	# them into typed arrays here so validation and execution never re-parse.
	match effect.kind:
		"conditional":
			effect.then_effects = _parse_effect_list(effect.params.get("then", []))
			effect.else_effects = _parse_effect_list(effect.params.get("else", []))
		"repeat", "random_target":
			effect.then_effects = _parse_effect_list(effect.params.get("effects", []))
	return effect


static func _parse_effect_list(v) -> Array[CardEffectDefinition]:
	var out: Array[CardEffectDefinition] = []
	for e in ContentDefinition.to_dict_array(v):
		out.append(CardEffectDefinition.from_dict(e))
	return out


## Returns human-readable problems ([] = valid). `ctx` prefixes every message
## (e.g. "card:strike_harpoon effect#0"). `depth` tracks container nesting.
func validate(registry, ctx: String, depth: int = 0) -> Array[String]:
	var problems: Array[String] = []
	if depth > MAX_DEPTH:
		# Stop here: reporting every descendant of an over-deep tree adds noise.
		problems.append("%s: effects nested too deeply (max %d levels)" % [ctx, MAX_DEPTH + 1])
		return problems
	if not KINDS.has(kind):
		problems.append("%s: unknown effect kind '%s' (allowed: %s)" % [ctx, kind, ", ".join(KINDS)])
		return problems
	match kind:
		"deal_damage":
			_require_int("amount", 0, ctx, problems)
			_check_int_min("times", 1, 1, ctx, problems)
			_check_param_in_set("damage_type", "physical", ContentDefinition.DAMAGE_TYPES, ctx, problems)
		"gain_block":
			_require_int("amount", 0, ctx, problems)
		"heal":
			_require_int("amount", 1, ctx, problems)
		"draw_cards":
			_require_int("count", 1, ctx, problems)
		"apply_status":
			var status_id := _require_string("status_id", ctx, problems)
			_check_ref(registry, ContentDefinition.TYPE_STATUS, status_id, "status_id", ctx, problems)
			_check_int_min("stacks", 1, 1, ctx, problems)
			_check_param_in_set("target", "enemy", STATUS_TARGETS, ctx, problems)
		"remove_status":
			var removed_id := _require_string("status_id", ctx, problems)
			_check_ref(registry, ContentDefinition.TYPE_STATUS, removed_id, "status_id", ctx, problems)
		"modify_energy":
			if not params.has("delta"):
				problems.append("%s: kind 'modify_energy' requires param 'delta'" % ctx)
			elif int(params.get("delta", 0)) == 0:
				problems.append("%s: param 'delta' must not be 0" % ctx)
		"add_temporary_card":
			var card_id := _require_string("card_id", ctx, problems)
			_check_ref(registry, ContentDefinition.TYPE_CARD, card_id, "card_id", ctx, problems)
			_check_int_min("count", 1, 1, ctx, problems)
			_check_param_in_set("destination", "hand", CARD_DESTINATIONS, ctx, problems)
		"exhaust_card":
			_check_param_in_set("selector", "this", EXHAUST_SELECTORS, ctx, problems)
		"transform_card":
			var into_id := _require_string("into_card_id", ctx, problems)
			_check_ref(registry, ContentDefinition.TYPE_CARD, into_id, "into_card_id", ctx, problems)
		"modify_item":
			# item_id is optional (an effect may target "the item this card
			# came from" implicitly); nothing else is required yet.
			_check_ref(registry, ContentDefinition.TYPE_ITEM, str(params.get("item_id", "")), "item_id", ctx, problems)
		"conditional":
			var condition = params.get("condition")
			if not (condition is Dictionary) or (condition as Dictionary).is_empty():
				problems.append("%s: kind 'conditional' requires a non-empty 'condition' Dictionary param" % ctx)
			if then_effects.is_empty():
				problems.append("%s: kind 'conditional' requires a non-empty 'then' effect list" % ctx)
			_validate_children(registry, then_effects, "then", ctx, depth, problems)
			_validate_children(registry, else_effects, "else", ctx, depth, problems)
		"repeat":
			_require_int("times", 2, ctx, problems)
			if then_effects.is_empty():
				problems.append("%s: kind 'repeat' requires a non-empty 'effects' list" % ctx)
			_validate_children(registry, then_effects, "effect", ctx, depth, problems)
		"random_target":
			if then_effects.is_empty():
				problems.append("%s: kind 'random_target' requires a non-empty 'effects' list" % ctx)
			_validate_children(registry, then_effects, "effect", ctx, depth, problems)
	return problems


# ---------------------------------------------------------------------------
# Param validation helpers. No ContentDefinition helpers here (no id/_ctx),
# so problem messages are built from the caller-supplied ctx instead.
# ---------------------------------------------------------------------------

## Required int param: key must be present and coerce to >= minimum.
func _require_int(field: String, minimum: int, ctx: String, problems: Array[String]) -> void:
	if not params.has(field):
		problems.append("%s: kind '%s' requires param '%s'" % [ctx, kind, field])
		return
	var v := int(params.get(field, 0))
	if v < minimum:
		problems.append("%s: param '%s' must be >= %d (got %d)" % [ctx, field, minimum, v])


## Optional int param with a default: absent is fine, present must be >= minimum.
func _check_int_min(field: String, default_value: int, minimum: int, ctx: String, problems: Array[String]) -> void:
	var v := int(params.get(field, default_value))
	if v < minimum:
		problems.append("%s: param '%s' must be >= %d (got %d)" % [ctx, field, minimum, v])


## Required non-empty String param. Returns the coerced value for ref checks.
func _require_string(field: String, ctx: String, problems: Array[String]) -> String:
	var v := str(params.get(field, ""))
	if v.is_empty():
		problems.append("%s: kind '%s' requires param '%s'" % [ctx, kind, field])
	return v


## Optional enum-like String param: falls back to default_value when absent.
func _check_param_in_set(field: String, default_value: String, allowed: Array, ctx: String, problems: Array[String]) -> void:
	var v := str(params.get(field, default_value))
	if not allowed.has(v):
		problems.append("%s: param '%s' has invalid value '%s' (allowed: %s)" % [ctx, field, v, ", ".join(allowed)])


## Cross-reference check. Skipped when registry is null (pure unit tests) or
## the id is empty (missing required ids are reported by _require_string).
func _check_ref(registry, ref_type: String, ref_id: String, field: String, ctx: String, problems: Array[String]) -> void:
	if registry == null or ref_id.is_empty():
		return
	if not registry.has_def(ref_type, ref_id):
		problems.append("%s: param '%s' references missing %s '%s'" % [ctx, field, ref_type, ref_id])


## Recurses into nested effects with a "#<i>"-suffixed ctx and depth + 1.
func _validate_children(registry, children: Array[CardEffectDefinition], label: String, ctx: String, depth: int, problems: Array[String]) -> void:
	for i in children.size():
		problems.append_array(children[i].validate(registry, "%s %s#%d" % [ctx, label, i], depth + 1))
