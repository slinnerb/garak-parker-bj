class_name IntentSelector
extends RefCounted
## Chooses an enemy's next intent (Phase 3 combat).
##
## Selection is data-driven and deterministic: it filters the enemy's intents by
## their conditions (HP thresholds, first-turn gating, cooldown / max-uses), then
## picks among the eligible ones per the enemy's behavior. weighted_random draws
## from the combat RNG stream so the same seed replays the same fight; sequence
## walks the intent list in order. Every enemy is guaranteed at least one
## unconditional intent (EnemyDefinition enforces this), so selection never
## comes up empty.


## Returns the chosen intent for this enemy's next turn (never null for a
## well-formed enemy). `rng` is only consumed by weighted_random.
static func select(enemy: EnemyState, rng: RngStream) -> EnemyIntentDefinition:
	var intents: Array = enemy.definition.intents
	var eligible: Array = []
	for intent in intents:
		if _condition_met(enemy, intent):
			eligible.append(intent)
	if eligible.is_empty():
		# Shouldn't happen (an unconditional intent always qualifies), but never
		# leave the enemy without a move.
		eligible = intents.duplicate()
	if enemy.definition.behavior == "sequence":
		return _select_sequence(enemy, intents, eligible)
	return _select_weighted(eligible, rng)


static func _select_weighted(eligible: Array, rng: RngStream) -> EnemyIntentDefinition:
	var weights: Array = []
	for intent in eligible:
		weights.append(intent.weight)
	var chosen = rng.pick_weighted(eligible, weights)
	return chosen if chosen != null else eligible[0]


## Walks the full intent list in definition order from a per-turn cursor and
## returns the first eligible entry, so a "sequence" enemy cycles predictably.
static func _select_sequence(enemy: EnemyState, intents: Array, eligible: Array) -> EnemyIntentDefinition:
	var count := intents.size()
	for offset in count:
		var intent = intents[(enemy.turns_taken + offset) % count]
		if eligible.has(intent):
			return intent
	return eligible[0]


static func _condition_met(enemy: EnemyState, intent: EnemyIntentDefinition) -> bool:
	var hp_fraction := float(enemy.hp) / float(enemy.max_hp)
	for key in intent.conditions:
		var value = intent.conditions[key]
		match key:
			"below_hp_pct":
				if not (hp_fraction < float(value)):
					return false
			"above_hp_pct":
				if not (hp_fraction > float(value)):
					return false
			"first_turn":
				if (enemy.turns_taken == 0) != bool(value):
					return false
			"not_first_turn":
				if (enemy.turns_taken > 0) != bool(value):
					return false
			"max_uses":
				if enemy.intent_use_count(intent.id) >= int(value):
					return false
			"cooldown":
				var since := enemy.turns_since_intent(intent.id)
				if since != -1 and since < int(value):
					return false
	return true
