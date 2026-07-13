class_name StatusEffectDefinition
extends ContentDefinition
## Status effect definition (Phase 2 data model) — registered under TYPE_STATUS.
##
## Status ids are mechanic-neutral (exposed, weakened, burning, ...) with all
## flavor kept in display_name/description, so every universe can reskin the
## same mechanics without new ids. Behavior is declared as data hooks that the
## combat engine (Phase 3) interprets — no per-status scripts.

## Const String arrays, not enums: content data references these by literal
## string.
const STACKING := ["intensity", "duration", "none"]
const DECAY := ["turn_start", "turn_end", "none"]
## Combat lifecycle points a status may react to. Hook payloads stay open
## dictionaries — the combat engine defines what it reads from them, so the
## data model only guarantees the shape (known hook name -> Dictionary).
const HOOKS := ["on_turn_start", "on_turn_end", "on_take_damage", "on_deal_damage", "on_combat_start", "on_combat_end"]

var stacking: String = "duration"
var decay: String = "turn_end"
## Drives UI treatment and effects like "remove all debuffs".
var is_debuff: bool = false
## hook name (see HOOKS) -> payload Dictionary.
var hooks: Dictionary = {}


func type_name() -> String:
	return TYPE_STATUS


static func from_dict(d: Dictionary) -> StatusEffectDefinition:
	var def := StatusEffectDefinition.new()
	def._apply_base(d)
	def.stacking = str(d.get("stacking", "duration"))
	def.decay = str(d.get("decay", "turn_end"))
	def.is_debuff = bool(d.get("is_debuff", false))
	# Kept as-is (not coerced) so validate() reports unknown hook names and
	# non-dictionary payloads instead of silently dropping them.
	var raw_hooks = d.get("hooks", {})
	def.hooks = raw_hooks if raw_hooks is Dictionary else {}
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	_check_in_set(stacking, STACKING, "stacking", problems)
	_check_in_set(decay, DECAY, "decay", problems)
	for hook_name in hooks:
		if not HOOKS.has(hook_name):
			problems.append(_ctx("hooks has unknown hook '%s' (allowed: %s)" % [hook_name, ", ".join(HOOKS)]))
		if not (hooks[hook_name] is Dictionary):
			problems.append(_ctx("hooks['%s'] payload must be a Dictionary" % hook_name))
	return problems
