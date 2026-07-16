class_name CombatState
extends RefCounted
## The turn-based combat orchestrator (Phase 3 combat).
##
## Owns the fight and drives the loop: start -> player turn (draw, play cards,
## end) -> each enemy acts on its telegraphed intent -> repeat until one side is
## gone. Rules live in the subsystems it calls — StatusEngine (hooks, decay,
## damage modifiers), EffectExecutor (card effects), IntentSelector (enemy AI);
## this class sequences them and holds the shared state (player, enemies, RNG,
## the combat log).
##
## Fully headless: construct it with a content provider (get_def/has_def), a
## seeded RngStream, a PlayerState, and EnemyStates, then call start_combat() and
## drive turns. No scene or node is touched — the UI (later) observes this state
## and sends commands (play_card / end_player_turn).

# Phase / outcome of the fight. Strings so combat logs stay readable.
const PHASE_NOT_STARTED := "not_started"
const PHASE_PLAYER_TURN := "player_turn"
const PHASE_ENEMY_TURN := "enemy_turn"
const PHASE_VICTORY := "victory"
const PHASE_DEFEAT := "defeat"

const TYPE_CARD := "card"

var content
var rng: RngStream
var player: PlayerState
var enemies: Array = []          # Array[EnemyState]
var turn_number: int = 0
var phase: String = PHASE_NOT_STARTED
var log: Array[String] = []
## Soul adaptation modifiers (SoulProgression.combat_modifiers): multipliers on
## damage taken from / dealt to enemies by tag. Empty = no adaptations.
var player_modifiers: Dictionary = {}
## The enemy whose blow ended the player, for the death report (null when death
## had no single killer, e.g. a damage-over-time status).
var killing_enemy: EnemyDefinition = null

# Set by the exhaust_card "this" effect while a card is resolving; consumed when
# the played card is routed out of the hand.
var _force_exhaust_current: bool = false


func _init(content_provider, rng_stream: RngStream, player_state: PlayerState, enemy_states: Array) -> void:
	content = content_provider
	rng = rng_stream
	player = player_state
	enemies = enemy_states


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

## Runs combat-start hooks, telegraphs each enemy's first intent, and begins the
## first player turn.
func start_combat() -> void:
	log_event("Combat begins: %s vs %d enemies" % [player.display_name, enemies.size()])
	StatusEngine.run_turn_hook(self, player, "on_combat_start")
	for enemy in enemies:
		StatusEngine.run_turn_hook(self, enemy, "on_combat_start")
		enemy.current_intent = IntentSelector.select(enemy, rng)
	_check_outcome()
	if not is_over():
		start_player_turn()


func start_player_turn() -> void:
	if is_over():
		return
	turn_number += 1
	phase = PHASE_PLAYER_TURN
	player.reset_block()
	# on_turn_start hooks first (Fortified block, Hallucinating junk into the
	# draw pile), then decay, then refill and draw so conjured cards can be drawn.
	StatusEngine.run_turn_hook(self, player, "on_turn_start")
	StatusEngine.apply_decay(content, player, "turn_start")
	# A start-of-turn damage-over-time status could be lethal; latch defeat before
	# handing control back, or the player would keep acting while dead.
	_check_outcome()
	if is_over():
		return
	player.refill_energy()
	player.draw(player.hand_size, rng)
	log_event("Player turn %d (energy %d, hand %d)" % [turn_number, player.energy, player.hand.size()])


## True if the card at hand index can be played right now (turn, playability,
## energy). Cheap enough for the UI to gate buttons with.
func can_play(hand_index: int) -> bool:
	if is_over() or phase != PHASE_PLAYER_TURN or not player.is_alive():
		return false
	if hand_index < 0 or hand_index >= player.hand.size():
		return false
	var card: CardInstance = player.hand[hand_index]
	return card.is_playable() and player.energy >= card.energy_cost()


## Plays the card at `hand_index`, aimed at `target_enemy_index` for single-enemy
## cards (ignored otherwise). Returns false if the play is illegal. Resolves all
## of the card's effects, then routes the card to discard / exhaust / oblivion.
func play_card(hand_index: int, target_enemy_index: int = -1) -> bool:
	if not can_play(hand_index):
		return false
	var card: CardInstance = player.hand[hand_index]
	player.energy -= card.energy_cost()
	player.hand.remove_at(hand_index)
	_force_exhaust_current = false

	var targets := _resolve_targets(card, target_enemy_index)
	var ctx := EffectContext.new(self, content, rng, player, targets, card)
	log_event("Player plays %s" % card.display_name())
	for effect in card.definition.effects:
		EffectExecutor.execute(ctx, effect)

	_route_played_card(card)
	_check_outcome()
	return true


## Ends the player's turn: end-of-turn hooks (Burning, Regeneration) and decay,
## discard, then the enemies act, then the next player turn (unless combat ended).
func end_player_turn() -> void:
	if is_over() or phase != PHASE_PLAYER_TURN:
		return
	StatusEngine.run_turn_hook(self, player, "on_turn_end")
	StatusEngine.apply_decay(content, player, "turn_end")
	_check_outcome()
	if is_over():
		return
	player.discard_hand()
	_run_enemy_turns()
	if not is_over():
		start_player_turn()


func _run_enemy_turns() -> void:
	phase = PHASE_ENEMY_TURN
	for enemy in enemies:
		if is_over():
			return
		if not enemy.is_alive():
			continue
		enemy.reset_block()
		StatusEngine.run_turn_hook(self, enemy, "on_turn_start")
		StatusEngine.apply_decay(content, enemy, "turn_start")
		_check_outcome()
		if is_over():
			return
		if enemy.is_alive():
			_perform_intent(enemy)
		_check_outcome()
		if is_over():
			return
		StatusEngine.run_turn_hook(self, enemy, "on_turn_end")
		StatusEngine.apply_decay(content, enemy, "turn_end")
		enemy.turns_taken += 1
		_check_outcome()
		# Telegraph the next move (only meaningful if it survived its own turn).
		if enemy.is_alive():
			enemy.current_intent = IntentSelector.select(enemy, rng)


func _perform_intent(enemy: EnemyState) -> void:
	var intent: EnemyIntentDefinition = enemy.current_intent
	if intent == null:
		intent = IntentSelector.select(enemy, rng)
		enemy.current_intent = intent
	log_event("%s: %s" % [enemy.display_name, intent.telegraph])
	match intent.kind:
		"attack":
			_enemy_attack(enemy, intent.amount, maxi(1, intent.times))
		"defend":
			enemy.add_block(intent.amount)
		"buff":
			StatusEngine.apply_status(content, enemy, intent.status_id, maxi(1, intent.amount))
		"debuff":
			StatusEngine.apply_status(content, player, intent.status_id, maxi(1, intent.amount))
		"special":
			# No generic special behavior yet; content-specific specials come later.
			log_event("%s uses a special move (no effect yet)" % enemy.display_name)
	enemy.record_intent_performed(intent.id)


## Enemy hits the player `times` times, through the attacker's outgoing modifier
## and the player's incoming modifier (players have no damage-type resistances).
func _enemy_attack(enemy: EnemyState, amount: int, times: int) -> void:
	var out_mult := StatusEngine.outgoing_damage_multiplier(content, enemy)
	var in_mult := StatusEngine.incoming_damage_multiplier(content, player)
	var soul_mult := adaptation_taken_multiplier(enemy)
	for _hit in times:
		if not player.is_alive():
			return
		var final_amount := maxi(0, int(round(amount * out_mult * in_mult * soul_mult)))
		var dealt := player.receive_damage(final_amount)
		log_event("%s hits %s for %d" % [enemy.display_name, player.display_name, dealt])
		if not player.is_alive() and killing_enemy == null:
			killing_enemy = enemy.definition  # remember who ended this life
		_check_outcome()
		if is_over():
			return


## Damage-taken multiplier from soul adaptations vs this enemy's tags
## (e.g. gills: x0.75 from anything tagged "drowned"). 1.0 with no adaptations.
func adaptation_taken_multiplier(enemy: EnemyState) -> float:
	var taken: Dictionary = player_modifiers.get("taken_vs_tags", {})
	if taken.is_empty() or enemy.definition == null:
		return 1.0
	var mult := 1.0
	for tag in enemy.definition.tags:
		mult *= float(taken.get(tag, 1.0))
	return mult


## Damage-dealt multiplier from soul adaptations vs this enemy's tags
## (e.g. the boss-scar: x1.10 against anything tagged "boss").
func adaptation_bonus_multiplier(target: EnemyState) -> float:
	var bonus: Dictionary = player_modifiers.get("bonus_vs_tags", {})
	if bonus.is_empty() or target.definition == null:
		return 1.0
	var mult := 1.0
	for tag in target.definition.tags:
		mult *= float(bonus.get(tag, 1.0))
	return mult


# ---------------------------------------------------------------------------
# Targeting
# ---------------------------------------------------------------------------

func _resolve_targets(card: CardInstance, target_enemy_index: int) -> Array:
	match card.definition.targeting:
		"self", "none":
			return [player]
		"all_enemies":
			return living_enemies()
		"random_enemy":
			var living := living_enemies()
			return [rng.pick(living)] if not living.is_empty() else []
		_:  # "enemy" — use the chosen index, falling back to the first living enemy
			if target_enemy_index >= 0 and target_enemy_index < enemies.size() and enemies[target_enemy_index].is_alive():
				return [enemies[target_enemy_index]]
			var living := living_enemies()
			return [living[0]] if not living.is_empty() else []


# ---------------------------------------------------------------------------
# Callbacks used by EffectExecutor / StatusEngine
# ---------------------------------------------------------------------------

func player_draw(count: int) -> void:
	player.draw(count, rng)


func modify_player_energy(delta: int) -> void:
	player.energy = maxi(0, player.energy + delta)


## Spawns `count` copies of a card into a player pile. force_temporary marks
## conjured cards so they vanish rather than persisting.
func add_card_to_player(card_id: String, destination: String, count: int, force_temporary: bool = false) -> void:
	var card_def = content.get_def(TYPE_CARD, card_id)
	if card_def == null:
		return
	for _i in maxi(1, count):
		var inst := CardInstance.new(card_def, force_temporary)
		match destination:
			"hand":
				player.hand.append(inst)
			"discard_pile":
				player.discard_pile.append(inst)
			_:  # "draw_pile"
				player.draw_pile.append(inst)


func mark_current_card_exhaust() -> void:
	_force_exhaust_current = true


func exhaust_random_in_hand(exclude: CardInstance, stream: RngStream) -> void:
	var candidates: Array = []
	for card in player.hand:
		if card != exclude:
			candidates.append(card)
	if candidates.is_empty():
		return
	var chosen: CardInstance = stream.pick(candidates)
	player.hand.erase(chosen)
	player.exhaust_pile.append(chosen)


func transform_random_in_hand(exclude: CardInstance, into_def: CardDefinition, stream: RngStream) -> void:
	var indices: Array = []
	for i in player.hand.size():
		if player.hand[i] != exclude:
			indices.append(i)
	if indices.is_empty():
		return
	var chosen: int = stream.pick(indices)
	player.hand[chosen] = CardInstance.new(into_def)


func living_enemies() -> Array:
	var out: Array = []
	for enemy in enemies:
		if enemy.is_alive():
			out.append(enemy)
	return out


## Called after damage lands so victory registers mid-effect (e.g. a multi-hit
## that kills before its later hits).
func note_damage_to(_target: Combatant) -> void:
	_check_outcome()


func log_event(message: String) -> void:
	log.append(message)
	Log.info(Log.Cat.COMBAT, message)


# ---------------------------------------------------------------------------
# Outcome
# ---------------------------------------------------------------------------

func is_victory() -> bool:
	return phase == PHASE_VICTORY


func is_defeat() -> bool:
	return phase == PHASE_DEFEAT


func is_over() -> bool:
	return phase == PHASE_VICTORY or phase == PHASE_DEFEAT


func _all_enemies_dead() -> bool:
	for enemy in enemies:
		if enemy.is_alive():
			return false
	return true


## Latches a terminal phase. Defeat takes priority: if the player fell, the run
## is over even if the last enemy died on the same exchange.
func _check_outcome() -> void:
	if is_over():
		return
	if not player.is_alive():
		phase = PHASE_DEFEAT
		log_event("Defeat: %s has died" % player.display_name)
	elif _all_enemies_dead():
		phase = PHASE_VICTORY
		log_event("Victory: all enemies defeated")


# ---------------------------------------------------------------------------
# Routing
# ---------------------------------------------------------------------------

func _route_played_card(card: CardInstance) -> void:
	if _force_exhaust_current and not card.temporary:
		player.exhaust_pile.append(card)
	else:
		player.route_played(card)
