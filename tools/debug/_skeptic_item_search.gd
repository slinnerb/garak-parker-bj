extends SceneTree
## Throwaway probe: how often does MapGenerator produce a map with ZERO
## item_search nodes (the _guarantee_item_search hole)?

func _init() -> void:
	var RngStreamC = load("res://core/rng/rng_stream.gd")
	var MapGen = load("res://gameplay/map/map_generator.gd")

	# FNV-1a derive, copied from rng_service.gd _derive_seed for the "map" stream.
	var derive_map := func(master: int) -> int:
		var h: int = master ^ 0x27d4eb2f165667c5
		for b in "map".to_utf8_buffer():
			h = h ^ int(b)
			h = h * 1099511628211
		return h

	var trials := 500000
	var zero_raw := 0
	var zero_game := 0
	var min_middle := 1 << 30
	var total_middle := 0
	var examples_raw: Array = []
	var examples_game: Array = []

	for s in trials:
		# Path A: raw RngStream seed (what the unit test exercises).
		var map_a = MapGen.generate(RngStreamC.new(s))
		var cnt_a := _count_item_search(map_a)
		var mid := _count_middle(map_a)
		total_middle += mid
		if mid < min_middle:
			min_middle = mid
		if cnt_a == 0:
			zero_raw += 1
			if examples_raw.size() < 5:
				examples_raw.append(s)

		# Path B: the real in-game path — master seed -> FNV("map") -> stream.
		var game_seed: int = derive_map.call(s)
		var map_b = MapGen.generate(RngStreamC.new(game_seed))
		if _count_item_search(map_b) == 0:
			zero_game += 1
			if examples_game.size() < 5:
				examples_game.append(s)

	print("trials=%d" % trials)
	print("zero_item_search (raw seed path)  = %d  (%.6f%%)" % [zero_raw, 100.0 * zero_raw / trials])
	print("zero_item_search (game FNV path)  = %d  (%.6f%%)" % [zero_game, 100.0 * zero_game / trials])
	print("min middle-node count seen = %d" % min_middle)
	print("avg middle-node count = %.2f" % (float(total_middle) / trials))
	print("examples_raw = %s" % str(examples_raw))
	print("examples_game = %s" % str(examples_game))
	quit()


func _count_item_search(map) -> int:
	var n := 0
	for node in map.all_nodes():
		if node.node_type == "item_search":
			n += 1
	return n


# Middle rows = rolled rows 1..rows-3 (the ones eligible to be item_search/combat).
func _count_middle(map) -> int:
	var n := 0
	for node in map.all_nodes():
		if node.row > 0 and node.row < map.rows - 2:
			n += 1
	return n
