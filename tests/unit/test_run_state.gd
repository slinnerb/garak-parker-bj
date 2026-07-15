extends TestCase
## Tests for RunState / RunManager: starting a life, walking the map, and how
## combat outcomes and item pickups change the run. Uses the real content and the
## RunManager autoload (shared across the process), so each test resets it.

func test_start_run_builds_body_and_map() -> void:
	var run := _start(1234)
	assert_ne(run.map, null, "a map is generated")
	assert_true(run.map.validate().is_empty(), "the run's map is valid")
	assert_gt(run.hp, 0, "starts with HP")
	assert_eq(run.hp, run.max_hp, "starts at full HP")
	# coastal_drifter's 3 starting items -> a 3-card starting deck.
	assert_eq(run.build_deck(ContentRegistry).size(), 3, "starting deck comes from the attuned starting items")
	_reset()

func test_start_is_deterministic() -> void:
	var m1 := _sig(_start(555).map)
	_reset()
	var m2 := _sig(_start(555).map)
	_reset()
	assert_eq(m1, m2, "same run seed => same map")

func test_traversal_rules() -> void:
	var run := _start(42)
	# Before entering, the choices are the entry row.
	var starts := run.available_next()
	assert_gt(starts.size(), 0, "there are start nodes to choose")
	assert_false(run.can_travel_to("does_not_exist"), "can't travel to a non-adjacent node")
	assert_true(run.travel_to(starts[0].id), "can enter a start node")
	# Now the choices are that node's forward connections.
	for node in run.available_next():
		assert_eq(node.row, run.current_node().row + 1, "next choices are one row ahead")
	_reset()

func test_walk_to_boss_and_win() -> void:
	var run := _start(7)
	var safety := 0
	while not run.at_boss() and safety < 50:
		var nexts := run.available_next()
		assert_gt(nexts.size(), 0, "always a way forward until the boss")
		run.travel_to(nexts[0].id)
		safety += 1
	assert_true(run.at_boss(), "the map can be walked to the boss")
	run.resolve_combat(20)  # survive the boss
	assert_true(run.is_victory(), "beating the boss with HP left wins the run")
	assert_true(run.is_over(), "a won run is over")
	_reset()

func test_death_ends_the_run() -> void:
	var run := _start(9)
	run.travel_to(run.available_next()[0].id)
	run.resolve_combat(0)  # died in a fight
	assert_true(run.is_defeat(), "0 HP is a defeat")
	assert_true(run.is_over(), "a lost run is over")
	assert_false(run.can_travel_to(run.available_next()[0].id if not run.available_next().is_empty() else "x"), "the dead don't travel")
	_reset()

func test_acquire_item_adds_and_attunes() -> void:
	var run := _start(3)
	var gaff: ItemDefinition = ContentRegistry.get_def("item", "fishermans_gaff")
	var before := run.build_deck(ContentRegistry).size()
	var attuned := run.acquire_item(gaff)
	assert_true(run.inventory.has("fishermans_gaff"), "the item goes into the bag")
	assert_true(attuned, "it attunes while slots remain (3 of 6 used)")
	assert_eq(run.build_deck(ContentRegistry).size(), before + 1, "and its card joins the deck")
	_reset()

# ---------------------------------------------------------------------------

func _start(seed_value: int) -> RunState:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	return RunManager.start_run(ContentRegistry, seed_value, "lovecraft_coast", "coastal_drifter")

func _reset() -> void:
	RunManager.end_run()
	ContentRegistry.clear()

func _sig(map: RunMap) -> String:
	var parts: Array[String] = []
	for node in map.all_nodes():
		parts.append("%s:%s" % [node.id, node.node_type])
	return "|".join(parts)
