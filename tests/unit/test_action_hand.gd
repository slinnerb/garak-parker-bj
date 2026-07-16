extends TestCase
## Tests for ActionHand — loot → hand: attuned items become the freeze cards
## (Action Arc). Uses the real content set so the mapping is grounded.

func _content():
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	return ContentRegistry

func test_starting_loadout_maps_to_cards() -> void:
	var content = _content()
	var att := Attunement.new(6)
	for iid in ["rusted_harpoon", "oilskin_coat", "storm_lantern"]:
		att.attune(content.get_def("item", iid))
	var hand := ActionHand.build_hand(content, att)
	assert_eq(hand.size(), 3, "three starting items grant three cards")
	assert_eq(hand[0].display_name, "Harpoon Thrust", "cards keep their loot names")
	assert_eq(hand[0].kind, ActionCard.LASH, "weapon-tagged damage maps to melee lash")
	assert_true(is_equal_approx(hand[0].power, 18.0), "7 dmg x2.5 rounds to 18")
	assert_eq(hand[1].kind, ActionCard.WARD, "block maps to ward")
	assert_true(is_equal_approx(hand[1].power, 18.0), "6 block x3 = 18")
	assert_eq(hand[2].kind, ActionCard.BOLT, "non-weapon damage maps to a ranged bolt")
	assert_true(is_equal_approx(hand[2].power, 13.0), "4 dmg x2.5 + burning rider bonus = 13")

func test_heal_and_rider_bonus() -> void:
	var content = _content()
	var att := Attunement.new(8)
	att.attune(content.get_def("item", "tincture_of_salt"))
	att.attune(content.get_def("item", "barnacle_crusted_shield"))
	var hand := ActionHand.build_hand(content, att)
	assert_eq(hand[0].kind, ActionCard.HEAL, "heal effect maps to a heal card")
	assert_true(is_equal_approx(hand[0].power, 15.0), "6 heal x2.5 = 15")
	assert_eq(hand[1].kind, ActionCard.WARD, "shield wall maps to ward")
	assert_true(is_equal_approx(hand[1].power, 30.0), "9 block x3 + fortified rider = 30")

func test_hand_capped_at_max() -> void:
	var content = _content()
	var att := Attunement.new(20)
	for iid in ["rusted_harpoon", "oilskin_coat", "storm_lantern", "fishermans_gaff",
			"barnacle_crusted_shield", "tincture_of_salt", "signal_flare", "net_of_woven_hair"]:
		var item = content.get_def("item", iid)
		if item != null:
			att.attune(item)
	var hand := ActionHand.build_hand(content, att)
	assert_eq(hand.size(), ActionHand.MAX_HAND, "8 granted cards cap to MAX_HAND")

func test_empty_attunement_gives_empty_hand() -> void:
	var content = _content()
	var hand := ActionHand.build_hand(content, Attunement.new(6))
	assert_true(hand.is_empty(), "nothing attuned -> empty hand (caller falls back)")

func test_cooldown_scales_with_cost() -> void:
	var content = _content()
	var cheap = ActionHand.map_card(content.get_def("card", "harpoon_thrust"))   # cost 1
	var pricey = ActionHand.map_card(content.get_def("card", "shield_wall"))     # cost 2
	assert_true(pricey.cooldown > cheap.cooldown, "higher energy cost -> longer cooldown")
