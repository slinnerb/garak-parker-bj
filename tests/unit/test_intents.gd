extends TestCase
## Unit tests for IntentSelector — deterministic weighted choice and the
## condition gates (first-turn, cooldown, HP thresholds, max-uses). Enemies are
## built from inline definitions so each rule is exercised in isolation; no
## content registry is needed (intent selection reads only the enemy state).

func test_selection_is_deterministic() -> void:
	var e1 := _enemy(_three_intent_dict())
	var e2 := _enemy(_three_intent_dict())
	var seq1 := _selection_sequence(e1, 5, 100)
	var seq2 := _selection_sequence(e2, 5, 100)
	assert_eq(seq1, seq2, "same enemy + same seed => same intent sequence")

func test_first_turn_gate() -> void:
	# "opener" is first_turn only; "jab" is unconditional.
	var e := _enemy({
		"id": "gated", "display_name": "Gated", "base_hp": 20,
		"intents": [
			{"id": "opener", "kind": "attack", "amount": 9, "telegraph": "x", "weight": 1.0, "conditions": {"first_turn": true}},
			{"id": "jab", "kind": "attack", "amount": 3, "telegraph": "y", "weight": 1.0},
		],
	})
	assert_true(_eligible_ids(e).has("opener"), "opener available on the first turn")
	e.turns_taken = 1
	assert_false(_eligible_ids(e).has("opener"), "opener gone after the first turn")

func test_cooldown_gate() -> void:
	var e := _enemy({
		"id": "cd", "display_name": "CD", "base_hp": 20,
		"intents": [
			{"id": "big", "kind": "attack", "amount": 9, "telegraph": "x", "weight": 1.0, "conditions": {"cooldown": 2}},
			{"id": "small", "kind": "attack", "amount": 3, "telegraph": "y", "weight": 1.0},
		],
	})
	assert_true(_eligible_ids(e).has("big"), "cooldown move available before first use")
	# Simulate using it on turn 0.
	e.record_intent_performed("big")
	e.turns_taken = 1
	assert_false(_eligible_ids(e).has("big"), "on cooldown 1 turn later")
	e.turns_taken = 2
	assert_true(_eligible_ids(e).has("big"), "available again after 2 turns")

func test_below_hp_gate() -> void:
	var e := _enemy({
		"id": "hpgate", "display_name": "HP Gate", "base_hp": 100, "hp_variance": 0,
		"intents": [
			{"id": "desperate", "kind": "attack", "amount": 9, "telegraph": "x", "weight": 1.0, "conditions": {"below_hp_pct": 0.5}},
			{"id": "calm", "kind": "attack", "amount": 3, "telegraph": "y", "weight": 1.0},
		],
	})
	assert_false(_eligible_ids(e).has("desperate"), "desperate move locked at full HP")
	e.hp = 40  # 40% of 100
	assert_true(_eligible_ids(e).has("desperate"), "unlocked below 50% HP")

func test_max_uses_gate() -> void:
	var e := _enemy({
		"id": "limited", "display_name": "Limited", "base_hp": 20,
		"intents": [
			{"id": "once", "kind": "attack", "amount": 9, "telegraph": "x", "weight": 1.0, "conditions": {"max_uses": 1}},
			{"id": "spam", "kind": "attack", "amount": 3, "telegraph": "y", "weight": 1.0},
		],
	})
	assert_true(_eligible_ids(e).has("once"), "available before use")
	e.record_intent_performed("once")
	assert_false(_eligible_ids(e).has("once"), "gone after hitting max_uses")

func test_weighting_favors_higher_weight() -> void:
	# Loose statistical check: over many deterministic rolls, the 3x-weight
	# intent should be chosen clearly more than the 1x one.
	var counts := {"heavy": 0, "light": 0}
	for s in 200:
		var e := _enemy({
			"id": "w", "display_name": "W", "base_hp": 20,
			"intents": [
				{"id": "heavy", "kind": "attack", "amount": 5, "telegraph": "x", "weight": 3.0},
				{"id": "light", "kind": "attack", "amount": 5, "telegraph": "y", "weight": 1.0},
			],
		})
		var chosen := IntentSelector.select(e, RngStream.new(s))
		counts[chosen.id] += 1
	assert_gt(counts["heavy"], counts["light"], "3x weight is picked more often than 1x")

# ---------------------------------------------------------------------------

func _enemy(def_dict: Dictionary) -> EnemyState:
	# variance defaults to 0 here, so HP is exact and no RNG is consumed.
	return EnemyState.from_definition(EnemyDefinition.from_dict(def_dict), RngStream.new(0))

func _three_intent_dict() -> Dictionary:
	return {
		"id": "trio", "display_name": "Trio", "base_hp": 30, "hp_variance": 0,
		"intents": [
			{"id": "a", "kind": "attack", "amount": 5, "telegraph": "a", "weight": 2.0},
			{"id": "b", "kind": "defend", "amount": 5, "telegraph": "b", "weight": 1.0},
			{"id": "c", "kind": "attack", "amount": 8, "telegraph": "c", "weight": 1.0},
		],
	}

## Runs `count` selections with a fixed seed, recording performing each pick so
## cooldown/max-uses bookkeeping advances, and returns the id sequence.
func _selection_sequence(enemy: EnemyState, count: int, seed_value: int) -> Array:
	var rng := RngStream.new(seed_value)
	var ids: Array = []
	for _i in count:
		var intent := IntentSelector.select(enemy, rng)
		ids.append(intent.id)
		enemy.record_intent_performed(intent.id)
		enemy.turns_taken += 1
	return ids

func _eligible_ids(enemy: EnemyState) -> Array:
	# Selecting many times with varied seeds surfaces every currently-eligible
	# intent (weighted_random can only ever return an eligible one).
	var ids := {}
	for s in 50:
		ids[IntentSelector.select(enemy, RngStream.new(s)).id] = true
	return ids.keys()
