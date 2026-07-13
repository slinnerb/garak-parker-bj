class_name EnemyIntentDefinition
extends RefCounted
## One move an enemy can telegraph and perform (Phase 2 data model).
##
## Plain nested data owned by EnemyDefinition — not a ContentDefinition, so it
## has no registry type or id uniqueness of its own (the owning enemy checks
## uniqueness among its intents). The owner passes a ctx prefix like
## "enemy:deep_one_acolyte intent#0" into validate() so aggregated problem
## reports stay traceable to the exact intent. registry may be null — the
## status cross-reference check is skipped then.

## Closed vocabulary of intent kinds. Const String array, not an enum: content
## data references these by literal string.
const KINDS := ["attack", "defend", "buff", "debuff", "special"]

## Selection gates the intent AI understands. Anything else in `conditions`
## is a data error, so validate() rejects unknown keys instead of letting a
## typo silently disable (or always-enable) a move.
const CONDITION_KEYS := ["below_hp_pct", "above_hp_pct", "first_turn", "not_first_turn", "max_uses", "cooldown"]

var id: String = ""
var kind: String = ""
var amount: int = 0
var times: int = 1
## Applied status for buff/debuff kinds; unused otherwise.
var status_id: String = ""
var weight: float = 1.0
## Player-facing intent text — enemies always telegraph, so this is required.
var telegraph: String = ""
## Selection conditions (see CONDITION_KEYS). Empty means always available;
## every enemy needs at least one unconditional intent (EnemyDefinition
## enforces that so the enemy always has a legal move).
var conditions: Dictionary = {}


static func from_dict(d: Dictionary) -> EnemyIntentDefinition:
	var def := EnemyIntentDefinition.new()
	def.id = str(d.get("id", ""))
	def.kind = str(d.get("kind", ""))
	def.amount = int(d.get("amount", 0))
	def.times = int(d.get("times", 1))
	def.status_id = str(d.get("status_id", ""))
	def.weight = float(d.get("weight", 1.0))
	def.telegraph = str(d.get("telegraph", ""))
	# Condition values are kept as-is (not coerced) so validate() can report
	# bad types/ranges instead of silently normalizing them.
	var raw_conditions = d.get("conditions", {})
	def.conditions = raw_conditions if raw_conditions is Dictionary else {}
	return def


## Returns human-readable problems ([] = valid). ctx is the caller-supplied
## prefix used in every message; registry may be null (skips ref checks).
func validate(registry, ctx: String) -> Array[String]:
	var problems: Array[String] = []
	if id.is_empty():
		problems.append("%s: required field 'id' is empty" % ctx)
	if not KINDS.has(kind):
		problems.append("%s: field 'kind' has invalid value '%s' (allowed: %s)" % [ctx, kind, ", ".join(KINDS)])
	if (kind == "attack" or kind == "defend") and amount < 1:
		problems.append("%s: kind '%s' requires field 'amount' >= 1 (got %d)" % [ctx, kind, amount])
	if times < 1:
		problems.append("%s: field 'times' must be >= 1 (got %d)" % [ctx, times])
	if kind == "buff" or kind == "debuff":
		if status_id.is_empty():
			problems.append("%s: kind '%s' requires field 'status_id'" % [ctx, kind])
		elif registry != null and not registry.has_def(ContentDefinition.TYPE_STATUS, status_id):
			problems.append("%s: field 'status_id' references missing status '%s'" % [ctx, status_id])
	if weight <= 0.0:
		problems.append("%s: field 'weight' must be > 0 (got %s)" % [ctx, weight])
	if telegraph.is_empty():
		problems.append("%s: required field 'telegraph' is empty (intents are always shown to the player)" % ctx)
	_validate_conditions(ctx, problems)
	return problems


func _validate_conditions(ctx: String, problems: Array[String]) -> void:
	for key in conditions:
		if not CONDITION_KEYS.has(key):
			problems.append("%s: conditions has unknown key '%s' (allowed: %s)" % [ctx, key, ", ".join(CONDITION_KEYS)])
			continue
		var value = conditions[key]
		match key:
			"below_hp_pct", "above_hp_pct":
				var is_pct := (value is float or value is int) and float(value) >= 0.0 and float(value) <= 1.0
				if not is_pct:
					problems.append("%s: condition '%s' must be a number in 0..1 (got '%s')" % [ctx, key, value])
			"first_turn", "not_first_turn":
				if not (value is bool):
					problems.append("%s: condition '%s' must be a bool (got '%s')" % [ctx, key, value])
			"max_uses", "cooldown":
				if not (value is int and value >= 1):
					problems.append("%s: condition '%s' must be an int >= 1 (got '%s')" % [ctx, key, value])
