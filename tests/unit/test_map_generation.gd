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
		var found := false
		for node in map.all_nodes():
			if node.node_type == "item_search":
				found = true
				break
		assert_true(found, "seed %d has no item_search node" % s)

func test_boss_reachable_from_every_start() -> void:
	var map := MapGenerator.generate(RngStream.new(7))
	for start in map.start_nodes():
		assert_true(_reaches(map, start.id, map.boss_id), "boss unreachable from start %s" % start.id)

# ---------------------------------------------------------------------------

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
