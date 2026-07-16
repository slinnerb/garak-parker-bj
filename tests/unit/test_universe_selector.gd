extends TestCase
## Tests for next-life universe selection: the fixed three-life opening, then
## seeded weighted randomness with no-repeat, recency penalties, unlock gates,
## and death-cause pull. Pure — profile is a plain dict.

func test_first_three_lives_are_fixed_order() -> void:
	_load_content()
	var profile := SaveManager.default_data("profile")
	assert_eq(_select(profile, 1), "lovecraft_coast", "life 1 is the coast")
	SoulProgression.begin_life(profile, "lovecraft_coast")
	assert_eq(_select(profile, 2), "japanese_mythos", "life 2 is the haunted isles")
	SoulProgression.begin_life(profile, "japanese_mythos")
	assert_eq(_select(profile, 3), "norse_mythos", "life 3 is the frozen world")
	ContentRegistry.clear()

func test_life_four_never_repeats_the_previous_universe() -> void:
	_load_content()
	var profile := _profile_after_three_lives()
	# Whatever the seed, the previous universe (norse) must not repeat.
	for s in 30:
		var chosen := UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(s))
		assert_ne(chosen, "norse_mythos", "seed %d repeated the previous universe" % s)
	ContentRegistry.clear()

func test_selection_is_deterministic_per_seed() -> void:
	_load_content()
	var profile := _profile_after_three_lives()
	var a := UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(9))
	var b := UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(9))
	assert_eq(a, b, "same profile + same seed => same destination")
	ContentRegistry.clear()

func test_unlock_requirements_gate_selection() -> void:
	_load_content()
	# A universe demanding 99 deaths must never be chosen on a fresh soul.
	var gated := UniverseDefinition.from_dict({
		"id": "gated_world", "display_name": "Gated World",
		"base_weight": 1000.0, "unlock_requirements": {"min_deaths": 99},
	})
	ContentRegistry.register(ContentDefinition.TYPE_UNIVERSE, gated.id, gated)
	var profile := _profile_after_three_lives()
	for s in 15:
		var chosen := UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(s))
		assert_ne(chosen, "gated_world", "a locked universe was chosen (seed %d)" % s)
	# Unknown requirement keys fail closed.
	var weird := UniverseDefinition.from_dict({
		"id": "weird_world", "display_name": "Weird World",
		"base_weight": 1000.0, "unlock_requirements": {"requires_moon_phase": true},
	})
	ContentRegistry.register(ContentDefinition.TYPE_UNIVERSE, weird.id, weird)
	for s in 15:
		assert_ne(UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(s)), "weird_world",
			"an unknown unlock gate must stay locked (seed %d)" % s)
	ContentRegistry.clear()

func test_degenerate_pool_falls_back_to_previous() -> void:
	_load_content()
	# Lock everything behind impossible gates: selection can't fail, it repeats.
	var profile := _profile_after_three_lives()
	for id in ContentRegistry.ids_of(ContentDefinition.TYPE_UNIVERSE):
		var def = ContentRegistry.get_def(ContentDefinition.TYPE_UNIVERSE, id)
		def.unlock_requirements = {"min_deaths": 999}
	var chosen := UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(1))
	assert_eq(chosen, "norse_mythos", "with nothing eligible, the soul returns where it was")
	ContentRegistry.clear()

# ---------------------------------------------------------------------------

func _load_content() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)

func _select(profile: Dictionary, _life: int) -> String:
	return UniverseSelector.select_next(ContentRegistry, profile, RngStream.new(1))

func _profile_after_three_lives() -> Dictionary:
	var profile := SaveManager.default_data("profile")
	for u in ["lovecraft_coast", "japanese_mythos", "norse_mythos"]:
		SoulProgression.begin_life(profile, u)
	return profile
