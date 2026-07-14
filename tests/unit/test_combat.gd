extends TestCase
## Integration tests for the Phase 3 combat engine, driven against the real
## Lovecraft content. Each test loads content fresh (the ContentRegistry autoload
## is shared across the process) and builds a combat by hand, then drives turns
## and asserts on the resulting state and combat log.

# A dummy enemy with fixed HP (no variance) and one unconditional attack, so
# damage assertions are exact and don't depend on an HP roll.
const DUMMY_ENEMY := {
	"id": "test_dummy",
	"display_name": "Dummy",
	"base_hp": 50,
	"hp_variance": 0,
	"intents": [{"id": "poke", "kind": "attack", "amount": 5, "telegraph": "It pokes.", "weight": 1.0}],
	"universe_availability": ["*"],
}


func test_enemy_hp_roll_is_deterministic() -> void:
	_load_content()
	var def := EnemyDefinition.from_dict({
		"id": "roller", "display_name": "Roller", "base_hp": 30, "hp_variance": 6,
		"intents": [{"id": "a", "kind": "attack", "amount": 1, "telegraph": "x"}],
	})
	var a := EnemyState.from_definition(def, RngStream.new(777))
	var b := EnemyState.from_definition(def, RngStream.new(777))
	var c := EnemyState.from_definition(def, RngStream.new(778))
	assert_eq(a.hp, b.hp, "same seed rolls the same HP")
	assert_true(a.hp >= 24 and a.hp <= 36, "HP stays within base +/- variance")
	assert_ne(a.hp, c.hp, "a different seed rolls differently (given this pair)")

func test_basic_attack_deals_damage() -> void:
	var combat := _combat(1, ["harpoon_thrust"], [DUMMY_ENEMY])
	combat.start_combat()
	assert_true(_play(combat, "harpoon_thrust"), "harpoon is playable")
	assert_eq(combat.enemies[0].hp, 43, "7 damage off 50 HP")

func test_block_absorbs_enemy_attack() -> void:
	var combat := _combat(2, ["brace_the_hull"], [DUMMY_ENEMY])
	combat.start_combat()
	_play(combat, "brace_the_hull")  # +6 block
	assert_eq(combat.player.block, 6, "brace grants 6 block")
	var hp_before := combat.player.hp
	combat.end_player_turn()  # dummy pokes for 5, fully blocked
	assert_eq(combat.player.hp, hp_before, "5 damage fully absorbed by 6 block")

func test_exposed_increases_incoming_damage() -> void:
	var combat := _combat(3, ["gaff_hook", "harpoon_thrust"], [DUMMY_ENEMY])
	combat.start_combat()
	_play(combat, "gaff_hook")  # 6 damage, then +1 Exposed
	assert_eq(combat.enemies[0].hp, 44, "gaff deals 6 before Exposed applies")
	assert_true(combat.enemies[0].has_status("exposed"), "gaff applies Exposed")
	_play(combat, "harpoon_thrust")  # 7 * 1.25 = 8.75 -> 9
	assert_eq(combat.enemies[0].hp, 35, "Exposed raises the 7-hit to 9")

func test_weakened_reduces_outgoing_damage() -> void:
	var combat := _combat(4, ["harpoon_thrust"], [DUMMY_ENEMY])
	combat.start_combat()
	StatusEngine.apply_status(ContentRegistry, combat.player, "weakened", 1)
	_play(combat, "harpoon_thrust")  # 7 * 0.75 = 5.25 -> 5
	assert_eq(combat.enemies[0].hp, 45, "Weakened lowers the 7-hit to 5")

func test_multi_hit_card() -> void:
	var combat := _combat(5, ["siren_lament"], [DUMMY_ENEMY])
	combat.start_combat()
	_play(combat, "siren_lament")  # 5 cosmic x2 = 10
	assert_eq(combat.enemies[0].hp, 40, "two 5-damage hits land")

func test_heal_card_exhausts() -> void:
	var combat := _combat(6, ["swallow_tincture"], [DUMMY_ENEMY])
	combat.start_combat()
	combat.player.hp = 40
	_play(combat, "swallow_tincture")  # heal 6, exhaust
	assert_eq(combat.player.hp, 46, "tincture heals 6")
	assert_eq(combat.player.exhaust_pile.size(), 1, "tincture exhausts after use")
	assert_eq(combat.player.discard_pile.size(), 0, "exhausted cards don't hit the discard")

func test_flare_burst_hits_all_enemies() -> void:
	var combat := _combat(7, ["flare_burst"], [DUMMY_ENEMY, DUMMY_ENEMY.duplicate()])
	combat.start_combat()
	_play(combat, "flare_burst")  # 8 fire to all
	assert_eq(combat.enemies[0].hp, 42, "first enemy hit")
	assert_eq(combat.enemies[1].hp, 42, "second enemy hit")

func test_energy_gates_play() -> void:
	var combat := _combat(8, ["shield_wall", "shield_wall", "shield_wall"], [DUMMY_ENEMY])
	combat.start_combat()
	# shield_wall costs 2; with 3 energy only one can be played, leaving 1 energy.
	assert_true(_play(combat, "shield_wall"), "first shield_wall affordable")
	assert_eq(combat.player.energy, 1, "2 energy spent")
	var idx := _find_in_hand(combat, "shield_wall")
	assert_false(combat.can_play(idx), "second shield_wall unaffordable at 1 energy")

func test_unplayable_curse_and_status_cards() -> void:
	var combat := _combat(9, ["dirge_of_the_drowned", "half_heard_whisper"], [DUMMY_ENEMY])
	combat.start_combat()
	assert_false(combat.can_play(_find_in_hand(combat, "dirge_of_the_drowned")), "curse card is unplayable")
	assert_false(combat.can_play(_find_in_hand(combat, "half_heard_whisper")), "status card is unplayable")

func test_victory_when_enemy_dies() -> void:
	var weak := DUMMY_ENEMY.duplicate()
	weak["base_hp"] = 7
	var combat := _combat(10, ["harpoon_thrust"], [weak])
	combat.start_combat()
	_play(combat, "harpoon_thrust")  # 7 damage kills a 7-HP enemy
	assert_true(combat.is_victory(), "killing the last enemy wins")
	assert_true(combat.is_over(), "combat is over on victory")

func test_defeat_when_player_dies() -> void:
	var combat := _combat(11, ["brace_the_hull"], [DUMMY_ENEMY])
	combat.start_combat()
	combat.player.hp = 3
	combat.player.block = 0
	combat.end_player_turn()  # dummy pokes for 5 into 3 HP
	assert_true(combat.is_defeat(), "lethal enemy hit is a defeat")

func test_hand_drawn_and_discarded_each_turn() -> void:
	var combat := _combat(12, ["harpoon_thrust", "gaff_hook", "brace_the_hull"], [DUMMY_ENEMY])
	combat.start_combat()
	assert_eq(combat.player.hand.size(), 3, "whole small deck is drawn")
	combat.end_player_turn()  # unplayed cards discarded, then a fresh hand next turn
	# After the enemy acts, a new player turn drew the reshuffled deck again.
	assert_eq(combat.player.hand.size(), 3, "a fresh hand is drawn next turn")

func test_full_fight_is_deterministic() -> void:
	var log_a := _auto_fight_log(4242)
	var log_b := _auto_fight_log(4242)
	assert_eq(log_a, log_b, "same seed + same policy => identical combat log")
	var log_c := _auto_fight_log(9999)
	assert_ne(log_a, log_c, "a different seed diverges")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _load_content() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)

## Builds a started-ready combat: player with the given deck, enemies from inline
## dicts. hand_size is large so the whole test deck lands in hand.
func _combat(seed_value: int, card_ids: Array, enemy_dicts: Array) -> CombatState:
	_load_content()
	var rng := RngStream.new(seed_value)
	var player := PlayerState.new("player", "Wanderer", 70, 3, 10)
	for cid in card_ids:
		player.add_to_draw_pile(CardInstance.new(ContentRegistry.get_def("card", cid)))
	var enemies: Array = []
	for ed in enemy_dicts:
		enemies.append(EnemyState.from_definition(EnemyDefinition.from_dict(ed), rng))
	return CombatState.new(ContentRegistry, rng, player, enemies)

func _find_in_hand(combat: CombatState, card_id: String) -> int:
	for i in combat.player.hand.size():
		if combat.player.hand[i].id() == card_id:
			return i
	return -1

func _play(combat: CombatState, card_id: String, target: int = 0) -> bool:
	var idx := _find_in_hand(combat, card_id)
	if idx < 0:
		return false
	return combat.play_card(idx, target)

## Runs a fixed greedy policy (play the first affordable card, else end turn)
## against the real boss and returns the combat log for determinism checks.
func _auto_fight_log(seed_value: int) -> Array:
	_load_content()
	var rng := RngStream.new(seed_value)
	var player := PlayerState.new("player", "Wanderer", 70, 3, 5)
	for cid in ["harpoon_thrust", "brace_the_hull", "gaff_hook", "lantern_sweep", "shield_wall"]:
		player.add_to_draw_pile(CardInstance.new(ContentRegistry.get_def("card", cid)))
	var enemy := EnemyState.from_definition(ContentRegistry.get_def("enemy", "brine_soaked_villager"), rng)
	var combat := CombatState.new(ContentRegistry, rng, player, [enemy])
	combat.start_combat()
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
	return combat.log
