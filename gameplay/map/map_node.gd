class_name MapNode
extends RefCounted
## One node in a generated run map (Phase 5).
##
## Pure graph data: where the node sits (row/col, for layout and generation
## rules), what kind of encounter it is (`node_type`, one of
## MapNodeDefinition.NODE_TYPES), and which nodes in the next row it leads to.
## The map is logical first — nodes carry a grid position but no pixel
## coordinates, so generation and traversal stay independent of any UI
## (master prompt §12).

var id: String = ""
## Row 0 is the entry; the last row is the boss. Column is the lane within a row.
var row: int = 0
var col: int = 0
## Encounter type — a MapNodeDefinition id/type ("combat", "elite", "rest", ...).
var node_type: String = "combat"
## Ids of the nodes in row+1 reachable from here. Empty for the boss (terminal).
var next_ids: Array[String] = []


func _init(node_id: String = "", node_row: int = 0, node_col: int = 0, type: String = "combat") -> void:
	id = node_id
	row = node_row
	col = node_col
	node_type = type


func is_terminal() -> bool:
	return next_ids.is_empty()
