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

func test_effect_int_params_reject_non_int() -> void:
	# Strictness: a coercible String/float must be rejected, not silently turned
	# into 0 / truncated. from_dict stores params raw, so a value that only
	# *looks* valid after int() would still ship wrong to the combat engine.
	var str_amount := CardEffectDefinition.from_dict({"kind": "deal_damage", "params": {"amount": "abc"}})
	assert_true(_has_problem(str_amount.validate(null, "t"), "must be an integer"), "string amount is rejected, not coerced to 0")
	var float_amount := CardEffectDefinition.from_dict({"kind": "deal_damage", "params": {"amount": 7.5}})
	assert_true(_has_problem(float_amount.validate(null, "t"), "must be an integer"), "float amount is rejected, not truncated to 7")
	var good := CardEffectDefinition.from_dict({"kind": "deal_damage", "params": {"amount": 6}})
	assert_false(_has_problem(good.validate(null, "t"), "must be an integer"), "a real int amount passes")

func test_effect_optional_int_and_energy_reject_non_int() -> void:
	# Optional int (deal_damage.times, via _check_int_min): a float must not
	# truncate to a valid count.
	var bad_times := CardEffectDefinition.from_dict({"kind": "deal_damage", "params": {"amount": 3, "times": 2.5}})
	assert_true(_has_problem(bad_times.validate(null, "t"), "must be an integer"), "float 'times' is rejected")
	# modify_energy.delta: a float must not slip past the != 0 check.
	var bad_delta := CardEffectDefinition.from_dict({"kind": "modify_energy", "params": {"delta": 1.0}})
	assert_true(_has_problem(bad_delta.validate(null, "t"), "must be an integer"), "float 'delta' is rejected")

func test_loot_amounts_reject_fractional() -> void:
	# Fractional min/max would truncate in validation but ship raw, so a "1.9/1.2"
	# pair could have max < min at roll time. Require real ints.
	var lt := LootTableDefinition.from_dict({
		"id": "bad_loot",
		"display_name": "Bad Loot",
		"entries": [{"kind": "remembrance", "weight": 1.0, "min_amount": 1.9, "max_amount": 1.2}],
	})
	var problems := lt.validate(null)
	assert_true(_has_problem(problems, "min_amount"), "fractional min_amount is rejected")
	assert_true(_has_problem(problems, "max_amount"), "fractional max_amount is rejected")

func test_enemy_hp_variance_bounded_by_base_hp() -> void:
	# Variance is a spread around base_hp; if it can reach base_hp an encounter
	# could roll the enemy in at 0 or negative HP.
	var too_wide := EnemyDefinition.from_dict(_enemy_dict({"base_hp": 4, "hp_variance": 6}))
	assert_true(_has_problem(too_wide.validate(null), "hp_variance"), "variance >= base_hp is a problem")
	var ok := EnemyDefinition.from_dict(_enemy_dict({"base_hp": 20, "hp_variance": 5}))
	assert_false(_has_problem(ok.validate(null), "hp_variance"), "variance < base_hp passes")

func test_empty_id_in_required_list_is_reported() -> void:
	# An empty string in a required id list must be reported, not skipped as an
	# absent optional reference — it would never resolve at runtime.
	var archetype := BodyArchetypeDefinition.from_dict({
		"id": "gapped_body",
		"display_name": "Gapped Body",
		"base_hp": 10,
		"base_energy": 1,
		"starting_item_ids": ["", "real_item"],
	})
	assert_true(_has_problem(archetype.validate(null), "empty id"), "empty starting_item_ids entry is a problem")
	var item := ItemDefinition.from_dict({
		"id": "nowhere_item",
		"display_name": "Nowhere Item",
		"category": "tool",
		"passive_modifiers": [{"kind": "noop"}],
		"universe_availability": [""],
	})
	assert_true(_has_problem(item.validate(null), "empty id"), "empty universe_availability entry is a problem")

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
