extends TestCase
## Integration test for the whole Phase 5 loop: start a run, walk the map, and at
## each node either fight (built from the run, auto-played) or take a boon, until
## the run reaches a conclusion (boss beaten or death). Proves map traversal,
## RunCombat, the combat engine, and outcome resolution all fit together with no
## stuck states.

func test_a_full_run_plays_to_a_conclusion() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	var run := RunManager.start_run(ContentRegistry, 4242, "lovecraft_coast", "coastal_drifter")

	var safety := 0
	var fights := 0
	while not run.is_over() and safety < 200:
		var nexts := run.available_next()
		if nexts.is_empty():
			break
		run.travel_to(nexts[0].id)  # greedy forward walk
		var node := run.current_node()
		if RunCombat.is_combat_node(node.node_type):
			var combat := RunCombat.build(ContentRegistry, run, RngStream.new(RunManager.encounter_seed(node.id)))
			assert_ne(combat, null, "a combat is built at node %s" % node.id)
			combat.start_combat()
			_auto_play(combat)
			run.resolve_combat(combat.player.hp)
			fights += 1
		else:
			run.heal(6)  # stands in for the inline boons the UI applies
		safety += 1

	assert_true(run.is_over(), "the run reaches a conclusion (victory or death), not a stuck state")
	assert_gt(fights, 0, "the run actually fought something")
	RunManager.end_run()
	ContentRegistry.clear()

func test_run_combat_uses_run_deck_and_hp() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)
	var run := RunManager.start_run(ContentRegistry, 7, "lovecraft_coast", "coastal_drifter")
	run.hp = 41  # carried damage
	run.travel_to(run.available_next()[0].id)  # a combat entry node
	var combat := RunCombat.build(ContentRegistry, run, RngStream.new(1))
	assert_ne(combat, null, "combat builds")
	assert_eq(combat.player.hp, 41, "player enters at the run's current HP")
	var deck := combat.player.hand.size() + combat.player.draw_pile.size()
	assert_eq(deck, 3, "the deck is the run's attuned starting items (3 cards)")
	RunManager.end_run()
	ContentRegistry.clear()

## Greedy auto-play: first affordable card each step, else end turn.
func _auto_play(combat: CombatState) -> void:
	var safety := 0
	while not combat.is_over() and safety < 2000:
		var played := false
		for i in combat.player.hand.size():
			if combat.can_play(i):
				combat.play_card(i, 0)
				played = true
				break
		if not played:
			combat.end_player_turn()
		safety += 1
