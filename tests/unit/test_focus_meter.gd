extends TestCase
## Tests for FocusMeter — the freeze-to-plan resource. Verifies the feel rules:
## draining while focusing, the forced-recharge exposure window, and regen.

func test_starts_full_and_idle() -> void:
	var m := FocusMeter.new()
	assert_true(is_equal_approx(m.fraction(), 1.0), "starts full")
	assert_false(m.active, "starts inactive")
	assert_true(is_equal_approx(m.time_factor(), 1.0), "no slowdown when idle")

func test_holding_focus_drains_and_slows() -> void:
	var m := FocusMeter.new()
	m.update(0.1, true)
	assert_true(m.active, "engages when held from full")
	assert_true(m.fraction() < 1.0, "draining while focused")
	assert_true(m.time_factor() < 1.0, "world slows while focused")

func test_drains_to_empty_then_forced_out() -> void:
	var m := FocusMeter.new()
	# Hold from full: it engages, drains (0.5/s over max 1.0 => ~2s), then is
	# forced out when empty and stays out while the input is still held.
	var saw_active := false
	var saw_forced_out := false
	for i in 30:
		m.update(0.1, true)
		if m.active:
			saw_active = true
		elif saw_active:
			saw_forced_out = true
	assert_true(saw_active, "engages while held from full")
	assert_true(saw_forced_out, "forced out after draining to empty")
	assert_false(m.active, "does not silently re-engage while still held")

func test_cannot_reengage_while_held_after_empty() -> void:
	var m := FocusMeter.new()
	for i in 30:  # drain to empty, keep holding
		m.update(0.1, true)
	assert_false(m.active, "held-empty does not auto re-engage")
	# Keep holding a while: it recharges but must NOT re-engage without a release.
	for i in 20:
		m.update(0.1, true)
	assert_false(m.active, "no re-engage until the input is released")

func test_regen_when_released_and_caps() -> void:
	var m := FocusMeter.new()
	for i in 10:  # partially drain
		m.update(0.1, true)
	var low := m.fraction()
	assert_true(low < 1.0, "partially drained")
	for i in 100:  # release and let it refill well past full
		m.update(0.1, false)
	assert_true(is_equal_approx(m.fraction(), 1.0), "regens back to full and caps")
	assert_false(m.active, "inactive while released")

func test_reengages_after_recharge() -> void:
	var m := FocusMeter.new()
	m.reengage_fraction = 0.3
	for i in 30:  # empty it
		m.update(0.1, true)
	for i in 20:  # release ~2s to climb above 30%
		m.update(0.1, false)
	assert_true(m.fraction() >= 0.3, "recharged above the re-engage threshold")
	m.update(0.05, true)
	assert_true(m.active, "can focus again once recharged")
