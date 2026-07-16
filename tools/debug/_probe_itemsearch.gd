extends SceneTree
## THROWAWAY probe: how often does a default-config map end up with ZERO
## item_search nodes? Confirms whether _guarantee_item_search can silently fail.

func _init() -> void:
	var Gen = load("res://gameplay/map/map_generator.gd")
	var RS = load("res://core/rng/rng_stream.gd")

	# 1) Structural rows=3 case (finding's deterministic claim).
	var r3_zero := 0
	for s in range(0, 200):
		var m = Gen.generate(RS.new(s), 3, 4, 6)
		if _count_search(m) == 0:
			r3_zero += 1
	print("rows=3 default: %d/200 seeds have ZERO item_search" % r3_zero)

	# 2) Shipped default config rows=7,width=4,paths=6.
	var scanned := 0
	var zero := 0
	var first_bad := -1
	for s in range(0, 200000):
		var m = Gen.generate(RS.new(s), 7, 4, 6)
		scanned += 1
		if _count_search(m) == 0:
			zero += 1
			if first_bad < 0:
				first_bad = s
	print("rows=7 default: %d/%d seeds have ZERO item_search (first bad seed=%d)" % [zero, scanned, first_bad])

	# 3) Small config rows=4 (finding says ~19-32%).
	var z4 := 0
	for s in range(0, 2000):
		var m = Gen.generate(RS.new(s), 4, 4, 6)
		if _count_search(m) == 0:
			z4 += 1
	print("rows=4: %d/2000 seeds have ZERO item_search" % z4)

	# 4) rows=5,width=2,paths=2 (finding says ~10%).
	var z5 := 0
	for s in range(0, 2000):
		var m = Gen.generate(RS.new(s), 5, 2, 2)
		if _count_search(m) == 0:
			z5 += 1
	print("rows=5,w=2,p=2: %d/2000 seeds have ZERO item_search" % z5)

	# If a rows=7 bad seed exists, confirm validate() still passes on it.
	if first_bad >= 0:
		var bad = Gen.generate(RS.new(first_bad), 7, 4, 6)
		var problems = bad.validate()
		print("rows=7 seed %d validate() problems: %s" % [first_bad, str(problems)])

	quit()

func _count_search(m) -> int:
	var n := 0
	for node in m.all_nodes():
		if node.node_type == "item_search":
			n += 1
	return n
