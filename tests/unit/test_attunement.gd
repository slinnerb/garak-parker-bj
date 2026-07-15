extends TestCase
## Tests for the Phase 4 item->deck spine: Inventory (the bag) and Attunement
## (slot-limited loadout that generates the combat deck). Uses the real coastal
## items from the shared ContentRegistry, so these also guard that the sample
## content still has the shapes the demo relies on.

func test_inventory_add_remove_has() -> void:
	_load_content()
	var inv := Inventory.new()
	assert_true(inv.add(_item("rusted_harpoon")), "adds a new item")
	assert_false(inv.add(_item("rusted_harpoon")), "won't carry the same item twice")
	assert_true(inv.has("rusted_harpoon"), "reports carried items")
	assert_eq(inv.size(), 1, "size counts distinct items")
	assert_true(inv.remove("rusted_harpoon"), "removes a carried item")
	assert_false(inv.has("rusted_harpoon"), "no longer carried after removal")

func test_attune_respects_capacity() -> void:
	_load_content()
	var att := Attunement.new(2)
	assert_true(att.attune(_item("rusted_harpoon")), "first 1-slot item fits")
	assert_true(att.attune(_item("oilskin_coat")), "second 1-slot item fits")
	assert_eq(att.free_slots(), 0, "capacity is full")
	assert_false(att.attune(_item("storm_lantern")), "a third item overflows and is rejected")
	assert_eq(att.used_slots(), 2, "slot usage is exact")

func test_multi_slot_item_consumes_multiple_slots() -> void:
	_load_content()
	var att := Attunement.new(3)
	assert_true(att.attune(_item("barnacle_crusted_shield")), "the 2-slot shield fits in 3")
	assert_eq(att.used_slots(), 2, "shield consumes 2 slots")
	assert_true(att.attune(_item("rusted_harpoon")), "one 1-slot item still fits")
	assert_false(att.attune(_item("oilskin_coat")), "no room for a fourth slot")

func test_cannot_attune_twice() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("rusted_harpoon"))
	assert_false(att.attune(_item("rusted_harpoon")), "the same item can't be attuned twice")

func test_cursed_item_cannot_be_unattuned() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("weeping_figurehead"))  # cursed, removable == false
	assert_false(att.can_unattune("weeping_figurehead"), "cursed items resist removal")
	assert_false(att.unattune("weeping_figurehead"), "unattune is refused")
	assert_true(att.is_attuned("weeping_figurehead"), "and it stays attuned")

func test_normal_item_unattunes() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("rusted_harpoon"))
	assert_true(att.unattune("rusted_harpoon"), "a normal item can be removed")
	assert_eq(att.used_slots(), 0, "its slots free up")

func test_deck_derives_from_attuned_items() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("rusted_harpoon"))  # -> harpoon_thrust
	att.attune(_item("oilskin_coat"))    # -> brace_the_hull
	var deck := att.build_deck(ContentRegistry)
	var ids := _deck_ids(deck)
	assert_eq(deck.size(), 2, "two 1-card items make a 2-card deck")
	assert_true(ids.has("harpoon_thrust") and ids.has("brace_the_hull"), "deck holds each item's card")

func test_consumable_contributes_one_copy_per_charge() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("tincture_of_salt"))  # consumable, charges 2 -> swallow_tincture x2
	var deck := att.build_deck(ContentRegistry)
	assert_eq(deck.size(), 2, "a 2-charge consumable yields 2 cards")
	for card in deck:
		assert_eq(card.id(), "swallow_tincture", "both are the consumable's card")

func test_multi_card_item_grants_all_its_cards() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("drowned_mans_journal"))  # -> forbidden_passage, whispered_names
	var ids := _deck_ids(att.build_deck(ContentRegistry))
	assert_true(ids.has("forbidden_passage") and ids.has("whispered_names"), "both granted cards appear")

func test_passive_relic_grants_no_cards_but_modifiers() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("heart_of_the_reef"))  # relic: no cards, one passive modifier
	assert_eq(att.build_deck(ContentRegistry).size(), 0, "a passive relic adds no cards")
	assert_eq(att.passive_modifiers().size(), 1, "but contributes its passive modifier")

func test_deck_rebuilds_when_loadout_changes() -> void:
	_load_content()
	var att := Attunement.new(6)
	att.attune(_item("rusted_harpoon"))
	att.attune(_item("fishermans_gaff"))
	assert_eq(att.build_deck(ContentRegistry).size(), 2, "two items -> two cards")
	att.unattune("fishermans_gaff")
	assert_eq(att.build_deck(ContentRegistry).size(), 1, "removing an item drops its card from the deck")

func test_cursed_item_must_be_non_removable() -> void:
	# The curse-sticks rule is enforced two ways; content that contradicts it
	# (cursed but removable) must fail validation rather than rely on the
	# attunement safety net.
	var bad := ItemDefinition.from_dict({
		"id": "false_curse", "display_name": "False Curse", "category": "charm",
		"granted_card_ids": ["harpoon_thrust"], "cursed": true, "removable": true,
	})
	assert_true(_has_problem(bad.validate(null), "removable = false"), "a cursed-but-removable item is invalid")

func test_combat_demo_builds_deck_from_loadout() -> void:
	# Covers the CombatDemo build path (deck derivation -> shuffle -> draw pile),
	# which the pure-domain tests don't exercise. Asserts identity, not just size.
	_load_content()
	var combat := CombatDemo.build_from(ContentRegistry, RngStream.new(3),
		"coastal_drifter", ["rusted_harpoon", "tincture_of_salt"], "brine_soaked_villager")
	assert_ne(combat, null, "build_from produces a combat")
	var ids: Array = []
	for pile in [combat.player.hand, combat.player.draw_pile]:
		for card in pile:
			ids.append(card.id())
	assert_eq(ids.size(), 3, "harpoon (1) + tincture (2 charges) = a 3-card deck")
	assert_true(ids.has("harpoon_thrust"), "the weapon's card is present")
	assert_eq(ids.count("swallow_tincture"), 2, "the 2-charge consumable contributes 2 copies")

func test_combat_demo_default_is_deterministic() -> void:
	_load_content()
	var a := CombatDemo.build(ContentRegistry, RngStream.new(42))
	var b := CombatDemo.build(ContentRegistry, RngStream.new(42))
	assert_eq(_pile_ids(a.player.draw_pile), _pile_ids(b.player.draw_pile), "same seed -> same shuffled deck order")

func _pile_ids(pile: Array) -> Array:
	var ids: Array = []
	for card in pile:
		ids.append(card.id())
	return ids

# ---------------------------------------------------------------------------

func _load_content() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)

func _item(item_id: String) -> ItemDefinition:
	return ContentRegistry.get_def("item", item_id)

func _deck_ids(deck: Array) -> Array:
	var ids: Array = []
	for card in deck:
		ids.append(card.id())
	return ids

func _has_problem(problems: Array[String], needle: String) -> bool:
	for p in problems:
		if p.contains(needle):
			return true
	return false
