extends TestCase
## Unit tests for StatusEngine — stacking, decay, damage modifiers, and turn
## hooks — in isolation from the full combat loop. Uses the real status content
## (loaded into the shared ContentRegistry) and a minimal enemy-less CombatState
## as the `combat` argument that hooks need for content/log/pile callbacks.

func test_intensity_status_stacks_add() -> void:
	_load_content()
	var c := _combatant()
	StatusEngine.apply_status(ContentRegistry, c, "exposed", 2)
	StatusEngine.apply_status(ContentRegistry, c, "exposed", 1)
	assert_eq(c.get_status("exposed"), 3, "intensity stacks accumulate")

func test_decay_reduces_matching_statuses() -> void:
	_load_content()
	var c := _combatant()
	StatusEngine.apply_status(ContentRegistry, c, "exposed", 3)      # decay turn_end
	StatusEngine.apply_status(ContentRegistry, c, "hallucinating", 2) # decay turn_start
	StatusEngine.apply_decay(ContentRegistry, c, "turn_end")
	assert_eq(c.get_status("exposed"), 2, "turn_end decay drops Exposed by 1")
	assert_eq(c.get_status("hallucinating"), 2, "turn_start decay leaves Hallucinating alone")
	StatusEngine.apply_decay(ContentRegistry, c, "turn_start")
	assert_eq(c.get_status("hallucinating"), 1, "turn_start decay drops Hallucinating by 1")

func test_status_removed_at_zero_stacks() -> void:
	_load_content()
	var c := _combatant()
	StatusEngine.apply_status(ContentRegistry, c, "exposed", 1)
	StatusEngine.apply_decay(ContentRegistry, c, "turn_end")
	assert_false(c.has_status("exposed"), "a status decaying to 0 is removed")

func test_outgoing_multiplier_scales_with_weakened_stacks() -> void:
	_load_content()
	var c := _combatant()
	assert_eq(StatusEngine.outgoing_damage_multiplier(ContentRegistry, c), 1.0, "no statuses => 1.0")
	StatusEngine.apply_status(ContentRegistry, c, "weakened", 1)
	assert_eq(StatusEngine.outgoing_damage_multiplier(ContentRegistry, c), 0.75, "1 Weakened => -25%")
	StatusEngine.apply_status(ContentRegistry, c, "weakened", 1)
	assert_eq(StatusEngine.outgoing_damage_multiplier(ContentRegistry, c), 0.5, "2 Weakened => -50%")

func test_incoming_multiplier_scales_with_exposed_stacks() -> void:
	_load_content()
	var c := _combatant()
	StatusEngine.apply_status(ContentRegistry, c, "exposed", 2)
	assert_eq(StatusEngine.incoming_damage_multiplier(ContentRegistry, c), 1.5, "2 Exposed => +50%")

func test_burning_hook_bypasses_block() -> void:
	_load_content()
	var combat := _combat()
	var c := combat.player
	c.add_block(10)
	c.hp = 30
	StatusEngine.apply_status(ContentRegistry, c, "burning", 2)
	StatusEngine.run_turn_hook(combat, c, "on_turn_end")
	assert_eq(c.hp, 28, "Burning deals 1/stack (2) straight to HP")
	assert_eq(c.block, 10, "damage-over-time ignores block")

func test_regeneration_hook_heals() -> void:
	_load_content()
	var combat := _combat()
	var c := combat.player
	c.hp = 20
	StatusEngine.apply_status(ContentRegistry, c, "regeneration", 3)
	StatusEngine.run_turn_hook(combat, c, "on_turn_end")
	assert_eq(c.hp, 23, "Regeneration heals 1/stack (3)")

func test_fortified_hook_grants_block() -> void:
	_load_content()
	var combat := _combat()
	var c := combat.player
	StatusEngine.apply_status(ContentRegistry, c, "fortified", 1)
	StatusEngine.run_turn_hook(combat, c, "on_turn_start")
	assert_eq(c.block, 2, "Fortified grants 2 block/stack at turn start")

func test_hallucinating_hook_adds_card_to_player() -> void:
	_load_content()
	var combat := _combat()
	var c := combat.player
	var before := c.draw_pile.size()
	StatusEngine.apply_status(ContentRegistry, c, "hallucinating", 1)
	StatusEngine.run_turn_hook(combat, c, "on_turn_start")
	assert_eq(c.draw_pile.size(), before + 1, "Hallucinating adds a card to the draw pile")
	assert_eq(c.draw_pile.back().id(), "half_heard_whisper", "and it's the junk whisper card")

# ---------------------------------------------------------------------------

func _load_content() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)

func _combatant() -> Combatant:
	return Combatant.new("t", "Test", 50)

## A minimal combat (no enemies) usable as the `combat` arg for turn hooks.
func _combat() -> CombatState:
	var player := PlayerState.new("player", "Wanderer", 70, 3, 5)
	return CombatState.new(ContentRegistry, RngStream.new(1), player, [])
