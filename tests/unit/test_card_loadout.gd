extends TestCase
## Tests for CardLoadout — the hand + cooldown bookkeeping behind freeze-queued
## cards (Action Arc, Phase B).

func _hand() -> Array:
	return [
		ActionCard.new("a", "A", ActionCard.BOLT, 10.0, 2.0),
		ActionCard.new("b", "B", ActionCard.WARD, 30.0, 3.0),
	]

func test_all_ready_initially() -> void:
	var l := CardLoadout.new(_hand())
	assert_eq(l.size(), 2, "loadout holds both cards")
	assert_true(l.is_ready(0), "card 0 ready at start")
	assert_true(l.is_ready(1), "card 1 ready at start")

func test_use_starts_cooldown() -> void:
	var l := CardLoadout.new(_hand())
	l.use(0)
	assert_false(l.is_ready(0), "used card is on cooldown")
	assert_true(l.cooldown_fraction(0) > 0.9, "cooldown shade near full right after use")
	assert_true(l.is_ready(1), "other card unaffected")

func test_tick_recovers() -> void:
	var l := CardLoadout.new(_hand())
	l.use(0)
	l.tick(1.0)
	assert_false(l.is_ready(0), "still cooling after 1s of a 2s cooldown")
	assert_true(l.cooldown_fraction(0) < 0.6, "cooldown shade shrinking")
	l.tick(1.2)
	assert_true(l.is_ready(0), "ready again after the cooldown elapses")

func test_out_of_range_is_safe() -> void:
	var l := CardLoadout.new(_hand())
	assert_false(l.is_ready(-1), "negative index not ready")
	assert_false(l.is_ready(9), "past-end index not ready")
	l.use(9)  # must not crash
	assert_true(is_equal_approx(l.cooldown_fraction(5), 0.0), "out-of-range fraction is 0")
