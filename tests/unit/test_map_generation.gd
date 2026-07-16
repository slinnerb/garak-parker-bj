extends TestCase
## Tests for the seeded run-map generator: the map is always a valid start-to-boss
## DAG, is reproducible from its seed, and honours the layout guarantees.

func test_generated_map_is_valid() -> void:
	# Try several seeds; every generated map must pass its own invariants.
	for s in 12:
		var map := MapGenerator.generate(RngStream.new(s * 31 + 7))
		var problems := map.validate()
		assert_true(problems.is_empty(), "seed %d produced an invalid map: %s" % [s, ", ".join(problems)])

func test_same_seed_same_map() -> void:
	var a := MapGenerator.generate(RngStream.new(4242))
	var b := MapGenerator.generate(RngStream.new(4242))
	assert_eq(_signature(a), _signature(b), "same seed must produce an identical map")

func test_different_seed_differs() -> void:
	var a := MapGenerator.generate(RngStream.new(1))
	var b := MapGenerator.generate(RngStream.new(2))
	assert_ne(_signature(a), _signature(b), "different seeds should (almost always) differ")

func test_layout_guarantees() -> void:
	var map := MapGenerator.generate(RngStream.new(99), 7, 4, 6)
	# Row 0 is a gentle, known combat step.
	for node in map.nodes_in_row(0):
		assert_eq(node.node_type, "combat", "entry row is combat")
	# Exactly one boss, terminal, in the last row.
	var last := map.nodes_in_row(map.rows - 1)
	assert_eq(last.size(), 1, "one boss node")
	assert_eq(last[0].node_type, "boss", "last row is the boss")
	assert_eq(last[0].id, map.boss_id, "boss_id points at it")
	assert_true(last[0].is_terminal(), "boss has no outgoing edges")
	# A guaranteed rest before the boss.
	for node in map.nodes_in_row(map.rows - 2):
		assert_eq(node.node_type, "rest", "the row before the boss is rest")

func test_at_least_one_item_search() -> void:
	# Even seeds that roll no item_search must get one injected.
	for s in 20:
		var map := MapGenerator.generate(RngStream.new(s))
		assert_true(_has_type(map, "item_search"), "seed %d has no item_search node" % s)

func test_item_search_guaranteed_on_tiny_and_narrow_maps() -> void:
	# Regression: the old guarantee only converted a middle *combat* node, so
	# tiny/narrow maps with no convertible combat node shipped with zero item
	# locations. The guarantee must now hold for every size and every seed.
	var configs := [[3, 2, 2], [4, 2, 2], [4, 3, 3], [5, 2, 2], [3, 4, 6]]
	for cfg in configs:
		for s in 40:
			var map := MapGenerator.generate(RngStream.new(s * 13 + 1), cfg[0], cfg[1], cfg[2])
			assert_true(_has_type(map, "item_search"),
				"rows=%d width=%d paths=%d seed=%d has no item_search" % [cfg[0], cfg[1], cfg[2], s])

func test_settings_drive_size() -> void:
	# floors/branches/lanes from map_gen_settings must actually shape the map,
	# not be silently ignored in favour of the generator defaults.
	var map := MapGenerator.generate_from_settings(RngStream.new(7), {"floors": 5, "lanes": 3, "branches": 3})
	assert_eq(map.rows, 5, "floors should set the row count")
	assert_eq(map.width, 3, "lanes should set the width")
	var big := MapGenerator.generate_from_settings(RngStream.new(7), {"floors": 9})
	assert_eq(big.rows, 9, "floors alone should still take effect")

func test_settings_guarantee_requested_types() -> void:
	# Every type in guaranteed_node_types must appear at least once.
	var map := MapGenerator.generate_from_settings(RngStream.new(3), {
		"floors": 7, "branches": 6, "guaranteed_node_types": ["item_search", "event", "elite"],
	})
	for t in ["item_search", "event", "elite"]:
		assert_true(_has_type(map, t), "guaranteed type '%s' is missing from the map" % t)

func test_settings_defaults_when_empty() -> void:
	# An empty settings dict must still produce a valid map with an item location.
	var map := MapGenerator.generate_from_settings(RngStream.new(11), {})
	assert_true(map.validate().is_empty(), "empty settings should still yield a valid map")
	assert_true(_has_type(map, "item_search"), "empty settings still guarantees an item location")

func test_settings_deterministic() -> void:
	var a := MapGenerator.generate_from_settings(RngStream.new(4242), {"floors": 7, "branches": 6})
	var b := MapGenerator.generate_from_settings(RngStream.new(4242), {"floors": 7, "branches": 6})
	assert_eq(_signature(a), _signature(b), "same seed + settings must produce an identical map")

func test_boss_reachable_from_every_start() -> void:
	var map := MapGenerator.generate(RngStream.new(7))
	for start in map.start_nodes():
		assert_true(_reaches(map, start.id, map.boss_id), "boss unreachable from start %s" % start.id)

# ---------------------------------------------------------------------------

func _has_type(map: RunMap, node_type: String) -> bool:
	for node in map.all_nodes():
		if node.node_type == node_type:
			return true
	return false

func _signature(map: RunMap) -> String:
	var parts: Array[String] = []
	for node in map.all_nodes():
		parts.append("%s(%s)->%s" % [node.id, node.node_type, ",".join(node.next_ids)])
	return "|".join(parts)

func _reaches(map: RunMap, from_id: String, target_id: String) -> bool:
	var seen := {}
	var stack: Array = [from_id]
	while not stack.is_empty():
		var id = stack.pop_back()
		if seen.has(id):
			continue
		seen[id] = true
		if id == target_id:
			return true
		for n in map.next_nodes(id):
			stack.append(n.id)
	return false
