class_name RunCombat
extends RefCounted
## Builds a combat for the run's current node (Phase 5b).
##
## The deck comes from the run's Attunement (the items you're carrying), the
## player enters at the run's *current* HP (damage carries between fights), and
## the enemy is drawn from the current universe's pool according to the node type
## (a normal, an elite, or the boss). Deterministic given the encounter RNG.

const NODE_ENEMY_FIELD := {
	"combat": "enemy_ids",
	"elite": "elite_ids",
	"boss": "boss_ids",
}


## Returns a ready-to-start CombatState for the run's current node, or null if
## the node isn't a fight or no enemy is available.
static func build(content, run: RunState, rng: RngStream) -> CombatState:
	var node := run.current_node()
	if node == null:
		return null
	var enemy_id := _pick_enemy(content, run.universe_id, node.node_type, rng)
	if enemy_id.is_empty():
		return null
	var enemy_def = content.get_def("enemy", enemy_id)
	if enemy_def == null:
		return null

	var archetype_name := "Wanderer"
	var archetype = content.get_def("body_archetype", run.archetype_id)
	if archetype != null:
		archetype_name = archetype.display_name

	var player := PlayerState.new("player", archetype_name, run.max_hp, run.base_energy, 5)
	player.hp = clampi(run.hp, 1, run.max_hp)  # carry damage in from earlier fights
	var deck := run.build_deck(content)
	rng.shuffle(deck)
	for card in deck:
		player.add_to_draw_pile(card)

	var enemy := EnemyState.from_definition(enemy_def, rng)
	return CombatState.new(content, rng, player, [enemy])


## True if a node type is a fight this builder handles.
static func is_combat_node(node_type: String) -> bool:
	return NODE_ENEMY_FIELD.has(node_type)


static func _pick_enemy(content, universe_id: String, node_type: String, rng: RngStream) -> String:
	var universe = content.get_def("universe", universe_id)
	if universe == null:
		return ""
	var field := str(NODE_ENEMY_FIELD.get(node_type, "enemy_ids"))
	var pool: Array = universe.get(field)
	if pool == null or pool.is_empty():
		# Fall back to normal enemies (e.g. an elite universe with no elites yet).
		pool = universe.enemy_ids
	if pool.is_empty():
		return ""
	return str(rng.pick(pool))
