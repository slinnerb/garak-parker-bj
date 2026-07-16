class_name RunState
extends RefCounted
## The mortal state of one life (Phase 5): where you are on the map, how much
## body you have left, and the items/deck you're carrying. All of this is lost at
## death — it's the "body" half of progression (docs/GAME_VISION.md). The soul's
## permanent progression will live elsewhere (Phase 6).
##
## Traversal is a simple forward walk: from the current node you may step to any
## node it connects to in the next row. Before entering the map, the choices are
## the map's start nodes.

var run_seed: int = 0
var universe_id: String = ""
var archetype_id: String = ""

var max_hp: int = 60
var hp: int = 60
var base_energy: int = 3
var slot_capacity: int = 6

var map: RunMap
var inventory: Inventory
var attunement: Attunement

## The node the player is currently on ("" before entering the map).
var current_node_id: String = ""
var visited: Array[String] = []
var boss_defeated: bool = false


# ---------------------------------------------------------------------------
# Traversal
# ---------------------------------------------------------------------------

## The nodes the player may move to next. At the map's start, that's the entry
## row; otherwise it's the current node's forward connections.
func available_next() -> Array[MapNode]:
	if map == null:
		return []
	if current_node_id.is_empty():
		return map.start_nodes()
	return map.next_nodes(current_node_id)


func can_travel_to(node_id: String) -> bool:
	if is_over():
		return false
	for node in available_next():
		if node.id == node_id:
			return true
	return false


## Moves to a reachable node. Returns whether the move was allowed.
func travel_to(node_id: String) -> bool:
	if not can_travel_to(node_id):
		return false
	current_node_id = node_id
	if not visited.has(node_id):
		visited.append(node_id)
	return true


func current_node() -> MapNode:
	return map.get_node(current_node_id) if map != null else null


func at_boss() -> bool:
	return map != null and current_node_id == map.boss_id


# ---------------------------------------------------------------------------
# Body state
# ---------------------------------------------------------------------------

func is_defeat() -> bool:
	return hp <= 0


func is_victory() -> bool:
	return boss_defeated


func is_over() -> bool:
	return is_defeat() or is_victory()


## Applies the outcome of a combat at the current node: the surviving HP, and
## whether this was the boss.
func resolve_combat(surviving_hp: int) -> void:
	hp = clampi(surviving_hp, 0, max_hp)
	if at_boss() and hp > 0:
		boss_defeated = true


func heal(amount: int) -> void:
	if amount > 0 and hp > 0:
		hp = mini(max_hp, hp + amount)


## Picks up an item into the bag, and attunes it if it still fits the slots.
## Returns whether it was attuned (so the caller can message "added to deck").
func acquire_item(item: ItemDefinition, auto_attune: bool = true) -> bool:
	if item == null:
		return false
	inventory.add(item)
	if auto_attune and attunement.can_attune(item):
		return attunement.attune(item)
	return false


## The combat deck derived from the currently attuned items.
func build_deck(content) -> Array:
	return attunement.build_deck(content) if attunement != null else []
