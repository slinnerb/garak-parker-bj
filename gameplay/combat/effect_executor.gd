class_name EffectExecutor
extends RefCounted
## Executes CardEffectDefinition atoms against a combat (Phase 3 combat).
##
## This is the one place card behavior is interpreted, so complex cards compose
## reusable effects instead of shipping scripts (docs/CONTENT_SCHEMA.md). Every
## handler is static and reads its world through an EffectContext. Container
## kinds (conditional / repeat / random_target) recurse back through execute().
##
## Damage flows through the full modifier chain: attacker's outgoing multiplier
## (e.g. Weakened) x defender's incoming multiplier (e.g. Exposed) x the target's
## damage-type multiplier, then block, per hit.

const TYPE_CARD := "card"


## Runs one effect (and, for containers, its children).
static func execute(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	match effect.kind:
		"deal_damage":
			_deal_damage(ctx, effect)
		"gain_block":
			ctx.source.add_block(int(effect.params.get("amount", 0)))
		"heal":
			ctx.source.heal(int(effect.params.get("amount", 0)))
		"draw_cards":
			if ctx.source is PlayerState:
				ctx.combat.player_draw(int(effect.params.get("count", 0)))
		"apply_status":
			_apply_status(ctx, effect)
		"remove_status":
			ctx.source.set_status(str(effect.params.get("status_id", "")), 0)
		"modify_energy":
			if ctx.source is PlayerState:
				ctx.combat.modify_player_energy(int(effect.params.get("delta", 0)))
		"add_temporary_card":
			_add_temporary_card(ctx, effect)
		"exhaust_card":
			_exhaust_card(ctx, effect)
		"transform_card":
			_transform_card(ctx, effect)
		"modify_item":
			# Items don't participate in combat until Phase 4 (attunement); until
			# then there is nothing to modify. Logged so it isn't silently lost.
			ctx.combat.log_event("modify_item effect skipped (items land in Phase 4)")
		"conditional":
			if _condition_met(ctx, effect.params.get("condition", {})):
				_run_all(ctx, effect.then_effects)
			else:
				_run_all(ctx, effect.else_effects)
		"repeat":
			for _i in maxi(0, int(effect.params.get("times", 1))):
				_run_all(ctx, effect.then_effects)
		"random_target":
			_random_target(ctx, effect)


static func _run_all(ctx: EffectContext, effects: Array[CardEffectDefinition]) -> void:
	for child in effects:
		execute(ctx, child)


static func _deal_damage(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	var base := int(effect.params.get("amount", 0))
	var times := maxi(1, int(effect.params.get("times", 1)))
	var damage_type := str(effect.params.get("damage_type", "physical"))
	var out_mult := StatusEngine.outgoing_damage_multiplier(ctx.content, ctx.source)
	for target in ctx.targets:
		for _hit in times:
			if not target.is_alive():
				break
			var amount := base * out_mult
			amount *= StatusEngine.incoming_damage_multiplier(ctx.content, target)
			if target is EnemyState:
				amount *= (target as EnemyState).damage_multiplier(damage_type)
				# Soul adaptations sharpen the player's hand vs certain foes.
				if ctx.source is PlayerState:
					amount *= ctx.combat.adaptation_bonus_multiplier(target)
			var final_amount := maxi(0, int(round(amount)))
			var dealt: int = target.receive_damage(final_amount)
			ctx.combat.log_event("%s hits %s for %d (%s)" % [ctx.source.display_name, target.display_name, dealt, damage_type])
			ctx.combat.note_damage_to(target)


static func _apply_status(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	var status_id := str(effect.params.get("status_id", ""))
	var stacks := int(effect.params.get("stacks", 1))
	var target_mode := str(effect.params.get("target", "enemy"))
	for who in _status_targets(ctx, target_mode):
		StatusEngine.apply_status(ctx.content, who, status_id, stacks)


## Resolves apply_status' target param to actual combatants.
static func _status_targets(ctx: EffectContext, target_mode: String) -> Array:
	match target_mode:
		"self":
			return [ctx.source]
		"all_enemies":
			return ctx.combat.living_enemies()
		_:  # "enemy" — the card's already-resolved targets
			return ctx.targets


static func _add_temporary_card(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	var card_id := str(effect.params.get("card_id", ""))
	var count := maxi(1, int(effect.params.get("count", 1)))
	var destination := str(effect.params.get("destination", "hand"))
	ctx.combat.add_card_to_player(card_id, destination, count, true)


static func _exhaust_card(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	match str(effect.params.get("selector", "this")):
		"this":
			ctx.combat.mark_current_card_exhaust()
		_:  # "chosen" / "random_in_hand" — no UI selection headlessly, pick randomly
			ctx.combat.exhaust_random_in_hand(ctx.card, ctx.rng)


static func _transform_card(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	# Transforms a random other card in hand into the named card. (Selecting a
	# specific card needs UI; headless play transforms at random.)
	var into_id := str(effect.params.get("into_card_id", ""))
	var into_def = ctx.content.get_def(TYPE_CARD, into_id)
	if into_def == null:
		return
	ctx.combat.transform_random_in_hand(ctx.card, into_def, ctx.rng)


static func _random_target(ctx: EffectContext, effect: CardEffectDefinition) -> void:
	var living: Array = ctx.combat.living_enemies()
	if living.is_empty():
		return
	var chosen: Combatant = ctx.rng.pick(living)
	_run_all(ctx.with_targets([chosen]), effect.then_effects)


## Evaluates a card-effect condition dictionary (all keys AND together). The
## card condition vocabulary is open (Phase 2 left it free-form); these are the
## keys the engine understands today. An unknown key fails closed.
static func _condition_met(ctx: EffectContext, condition: Dictionary) -> bool:
	for key in condition:
		var value = condition[key]
		match key:
			"chance_pct":
				if not ctx.rng.chance(float(value) / 100.0):
					return false
			"source_hp_below_pct":
				if not (float(ctx.source.hp) / ctx.source.max_hp < float(value)):
					return false
			"source_hp_above_pct":
				if not (float(ctx.source.hp) / ctx.source.max_hp > float(value)):
					return false
			"source_has_status":
				if not ctx.source.has_status(str(value)):
					return false
			"target_has_status":
				if not _any_target_has_status(ctx, str(value)):
					return false
			"enemies_alive_at_least":
				if ctx.combat.living_enemies().size() < int(value):
					return false
			_:
				ctx.combat.log_event("unknown card condition '%s' — treated as false" % key)
				return false
	return true


static func _any_target_has_status(ctx: EffectContext, status_id: String) -> bool:
	for target in ctx.targets:
		if target.has_status(status_id):
			return true
	return false
