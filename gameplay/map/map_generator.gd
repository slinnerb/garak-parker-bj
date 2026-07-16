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


## Builds a map from a universe's `map_gen_settings` dictionary (floors/branches/
## lanes/guaranteed_node_types), so authored per-universe tuning actually drives
## generation instead of being silently ignored. Missing keys fall back to the
## generate() defaults. `guaranteed_node_types` defaults to at least one item
## location; structural types (entry combat / rest / boss) are always present.
static func generate_from_settings(rng: RngStream, settings: Dictionary) -> RunMap:
	var rows := int(settings.get("floors", 7))
	var width := int(settings.get("lanes", 4))
	var paths := int(settings.get("branches", 6))
	var guaranteed = settings.get("guaranteed_node_types", ["item_search"])
	if not (guaranteed is Array) or guaranteed.is_empty():
		guaranteed = ["item_search"]
	return generate(rng, rows, width, paths, guaranteed)


## Generates a map. `rows` includes the entry (row 0) and boss (last row);
## `width` is the number of lanes; `paths` is how many routes are drawn (more
## paths => a denser, more branching map). `guaranteed` lists node types every
## map must contain (a convertible node is retyped if a type didn't roll).
static func generate(rng: RngStream, rows: int = 7, width: int = 4, paths: int = 6, guaranteed: Array = ["item_search"]) -> RunMap:
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

	_assign_types(rng, map, guaranteed)
	return map


static func _assign_types(rng: RngStream, map: RunMap, guaranteed: Array) -> void:
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
	_guarantee_types(rng, map, guaranteed)


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


## Ensures every required node type appears at least once. The old version only
## converted a middle *combat* node, so an unlucky map where every middle node
## rolled non-combat could ship with zero item-search nodes despite the stated
## guarantee. This retypes a node for each missing type, so the contract holds
## for any map size or roll. Structural types (rest/boss) are already placed and
## are skipped here; "combat" is never a guarantee target (it's the default).
static func _guarantee_types(rng: RngStream, map: RunMap, guaranteed: Array) -> void:
	for t in guaranteed:
		var type_name := str(t)
		if type_name in ["combat", "rest", "boss"]:
			continue
		_ensure_type(rng, map, type_name)


## Guarantees one node of `node_type` exists, converting a spare node if not.
## Preference order keeps the guarantee non-destructive: a middle-row combat node
## first (so we don't clobber another special node), then any middle-row node,
## then the entry row (only reachable on a degenerate 3-row map). Deterministic:
## exactly one rng.pick when a conversion is needed, none when already satisfied.
static func _ensure_type(rng: RngStream, map: RunMap, node_type: String) -> void:
	var combat_mid: Array[MapNode] = []
	var any_mid: Array[MapNode] = []
	var entry: Array[MapNode] = []
	for node in map.all_nodes():
		if node.node_type == node_type:
			return  # already present — guarantee met
		if node.row == 0:
			entry.append(node)
		elif node.row > 0 and node.row < map.rows - 2:
			any_mid.append(node)
			if node.node_type == "combat":
				combat_mid.append(node)
	var pool := combat_mid
	if pool.is_empty():
		pool = any_mid
	if pool.is_empty():
		pool = entry
	if not pool.is_empty():
		var pick: MapNode = rng.pick(pool)
		pick.node_type = node_type


static func _node_id(row: int, col: int) -> String:
	return "n%d_%d" % [row, col]
