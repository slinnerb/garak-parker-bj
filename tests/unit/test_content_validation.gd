extends TestCase
## Registry-level validation tests: duplicate registration, cross-references
## surfacing through validate_all(), archetype slot budgets, and the global
## universe fixed-order checks.
##
## The ContentRegistry autoload is shared by every test in the process, so
## every method here clears it as its first line and its last line.

func test_duplicate_register_returns_false() -> void:
	ContentRegistry.clear()
	var card := CardDefinition.from_dict({"id": "dup_card", "display_name": "Dup Card"})
	assert_true(ContentRegistry.register(ContentDefinition.TYPE_CARD, card.id, card), "first register succeeds")
	assert_false(ContentRegistry.register(ContentDefinition.TYPE_CARD, card.id, card), "duplicate id is rejected")
	ContentRegistry.clear()

func test_missing_source_item_surfaces_in_validate_all() -> void:
	ContentRegistry.clear()
	var card := CardDefinition.from_dict({
		"id": "orphan_strike",
		"display_name": "Orphan Strike",
		"card_type": "attack",
		"targeting": "enemy",
		"source_item_id": "item_which_never_was",
		"effects": [{"kind": "deal_damage", "params": {"amount": 4}}],
	})
	ContentRegistry.register(ContentDefinition.TYPE_CARD, card.id, card)
	var problems := ContentRegistry.validate_all()
	assert_true(_has_problem(problems, "item_which_never_was"), "missing source item must surface in validate_all()")
	ContentRegistry.clear()

func test_archetype_slot_overflow_detected() -> void:
	ContentRegistry.clear()
	var harpoon := ItemDefinition.from_dict({
		"id": "heavy_harpoon",
		"display_name": "Heavy Harpoon",
		"category": "weapon",
		"slot_cost": 4,
		"granted_card_ids": ["strike_harpoon"],
	})
	var coat := ItemDefinition.from_dict({
		"id": "oiled_coat",
		"display_name": "Oiled Coat",
		"category": "defensive",
		"slot_cost": 3,
		"granted_card_ids": ["brace_coat"],
	})
	ContentRegistry.register(ContentDefinition.TYPE_ITEM, harpoon.id, harpoon)
	ContentRegistry.register(ContentDefinition.TYPE_ITEM, coat.id, coat)
	var archetype := BodyArchetypeDefinition.from_dict({
		"id": "test_body",
		"display_name": "Test Body",
		"base_hp": 50,
		"base_energy": 3,
		"base_slots": 6,
		"starting_item_ids": ["heavy_harpoon", "oiled_coat"],
	})
	var problems := archetype.validate(ContentRegistry)
	assert_true(_has_problem(problems, "slots"), "7 slots of starting items must not fit a 6-slot body")
	ContentRegistry.clear()

func test_universe_fixed_order_global_checks() -> void:
	ContentRegistry.clear()
	# Baseline: positions 1/2/3 each present exactly once. Whatever unrelated
	# global problems exist here (no playable universe, no archetype) exist
	# identically in the broken setup, so the size comparison isolates the
	# fixed-order rules without depending on exact message wording.
	_register_universe("u_one", 1)
	_register_universe("u_two", 2)
	_register_universe("u_three", 3)
	var baseline := ContentRegistry.validate_all()
	ContentRegistry.clear()
	# Broken: position 1 duplicated and position 3 missing.
	_register_universe("u_one", 1)
	_register_universe("u_two", 1)
	_register_universe("u_three", 2)
	var broken := ContentRegistry.validate_all()
	assert_gt(broken.size(), baseline.size(), "duplicate + missing fixed_order_position must add problems")
	assert_true(_has_problem(broken, "position"), "problems name the fixed-order position rule")
	ContentRegistry.clear()

func test_card_item_link_must_be_bidirectional() -> void:
	ContentRegistry.clear()
	# The card names harpoon as its source, but harpoon does not list the card.
	# Both refs resolve, so only the registry's both-ends check can catch it.
	var harpoon := ItemDefinition.from_dict({
		"id": "link_harpoon",
		"display_name": "Harpoon",
		"category": "weapon",
		"slot_cost": 1,
		"passive_modifiers": [{"kind": "noop"}],  # does something, but grants no cards
	})
	var card := CardDefinition.from_dict({
		"id": "link_strike",
		"display_name": "Strike",
		"card_type": "attack",
		"targeting": "enemy",
		"source_item_id": "link_harpoon",
		"effects": [{"kind": "deal_damage", "params": {"amount": 5}}],
	})
	ContentRegistry.register(ContentDefinition.TYPE_ITEM, harpoon.id, harpoon)
	ContentRegistry.register(ContentDefinition.TYPE_CARD, card.id, card)
	assert_true(_has_problem(ContentRegistry.validate_all(), "does not list this card"), "a one-way card->item link is a problem")
	ContentRegistry.clear()

func test_item_granting_card_sourced_elsewhere_is_a_problem() -> void:
	ContentRegistry.clear()
	# harpoon<->shared_strike is a consistent pair; the gaff also grants
	# shared_strike, but the card can only name one source (the harpoon), so the
	# gaff's grant is the inconsistency the reverse check must catch.
	var harpoon := ItemDefinition.from_dict({
		"id": "the_harpoon", "display_name": "Harpoon", "category": "weapon",
		"slot_cost": 1, "granted_card_ids": ["shared_strike"],
	})
	var gaff := ItemDefinition.from_dict({
		"id": "the_gaff", "display_name": "Gaff", "category": "weapon",
		"slot_cost": 1, "granted_card_ids": ["shared_strike"],
	})
	var card := CardDefinition.from_dict({
		"id": "shared_strike", "display_name": "Shared Strike", "card_type": "attack",
		"targeting": "enemy", "source_item_id": "the_harpoon",
		"effects": [{"kind": "deal_damage", "params": {"amount": 5}}],
	})
	ContentRegistry.register(ContentDefinition.TYPE_ITEM, harpoon.id, harpoon)
	ContentRegistry.register(ContentDefinition.TYPE_ITEM, gaff.id, gaff)
	ContentRegistry.register(ContentDefinition.TYPE_CARD, card.id, card)
	assert_true(_has_problem(ContentRegistry.validate_all(), "source_item_id"), "an item granting a card sourced to another item is a problem")
	ContentRegistry.clear()

func test_registration_failure_surfaces_in_validate_all() -> void:
	ContentRegistry.clear()
	# A definition dropped for an empty/duplicate id never validates itself; the
	# loader records the failure so the boot content gate still fails loudly.
	ContentRegistry.record_load_problem("content loader: could not register card 'twin' (empty or duplicate id)")
	assert_true(_has_problem(ContentRegistry.validate_all(), "could not register"), "recorded load problems surface in validate_all()")
	ContentRegistry.clear()
	# clear() must also drop load problems so they don't leak into later tests.
	assert_false(_has_problem(ContentRegistry.validate_all(), "could not register"), "clear() resets recorded load problems")
	ContentRegistry.clear()

func _register_universe(universe_id: String, position: int) -> void:
	var universe := UniverseDefinition.from_dict({
		"id": universe_id,
		"display_name": universe_id.capitalize(),
		"fixed_order_position": position,
	})
	ContentRegistry.register(ContentDefinition.TYPE_UNIVERSE, universe.id, universe)

## True when any problem message contains the needle (see test_definitions.gd).
func _has_problem(problems: Array[String], needle: String) -> bool:
	for p in problems:
		if p.contains(needle):
			return true
	return false
