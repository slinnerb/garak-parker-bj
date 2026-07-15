class_name MapGenerator
extends RefCounted
## Builds a seeded, branching run map (Phase 5, master prompt §12).
##
## Algorithm (paths): draw several paths from row 0 to the boss row. Each path
## starts in a random lane and, each row, steps to an adjacent lane. The union of
## visited cells becomes the nodes; consecutive steps become edges. All paths
## converge on a single boss in the last row, so the map is always a connected
## start-to-boss DAG. Node *types* are then assigned by weighted chance with a
## few guarantees (a gentle first row, a rest before the boss, at least one place
## to find an item).
##
## Everything derives from the passed RngStream, so the same run seed always
## produces the same map. Purely logical — no pixel coordinates (§12).

# Node types eligible for the random middle rows, with weights. Neutral/rare
# and gated types (tattoo/story) are placed by other systems, not here.
const MIDDLE_WEIGHTS := {
	"combat": 10,
	"item_search": 4,
	"event": 4,
	"treasure": 2,
	"shrine": 2,
	"merchant": 2,
	"memory_anomaly": 1,
}
# Elites are dangerous — only from this row onward, added with this weight.
const ELITE_MIN_ROW := 3
const ELITE_WEIGHT := 3


## Generates a map. `rows` includes the entry (row 0) and boss (last row);
## `width` is the number of lanes; `paths` is how many routes are drawn (more
## paths => a denser, more branching map).
static func generate(rng: RngStream, rows: int = 7, width: int = 4, paths: int = 6) -> RunMap:
	rows = maxi(3, rows)
	width = maxi(2, width)
	paths = maxi(2, paths)
	var boss_col := int(width / 2)

	var present := {}        # Vector2i(row, col) -> true
	var edges := {}          # "row_col_nextcol" -> true (dedup)
	present[Vector2i(rows - 1, boss_col)] = true

	for _p in paths:
		var col := rng.randi_range(0, width - 1)
		present[Vector2i(0, col)] = true
		for r in range(1, rows - 1):
			var next_col := clampi(col + rng.randi_range(-1, 1), 0, width - 1)
			present[Vector2i(r, next_col)] = true
			edges["%d_%d_%d" % [r - 1, col, next_col]] = true
			col = next_col
		# Funnel the last pre-boss lane into the boss.
		edges["%d_%d_%d" % [rows - 2, col, boss_col]] = true

	var map := RunMap.new()
	map.rows = rows
	map.width = width

	# Build nodes in row-major order (deterministic).
	for r in rows:
		for c in width:
			if present.has(Vector2i(r, c)):
				map.add_node(MapNode.new(_node_id(r, c), r, c, "combat"))

	# Resolve edges into next_ids, lane-sorted for stability.
	for r in range(0, rows - 1):
		for c in width:
			var node := map.get_node(_node_id(r, c))
			if node == null:
				continue
			for nc in width:
				if edges.has("%d_%d_%d" % [r, c, nc]):
					node.next_ids.append(_node_id(r + 1, nc))

	for c in width:
		if present.has(Vector2i(0, c)):
			map.start_ids.append(_node_id(0, c))
	map.boss_id = _node_id(rows - 1, boss_col)

	_assign_types(rng, map)
	return map


static func _assign_types(rng: RngStream, map: RunMap) -> void:
	var last_row := map.rows - 1
	for node in map.all_nodes():
		if node.row == 0:
			node.node_type = "combat"          # a gentle, known first step
		elif node.row == last_row:
			node.node_type = "boss"
		elif node.row == last_row - 1:
			node.node_type = "rest"            # guaranteed rest before the boss
		else:
			node.node_type = _roll_type(rng, node.row)
	_guarantee_item_search(rng, map)


static func _roll_type(rng: RngStream, row: int) -> String:
	var types: Array = []
	var weights: Array = []
	for t in MIDDLE_WEIGHTS:
		types.append(t)
		weights.append(MIDDLE_WEIGHTS[t])
	if row >= ELITE_MIN_ROW:
		types.append("elite")
		weights.append(ELITE_WEIGHT)
	var chosen = rng.pick_weighted(types, weights)
	return str(chosen) if chosen != null else "combat"


## Every run should offer at least one place to find an item. If the roll didn't
## produce one, convert a random middle combat node.
static func _guarantee_item_search(rng: RngStream, map: RunMap) -> void:
	var candidates: Array[MapNode] = []
	var has_search := false
	for node in map.all_nodes():
		if node.node_type == "item_search":
			has_search = true
		elif node.node_type == "combat" and node.row > 0 and node.row < map.rows - 2:
			candidates.append(node)
	if not has_search and not candidates.is_empty():
		var pick: MapNode = rng.pick(candidates)
		pick.node_type = "item_search"


static func _node_id(row: int, col: int) -> String:
	return "n%d_%d" % [row, col]
