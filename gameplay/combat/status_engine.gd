class_name StatusEngine
extends RefCounted
## Interprets StatusEffectDefinition data at runtime (Phase 3 combat).
##
## Statuses are declared as data: a stacking rule, a decay rule, and hook
## payloads the combat engine reads (see content/statuses.gd). This class is the
## single place that understands those payloads, so no status needs its own
## script. Everything is static and takes its dependencies explicitly (a content
## provider with get_def(), the owning combatant, and for turn hooks the
## CombatState that can mutate piles / log).
##
## Payload conventions this engine understands:
##   on_take_damage: {modifier: "incoming_damage_pct", amount: <pct per stack>}
##   on_deal_damage: {modifier: "outgoing_damage_pct", amount: <pct per stack>}
##   on_turn_start/on_turn_end action payloads:
##     {action: "take_damage", amount_per_stack, damage_type}  (ignores block)
##     {action: "heal", amount_per_stack}
##     {action: "gain_block", amount_per_stack}
##     {action: "add_card", card_id, destination}              (player only)

const TYPE_STATUS := "status"


## Applies `stacks` of a status per its stacking rule. intensity/duration add;
## "none" is a binary flag. Unknown status ids are ignored (already reported by
## content validation). `stacks` <= 0 is a no-op.
static func apply_status(content, owner: Combatant, status_id: String, stacks: int) -> void:
	if stacks <= 0:
		return
	var def = content.get_def(TYPE_STATUS, status_id) if content != null else null
	if def == null:
		return
	match def.stacking:
		"none":
			owner.set_status(status_id, 1)
		_:
			# intensity and duration both accumulate; the distinction is about
			# how the value reads to the player, not how it adds.
			owner.add_status_stacks(status_id, stacks)


## Decrements by one every status whose decay rule fires at `when`
## ("turn_start" or "turn_end"). Statuses reaching 0 are removed.
static func apply_decay(content, owner: Combatant, when: String) -> void:
	if content == null:
		return
	# Iterate a copy of the keys: set_status may erase during the loop.
	for status_id in owner.statuses.keys():
		var def = content.get_def(TYPE_STATUS, status_id)
		if def != null and def.decay == when:
			owner.add_status_stacks(status_id, -1)


## Outgoing damage multiplier from the attacker's statuses (e.g. Weakened).
## 1.0 = unmodified; clamped at 0 so heavy stacks can't heal the target.
static func outgoing_damage_multiplier(content, attacker: Combatant) -> float:
	return maxf(0.0, 1.0 + _percent_sum(content, attacker, "on_deal_damage", "outgoing_damage_pct"))


## Incoming damage multiplier from the defender's statuses (e.g. Exposed).
static func incoming_damage_multiplier(content, defender: Combatant) -> float:
	return maxf(0.0, 1.0 + _percent_sum(content, defender, "on_take_damage", "incoming_damage_pct"))


## Runs every matching turn-lifecycle hook on `owner`. `combat` supplies the
## content provider and pile/log callbacks. Iterates a key copy since hooks
## (e.g. burning) can kill and mutate.
static func run_turn_hook(combat, owner: Combatant, hook_name: String) -> void:
	var content = combat.content
	for status_id in owner.statuses.keys():
		var stacks := owner.get_status(status_id)
		if stacks <= 0:
			continue
		var def = content.get_def(TYPE_STATUS, status_id)
		if def == null:
			continue
		var payload = def.hooks.get(hook_name)
		if payload is Dictionary and not (payload as Dictionary).is_empty():
			_run_action(combat, owner, status_id, stacks, payload)


static func _run_action(combat, owner: Combatant, status_id: String, stacks: int, payload: Dictionary) -> void:
	match str(payload.get("action", "")):
		"take_damage":
			var amount := int(payload.get("amount_per_stack", 0)) * stacks
			var lost := owner.lose_hp(amount)  # DoT bypasses block
			if lost > 0:
				combat.log_event("%s takes %d from %s" % [owner.display_name, lost, status_id])
		"heal":
			var healed := owner.heal(int(payload.get("amount_per_stack", 0)) * stacks)
			if healed > 0:
				combat.log_event("%s heals %d from %s" % [owner.display_name, healed, status_id])
		"gain_block":
			var block := int(payload.get("amount_per_stack", 0)) * stacks
			owner.add_block(block)
			if block > 0:
				combat.log_event("%s gains %d block from %s" % [owner.display_name, block, status_id])
		"add_card":
			if owner is PlayerState:
				var card_id := str(payload.get("card_id", ""))
				var destination := str(payload.get("destination", "draw_pile"))
				combat.add_card_to_player(card_id, destination, 1)


## Sums (pct/100 * stacks) across an owner's statuses that declare `modifier`
## under `hook_name`. Positive raises, negative lowers.
static func _percent_sum(content, owner: Combatant, hook_name: String, modifier: String) -> float:
	if content == null:
		return 0.0
	var total := 0.0
	for status_id in owner.statuses:
		var def = content.get_def(TYPE_STATUS, status_id)
		if def == null:
			continue
		var payload = def.hooks.get(hook_name)
		if payload is Dictionary and str((payload as Dictionary).get("modifier", "")) == modifier:
			total += float((payload as Dictionary).get("amount", 0)) / 100.0 * owner.get_status(status_id)
	return total
