extends TestCase
## Sample-content smoke tests: loads the real shipped content through
## ContentLoader and asserts it is complete, cross-referenced, and clean.
## These are the tests that catch a typo'd id in content/ before it becomes a
## runtime lookup failure mid-run.
##
## The ContentRegistry autoload is shared by every test in the process, so
## every method here clears it as its first line and its last line (and then
## reloads, since load order between test files is not guaranteed).

func test_load_all_registers_and_is_idempotent() -> void:
	ContentRegistry.clear()
	var first := ContentLoader.load_all(ContentRegistry)
	assert_gt(first, 0, "first load registers content")
	var second := ContentLoader.load_all(ContentRegistry)
	assert_eq(second, 0, "second load is a no-op (idempotent)")
	ContentRegistry.clear()

func test_sample_content_validates_clean() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	# Fail once per problem so a broken batch of content reads as a list of
	# exact, traceable messages instead of one opaque assertion.
	for problem in ContentRegistry.validate_all():
		fail(problem)
	ContentRegistry.clear()

func test_sample_content_counts() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	_assert_at_least(ContentDefinition.TYPE_ITEM, 12)
	_assert_at_least(ContentDefinition.TYPE_CARD, 14)
	_assert_at_least(ContentDefinition.TYPE_STATUS, 5)
	_assert_at_least(ContentDefinition.TYPE_TATTOO, 2)
	_assert_at_least(ContentDefinition.TYPE_MEMORY, 3)
	_assert_at_least(ContentDefinition.TYPE_ADAPTATION, 3)
	_assert_at_least(ContentDefinition.TYPE_BODY_ARCHETYPE, 1)
	assert_eq(ContentRegistry.ids_of(ContentDefinition.TYPE_MAP_NODE).size(), 12, "one map node per NODE_TYPES entry")
	var enemies: Array = ContentRegistry.all_of(ContentDefinition.TYPE_ENEMY).values()
	assert_eq(enemies.size(), 5, "exactly 3 normal + 1 elite + 1 boss enemies")
	var elites := 0
	var bosses := 0
	for enemy in enemies:
		if enemy.is_elite:
			elites += 1
		if enemy.is_boss:
			bosses += 1
	assert_eq(elites, 1, "exactly one elite enemy")
	assert_eq(bosses, 1, "exactly one boss enemy")
	ContentRegistry.clear()

func test_universe_fixed_order_matches_design() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	var universes: Array = ContentRegistry.all_of(ContentDefinition.TYPE_UNIVERSE).values()
	assert_eq(universes.size(), 3, "exactly 3 universes ship in Phase 2")
	var by_position := {}
	for universe in universes:
		by_position[universe.fixed_order_position] = universe.id
	# The first three lives are a scripted on-ramp; these ids are load-bearing
	# (the profile save's default unlocked universe is lovecraft_coast).
	assert_eq(str(by_position.get(1, "<missing>")), "lovecraft_coast", "life 1 universe")
	assert_eq(str(by_position.get(2, "<missing>")), "japanese_mythos", "life 2 universe")
	assert_eq(str(by_position.get(3, "<missing>")), "norse_mythos", "life 3 universe")
	ContentRegistry.clear()

func test_profile_default_universe_is_registered() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	var profile := SaveManager.default_data("profile")
	var unlocked: Array = profile.get("unlocked_universes", [])
	assert_false(unlocked.is_empty(), "profile default must unlock at least one universe")
	if not unlocked.is_empty():
		var universe_id := str(unlocked[0])
		assert_true(
			ContentRegistry.has_def(ContentDefinition.TYPE_UNIVERSE, universe_id),
			"default unlocked universe '%s' must be registered content" % universe_id
		)
	ContentRegistry.clear()

func _assert_at_least(content_type: String, minimum: int) -> void:
	var count := ContentRegistry.ids_of(content_type).size()
	assert_true(count >= minimum, "expected >= %d '%s' definitions, got %d" % [minimum, content_type, count])
