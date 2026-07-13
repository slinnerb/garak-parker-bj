extends TestCase
## Tests for deterministic RNG streams — the basis of reproducible runs.

func _sequence(seed: int, n: int) -> Array:
	var s := RngStream.new(seed)
	var out := []
	for i in n:
		out.append(s.randi_range(0, 1_000_000))
	return out

func test_same_seed_same_sequence() -> void:
	assert_eq(_sequence(12345, 10), _sequence(12345, 10), "identical seeds must replay identically")

func test_different_seed_different_sequence() -> void:
	assert_ne(_sequence(1, 10), _sequence(2, 10), "different seeds should diverge")

func test_reseed_restarts_sequence() -> void:
	var s := RngStream.new(999)
	var first := s.randi_range(0, 1_000_000)
	s.randi_range(0, 1_000_000)  # advance
	s.set_seed(999)
	assert_eq(s.randi_range(0, 1_000_000), first, "reseeding returns to the start")

func test_randi_range_bounds() -> void:
	var s := RngStream.new(7)
	for i in 200:
		var v := s.randi_range(3, 5)
		assert_true(v >= 3 and v <= 5, "value %d out of [3,5]" % v)

func test_chance_extremes() -> void:
	var s := RngStream.new(7)
	assert_true(s.chance(1.0), "chance(1.0) is always true")
	assert_false(s.chance(0.0), "chance(0.0) is always false")

func test_pick_weighted_respects_zero_weight() -> void:
	var s := RngStream.new(42)
	# "b" has all the weight; "a" and "c" can never be chosen.
	for i in 100:
		assert_eq(s.pick_weighted(["a", "b", "c"], [0, 1, 0]), "b")

func test_pick_weighted_empty_is_null() -> void:
	var s := RngStream.new(1)
	assert_eq(s.pick_weighted([], []), null)

func test_shuffle_is_deterministic_and_preserves_elements() -> void:
	var a := [1, 2, 3, 4, 5, 6, 7, 8]
	var b := [1, 2, 3, 4, 5, 6, 7, 8]
	RngStream.new(55).shuffle(a)
	RngStream.new(55).shuffle(b)
	assert_eq(a, b, "same seed shuffles identically")
	var sorted_a := a.duplicate()
	sorted_a.sort()
	assert_eq(sorted_a, [1, 2, 3, 4, 5, 6, 7, 8], "shuffle keeps every element")
