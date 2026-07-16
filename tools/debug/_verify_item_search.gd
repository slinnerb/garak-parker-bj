extends SceneTree
## Ad-hoc verification: how often does MapGenerator produce ZERO item_search?

func _initialize() -> void:
	var MapGen = load("res://gameplay/map/map_generator.gd")
	var RngStreamC = load("res://core/rng/rng_stream.gd")

	# 1) Default shipped config rows=7,width=4,paths=6 over many random-ish seeds.
	_scan(MapGen, RngStreamC, 7, 4, 6, 200000)
	# 2) Smaller configs the finding calls out.
	_scan(MapGen, RngStreamC, 5, 2, 2, 200000)
	_scan(MapGen, RngStreamC, 4, 4, 6, 200000)
	# 3) Structural: rows=3 (no roll rows). Expect 100% zero.
	_scan(MapGen, RngStreamC, 3, 4, 6, 50)

	quit()

func _scan(MapGen, RngStreamC, rows: int, width: int, paths: int, count: int) -> void:
	var zero := 0
	var first_zero_seed := -1
	# Use widely-spaced pseudo seeds to mimic derived stream seeds.
	for i in count:
		var s := (i * 2654435761) & 0x7fffffff
		var rng = RngStreamC.new(s)
		var map = MapGen.generate(rng, rows, width, paths)
		var has := false
		for node in map.all_nodes():
			if node.node_type == "item_search":
				has = true
				break
		if not has:
			zero += 1
			if first_zero_seed < 0:
				first_zero_seed = s
	var pct := 100.0 * float(zero) / float(count)
	print("rows=%d width=%d paths=%d : %d/%d zero-item_search (%.4f%%) first_zero_seed=%d" % [
		rows, width, paths, zero, count, pct, first_zero_seed])
