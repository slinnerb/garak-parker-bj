extends TestCase
## Definition-level tests (Phase 2 data model): from_dict defaults/coercion and
## validate() rules. The registry argument is null everywhere — these are pure
## data checks, so cross-reference lookups are skipped and no autoload is
## touched (which also means no ContentRegistry.clear() bookkeeping is needed).

func test_minimal_card_gets_defaults() -> void:
	var card := CardDefinition.from_dict({"id": "bare_hands", "display_name": "Bare Hands"})
	assert_eq(card.card_type, "skill")
	assert_eq(card.energy_cost, 1)
	assert_eq(card.targeting, "none")
	assert_eq(card.rarity, "common")
	assert_eq(card.source_item_id, "")
	assert_eq(card.effects.size(), 0)
	assert_false(card.exhaust or card.retain or card.temporary or card.consumable, "all flags default to false")

func test_from_dict_coerces_malformed_values() -> void:
	# Malformed data must never crash from_dict — it coerces to safe values and
	# lets validate() report anything that ends up wrong.
	var card := CardDefinition.from_dict({
		"id": "coerced",
		"display_name": "Coerced",
		"energy_cost": 2.9,
		"exhaust": 1,
		"effects": "not_a_list",
		"tags": {"not": "a list"},
	})
	assert_eq(card.energy_cost, 2, "float energy_cost truncates via int()")
	assert_true(card.exhaust, "truthy int coerces to bool")
	assert_eq(card.effects.size(), 0, "non-array effects become empty")
	assert_eq(card.tags.size(), 0, "non-array tags become empty")

func test_invalid_enum_values_reported() -> void:
	var card := CardDefinition.from_dict({
		"id": "weird_card",
		"display_name": "Weird Card",
		"card_type": "sorcery",
		"targeting": "everyone",
		"rarity": "mythic",
	})
	var problems := card.validate(null)
	assert_true(_has_problem(problems, "'card_type'"), "invalid card_type is reported")
	assert_true(_has_problem(problems, "'targeting'"), "invalid targeting is reported")
	assert_true(_has_problem(problems, "'rarity'"), "invalid rarity is reported")

func test_deal_damage_requires_amount() -> void:
	var effect := CardEffectDefinition.from_dict({"kind": "deal_damage", "params": {}})
	var problems := effect.validate(null, "test effect#0")
	assert_true(_has_problem(problems, "'amount'"), "deal_damage without amount is a problem")

func test_conditional_requires_condition_and_then() -> void:
	var no_condition := CardEffectDefinition.from_dict({
		"kind": "conditional",
		"params": {"then": [{"kind": "deal_damage", "params": {"amount": 3}}]},
	})
	assert_true(_has_problem(no_condition.validate(null, "test"), "'condition'"), "conditional without condition is a problem")
	var no_then := CardEffectDefinition.from_dict({
		"kind": "conditional",
		"params": {"condition": {"target_has_status": "exposed"}},
	})
	assert_true(_has_problem(no_then.validate(null, "test"), "'then'"), "conditional without then-effects is a problem")

func test_effect_nesting_depth_limit() -> void:
	# The leaf of N conditional wrappers validates at depth N; depth > 4 is the
	# authoring-mistake threshold, so 4 wrappers pass and 5 do not.
	var at_limit := _nested_conditionals(4)
	assert_false(_has_problem(at_limit.validate(null, "test"), "nested too deeply"), "nesting at the limit is allowed")
	var past_limit := _nested_conditionals(5)
	assert_true(_has_problem(past_limit.validate(null, "test"), "nested too deeply"), "nesting past the limit is a problem")

func test_trauma_memory_requires_drawback() -> void:
	var memory := MemoryDefinition.from_dict({
		"id": "the_drowning",
		"display_name": "The Drowning",
		"memory_type": "trauma",
		"effect": {"kind": "bonus_energy", "amount": 1},
	})
	assert_true(_has_problem(memory.validate(null), "drawback"), "trauma memory without drawback is a problem")
	memory.drawback = {"kind": "fear_of_water"}
	assert_false(_has_problem(memory.validate(null), "drawback"), "trauma memory with drawback passes")

func test_enemy_cannot_be_both_elite_and_boss() -> void:
	var enemy := EnemyDefinition.from_dict(_enemy_dict({"is_elite": true, "is_boss": true}))
	assert_true(_has_problem(enemy.validate(null), "is_elite and is_boss"), "elite+boss enemy is a problem")

func test_enemy_needs_unconditional_intent() -> void:
	var d := _enemy_dict({})
	d["intents"] = [_intent_dict("cornered", {"below_hp_pct": 0.5})]
	var gated := EnemyDefinition.from_dict(d)
	assert_true(_has_problem(gated.validate(null), "empty conditions"), "an enemy whose every intent is conditional is a problem")
	var fallback := EnemyDefinition.from_dict(_enemy_dict({}))
	assert_false(_has_problem(fallback.validate(null), "empty conditions"), "an unconditional intent satisfies the fallback rule")

## True when any problem message contains the needle. Substring matching keeps
## these tests about which rule fired, not about exact message wording.
func _has_problem(problems: Array[String], needle: String) -> bool:
	for p in problems:
		if p.contains(needle):
			return true
	return false

## Wraps a valid deal_damage leaf in `levels` valid conditional containers.
func _nested_conditionals(levels: int) -> CardEffectDefinition:
	var node: Dictionary = {"kind": "deal_damage", "params": {"amount": 1}}
	for i in levels:
		node = {"kind": "conditional", "params": {"condition": {"always": true}, "then": [node]}}
	return CardEffectDefinition.from_dict(node)

## A minimally valid enemy dict (one unconditional intent) with overrides.
func _enemy_dict(overrides: Dictionary) -> Dictionary:
	var d := {
		"id": "pale_swimmer",
		"display_name": "Pale Swimmer",
		"base_hp": 20,
		"intents": [_intent_dict("lunge", {})],
	}
	d.merge(overrides, true)
	return d

func _intent_dict(intent_id: String, conditions: Dictionary) -> Dictionary:
	return {
		"id": intent_id,
		"kind": "attack",
		"amount": 6,
		"telegraph": "It coils to strike.",
		"conditions": conditions,
	}
