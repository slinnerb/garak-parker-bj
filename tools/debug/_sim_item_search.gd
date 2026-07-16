extends SceneTree
## Throwaway Monte Carlo: how often does a generated map ship with ZERO
## item_search nodes (i.e. _guarantee_item_search silently failed)?

func _derive_seed(master_seed: int, name: String) -> int:
	var h: int = master_seed ^ 0x27d4eb2f165667c5
	for b in name.to_utf8_buffer():
		h = h ^ int(b)
		h = h * 1099511628211
	return h

func _init() -> void:
	var MG = load("res://gameplay/map/map_generator.gd")
	var RS = load("res://core/rng/rng_stream.gd")

	var trials := 500000
	var zero_search := 0
	var zero_middle_combat := 0
	var min_search := 1 << 30
	var min_middle_combat := 1 << 30
	var worst_seed := 0

	var rng := RandomNumberGenerator.new()
	rng.seed = 123456789  # deterministic sweep of "random" master seeds

	for i in trials:
		# Emulate a real run: fresh 32-bit master seed -> FNV-derived MAP stream.
		var master := rng.randi()
		var map_seed := _derive_seed(master, "map")
		var stream = RS.new(map_seed)
		var map = MG.generate(stream)  # default rows=7,width=4,paths=6

		var search_count := 0
		var middle_combat := 0
		for node in map.all_nodes():
			if node.node_type == "item_search":
				search_count += 1
			elif node.node_type == "combat" and node.row > 0 and node.row < map.rows - 2:
				middle_combat += 1

		if search_count == 0:
			zero_search += 1
		if middle_combat == 0:
			zero_middle_combat += 1
		if search_count < min_search:
			min_search = search_count
			worst_seed = master
		min_middle_combat = mini(min_middle_combat, middle_combat)

	print("trials=%d" % trials)
	print("maps_with_zero_item_search=%d" % zero_search)
	print("maps_with_zero_middle_combat_candidates=%d" % zero_middle_combat)
	print("min_item_search_count=%d (master_seed=%d)" % [min_search, worst_seed])
	print("min_middle_combat_candidate_count=%d" % min_middle_combat)
	quit()
