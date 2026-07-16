extends SceneTree
## TEMP verification scan — counts default-config maps with zero item_search.

func _init() -> void:
	var RngStreamC = load("res://core/rng/rng_stream.gd")
	var MapGen = load("res://gameplay/map/map_generator.gd")
	var total := 0
	var zero := 0
	var min_middle := 9999
	var first_fail := -1
	for s in range(0, 200000):
		var rng = RngStreamC.new(s)
		var map = MapGen.generate(rng, 7, 4, 6)
		var count := 0
		var middle := 0
		for node in map.all_nodes():
			if node.node_type == "item_search":
				count += 1
			if node.row > 0 and node.row < map.rows - 2:
				middle += 1
		min_middle = mini(min_middle, middle)
		total += 1
		if count == 0:
			zero += 1
			if first_fail < 0:
				first_fail = s
				var problems = map.validate()
				print("FIRST FAIL seed=%d middle_nodes=%d validate_problems=%s" % [s, middle, str(problems)])
	print("scanned=%d  zero_item_search=%d  min_middle_nodes=%d  first_fail_seed=%d" % [total, zero, min_middle, first_fail])
	quit()
