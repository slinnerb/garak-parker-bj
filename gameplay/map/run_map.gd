class_name RunMap
extends RefCounted
## A generated run map: a directed acyclic graph of MapNodes from one or more
## start nodes (row 0) to a single boss (last row) — Phase 5.
##
## Built by MapGenerator, traversed by RunState. Nodes are stored id-keyed plus
## an insertion-ordered id list so any iteration that affects gameplay stays
## deterministic (never rely on raw Dictionary order for logic).

var rows: int = 0
var width: int = 0
var _nodes: Dictionary = {}      # id -> MapNode
var _order: Array[String] = []   # ids in insertion (row-major) order
var start_ids: Array[String] = []
var boss_id: String = ""


func add_node(node: MapNode) -> void:
	_nodes[node.id] = node
	_order.append(node.id)


func has_node(id: String) -> bool:
	return _nodes.has(id)


func get_node(id: String) -> MapNode:
	return _nodes.get(id)


## All nodes in row-major order (stable).
func all_nodes() -> Array[MapNode]:
	var out: Array[MapNode] = []
	for id in _order:
		out.append(_nodes[id])
	return out


func nodes_in_row(row: int) -> Array[MapNode]:
	var out: Array[MapNode] = []
	for id in _order:
		if _nodes[id].row == row:
			out.append(_nodes[id])
	return out


## The nodes reachable in one step from `id` (its next_ids resolved).
func next_nodes(id: String) -> Array[MapNode]:
	var out: Array[MapNode] = []
	var node := get_node(id)
	if node != null:
		for nid in node.next_ids:
			if _nodes.has(nid):
				out.append(_nodes[nid])
	return out


func start_nodes() -> Array[MapNode]:
	var out: Array[MapNode] = []
	for id in start_ids:
		if _nodes.has(id):
			out.append(_nodes[id])
	return out


# ---------------------------------------------------------------------------
# Validation — the map must be a well-formed start-to-boss DAG
# ---------------------------------------------------------------------------

## Returns human-readable problems ([] = valid). Checks the invariants the
## generator must uphold: real endpoints, no dangling edges, boss is terminal,
## every node is reachable from a start, and the boss is reachable from every
## node.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if start_ids.is_empty():
		problems.append("map has no start nodes")
	if boss_id.is_empty() or not has_node(boss_id):
		problems.append("map has no valid boss node")
	for id in _order:
		var node: MapNode = _nodes[id]
		for nid in node.next_ids:
			if not has_node(nid):
				problems.append("node '%s' points to missing node '%s'" % [id, nid])
			elif _nodes[nid].row != node.row + 1:
				problems.append("node '%s' edges to '%s' not in the next row" % [id, nid])
	if not boss_id.is_empty() and has_node(boss_id) and not get_node(boss_id).is_terminal():
		problems.append("boss node '%s' must be terminal (no outgoing edges)" % boss_id)

	# Reachability from starts (forward BFS).
	var reachable := _reachable_from(start_ids)
	for id in _order:
		if not reachable.has(id):
			problems.append("node '%s' is unreachable from any start" % id)
	# Every node must be able to reach the boss (no dead ends short of the boss).
	if has_node(boss_id):
		for id in _order:
			if id != boss_id and not _can_reach(id, boss_id):
				problems.append("node '%s' cannot reach the boss (dead end)" % id)
	return problems


func _reachable_from(seed_ids: Array) -> Dictionary:
	var seen := {}
	var stack: Array = seed_ids.duplicate()
	while not stack.is_empty():
		var id = stack.pop_back()
		if seen.has(id) or not has_node(id):
			continue
		seen[id] = true
		for nid in _nodes[id].next_ids:
			stack.append(nid)
	return seen


func _can_reach(from_id: String, target_id: String) -> bool:
	return _reachable_from([from_id]).has(target_id)
